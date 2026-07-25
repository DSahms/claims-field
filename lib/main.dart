import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'domain/models.dart';
import 'services/vlm_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClaimsFieldApp());
}

class ClaimsFieldApp extends StatelessWidget {
  const ClaimsFieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Claims Field',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B3A4B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const FieldHomePage(),
    );
  }
}

class FieldHomePage extends StatefulWidget {
  const FieldHomePage({super.key});

  @override
  State<FieldHomePage> createState() => _FieldHomePageState();
}

class _FieldHomePageState extends State<FieldHomePage> {
  final _vlm = ClaimsFieldVlmService();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  late FieldReport _report;
  final _claimCtrl = TextEditingController();
  final _policyCtrl = TextEditingController();
  final _insuredCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _lossCtrl = TextEditingController();
  final _narrativeCtrl = TextEditingController();
  final _authorityCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _severityCtrl = TextEditingController();
  final _areasCtrl = TextEditingController();
  final _safetyCtrl = TextEditingController();
  final _injuriesCtrl = TextEditingController();
  final _witnessesCtrl = TextEditingController();
  final _nextCtrl = TextEditingController();
  final _serverCtrl = TextEditingController(text: 'http://127.0.0.1:8080/v1');
  final Map<String, TextEditingController> _captionCtrls = {};
  final Map<String, TextEditingController> _extraCtrls = {};

  bool _busy = false;
  bool _useLocalServer = false;
  bool _autoDescribe = true;
  String _status = '';

  TextEditingController _captionCtrlFor(EvidencePhoto photo) {
    return _captionCtrls.putIfAbsent(
      photo.id,
      () => TextEditingController(text: photo.caption),
    );
  }

  TextEditingController _extraCtrlFor(String key, [String initial = '']) {
    return _extraCtrls.putIfAbsent(
      key,
      () => TextEditingController(text: initial),
    );
  }

  void _disposeCaption(String id) {
    _captionCtrls.remove(id)?.dispose();
  }

  void _rebuildExtraControllers() {
    final specs = ClaimFormCatalog.fieldsFor(_report.claimLine);
    final needed = {
      for (final s in specs)
        if (!_isCoreKey(s.key)) s.key,
    };
    for (final key in _extraCtrls.keys.toList()) {
      if (!needed.contains(key)) {
        _extraCtrls.remove(key)?.dispose();
      }
    }
    for (final key in needed) {
      _extraCtrlFor(key, _report.extraFields[key] ?? '');
    }
  }

  bool _isCoreKey(String key) {
    const core = {
      'policyNumber',
      'claimNumber',
      'insuredName',
      'lossDate',
      'location',
      'lossNarrative',
      'authorityContacted',
      'damageSummary',
      'severity',
      'affectedAreas',
      'safetyNotes',
      'injuries',
      'witnesses',
      'recommendedNext',
    };
    return core.contains(key);
  }

  @override
  void initState() {
    super.initState();
    _report = FieldReport(
      id: _uuid.v4(),
      claimLine: ClaimLine.auto,
      createdAt: DateTime.now(),
      photos: [],
      vlmTier: VlmTier.qwen2Vl2b,
    );
    _vlm.setTier(VlmTier.qwen2Vl2b);
    _rebuildExtraControllers();
    _status = _vlm.engine.statusLabel;
  }

