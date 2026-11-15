// Creates the android/ and ios/ folders and applies the few native settings
// this app needs. Run it once after cloning:
//
//   dart run tool/setup_platforms.dart
//
// It is safe to run again: existing Dart code is never overwritten and each
// patch is applied only if it is missing.
import 'dart:io';

const _manifestPath = 'android/app/src/main/AndroidManifest.xml';
const _ttsIntent =
    '        <intent>\n'
    '            <action android:name="android.intent.action.TTS_SERVICE"/>\n'
    '        </intent>\n';

Future<void> main() async {
  stdout.writeln('> flutter create (android, ios)');
  final create = await Process.run('flutter', [
    'create',
    '--platforms=android,ios',
    '--project-name',
    'nujoom',
    '--org',
    'com.alsllam',
    '.',
  ], runInShell: true);
  stdout.write(create.stdout);
  stderr.write(create.stderr);
  if (create.exitCode != 0) exit(create.exitCode);

  final manifest = File(_manifestPath);
  if (!manifest.existsSync()) {
    stderr.writeln('Could not find $_manifestPath');
    exit(1);
  }
  var xml = manifest.readAsStringSync();

  // 1. Android 11+ hides the text-to-speech engine from apps that do not
  //    declare they use it. Without this the spoken words stay silent.
  if (!xml.contains('android.intent.action.TTS_SERVICE')) {
    if (xml.contains('<queries>')) {
      xml = xml.replaceFirst('<queries>', '<queries>\n$_ttsIntent');
    } else {
      xml = xml.replaceFirst(
        '</manifest>',
        '    <queries>\n$_ttsIntent    </queries>\n</manifest>',
      );
    }
    stdout.writeln('> added text-to-speech query');
  }

  // 2. Start in landscape so there is no portrait flash before Dart runs.
  if (!xml.contains('android:screenOrientation')) {
    xml = xml.replaceFirst(
      'android:name=".MainActivity"',
      'android:name=".MainActivity"\n'
          '            android:screenOrientation="sensorLandscape"',
    );
    stdout.writeln('> locked the activity to landscape');
  }

  // 3. The name shown under the launcher icon.
  xml = xml.replaceFirst('android:label="nujoom"', 'android:label="Nujoom"');

  manifest.writeAsStringSync(xml);
  stdout.writeln('Done. Next: flutter run');
}
