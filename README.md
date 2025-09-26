
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
"""

open(os.path.join(base, "README.md"), "w").write(readme)

# config.example.yaml
config_yaml = """# Example configuration
environment: development
pricing:
  default_price_list: 'regional-IL-WI-2025Q3'
  overhead_pct: 10
  profit_pct: 10
  tax_pct: 7.5
assumptions:
  default_waste_pct_by_pitch:
    low: 7
    medium: 10
    steep: 15
codes:
  adopted_building_code_year: 2018
  ice_barrier_zone: true
"""
open(os.path.join(base, "config.example.yaml"), "w").write(config_yaml)

# app/config.py
config_py = """from pydantic import BaseSettings
from functools import lru_cache
import yaml, os

class Settings(BaseSettings):
    environment: str = "development"
    default_price_list: str = "regional-IL-WI-2025Q3"
    overhead_pct: float = 10.0
    profit_pct: float = 10.0
    tax_pct: float = 7.5

@lru_cache()
def get_settings():
    s = Settings()
    # Optionally merge YAML
    path = os.getenv("APP_CONFIG", "config.yaml")
    if os.path.exists(path):
        with open(path, "r") as f:
            y = yaml.safe_load(f) or {}
        s.default_price_list = y.get("pricing", {}).get("default_price_list", s.default_price_list)
        s.overhead_pct = float(y.get("pricing", {}).get("overhead_pct", s.overhead_pct))
        s.profit_pct = float(y.get("pricing", {}).get("profit_pct", s.profit_pct))
        s.tax_pct = float(y.get("pricing", {}).get("tax_pct", s.tax_pct))
    return s
"""
open(os.path.join(base, "app", "config.py"), "w").write(config_py)

# app/models.py
models_py = """from pydantic import BaseModel, Field, validator
from typing import List, Optional

class EdgeLF(BaseModel):
    eave: float = 0.0
    rake: float = 0.0
    hip: float = 0.0
    ridge: float = 0.0
    valley: float = 0.0
    gutter: float = 0.0
    downspouts: int = 0

class RoofPlane(BaseModel):
    area_ft2: float
    pitch: str = Field(..., description='low|medium|steep')
    perimeter_lf: float = 0.0
    waste_pct: Optional[float] = None

class Siding(BaseModel):
    squares: float = 0.0
    j_channel_lf: float = 0.0
    starter_strip_lf: float = 0.0
    corner_beads: int = 0

class StormEvent(BaseModel):
    kind: str = Field(..., description='hail|wind|other')
    hail_size_in: Optional[float] = None
    wind_speed_mph: Optional[float] = None
    duration_min: Optional[int] = None
    occurred_at: str
    lat: float
    lon: float
    radar_refs: Optional[list[str]] = None

class LineItem(BaseModel):
    description: str
    unit: str
    quantity: float
    unit_price: float
    vendor_code: Optional[str] = None
    notes: Optional[str] = None

class Estimate(BaseModel):
    items: List[LineItem]
    subtotal: float
    overhead: float
    profit: float
    tax: float
    total: float
    notes: Optional[str] = None

class MeasurementBundle(BaseModel):
    roof_planes: List[RoofPlane] = []
    edges: EdgeLF = EdgeLF()
    siding: Optional[Siding] = None
    openings: Optional[dict] = None
"""
open(os.path.join(base, "app", "models.py"), "w").write(models_py)

# app/utils/geometry.py
geometry_py = """from math import ceil

def squares_from_area_ft2(area_ft2: float, waste_pct: float = 10.0) -> float:
    base = area_ft2 / 100.0
    return round(base * (1 + waste_pct/100.0), 2)

def pitch_factor(pitch: str) -> float:
    lookup = {'low': 1.00, 'medium': 1.06, 'steep': 1.12}
    return lookup.get(pitch, 1.06)

def adjusted_area(area_ft2: float, pitch: str, waste_pct: float|None) -> float:
    pf = pitch_factor(pitch)
    wp = waste_pct if waste_pct is not None else 10.0
    return round(area_ft2 * pf * (1 + wp/100.0), 2)

