import 'dart:io';

import '../domain/models.dart';

/// Offline vision→text for agent field docs.
///
/// Deployment ladder (all offline when on-device):
/// 1. SmolVLM-500M — phone you already have
/// 2. SmolVLM2-2.2B — step-up, LiteRT `.litertlm` via Google AI Edge Gallery / LiteRT-LM
/// 3. Qwen2-VL-2B — alternate step-up (OCR/docs), also LiteRT
///
/// Engines:
/// - [FieldScaffoldEngine] — structured draft from photo + claim line (works offline now)
/// - [OpenAiCompatibleLocalEngine] — contract for local LiteRT-LM / OpenAI-compatible server
abstract class VlmEngine {
  VlmTier get tier;
  String get statusLabel;

  Future<VlmDescribeResult> describeDamage({
    required String imagePath,
    required ClaimLine claimLine,
    String? extraContext,
  });
}

class VlmDescribeResult {
  VlmDescribeResult({
    required this.caption,
    required this.suggestedFields,
    required this.engineNote,
    this.raw = '',
  });

  final String caption;
  final Map<String, String> suggestedFields;
  final String engineNote;
  final String raw;
}

/// Insurance-shaped prompts — same job whether 500M or 2.2B answers them.
class DamagePrompts {
  static String systemFor(ClaimLine line) => '''
You are an on-device field assistant for an insurance adjuster / agent.
Claim line: ${line.label}.
Describe ONLY what is visible. Do not invent policy coverage or liability.
Be precise: materials, location on the property/vehicle, extent, weather/water if relevant.
Flag hazards (structural, electrical, mold risk, road safety) briefly.
Output plain language an adjuster can paste into a report.
''';

  static String userFor(ClaimLine line, {String? extra}) {
    final base = switch (line) {
      ClaimLine.auto =>
        'Describe vehicle damage for a first-notice / field report: panels, glass, tires, fluids, airbags, point of impact, driveability concerns.',
      ClaimLine.homeowners =>
        'Describe property damage for a homeowners field report: room/area, materials, water/fire/storm indicators, contents vs structure, severity.',
      ClaimLine.commercial =>
        'Describe commercial property damage: building systems, inventory, business interruption clues, safety hazards.',
      ClaimLine.other =>
        'Describe the damage in this photo for an insurance field report.',
    };
    if (extra == null || extra.trim().isEmpty) return base;
    return '$base\nAgent note: $extra';
  }
}

/// Works tonight with no model: builds a claim-line checklist the agent edits.
/// When LiteRT / local server is wired, swap this for real vision captions.
class FieldScaffoldEngine implements VlmEngine {
  FieldScaffoldEngine(this.tier);

  @override
  final VlmTier tier;

  @override
  String get statusLabel =>
      'Field scaffold · ${tier.label} (edit draft; local VLM when available)';

  @override
  Future<VlmDescribeResult> describeDamage({
    required String imagePath,
    required ClaimLine claimLine,
    String? extraContext,
  }) async {
    final file = File(imagePath);
    final exists = await file.exists();
    final bytes = exists ? await file.length() : 0;
    final name = imagePath.split(RegExp(r'[\\/]')).last;
    final when = DateTime.now().toLocal().toIso8601String().split('.').first;
    final checklist = _checklistFor(claimLine);
    final agentNote = (extraContext == null || extraContext.trim().isEmpty)
        ? ''
        : '\nAgent note: ${extraContext.trim()}';

    final caption = '''
FIELD DRAFT — ${claimLine.label} · pending ${tier.label} vision
Photo: $name${exists ? ' · ${(bytes / 1024).toStringAsFixed(0)} KB' : ' · (file missing)'}
Captured / described: $when

Visible damage (edit):
$checklist
$agentNote

Hazards to confirm: structural · electrical · slip/trip · roadworthiness · mold/water
Next: complete report fields → export packet.
'''
        .trim();

    return VlmDescribeResult(
      caption: caption,
      suggestedFields: {
        'damageSummary':
            '${claimLine.label} — photo on file ($name). Agent to refine from checklist.',
        'severity': 'TBD — agent estimate after walkthrough',
        'affectedAreas': checklist.split('\n').take(3).join('; '),
        'safetyNotes': 'Confirm scene safe before further inspection.',
        'recommendedNext':
            'Complete field notes; attach evidence packet; schedule follow-up if needed.',
      },
      engineNote: statusLabel,
      raw: DamagePrompts.userFor(claimLine, extra: extraContext),
    );
  }

  String _checklistFor(ClaimLine line) => switch (line) {
        ClaimLine.auto => '''
- [ ] Point of impact / primary panel
- [ ] Glass / lights / mirrors
- [ ] Tires / wheels / fluids
- [ ] Airbags / cabin intrusion
- [ ] Driveability concern''',
        ClaimLine.homeowners => '''
- [ ] Room / elevation / exterior area
- [ ] Structure vs contents
- [ ] Water / fire / storm indicators
- [ ] Materials affected
- [ ] Temporary mitigation needed''',
        ClaimLine.commercial => '''
- [ ] Building system / suite / warehouse zone
- [ ] Inventory / equipment
- [ ] Business interruption clues
- [ ] Safety / egress impact
- [ ] Temporary mitigation''',
        ClaimLine.other => '''
- [ ] What is damaged
- [ ] Where on site
- [ ] Extent / severity cues
- [ ] Safety concerns
- [ ] Follow-up photos needed''',
      };
}

/// Prefer this name in UI/service — same as [FieldScaffoldEngine].
typedef PromptOnlyEngine = FieldScaffoldEngine;

/// Optional: local OpenAI-compatible endpoint (LiteRT-LM CLI can serve one).
/// Still offline if the server is on-box / on-LAN with no cloud.
class OpenAiCompatibleLocalEngine implements VlmEngine {
  OpenAiCompatibleLocalEngine({
    required this.tier,
    this.baseUrl = 'http://127.0.0.1:8080/v1',
    this.model = 'local-vlm',
    this.httpPost,
  });

  @override
  final VlmTier tier;
  final String baseUrl;
  final String model;

  /// Injected for tests; defaults unused until http wired in UI service.
  final Future<String> Function(Uri url, Map<String, dynamic> body)? httpPost;

  @override
  String get statusLabel => 'Local OpenAI-compatible · ${tier.label} @ $baseUrl';

  @override
  Future<VlmDescribeResult> describeDamage({
    required String imagePath,
    required ClaimLine claimLine,
    String? extraContext,
  }) async {
    throw UnimplementedError(
      'Use ClaimsFieldVlmService.describeWithLocalServer for HTTP+image.',
    );
  }
}
