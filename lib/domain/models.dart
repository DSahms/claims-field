// Claims Field (Product B) — agent-side damage documentation models.
// Sibling to Ledger Quest (Product A). Shared packet shape later — separate apps.
// Canon: ../../docs/CLAIMS_FORMS_CANON.md

/// Field-photo / FNOL lines Product B can document.
/// Aligns with ACORD 1/2/3 + FROI scene work. Health/life stay A-first.
enum ClaimLine {
  auto(
    id: 'auto',
    label: 'Personal auto',
    acordHint: 'ACORD 2',
    volumeNote: 'Highest US volume (~31M/yr)',
  ),
  commercialAuto(
    id: 'commercial-auto',
    label: 'Commercial auto',
    acordHint: 'ACORD 2',
    volumeNote: '~1.8M/yr; gig/fleet risk',
  ),
  homeowners(
    id: 'homeowners',
    label: 'Homeowners',
    acordHint: 'ACORD 1',
    volumeNote: '~5M/yr property',
  ),
  renters(
    id: 'renters',
    label: 'Renters / personal property',
    acordHint: 'ACORD 1',
    volumeNote: 'Contents-focused property',
  ),
  commercialProperty(
    id: 'commercial-property',
    label: 'Commercial property',
    acordHint: 'ACORD 1',
    volumeNote: '~0.7M/yr',
  ),
  generalLiability(
    id: 'general-liability',
    label: 'General liability',
    acordHint: 'ACORD 3',
    volumeNote: 'Slip/fall, premises, BI',
  ),
  workersComp(
    id: 'workers-comp',
    label: "Workers' comp (scene)",
    acordHint: 'FROI',
    volumeNote: 'State FROI; photos support A',
  ),
  other(
    id: 'other',
    label: 'Other / unknown',
    acordHint: 'FNOL core',
    volumeNote: 'Catch-all until line known',
  );

  const ClaimLine({
    required this.id,
    required this.label,
    required this.acordHint,
    required this.volumeNote,
  });

  final String id;
  final String label;
  final String acordHint;
  final String volumeNote;
}

/// Offline VLM product ladder — all run without cloud when deployed on-device.
enum VlmTier {
  /// What Dave already runs on an older Android phone.
  smolVlm500m(
    id: 'smolvlm-500m',
    label: 'SmolVLM 500M',
    params: '500M',
    ramHint: '~0.8–1 GB',
    notes: 'Phone baseline — efficient offline captions.',
  ),

  /// Natural step-up in the same Hugging Face family.
  smolVlm2_2b(
    id: 'smolvlm2-2.2b',
    label: 'SmolVLM2 2.2B',
    params: '2.2B',
    ramHint: '~3+ GB',
    notes: 'Same lineage, sharper descriptions + video walkthroughs.',
  ),

