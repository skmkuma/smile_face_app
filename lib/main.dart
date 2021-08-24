// <main.dart>
import 'dart:io';

import 'timeline_page.dart';

import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart'; // 時間を文字列に変換
import 'package:uuid/uuid.dart'; // uniqueなIDの生成(今回は画像のURLを生成)
import 'package:path/path.dart'; // pathの操作に必要なライブラリ
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; //firebaseに必要なライブラリ
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // runApp()を呼び出す前にFlutter Engineの機能を利用したい場合にコール
  await Firebase.initializeApp();
  runApp(MyAIApp());
}

class MyAIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMILE SNS App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainForm(),
    );
  }
}

class MainForm extends StatefulWidget {
  @override
  _MainFormState createState() => _MainFormState();
}

// MainPage
class _MainFormState extends State<MainForm> {
  String _name = "";
  String _processingMessage = "";

  final FaceDetector _faceDetector = FirebaseVision.instance.faceDetector(
    FaceDetectorOptions(
      mode: FaceDetectorMode
          .accurate, // Option for controlling additional accuracy / speed trade-offs.
      enableLandmarks: true, // Whether to detect FaceLandmarks. 目や鼻などの検出を可能にする
      enableClassification:
          true, // characterizing attributes such as "smiling" and "eyes open".
    ),
  );
  final ImagePicker _picker = ImagePicker();

  void _getImageAndFindFace(
      BuildContext context, ImageSource imageSource) async {
    setState(() {
      _processingMessage = "Wait a minutes, Processing...";
    });

    final PickedFile pickedImage = await _picker.getImage(source: imageSource);
    final File imageFile = File(pickedImage.path);

    // 写真がimageFileに格納されたタイミングでfaceDetectorで笑顔の確率の計算&データベースとストレージに写真を保存
    if (imageFile != null) {
      final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(
          imageFile); // FaceDetectorに渡せるようにFirebaseVisionImage型に変換
      List<Face> faces = await _faceDetector.processImage(visionImage);
      if (faces.length > 0) {
        String imagePath = "/images/" +
            Uuid().v1() +
            basename(pickedImage.path); // Uuid.v1:時刻に基づくユニークなid
        StorageReference ref = FirebaseStorage.instance
            .ref()
            .child(imagePath); // Google Cloud Storageへの参照を表す
        final StorageTaskSnapshot storedImage = await ref
            .putFile(imageFile)
            .onComplete; // StorageTaskSnapshot:Storageへの操作の際に型宣言する
        if (storedImage.error == null) {
          final String downloadUrl =
              await storedImage.ref.getDownloadURL(); //Urlを付与
          Face largestFace = findLargestFace(faces);
          // Firestoreデータベースにsmilesコレクションを追加し以下の設定で保存する
          FirebaseFirestore.instance.collection("smiles").add({
            "name": _name, //UIのテキスト入力が写真のnameとなる
            "image_url": downloadUrl, //データベースから写真を取得する際のURを設定
            "date": Timestamp.now(),
            "smile_prob": largestFace.smilingProbability, //笑顔の確率
          });
          // Firebaseストレージに写真が追加されたら、TimelinePageに遷移する
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => TimelinePage()));
        }
      }
    }
    setState(() {
      _processingMessage = "";
    });
  }

  //取得した顔のリストの中から最も大きい顔を検出する関数
  Face findLargestFace(List<Face> faces) {
    Face largestFace = faces[0];
    for (Face face in faces) {
      if (face.boundingBox.height + face.boundingBox.width >
          largestFace.boundingBox.height + largestFace.boundingBox.width) {
        largestFace = face;
      }
    }
    return largestFace;
  }

  // MainPageのUI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Smile SNS")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(padding: EdgeInsets.all(20)), // ある方向のみの場合はEdgeInsets.only
          Text(_processingMessage,
              style: TextStyle(
                color: Colors.lightBlue,
                fontSize: 20,
              )),
          TextFormField(
            style: TextStyle(fontSize: 23),
            decoration: InputDecoration(
              icon: Icon(
                Icons.person_add_alt,
                size: 40,
              ),
              labelText: "YOUR NAME",
              hintText: "Please input your name",
            ),
            onChanged: (text) {
              setState(() {
                _name = text;
              });
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            tooltip: "screen change sns",
            heroTag: "sns",
            child: Icon(Icons.timeline_outlined),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => TimelinePage()));
            },
          ),
          Padding(padding: EdgeInsets.all(10)),
          FloatingActionButton(
            tooltip: "Select image",
            heroTag: "gallery",
            child: Icon(Icons.add_photo_alternate),
            onPressed: () {
              _getImageAndFindFace(context, ImageSource.gallery);
            },
          ),
          Padding(padding: EdgeInsets.all(10)),
          FloatingActionButton(
            tooltip: "Take photo",
            heroTag: "camera",
            child: Icon(Icons.add_a_photo),
            onPressed: () {
              _getImageAndFindFace(context, ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }
}
