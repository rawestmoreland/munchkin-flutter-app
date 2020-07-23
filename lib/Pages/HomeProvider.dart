import 'dart:async';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:munchkin/models/PlayerList.dart';
import 'package:munchkin/widgets/PlayerGridList.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../controllers/Controller.dart';

class HomeProvider extends StatefulWidget {
  @override
  _HomeProviderState createState() => _HomeProviderState();
}

const bool kAutoConsume = true;

const String _kConsumableId = '';
const List<String> _kProductIds = <String>['no_ads_munchkin_flutter'];

class _HomeProviderState extends State<HomeProvider> {
  final InAppPurchaseConnection _connection = InAppPurchaseConnection.instance;
  StreamSubscription<List<PurchaseDetails>> _subscription;
  List<String> _notFoundIds = [];
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  List<String> _consumables = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String _queryProductError;
  bool _purchased = false;

  @override
  void initState() {
    super.initState();
    Stream purchaseUpdated =
        InAppPurchaseConnection.instance.purchaseUpdatedStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // handle error here.
    });
    initStoreInfo();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerList = Provider.of<PlayerList>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Munchkin Levels'.toUpperCase(),
            style: TextStyle(
                fontFamily: 'Architects Daughter',
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: Consumer<PlayerList>(
          builder: (context, playerList, child) => IconButton(
              icon: !playerList.editing ? Icon(Icons.edit) : Icon(Icons.cancel),
              onPressed: () =>
                  {playerList.handleEditButton(playerList.editing)}),
        ),
        backgroundColor: Colors.brown[700],
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.add),
              onPressed: () => {
                    showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          TextEditingController playerNameController =
                              TextEditingController();
                          return AlertDialog(
                            title: Text("add a player"),
                            content: TextField(
                              controller: playerNameController,
                              decoration:
                                  InputDecoration(hintText: "player name"),
                              style:
                                  TextStyle(fontFamily: "Architects Daughter"),
                              textCapitalization: TextCapitalization.characters,
                            ),
                            actions: <Widget>[
                              FlatButton(
                                  onPressed: () => {
                                        playerList.addPlayer(
                                            playerNameController.text),
                                        Navigator.pop(context),
                                        playerNameController.text = ""
                                      },
                                  child: Text("add")),
                              FlatButton(
                                  onPressed: () => {
                                        Navigator.pop(context),
                                        playerNameController.text = ""
                                      },
                                  child: Text("cancel"))
                            ],
                          );
                        })
                  })
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.brown[700],
        child: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FlatButton(
                child: Text("New Game", style: TextStyle(color: Colors.white)),
                onPressed: () => {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: Text(
                              "Are you sure you want to reset all scores?",
                              style:
                                  TextStyle(fontFamily: 'Architects Daughter')),
                          actions: <Widget>[
                            FlatButton(
                              child: Text("No"),
                              onPressed: () => {Navigator.pop(context)},
                            ),
                            FlatButton(
                              child: Text("Yes"),
                              onPressed: () => {
                                playerList.newGame(),
                                Navigator.pop(context)
                              },
                            )
                          ],
                        );
                      })
                },
              ),
              (!_purchased)
                  ? FlatButton(
                      child: Text("Remove Ads",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () => {
                            showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (BuildContext context) {
                                  return Center(
                                    child: SingleChildScrollView(
                                        child: AlertDialog(
                                      content: Container(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              "Remove ads from Munchkin Levels for \$0.99?",
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(
                                              height: 30.0,
                                            ),
                                            FlatButton(
                                              color: Colors.blue,
                                              child: Text(
                                                "Yes, remove ads for \$0.99",
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                              onPressed: () => {
                                                Navigator.pop(context),
                                                _buyProduct(_products[0]),
                                              },
                                            ),
                                            SizedBox(height: 30.0),
                                            Text(
                                                (Platform.isIOS)
                                                    ? "Payment will be charged to your Apple ID account at the confirmation of purchase."
                                                    : "Payment will be charged to your Google Play account at the confirmation of purchase.",
                                                style:
                                                    TextStyle(fontSize: 10.0),
                                                textAlign: TextAlign.center),
                                            SizedBox(height: 10.0),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                InkWell(
                                                    child: Text(
                                                        "privacy policy",
                                                        style: TextStyle(
                                                            fontSize: 10.0,
                                                            color:
                                                                Colors.blue)),
                                                    onTap: () async {
                                                      const privacyUrl =
                                                          "https://app.termly.io/document/privacy-policy/28251f47-3c81-4ae6-a9bc-61d11cb036d2";
                                                      if (await canLaunch(
                                                          privacyUrl)) {
                                                        await launch(
                                                            privacyUrl);
                                                      } else {
                                                        throw 'Could not launch privacy URL';
                                                      }
                                                    }),
                                                Text(
                                                  " and ",
                                                  style:
                                                      TextStyle(fontSize: 10.0),
                                                ),
                                                InkWell(
                                                    child: Text(
                                                        "terms and conditions",
                                                        style: TextStyle(
                                                            fontSize: 10.0,
                                                            color:
                                                                Colors.blue)),
                                                    onTap: () async {
                                                      const termsUrl =
                                                          "https://www.websitepolicies.com/policies/view/OGLePPlG";
                                                      if (await canLaunch(
                                                          termsUrl)) {
                                                        await launch(termsUrl);
                                                      } else {
                                                        throw 'Could not launch terms URL';
                                                      }
                                                    }),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text("NO THANKS",
                                              style:
                                                  TextStyle(color: Colors.red)),
                                          onPressed: () =>
                                              {Navigator.pop(context)},
                                        )
                                      ],
                                    )),
                                  );
                                }),
                          })
                  : Container(
                      height: 0,
                      width: 0,
                    ),
            ],
          ),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height * 2,
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/Paper-Texture-.png'),
              fit: BoxFit.cover),
        ),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Container(
                child: Consumer<PlayerList>(
                    builder: (context, playerList, child) =>
                        PlayerGridList(players: playerList.playerList)),
              ),
            ),
            !_purchased
                ? Positioned(
                    bottom: 0,
                    child: Container(
                      color: Colors.transparent,
                      width: MediaQuery.of(context).size.width,
                      child: AdmobBanner(
                        adSize: AdmobBannerSize.BANNER,
                        adUnitId: Controller.getBannerAdUnitId(),
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Future<void> initStoreInfo() async {
    FlutterInappPurchase.instance.clearTransactionIOS();
    final bool isAvailable = await _connection.isAvailable();
    if (!isAvailable) {
      print("The store is not available");
      setState(() {
        _isAvailable = isAvailable;
        _products = [];
        _purchases = [];
        _notFoundIds = [];
        _consumables = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    } else {
      print("The store is available");
    }

    ProductDetailsResponse productDetailResponse =
        await _connection.queryProductDetails(_kProductIds.toSet());
    if (productDetailResponse.error != null) {
      print("Product Details Response Error: " +
          productDetailResponse.error.message);
      setState(() {
        _queryProductError = productDetailResponse.error.message;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = [];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _consumables = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      print("Product Details Response is Empty");
      setState(() {
        _queryProductError = null;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = [];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _consumables = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    final QueryPurchaseDetailsResponse response =
        await _connection.queryPastPurchases();
    if (response.error != null) {
      print("There was a past purchases error: " + response.error.message);
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
      if (i.productID == 'no_ads_munchkin_flutter') {
        setState(() {
          _purchased = true;
          // Firestore.instance
          //     .collection("users")
          //     .document(userUID)
          //     .updateData({"paid": true});
          print("You have purchased an upgraded thing");
          print("Purchased: $_purchased");
        });
      }
    }
    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _purchases = verifiedPurchases;
      _notFoundIds = productDetailResponse.notFoundIDs;
      _purchasePending = false;
      _loading = false;
    });

    print(_products);
  }

  void showPendingUI() {
    setState(() {
      _purchasePending = true;
    });
  }

  void deliverProduct(PurchaseDetails purchaseDetails) async {
    // IMPORTANT!! Always verify a purchase purchase details before delivering the product.
    setState(() {
      _purchases.add(purchaseDetails);
      _purchasePending = false;
      _purchased = true;
      print("Purchased: $_purchased");
      print("product delivered");
    });
  }

  void handleError(IAPError error) {
    setState(() {
      _purchasePending = false;
    });
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
      setState(() {
        _purchased = true;
      });
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
          if (kAutoConsume && purchaseDetails.productID == _kConsumableId) {
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
