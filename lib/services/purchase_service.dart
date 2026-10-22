import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';

class PurchaseService {
  // Product Identifiers configured in Google Play Console
  static const String productCoins250 = 'coins_250';
  static const String productCoins750 = 'coins_750';
  static const String productCoins2000 = 'coins_2000';
  static const String productCoins5000 = 'coins_5000';
  static const String productCoins12000 = 'coins_12000';

  static const String productHints10 = 'hints_10';
  static const String productHints30 = 'hints_30';
  static const String productHints75 = 'hints_75';
  static const String productHintsMega10 = 'hints_mega_10';
  static const String productHintsMega15 = 'hints_mega_15';
  static const String productHintsUltra5 = 'hints_ultra_5';
  static const String productHintsUltra8 = 'hints_ultra_8';

  static const String productWelcomePack = 'welcome_pack';
  static const String productRemoveAds = 'remove_ads';
  static const String productCozyStarterPack = 'cozy_starter_pack';
  static const String productCozyBundle = 'cozy_bundle';
  static const String productMasterBundle = 'master_bundle';
  static const String productFlashBundle = 'flash_starter_bundle';
  static const String productAcornVault = 'acorn_vault';

  static const Set<String> nonConsumableIds = {
    productRemoveAds,
  };

  static const List<String> allProductIds = [
    productCoins250,
    productCoins750,
    productCoins2000,
    productCoins5000,
    productCoins12000,
    productHints10,
    productHints30,
    productHints75,
    productHintsMega10,
    productHintsMega15,
    productHintsUltra5,
    productHintsUltra8,
    productWelcomePack,
    productRemoveAds,
    productCozyStarterPack,
    productCozyBundle,
    productMasterBundle,
    productFlashBundle,
    productAcornVault,
  ];

