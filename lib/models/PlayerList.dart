import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'PlayerModel.dart';

class PlayerList extends ChangeNotifier {
  List<PlayerModel> playerList = [];
  // Are we editing the list of players?
  bool editing = false;

  PlayerList() {
    setup();
  }

  // testing push

  // Get the player list from disk on startup
  setup() async {
    final prefs = await SharedPreferences.getInstance();
    playerList = jsonDecode(prefs.getString('players')) ?? [];
    notifyListeners();
  }

  // Save the playerlist to disk
  savePlayerList(List playerList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('players', playerList.toString());
  }

  // Add a player to the list and save the lsit to disk
  addPlayer(name) {
    var player = new PlayerModel(name, 1);
    playerList.add(player);
    print(playerList);
    savePlayerList(playerList);
    notifyListeners();
  }

  deletePlayer(name) {
    // TODO: Delete a player from the list
  }
}
