#!/usr/bin/env python3
"""Claude Code statusline (tmux): model · cumulative tokens · plan rate limits.

Writes a tmux-formatted status fragment to /tmp/claude_status_$TMUX_PANE, which
~/.tmux.conf cats into status-right. The in-Claude statusline is intentionally
left blank (nothing is printed to stdout) — status lives only in the tmux bar.
"""
import json
import os
import sys
import time

# Last-known rate limits, persisted so the bars can render at session start
# before the first API response populates ctx["rate_limits"].
RATE_CACHE = os.path.expanduser("~/.claude/rate_limits_cache.json")


def load_rate_cache():
    try:
        with open(RATE_CACHE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_rate_cache(limits):
    try:
        with open(RATE_CACHE, "w") as f:
            json.dump(limits, f)
    except OSError:
        pass


def tokens_of(usage):
    if not usage:
        return 0
    return (
        usage.get("input_tokens", 0)
        + usage.get("cache_creation_input_tokens", 0)
        + usage.get("cache_read_input_tokens", 0)
        + usage.get("output_tokens", 0)
    )


def fmt_tokens(n):
    n = int(n)
    if n >= 1_000_000:
        return f"{n/1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n/1_000:.1f}K"
    return str(n)


def session_tokens(path):
    """Cumulative billed tokens this session — every turn re-bills the cached
    prefix, so this grows without bound. Deduped by message id. Informational:
    it does NOT track context occupancy or predict compaction."""
    total = 0
    seen = set()
    try:
        with open(path) as f:
            for line in f:
                try:
                    e = json.loads(line)
                except Exception:
                    continue
                msg = e.get("message") or {}
                usage = msg.get("usage")
                if not usage:
                    continue
                mid = msg.get("id")
                if mid:
                    if mid in seen:
                        continue
                    seen.add(mid)
                total += tokens_of(usage)
    except FileNotFoundError:
        pass
    return total


def tmux_bar(pct, w=10):
    filled = int(round(pct * w))
    if pct < 0.6:
        fill = "#[fg=#A7C080]"   # green
    elif pct < 0.85:
        fill = "#[fg=#DBBC7F]"   # amber — getting full
    else:
        fill = "#[fg=#E67E80]"   # red — compaction near
    track = "#[fg=#3d3d3d]"
    tail = "#[fg=#859289]"
    return f"{fill}{'━' * filled}{track}{'╌' * (w - filled)}{tail}"


def main():
    try:
        ctx = json.load(sys.stdin)
    except Exception:
        ctx = {}
    transcript = ctx.get("transcript_path", "")
    model = ctx.get("model") or {}
    model_name = model.get("display_name") or model.get("id") or ""

    sess_tok = session_tokens(transcript) if transcript else 0

    # Plan rate limits (Pro/Max only, present after the first API response).
    # Cache live values; fall back to the cache at session start so the bars
    # render before the first response. Stale values are tagged with "~".
    limits = ctx.get("rate_limits") or {}
    if limits.get("five_hour") or limits.get("seven_day"):
        save_rate_cache(limits)
        stale = False
    else:
        limits = load_rate_cache()
        stale = True

    tmux_pane = os.environ.get("TMUX_PANE")
    if tmux_pane:
        try:
            tmux_parts = []
            if model_name:
                tmux_parts.append(f"#[fg=#83a598]{model_name}#[fg=#859289]")
            tmux_parts.append(fmt_tokens(sess_tok))
            now = time.time()
            for label, key, width in (("5h", "five_hour", 10), ("7d", "seven_day", 4)):
                window = limits.get(key) or {}
                used = window.get("used_percentage")
                if used is None:
                    continue
                resets_at = window.get("resets_at")
                if stale and resets_at and now >= resets_at:
                    used = 0  # window rolled over since the cache was written
                tag = "~" if stale else ""
                tmux_parts.append(
                    f"{tag}{label} {tmux_bar(min(used / 100.0, 1.0), width)} {used:.0f}%"
                )
            sep = " #[fg=#3d3d3d]│#[fg=#859289] "
            tmux_status = "#[fg=#3d3d3d]│#[fg=#859289] " + sep.join(tmux_parts) + " "
            with open(f"/tmp/claude_status_{tmux_pane}", "w") as f:
                f.write(tmux_status)
        except OSError:
            pass


if __name__ == "__main__":
    main()
