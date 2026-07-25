# Autonomous pass — 2026-07-25 (~5am)

Dave away for Windows updates. Work landed and pushed.

## Done

1. **Qwen2-VL 2B** set as default VLM tier in Claims Field (not “Gwen”).
2. **Forms research** → `docs/CLAIMS_FORMS_CANON.md` (also in A + B repos).
3. Expanded B claim lines to 8 (auto, commercial auto, HO, renters, commercial property, GL, WC scene, other).
4. ACORD/FROI-shaped FNOL fields + **FNOL x/y required** badge + export gap warning.
5. Packet version **0.2** with `formHints.acord` + CA fraud-warning flag.
6. Pushed: https://github.com/DSahms/claims-field · https://github.com/DSahms/ledger-quest

## Volume reality (US 2025)

Personal auto dwarfs everything (~31M). Then HO (~5M), commercial auto (~1.8M), commercial property (~0.7M). Injury isn’t one form — it’s auto BI / GL / WC / health.

## Next when Dave returns

- Rebuild Windows app to see new UI: `flutter run -d windows`
- Validate Qwen in Google AI Edge Gallery on phone
- Later: LiteRT embed; renters/GL chapters in Product A; real ACORD PDF fill
