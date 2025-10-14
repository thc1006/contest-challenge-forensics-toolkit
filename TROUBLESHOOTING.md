# Troubleshooting Guide

Common issues and their solutions.

---

## Installation Issues

### "yq: command not found"

**Problem:** The yq YAML parser is not installed.

**Solution:**

**Windows:**
```powershell
# Using Chocolatey
choco install yq

# Or download manually from:
# https://github.com/mikefarah/yq/releases
# Place yq.exe in your PATH
```

**Linux:**
```bash
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
sudo chmod +x /usr/bin/yq
```

**macOS:**
```bash
brew install yq
```

---

### "jq: command not found"

**Problem:** The jq JSON processor is not installed.

**Solution:**

**Windows:**
```powershell
# Using Chocolatey
choco install jq

# Or download from: https://stedolan.github.io/jq/download/
```

**Linux:**
```bash
sudo apt install jq
```

**macOS:**
```bash
brew install jq
```

---

### Python zoneinfo errors

**Error:**
```
ModuleNotFoundError: No module named 'zoneinfo'
```

**Cause:** Python 3.9 doesn't have zoneinfo in the standard library.

**Solution:**
```bash
pip install tzdata backports.zoneinfo
```

Then update `tools/compile_timeline.py` (line 3):
```python
try:
    from zoneinfo import ZoneInfo
except ImportError:
    from backports.zoneinfo import ZoneInfo
```

---

### "curl: not found" on Windows

**Problem:** Running in PowerShell instead of Git Bash.

**Solution:**
1. Open Git Bash (not PowerShell)
2. Navigate to the project directory
3. Run the commands there

In PowerShell, `curl` is an alias for `Invoke-WebRequest` and won't work with these scripts.

---

## Runtime Issues

### GitHub API Rate Limit Exceeded

**Error:**
```
API rate limit exceeded for xxx.xxx.xxx.xxx
```

**Cause:** GitHub API limits unauthenticated requests to 60/hour.

**Solution:**
1. Create a GitHub Personal Access Token: https://github.com/settings/tokens
2. Add it to `.env`:
   ```bash
   GITHUB_TOKEN=ghp_your_token_here
   ```
3. Re-run the script

With a token, you get 5,000 requests/hour.

---

### "Permission denied" on Scripts

**Error:**
```bash
bash: ./scripts/run_case.sh: Permission denied
```

**Cause:** Scripts don't have execute permissions.

**Solution:**
```bash
chmod +x scripts/*.sh
```

Or run with `bash` explicitly:
```bash
bash scripts/run_case.sh cases/my_case.yaml
```

---

### GH Archive Download Fails

**Error:**
```
Failed to download https://data.gharchive.org/2025-10-05-12.json.gz
```

**Cause:** 
- Network issues
- Date range includes future dates or very old dates
- GH Archive server temporarily unavailable

**Solution:**
1. Check your internet connection
2. Verify dates in your case file are reasonable (not in the future, not before 2011)
3. Check GH Archive status: https://www.gharchive.org/
4. Retry after a few minutes

---

### urlscan.io Errors

**Error:**
```
{"message":"Invalid API key","status":401}
```

**Solution:**
1. Verify your API key in `.env`
2. Check if your key is valid at https://urlscan.io/user/profile/
3. If you don't have a key, leave it empty (the script will skip urlscan)

**Rate Limits:**
- Free tier: 50 scans/day, 100 searches/day
- If exceeded, wait 24 hours or upgrade

---

### Empty Timeline Report

**Problem:** `timeline.md` is generated but contains no events.

**Possible Causes:**
1. **Date window too narrow:** Expand `date_window_utc` in your case file
2. **Wrong repository:** Double-check owner/name
3. **No matching events:** The repository had no activity in that window
4. **Network errors:** Check `LOG.md` for error messages

**Solution:**
1. Check `outputs/<case_slug>/LOG.md` for errors
2. Verify your case file:
   ```yaml
   targets:
     date_window_utc:
       start: 2025-10-01  # Should be before deadline
       end:   2025-10-07  # Should be after deadline
     repos:
       - owner: correct_owner
         name: correct_repo_name
   ```
3. Manually check if the repo exists: `https://github.com/<owner>/<repo>`

---

### Timezone Issues

**Problem:** Times in report don't match expected timezone.

**Solution:**
1. Check `LOCAL_TZ` in `.env`:
   ```bash
   LOCAL_TZ=Asia/Taipei
   ```
2. Use IANA timezone names: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
3. Common timezones:
   - `Asia/Taipei` (UTC+8)
   - `America/New_York` (UTC-5/-4)
   - `Europe/London` (UTC+0/+1)
   - `UTC` (UTC+0)

---

### "❌" (Late) Markers Incorrect

**Problem:** Events are marked as late when they shouldn't be (or vice versa).

**Cause:** Deadline timezone mismatch.

**Solution:**
Verify `deadline_local` in your case file includes correct timezone:
```yaml
deadline_local: 2025-10-06T00:00:00+08:00
#                                   ^^^^^ Timezone offset
```

