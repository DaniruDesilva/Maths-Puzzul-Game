import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';

class PurchaseService {
  // RevenueCat Public SDK API Keys
  // In production, paste your RevenueCat API keys from the dashboard:
  // https://app.revenuecat.com/ -> Project Settings -> API Keys
  static const String _androidApiKey = 'goog_rVRJkyjBDJluACDBuAyYWhhEILD';
  static const String _iosApiKey = '<YOUR_REVENUECAT_APPLE_API_KEY>';

  // Entitlement ID in RevenueCat for Ad-free play
  static const String entitlementRemoveAds = 'remove_ads';

  // Product Identifiers configured in Google Play Console / App Store Connect
  static const String productCoins250 = 'coins_250';
  static const String productCoins750 = 'coins_750';
  static const String productCoins2000 = 'coins_2000';
  static const String productCoins5000 = 'coins_5000';
  static const String productCoins12000 = 'coins_12000';

  static const String productHints10 = 'hints_10';
  static const String productHints30 = 'hints_30';
  static const String productHintsMega10 = 'hints_mega_10';
  static const String productHintsUltra5 = 'hints_ultra_5';

  static const String productWelcomePack = 'welcome_pack';
  static const String productRemoveAds = 'remove_ads';
  static const String productCozyStarterPack = 'cozy_starter_pack';
  static const String productCozyBundle = 'cozy_bundle';
  static const String productMasterBundle = 'master_bundle';
  static const String productFlashBundle = 'flash_starter_bundle';
  static const String productAcornVault = 'acorn_vault';

  static bool _isConfigured = false;
  static bool get isConfigured => _isConfigured;

  static bool get hasValidKey {
    if (kIsWeb) return false;
    try {
      final key = Platform.isIOS ? _iosApiKey : _androidApiKey;
      return !key.startsWith('<YOUR_');
    } catch (_) {
      return false;
    }
  }

  /// Initializes RevenueCat Purchases SDK
  static Future<void> initialize(UserProvider user) async {
    if (!hasValidKey) {
      debugPrint('PurchaseService: Running in development mode with simulated purchases.');
      return;
    }

    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      final key = Platform.isIOS ? _iosApiKey : _androidApiKey;
      final configuration = PurchasesConfiguration(key);
      await Purchases.configure(configuration);
      _isConfigured = true;

      // Check current entitlement status on startup
      final customerInfo = await Purchases.getCustomerInfo();
      _checkEntitlements(customerInfo, user);

      // Listen for entitlement changes (e.g. renewals, restores)
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _checkEntitlements(customerInfo, user);
      });
    } catch (e) {
      debugPrint('PurchaseService initialization error: $e');
    }
  }

  static void _checkEntitlements(CustomerInfo customerInfo, UserProvider user) {
    if (customerInfo.entitlements.active.containsKey(entitlementRemoveAds)) {
      if (!user.adsRemoved) {
        user.removeAds();
      }
    }
  }

  /// Initiates a purchase for a given product ID
  static Future<bool> purchase({
    required BuildContext context,
    required String productId,
    required String title,
    required UserProvider user,
    required VoidCallback onRewardGranted,
  }) async {
    if (!_isConfigured) {
      // Development mode fallback: grants item immediately
      onRewardGranted();
      return true;
    }

    try {
      final products = await Purchases.getProducts([productId]);
      if (products.isEmpty) {
        debugPrint('Warning: Product $productId not found in store catalogue. Granting in fallback mode.');
        onRewardGranted();
        return true;
      }

      final storeProduct = products.first;
      final purchaseResult = await Purchases.purchase(PurchaseParams.storeProduct(storeProduct));

      _checkEntitlements(purchaseResult.customerInfo, user);
      onRewardGranted();
      return true;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        if (context.mounted) {
          _showErrorDialog(context, 'Purchase failed: ${e.message ?? 'Unknown error'}');
        }
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Error processing purchase: $e');
      }
      return false;
    }
  }

  /// Restores previous purchases (Required by Apple App Store and Google Play)
  static Future<void> restorePurchases({
    required BuildContext context,
    required UserProvider user,
  }) async {
    if (!_isConfigured) {
      if (context.mounted) {
        _showInfoDialog(context, 'Restore Completed', 'Purchases successfully restored.');
      }
      return;
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      _checkEntitlements(customerInfo, user);
      if (customerInfo.entitlements.active.containsKey(entitlementRemoveAds)) {
        if (context.mounted) {
          _showInfoDialog(
            context,
            'Purchases Restored! 🎉',
            'Your "Remove Ads" permanent purchase was successfully restored.',
          );
        }
      } else {
        if (context.mounted) {
          _showInfoDialog(
            context,
            'Restore Completed',
            'No active non-consumable purchases were found on this account.',
          );
        }
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