def lf_to_count(lf: float, stick_len: float) -> int:
    return ceil(max(lf, 0.0) / stick_len)
"""
open(os.path.join(base, "app", "utils", "geometry.py"), "w").write(geometry_py)

# app/utils/validators.py
validators_py = """def positive(value: float, name: str):
    if value < 0:
        raise ValueError(f\"{name} must be >= 0\")
    return value

def assert_reasonable_pitch(pitch: str):
    if pitch not in ('low','medium','steep'):
        raise ValueError('pitch must be low|medium|steep')
"""
open(os.path.join(base, "app", "utils", "validators.py"), "w").write(validators_py)

# app/estimators/pricing_engine.py
pricing_engine_py = """from typing import List, Optional
from ..models import LineItem, Estimate
from ..config import get_settings

def sum_items(items: List[LineItem]) -> float:
    return round(sum(i.quantity * i.unit_price for i in items), 2)

def build_totals(items: List[LineItem], tax_pct: Optional[float]=None) -> Estimate:
    s = get_settings()
    subtotal = sum_items(items)
    overhead = round(subtotal * (s.overhead_pct/100.0), 2)
    profit = round((subtotal + overhead) * (s.profit_pct/100.0), 2)
    tax_rate = (tax_pct if tax_pct is not None else s.tax_pct)/100.0
    tax = round((subtotal + overhead + profit) * tax_rate, 2)
    total = round(subtotal + overhead + profit + tax, 2)
    return Estimate(items=items, subtotal=subtotal, overhead=overhead, profit=profit, tax=tax, total=total)
"""
open(os.path.join(base, "app", "estimators", "pricing_engine.py"), "w").write(pricing_engine_py)

# app/estimators/xactimate_adapter.py
xactimate_adapter_py = """# Note: This file defines a *pluggable* mapping from your internal line items
# to vendor-specific code books (e.g., Xactimate). Keep the mapping in YAML
# or a database so you can update it without redeploying code.

from typing import Dict

# Example static mapping. Replace with your real codes.
EXAMPLE_MAP: Dict[str, str] = {
    "Remove & replace asphalt shingles (per square)": "RFG-ASPH-R&R-SQ",
    "Ice & water shield (LF)": "RFG-ICEW-LF",
    "Drip edge (LF)": "RFG-DRIP-LF",
    "Starter (LF)": "RFG-START-LF",
    "Ridge cap (LF)": "RFG-RIDG-LF",
    "Gutter (LF)": "GUT-INST-LF",
    "Downspout (EA)": "GUT-DSPT-EA",
    "Siding (per square)": "SID-RPL-SQ",
    "J-channel (LF)": "SID-JCHN-LF",
    "Corner bead (EA)": "SID-CNRB-EA"
}

def map_description_to_vendor_code(description: str) -> str|None:
    return EXAMPLE_MAP.get(description)
"""
open(os.path.join(base, "app", "estimators", "xactimate_adapter.py"), "w").write(xactimate_adapter_py)

# app/ai/prompts.py
prompts_py = """SYSTEM_SUPERVISOR = '''
You are the MEGA AI Supervisor for a roofing-insurance estimation platform.
Your duties:
1) verify math and measurement logic,
2) demand evidence for every claim,
3) flag missing photos, code citations, or manufacturer specs,
4) keep tone professional and non-adversarial,
5) produce outputs that are concise, factual, and defensible.
Never invent measurements or code references. Always ask for the exact source.
'''

REBUTTAL_STYLE = '''
Respectful, technical, evidence-forward. Avoid absolutist language.
Structure:
- Summary of insurer position
- Evidence table (photos, measurements, code/spec citations)
- Technical analysis (why repair/replace is required)
- Cost impact summary (line items, quantities, prices)
- Closing request (clear ask)
'''
"""
open(os.path.join(base, "app", "ai", "prompts.py"), "w").write(prompts_py)

# app/ai/orchestrator.py
orchestrator_py = """from .prompts import SYSTEM_SUPERVISOR, REBUTTAL_STYLE

class MegaSupervisor:
    def __init__(self, llm=None):
        self.llm = llm  # inject your model client

    def review_estimate(self, estimate_json: dict, evidence: dict) -> dict:
        # Pseudo-logic for where you'd call the LLM
        # Return structured findings
        findings = {
            "math_check": "passed",
            "logic_flags": [],
            "missing_evidence": [],
            "notes": "All quantities linked to measurements. Provide shingle spec sheet in appendix."
        }
        return findings

    def draft_rebuttal(self, insurer_position: str, evidence_bundle: dict) -> str:
        # Use REBUTTAL_STYLE to structure the response; plug into your LLM of choice.
        return f\"\"\"\
Summary of insurer position:
{insurer_position}

Evidence:
- Photos: {len(evidence_bundle.get('photos', []))}
- Measurements: present
- Codes/specs: cite as numbered list

Technical analysis:
Explain why scope is required based on damage patterns and manufacturer/codes.

Cost impact:
Reference line items + quantities + extended totals.

Request:
Please reconsider scope and pricing as outlined above; see attached exhibits.
\"\"\"
"""
open(os.path.join(base, "app", "ai", "orchestrator.py"), "w").write(orchestrator_py)

# app/ai/rebuttal_templates.md
rebuttals_md = """# Rebuttal Templates (Evidence-First)

## Hail impact – shingle & accessory replacement
- **Insurer position**: cosmetic, limited slope repairs only.
- **Evidence**: slope-by-slope photo grids; test squares; brittle test videos; manufacturer spec showing loss of granules exposes mat; code requiring uniformity on plane.
- **Analysis**: intermingling old/new violates manufacturer uniform appearance; compromised mat cannot be sealed reliably.
- **Ask**: full plane replacement for slopes A/C; accessories (ridge, starter, drip edge) per LF.

## Wind creasing – tab uplift
- Position: repairable.
- Evidence: high-speed video of uplift, nails withdrawn; NOAA wind at {mph} mph sustained, gusts {mph_max}.
- Analysis: sealed tab failure exceeds repair tolerance; slope uniformity issues.
- Ask: replace affected slopes + accessories.

Always include: photo index, measurement tables, code refs, manufacturer spec excerpts.
"""
open(os.path.join(base, "app", "ai", "rebuttal_templates.md"), "w").write(rebuttals_md)

# app/schemas/measurement.schema.json
measurement_schema = {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "MeasurementBundle",
  "type": "object",
  "properties": {
    "roof_planes": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "area_ft2": {"type": "number"},
          "pitch": {"type": "string", "enum": ["low", "medium", "steep"]},
          "perimeter_lf": {"type": "number"},
          "waste_pct": {"type": ["number", "null"]}
        },
        "required": ["area_ft2", "pitch"]
      }
    },
    "edges": {
      "type": "object",
      "properties": {
        "eave": {"type": "number"},
        "rake": {"type": "number"},
        "hip": {"type": "number"},
        "ridge": {"type": "number"},
        "valley": {"type": "number"},
        "gutter": {"type": "number"},
        "downspouts": {"type": "integer"}
      }
    },
    "siding": {
      "type": ["object", "null"],
      "properties": {
        "squares": {"type": "number"},
        "j_channel_lf": {"type": "number"},
        "starter_strip_lf": {"type": "number"},
        "corner_beads": {"type": "integer"}
      }
    }
  },
  "required": ["roof_planes", "edges"]
}
open(os.path.join(base, "app", "schemas", "measurement.schema.json"), "w").write(json.dumps(measurement_schema, indent=2))

# app/schemas/estimate.schema.json
estimate_schema = {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Estimate",
  "type": "object",
  "properties": {
    "items": {"type": "array"},
    "subtotal": {"type": "number"},
    "overhead": {"type": "number"},
    "profit": {"type": "number"},
    "tax": {"type": "number"},
    "total": {"type": "number"},
    "notes": {"type": ["string", "null"]}
  },
  "required": ["items", "subtotal", "overhead", "profit", "tax", "total"]
}
open(os.path.join(base, "app", "schemas", "estimate.schema.json"), "w").write(json.dumps(estimate_schema, indent=2))

# app/main.py
main_py = """from fastapi import FastAPI, HTTPException
from .models import MeasurementBundle, StormEvent, LineItem
from .estimators.pricing_engine import build_totals
from .estimators.xactimate_adapter import map_description_to_vendor_code
from .utils.geometry import adjusted_area, squares_from_area_ft2

app = FastAPI(title="Roof-Insure Origin")

@app.post("/estimate/build")
def build_estimate(measurements: MeasurementBundle, storm: StormEvent, region: str = "IL-WI"):
    items = []

    # Example: compute shingles per square from planes
    total_adjusted_area = sum(adjusted_area(p.area_ft2, p.pitch, p.waste_pct) for p in measurements.roof_planes)
    shingles_squares = round(total_adjusted_area / 100.0, 2)
    items.append(LineItem(
        description="Remove & replace asphalt shingles (per square)",
        unit="SQ",
        quantity=shingles_squares,
        unit_price=300.00, # placeholder
        vendor_code=map_description_to_vendor_code("Remove & replace asphalt shingles (per square)")
    ))

    # Accessories from edges
    if measurements.edges.gutter > 0:
        items.append(LineItem(
            description="Gutter (LF)",
            unit="LF",
            quantity=measurements.edges.gutter,
            unit_price=8.50,
            vendor_code=map_description_to_vendor_code("Gutter (LF)")
        ))
    if measurements.edges.downspouts > 0:
        items.append(LineItem(
            description="Downspout (EA)",
            unit="EA",
            quantity=measurements.edges.downspouts,
            unit_price=45.0,
            vendor_code=map_description_to_vendor_code("Downspout (EA)")
        ))

    estimate = build_totals(items)
    return estimate

@app.post("/rebuttal/draft")
def rebuttal_draft(payload: dict):
    insurer_position = payload.get("insurer_position", "")
    # In production, call MegaSupervisor.llm; here we return structured draft
    return {
        "summary": insurer_position,
        "required_evidence": ["photo grid by slope", "test squares", "manufacturer spec", "adopted code citation"],
        "outline": ["Summary", "Evidence Table", "Technical Analysis", "Cost Impact", "Request"]
    }
"""
open(os.path.join(base, "app", "main.py"), "w").write(main_py)

# docs/playbook.md
playbook = """# Operations Playbook

## Intake
- Require measurement JSON + storm JSON + photo bundle index.
- Validate with schema; reject missing slopes or edges.

## Estimating QA
- Pitch factor applied?
- Waste within configured bounds?
- Edges mapped to correct accessories?

## Rebuttal QA
- Is each claim supported by photo + code/spec?
- Avoid absolutist language; cite sources.
- Close with a clear, reasonable request.
"""
open(os.path.join(base, "docs", "playbook.md"), "w").write(playbook)

# scripts/calc_example.py
calc_example = """import json
from app.models import MeasurementBundle, StormEvent
from app.main import build_estimate

measurements = MeasurementBundle.parse_obj({
  "roof_planes":[{"area_ft2": 2500, "pitch":"medium", "perimeter_lf": 210, "waste_pct": 10}],
  "edges":{"eave":120,"rake":90,"hip":0,"ridge":30,"valley":20,"gutter":100,"downspouts":4}
})
storm = StormEvent.parse_obj({
  "kind":"hail","hail_size_in":1.25,"duration_min":12,"occurred_at":"2025-06-10T18:42:00Z",
  "lat":42.68,"lon":-89.02
})

print(build_estimate(measurements, storm))
"""
open(os.path.join(base, "scripts", "calc_example.py"), "w").write(calc_example)

# Zip the scaffold
zip_path = "/mnt/data/roof-insure-origin.zip"
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
    for root, _, files in os.walk(base):
        for f in files:
            full = os.path.join(root, f)
            arc = os.path.relpath(full, base)
            z.write(full, arc)

zip_path
