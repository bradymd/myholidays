import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const _kProductIds = {'tip_small', 'tip_coffee'};

final tipJarProvider =
    AsyncNotifierProvider<TipJarNotifier, TipJarState>(TipJarNotifier.new);

class TipJarState {
  const TipJarState({
    this.products = const [],
    this.isPurchasing = false,
    this.lastError,
    this.lastSuccess = false,
  });

  final List<ProductDetails> products;
  final bool isPurchasing;
  final String? lastError;
  final bool lastSuccess;

  TipJarState copyWith({
    List<ProductDetails>? products,
    bool? isPurchasing,
    String? lastError,
    bool? lastSuccess,
  }) {
    return TipJarState(
      products: products ?? this.products,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      lastError: lastError,
      lastSuccess: lastSuccess ?? false,
    );
  }
}

class TipJarNotifier extends AsyncNotifier<TipJarState> {
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  Future<TipJarState> build() async {
    final iap = InAppPurchase.instance;
    final available = await iap.isAvailable();
    if (!available) {
      return const TipJarState(lastError: 'Store not available');
    }

    _subscription = iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        state = AsyncData(
          state.requireValue.copyWith(
            isPurchasing: false,
            lastError: error.toString(),
          ),
        );
      },
    );
    ref.onDispose(() => _subscription?.cancel());

    final response = await iap.queryProductDetails(_kProductIds);
    final products = response.productDetails
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

    return TipJarState(products: products);
  }

  void buy(ProductDetails product) {
    state = AsyncData(
      state.requireValue.copyWith(isPurchasing: true, lastSuccess: false),
    );
    final purchaseParam = PurchaseParam(productDetails: product);
    InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          InAppPurchase.instance.completePurchase(purchase);
          state = AsyncData(
            state.requireValue.copyWith(
              isPurchasing: false,
              lastSuccess: true,
            ),
          );
        case PurchaseStatus.error:
          state = AsyncData(
            state.requireValue.copyWith(
              isPurchasing: false,
              lastError: purchase.error?.message ?? 'Purchase failed',
            ),
          );
        case PurchaseStatus.pending:
          state = AsyncData(
            state.requireValue.copyWith(isPurchasing: true),
          );
        case PurchaseStatus.canceled:
          state = AsyncData(
            state.requireValue.copyWith(isPurchasing: false),
          );
      }
    }
  }
}
