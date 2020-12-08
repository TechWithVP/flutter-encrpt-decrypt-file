import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:encrypt/encrypt.dart' as enc;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isGranted;
  String _appDocPath, _externalDirPath;
  File _outFile, _inputFie;
  String _videoURL =
      "https://assets.mixkit.co/videos/preview/mixkit-clouds-and-blue-sky-2408-large.mp4";
  String _imageURL =
      "https://images.pexels.com/photos/5849319/pexels-photo-5849319.jpeg?crop=entropy&cs=srgb&dl=pexels-polina-tankilevitch-5849319.mp4&fit=crop&fm=jpg&h=1920&w=1280";

  @override
  void initState() {
    super.initState();
    requestStoragePermission();
    getAppDir();
    getExternalVisibleDir();
  }

  getAppDir() async {
    Directory appDocDir = await getExternalStorageDirectory();
    setState(() {
      _appDocPath = appDocDir.path;
    });
  }

  getExternalVisibleDir() async {
    if (await Directory('/storage/emulated/0/MyEncFolder').exists()) {
      Directory externalDir =
          await Directory('/storage/emulated/0/MyEncFolder');
      setState(() {
        _externalDirPath = externalDir.path;
      });
    } else {
      await Directory('/storage/emulated/0/MyEncFolder')
          .create(recursive: true);
      Directory externalDir =
          await Directory('/storage/emulated/0/MyEncFolder');
      setState(() {
        _externalDirPath = externalDir.path;
      });
    }
  }

  requestStoragePermission() async {
    if (!await Permission.storage.isGranted) {
      PermissionStatus result = await Permission.storage.request();
      if (result.isGranted) {
        setState(() {
          _isGranted = true;
        });
      } else {
        _isGranted = false;
      }
    } else {
      _isGranted = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RaisedButton(
              child: Text("Download Video"),
              onPressed: () async {
                if (_isGranted) {
                  _mainOperaton(_videoURL, _outFile);
                } else {
                  print("No permission granted.");
                  requestStoragePermission();
                }
              },
            ),
            RaisedButton(
              child: Text("Decrypt Video"),
              onPressed: () async {
                if (_isGranted) {
                  _decryptData(_inputFie, _outFile);
                } else {
                  print("No permission granted.");
                  requestStoragePermission();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

_mainOperaton(String url, File _outFile) async {
  if (await canLaunch(url)) {
    print("Data downloading....");
    var resp = await http.get(url);
    // String filename = _getFilenameFromHeaders(resp.headers);

    var encResult = _encryptData(resp.bodyBytes);

    print("Writting file...");
    _outFile = File("/storage/emulated/0/MyEncFolder/demo.mp4.aes");
    File a = await _outFile.writeAsBytes(encResult);
    print("file generated here: ${a.absolute}");
  } else {
    print("Can't launch URL.");
  }
}

_getFilenameFromHeaders(Map<String, String> h) {
  if (h.containsKey('content-disposition')) {
    return h['content-disposition'].split("=")[1].replaceAll('"', '');
  } else {
    print("Filename not available.");
  }
}

_encryptData(plainString) {
  print("Encrypting File...");
  final encrypter = enc.Encrypter(enc.AES(MyEncrypt.myKey));
  final encrypted = encrypter.encryptBytes(plainString, iv: MyEncrypt.myIv);
  return encrypted.bytes;
}

_decryptData(_inputFile, _outFile) async {
  final encrypter = enc.Encrypter(enc.AES(MyEncrypt.myKey));
  print("File decryption in progress...");
  if (await Directory('/storage/emulated/0/MyEncFolder').exists()) {
    _inputFile = File(
        Directory('/storage/emulated/0/MyEncFolder').path + "/demo.mp4.aes");
    var readData = await _inputFile.readAsBytes();
    enc.Encrypted en = new enc.Encrypted(readData);
    final decrypted = encrypter.decryptBytes(en, iv: MyEncrypt.myIv);
    _outFile =
        File(Directory('/storage/emulated/0/MyEncFolder').path + "/demo.mp4");
    await _outFile.writeAsBytes(decrypted);
    print("file generated here: ${_outFile.path}");
  }
}

_readData(fileNameWithPath) async {
  File f = File(fileNameWithPath);
  return await f.readAsBytes();
}

_writeData(dataToWrite, fileNameWithPath) async {
  File f =
      File(fileNameWithPath);
  await f.writeAsBytes(dataToWrite);
  return f.absolute;
}

class MyEncrypt {
  static final myKey = enc.Key.fromUtf8('TechWithVPTechWithVPTechWithVP09');
  static final myIv = enc.IV.fromUtf8("VivekPanchal0910");
}
