import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/services/subscription_service.dart';
import '../domain/subscription_plan.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider({required SubscriptionService service})
    : _service = service;

  final SubscriptionService _service;

  SubscriptionTier _activeTier = SubscriptionTier.free;
  Offerings? _offerings;
  int _questionsAskedToday = 0;
  DateTime? _lastQuestionDate;

  SubscriptionTier get activeTier => _activeTier;
  Offerings? get offerings => _offerings;

  bool get hasPremiumAccess => _activeTier == SubscriptionTier.premium;
  bool get hasBasicAccess =>
      _activeTier == SubscriptionTier.basic ||
      _activeTier == SubscriptionTier.premium;
  int? get remainingDailyQuestions => _activeTier == SubscriptionTier.free
      ? (5 - _questionsAskedToday).clamp(0, 5).toInt()
      : null;

  Future<void> loadOfferings() async {
    _offerings = await _service.fetchOfferings();
    notifyListeners();
  }

  Future<void> restore() async {
    final info = await _service.restorePurchases();
    if (info != null) {
      _applyCustomerInfo(info);
    }
  }

  Future<void> purchasePlan(Package package) async {
    final info = await _service.purchasePackage(package);
    if (info != null) {
      _applyCustomerInfo(info);
    }
  }

  bool canAskNewQuestion() {
    _resetDailyCounterIfNeeded();
    if (_activeTier == SubscriptionTier.free &&
        (remainingDailyQuestions ?? 0) <= 0) {
      return false;
    }
    return true;
  }

  void registerQuestionAsked() {
    _resetDailyCounterIfNeeded();
    _questionsAskedToday += 1;
    _lastQuestionDate = DateTime.now();
    notifyListeners();
  }

  void setTierForTesting(SubscriptionTier tier) {
    _activeTier = tier;
    notifyListeners();
  }

  void _applyCustomerInfo(CustomerInfo info) {
    final entitlements = info.entitlements.active;
    if (entitlements.containsKey('premium')) {
      _activeTier = SubscriptionTier.premium;
    } else if (entitlements.containsKey('basic')) {
      _activeTier = SubscriptionTier.basic;
    } else {
      _activeTier = SubscriptionTier.free;
    }
    notifyListeners();
  }

  void _resetDailyCounterIfNeeded() {
    final now = DateTime.now();
    if (_lastQuestionDate == null ||
        now.year != _lastQuestionDate!.year ||
        now.month != _lastQuestionDate!.month ||
        now.day != _lastQuestionDate!.day) {
      _questionsAskedToday = 0;
      _lastQuestionDate = now;
    }
  }
}
