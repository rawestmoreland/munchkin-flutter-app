import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// A class for the in app purchases in the app
/// List of product ids
/// Functions for accessing the products
/// Variables associated with getting and verifying products
class Purchase {
  Purchase() {
    Stream purchaseUpdated = InAppPurchaseConnection.instance.purchaseUpdatedStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // TODO: handle the error here
    });
    initStoreInfo();
  }

  static const bool kAutoConsume = true;
  static const String _kConsumabeId = '';
  static const List<String> _kProducts = <String>[
    'no_ads_munchkin',
  ];
  final InAppPurchaseConnection _connection = InAppPurchaseConnection.instance;
  StreamSubscription<List<PurchaseDetails>> _subscription;  
  List<String> _notFoundIds = [];
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  List<String> _consumables = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = false;
  String _queryProductError;
  bool purchased = false;

  Future<void> initStoreInfo() async {
    // If we have a stuck transaction - clear it from iOS
    FlutterInappPurchase.instance.clearTransactionIOS();
    final bool isAvailable = await _connection.isAvailable();
    if (!isAvailable) {
      print("The store is not available");
      _isAvailable = isAvailable;
      _products = [];
      _purchases = [];
      _notFoundIds = [];
      _consumables = [];
      _purchasePending = [];
      _loading = false;
      return;
    } else {
      print("The store is open for business");
    }

    ProductDetailsResponse productDetailResponse =
      await _connection.queryProductDetails(_kProductIds.toSet());
    if (productDetailsResponse.error != null) {
      _queryProductError = productDetailResponse.error.message;
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _purchases = [];
      _notFoundIds = productDetailResponse.notFoundIDs;
      _consumables = [];
      _purchasePending = false;
      _loading = false;
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      _queryProductError = null;
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _purchases = [];
      _notFoundIds = productDetailResponse.notFoundIDs;
      _consumables = [];
      _purchasePending = false;
      _loading = false;
      return;
    }

    final QueryPurchaseDetailsResponse response =
      await _connection.queryPastPurchases();
    if (response.error != null) {
      // TODO: handle query past purchase error
    }
    final List<PurchaseDetails> verifiedPurchases = [];
    for (PurchaseDetails purchase in response.pastPurchases) {
      _purchases.add(purchase);
      if (await _verifyPurchase(purchase)) {
        if (Platform.isIOS) {
          _connection.completePurchase(purchase);
        }
        verifiedPurchases.add(purchase);
      }
    }
    for (var i in verifiedPurchases) {
      if (i.productID == 'no_ads_munchkin') {
        purchased = true;
        print("You have purchased an upgraded thing");
        print("Purchased: $purchased");
      }
    }
    _isAvailable = isAvailable;
    _products = productDetailResponse.productDetails;
    _purchases = verifiedPurchases;
    _notFoundIds = productDetailResponse.notFoundIDs;
    _purchasePending = false;
    _loading = false;
  }

  void showPendingUI() {
    _purchasePending = true;
  }

  void deliverProduct(PurchaseDetails purchaseDetails) async {
    _purchases.add(purchaseDetails);
    _purchasePending = false;
    purchased = true;
    print("Purchased: $purchased");
    print("product delivered");
  }

  void handleError(IAPError error) {
    _purchasePending = false;
  }

  /// Returns purchase of specific product ID
  PurchaseDetails _hasPurchased(String productID) {
    return _purchases.firstWhere((purchase) => purchase.productID == productID,
        orElse: () => null);
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
    // IMPORTANT!! Always verify a purchase before delivering the product.
    // For the purpose of an example, we directly return true.
    PurchaseDetails purchase = _hasPurchased(purchaseDetails.productID);
    if (purchase != null && purchase.status == PurchaseStatus.purchased) {
      purchased = true;
      return Future<bool>.value(true);
    } else {
      _handleInvalidPurchase(purchaseDetails);
      return Future<bool>.value(false);
    }
  }
  
  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    print("This is an invalid purchase");
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          handleError(purchaseDetails.error);
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          print("You have purchased the thing");
          deliverProduct(purchaseDetails);
        } else {
          _handleInvalidPurchase(purchaseDetails);
        }
        if (Platform.isIOS) {
          InAppPurchaseConnection.instance.completePurchase(purchaseDetails);
        } else if (Platform.isAndroid) {
          if (!kAutoConsume && purchaseDetails.productID == _kConsumableId) {
            InAppPurchaseConnection.instance.consumePurchase(purchaseDetails);
          }
        }
      }
    });
  }

  void _buyProduct(ProductDetails prod) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);

    _connection.buyNonConsumable(purchaseParam: purchaseParam);
  }
}
