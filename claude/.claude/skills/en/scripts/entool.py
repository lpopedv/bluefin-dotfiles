#!/usr/bin/env python3
"""Helper for the English-learning skills (/en, /en-review, /en-interview).

Subcommands:
  log      read one JSON object from stdin, validate it, stamp the real UTC time, append to log.jsonl
  stats    aggregate the log (optional: --days N) and print a JSON report for /en-review
  context  short plain-text summary of recurring mistakes (used by the auto-detect hook)
"""
import json
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

BASE = Path.home() / ".claude" / "english"
LOG = BASE / "log.jsonl"
VOCAB = BASE / "vocab.jsonl"

TYPES = {
    "spelling", "punctuation", "verb-tense", "verb-form",
    "subject-verb-agreement", "article", "preposition", "plural", "pronoun",
    "word-order", "question-form", "missing-word", "sentence-structure",
    "infinitive-gerund", "word-choice", "vocabulary", "collocation",
    "phrasal-verb", "false-friend", "idiom-naturalness", "register",
    "conditional", "comparative",
}
LEVELS = {"A1", "A2", "B1", "B2", "C1", "C2"}
# Not taught or counted any more; dropped from older entries as they load.
IGNORED = {"capitalization"}


def load(days=None):
    entries = []
    if not LOG.exists():
        return entries
    cutoff = datetime.now(timezone.utc) - timedelta(days=days) if days else None
    for line in LOG.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            continue
        if cutoff:
            try:
                ts = datetime.fromisoformat(e["ts"].replace("Z", "+00:00"))
            except (KeyError, ValueError):
                continue
            if ts < cutoff:
                continue
        e["errors"] = [err for err in e.get("errors", []) if err.get("type") not in IGNORED]
        entries.append(e)
    return entries


def cmd_log():
    raw = sys.stdin.read().strip()
    try:
        e = json.loads(raw)
    except json.JSONDecodeError as exc:
        sys.exit(f"invalid JSON: {exc}")
    problems = []
    if not isinstance(e.get("original"), str) or not e["original"].strip():
        problems.append("'original' must be a non-empty string")
    errors = e.get("errors")
    if not isinstance(errors, list):
        problems.append("'errors' must be a list")
        errors = []
    for i, err in enumerate(errors):
        if err.get("type") not in TYPES:
            problems.append(f"errors[{i}].type '{err.get('type')}' is not an allowed slug: {sorted(TYPES)}")
        for k in ("wrong", "right", "note"):
            if not isinstance(err.get(k), str):
                problems.append(f"errors[{i}].{k} missing")
    if not isinstance(e.get("score"), int) or not 0 <= e["score"] <= 10:
        problems.append("'score' must be an integer 0-10")
    if e.get("level_estimate") not in LEVELS:
        problems.append(f"'level_estimate' must be one of {sorted(LEVELS)}")
    if problems:
        sys.exit("not logged:\n- " + "\n- ".join(problems))

    now = datetime.now(timezone.utc).replace(microsecond=0)
    e["ts"] = now.isoformat().replace("+00:00", "Z")
    e.setdefault("source", "chat")
    e.setdefault("did_well", [])
    vocab = e.pop("vocab", None) or []

    BASE.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(e, ensure_ascii=False) + "\n")
    if vocab:
        with VOCAB.open("a", encoding="utf-8") as f:
            for v in vocab:
                if isinstance(v, dict) and v.get("term"):
                    v["ts"] = e["ts"]
                    f.write(json.dumps(v, ensure_ascii=False) + "\n")
    print(f"logged ({len(errors)} errors, {len(vocab)} vocab)")


def aggregate(entries):
    types = Counter()
    patterns = defaultdict(list)
    for e in entries:
        for err in e.get("errors", []):
            types[err.get("type")] += 1
            key = (err.get("type"), (err.get("right") or "").strip().lower())
            patterns[key].append({"wrong": err.get("wrong"), "right": err.get("right"),
                                  "note": err.get("note"), "ts": e.get("ts")})
    return types, patterns


def cmd_stats(argv):
    days = None
    if "--days" in argv:
        days = int(argv[argv.index("--days") + 1])
    entries = load(days)
    if not entries:
        print(json.dumps({"messages": 0}))
        return
    types, patterns = aggregate(entries)
    scores = [e["score"] for e in entries if isinstance(e.get("score"), int)]
    half = len(scores) // 2
    vocab = []
    if VOCAB.exists():
        for line in VOCAB.read_text(encoding="utf-8").splitlines():
            try:
                vocab.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    reviews = sorted((BASE / "reviews").glob("*.md")) if (BASE / "reviews").exists() else []
    report = {
        "messages": len(entries),
        "by_source": Counter(e.get("source", "chat") for e in entries),
        "first_ts": entries[0].get("ts"),
        "last_ts": entries[-1].get("ts"),
        "avg_score": round(sum(scores) / len(scores), 2) if scores else None,
        "avg_score_first_half": round(sum(scores[:half]) / half, 2) if half else None,
        "avg_score_second_half": round(sum(scores[half:]) / (len(scores) - half), 2) if scores else None,
        "messages_without_errors": sum(1 for e in entries if not e.get("errors")),
        "error_types": types.most_common(),
        "repeated_patterns": [
            {"type": t, "right": r, "count": len(v), "examples": v[:3]}
            for (t, r), v in sorted(patterns.items(), key=lambda kv: -len(kv[1]))
            if len(v) > 1
        ],
        "level_timeline": [(e.get("ts"), e.get("level_estimate")) for e in entries],
        "did_well": [w for e in entries for w in e.get("did_well", [])],
        "vocab": vocab[-40:],
        "previous_review": str(reviews[-1]) if reviews else None,
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))


def context_summary(limit=4):
    total = len(load())
    challenge = "YES" if (total + 1) % 5 == 0 else "no"
    entries = load()[-30:]
    if not entries:
        return f"No history yet — this is the learner's first logged message. Mini-challenge this turn: {challenge}"
    types, patterns = aggregate(entries)
    lines = [f"Messages practiced so far: {total}. Mini-challenge this turn: {challenge}."]
    if types:
        lines.append("Most frequent error types: " + ", ".join(f"{t} ({n})" for t, n in types.most_common(limit)))
    recent = []
    for e in reversed(entries[-15:]):
        for err in e.get("errors", []):
            recent.append(f"\"{err.get('wrong')}\" -> \"{err.get('right')}\" ({err.get('type')})")
    if recent:
        lines.append("Recent mistakes to watch for (flag as REPEATED if they happen again): " + "; ".join(recent[:6]))
    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd = sys.argv[1]
    if cmd == "log":
        cmd_log()
    elif cmd == "stats":
        cmd_stats(sys.argv[2:])
    elif cmd == "context":
        print(context_summary())
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
