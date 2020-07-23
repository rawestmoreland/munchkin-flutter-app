class PlayerModel {
  String name;
  int score;

  Map<String, dynamic> toMap() {
    return {'name': name, 'score': score};
  }

  PlayerModel(this.name, this.score);
}
