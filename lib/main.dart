import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:munchkin/models/PlayerList.dart';
import 'package:provider/provider.dart';

// import pages
import 'Pages/Home.dart';
import 'package:munchkin/Pages/HomeProvider.dart';
import 'models/Dialogs.dart';
import 'models/PlayerList.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Admob.initialize(getAppId());
  InAppPurchaseConnection.enablePendingPurchases();
  runApp(MyApp());
  }

  class MyApp extends StatefulWidget {
    @override
    _MyAppState createState() => _MyAppState();
  }
  
  class _MyAppState extends State<MyApp> {
    GlobalKey<ScaffoldState> scaffoldState = GlobalKey();
    AdmobBannerSize bannerSize;
    AdmobInterstitial interstitialAd;

    @override
    void initState() {
      super.initState();
      bannerSize = AdmobBannerSize.BANNER;
    }

    @override
    Widget build(BuildContext context) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<PlayerList>(create: (_) => PlayerList()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Munchkin Counter',
          theme: ThemeData(
            primarySwatch: Colors.blue
          ),
          home: HomeProvider()
        ),
      );
    }
  }

  String getAppId() {
    if (Platform.isIOS) {
      return 'ca-app-pub-7987021525697218~6587745142';
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-7987021525697218~1864705963';
    }
      return null;
  }