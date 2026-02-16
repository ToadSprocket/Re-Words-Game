// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'dart:io';

/// Bumps PATCH and BUILD, then syncs both pubspec.yaml and lib/config/config.dart.
///
/// - MAJOR/MINOR/PHASE are preserved (manual control)
/// - PATCH and BUILD are incremented by 1
/// - pubspec uses Flutter format: MAJOR.MINOR.PATCH+BUILD
void main(List<String> args) {
  final dryRun = args.contains('--dry-run');

  final pubspecFile = File('pubspec.yaml');
  final configFile = File('lib/config/config.dart');

  if (!pubspecFile.existsSync() || !configFile.existsSync()) {
    stderr.writeln('Missing pubspec.yaml or lib/config/config.dart');
    exit(1);
  }

  final pubspec = pubspecFile.readAsStringSync();
  final config = configFile.readAsStringSync();

  final versionRegex = RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$', multiLine: true);
  final versionMatch = versionRegex.firstMatch(pubspec);
  if (versionMatch == null) {
    stderr.writeln('Could not parse pubspec version (expected x.y.z+build)');
    exit(1);
  }

  final major = int.parse(versionMatch.group(1)!);
  final minor = int.parse(versionMatch.group(2)!);
  final currentPatch = int.parse(versionMatch.group(3)!);
  final currentBuild = int.parse(versionMatch.group(4)!);

  final newPatch = currentPatch + 1;
  final newBuild = currentBuild + 1;

  final newPubspecVersion = 'version: $major.$minor.$newPatch+$newBuild';
  final updatedPubspec = pubspec.replaceFirst(versionRegex, newPubspecVersion);

  // Keep build displayed as 2 digits (03, 04, ...)
  final paddedBuild = newBuild.toString().padLeft(2, '0');

  String updatedConfig = config;
  updatedConfig = updatedConfig.replaceFirst(
    RegExp(r'static const String PATCH\s*=\s*"\d+";'),
    'static const String PATCH = "$newPatch";',
  );
  updatedConfig = updatedConfig.replaceFirst(
    RegExp(r'static const String BUILD\s*=\s*"\d+";'),
    'static const String BUILD = "$paddedBuild";',
  );

  if (dryRun) {
    stdout.writeln('DRY RUN');
    stdout.writeln('pubspec -> $newPubspecVersion');
    stdout.writeln('config  -> PATCH=$newPatch, BUILD=$paddedBuild');
    return;
  }

  pubspecFile.writeAsStringSync(updatedPubspec);
  configFile.writeAsStringSync(updatedConfig);

  stdout.writeln('Updated:');
  stdout.writeln(' - pubspec.yaml: $major.$minor.$newPatch+$newBuild');
  stdout.writeln(' - config.dart : PATCH=$newPatch, BUILD=$paddedBuild');
}
