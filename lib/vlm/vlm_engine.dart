import 'dart:io';

import '../domain/models.dart';

/// Offline vision→text for agent field docs.
///
/// Deployment ladder (all offline when on-device):
/// 1. SmolVLM-500M — phone baseline
/// 2. SmolVLM2-2.2B — step-up same family
/// 3. Qwen2-VL-2B — **default** (OCR / VIN / docs)
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

class DamagePrompts {
  static String systemFor(ClaimLine line) => '''
You are an on-device field assistant for an insurance adjuster / agent.
Claim line: ${line.label} (${line.acordHint}).
Describe ONLY what is visible. Do not invent policy coverage or liability.
Be precise: materials, location, extent, weather/water if relevant.
For auto: call out VIN/plate text if readable (OCR).
Flag hazards briefly.
Output plain language an adjuster can paste into a ${line.acordHint} / FNOL draft.
''';

  static String userFor(ClaimLine line, {String? extra}) {
    final base = switch (line) {
      ClaimLine.auto || ClaimLine.commercialAuto =>
        'Describe vehicle damage for ACORD 2 / field report: panels, glass, tires, fluids, airbags, point of impact, driveability. Read VIN or plate if visible.',
      ClaimLine.homeowners || ClaimLine.renters =>
        'Describe property/contents damage for ACORD 1: room/area, materials, water/fire/storm indicators, contents vs structure, severity.',
      ClaimLine.commercialProperty =>
        'Describe commercial property damage: building systems, inventory, business interruption clues, safety hazards.',
      ClaimLine.generalLiability =>
        'Describe the premises / hazard for ACORD 3: floor condition, defects, lighting, what a claimant might have contacted, evidence of injury scene.',
      ClaimLine.workersComp =>
        'Describe the worksite injury scene for FROI support: equipment, body-position clues, hazards — do not diagnose.',
      ClaimLine.other =>
        'Describe the damage in this photo for an insurance field report / FNOL.',
    };
    if (extra == null || extra.trim().isEmpty) return base;
    return '$base\nAgent note: $extra';
  }
}

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
    final file = await _fileMeta(imagePath);
    final checklist = _checklistFor(claimLine);
    final agentNote = (extraContext == null || extraContext.trim().isEmpty)
        ? ''
        : '\nAgent note: ${extraContext.trim()}';
    final when = DateTime.now().toLocal().toIso8601String().split('.').first;

    final caption = '''
FIELD DRAFT — ${claimLine.label} · ${claimLine.acordHint} · pending ${tier.label}
Photo: ${file['name']}${file['meta']}
Captured / described: $when

Visible damage (edit):
$checklist
$agentNote

Hazards to confirm: structural · electrical · slip/trip · roadworthiness · mold/water
OCR targets (Qwen): VIN · plate · labels · paperwork in frame
Next: fill required FNOL fields → export packet.
'''
        .trim();

    final suggested = <String, String>{
      'damageSummary':
          '${claimLine.label} — photo on file (${file['name']}). Agent to refine from checklist.',
      'severity': 'TBD — agent estimate after walkthrough',
      'affectedAreas': checklist.split('\n').take(3).join('; '),
      'safetyNotes': 'Confirm scene safe before further inspection.',
      'recommendedNext':
          'Complete ${claimLine.acordHint} FNOL fields; attach evidence; schedule follow-up if needed.',
      'lossNarrative': 'Pending agent narrative from walkthrough / interview packet A.',
    };

    if (claimLine == ClaimLine.auto ||
        claimLine == ClaimLine.commercialAuto) {
      suggested['vehicleYearMakeModel'] = 'TBD from photo / registration';
      suggested['vin'] = 'OCR with Qwen when plate/VIN in frame';
    }
    if (claimLine == ClaimLine.homeowners ||
        claimLine == ClaimLine.renters ||
        claimLine == ClaimLine.commercialProperty) {
      suggested['kindOfLoss'] = 'TBD — fire / water / wind / theft / other';
    }

    return VlmDescribeResult(
      caption: caption,
      suggestedFields: suggested,
      engineNote: statusLabel,
      raw: DamagePrompts.userFor(claimLine, extra: extraContext),
    );
  }

  Future<Map<String, String>> _fileMeta(String imagePath) async {
    final file = File(imagePath);
    final exists = await file.exists();
    final bytes = exists ? await file.length() : 0;
    final name = imagePath.split(RegExp(r'[\\/]')).last;
    return {
      'name': name,
      'meta': exists ? ' · ${(bytes / 1024).toStringAsFixed(0)} KB' : ' · (file missing)',
    };
  }

  String _checklistFor(ClaimLine line) => switch (line) {
        ClaimLine.auto || ClaimLine.commercialAuto => '''
- [ ] Point of impact / primary panel
- [ ] Glass / lights / mirrors
- [ ] Tires / wheels / fluids
- [ ] Airbags / cabin intrusion
- [ ] VIN / plate readable?
- [ ] Driveability concern''',
        ClaimLine.homeowners || ClaimLine.renters => '''
- [ ] Room / elevation / exterior area
- [ ] Structure vs contents
- [ ] Water / fire / storm indicators
- [ ] Materials affected
- [ ] Temporary mitigation needed''',
        ClaimLine.commercialProperty => '''
- [ ] Building system / suite / warehouse zone
- [ ] Inventory / equipment
- [ ] Business interruption clues
- [ ] Safety / egress impact
- [ ] Temporary mitigation''',
        ClaimLine.generalLiability => '''
- [ ] Premises condition / hazard
- [ ] Lighting / signage
- [ ] Claimant contact point
- [ ] Witness / camera vantage
- [ ] Immediate cleanup / changes to scene''',
        ClaimLine.workersComp => '''
- [ ] Worksite / equipment involved
- [ ] Body-part clues (no diagnosis)
- [ ] Guarding / PPE visible?
- [ ] Witness vantage
- [ ] Scene preserved?''',
        ClaimLine.other => '''
- [ ] What is damaged
- [ ] Where on site
- [ ] Extent / severity cues
- [ ] Safety concerns
- [ ] Follow-up photos needed''',
      };
}

typedef PromptOnlyEngine = FieldScaffoldEngine;

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
