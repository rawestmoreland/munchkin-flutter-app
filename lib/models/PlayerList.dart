import 'package:flutter/material.dart';

import './PlayerModel.dart';

class PlayerList extends ChangeNotifier {
  List<PlayerModel> taskList = [];


  addPlayer() {
    // TODO: function to create player and add to list

    notifyListeners();
  }
}