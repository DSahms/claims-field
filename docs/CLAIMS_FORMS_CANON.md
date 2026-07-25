# Claims suite — forms & claim-line canon

**Updated:** 2026-07-25 (autonomous pass while Dave on Windows updates)  
**Products:** A = Ledger Quest (claimant interview) · B = Claims Field (agent/camera)  
**Do not merge apps.** Share packet fields later.

Spelling: **Qwen2-VL** (not “Gwen”). Default on-device tier for B is **Qwen2-VL 2B** (OCR/VIN/docs).

---

## How many claim lines matter?

Industry volume (Verisk ClaimSearch 2025 — US):

| Line | ~2025 volume | Suite priority |
|------|----------------|----------------|
| Personal auto | ~31.6M | **P0** — A + B |
| Homeowners | ~5.27M | **P0** — A + B |
| Commercial auto | ~1.84M | **P1** — A + B |
| Commercial property | ~0.71M | **P1** — A + B |
| Workers’ comp | steady | **P1** — A (FROI); B limited (injury scene) |
| General liability | steady | **P1** — A + B (slip/fall scenes) |
| Health / disability / life | different intake | **P2** — A already has chapters; B light |

**Product A today (7):** homeowners, auto, health, workers-comp, disability, life, commercial.  
**Product B target (field-photo lines):** auto, commercial auto, homeowners, renters/personal property, commercial property, general liability, workers’ comp scene, other.

“Physical injury” is not one form — it rides under **auto BI**, **GL**, **workers’ comp (FROI)**, or **health**. Capture injury fields when the line needs them.

---

## Industry standard forms (what carriers actually expect)

These are the **ACORD loss notices** used as FNOL / first report of loss (not every carrier UI looks identical; fields map here):

| Form | Use | Product |
|------|-----|---------|
| **ACORD 1** | Property Loss Notice (home / commercial property / contents) | A interview → packet; B photos + captions |
| **ACORD 2** | Automobile Loss Notice (personal + commercial auto) | A + B |
| **ACORD 3** | General Liability Notice of Occurrence / Claim | A + B |
| **FROI / First Report of Injury** | Workers’ compensation (state-specific; CA has strict deadlines) | A heavy; B scene photos only |
| Carrier proprietary FNOL | Portal/app — same *information*, different labels | Map our packet → theirs later |
| Proof of Loss | Later in lifecycle (not first night) | Future |

California note: ACORD loss notices carry a **CA fraud warning** block. We store a `jurisdictionHints.caFraudWarning` flag on the packet — do not invent legal advice; surface the requirement.

---

## Shared information every claim needs (core FNOL)

Regardless of line:

1. **Policy** — carrier, policy #, named insured, contact phones/emails  
2. **Loss** — date, time, location (street/city/state/ZIP), narrative  
3. **Authority** — police/fire contacted? report #  
4. **People** — insured, contact person, witnesses  
5. **Damage / injury** — what was hurt (property and/or body), severity estimate  
6. **Evidence** — photos, video, receipts, official reports  
7. **Immediate actions** — mitigation, medical care, towing, temporary housing  

---

## Line-specific fields (intake essentials)

### Auto (ACORD 2 shape)

- Insured vehicle: year, make, model, body type, **VIN**, plate + state  
- Driver: name, DOB, license # + state, relation to insured, permission, purpose of use  
- Accident description; where damage can be seen; estimate amount  
- Other vehicle / property damaged; other party insurer + policy #  
- Injured persons: name, age, extent, which vehicle / pedestrian  
- Citations / violations if any  

### Property / homeowners / renters (ACORD 1 shape)

- Kind of loss: fire, theft, lightning, hail, flood, wind, water, other  
- Occupancy / habitability  
- Structure vs contents; rooms/areas  
- Probable amount of entire loss  
- Mortgagee / loss payee if known  
- Mitigation (tarp, board-up, water extract)  

### Commercial property

- Building / suite / warehouse zone  
- Inventory / equipment  
- Business interruption clues  
- Systems (HVAC, electrical, roof)  

### General liability (ACORD 3 shape)

- Occurrence vs claim made  
- Injured party / claimant identity  
- Premises description; hazard (wet floor, defect)  
- Witnesses; surveillance video existence  
- Medical treatment sought?  

### Workers’ comp (FROI — high level)

- Employer, worksite, date/time of injury  
- Body part / nature of injury  
- How injury occurred  
- Witnesses; medical provider  
- **State reporting clock** (surface in A; don’t pretend to file for them)  

### Health / disability / life (A-first)

- Provider, diagnosis narrative (claimant words), dates of service  
- Disability: onset, work status, attending physician  
- Life: decedent, cause, beneficiary contact — sensitive; interview tone locked in A  

---

## What Product A vs B each collect

| Info | A (claimant) | B (agent field) |
|------|--------------|-----------------|
| Story / empathy / completeness | Primary | Light notes |
| Photos of damage | Optional ask | **Primary** |
| VIN / OCR from plate/docs | Rare | **Qwen2-VL strength** |
| Structured ACORD-ish fields | From interview summary | From captions + agent edit |
| Sign-off | Claimant report | Agent packet export |

**Shared packet (target):** `suiteRole` A|B, `claimLine`, core FNOL block, `evidence[]`, `formHints.acord` = 1|2|3|froi.

---

## Implementation status (this pass)

- [x] Research written here  
- [x] Claims Field: expand claim lines + FNOL field map + default **Qwen2-VL 2B**  
- [ ] Product A: add renters / GL as first-class categories (later — A already has 7)  
- [ ] Real ACORD PDF fill / e-sign (later)  
- [ ] On-device LiteRT Qwen embed (later; local server path exists)

---

## Sources (non-exhaustive)

- Verisk ClaimSearch trends 2025 (auto / HO / commercial volumes)  
- ACORD 1 Property Loss Notice / ACORD 2 Automobile Loss Notice field layouts  
- Industry FNOL glossaries (ACORD 1/2/3 mapping)  
- Existing Product A chapters in `ledger-quest/src/lib/claim-data.ts`
