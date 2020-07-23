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
  addPlayer(name) {
    var player = new PlayerModel(name, 1).toMap();
    playerList.add(player);
    savePlayerList(playerList);
    notifyListeners();
  }

  deletePlayer(playerName) {
    // Find the index of our player based on the name
    int playerIndex;
    playerIndex =
        playerList.indexWhere((player) => player['name'] == playerName);
    playerList.removeAt(playerIndex);
    savePlayerList(playerList);
    if (playerList.length == 0) {
      editing = false;
    }
    notifyListeners();
  }

  newGame() {
    for (var i = 0; i < playerList.length; i++) {
      playerList[i]['score'] = 1;
    }
    savePlayerList(playerList);
    notifyListeners();
  }

  changeScore(playerName, upOrDown) {
    // get the index of the object that contains our player
    var playerIndex =
        playerList.indexWhere((player) => player["name"] == playerName);
    if (upOrDown == "up") {
      playerList[playerIndex]["score"] += 1;
    } else {
      playerList[playerIndex]["score"] -= 1;
    }
    savePlayerList(playerList);
    notifyListeners();
  }

  handleEditButton(isEditing) {
    isEditing ? editing = false : editing = true;
    notifyListeners();
  }
}
