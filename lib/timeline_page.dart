// <timeline_page.dart>
// TimelinePage(SNSタイムライン)
import 'image_page.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 時間を文字列に変換

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TimelinePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smile SNS"),
      ),
      body: Container(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("smiles")
          .orderBy("date", descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildList(context, snapshot.data!.docs);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapList) {
    return ListView.builder(
        padding: EdgeInsets.all(10),
        itemCount: snapList.length,
        itemBuilder: (context, i) {
          return _buildListItem(context, snapList[i]);
        });
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot snap) {
    Map<String, dynamic> _data = snap.data();
    DateTime _datetime = _data["date"].toDate();
    var _formatter = DateFormat("dd//MM HH:mm"); // 2021表記はy
    String postDate = _formatter.format(_datetime);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          title: Text(
            _data["name"],
            style: TextStyle(fontSize: 15),
          ),
          leading: Text(postDate),
          subtitle: Text(
              "は" + (_data["smile_prob"] * 100).toStringAsFixed(1) + "%の笑顔です"),
          trailing: Text(_getEmozi(_data["smile_prob"]),
              style: TextStyle(fontSize: 30)),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ImagePage(_data["image_url"], _data["name"]),
                ));
          },
        ),
      ),
    );
  }

  // Firebaseのデータベースのsmile_probの値を顔文字で表現
  String _getEmozi(double smileProb) {
    String emozi;
    if (smileProb < 0.2) {
      emozi = "😯";
    } else if (smileProb < 0.4) {
      emozi = "😌";
    } else if (smileProb < 0.6) {
      emozi = "😀";
    } else if (smileProb < 0.8) {
      emozi = "😄";
    } else {
      emozi = "😆";
    }
    return emozi;
  }
}
