import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/app_env.dart';

class SubscriptionService {
  SubscriptionService(this._env);

  final AppEnv _env;

  bool _initialized = false;

  bool get _hasApiKey =>
      _env.revenuecatKey != null && _env.revenuecatKey!.isNotEmpty;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (!_hasApiKey) {
      debugPrint(
        'RevenueCat API key missing; skipping Purchases initialization.',
      );
      return;
    }

    try {
      await Purchases.configure(PurchasesConfiguration(_env.revenuecatKey!));
      _initialized = true;
    } catch (error) {
      debugPrint('RevenueCat init failed: $error');
    }
  }

  Future<Offerings?> fetchOfferings() async {
    if (!_hasApiKey) {
      debugPrint('RevenueCat API key missing; returning null offerings.');
      return null;
    }

    if (!_initialized) {
      await initialize();

      if (!_initialized) {
        return null;
      }
    }

    try {
      return await Purchases.getOfferings();
    } catch (error, stackTrace) {
      debugPrint('Failed to fetch offerings: $error\n$stackTrace');
      return null;
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!_hasApiKey) {
      debugPrint('RevenueCat API key missing; cannot restore purchases.');
      return null;
    }

    try {
      return await Purchases.restorePurchases();
    } catch (error) {
      debugPrint('Restore purchases failed: $error');
      return null;
    }
  }

  Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!_hasApiKey) {
      debugPrint('RevenueCat API key missing; cannot initiate purchase.');
      return null;
    }

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo;
    } on PlatformException catch (error) {
      debugPrint('Purchase error: $error');
      return null;
    } catch (error) {
      debugPrint('Unhandled purchase error: $error');
      return null;
    }
  }
}
