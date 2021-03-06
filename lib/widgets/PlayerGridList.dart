import 'package:flutter/material.dart';
import 'package:munchkin/models/PlayerList.dart';
import 'package:provider/provider.dart';
import 'ScoreOrDelete.dart';

///
/// A grid view that show the list of players with their name,
/// score and score keeping buttons
///
class PlayerGridList extends StatelessWidget {
  final List players;
  PlayerGridList({this.players});
  @override
  Widget build(BuildContext context) {
    bool editing = Provider.of<PlayerList>(context, listen: false).editing;
    return GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(10.0),
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        scrollDirection: Axis.vertical,
        children: players.map((player) {
          return Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                color: Colors.white.withOpacity(0.7)),
            alignment: Alignment.center,
            child: Column(
              children: <Widget>[
                Flexible(
                    flex: 3,
                    child: Container(
                        alignment: Alignment.center,
                        child: Text(player['name'],
                            style: TextStyle(
                                fontFamily: "Architects Daughter",
                                fontSize: 24,
                                fontWeight: FontWeight.bold)))),
                Flexible(
                  flex: 4,
                  child: Container(
                      child: Consumer<PlayerList>(builder: (context, playerList, child) => ScoreOrDelete(player: player, editing: editing))),
                ),
              ],
            ),
          );
        }).toList());
  }
}
