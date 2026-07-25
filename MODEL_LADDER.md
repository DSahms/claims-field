# Claims Field — Offline VLM ladder

**Product B** of the Claims suite (agent / adjuster). Fully offline when on-device.

**Default tier in the app: Qwen2-VL 2B** (OCR / VIN / paperwork). Dave’s phone also runs SmolVLM-500M.

## Ladder

| Tier | Model | Params | RAM (ballpark) | Offline? | Role for us |
|------|--------|--------|----------------|----------|-------------|
| **Default** | Qwen/Qwen2-VL-2B-Instruct | 2B | ~2–3 GB | Yes | OCR, VIN plates, docs in frame |
| **Baseline** | HuggingFaceTB/SmolVLM-500M-Instruct | 500M | ~0.8–1 GB | Yes | Older phone — efficient captions |
| **Step-up (same line)** | HuggingFaceTB/SmolVLM2-2.2B-Instruct | 2.2B | ~3+ GB | Yes | Sharper damage descriptions; video |

All three have **LiteRT** (`.litertlm`) community bundles for Android via Google AI Edge Gallery — prove quality on-phone before we embed native inference in this Flutter app.

## How to validate on a phone (no app build required)

1. Install **Google AI Edge Gallery**.
2. Import Qwen2-VL-2B or SmolVLM2-2.2B `.litertlm` (enable **Support image**).
3. Ask Image: dented bumper / wet ceiling / VIN plate + our damage prompt.
4. Prefer Qwen when OCR matters; SmolVLM2 when narrative damage description is stronger on that device.

## In this Flutter app today

- Camera / gallery evidence (auto-describe after capture)
- 8 claim lines with ACORD/FROI-shaped FNOL fields + completeness badge
- Default tier **Qwen2-VL 2B**
- Optional local OpenAI-compatible server
- Export MD + JSON packet (`suiteRole: B`, `packetVersion: 0.2`)
- Forms canon: [docs/CLAIMS_FORMS_CANON.md](./docs/CLAIMS_FORMS_CANON.md)

## Not in scope for B

- Claimant interview → **ledger-quest** (Product A)
- Cloud vision APIs as the primary path (local-first)
