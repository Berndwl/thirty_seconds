import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'dart:math' show Random;
import 'dart:async' show Future;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';

import 'team_repository.dart';

var allQuestions;
var gameQuestions;

Future<void> main() async {
  runApp(MyApp());
  
  var questionsString = await loadAsset();
  var decodedQuestions = jsonDecode(questionsString);
  allQuestions = gameQuestions = decodedQuestions['dutch'];
}

Future<String> loadAsset() async {
  return await rootBundle.loadString('assets/out.json');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '30 Seconds',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('30 Seconds'),
        ),
        body: Center(child: MainMenu()),
      ),
    );
  }
}

class TeamState extends StatefulWidget {
  int teamId;

  TeamState(int teamId) {
    this.teamId = teamId;
  }

  @override
  CreateTeamState createState() => CreateTeamState(teamId);
}

class QuestionOverviewState extends State<QuestionOverview> {
  final confirmText = 'Bevestig';

  List<String> questions = List();

  var correctAnswers = <String>[];
  var startTime = 30;
  var expired = false;
  Timer _timer;

  QuestionOverviewState() {
    setQuestions();
    startCountdown();
  }

  void setQuestions() {
    const amountOfQuestions = 5;
    var list = List.generate(gameQuestions.length, (i) => i);
    list.shuffle();

    var random = Random();

    for (int i = 0; i < amountOfQuestions; i++) {
      var randomIndex = list[i];
      var randomCategory = gameQuestions[randomIndex];
      var categoryName = randomCategory.keys.first;
      var categoryWords = randomCategory[categoryName];
      var randomQuestionId = random.nextInt(categoryWords.length);

      var randomWord = categoryWords[randomQuestionId];
      gameQuestions[randomIndex][categoryName].removeAt(randomQuestionId);

      questions.add(randomWord);
    }
  }

  void showBoard(int amountCorrect) {
    addCurrentTeamScore(amountCorrect);

    setNextTurn();

    Navigator.pop(
      context,
      MaterialPageRoute(builder: (context) => GameOverview()),
    );
  }

  void startCountdown() {
    const second = const Duration(seconds: 1);
    _timer = Timer.periodic(
        second,
        (Timer timer) => setState(() {
              if (startTime < 1) {
                timer.cancel();
                setState(() {
                  expired = true;
                });
              } else {
                startTime -= 1;
              }
            }));
  }

  Widget buildRow(String word) {
    final correctAnswer = correctAnswers.contains(word);

    return ListTile(
        title: Text(word),
        trailing: correctAnswer
            ? Icon(Icons.check_circle)
            : Icon(Icons.check_circle_outline),
        onTap: () {
          setState(() {
            if (correctAnswer) {
              correctAnswers.remove(word);
            } else {
              correctAnswers.add(word);
            }
          });
        });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: EdgeInsets.only(top: 150.0),
          child: Column(
            children: <Widget>[
              ListView.separated(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(4),
                  itemCount: questions.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      height: 70,
                      color: Colors.lightBlueAccent,
                      child: Center(child: buildRow(questions[index])),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider()),
              Center(
                  child: Padding(
                      padding: EdgeInsets.only(top: 100.0),
                      child: !expired
                          ? Text('$startTime',
                              style: TextStyle(
                                  fontSize: 50, color: Colors.lightBlueAccent))
                          : ButtonTheme(
                              minWidth: 300.0,
                              child: FlatButton(
                                  color: Colors.lightBlueAccent,
                                  child: Text(confirmText),
                                  onPressed: () =>
                                      showBoard(correctAnswers.length)))))
            ],
          )),
    );
  }
}

class QuestionOverview extends StatefulWidget {
  @override
  QuestionOverviewState createState() => QuestionOverviewState();
}

class GameOverview extends StatefulWidget {
  @override
  GameOverviewState createState() => GameOverviewState();
}

class GameOverviewState extends State<GameOverview> {
  final appBarText = '30 Seconds';

