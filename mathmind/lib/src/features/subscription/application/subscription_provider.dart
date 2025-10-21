import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../auth/application/auth_provider.dart';
import '../../../core/services/daily_limit_storage.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/details_limit_storage.dart';
import '../domain/subscription_plan.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider({
    required SubscriptionService service,
    required DailyLimitStorage dailyLimitStorage,
    required AuthProvider authProvider,
    required DetailsLimitStorage detailsLimitStorage,
  }) : _service = service,
       _dailyLimitStorage = dailyLimitStorage,
       _detailsLimitStorage = detailsLimitStorage,
       _authProvider = authProvider {
    _authProvider.addListener(_handleAuthChange);
    _handleAuthChange();
    unawaited(_initializeDailyLimitState());
    unawaited(_initializeDetailsLimitState());
  }

  static const int _freeDailyLimit = 3;
  static const int _freeDetailsLimit = 5;

  final SubscriptionService _service;
  final DailyLimitStorage _dailyLimitStorage;
  final DetailsLimitStorage _detailsLimitStorage;
  final AuthProvider _authProvider;

  SubscriptionTier _baseTier = SubscriptionTier.free;
  Offerings? _offerings;
  int _questionsAskedToday = 0;
  DateTime? _lastQuestionDate;
  bool _dailyStateInitialized = false;
  bool _forcePremium = false;

  // Details ("더 자세히 보기") daily counter
  int _detailsOpenedToday = 0;
  DateTime? _lastDetailsDate;
  bool _detailsStateInitialized = false;

  SubscriptionTier get activeTier =>
      _forcePremium ? SubscriptionTier.premium : _baseTier;
  Offerings? get offerings => _offerings;
  bool get isDailyLimitReady =>
      _dailyStateInitialized || activeTier != SubscriptionTier.free;

  bool get hasPremiumAccess => activeTier == SubscriptionTier.premium;
  bool get hasBasicAccess =>
      activeTier == SubscriptionTier.basic || hasPremiumAccess;
  int? get remainingDailyQuestions {
    if (activeTier != SubscriptionTier.free) {
      return null;
    }
    if (!_dailyStateInitialized) {
      return null;
    }
    return (_freeDailyLimit - _questionsAskedToday)
        .clamp(0, _freeDailyLimit)
        .toInt();
  }

  int? get remainingDailyDetails {
    if (activeTier != SubscriptionTier.free) return null;
    if (!_detailsStateInitialized) return null;
    return (_freeDetailsLimit - _detailsOpenedToday)
        .clamp(0, _freeDetailsLimit)
        .toInt();
  }

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
    if (activeTier != SubscriptionTier.free) {
      return true;
    }
    if (!_dailyStateInitialized) {
      return false;
    }
    _resetDailyCounterIfNeeded();
    if ((remainingDailyQuestions ?? 0) <= 0) {
      return false;
    }
    return true;
  }

  bool canOpenDetails() {
    if (activeTier != SubscriptionTier.free) return true;
    if (!_detailsStateInitialized) return false;
    _resetDetailsCounterIfNeeded();
    return (remainingDailyDetails ?? 0) > 0;
  }

  void registerQuestionAsked() {
    if (activeTier != SubscriptionTier.free) {
      return;
    }
    if (!_dailyStateInitialized) {
      return;
    }
    _resetDailyCounterIfNeeded();
    _questionsAskedToday += 1;
    _lastQuestionDate = DateTime.now();
    unawaited(_persistDailyState());
    notifyListeners();
  }

  void registerDetailsOpened() {
    if (activeTier != SubscriptionTier.free) return;
    if (!_detailsStateInitialized) return;
    _resetDetailsCounterIfNeeded();
    _detailsOpenedToday += 1;
    _lastDetailsDate = DateTime.now();
    unawaited(_persistDetailsState());
    notifyListeners();
  }

  void setTierForTesting(SubscriptionTier tier) {
    _baseTier = tier;
    notifyListeners();
  }

  void _applyCustomerInfo(CustomerInfo info) {
    final entitlements = info.entitlements.active;
    if (entitlements.containsKey('premium')) {
      _baseTier = SubscriptionTier.premium;
    } else if (entitlements.containsKey('basic')) {
      _baseTier = SubscriptionTier.basic;
    } else {
      _baseTier = SubscriptionTier.free;
    }
    notifyListeners();
  }

  Future<void> _initializeDailyLimitState() async {
    try {
      final snapshot = await _dailyLimitStorage.load();
      if (snapshot != null) {
        _questionsAskedToday = snapshot.questionsAsked;
        _lastQuestionDate = snapshot.date;
        final wasReset = _resetDailyCounterIfNeeded(persistOnReset: false);
        if (wasReset) {
          await _persistDailyState();
        }
      } else {
        _questionsAskedToday = 0;
        _lastQuestionDate = DateTime.now();
        await _persistDailyState();
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to load daily limit: $error\n$stackTrace');
      _questionsAskedToday = 0;
      _lastQuestionDate = DateTime.now();
    } finally {
      _dailyStateInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _initializeDetailsLimitState() async {
    try {
      final snapshot = await _detailsLimitStorage.load();
      if (snapshot != null) {
        _detailsOpenedToday = snapshot.detailsOpened;
        _lastDetailsDate = snapshot.date;
        final wasReset = _resetDetailsCounterIfNeeded(persistOnReset: false);
        if (wasReset) {
          await _persistDetailsState();
        }
      } else {
        _detailsOpenedToday = 0;
        _lastDetailsDate = DateTime.now();
        await _persistDetailsState();
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to load details limit: $error\n$stackTrace');
      _detailsOpenedToday = 0;
      _lastDetailsDate = DateTime.now();
    } finally {
      _detailsStateInitialized = true;
      notifyListeners();
    }
  }

  bool _resetDailyCounterIfNeeded({bool persistOnReset = true}) {
    final now = DateTime.now();
    if (_lastQuestionDate == null || !_isSameDay(now, _lastQuestionDate!)) {
      _questionsAskedToday = 0;
      _lastQuestionDate = now;
      if (persistOnReset) {
        unawaited(_persistDailyState());
      }
      return true;
    }
    return false;
  }

  bool _resetDetailsCounterIfNeeded({bool persistOnReset = true}) {
    final now = DateTime.now();
    if (_lastDetailsDate == null || !_isSameDay(now, _lastDetailsDate!)) {
      _detailsOpenedToday = 0;
      _lastDetailsDate = now;
      if (persistOnReset) {
        unawaited(_persistDetailsState());
      }
      return true;
    }
    return false;
  }

  Future<void> _persistDailyState() async {
    final dateToSave = _lastQuestionDate ?? DateTime.now();
    await _dailyLimitStorage.save(
      questionsAsked: _questionsAskedToday,
      date: dateToSave,
    );
  }

  Future<void> _persistDetailsState() async {
    final dateToSave = _lastDetailsDate ?? DateTime.now();
    await _detailsLimitStorage.save(
      detailsOpened: _detailsOpenedToday,
      date: dateToSave,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _handleAuthChange() {
    final email = _authProvider.currentUser?.email?.toLowerCase();
    final shouldForce = email == 'kms0715@gmail.com';
    if (_forcePremium == shouldForce) {
      return;
    }
    _forcePremium = shouldForce;
    notifyListeners();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChange);
    super.dispose();
  }
}