  /// Default for Claims Field — OCR / VIN / paperwork in frame.
  qwen2Vl2b(
    id: 'qwen2-vl-2b',
    label: 'Qwen2-VL 2B',
    params: '2B',
    ramHint: '~2–3 GB',
    notes: 'Default tier — OCR, VIN plates, docs. Offline LiteRT path.',
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

/// One FNOL-shaped field the agent should fill (or VLM suggest).
class FormFieldSpec {
  const FormFieldSpec({
    required this.key,
    required this.label,
    required this.group,
    this.hint = '',
    this.requiredForFnol = false,
  });

  final String key;
  final String label;
  final String group;
  final String hint;
  final bool requiredForFnol;
}

/// ACORD / FROI-inspired field catalogs per claim line.
class ClaimFormCatalog {
  static List<FormFieldSpec> fieldsFor(ClaimLine line) {
    final core = <FormFieldSpec>[
      const FormFieldSpec(
        key: 'policyNumber',
        label: 'Policy #',
        group: 'Policy',
        requiredForFnol: true,
      ),
      const FormFieldSpec(
        key: 'claimNumber',
        label: 'Claim # (if assigned)',
        group: 'Policy',
      ),
      const FormFieldSpec(
        key: 'insuredName',
        label: 'Named insured',
        group: 'Policy',
        requiredForFnol: true,
      ),
      const FormFieldSpec(
        key: 'lossDate',
        label: 'Date / time of loss',
        group: 'Loss',
        requiredForFnol: true,
      ),
      const FormFieldSpec(
        key: 'location',
        label: 'Location of loss',
        group: 'Loss',
        requiredForFnol: true,
        hint: 'Street, city, state, ZIP',
      ),
      const FormFieldSpec(
        key: 'lossNarrative',
        label: 'Description of loss / accident',
        group: 'Loss',
        requiredForFnol: true,
      ),
      const FormFieldSpec(
        key: 'authorityContacted',
        label: 'Police / fire contacted + report #',
        group: 'Authority',
      ),
      const FormFieldSpec(
        key: 'damageSummary',
        label: 'Damage summary',
        group: 'Damage',
        requiredForFnol: true,
      ),
      const FormFieldSpec(
        key: 'severity',
        label: 'Severity / probable amount',
        group: 'Damage',
      ),
      const FormFieldSpec(
        key: 'affectedAreas',
        label: 'Affected areas / items',
        group: 'Damage',
      ),
      const FormFieldSpec(
        key: 'safetyNotes',
        label: 'Safety / hazards',
        group: 'Safety',
      ),
      const FormFieldSpec(
        key: 'injuries',
        label: 'Injuries (who / extent)',
        group: 'Injury',
      ),
      const FormFieldSpec(
        key: 'witnesses',
        label: 'Witnesses',
        group: 'People',
      ),
      const FormFieldSpec(
        key: 'recommendedNext',
        label: 'Recommended next step',
        group: 'Next',
      ),
    ];

    final extra = switch (line) {
      ClaimLine.auto || ClaimLine.commercialAuto => const [
          FormFieldSpec(
            key: 'vehicleYearMakeModel',
            label: 'Vehicle year / make / model',
            group: 'Vehicle',
            requiredForFnol: true,
          ),
          FormFieldSpec(
            key: 'vin',
            label: 'VIN',
            group: 'Vehicle',
            hint: 'Qwen OCR target',
            requiredForFnol: true,
          ),
          FormFieldSpec(
            key: 'plate',
            label: 'Plate # + state',
            group: 'Vehicle',
          ),
          FormFieldSpec(
            key: 'driverNameLicense',
            label: 'Driver name + license # / state',
            group: 'Driver',
            requiredForFnol: true,
          ),
          FormFieldSpec(
            key: 'otherPartyVehicle',
            label: 'Other vehicle / property damaged',
            group: 'Third party',
          ),
          FormFieldSpec(
            key: 'otherInsurer',
            label: 'Other party insurer + policy #',
            group: 'Third party',
          ),
          FormFieldSpec(
            key: 'whereDamageSeen',
            label: 'Where can damage be seen?',
            group: 'Vehicle',
          ),
        ],
      ClaimLine.homeowners ||
      ClaimLine.renters ||
      ClaimLine.commercialProperty =>
        const [
          FormFieldSpec(
            key: 'kindOfLoss',
            label: 'Kind of loss',
            group: 'Property',
            hint: 'Fire, theft, wind, hail, water, lightning, flood, other',
            requiredForFnol: true,
          ),
          FormFieldSpec(
            key: 'structureVsContents',
            label: 'Structure vs contents',
            group: 'Property',
          ),
          FormFieldSpec(
            key: 'occupancy',
            label: 'Occupancy / habitability',
            group: 'Property',
          ),
          FormFieldSpec(
            key: 'mitigation',
            label: 'Mitigation done',
            group: 'Property',
            hint: 'Tarp, board-up, water extraction',
          ),
          FormFieldSpec(
            key: 'mortgagee',
            label: 'Mortgagee / loss payee',
            group: 'Property',
          ),
        ],
      ClaimLine.generalLiability => const [
          FormFieldSpec(
            key: 'premisesDescription',
            label: 'Premises / hazard description',
            group: 'Liability',
            requiredForFnol: true,
          ),
          FormFieldSpec(
            key: 'claimantParty',
            label: 'Injured / claimant party',
            group: 'Liability',
            requiredForFnol: true,
          ),
          FormFieldSpec(
            key: 'surveillance',
            label: 'Surveillance / video available?',
            group: 'Liability',
          ),
        ],
      ClaimLine.workersComp => const [
          FormFieldSpec(
            key: 'employerWorksite',
            label: 'Employer / worksite',
            group: 'WC',
            requiredForFnol: true,
          ),
          FormFieldSpec(
            key: 'bodyPartNature',
            label: 'Body part / nature of injury',
            group: 'WC',
            requiredForFnol: true,
          ),
          FormFieldSpec(
            key: 'howInjuryOccurred',
            label: 'How injury occurred',
            group: 'WC',
            requiredForFnol: true,
          ),
          FormFieldSpec(
            key: 'medicalProvider',
            label: 'Medical provider (if known)',
            group: 'WC',
          ),
        ],
      ClaimLine.other => const [],
    };

    return [...core, ...extra];
  }
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
    this.insuredName = '',
    this.location = '',
    this.lossDate = '',
    this.lossNarrative = '',
    this.authorityContacted = '',
    this.damageSummary = '',
    this.severity = '',
    this.affectedAreas = '',
    this.safetyNotes = '',
    this.injuries = '',
    this.witnesses = '',
    this.recommendedNext = '',
    this.extraFields = const {},
    this.photos = const [],
    this.vlmTier = VlmTier.qwen2Vl2b,
    this.jurisdiction = 'US-CA',
  });

