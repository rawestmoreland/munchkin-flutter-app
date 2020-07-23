import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// A class for the in app purchases in the app
/// List of product ids
/// Functions for accessing the products
/// Variables associated with getting and verifying products
class Purchase extends ChangeNotifier {
  Future<Map<String, dynamic>> setupPurchases() async {
    Stream purchaseUpdated =
        InAppPurchaseConnection.instance.purchaseUpdatedStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      print(error);
    });
    await initStoreInfo();

    Map<String, dynamic> purchaseInfo = {
      'purchased': purchased,
      'products': products
    };

    return purchaseInfo;
  }

  static const bool kAutoConsume = true;
  static const String _kConsumableId = 'munchkin_test';
  static const List<String> _kProductIds = <String>['munchkin_test'];

  final InAppPurchaseConnection _connection = InAppPurchaseConnection.instance;
  StreamSubscription<List<PurchaseDetails>> _subscription;
  List<String> _notFoundIds = [];
  List<ProductDetails> products = [];
  List<PurchaseDetails> _purchases = [];
  List<String> _consumables = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String _queryProductError;
  bool purchased = false;
  Map<String, dynamic> purchaseInfo;

  Future<void> initStoreInfo() async {
    FlutterInappPurchase.instance.clearTransactionIOS();
    final bool isAvailable = await _connection.isAvailable();
    if (!isAvailable) {
      print('The store is not available');
      _isAvailable = isAvailable;
      products = [];
      _purchases = [];
      _notFoundIds = [];
      _consumables = [];
      _purchasePending = false;
      _loading = false;
      return;
    } else {
      print('The store is open for business');
    }

    ProductDetailsResponse productDetailsResponse =
        await _connection.queryProductDetails(_kProductIds.toSet());
    if (productDetailsResponse.error != null) {
      print('Product details error not null');
      _queryProductError = productDetailsResponse.error.message;
      print(_queryProductError);
        _isAvailable = isAvailable;
        products = productDetailsResponse.productDetails;
        _purchases = [];
        _notFoundIds = productDetailsResponse.notFoundIDs;
        _consumables = [];
        _purchasePending = false;
        _loading = false;
      return;
    }

    if (productDetailsResponse.productDetails.isEmpty) {
      print('Product details empty');
      _queryProductError = null;
      _isAvailable = isAvailable;
      products = productDetailsResponse.productDetails;
      _purchases = [];
      _notFoundIds = productDetailsResponse.notFoundIDs;
      _consumables = [];
      _purchasePending = false;
      _loading = false;
      return;
    }

    final QueryPurchaseDetailsResponse response =
        await _connection.queryPastPurchases();
    if (response.error != null) {
      print('There was a past purchase error');
      print(response.error.message);
    }
    final List<PurchaseDetails> verifiedPurchases = [];
    for (PurchaseDetails purchase in response.pastPurchases) {
      print(purchase.productID);
      _purchases.add(purchase);
      if (await _verifyPurchase(purchase)) {
        if (Platform.isIOS) {
          _connection.completePurchase(purchase);
        }
        verifiedPurchases.add(purchase);
      }
    }
    for (var i in verifiedPurchases) {
      if (_kProductIds.contains(i.productID)) {
        purchased = true;
        print('You have paid to remove ads');
        print('Purchased: $purchased');
      }
    }
    _isAvailable = isAvailable;
    products = productDetailsResponse.productDetails;
    _purchases = verifiedPurchases;
    _notFoundIds = productDetailsResponse.notFoundIDs;
    _purchasePending = false;
    _loading = false;
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          handleError(purchaseDetails.error);
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          purchased = true;
          print('You have made a purchase');
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

  void showPendingUI() {
    _purchasePending = true;
  }

  void handleError(IAPError error) {
    _purchasePending = false;
  }

  void deliverProduct(PurchaseDetails purchaseDetails) async {
    _purchases.add(purchaseDetails);
    _purchasePending = false;
    print('Purchased: $purchased');
    print('product delivered');
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
    PurchaseDetails purchase = _hasPurchased(purchaseDetails.productID);
    if (purchase != null && purchase.status == PurchaseStatus.purchased) {
      purchased = true;
      return Future<bool>.value(false);
    } else {
      _handleInvalidPurchase(purchaseDetails);
      return Future<bool>.value(false);
    }
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    print('This is an invalid purchase');
  }

  PurchaseDetails _hasPurchased(String productID) {
    return _purchases.firstWhere((purchase) => purchase.productID == productID,
        orElse: () => null);
  }

  void buyProduct(ProductDetails prod) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);

    await _connection.buyConsumable(purchaseParam: purchaseParam);
  }
}
