import 'package:flutter/material.dart';
import 'package:munchkin/models/Dialogs.dart';
import 'package:munchkin/models/PlayerList.dart';
import 'package:munchkin/widgets/PlayerGridList.dart';
import 'package:provider/provider.dart';

class HomeProvider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final playerList = Provider.of<PlayerList>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('Munchkin Levels'.toUpperCase(),
            style: TextStyle(
                fontFamily: 'Architects Daughter',
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.brown[700],
        actions: <Widget>[
          IconButton(icon: Icon(Icons.add), onPressed: () => {playerList.addPlayer('John')})
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height * 2,
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/Paper-Texture-.png'),
              fit: BoxFit.cover),
        ),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Container(
                child: Consumer<PlayerList>(
                    builder: (context, playerList, child) => PlayerGridList(players: playerList.playerList)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
