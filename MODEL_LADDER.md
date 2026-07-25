# Claims Field — Offline VLM ladder

**Product B** of the Claims suite (agent / adjuster). Fully offline when on-device.

Dave’s phone already runs **SmolVLM-500M-Instruct**. There *is* a step-up in the same family, plus a strong alternate.

## Ladder

| Tier | Model | Params | RAM (ballpark) | Offline? | Role for us |
|------|--------|--------|----------------|----------|-------------|
| **Baseline** | HuggingFaceTB/SmolVLM-500M-Instruct (or SmolVLM2-500M) | 500M | ~0.8–1 GB | Yes | What you have now — efficient captions |
| **Step-up (same line)** | HuggingFaceTB/SmolVLM2-2.2B-Instruct | 2.2B | ~3+ GB | Yes | Sharper damage descriptions; video walk-around |
| **Alt step-up** | Qwen/Qwen2-VL-2B-Instruct | 2B | ~2–3 GB | Yes | Better OCR / VIN / paperwork in frame |

All three have **LiteRT** (`.litertlm`) community bundles for Android via Google AI Edge Gallery — prove quality on-phone before we embed native inference in this Flutter app.

## How to validate the step-up on a phone (no app build required)

1. Install **Google AI Edge Gallery** (recent build).
2. Import e.g. `litert-community/SmolVLM2-2.2B` `.litertlm` (enable **Support image**).
3. Ask Image: attach a dented bumper / wet ceiling photo + our damage prompt.
4. Compare answers vs your 500M app — if 2.2B is clearly better and still usable on that device, that’s the agent-tier default.

## In this Flutter app today

- Camera / gallery evidence (auto-describe after capture)
- Claim-line field scaffolds (auto / homeowners / commercial) — editable drafts offline now
- Tier picker (records which model the packet expects)
- Optional **local OpenAI-compatible server** (LiteRT-LM CLI on PC/LAN — still offline if no cloud)
- Real on-device LiteRT embed still next; scaffold keeps the agent loop moving
- Export MD + JSON packet (`suiteRole: B`) for later merge with Product A

## Not in scope for B

- Claimant interview → **ledger-quest** (Product A / GLM sandbox)
- Cloud vision APIs as the primary path (local-first)
