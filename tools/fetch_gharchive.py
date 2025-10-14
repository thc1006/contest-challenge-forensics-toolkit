#!/usr/bin/env python3
import argparse, datetime as dt, gzip, json, urllib.request, urllib.error

def hour_iter(start_date, end_date):
    start = dt.datetime.fromisoformat(start_date).replace(tzinfo=dt.timezone.utc)
    end = dt.datetime.fromisoformat(end_date).replace(tzinfo=dt.timezone.utc)
    cur = start
    while cur <= end + dt.timedelta(hours=23):
        yield cur.strftime("%Y-%m-%d-%H")
        cur += dt.timedelta(hours=1)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--owner", required=True)
    ap.add_argument("--repo", required=True)
    ap.add_argument("--start", required=True)
    ap.add_argument("--end", required=True)
    args = ap.parse_args()
    target = f"{args.owner}/{args.repo}"
    for hour in hour_iter(args.start, args.end):
        url = f"https://data.gharchive.org/{hour}.json.gz"
        try:
            with urllib.request.urlopen(url, timeout=60) as resp:
                gz = resp.read()
        except Exception:
            continue
        try:
            data = gzip.decompress(gz).decode("utf-8", errors="ignore").splitlines()
        except Exception:
            continue
        for line in data:
            try:
                ev = json.loads(line)
            except Exception:
                continue
            if ev.get("type") != "PushEvent":
                continue
            repo = ev.get("repo", {}).get("name")
            if repo != target:
                continue
            payload = ev.get("payload", {})
            out = {
                "created_at": ev.get("created_at"),
                "actor_login": ev.get("actor", {}).get("login"),
                "repo_name": repo,
                "ref": payload.get("ref"),
                "size": payload.get("size"),
                "distinct_size": payload.get("distinct_size"),
                "head": payload.get("head"),
                "before": payload.get("before"),
                "url_hour": url,
            }
            print(json.dumps(out, ensure_ascii=False))

if __name__ == "__main__":
    main()