Examples:
- Taiwan (UTC+8): `2025-10-06T00:00:00+08:00`
- New York (UTC-5): `2025-10-06T00:00:00-05:00`
- London (UTC+0): `2025-10-06T00:00:00+00:00`

---

## Data Interpretation Issues

### Understanding GH Archive PushEvents

**Q:** What does a GH Archive PushEvent represent?

**A:** It's the **server-side** timestamp when GitHub received the push. This is:
- ✅ Reliable and tamper-proof (recorded by GitHub)
- ✅ Independent of client-side git commit times
- ❌ May be slightly after the actual commit time (due to network delay)

**Q:** Why do I see multiple events for the same commit?

**A:** Common reasons:
- Commit was pushed multiple times
- Different branches
- Force pushes
- Repository transfers

---

### Understanding Commit Times

GitHub API returns two timestamps for each commit:

1. **author.date**: When the code was originally written (set by git client)
   - ⚠️ Can be manipulated by client
   - May be backdated or future-dated
   
2. **committer.date**: When the commit was finalized
   - ⚠️ Also can be manipulated
   - Usually same as author.date unless rebased/amended

**Most reliable timestamp:** GH Archive PushEvent `created_at` (server-side).

---

### Certificate Transparency (CT) Logs

**Q:** What does `not_before` mean?

**A:** The earliest date the SSL certificate is valid. This indicates when the domain first got an SSL certificate, suggesting when it went live.

**Q:** Why so many entries?

**A:** Each certificate renewal creates a new CT log entry. Look for the **earliest** one.

---

### urlscan.io Results

**Q:** What do urlscan results show?

**A:** Historical scans of the website by urlscan.io users or automated systems. Shows:
- When the site was first observed
- How it looked at different times
- Technologies used

**Q:** No results found?

**A:** The domain may be:
- Very new (not yet scanned)
- Private/not publicly accessible
- Not popular enough to be scanned

---

## Best Practices

### 1. Always Check Multiple Sources

Don't rely on a single timestamp. Compare:
- ✅ GH Archive (most reliable)
- ✅ GitHub API commit times
- ✅ CT logs (for websites)
- ✅ urlscan.io (for websites)
- ✅ Wayback Machine snapshots

### 2. Understand Limitations

- **GitHub commit times** can be manipulated by the client
- **CT logs** only show certificate issuance, not actual site deployment
- **urlscan** only captures when someone scanned the site
- **Wayback** only captures when Internet Archive crawled it

### 3. Document Everything

The toolkit automatically:
- ✅ Saves all raw data in `outputs/<case_slug>/`
- ✅ Records SHA256 hashes in `sources_manifest.txt`
- ✅ Logs all operations in `LOG.md`

Keep these files as evidence!

---

## Getting Help

1. **Check logs:** `outputs/<case_slug>/LOG.md`
2. **Run dependency checker:** `bash scripts/check_dependencies.sh`
3. **Verify case file:** Check YAML syntax with `yq eval cases/your_case.yaml`
4. **Test network:** `curl -I https://api.github.com`

If issue persists:
1. Collect relevant log sections
2. Note your OS and tool versions
3. Describe expected vs actual behavior
4. Open an issue with details

---

## Known Limitations

### 1. GH Archive Coverage
- Only available from 2011-02-12 onwards
- Occasional gaps due to downtime
- Only captures public repository events

### 2. API Rate Limits
- GitHub: 60/hour without token, 5000/hour with token
- urlscan: 50 scans/day (free tier)
- SecurityTrails: varies by plan

### 3. Timezone Handling
- All source timestamps are converted to UTC first
- Local timezone conversion may have edge cases around DST transitions
- Always verify timezone offsets in your case file

### 4. Windows Compatibility
- Must use Git Bash (not PowerShell or CMD)
- Path separators may cause issues in some scripts
- Some Unix tools behave differently on Windows

---

## Performance Tips

### Speed Up GH Archive Downloads
- Narrow the `date_window_utc` to only necessary dates
- GH Archive downloads are sequential (not parallel)
- Each hour file is ~50-100MB compressed

### Reduce API Calls
- Cache results by keeping `outputs/` directory
- Use `GITHUB_TOKEN` to avoid rate limits
- Don't run multiple cases simultaneously

### Handle Large Repositories
- GH Archive filters by repository, so repo size doesn't matter
- GitHub API commits endpoint is limited to 30 per call
- For very active repos, consider narrowing the date range

---

## Emergency Fallback

If automated tools fail, you can manually gather evidence:

### Manual GH Archive Check
```bash
# Download hour file
curl -sS https://data.gharchive.org/2025-10-05-15.json.gz | gunzip > events.json

# Search for your repo
grep "onion0905/Exoplanet-Playground" events.json | jq -r 'select(.type=="PushEvent")'
```

### Manual GitHub API Check
```bash
curl -H "Accept: application/vnd.github+json" \
     https://api.github.com/repos/OWNER/REPO/commits/SHA
```

### Manual CT Log Check
Visit: https://crt.sh/?q=%.yourdomain.com

### Manual urlscan Check
Visit: https://urlscan.io/search/#domain:yourdomain.com
