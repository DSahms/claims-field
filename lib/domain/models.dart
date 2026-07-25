// Claims Field (Product B) — agent-side damage documentation models.
// Sibling to Ledger Quest (Product A). Shared packet shape later — separate apps.

enum ClaimLine {
  auto('auto', 'Auto'),
  homeowners('homeowners', 'Homeowners'),
  commercial('commercial', 'Commercial property'),
  other('other', 'Other');

  const ClaimLine(this.id, this.label);
  final String id;
  final String label;
}

/// Offline VLM product ladder — all run without cloud when deployed on-device.
enum VlmTier {
  /// What Dave already runs on an older Android phone.
  smolVlm500m(
    id: 'smolvlm-500m',
    label: 'SmolVLM 500M',
    params: '500M',
    ramHint: '~0.8–1 GB',
    notes: 'Current phone baseline — efficient, offline captions.',
  ),

  /// Natural step-up in the same Hugging Face family.
  smolVlm2_2b(
    id: 'smolvlm2-2.2b',
    label: 'SmolVLM2 2.2B',
    params: '2.2B',
    ramHint: '~3+ GB',
    notes: 'Same lineage, sharper descriptions + video walkthroughs. Newer phone/tablet.',
  ),

  /// Alternate offline step-up (LiteRT bundle exists for Android).
  qwen2Vl2b(
    id: 'qwen2-vl-2b',
    label: 'Qwen2-VL 2B',
    params: '2B',
    ramHint: '~2–3 GB',
    notes: 'Stronger OCR/docs; good for policy papers / VIN plates. Different family.',
  );

  const VlmTier({
    required this.id,
    required this.label,
    required this.params,
    required this.ramHint,
    required this.notes,
  });

  final String id;
  final String label;
  final String params;
  final String ramHint;
  final String notes;
}

class EvidencePhoto {
  EvidencePhoto({
    required this.id,
    required this.path,
    required this.capturedAt,
    this.caption = '',
    this.tags = const [],
  });

  final String id;
  final String path;
  final DateTime capturedAt;
  String caption;
  List<String> tags;

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'capturedAt': capturedAt.toIso8601String(),
        'caption': caption,
        'tags': tags,
      };
}

class FieldReport {
  FieldReport({
    required this.id,
    required this.claimLine,
    required this.createdAt,
    this.claimNumber = '',
    this.policyNumber = '',
    this.location = '',
    this.lossDate = '',
    this.damageSummary = '',
    this.severity = '',
    this.affectedAreas = '',
    this.safetyNotes = '',
    this.recommendedNext = '',
    this.photos = const [],
    this.vlmTier = VlmTier.smolVlm500m,
  });

  final String id;
  ClaimLine claimLine;
  final DateTime createdAt;
  String claimNumber;
  String policyNumber;
  String location;
  String lossDate;
  String damageSummary;
  String severity;
  String affectedAreas;
  String safetyNotes;
  String recommendedNext;
  List<EvidencePhoto> photos;
  VlmTier vlmTier;

  Map<String, dynamic> toPacketJson() => {
        'product': 'claims-field',
        'suiteRole': 'B', // agent documentation
        'packetVersion': '0.1',
        'id': id,
        'claimLine': claimLine.id,
        'createdAt': createdAt.toIso8601String(),
        'claimNumber': claimNumber,
        'policyNumber': policyNumber,
        'location': location,
        'lossDate': lossDate,
        'damageSummary': damageSummary,
        'severity': severity,
        'affectedAreas': affectedAreas,
        'safetyNotes': safetyNotes,
        'recommendedNext': recommendedNext,
        'vlmTier': vlmTier.id,
        'evidence': photos.map((p) => p.toJson()).toList(),
      };

  String toMarkdown() {
    final buf = StringBuffer()
      ..writeln('# Claims Field Report')
      ..writeln()
      ..writeln('- **Product:** Claims Field (suite B — agent)')
      ..writeln('- **Claim line:** ${claimLine.label}')
      ..writeln('- **Claim #:** $claimNumber')
      ..writeln('- **Policy #:** $policyNumber')
      ..writeln('- **Location:** $location')
      ..writeln('- **Loss date:** $lossDate')
      ..writeln('- **VLM tier:** ${vlmTier.label}')
      ..writeln()
      ..writeln('## Damage summary')
      ..writeln(damageSummary.isEmpty ? '_Not filled_' : damageSummary)
      ..writeln()
      ..writeln('## Severity')
      ..writeln(severity.isEmpty ? '_Not filled_' : severity)
      ..writeln()
      ..writeln('## Affected areas / items')
      ..writeln(affectedAreas.isEmpty ? '_Not filled_' : affectedAreas)
      ..writeln()
      ..writeln('## Safety / hazard notes')
      ..writeln(safetyNotes.isEmpty ? '_None_' : safetyNotes)
      ..writeln()
      ..writeln('## Recommended next step')
      ..writeln(recommendedNext.isEmpty ? '_None_' : recommendedNext)
      ..writeln()
      ..writeln('## Evidence (${photos.length})');
    for (var i = 0; i < photos.length; i++) {
      final p = photos[i];
      buf
        ..writeln('### Photo ${i + 1}')
        ..writeln('- Path: `${p.path}`')
        ..writeln('- Caption: ${p.caption.isEmpty ? '_pending_' : p.caption}')
        ..writeln();
    }
    return buf.toString();
  }
}
