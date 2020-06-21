import 'package:flutter/material.dart';

/**
 * A grid view that show the list of players with their name,
 * score and score keeping buttons
 */

class PlayerGridList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: EdgeInsets.all(10.0),
      crossAxisSpacing: 10.0,
      mainAxisSpacing: 10.0,
      scrollDirection: Axis.vertical,
      children: _players.map((player) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10.0)), 
            color: Colors.white.withOpacity(0.7)), 
          alignment: Alignment.center,
          child: Column(
            children: <Widget>[
              Flexible(
                flex: 3,
                child: Container(alignment: Alignment.center, child: Text("${player['name']}", style: TextStyle(fontFamily: "Architects Daughter", fontSize: 24, fontWeight: FontWeight.bold)))
              ),
              Flexible(
                flex: 4,
                child: Container(
                  child: scoreOrDelete(editing, player)
                ),
              ),
            ],
          ),
        );
      }
    ).toList());
  }
}