  @override
  void dispose() {
    _claimCtrl.dispose();
    _policyCtrl.dispose();
    _insuredCtrl.dispose();
    _locationCtrl.dispose();
    _lossCtrl.dispose();
    _narrativeCtrl.dispose();
    _authorityCtrl.dispose();
    _summaryCtrl.dispose();
    _severityCtrl.dispose();
    _areasCtrl.dispose();
    _safetyCtrl.dispose();
    _injuriesCtrl.dispose();
    _witnessesCtrl.dispose();
    _nextCtrl.dispose();
    _serverCtrl.dispose();
    for (final c in _captionCtrls.values) {
      c.dispose();
    }
    for (final c in _extraCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addPhoto(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (x == null) return;
    final photo = EvidencePhoto(
      id: _uuid.v4(),
      path: x.path,
      capturedAt: DateTime.now(),
    );
    setState(() {
      _report.photos = [..._report.photos, photo];
    });
    if (_autoDescribe) {
      await _describe(photo);
    }
  }

  Future<void> _describe(EvidencePhoto photo) async {
    setState(() {
      _busy = true;
      _status = _useLocalServer
          ? 'Describing via local VLM…'
          : 'Building ${_report.claimLine.acordHint} draft · ${_report.vlmTier.label}…';
    });
    try {
      final result = await _vlm.describe(
        photo: photo,
        claimLine: _report.claimLine,
        localServerBaseUrl: _useLocalServer ? _serverCtrl.text.trim() : null,
      );
      setState(() {
        photo.caption = result.caption;
        _captionCtrlFor(photo).text = result.caption;
        _applySuggested(result.suggestedFields);
        _status = result.engineNote;
      });
    } catch (e) {
      setState(() => _status = 'VLM error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Describe failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _applySuggested(Map<String, String> fields) {
    void fill(TextEditingController c, String? v) {
      if (v == null || v.trim().isEmpty) return;
      if (c.text.trim().isEmpty) c.text = v;
    }

    fill(_summaryCtrl, fields['damageSummary']);
    fill(_narrativeCtrl, fields['lossNarrative']);
    fill(_severityCtrl, fields['severity']);
    fill(_areasCtrl, fields['affectedAreas']);
    fill(_safetyCtrl, fields['safetyNotes']);
    fill(_nextCtrl, fields['recommendedNext']);
    fill(_injuriesCtrl, fields['injuries']);
    fill(_witnessesCtrl, fields['witnesses']);

    for (final e in fields.entries) {
      if (_isCoreKey(e.key)) continue;
      final c = _extraCtrlFor(e.key);
      if (c.text.trim().isEmpty && e.value.trim().isNotEmpty) {
        c.text = e.value;
      }
    }
  }

  Future<void> _export() async {
    _syncControllersToReport();
    setState(() => _busy = true);
    try {
      final file = await _vlm.exportPacket(_report);
      final miss = (_report.toPacketJson()['fnolCompleteness']
          as Map)['missingRequired'] as List;
      setState(() => _status = 'Exported: ${file.path}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              miss.isEmpty
                  ? 'Saved ${file.path}'
                  : 'Saved — still missing FNOL: ${miss.join(', ')}',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _status = 'Export error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _syncControllersToReport() {
    for (final photo in _report.photos) {
      final c = _captionCtrls[photo.id];
      if (c != null) photo.caption = c.text;
    }
    final extras = <String, String>{};
    for (final e in _extraCtrls.entries) {
      final v = e.value.text.trim();
      if (v.isNotEmpty) extras[e.key] = v;
    }
    _report
      ..claimNumber = _claimCtrl.text.trim()
      ..policyNumber = _policyCtrl.text.trim()
      ..insuredName = _insuredCtrl.text.trim()
      ..location = _locationCtrl.text.trim()
      ..lossDate = _lossCtrl.text.trim()
      ..lossNarrative = _narrativeCtrl.text.trim()
      ..authorityContacted = _authorityCtrl.text.trim()
      ..damageSummary = _summaryCtrl.text.trim()
      ..severity = _severityCtrl.text.trim()
      ..affectedAreas = _areasCtrl.text.trim()
      ..safetyNotes = _safetyCtrl.text.trim()
      ..injuries = _injuriesCtrl.text.trim()
      ..witnesses = _witnessesCtrl.text.trim()
      ..recommendedNext = _nextCtrl.text.trim()
      ..extraFields = extras;
  }

  String _fnolBadge() {
    final specs = ClaimFormCatalog.fieldsFor(_report.claimLine)
        .where((s) => s.requiredForFnol);
    var filled = 0;
    for (final s in specs) {
      if (_liveValue(s.key).trim().isNotEmpty) filled++;
    }
    final total = specs.length;
    return 'FNOL $filled/$total required';
  }

  String _liveValue(String key) {
    switch (key) {
      case 'policyNumber':
        return _policyCtrl.text;
      case 'claimNumber':
        return _claimCtrl.text;
      case 'insuredName':
        return _insuredCtrl.text;
      case 'lossDate':
        return _lossCtrl.text;
      case 'location':
        return _locationCtrl.text;
      case 'lossNarrative':
        return _narrativeCtrl.text;
      case 'authorityContacted':
        return _authorityCtrl.text;
      case 'damageSummary':
        return _summaryCtrl.text;
      case 'severity':
        return _severityCtrl.text;
      case 'affectedAreas':
        return _areasCtrl.text;
      case 'safetyNotes':
        return _safetyCtrl.text;
      case 'injuries':
        return _injuriesCtrl.text;
      case 'witnesses':
        return _witnessesCtrl.text;
      case 'recommendedNext':
        return _nextCtrl.text;
      default:
        return _extraCtrls[key]?.text ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineSpecs = ClaimFormCatalog.fieldsFor(_report.claimLine)
        .where((s) => !_isCoreKey(s.key))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Claims Field'),
            Text(
              'Suite B — agent damage docs',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _fnolBadge(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Export packet',
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      floatingActionButton: _busy
          ? const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(),
            )
          : FloatingActionButton.extended(
              onPressed: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_camera),
                          title: const Text('Take photo'),
                          subtitle: const Text('Camera / webcam'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _addPhoto(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('From gallery'),
                          subtitle: const Text('Best on Windows'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _addPhoto(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Evidence'),
            ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'ACORD-shaped FNOL fields · default vision tier Qwen2-VL 2B (OCR/VIN). '
            'Canon: The Ledger Series/docs/CLAIMS_FORMS_CANON.md',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(_status, style: Theme.of(context).textTheme.labelLarge),
          SwitchListTile(
            title: const Text('Auto-describe after capture'),
            value: _autoDescribe,
            onChanged: (v) => setState(() => _autoDescribe = v),
          ),
          SwitchListTile(
            title: const Text('Use local VLM server'),
            subtitle: Text(_serverCtrl.text),
            value: _useLocalServer,
            onChanged: (v) => setState(() => _useLocalServer = v),
          ),
          if (_useLocalServer)
            TextField(
              controller: _serverCtrl,
              decoration: const InputDecoration(
                labelText: 'Local VLM base URL',
                hintText: 'http://127.0.0.1:8080/v1',
              ),
            ),
          const SizedBox(height: 8),
          Text('Claim line', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ClaimLine.values.map((line) {
              return ChoiceChip(
                label: Text(line.label),
                selected: _report.claimLine == line,
                onSelected: (_) => setState(() {
                  _report.claimLine = line;
                  _rebuildExtraControllers();
                }),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              '${_report.claimLine.acordHint} · ${_report.claimLine.volumeNote}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text('On-device VLM tier',
              style: Theme.of(context).textTheme.titleMedium),
          ...VlmTier.values.map((tier) {
            return RadioListTile<VlmTier>(
              value: tier,
              groupValue: _report.vlmTier,
              title: Text(tier.label),
              subtitle: Text('${tier.params} · ${tier.ramHint}\n${tier.notes}'),
              isThreeLine: true,
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _report.vlmTier = v;
                  _vlm.setTier(v);
                  _status = _vlm.engine.statusLabel;
                });
              },
            );
          }),
          const Divider(height: 32),
          Text('FNOL / report fields',
              style: Theme.of(context).textTheme.titleMedium),
          TextField(
              controller: _claimCtrl,
              decoration: const InputDecoration(labelText: 'Claim #')),
          TextField(
              controller: _policyCtrl,
              decoration: const InputDecoration(labelText: 'Policy # *')),
          TextField(
              controller: _insuredCtrl,
              decoration: const InputDecoration(labelText: 'Named insured *')),
          TextField(
              controller: _locationCtrl,
              decoration:
                  const InputDecoration(labelText: 'Location of loss *')),
          TextField(
              controller: _lossCtrl,
              decoration:
                  const InputDecoration(labelText: 'Date / time of loss *')),
          TextField(
            controller: _narrativeCtrl,
            decoration:
                const InputDecoration(labelText: 'Loss / accident narrative *'),
            maxLines: 3,
          ),
          TextField(
            controller: _authorityCtrl,
            decoration: const InputDecoration(
                labelText: 'Police / fire + report #'),
          ),
          TextField(
            controller: _summaryCtrl,
            decoration: const InputDecoration(labelText: 'Damage summary *'),
            maxLines: 4,
          ),
          TextField(
              controller: _severityCtrl,
              decoration: const InputDecoration(
                  labelText: 'Severity / probable amount')),
          TextField(
            controller: _areasCtrl,
            decoration:
                const InputDecoration(labelText: 'Affected areas / items'),
            maxLines: 3,
          ),
          TextField(
            controller: _injuriesCtrl,
            decoration:
                const InputDecoration(labelText: 'Injuries (who / extent)'),
            maxLines: 2,
          ),
          TextField(
            controller: _witnessesCtrl,
            decoration: const InputDecoration(labelText: 'Witnesses'),
          ),
          TextField(
            controller: _safetyCtrl,
            decoration: const InputDecoration(labelText: 'Safety / hazards'),
            maxLines: 2,
          ),
          TextField(
            controller: _nextCtrl,
            decoration:
                const InputDecoration(labelText: 'Recommended next step'),
          ),
          if (lineSpecs.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Line-specific (${_report.claimLine.acordHint})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...lineSpecs.map((spec) {
              return TextField(
                controller: _extraCtrlFor(spec.key),
                decoration: InputDecoration(
                  labelText: spec.requiredForFnol ? '${spec.label} *' : spec.label,
                  hintText: spec.hint.isEmpty ? null : spec.hint,
                  helperText: spec.group,
                ),
                maxLines: spec.key.contains('Narrative') ||
                        spec.key.contains('Description') ||
                        spec.key == 'howInjuryOccurred' ||
                        spec.key == 'premisesDescription'
                    ? 3
                    : 1,
              );
            }),
          ],
          const Divider(height: 32),
          Text('Evidence (${_report.photos.length})',
              style: Theme.of(context).textTheme.titleMedium),
          if (_report.photos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No photos yet — Evidence → gallery (Windows) or camera (phone).',
              ),
            ),
          ..._report.photos.asMap().entries.map((entry) {
            final index = entry.key;
            final photo = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Photo ${index + 1}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Remove',
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                    _disposeCaption(photo.id);
                                    _report.photos = [
                                      for (var i = 0;
                                          i < _report.photos.length;
                                          i++)
                                        if (i != index) _report.photos[i],
                                    ];
                                  }),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    if (File(photo.path).existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(photo.path),
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _captionCtrlFor(photo),
                      decoration: const InputDecoration(
                        labelText: 'Caption / field notes',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      onChanged: (v) => photo.caption = v,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : () => _describe(photo),
                      icon: const Icon(Icons.visibility),
                      label: Text(
                        _useLocalServer
                            ? 'Describe · local VLM'
                            : 'Describe · ${_report.vlmTier.label}',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
