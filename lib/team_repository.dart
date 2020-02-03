import 'package:flutter/material.dart';

var teams = List<Team>();
var id = 0;
var previousTeamScore;
var boardLength = 35;

class Team {
  int _teamId;
  String _teamName;
  Color _teamColor;
  List<String> _players;
  int _score;

  Team(Color teamColor) {
    this._teamId = id;
    this._teamName = '';
    this._teamColor = teamColor;
    this._score = 0;
    _initSpelers();
    id++;
  }

  Team.init(String teamNaam, Color teamColor) {
    this._teamId = id;
    this._teamName = teamNaam;
    this._teamColor = teamColor;
    this._score = 0;
    _initSpelers();
    id++;
  }

  void _initSpelers() {
    this._players = new List();
    _players.add('Speler 1');
    _players.add('Speler 2');
    _players.add('');
    _players.add('');
  }

  int get teamId => _teamId;

  Color get teamColor => _teamColor;

  String get teamName => _teamName;

  int get score => _score;

  List<String> get players => _players;

  String getPlayerByName(String naam) {
    return _players.where((x) => x == naam).toList().first;
  }

  void addScore(int score) {
    if (score > boardLength) {
      score = boardLength;
    } else {
      _score += score;
    }
  }

  set teamName(String value) {
    _teamName = value;
  }

  set color(Color color) {
    _teamColor = color;
  }

  set players(List<String> players) {
    _players = players;
  }
}

void initTeams() {
  teams = List<Team>();
  id = 0;
  previousTeamScore = null;

  teams.add(new Team.init('Team 1', Colors.green));
  teams.add(new Team.init('Team 2', Colors.red));
  teams.add(new Team(Colors.orange));
  teams.add(new Team(Colors.purple));
}

bool previousTeamWon(){
  return teams.last.score == boardLength;
}

List<Team> getTeams() {
  return teams;
}

Team getTeamByName(String teamNaam) {
  var foundTeams = teams.where((x) => x._teamName == teamNaam).toList();
  return foundTeams.first;
}

Team getTeamById(int id) {
  var foundTeams = teams.where((x) => x._teamId == id).toList();
  return foundTeams.first;
}

void removeEmptyTeams() {
  teams = teams.where((x) => x.teamName != '').toList();
}

void removeEmptyPlayers() {
  for (Team team in teams) {
    team.players = team.players.where((x) => x != '').toList();
  }
}

void addCurrentTeamScore(int score) {
  teams.first.addScore(score);
  previousTeamScore = score;
}

Team getTeamAtTurn() {
  return teams.first;
}

Team getPreviousTeam() {
  return teams.last;
}

int getPreviousTeamScore() {
  return previousTeamScore;
}

String getPlayerAtTurn() {
  var team = teams.first;

  return team.players.first;
}

void setNextTurn() {
  var team = teams.removeAt(0);
  var player = team.players.removeAt(0);

  team.players.add(player);
  teams.add(team);
}
