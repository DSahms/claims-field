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
  final _locationCtrl = TextEditingController();
  final _lossCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _severityCtrl = TextEditingController();
  final _areasCtrl = TextEditingController();
  final _safetyCtrl = TextEditingController();
  final _nextCtrl = TextEditingController();
  final _serverCtrl = TextEditingController(text: 'http://127.0.0.1:8080/v1');

  bool _busy = false;
  bool _useLocalServer = false;
  bool _autoDescribe = true;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _report = FieldReport(
      id: _uuid.v4(),
      claimLine: ClaimLine.auto,
      createdAt: DateTime.now(),
      photos: [],
    );
    _status = _vlm.engine.statusLabel;
  }

  @override
  void dispose() {
    _claimCtrl.dispose();
    _policyCtrl.dispose();
    _locationCtrl.dispose();
    _lossCtrl.dispose();
    _summaryCtrl.dispose();
    _severityCtrl.dispose();
    _areasCtrl.dispose();
    _safetyCtrl.dispose();
    _nextCtrl.dispose();
    _serverCtrl.dispose();
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
          : 'Building field draft · ${_report.vlmTier.label}…';
    });
    try {
      final result = await _vlm.describe(
        photo: photo,
        claimLine: _report.claimLine,
        localServerBaseUrl:
            _useLocalServer ? _serverCtrl.text.trim() : null,
      );
      setState(() {
        photo.caption = result.caption;
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
    fill(_severityCtrl, fields['severity']);
    fill(_areasCtrl, fields['affectedAreas']);
    fill(_safetyCtrl, fields['safetyNotes']);
    fill(_nextCtrl, fields['recommendedNext']);
  }

  Future<void> _export() async {
    _syncControllersToReport();
    setState(() => _busy = true);
    try {
      final file = await _vlm.exportPacket(_report);
      setState(() => _status = 'Exported: ${file.path}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${file.path}')),
        );
      }
    } catch (e) {
      setState(() => _status = 'Export error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _syncControllersToReport() {
    _report
      ..claimNumber = _claimCtrl.text.trim()
      ..policyNumber = _policyCtrl.text.trim()
      ..location = _locationCtrl.text.trim()
      ..lossDate = _lossCtrl.text.trim()
      ..damageSummary = _summaryCtrl.text.trim()
      ..severity = _severityCtrl.text.trim()
      ..affectedAreas = _areasCtrl.text.trim()
      ..safetyNotes = _safetyCtrl.text.trim()
      ..recommendedNext = _nextCtrl.text.trim();
  }

  @override
  Widget build(BuildContext context) {
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
                          subtitle: const Text('Best on Windows tonight'),
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
            'Offline vision ladder: SmolVLM 500M → SmolVLM2 2.2B → Qwen2-VL 2B. '
            'Tonight: photo → field draft → edit → export. Local VLM when you flip the switch.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(_status, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
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
            children: ClaimLine.values.map((line) {
              return ChoiceChip(
                label: Text(line.label),
                selected: _report.claimLine == line,
                onSelected: (_) => setState(() => _report.claimLine = line),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
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
          Text('Report fields', style: Theme.of(context).textTheme.titleMedium),
          TextField(
              controller: _claimCtrl,
              decoration: const InputDecoration(labelText: 'Claim #')),
          TextField(
              controller: _policyCtrl,
              decoration: const InputDecoration(labelText: 'Policy #')),
          TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Location')),
          TextField(
              controller: _lossCtrl,
              decoration: const InputDecoration(labelText: 'Loss date')),
          TextField(
            controller: _summaryCtrl,
            decoration: const InputDecoration(labelText: 'Damage summary'),
            maxLines: 4,
          ),
          TextField(
              controller: _severityCtrl,
              decoration: const InputDecoration(labelText: 'Severity')),
          TextField(
            controller: _areasCtrl,
            decoration:
                const InputDecoration(labelText: 'Affected areas / items'),
            maxLines: 3,
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
          ..._report.photos.map((photo) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    Text(
                      photo.caption.isEmpty
                          ? 'No caption yet'
                          : photo.caption,
                      maxLines: 12,
                      overflow: TextOverflow.ellipsis,
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