  static bool get _isInTest {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static final Map<String, ProductDetails> _productsMap = {};
  static Map<String, ProductDetails> get productsMap => _productsMap;

  static UserProvider? _cachedUser;
  static final Map<String, VoidCallback> _pendingCallbacks = {};

  static bool _isAvailable = false;
  static bool get isConfigured => _isAvailable;

  /// Initializes Google Play / App Store In-App Purchases
  static Future<void> initialize(UserProvider user) async {
    _cachedUser = user;
    if (_isInTest) {
      _isAvailable = true;
      return;
    }

    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        debugPrint('PurchaseService: InAppPurchase is not available on this device');
        return;
      }

      _subscription?.cancel();
      _subscription = _iap.purchaseStream.listen(
        (purchaseDetailsList) {
          _handlePurchaseUpdates(purchaseDetailsList);
        },
        onDone: () {
          _subscription?.cancel();
        },
        onError: (error) {
          debugPrint('PurchaseService: purchaseStream error: $error');
        },
      );

      // Pre-fetch store products
      await fetchProducts();
    } catch (e) {
      debugPrint('PurchaseService initialization error: $e');
    }
  }

  static Future<void> fetchProducts() async {
    if (_isInTest) return;
    try {
      final isAvailable = await _iap.isAvailable();
      if (!isAvailable) return;

      final ProductDetailsResponse response =
          await _iap.queryProductDetails(allProductIds.toSet());
      if (response.error != null) {
        debugPrint('Error querying product details: ${response.error}');
      }
      for (final p in response.productDetails) {
        _productsMap[p.id] = p;
      }
      debugPrint('PurchaseService: Loaded ${_productsMap.length} products from store.');
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  static String getPrice(String productId, {String fallbackPrice = ''}) {
    final prod = _productsMap[productId];
    if (prod != null && prod.price.isNotEmpty) {
      return prod.price;
    }
    return fallbackPrice;
  }

  /// Initiates a purchase for a given product ID via Google Play
  static Future<bool> purchase({
    required BuildContext context,
    required String productId,
    required String title,
    required UserProvider user,
    required VoidCallback onRewardGranted,
  }) async {
    _cachedUser = user;

    if (_isInTest) {
      onRewardGranted();
      return true;
    }

    try {
      final isAvailable = await _iap.isAvailable();
      if (!isAvailable) {
        if (context.mounted) {
          _showErrorDialog(
            context,
            'Google Play Billing service is currently unavailable on this device. Please check your internet connection or Google Play Store app.',
          );
        }
        return false;
      }

      ProductDetails? productDetails = _productsMap[productId];
      if (productDetails == null) {
        // Fetch product on demand if not cached
        final response = await _iap.queryProductDetails({productId});
        if (response.productDetails.isNotEmpty) {
          productDetails = response.productDetails.first;
          _productsMap[productId] = productDetails;
        }
      }

      if (productDetails == null) {
        debugPrint('Product $productId not yet available in store catalogue');
        if (context.mounted) {
          _showErrorDialog(
            context,
            'Product "$title" ($productId) is not yet active in your Google Play Console catalogue.\n\n'
            'Please ensure:\n'
            '• The in-app product status is "Active" in Play Console.\n'
            '• Your Google account is added under Play Console > Setup > License testing.\n'
            '• You have accepted the Closed Testing invite link on this device.',
          );
        }
        return false;
      }

      // Register callback to be invoked once purchase is confirmed
      _pendingCallbacks[productId] = onRewardGranted;

      final purchaseParam = PurchaseParam(productDetails: productDetails);
      final isConsumable = !nonConsumableIds.contains(productId);

      if (isConsumable) {
        await _iap.buyConsumable(purchaseParam: purchaseParam);
      } else {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
      return true;
    } catch (e) {
      _pendingCallbacks.remove(productId);
      if (context.mounted) {
        _showErrorDialog(context, 'Unable to launch Google Play purchase: $e');
      }
      return false;
    }
  }

  static void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('Purchase pending: ${purchaseDetails.productID}');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          debugPrint('Purchase succeeded: ${purchaseDetails.productID}');

          // Check if it includes removing ads
          if (purchaseDetails.productID == productRemoveAds ||
              purchaseDetails.productID == productWelcomePack) {
            _cachedUser?.removeAds();
          }

          // Trigger reward callback
          final callback = _pendingCallbacks.remove(purchaseDetails.productID);
          if (callback != null) {
            callback.call();
          } else if (_cachedUser != null) {
            _grantFallbackReward(purchaseDetails.productID, _cachedUser!);
          }

          // Acknowledge/consume purchase with Google Play
          if (purchaseDetails.pendingCompletePurchase) {
            try {
              await _iap.completePurchase(purchaseDetails);
            } catch (e) {
              debugPrint('Error completing purchase: $e');
            }
          }
          break;

        case PurchaseStatus.error:
          debugPrint('Purchase error: ${purchaseDetails.error}');
          _pendingCallbacks.remove(purchaseDetails.productID);
          break;

        case PurchaseStatus.canceled:
          debugPrint('Purchase canceled: ${purchaseDetails.productID}');
          _pendingCallbacks.remove(purchaseDetails.productID);
          break;
      }
    }
  }

  static void _grantFallbackReward(String productId, UserProvider user) {
    switch (productId) {
      case productCoins250:
        user.addCoins(250);
        break;
      case productCoins750:
        user.addCoins(750);
        break;
      case productCoins2000:
        user.addCoins(2000);
        break;
      case productCoins5000:
        user.addCoins(5000);
        break;
      case productCoins12000:
        user.addCoins(12000);
        break;
      case productHints10:
        user.addHint(10);
        break;
      case productHints30:
        user.addHint(30);
        break;
      case productHints75:
        user.addHint(75);
        break;
      case productHintsMega10:
        user.addMegaHint(5);
        break;
      case productHintsMega15:
        user.addMegaHint(15);
        break;
      case productHintsUltra5:
        user.addUltraHint(5);
        break;
      case productHintsUltra8:
        user.addUltraHint(8);
        break;
      case productRemoveAds:
        user.removeAds();
        break;
      case productWelcomePack:
        user.removeAds();
        user.addCoins(500);
        user.addHint(10);
        user.addMegaHint(3);
        break;
      case productCozyStarterPack:
        user.addCoins(400);
        user.addHint(15);
        user.addMegaHint(2);
        break;
      case productCozyBundle:
        user.addCoins(1000);
        user.addHint(30);
        user.addMegaHint(5);
        user.addUltraHint(2);
        break;
      case productMasterBundle:
        user.addCoins(3000);
        user.addHint(75);
        user.addMegaHint(15);
        user.addUltraHint(5);
        break;
      case productFlashBundle:
        user.addCoins(600);
        user.addHint(20);
        user.addMegaHint(3);
        break;
      case productAcornVault:
        user.crackAcornVault();
        break;
    }
  }

  /// Restores previous purchases
  static Future<void> restorePurchases({
    required BuildContext context,
    required UserProvider user,
  }) async {
    _cachedUser = user;
    if (_isInTest) {
      if (context.mounted) {
        _showInfoDialog(context, 'Restore Completed', 'Purchases successfully restored.');
      }
      return;
    }

    try {
      await _iap.restorePurchases();
      if (context.mounted) {
        _showInfoDialog(
          context,
          'Restore Completed',
          user.adsRemoved
              ? 'Your "Remove Ads" permanent purchase was successfully restored!'
              : 'Purchase check completed.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to restore purchases: $e');
      }
    }
  }

  static void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF7A451A), width: 3),
        ),
        title: Text(
          title,
          style: GoogleFonts.lilitaOne(color: const Color(0xFF5D4037), fontSize: 18),
        ),
        content: Text(
          message,
          style: GoogleFonts.baloo2(color: const Color(0xFF5D4037), fontSize: 14.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: GoogleFonts.lilitaOne(color: const Color(0xFF8B5A2B))),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE53935), width: 2.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 24),
            const SizedBox(width: 8),
            Text(
              'PURCHASE NOTICE',
              style: GoogleFonts.lilitaOne(color: const Color(0xFFB71C1C), fontSize: 17),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.baloo2(color: const Color(0xFF5D4037), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: GoogleFonts.lilitaOne(color: const Color(0xFF8B5A2B))),
          ),
        ],
      ),
    );
  }
}