  final String id;
  ClaimLine claimLine;
  final DateTime createdAt;
  String claimNumber;
  String policyNumber;
  String insuredName;
  String location;
  String lossDate;
  String lossNarrative;
  String authorityContacted;
  String damageSummary;
  String severity;
  String affectedAreas;
  String safetyNotes;
  String injuries;
  String witnesses;
  String recommendedNext;
  Map<String, String> extraFields;
  List<EvidencePhoto> photos;
  VlmTier vlmTier;
  String jurisdiction;

  Map<String, dynamic> toPacketJson() => {
        'product': 'claims-field',
        'suiteRole': 'B',
        'packetVersion': '0.2',
        'id': id,
        'claimLine': claimLine.id,
        'formHints': {
          'acord': claimLine.acordHint,
          'jurisdiction': jurisdiction,
          'caFraudWarningRequired': jurisdiction.startsWith('US-CA'),
        },
        'createdAt': createdAt.toIso8601String(),
        'claimNumber': claimNumber,
        'policyNumber': policyNumber,
        'insuredName': insuredName,
        'location': location,
        'lossDate': lossDate,
        'lossNarrative': lossNarrative,
        'authorityContacted': authorityContacted,
        'damageSummary': damageSummary,
        'severity': severity,
        'affectedAreas': affectedAreas,
        'safetyNotes': safetyNotes,
        'injuries': injuries,
        'witnesses': witnesses,
        'recommendedNext': recommendedNext,
        'extraFields': extraFields,
        'vlmTier': vlmTier.id,
        'evidence': photos.map((p) => p.toJson()).toList(),
        'fnolCompleteness': _completeness(),
      };

  Map<String, dynamic> _completeness() {
    final specs = ClaimFormCatalog.fieldsFor(claimLine);
    final required = specs.where((s) => s.requiredForFnol).toList();
    final filled = required.where((s) => _valueFor(s.key).trim().isNotEmpty);
    return {
      'requiredCount': required.length,
      'filledRequiredCount': filled.length,
      'missingRequired': [
        for (final s in required)
          if (_valueFor(s.key).trim().isEmpty) s.key,
      ],
    };
  }

  String _valueFor(String key) {
    switch (key) {
      case 'policyNumber':
        return policyNumber;
      case 'claimNumber':
        return claimNumber;
      case 'insuredName':
        return insuredName;
      case 'lossDate':
        return lossDate;
      case 'location':
        return location;
      case 'lossNarrative':
        return lossNarrative;
      case 'authorityContacted':
        return authorityContacted;
      case 'damageSummary':
        return damageSummary;
      case 'severity':
        return severity;
      case 'affectedAreas':
        return affectedAreas;
      case 'safetyNotes':
        return safetyNotes;
      case 'injuries':
        return injuries;
      case 'witnesses':
        return witnesses;
      case 'recommendedNext':
        return recommendedNext;
      default:
        return extraFields[key] ?? '';
    }
  }

  String toMarkdown() {
    final complete = _completeness();
    final buf = StringBuffer()
      ..writeln('# Claims Field Report')
      ..writeln()
      ..writeln('- **Product:** Claims Field (suite B — agent)')
      ..writeln('- **Claim line:** ${claimLine.label} (${claimLine.acordHint})')
      ..writeln('- **Claim #:** $claimNumber')
      ..writeln('- **Policy #:** $policyNumber')
      ..writeln('- **Insured:** $insuredName')
      ..writeln('- **Location:** $location')
      ..writeln('- **Loss date:** $lossDate')
      ..writeln('- **VLM tier:** ${vlmTier.label}')
      ..writeln(
          '- **FNOL required fields:** ${complete['filledRequiredCount']}/${complete['requiredCount']}')
      ..writeln()
      ..writeln('## Loss narrative')
      ..writeln(lossNarrative.isEmpty ? '_Not filled_' : lossNarrative)
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
      ..writeln('## Injuries')
      ..writeln(injuries.isEmpty ? '_None noted_' : injuries)
      ..writeln()
      ..writeln('## Witnesses')
      ..writeln(witnesses.isEmpty ? '_None noted_' : witnesses)
      ..writeln()
      ..writeln('## Authority')
      ..writeln(
          authorityContacted.isEmpty ? '_Not filled_' : authorityContacted)
      ..writeln()
      ..writeln('## Safety / hazard notes')
      ..writeln(safetyNotes.isEmpty ? '_None_' : safetyNotes)
      ..writeln()
      ..writeln('## Line-specific fields')
      ..writeln();
    if (extraFields.isEmpty) {
      buf.writeln('_None yet_');
    } else {
      for (final e in extraFields.entries) {
        buf.writeln('- **${e.key}:** ${e.value}');
      }
    }
    buf
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
    if (jurisdiction.startsWith('US-CA')) {
      buf
        ..writeln('## Jurisdiction note')
        ..writeln(
            'California fraud-warning language is required on many loss notices. '
            'This packet flags that requirement; formal ACORD PDF fill comes later.');
    }
    return buf.toString();
  }
}
