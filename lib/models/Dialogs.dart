import 'package:flutter/material.dart';
import 'package:munchkin/models/PlayerList.dart';
import 'package:provider/provider.dart';

class Dialogs {
  final playerNameController = TextEditingController();

  void addPlayerDialog(BuildContext context) {
    final playerList = Provider.of<PlayerList>(context);
    // The dialog
    AlertDialog addPlayer = AlertDialog(
      title: Text("add a player"),
      content: TextField(
          controller: playerNameController,
          decoration: InputDecoration(hintText: "player name"),
          style: TextStyle(fontFamily: 'Architects Daughter'),
          textCapitalization: TextCapitalization.characters),
      actions: <Widget>[
        FlatButton(
            onPressed: () => {playerList.addPlayer(playerNameController.text)},
            child: Text("add")),
        FlatButton(
            onPressed: () =>
                {Navigator.pop(context), playerNameController.text = ""},
            child: Text("cancel"))
      ],
    );

    // Show the dialog
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return addPlayer;
        });
  }
}
