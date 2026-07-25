# Claims Field (Product B)

**Agent / adjuster** damage documentation — camera + offline vision language models.  
**Not** the claimant interview. That is Product A: `../ledger-quest/`.

| | A — Ledger Quest | **B — Claims Field (this app)** |
|---|---|---|
| Who | Customer whose stuff is damaged | Insurance agent documenting the scene |
| Job | Warm interview → report | Photos + VLM captions → fill report fields |
| Stack | Next.js web | **Flutter** (Windows + Android) |
| Brain | Venice (sandbox) | SmolVLM ladder **offline** |

**GitHub:** https://github.com/DSahms/claims-field

## Tonight flow (no beta marathon)

1. `flutter run -d windows` (or Android phone)
2. **Evidence** → gallery or camera
3. Auto field draft fills caption + report starters (edit freely)
4. Optional: flip **Use local VLM server** when LiteRT-LM / OpenAI-compatible vision is on `:8080`
5. Export packet (markdown + JSON)

## Offline model ladder

See [MODEL_LADDER.md](./MODEL_LADDER.md).

- **500M** — your current phone (efficient)
- **SmolVLM2 2.2B** — step-up, same family, still offline
- **Qwen2-VL 2B** — alternate offline step-up (OCR)

## Run

```powershell
cd "D:\dev\The Ledger Series\claims-field"
flutter pub get
flutter run -d windows   # or an Android device
```

Build Android APK when ready:

```powershell
flutter build apk --debug
```

## Company

AI Integration and Consulting LLC — Claims suite under The Ledger Series. Do not merge A and B into one app; share export packets later.
