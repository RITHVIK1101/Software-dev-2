import 'package:flutter/material.dart';
import 'addsportsscreen.dart';
import 'addclubscreen.dart';

class EcCoordinatorChoiceScreen extends StatelessWidget {
  final String token;
  final String userId;

  EcCoordinatorChoiceScreen({
    required this.token,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Extracurricular Coordinator'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddSportScreen(token: token, userId: userId),
                  ),
                );
              },
              child: Text('Sports'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddClubScreen(token: token, userId: userId),
                  ),
                );
              },
              child: Text('Clubs'),
            ),
          ],
        ),
      ),
    );
  }
}
