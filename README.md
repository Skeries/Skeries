
---

## Key Data Concepts

### Measurements
- **Roof planes**: area (ft²), pitch, waste %, perimeter LF
- **Edges**: eave LF, rake LF, hip LF, ridge LF, valley LF, step/corner counts
- **Drainage**: gutters/downspouts LF & counts
- **Siding**: squares, J‑channel LF, starter strip LF, corner beads count
- **Openings**: windows/doors—flashing, drip edge
- **Attachments**: ventilation, pipe boots, satellite removal/reattach


```markdown

---

## Key Data Concepts

### Measurements
- **Roof planes**: area (ft²), pitch, waste %, perimeter LF
- **Edges**: eave LF, rake LF, hip LF, ridge LF, valley LF, step/corner counts
- **Drainage**: gutters/downspouts LF & counts
- **Siding**: squares, J‑channel LF, starter strip LF, corner beads count
- **Openings**: windows/doors—flashing, drip edge
- **Attachments**: ventilation, pipe boots, satellite removal/reattach

### Storm Event
- **Type** (hail/wind), **hail size (in)**, **wind speed (mph)**, **duration (min)**
- **Date/time**, **geocode/lat‑lon**, **radar product IDs**, **NOAA references**
- **Exposure**: slope orientation, tree cover

### Estimate
- **Line items**: description, unit, quantity, unit price, vendor_code (optional)
- **Financials**: subtotal, O&P, tax, grand total
- **Notes**: assumptions, exclusions, photographic refs

---

## Estimation Flow

1. **Ingest** measurements (`/measurements`) and storm telemetry (`/storm`).
2. **Normalize & validate** (pitch factor, unit sanity, waste).
3. **Assemble line items** via estimator + selected price list.
4. **Price & summarize** (O&P, tax, rounding).
5. **Annotate**: auto‑generated rationale + code references.
6. **QA** by Mega Bot: math check, reasonableness, missing evidence.
7. **Export**: JSON/PDF; optional adapter for Xactimate‑style codes.

---

## Rebuttal Engine (evidence‑first)

- Generates **concise, respectful** responses to common insurer positions.
- Anchored on **facts, photos, codes, manufacturer specs, and storm data**.
- Avoid absolutist language; **certainty comes from evidence**, not volume.

See `app/ai/rebuttal_templates.md` for patterns.

---

## API (FastAPI)

- `POST /estimate/build` → input (measurements + storm + pricing profile) → estimate JSON
- `POST /estimate/pdf` → returns PDF (if a renderer is attached)
- `POST /rebuttal/draft` → draft response given insurer rationale + evidence bundle
- `POST /analyze/qa` → Mega Bot review with flags (math, logic, missing docs)

Run: `uvicorn app.main:app --reload`

---

## Configuration

Edit `config.example.yaml`, copy to `config.yaml` or use env vars.

- Default waste: 10–15% based on pitch
- Default O&P: 10/10 or as configured
- Jurisdiction code set (adopted code year, ice‑barrier climate zone)

---

## Legal & Ethics

- **Do:** truth, photos, measurement logs, spec sheets, code citations.
- **Don’t:** exaggerate, promise outcomes, or “never lose.” The strongest posture is **verifiable accuracy**.
- This repo prints **defensible**, **audit‑ready** work products.

---

## Windows / PowerShell

Install PowerShell (stable) via winget on Windows:

```powershell
winget install --id Microsoft.PowerShell -e --source winget
```

Or install the preview release:

```powershell
winget install --id Microsoft.PowerShell.Preview -e --source winget
```

After installation verify:

```powershell
pwsh --version
```

Note about the repository shim

- This repository includes `bin/upsun.ps1`, a PowerShell shim that invokes the CLI entrypoint (`upsun-cli.ps1`) or a bundled executable.
- The shim prefers `pwsh` (PowerShell Core). Once `pwsh` is available you can run the shim directly from the repo root:

```powershell
# from repository root
.\bin\upsun.ps1 --help
```

If you want me to stage & commit this change to `upsun-config` and push the update to PR #5, say "commit and push" and I'll do it.
