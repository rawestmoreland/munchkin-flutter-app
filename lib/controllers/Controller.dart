import 'dart:io';

class Controller {
  static getBannerAdUnitId() {
    if (Platform.isIOS) {
      return "ca-app-pub-7987021525697218/5612379282";
    } else if (Platform.isAndroid) {
      return "ca-app-pub-7987021525697218/6921290209";
    }
  }
}
