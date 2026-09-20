import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Wraps Google Play's official **In-App Update** API.
///
/// HOW THIS ACTUALLY TRIGGERS AN UPDATE:
/// Every time you upload a new build to the Play Console and roll it out
/// (even to internal testing), the Play Store records that a newer
/// `versionCode` exists for your app. Next time a user opens the app, this
/// service asks Play "is there a newer version than the one currently
/// installed?" — if yes, it shows Play's own native update UI, right
/// inside your app. You don't need to change anything here per release;
/// just make sure `android/app/build.gradle`'s `versionCode` is
/// incremented on every build you upload (Flutter does this for you if
/// you bump the `version:` line in `pubspec.yaml`, e.g. `1.0.1+2`).
///
/// THIS APP FORCES EVERY UPDATE. Every time the app is opened and Play
/// reports a newer version exists, the user is shown Play's full-screen,
/// non-dismissible **immediate update** flow and cannot continue into the
/// app until they update — there's no "later"/"skip" option. This is
/// deliberate per how this service is configured; if you instead want an
/// optional/background update prompt for some releases, that's a Play
/// Console per-release setting, not a code change — see the note at the
/// bottom of this file.
///
/// IMPORTANT — THIS ONLY WORKS FOR PLAY-STORE-INSTALLED BUILDS. It always
/// silently no-ops on: iOS, debug builds, builds you sideload via `flutter
/// run`/APK, and Play builds before the app has ever been published. To
/// actually test this, upload a build to Play Console's internal testing
/// track, install it from that track's opt-in link, then upload a second,
/// higher-versionCode build and reopen the app.
class UpdateService {
  UpdateService._();

  static Future<void> checkForUpdate(BuildContext context) async {
    if (!Platform.isAndroid) return; // no Play Store equivalent on iOS

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (info.immediateUpdateAllowed) {
        // Full-screen native Play UI. The Future only completes once the
        // user has updated (or the update fails) — there's no way for
        // them to dismiss it and keep using the old version.
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      // Rare fallback: Play sometimes only allows a flexible (backgrounded)
      // update for a given release. We still force it — as soon as the
      // download finishes we restart the app into the new version
      // ourselves, instead of waiting for the user to tap a "Restart"
      // prompt, so the end result is still a forced update either way.
      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      // Expected and harmless outside a real Play Store install (debug
      // builds, sideloaded APKs, an app never published, etc).
      if (kDebugMode) debugPrint('In-app update check skipped: $e');
    }
  }
}

// Want SOME releases to be a soft/optional prompt instead of forced, while
// keeping others forced? Don't change this file — in Play Console, set
// that release's "in-app update priority" to 0–3 for optional and 4–5 for
// forced, and swap the `if (info.immediateUpdateAllowed)` check above for
// `if (info.updatePriority >= 4 && info.immediateUpdateAllowed)`, with a
// flexible (non-blocking, user-dismissible) path for the rest.

