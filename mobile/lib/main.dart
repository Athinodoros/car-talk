import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured -- push notifications disabled.
  }

  // Initialize Google Mobile Ads SDK (only on mobile platforms).
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      // AdMob not configured -- ads disabled.
    }
  }

  runApp(const ProviderScope(child: CarPostAllApp()));
}
