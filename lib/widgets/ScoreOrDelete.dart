import 'package:flutter/material.dart';
import 'package:munchkin/models/PlayerList.dart';
import 'package:provider/provider.dart';

class ScoreOrDelete extends StatelessWidget {
  final Map player;
  final bool editing;
  ScoreOrDelete({this.player, this.editing});

  @override
  Widget build(BuildContext context) {
    final playerList = Provider.of<PlayerList>(context, listen: false);
    if (!editing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            onPressed: () => {
              player["score"] > 1
                  ? playerList.changeScore(player["name"], "down")
                  : null
            },
            icon: Icon(Icons.remove),
          ),
          Text(
            "${player['score']}",
            style: TextStyle(fontFamily: "Architects Daughter", fontSize: 40),
          ),
          IconButton(
            onPressed: () => {
              player["score"] <= 9
                  ? playerList.changeScore(player["name"], "up")
                  : null
            },
            icon: Icon(Icons.add),
          ),
        ],
      );
    }
    return IconButton(
      icon: Icon(Icons.delete), 
      onPressed: () => {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text("Are you sure you want to delete " + player["name"] + "?", style: TextStyle(fontFamily: 'Architects Daughter'),),
              actions: <Widget>[
                FlatButton(
                  child: Text("No"),
                  onPressed: () => {Navigator.pop(context)}
                ),
                FlatButton(
                  child: Text("Yes"),
                  onPressed: () => {playerList.deletePlayer(player["name"]), Navigator.pop(context)}
                )
              ],
            );
          }
        )
      },
      iconSize: 42.0,
      color: Colors.red,
    );
  }
}
