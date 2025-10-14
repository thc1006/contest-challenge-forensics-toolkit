#!/usr/bin/env python3
import argparse, json, os, glob, hashlib
from datetime import datetime, timezone
try:
    from zoneinfo import ZoneInfo
except ImportError:
    # Fallback for Python 3.9
    try:
        from backports.zoneinfo import ZoneInfo
    except ImportError:
        print("ERROR: zoneinfo not available. Install: pip install tzdata backports.zoneinfo")
        import sys
        sys.exit(1)
import yaml

def read_text(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return ""

def list_outputs(case_slug, pattern):
    return sorted(glob.glob(os.path.join("outputs", case_slug, pattern)))

def fmt_both(t_utc_str, local_tz):
    if not t_utc_str or t_utc_str == "null":
        return ("", "")
    s = t_utc_str.replace("Z","").replace(" ","T")
    try:
        t = datetime.fromisoformat(s)
    except Exception:
        return (t_utc_str, "")
    if t.tzinfo is None:
        t = t.replace(tzinfo=timezone.utc)
    t_utc = t.astimezone(timezone.utc)
    t_loc = t.astimezone(ZoneInfo(local_tz))
    return (t_utc.isoformat().replace("+00:00","Z"), t_loc.isoformat())

def parse_tsv(tsv_path):
    events = []
    if not os.path.exists(tsv_path):
        return events
    with open(tsv_path, "r", encoding="utf-8") as f:
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 7: 
                continue
            created_at, actor, repo, ref, size, dsize, head = parts[:7]
            events.append({
                "type": "gharchive_push",
                "created_at": created_at,
                "actor": actor,
                "repo": repo,
                "ref": ref,
                "size": size,
                "distinct_size": dsize,
                "head": head
            })
    return events

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--case", required=True, help="YAML case file")
    args = ap.parse_args()

    with open(args.case, "r", encoding="utf-8") as f:
        case = yaml.safe_load(f)
    case_slug = case["case_slug"]
    local_tz = os.environ.get("LOCAL_TZ", "Asia/Taipei")

    deadline_local = case.get("deadline_local", "")
    deadline_utc = ""
    if deadline_local:
        try:
            t = datetime.fromisoformat(deadline_local)
            deadline_utc = t.astimezone(timezone.utc).isoformat().replace("+00:00","Z")
        except Exception:
            pass

    out_dir = os.path.join("outputs", case_slug)
    os.makedirs(out_dir, exist_ok=True)
    lines = []
    lines.append(f"# Timeline Report — {case_slug}")
    lines.append("")
    lines.append(f"- **Rules URL**: {case.get('rules_url','')}")
    lines.append(f"- **Local TZ**: `{local_tz}`")
    if deadline_local:
        lines.append(f"- **Deadline (Local)**: `{deadline_local}`")
    if deadline_utc:
        lines.append(f"- **Deadline (UTC)**: `{deadline_utc}`")
    lines.append("")

    # GH Archive PushEvents
    tsv_path = os.path.join(out_dir, "gharchive_push_events.tsv")
    events = parse_tsv(tsv_path)
    if events:
        lines.append("## GH Archive PushEvents (server-side UTC)")
        lines.append("| UTC | Local | Late? | Actor | Ref | Size | Distinct | Head |")
        lines.append("|---|---|:--:|---|---:|---:|---:|---|")
        for ev in events:
            utc, loc = fmt_both(ev["created_at"], local_tz)
            late = ""
            if deadline_utc and utc and utc > deadline_utc:
                late = "❌"
            lines.append(f"| {utc} | {loc} | {late} | `{ev['actor']}` | `{ev['ref']}` | {ev['size']} | {ev['distinct_size']} | `{ev['head']}` |")
        lines.append("")
    else:
        lines.append("## GH Archive PushEvents")
        lines.append("_No events captured in the selected window._\n")

    # GitHub commit times
    for path in list_outputs(case_slug, "github_commit_*.json"):
        try:
            data = json.loads(read_text(path) or "{}")
        except Exception:
            data = {}
        author = data.get("commit", {}).get("author", {}).get("date", "")
        committer = data.get("commit", {}).get("committer", {}).get("date", "")
        utc_a, loc_a = fmt_both(author, local_tz)
        utc_c, loc_c = fmt_both(committer, local_tz)
        late_a = "❌" if deadline_utc and utc_a and utc_a > deadline_utc else ""
        late_c = "❌" if deadline_utc and utc_c and utc_c > deadline_utc else ""
        lines.append(f"## GitHub Commit Time — `{os.path.basename(path)}`")
        lines.append(f"- author.date: `{utc_a}` / `{loc_a}` {late_a}")
        lines.append(f"- committer.date: `{utc_c}` / `{loc_c}` {late_c}")
        lines.append("")

    # urlscan
    us_files = list_outputs(case_slug, "urlscan_*.json")
    if us_files:
        lines.append("## urlscan.io")
        for f in us_files:
            try:
                data = json.loads(read_text(f) or "{}")
            except Exception:
                data = {}
            if "results" in data:
                cnt = len(data.get("results", []))
                lines.append(f"- `{os.path.basename(f)}` — results: {cnt}")
            else:
                uuid = data.get("uuid", "")
                result = data.get("result", "")
                lines.append(f"- `{os.path.basename(f)}` — uuid: `{uuid}` result: {result}")
        lines.append("")

    # CT logs
    for path in list_outputs(case_slug, "ct_*.json"):
        try:
            data = json.loads(read_text(path) or "[]")
        except Exception:
            data = []
        earliest = ""
        if isinstance(data, list) and data:
            try:
                not_befores = [e.get("not_before","") for e in data if "not_before" in e]
                not_befores = [x for x in not_befores if x]
                earliest = min(not_befores) if not_befores else ""
            except Exception:
                earliest = ""
        utc_ct, loc_ct = fmt_both(earliest, local_tz)
        late_ct = "❌" if deadline_utc and utc_ct and utc_ct > deadline_utc else ""
        lines.append(f"## Certificate Transparency — `{os.path.basename(path)}`")
        lines.append(f"- earliest not_before: `{utc_ct}` / `{loc_ct}` {late_ct}")
        lines.append("")

    # DNS history
    for path in list_outputs(case_slug, "dns_*.json"):
        try:
            data = json.loads(read_text(path) or "{}")
        except Exception:
            data = {}
        lines.append(f"## DNS History — `{os.path.basename(path)}`")
        lines.append(f"- keys: {', '.join(sorted(data.keys()))}")
        lines.append("")

    # Wayback saves
    for path in list_outputs(case_slug, "wayback_*.json"):
        try:
            data = json.loads(read_text(path) or "{}")
        except Exception:
            data = {}
        saved = data.get("saved", "")
        utc_wb, loc_wb = fmt_both(saved, local_tz)
        lines.append(f"## Wayback Save — `{os.path.basename(path)}`")
        lines.append(f"- saved at: `{utc_wb}` / `{loc_wb}`")
        lines.append(f"- target: `{data.get('target','')}`")
        lines.append("")

    # Manifest
    manifest = os.path.join(out_dir, "sources_manifest.txt")
    if os.path.exists(manifest):
        lines.append("## Sources Manifest (SHA256)")
        lines.append("```")
        lines.append(read_text(manifest))
        lines.append("```")

    with open(os.path.join(out_dir, "timeline.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"Wrote {os.path.join(out_dir, 'timeline.md')}")

if __name__ == "__main__":
    main()
