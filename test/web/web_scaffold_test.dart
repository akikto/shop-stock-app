import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// These tests do not launch a browser or run `flutter build web` —
/// there is no Flutter/Dart SDK toolchain available in the environment
/// that authored this project (see README.md "Browser preview
/// troubleshooting"). Instead they statically confirm the required
/// files exist and are well-formed, so a future accidental deletion or
/// malformed edit is caught at review time. This is not a substitute
/// for actually running `flutter run -d web-server` / `flutter build
/// web` and looking at the result in a browser.
void main() {
  group('required Flutter Web files exist', () {
    test('pubspec.yaml exists', () {
      expect(File('pubspec.yaml').existsSync(), isTrue);
    });

    test('lib/main.dart exists', () {
      expect(File('lib/main.dart').existsSync(), isTrue);
    });

    test('web/index.html exists', () {
      expect(File('web/index.html').existsSync(), isTrue);
    });

    test('web/manifest.json exists', () {
      expect(File('web/manifest.json').existsSync(), isTrue);
    });
  });

  group('web/index.html is well-formed for GitHub Pages deployment', () {
    late String html;
    setUpAll(() => html = File('web/index.html').readAsStringSync());

    test(
        'references the FLUTTER_BASE_HREF build-time token, not a hardcoded path',
        () {
      expect(html, contains(r'<base href="$FLUTTER_BASE_HREF">'));
    });

    test('links the manifest', () {
      expect(html, contains('rel="manifest" href="manifest.json"'));
    });

    test('does not embed any Supabase key or URL directly', () {
      // Config must come from --dart-define at build time, never be
      // baked into the static HTML shell itself.
      expect(html.toLowerCase(), isNot(contains('supabase')));
      expect(html.toLowerCase(), isNot(contains('service_role')));
    });
  });

  group('web/manifest.json is valid and internally consistent', () {
    late Map<String, dynamic> manifest;
    setUpAll(() {
      manifest = jsonDecode(File('web/manifest.json').readAsStringSync())
          as Map<String, dynamic>;
    });

    test('has the required PWA fields', () {
      expect(manifest['name'], isNotEmpty);
      expect(manifest['short_name'], isNotEmpty);
      expect(manifest['start_url'], isNotNull);
      expect(manifest['display'], 'standalone');
    });

    test('lists at least a 192x192 and a 512x512 icon', () {
      final icons = (manifest['icons'] as List).cast<Map<String, dynamic>>();
      expect(icons.any((i) => i['sizes'] == '192x192'), isTrue);
      expect(icons.any((i) => i['sizes'] == '512x512'), isTrue);
    });

    test('every icon referenced in the manifest exists on disk', () {
      final icons = (manifest['icons'] as List).cast<Map<String, dynamic>>();
      for (final icon in icons) {
        final path = 'web/${icon['src']}';
        expect(File(path).existsSync(), isTrue,
            reason: '$path referenced by manifest.json but missing');
      }
    });
  });

  group('no secrets anywhere under web/', () {
    test('no service_role key or obvious secret pattern in any web/ file', () {
      final webDir = Directory('web');
      final offenders = <String>[];
      for (final entity in webDir.listSync(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.html') &&
            !entity.path.endsWith('.json') &&
            !entity.path.endsWith('.js')) {
          continue;
        }
        final content = entity.readAsStringSync().toLowerCase();
        if (content.contains('service_role') ||
            content.contains('sk_live') ||
            content.contains('sk_test')) {
          offenders.add(entity.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'Potential secret found in: $offenders');
    });
  });

  group('CI workflow deploys web preview without exposing secrets', () {
    late String workflow;
    setUpAll(() {
      workflow =
          File('.github/workflows/deploy-web-preview.yml').readAsStringSync();
    });

    test('workflow file exists', () {
      expect(File('.github/workflows/deploy-web-preview.yml').existsSync(),
          isTrue);
    });

    test('reads Supabase config from repository secrets, not hardcoded values',
        () {
      expect(workflow, contains(r'${{ secrets.SUPABASE_URL }}'));
      expect(workflow, contains(r'${{ secrets.SUPABASE_ANON_KEY }}'));
    });

    test('writes config JSON with jq so secret characters stay valid', () {
      expect(workflow, contains('jq -n'));
      expect(workflow, contains('config/config.ci.json'));
    });

    test('verifies Supabase URL is embedded in web build output', () {
      expect(workflow, contains('grep -q "supabase.co" build/web/main.dart.js'));
    });

    test('builds Android app bundle in addition to APK', () {
      expect(workflow, contains('flutter build appbundle'));
    });

    test('builds web without PWA service worker (avoids stale preview cache)', () {
      expect(workflow, contains('--pwa-strategy=none'));
    });

    test('optionally writes google-services.json from GitHub secret', () {
      expect(workflow, contains('GOOGLE_SERVICES_JSON'));
      expect(workflow, contains('android/app/google-services.json'));
    });

    test('uploads APK and AAB artifacts', () {
      expect(workflow, contains('name: android-apk'));
      expect(workflow, contains('name: android-aab'));
    });

    test(
        'never references a service_role secret value (the word appears only in cautionary comments)',
        () {
      expect(workflow, isNot(contains('secrets.SERVICE_ROLE')));
      expect(workflow, isNot(contains('secrets.SUPABASE_SERVICE_ROLE')));
    });

    test('deletes the generated config file before publishing the artifact',
        () {
      final removeIndex = workflow.indexOf('rm -f config/config.ci.json');
      final uploadIndex = workflow.indexOf('upload-pages-artifact');
      expect(removeIndex, greaterThanOrEqualTo(0));
      expect(uploadIndex, greaterThan(removeIndex),
          reason:
              'the CI config file must be removed before the build/web artifact is uploaded');
    });
  });
}
