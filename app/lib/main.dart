// Component 1 — walking skeleton.
//
// Purpose: prove the toolchain end to end. It deliberately does almost nothing,
// because what kills mobile projects is build tooling and signing, not feature
// code. Three things must be true before any parser work begins:
//
//   1. The app builds and runs on a real Android device.
//   2. ML Kit links and initialises on-device — the dependency that breaks iOS
//      builds (armv7, deployment target).
//   3. A device prefix exists and persists, per DR-008. Two phones each counting
//      from 1 would silently conflate rows on merge. Cheap now; unfixable once
//      300 rows exist.
//
// NOT COMPILED. Written without a Flutter SDK available. Expect to fix small
// things on first build; that is what Component 1 is for.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'grid_spike_page.dart';

void main() {
  runApp(const CaptureApp());
}

class CaptureApp extends StatelessWidget {
  const CaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Questionnaire Capture',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F3864)),
        useMaterial3: true,
      ),
      home: const HealthCheckPage(),
    );
  }
}

/// One check the skeleton runs, and what it proves.
class CheckResult {
  CheckResult(this.name, this.ok, this.detail);
  final String name;
  final bool ok;
  final String detail;
}

class HealthCheckPage extends StatefulWidget {
  const HealthCheckPage({super.key});

  @override
  State<HealthCheckPage> createState() => _HealthCheckPageState();
}

class _HealthCheckPageState extends State<HealthCheckPage> {
  List<CheckResult> _results = [];
  bool _running = true;
  String _deviceId = '?';

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  /// DR-008: response identifiers carry a device prefix so two phones never
  /// produce colliding IDs. Assigned once, on first launch, then persisted.
  Future<String> _devicePrefix() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('device_prefix');
    if (existing != null) return existing;

    // A..Z, chosen at random rather than sequentially: there is no coordination
    // between devices, so a fixed starting letter would guarantee collisions.
    final letter = String.fromCharCode(65 + Random().nextInt(26));
    await prefs.setString('device_prefix', letter);
    return letter;
  }

  Future<void> _runChecks() async {
    final out = <CheckResult>[];

    // 1. Persistent storage.
    try {
      final prefix = await _devicePrefix();
      _deviceId = prefix;
      out.add(CheckResult(
        'Device prefix (DR-008)',
        true,
        'Assigned "$prefix". IDs will look like $prefix-0001.',
      ));
    } catch (e) {
      out.add(CheckResult('Device prefix (DR-008)', false, '$e'));
    }

    // 2. Writable storage — needed later for photos, the database and the workbook.
    try {
      final dir = await getApplicationDocumentsDirectory();
      final probe = '${dir.path}/.write_probe';
      await (await getApplicationDocumentsDirectory()).exists();
      out.add(CheckResult('App storage', true, dir.path));
      // Not writing a file here; existence of the directory is enough for a skeleton.
      assert(probe.isNotEmpty);
    } catch (e) {
      out.add(CheckResult('App storage', false, '$e'));
    }

    // 3. ML Kit linkage. Instantiating and closing the recognizer proves the
    //    native library is present and linked without needing an image. This is
    //    the check that most often fails on iOS.
    try {
      final latin = TextRecognizer(script: TextRecognitionScript.latin);
      await latin.close();
      out.add(CheckResult(
        'ML Kit — Latin',
        true,
        'Recognizer created and closed. Used for the printed code column (DR-003).',
      ));
    } catch (e) {
      out.add(CheckResult('ML Kit — Latin', false, '$e'));
    }

    try {
      final deva = TextRecognizer(script: TextRecognitionScript.devanagiri);
      await deva.close();
      out.add(CheckResult(
        'ML Kit — Devanagari',
        true,
        'Recognizer created and closed. Required by DR-006.',
      ));
    } catch (e) {
      out.add(CheckResult(
        'ML Kit — Devanagari',
        false,
        'If this fails but Latin passed, the enum name may differ in 0.15.1 — '
        'check TextRecognitionScript in the package source. $e',
      ));
    }

    if (!mounted) return;
    setState(() {
      _results = out;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final passed = _results.where((r) => r.ok).length;
    final all = _results.isNotEmpty && passed == _results.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Component 1 — Walking Skeleton'),
        backgroundColor: const Color(0xFF1F3864),
        foregroundColor: Colors.white,
      ),
      body: _running
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: all ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          all ? 'Toolchain verified' : 'Something is not linked',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text('$passed of ${_results.length} checks passed'),
                        const SizedBox(height: 8),
                        Text('This device will issue IDs as $_deviceId-0001, '
                            '$_deviceId-0002, …'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ..._results.map(
                  (r) => Card(
                    child: ListTile(
                      leading: Icon(
                        r.ok ? Icons.check_circle : Icons.error,
                        color: r.ok ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      title: Text(r.name),
                      subtitle: Text(r.detail),
                      isThreeLine: r.detail.length > 60,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Component 1 is done when this screen shows all checks '
                      'passing on a real Android phone, an IPA has been built on '
                      'the Mac, and DR-007 has a written answer in PLAN.md.\n\n'
                      'Do not start Component 2 until then.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GridSpikePage()),
                  ),
                  child: const Text('Component 3 — Code-Column OCR spike'),
                ),
              ],
            ),
    );
  }
}
