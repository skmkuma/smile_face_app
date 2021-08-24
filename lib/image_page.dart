// <image_page.dart>
// ImagePage(SNSタイムラインからリストをクリックすると写真を表示する)
import 'package:flutter/material.dart';

class ImagePage extends StatelessWidget {
  String _imageUrl = "";
  String _name = "";

  ImagePage(String imageUrl, String name) {
    this._imageUrl = imageUrl;
    this._name = name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smile SNS"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(_name,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Center(
            child: Image.network(_imageUrl),
          ),
        ],
      ),
    );
  }
}
