import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dairy_sacco_mobile/features/app_update/data/app_release.dart';
import 'package:dairy_sacco_mobile/features/app_update/data/app_update_service.dart';
import 'package:dairy_sacco_mobile/features/app_update/presentation/app_update_controller.dart';
import 'package:dairy_sacco_mobile/features/app_update/presentation/widgets/app_update_tile.dart';
import 'package:dairy_sacco_mobile/features/app_update/presentation/widgets/update_gate.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'layout/harness.dart';
import 'support/fake_app_update.dart';

/// Serves one APK, like the API's /app/download.
class _ApkServer implements HttpClientAdapter {
  final List<int> apk;

  /// Honour Range requests (the API does; a proxy might not).
  bool resumes = true;

  /// Close the connection after this many bytes of the body.
  int? cutAfter;
  final List<String?> ranges = [];

  _ApkServer(this.apk);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final range = options.headers['Range'] as String?;
    ranges.add(range);
    var start = 0;
    var status = 200;
    if (range != null && resumes) {
      start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
      status = 206;
    }
    var body = apk.sublist(start);
    if (cutAfter != null) body = body.sublist(0, cutAfter);
    return ResponseBody(
      Stream.value(Uint8List.fromList(body)),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/vnd.android.package-archive'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

AppRelease _releaseOf(List<int> apk, {String? sha}) => AppRelease(
  version: '1.4.1',
  build: 11,
  minBuild: 10,
  files: {
    'arm64': ReleaseFile(
      url: '/app/download/arm64',
      sha256: sha ?? sha256.convert(apk).toString(),
      size: apk.length,
    ),
  },
);

void main() {
  // Flutter installs build 11 as versionCode 2011 (arm64) or 1011 (armv7);
  // comparing that with the published build hid every update in 1.4.0.
  test('the installed build is read without the phone-type offset', () {
    expect(releaseBuild(2011), 11);
    expect(releaseBuild(1011), 11);
    expect(releaseBuild(11), 11); // a build without --split-per-abi
    expect(releaseBuild(2999), 999);
  });

  group('downloading an update', () {
    late Directory dir;
    late _ApkServer server;
    late AppUpdateService service;
    final apk = utf8.encode('APK' * 5000);

    setUp(() {
      dir = Directory.systemTemp.createTempSync('updates');
      server = _ApkServer(apk);
      service = AppUpdateService(
        Dio(BaseOptions(baseUrl: 'http://api'))..httpClientAdapter = server,
        FakeInstaller(dir: dir.path),
      );
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('saves the checked file and reports progress', () async {
      final seen = <int>[];
      final path = await service.download(
        _releaseOf(apk),
        'arm64',
        onProgress: (received, total) => seen.add(received),
      );
      expect(File(path).readAsBytesSync(), apk);
      expect(seen.last, apk.length);
      expect(File('$path.part').existsSync(), isFalse);
    });

    test('continues where a dropped download stopped', () async {
      server.cutAfter = 4000;
      await expectLater(
        service.download(_releaseOf(apk), 'arm64'),
        throwsA(
          isA<UpdateException>().having(
            (e) => e.message,
            'message',
            contains('continue'),
          ),
        ),
      );

      server.cutAfter = null;
      final path = await service.download(_releaseOf(apk), 'arm64');
      expect(server.ranges.last, 'bytes=4000-');
      expect(File(path).readAsBytesSync(), apk);
    });

    test('starts again when the server sends the whole file', () async {
      server.cutAfter = 4000;
      await expectLater(
        service.download(_releaseOf(apk), 'arm64'),
        throwsA(isA<UpdateException>()),
      );
      server
        ..cutAfter = null
        ..resumes = false;
      final path = await service.download(_releaseOf(apk), 'arm64');
      expect(File(path).readAsBytesSync(), apk);
    });

    test('throws away a damaged file', () async {
      final wrong = sha256.convert(utf8.encode('other')).toString();
      await expectLater(
        service.download(_releaseOf(apk, sha: wrong), 'arm64'),
        throwsA(
          isA<UpdateException>().having(
            (e) => e.message,
            'message',
            contains('damaged'),
          ),
        ),
      );
      expect(dir.listSync(), isEmpty, reason: 'nothing damaged is kept');
    });

    test('reuses a finished download without asking again', () async {
      await service.download(_releaseOf(apk), 'arm64');
      final requests = server.ranges.length;
      await service.download(_releaseOf(apk), 'arm64');
      expect(server.ranges.length, requests);
    });

    test('knows a finished download, and only a sound one', () async {
      final release = _releaseOf(apk);
      expect(await service.downloaded(release, 'arm64'), isNull);
      final path = await service.download(release, 'arm64');
      expect(await service.downloaded(release, 'arm64'), path);
      File(path).writeAsBytesSync(apk.sublist(1));
      expect(await service.downloaded(release, 'arm64'), isNull);
    });

    test('removes downloads of other versions', () async {
      final path = await service.download(_releaseOf(apk), 'arm64');
      File('${dir.path}/DairyGo-9-arm64.apk').writeAsStringSync('old');
      await service.removeOldDownloads(keepBuild: 11);
      expect(dir.listSync().map((f) => f.path), [path]);
    });
  });

  group('AppUpdateController', () {
    late FakeAppUpdateService service;
    late ProviderContainer container;
    AppUpdateController controller() =>
        container.read(appUpdateProvider.notifier);
    AppUpdateState state() => container.read(appUpdateProvider);

    setUp(() {
      service = FakeAppUpdateService();
      container = ProviderContainer(overrides: fakeUpdateOverrides(service));
    });
    tearDown(() => container.dispose());

    test('finds a newer version', () async {
      service.latest = releaseForTests(build: 11, minBuild: 10);
      await controller().check();
      expect(state().available, isTrue);
      expect(state().required, isFalse);
    });

    test('requires the update when this version is too old', () async {
      service.latest = releaseForTests(build: 12, minBuild: 11);
      await controller().check();
      expect(state().required, isTrue);
    });

    test('nothing to do when up to date or nothing is published', () async {
      await controller().check(manual: true);
      expect(state().available, isFalse);
      expect(state().confirmedUpToDate, isTrue);

      service.latest = releaseForTests(build: 10, minBuild: 10);
      await controller().check(manual: true);
      expect(state().available, isFalse);
      expect(state().required, isFalse);
    });

    test('checks automatically at most every few hours', () async {
      await controller().check();
      await controller().check();
      await controller().onResume();
      expect(service.checks, 1);
      await controller().check(manual: true);
      expect(service.checks, 2);
    });

    test('says so only when a check the user asked for fails', () async {
      service.checkError = Exception('offline');
      await controller().check();
      expect(state().error, isNull);
      await controller().check(manual: true);
      expect(state().error, contains('Could not check'));
    });

    test('asks for permission, then installs on return to the app', () async {
      service.latest = releaseForTests();
      service.fakeInstaller.allowed = false;
      await controller().check();
      await controller().update();
      expect(state().step, UpdateStep.needsPermission);
      expect(service.fakeInstaller.installed, isEmpty);

      await controller().allowInstalls();
      expect(service.fakeInstaller.settingsOpened, 1);
      service.fakeInstaller.allowed = true;
      await controller().onResume();
      expect(state().step, UpdateStep.installing);
      expect(service.fakeInstaller.installed, [
        '/updates/DairyGo-11-arm64.apk',
      ]);
    });

    test('a failed download can be tried again', () async {
      service.latest = releaseForTests();
      service.downloadError = UpdateException.stopped;
      await controller().check();
      await controller().update();
      expect(state().step, UpdateStep.failed);
      expect(state().error, contains('continue'));

      service.downloadError = null;
      await controller().update();
      expect(state().step, UpdateStep.installing);
    });

    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('on Wi-Fi it downloads by itself and waits for Restart', () async {
      service
        ..latest = releaseForTests()
        ..wifi = true;
      await controller().check();
      await settle();
      expect(service.downloads, 1);
      expect(state().step, UpdateStep.readyToInstall);
      expect(service.fakeInstaller.installed, isEmpty, reason: 'not asked');

      await controller().install();
      expect(state().step, UpdateStep.installing);
      expect(service.fakeInstaller.installed, [
        '/updates/DairyGo-11-arm64.apk',
      ]);
    });

    test('on mobile data nothing downloads until asked', () async {
      service.latest = releaseForTests();
      await controller().check();
      await settle();
      expect(service.downloads, 0);
      expect(state().step, UpdateStep.idle);
      expect(state().available, isTrue);
    });

    test('a download from before is ready at once, with no data', () async {
      service
        ..latest = releaseForTests()
        ..alreadyDownloaded = true;
      await controller().check();
      expect(service.downloads, 0);
      expect(state().step, UpdateStep.readyToInstall);
      await controller().install();
      expect(service.fakeInstaller.installed, hasLength(1));
    });

    test('a download on Wi-Fi that fails leaves the usual offer', () async {
      service
        ..latest = releaseForTests()
        ..wifi = true
        ..downloadError = UpdateException.stopped;
      await controller().check();
      await settle();
      expect(state().step, UpdateStep.idle);
      expect(state().error, isNull);
      expect(state().available, isTrue);
    });

    test('follows what Android says about the install', () async {
      service
        ..latest = releaseForTests()
        ..alreadyDownloaded = true;
      await controller().check();
      final installer = service.fakeInstaller;

      await controller().install();
      installer.answer(const InstallResult(InstallOutcome.confirming));
      await settle();
      expect(state().step, UpdateStep.installing);

      // The user closed Android's confirm screen: offer Restart again.
      installer.answer(const InstallResult(InstallOutcome.cancelled));
      await settle();
      expect(state().step, UpdateStep.readyToInstall);

      await controller().install();
      installer.answer(
        const InstallResult(InstallOutcome.failed, 'INSTALL_FAILED_NO_SPACE'),
      );
      await settle();
      expect(state().step, UpdateStep.failed);
      expect(state().error, contains('INSTALL_FAILED_NO_SPACE'));

      // Try again reuses the file and installs.
      await controller().update();
      expect(state().step, UpdateStep.installing);
      expect(installer.installed, hasLength(3));
    });

    test('Android could not start the install', () async {
      final installer = _RefusingInstaller();
      service = FakeAppUpdateService(
        latest: releaseForTests(),
        installer: installer,
      )..alreadyDownloaded = true;
      container.dispose();
      container = ProviderContainer(overrides: fakeUpdateOverrides(service));
      await controller().check();
      await controller().install();
      expect(state().step, UpdateStep.failed);
      expect(state().error, contains('DairyGo page'));
    });

    test('a phone type without an APK is not offered the update', () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          ...fakeUpdateOverrides(service),
          deviceAbiProvider.overrideWithValue(null),
        ],
      );
      service.latest = releaseForTests();
      await controller().check();
      expect(state().available, isFalse);
    });
  });

  group('update screens', () {
    // Real fonts, so widths match the phone.
    setUpAll(loadFonts);

    Future<FakeAppUpdateService> pumpGate(
      WidgetTester tester,
      AppRelease? latest, {
      bool wifi = false,
    }) async {
      final service = FakeAppUpdateService(latest: latest)..wifi = wifi;
      await tester.pumpWidget(
        ProviderScope(
          overrides: fakeUpdateOverrides(service),
          child: MaterialApp(
            home: const Scaffold(body: Text('the app')),
            builder: (context, child) => UpdateGate(child: child!),
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(UpdateGate)),
      );
      await container.read(appUpdateProvider.notifier).check();
      await tester.pumpAndSettle();
      return service;
    }

    testWidgets('a new version is offered and can be put off', (tester) async {
      await pumpGate(tester, releaseForTests());
      expect(find.text('the app'), findsOneWidget);
      expect(find.text('New version 1.4.11 is ready'), findsOneWidget);

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(find.text('New version 1.4.11 is ready'), findsNothing);
    });

    testWidgets('a too-old app shows only the update screen', (tester) async {
      await pumpGate(tester, releaseForTests(build: 12, minBuild: 11));
      expect(find.text('the app'), findsNothing);
      expect(find.text('Please update DairyGo'), findsOneWidget);
      expect(find.text('Later'), findsNothing);

      await tester.tap(find.text('Update now'));
      await tester.pumpAndSettle();
      expect(find.text('Restart to update'), findsOneWidget);
    });

    testWidgets('downloaded on Wi-Fi, one tap on Restart installs it', (
      tester,
    ) async {
      final service = await pumpGate(tester, releaseForTests(), wifi: true);
      expect(find.text('Version 1.4.11 is ready to install'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);

      await tester.tap(find.text('Restart'));
      await tester.pumpAndSettle();
      expect(find.text('Updating DairyGo…'), findsOneWidget);
      expect(find.text('Later'), findsNothing);
      expect(service.fakeInstaller.installed, hasLength(1));
    });

    testWidgets('Later hides the Restart offer', (tester) async {
      await pumpGate(tester, releaseForTests(), wifi: true);
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(find.text('Version 1.4.11 is ready to install'), findsNothing);
    });

    testWidgets('More shows the version and checks when asked', (tester) async {
      final service = FakeAppUpdateService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: fakeUpdateOverrides(service),
          child: const MaterialApp(home: Scaffold(body: AppUpdateTile())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('App version 1.4.0'), findsOneWidget);

      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(find.text('Up to date'), findsOneWidget);

      service.latest = releaseForTests();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(find.text('New version 1.4.11 is ready'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Update'), findsOneWidget);
    });

    // The smallest phone with the largest text, in the real app.
    for (final (name, release, wifi) in [
      ('update strip', releaseForTests(), false),
      ('restart strip', releaseForTests(), true),
      ('update screen', releaseForTests(build: 12, minBuild: 11), false),
      ('restart screen', releaseForTests(build: 12, minBuild: 11), true),
    ]) {
      testWidgets('the $name fits a 320 dp phone with large text', (
        tester,
      ) async {
        tester.view
          ..physicalSize = const Size(320, 640)
          ..devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final app = await AppUnderTest.open(
          tester,
          'collector',
          '/dashboard',
          updates: FakeAppUpdateService(latest: release)..wifi = wifi,
        );
        final container = app.container;
        await container.read(appUpdateProvider.notifier).check(manual: true);
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        final shown = find
            .textContaining(
              release.minBuild > 10 ? 'Please update' : 'is ready',
            )
            .evaluate()
            .length;
        final button = find
            .textContaining(wifi ? 'Restart' : 'Update')
            .evaluate()
            .length;
        final errors = [...app.errors];
        await app.close();
        expect(shown, 1);
        expect(button, greaterThan(0));
        expect(errors, isEmpty);
      });
    }
  });
}

class _RefusingInstaller extends FakeInstaller {
  @override
  Future<bool> install(String path) async {
    installed.add(path);
    return false;
  }
}
