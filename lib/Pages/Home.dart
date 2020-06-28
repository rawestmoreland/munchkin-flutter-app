import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:munchkin/widgets/PlayerGridList.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';


const bool kAutoConsume = true;
const String _kConsumableId = '';
const List<String> _kProductIds = <String>[
  'no_ads_munchkin',
];

class Home extends StatefulWidget {

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  // Initialize the in app purchase things
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
  bool purchased = false;

  GlobalKey<ScaffoldState> scaffoldState = GlobalKey();

  bool editing = false;


  /// Variables
  var playerName = '';
  var playerNameController = TextEditingController();
  // The list of players - a list of Maps
  var _players = [];

  /// Functions
  // Get players from shared prefs
  // Check for purchases
  Future<void> _initSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // prefs.clear();
    String playerString = prefs.getString('players');
    List playerList;
    if (playerString != null) {
      playerList = await json.decode(playerString);
      setState(() {
        _players = playerList;
        purchased = prefs.getBool('purchased') ?? false;
      });
    }
  }
  // Save players to dhared prefs
  Future<void> _savePlayersToSharedPrefs(players) async {
    final prefs = await SharedPreferences.getInstance();
    // New list to hold the encoded json objects
    List playerSave = [];
    // JSON encode all player maps before saving to shared prefs
    for (var player in players) {
      player = json.encode(player);
      playerSave.add(player);
    }
    // Save it
    await prefs.setString('players', playerSave.toString());
  }
  // Add a player to the players list
  void _addPlayer(name, context) {

    var player = {};

    player["name"] = name;

    player["score"] = 1;

    _players.add(player);

    // Save players list to shared prefs (local storage)
    _savePlayersToSharedPrefs(_players);
    // Dismiss the dialog
    Navigator.pop(context);
    // Text controller back to empty
    playerNameController.text = "";
  }
  // Update the player name as the user types in the text field
  void _updatePlayerName() {
    setState(() {
      playerName = playerNameController.text;
    });
  }

  // Deal with the new player dialog dialog
  void showAddPlayerDialog(BuildContext context) {
      void dismissDialog(context) {
        Navigator.pop(context);
        playerNameController.text = "";
      }
      // The dialog
      AlertDialog addPlayer = AlertDialog(
        title: Text("add a player"),
        content: TextField(controller: playerNameController, decoration: InputDecoration(hintText: "player name"), style: TextStyle(fontFamily: 'Architects Daughter'), textCapitalization: TextCapitalization.characters,),
        actions: <Widget>[
          FlatButton(onPressed: () => _addPlayer(playerNameController.text, context), child: Text("add")),
          FlatButton(onPressed: () => dismissDialog(context), child: Text("cancel"))
        ],
      );
      // show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return addPlayer;
        },
      );
  }

  void showDeletePlayerDialog(BuildContext context, playerName) {
    // Variable to hold the index of the player we're deleting.
    int playerIndex;
        AlertDialog deletePlayer = AlertDialog(
          content: Text("Are you sure you want to delete $playerName?", style: TextStyle(fontFamily: "Architects Daughter")),
          actions: <Widget>[
            FlatButton(
              child: Text("No"),
              onPressed: () => {
                setState(() {
                  editing = false;
                }),
                Navigator.pop(context)
              },
            ),
            FlatButton(
              child: Text("Yes"),
              onPressed: () => {
                playerIndex = _players.indexWhere((player) => player['name'] == playerName),
                _players.removeAt(playerIndex),
                _savePlayersToSharedPrefs(_players),
                setState(() {
                  editing = false;
                }),
                Navigator.pop(context)
          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return deletePlayer;
      }
    );
  }

  void showNewGameDialog(BuildContext context) {
    AlertDialog newGameDialog = AlertDialog(
      content: Text("Are you sure you want to reset all scores?", style: TextStyle(fontFamily: "Architects Daughter")),
      actions: <Widget>[
            FlatButton(
              child: Text("No"),
              onPressed: () => {
                Navigator.pop(context)
              },
            ),
            FlatButton(
              child: Text("Yes"),
              onPressed: () => {
                newGame(),
                _savePlayersToSharedPrefs(_players),
                Navigator.pop(context)
          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return newGameDialog;
      }
    );
  }

  @override
  void initState() {
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
    super.initState();
    playerNameController.addListener(_updatePlayerName);
    editing = false;
    _initSharedPrefs();
  }

    @override
    void dispose() {
      _subscription.cancel();
      // Clean up the controller when the widget is removed from the widget tree
      playerNameController.dispose();
      super.dispose();
    }
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Munchkin Levels'.toUpperCase(), style: TextStyle(fontFamily: 'Architects Daughter', fontWeight: FontWeight.bold),),
          centerTitle: true,
          leading: IconButton(icon: !editing ? Icon(Icons.edit) : Icon(Icons.cancel), onPressed: () => {handleEditButton()}),
          backgroundColor: Colors.brown[700],
          actions: <Widget>[
            IconButton(icon: Icon(Icons.add), onPressed: () => {showAddPlayerDialog(context)}),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.brown[700],
          child: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FlatButton(
                  child: Text("New Game", style: TextStyle(color: Colors.white),),
                  onPressed: () => {
                    showNewGameDialog(context)
                  },
                ),
                !purchased ?
                FlatButton(
                  child: Text("Remove Ads", style: TextStyle(color: Colors.white),),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text("Remove ads from Munchkin Levels for \$0.99?", textAlign: TextAlign.center,),
                                    SizedBox(height: 30.0,),
                                    FlatButton(
                                      color: Colors.blue,
                                      child: Text("Yes, remove ads for \$0.99", style: TextStyle(color: Colors.white),),
                                      onPressed: () => {
                                        _buyProduct(_products[0]),
                                        Navigator.pop(context)
                                      },
                                    ),
                                    SizedBox(height: 30.0),
                                    Text(
                                      (Platform.isIOS)
                                        ? "Payment will be charged to your Apple ID account at the confirmation of purchase."
                                        : "Payment will be charged to your Google Play account at the confirmation of purchase.",
                                        style: TextStyle(fontSize: 10.0), textAlign: TextAlign.center
                                    ),
                                    SizedBox(height: 10.0),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        InkWell(
                                          child: Text("privacy policy", style: TextStyle(fontSize: 10.0, color: Colors.blue)),
                                          onTap: () async {
                                            const privacyUrl = "https://app.termly.io/document/privacy-policy/28251f47-3c81-4ae6-a9bc-61d11cb036d2";
                                            if (await canLaunch(privacyUrl)) {
                                              await launch(privacyUrl);
                                            } else {
                                              throw 'Could not launch privacy URL';
                                            }
                                          }
                                        ),
                                        Text(" and ", style: TextStyle(fontSize: 10.0),),
                                        InkWell(
                                          child: Text("terms and conditions", style: TextStyle(fontSize: 10.0, color: Colors.blue)),
                                          onTap: () async {
                                            const termsUrl = "https://www.websitepolicies.com/policies/view/OGLePPlG";
                                            if (await canLaunch(termsUrl)) {
                                              await launch(termsUrl);
                                            } else {
                                              throw 'Could not launch terms URL';
                                            }
                                          }
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text("NO THANKS", style: TextStyle(color: Colors.red)),
                                  onPressed: () => {
                                    Navigator.pop(context)
                                  },
                                )
                              ],
                            )
                          ),
                        );
                      }
                    ),
                  },
                ) : Container(height: 0, width: 0,)
              ]
            ,)
          ),
        ),
        body: Container(
          height: MediaQuery.of(context).size.height * 2,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/Paper-Texture-.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: Container(
                  child: PlayerGridList(),
                ),
              ),
              // Show the ad if no purchase has been made
              !purchased ?
              Positioned(
                bottom: 0,
                child: Container(
                  color: Colors.transparent,
                  width: MediaQuery.of(context).size.width,
                  child: AdmobBanner(
                  adSize: AdmobBannerSize.BANNER,
                  adUnitId: getBannerAdUnitId(),
                    ),
                ),
              ) : Container()
            ],
          ),
        ),
      );
    }
  
    // Function to show either a delete button or the score keeping row
    Widget scoreOrDelete(bool editing, player) {
      if (!editing) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              onPressed: () => {player["score"] > 1 ? changeScore(player["name"], "down") : null},
              icon: Icon(Icons.remove),
            ),
            Text("${player['score']}", style: TextStyle(fontFamily: "Architects Daughter", fontSize: 40),),
            IconButton(
              onPressed: () => {player["score"] <= 9 ? changeScore(player["name"], "up") : null},
              icon: Icon(Icons.add),
            ),
          ],
        );
      }
  
      return IconButton(icon: Icon(Icons.delete), onPressed: () => {showDeletePlayerDialog(context, player["name"])}, iconSize: 42.0, color: Colors.red,);
    }
  
    void handleEditButton() {
      setState(() {
        editing = !editing;
      });
    }
  
    void changeScore(playerName, upOrDown) {
      // get the index of the object that contains our player
      var playerIndex = _players.indexWhere((player) => player["name"] == playerName);
      setState(() {
        if (upOrDown == "up") {
          _players[playerIndex]["score"] += 1;
        } else {
          _players[playerIndex]["score"] -= 1;
        }
      });
      _savePlayersToSharedPrefs(_players);
    }
  
    void newGame() {
      for (var i = 0; i < _players.length; i++) {
        _players[i]['score'] = 1;
      }
      setState(() {
        _players = _players;
      });
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
      // handle query past purchase error..
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
        setState(() {
          purchased = true;
          print("You have purchased an upgraded thing");
          print("Purchased: $purchased");
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
      purchased = true;
      print("Purchased: $purchased");
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
        purchased = true;
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

  String getBannerAdUnitId() {
    if (Platform.isIOS) {
      return "ca-app-pub-7987021525697218/5612379282";
    } else if (Platform.isAndroid) {
      return "ca-app-pub-7987021525697218/6921290209";
    }
    return null;
  }
}