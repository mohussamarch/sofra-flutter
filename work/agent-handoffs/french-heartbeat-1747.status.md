# French Wikibooks heartbeat status

- Batch 1: exit 0, 10 requests, +122 source pages, +81 parsed.
- Batch 2: exit 1 after 2 requests; HTTP 429 at 18:04:40.525Z. Stopped immediately.
- Current: 874 raw pages / 621 parsed; +122/+81 from 5a60180. Parsed arrays: 4,090 ingredients and 3,794 steps (+533/+584).
- Current parsed numeric amounts/units: 0/0; runtime-ready: 0. Distinct source category labels: raw 180→199→208 (625→752→874 pages); parsed 142→163→165 (450→540→621 recipes), snapshots 2d184e9→5a60180→current. No cuisine inference.
- Cumulative API requests 65→77; 49 IDs pending; source not exhausted.
- Raw first-752-record prefix matches prior SHA. Parsed comparison by recordId against 5a60180: 540 prior records, 0 missing/changed, 81 new; current full hashes match manifest.
- No lock/process remains. Gate: 2026-10-13T18:14:40.525Z. See full handoff for prefix details.
