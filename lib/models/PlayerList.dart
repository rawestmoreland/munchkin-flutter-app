import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'PlayerModel.dart';

class PlayerList extends ChangeNotifier {
  List playerList = [];
  // Are we editing the list of players?
  bool editing = false;

  PlayerList() {
    setup();
  }

  // Get the player list from disk on startup
  setup() async {
    final prefs = await SharedPreferences.getInstance();
    String playerString;
    if (prefs.getString('players') != null) {
      playerString = prefs.getString('players');
      playerList = await json.decode(playerString);
    } else {
      playerList = [];
    }
    notifyListeners();
  }

  // Save the playerlist to disk
  savePlayerList(List playerList) async {
    final prefs = await SharedPreferences.getInstance();
    List playerSave = [];
    playerList.forEach((player) {
      player = json.encode(player);
      playerSave.add(player);
    });
    await prefs.setString('players', playerSave.toString());
  }

  // Add a player to the list and save the lsit to disk
  void addPlayer(name) {
    var player = new PlayerModel(name, 1).toMap();
    playerList.add(player);
    savePlayerList(playerList);
    notifyListeners();
  }

  deletePlayer(name) {
    // TODO: Delete a player from the list
  }
}
