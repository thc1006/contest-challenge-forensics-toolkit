
# CLAUDE.md — Automation Plan (CLI only)

**目標**：針對 `cases/<name>.yaml` 產出 `outputs/<case_slug>/timeline.md` 與 `sources_manifest.txt`。  
**要求**：不得開啟 GUI；只用 shell/curl/jq/python。失敗要寫入 `LOG.md`。

## 執行
```bash
set -euo pipefail
cd contest-challenge-kit-full
cp -n .env.sample .env || true
make case CASE=cases/sample_case.yaml || ./scripts/run_case.sh cases/sample_case.yaml
```

## 驗收
- 報告包含：截止（UTC/Local）、GH Archive PushEvent（UTC）、GitHub commit 時間（UTC）、urlscan/CT/DNS/Wayback 摘要、逾期標記（❌）。
- 來源檔 SHA256 清單存在。