  void showQuestion() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => QuestionOverview()));
  }

  @override
  Widget build(BuildContext context) {
    var teamWon = previousTeamWon();
    var currentTeam = getTeamAtTurn();
    var previousTeam = getPreviousTeam();
    var previousTeamScore = getPreviousTeamScore();

    var teamAtTurn = 'Team ${currentTeam.teamName} is aan zet';
    var playerAtTurn = '${getPlayerAtTurn()} is aan de beurt';
    var teamSteps = '${previousTeam.teamName} gaat $previousTeamScore ';
    var teamWonText = '${previousTeam.teamName} heeft gewonnen!';

    if (previousTeamScore == 1) {
      teamSteps += "stap";
    } else {
      teamSteps += "stappen";
    }

    return Scaffold(
        appBar: AppBar(title: Text(appBarText)),
        body: Stack(
          children: <Widget>[
            Align(
                alignment: Alignment.topCenter,
                child: !teamWon
                    ? Padding(
                        padding: EdgeInsets.only(top: 40.0),
                        child: Text(
                          teamAtTurn,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20, color: currentTeam.teamColor),
                        ))
                    : Container()),
            Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: CustomPaint(
                  painter: GameBoard(context),
                )),
            Align(
                alignment: Alignment.bottomCenter,
                child: previousTeamScore != null
                    ? Padding(
                        padding: EdgeInsets.only(bottom: 250.0),
                        child: Text(
                          teamSteps,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20, color: previousTeam.teamColor),
                        ))
                    : Container()),
            Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                    padding: EdgeInsets.only(bottom: 150.0),
                    child: Text(
                      !teamWon ? playerAtTurn : teamWonText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20,
                          color: !teamWon
                              ? currentTeam.teamColor
                              : previousTeam.teamColor),
                    ))),
            Align(
                alignment: Alignment.bottomCenter,
                child: !teamWon
                    ? Padding(
                        padding: EdgeInsets.only(bottom: 50.0),
                        child: ButtonTheme(
                            minWidth: 200.0,
                            child: FlatButton(
                                color: Colors.blue,
                                child: Text('Ready'),
                                onPressed: showQuestion)),
                      )
                    : Container())
          ],
        ));
  }
}

class GameBoard extends CustomPainter {
  final leftOffset = 0.0;
  final topOffset = 150.0;
  final rectSize = 38.0;
  final rectOffset = 40;

  final Paint yellow = Paint()..color = Colors.yellow;
  final Paint blue = Paint()..color = Colors.lightBlue;

  double width;
  double height;
  List<Rect> rects;

  GameBoard(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
  }

  void setGameBoardPieces(Canvas canvas) {
    final pieceRadius = 15.0;
    var black = Paint()..color = Colors.black;

    for (int i = 0; i < rects.length; i++) {
      var index = 0;
      var pieceOffsetY = 0.0;
      var pieceOffsetX = 0.0;

      var teamsAtPosition = teams.where((x) => x.score == i).toList();

      for (Team team in teamsAtPosition) {
        var paint = Paint()..color = team.teamColor;
        var currentRect = rects[i];

        if (teamsAtPosition.length == 2) {
          switch (index) {
            case 0:
              pieceOffsetX = -10;
              break;
            case 1:
              pieceOffsetX = 10;
              break;
          }
        }

        if (teamsAtPosition.length > 2) {
          switch (index) {
            case 0:
              pieceOffsetX = -10;
              pieceOffsetY = -10;
              break;
            case 1:
              pieceOffsetX = 10;
              pieceOffsetY = -10;
              break;
            case 2:
              pieceOffsetX = -10;
              pieceOffsetY = 10;
              break;
            case 3:
              pieceOffsetX = 10;
              pieceOffsetY = 10;
              break;
          }
        }

        var offset = currentRect.center;
        var newOffset =
            Offset(offset.dx + pieceOffsetX, offset.dy + pieceOffsetY);

        canvas.drawCircle(newOffset, pieceRadius + 2, black);
        canvas.drawCircle(newOffset, pieceRadius, paint);

        index++;
      }
    }
  }

