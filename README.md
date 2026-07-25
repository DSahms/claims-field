# Claims Field (Product B)

**Agent / adjuster** damage documentation — camera + offline vision language models.  
**Not** the claimant interview. That is Product A: `../ledger-quest/`.

| | A — Ledger Quest | **B — Claims Field (this app)** |
|---|---|---|
| Who | Customer whose stuff is damaged | Insurance agent documenting the scene |
| Job | Warm interview → report | Photos + VLM captions → fill report fields |
| Stack | Next.js web | **Flutter** (Windows + Android) |
| Brain | Venice (sandbox) | **Qwen2-VL 2B** default · SmolVLM ladder offline |

**GitHub:** https://github.com/DSahms/claims-field  
**Default VLM:** Qwen2-VL 2B (OCR / VIN)  
**Forms canon:** [docs/CLAIMS_FORMS_CANON.md](./docs/CLAIMS_FORMS_CANON.md) (ACORD 1/2/3 + FROI)

## Claim lines (Product B)

Personal auto · Commercial auto · Homeowners · Renters/personal property · Commercial property · General liability · Workers’ comp (scene) · Other

## Flow

1. `flutter run -d windows` (or Android phone)
2. Pick claim line → **Evidence** → gallery or camera
3. Auto field draft fills caption + FNOL starters (edit freely)
4. Watch **FNOL x/y required** in the app bar; export warns on gaps
5. Optional: flip **Use local VLM server** when LiteRT-LM vision is on `:8080`

## Offline model ladder

See [MODEL_LADDER.md](./MODEL_LADDER.md).

- **Qwen2-VL 2B** — default (OCR / paperwork)
- **500M** — older phone baseline
- **SmolVLM2 2.2B** — same-family step-up

## Run

```powershell
cd "D:\dev\The Ledger Series\claims-field"
flutter pub get
flutter run -d windows
```

## Company

AI Integration and Consulting LLC — Claims suite under The Ledger Series. Do not merge A and B; share export packets later.
