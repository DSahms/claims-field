import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import '../vlm/vlm_engine.dart';

class ClaimsFieldVlmService {
  ClaimsFieldVlmService({VlmEngine? engine})
      : _engine = engine ?? FieldScaffoldEngine(VlmTier.smolVlm500m);

  VlmEngine _engine;
  final _uuid = const Uuid();

  VlmEngine get engine => _engine;

  void setTier(VlmTier tier) {
    _engine = FieldScaffoldEngine(tier);
  }

  /// Prefer local OpenAI-compatible VLM when [localServerBaseUrl] is set.
  /// Falls back to field scaffold so the agent always gets a draft.
  Future<VlmDescribeResult> describe({
    required EvidencePhoto photo,
    required ClaimLine claimLine,
    String? extraContext,
    String? localServerBaseUrl,
  }) async {
    final base = localServerBaseUrl?.trim();
    if (base != null && base.isNotEmpty) {
      try {
        return await describeWithLocalServer(
          imagePath: photo.path,
          claimLine: claimLine,
          extraContext: extraContext,
          baseUrl: base,
          tier: _engine.tier,
        );
      } catch (e) {
        final scaffold = await _engine.describeDamage(
          imagePath: photo.path,
          claimLine: claimLine,
          extraContext: extraContext,
        );
        return VlmDescribeResult(
          caption:
              '${scaffold.caption}\n\n---\nLocal VLM unreachable ($e). Using field scaffold.',
          suggestedFields: scaffold.suggestedFields,
          engineNote: 'Scaffold fallback · $e',
          raw: scaffold.raw,
        );
      }
    }
    return _engine.describeDamage(
      imagePath: photo.path,
      claimLine: claimLine,
      extraContext: extraContext,
    );
  }

  /// LiteRT-LM / any OpenAI-compatible local server with vision.
  Future<VlmDescribeResult> describeWithLocalServer({
    required String imagePath,
    required ClaimLine claimLine,
    required String baseUrl,
    required VlmTier tier,
    String? extraContext,
    String model = 'local-vlm',
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    final b64 = base64Encode(bytes);
    final ext = p.extension(imagePath).replaceAll('.', '').toLowerCase();
    final mime = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final uri = Uri.parse(baseUrl.endsWith('/v1')
        ? '$baseUrl/chat/completions'
        : '$baseUrl/v1/chat/completions');

    final body = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': DamagePrompts.systemFor(claimLine),
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': DamagePrompts.userFor(claimLine, extra: extraContext),
            },
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mime;base64,$b64'},
            },
          ],
        },
      ],
      'max_tokens': 512,
      'temperature': 0.2,
    };

    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 120));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException(
        'Local VLM HTTP ${res.statusCode}: ${res.body}',
        uri: uri,
      );
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final content = (((decoded['choices'] as List?)?.first
            as Map<String, dynamic>?)?['message']
        as Map<String, dynamic>?)?['content'] as String? ??
        '';

    return VlmDescribeResult(
      caption: content.trim(),
      suggestedFields: _heuristicFieldsFromCaption(content),
      engineNote: 'Local server · ${tier.label} · $baseUrl',
      raw: res.body,
    );
  }

  Map<String, String> _heuristicFieldsFromCaption(String caption) {
    return {
      'damageSummary':
          caption.length > 400 ? caption.substring(0, 400) : caption,
      'severity': '',
      'affectedAreas': '',
      'safetyNotes': '',
      'recommendedNext': '',
    };
  }

  Future<File> exportPacket(FieldReport report) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(dir.path, 'claims_field_exports'));
    if (!await outDir.exists()) await outDir.create(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final base = p.join(outDir.path, 'claims-field-${report.id}-$stamp');
    final md = File('$base.md');
    final jsonFile = File('$base.json');
    await md.writeAsString(report.toMarkdown());
    await jsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report.toPacketJson()),
    );
    return md;
  }

  String newId() => _uuid.v4();
}