  void buildMatrix() {
    //Base matrix
//        var matrix = [
//      [0, 0 ,0 ,0, 0, 0, 0 ,0 ,0 ,0],
//      [0, 0 ,0 ,0, 0, 0, 0 ,0 ,0 ,0],
//      [0, 0 ,0 ,0, 0, 0, 0 ,0 ,0 ,0],
//      [0, 0 ,0 ,0, 0, 0, 0 ,0 ,0 ,0],
//      [0, 0 ,0 ,0, 0, 0, 0 ,0 ,0 ,0],
//      [0, 0 ,0 ,0, 0, 0, 0 ,0 ,0 ,0],
//      [0, 0 ,0 ,0, 0, 0, 0 ,0 ,0 ,0],
//      [0, 0 ,0 ,0, 0, 0, 0 ,0 ,0 ,0],
//
//    ];

    var matrix = [
      [14, 15, 16, 17, 18, 19, 20, 21, 22, 23],
      [13, 0, 0, 0, 0, 0, 0, 0, 0, 24],
      [12, 0, 0, 0, 0, 0, 0, 0, 0, 25],
      [11, 0, 0, 0, 0, 0, 0, 0, 0, 26],
      [10, 0, 0, 0, 0, 0, 0, 0, 0, 27],
      [9, 0, 0, 0, 1, 36, 0, 0, 0, 28],
      [8, 0, 0, 0, 2, 35, 0, 0, 0, 29],
      [7, 6, 5, 4, 3, 34, 33, 32, 31, 30],
    ];

    rects = List.filled(36, null);

    for (int i = 0; i < matrix.length; i++) {
      var currentList = matrix[i];

      for (int j = 0; j < currentList.length; j++) {
        var boardIndex = currentList[j];

        var rect = new Rect.fromLTWH(leftOffset + (j * rectOffset),
            topOffset + (i * rectOffset), rectSize, rectSize);

        if (boardIndex != 0) {
          rects[boardIndex - 1] = rect;
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    buildMatrix();

    for (int i = 0; i < rects.length; i++) {
      var rect = rects[i];

      if (i % 2 == 0) {
        canvas.drawRect(rect, yellow);
      } else if (i % 2 != 0) {
        canvas.drawRect(rect, blue);
      }
    }

    setGameBoardPieces(canvas);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class TeamOverview extends StatefulWidget {
  @override
  TeamOverviewState createState() => TeamOverviewState();
}

class TeamOverviewState extends State<TeamOverview> {
  final createTeamsText = 'De teams';
  final optionalTeamText = 'Optioneel team';
  final teamsIncompleteError = 'Teams moeten minimaal 2 spelers hebben';
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Team> teams = <Team>[];
  var team1Button;
  var team2Button;
  var team3Button;
  var team4Button;
  var startButton;
  final width = 300.0;

  void setupTeam(teamNaam) {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return TeamState(teamNaam);
    })).then((value) {
      setState(() {
        this.teams = getTeams();
      });
    });
  }

  bool teamNameIsEmpty(String teamName) {
    return teamName == '';
  }

  bool hasValidTeams() {
    var allTeams = getTeams();
    bool validTeams = true;

    for (Team team in allTeams) {
      if (team.teamName != '') {
        var validPlayers =
            team.players.where((playerName) => playerName != '').toList();

        if (validPlayers.length < 2) {
          validTeams = false;
        }
      }
    }
    return validTeams;
  }

  void startGame(BuildContext context) {
    if (!hasValidTeams()) {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text(teamsIncompleteError)));
    } else {
      removeEmptyTeams();
      removeEmptyPlayers();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GameOverview()),
      );
    }
  }

  void setupTeams() {
    if (teams.length == 0) {
      initTeams();
      teams = getTeams();
    }

    var team1 = teams.elementAt(0);
    team1Button = FlatButton(
        color: team1.teamColor,
        child: Text(team1.teamName),
        onPressed: () => setupTeam(team1.teamId));

    var team2 = teams.elementAt(1);
    team2Button = FlatButton(
        color: team2.teamColor,
        child: Text(team2.teamName),
        onPressed: () => setupTeam(team2.teamId));

    var team3 = teams.elementAt(2);
    team3Button = FlatButton(
        color: team3.teamColor,
        child: Text(!teamNameIsEmpty(team3.teamName)
            ? team3.teamName
            : optionalTeamText),
        onPressed: () => setupTeam(team3.teamId));

    var team4 = teams.elementAt(3);
    team4Button = FlatButton(
        color: team4.teamColor,
        child: Text(!teamNameIsEmpty(team4.teamName)
            ? team4.teamName
            : optionalTeamText),
        onPressed: () => setupTeam(team4.teamId));

    startButton = FlatButton(
        color: Colors.blue,
        child: Text('Start'),
        onPressed: () => startGame(context));
  }

  @override
  Widget build(BuildContext context) {
    setupTeams();
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(createTeamsText),
        ),
        body: Center(
            child: Container(
          child: Padding(
              padding: EdgeInsets.only(top: 25.0),
              child: Column(
                children: <Widget>[
                  ButtonTheme(minWidth: width, child: team1Button),
                  ButtonTheme(minWidth: width, child: team2Button),
                  ButtonTheme(minWidth: width, child: team3Button),
                  ButtonTheme(minWidth: width, child: team4Button),
                  Padding(
                      padding: EdgeInsets.all(50.0),
                      child: ButtonTheme(
                        minWidth: width,
                        child: startButton,
                      ))
                ],
              )),
        )));
  }
}

class CreateTeamState extends State<TeamState> {
  final teamNameController = new TextEditingController();
  final speler1Controller = new TextEditingController();
  final speler2Controller = new TextEditingController();
  final speler3Controller = new TextEditingController();
  final speler4Controller = new TextEditingController();

  final appBarText = 'Wie zit er in je team?';
  final teamNameText = 'Team naam';
  final playersText = 'Spelers: ';
  final saveText = 'Opslaan';

  Team currentTeam;

  CreateTeamState(int teamId) {
    currentTeam = getTeamById(teamId);

    teamNameController.text = currentTeam.teamName;
    speler1Controller.text = currentTeam.players[0];
    speler2Controller.text = currentTeam.players[1];
    speler3Controller.text = currentTeam.players[2];
    speler4Controller.text = currentTeam.players[3];
  }

  @override
  void dispose() {
    teamNameController.dispose();
    speler1Controller.dispose();
    speler2Controller.dispose();
    speler3Controller.dispose();
    speler4Controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    teamNameController.addListener(setTeam);
    speler1Controller.addListener(setPlayer1);
    speler2Controller.addListener(setPlayer2);
    speler3Controller.addListener(setPlayer3);
    speler4Controller.addListener(setPlayer4);
  }

  opslaan() {
    Navigator.pop(
      context,
      MaterialPageRoute(builder: (context) => TeamOverview()),
    );
  }

  void setTeam() {
    currentTeam.teamName = teamNameController.text;
  }

  void setPlayer1() {
    currentTeam.players[0] = speler1Controller.text;
  }

  void setPlayer2() {
    currentTeam.players[1] = speler2Controller.text;
  }

  void setPlayer3() {
    currentTeam.players[2] = speler3Controller.text;
  }

  void setPlayer4() {
    currentTeam.players[3] = speler4Controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(appBarText)),
        body: Center(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Container(
                    child: Column(children: <Widget>[
                  TextField(
                      controller: teamNameController,
                      decoration: InputDecoration(hintText: teamNameText)),
                  Padding(
                      padding: EdgeInsets.all(20.0), child: Text(playersText)),
                  TextField(
                      controller: speler1Controller,
                      decoration: InputDecoration(hintText: 'Player 1')),
                  TextField(
                      controller: speler2Controller,
                      decoration: InputDecoration(hintText: 'Player 2')),
                  TextField(
                      controller: speler3Controller,
                      decoration: InputDecoration(hintText: 'Player 3')),
                  TextField(
                      controller: speler4Controller,
                      decoration: InputDecoration(hintText: 'Player 4')),
                  Padding(
                      padding: EdgeInsets.all(16.0),
                      child: FlatButton(
                          color: Colors.green,
                          child: Text(saveText),
                          onPressed: opslaan))
                ])))));
  }
}

class MainMenuState extends State<MainMenu> {
  @override
  Widget build(BuildContext context) {
    return buildMenu();
  }

  openTeamOverviewMenu() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => TeamOverview()));
  }

  Material buildMenu() {
    var materialButton = FlatButton(
        color: Colors.green,
        child: Text('Spelen'),
        onPressed: openTeamOverviewMenu);
    return Material(child: materialButton);
  }
}

class MainMenu extends StatefulWidget {
  @override
  MainMenuState createState() => MainMenuState();
}
