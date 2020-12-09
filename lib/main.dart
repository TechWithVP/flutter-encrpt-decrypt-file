import 'dart:io';
import 'dart:typed_data';
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
  bool _isGranted = true;
  String filename = "demo.mp4";
  String _videoURL =
      "https://assets.mixkit.co/videos/preview/mixkit-clouds-and-blue-sky-2408-large.mp4";
  String _imageURL =
      "https://images.pexels.com/photos/5849319/pexels-photo-5849319.jpeg?crop=entropy&cs=srgb&dl=pexels-polina-tankilevitch-5849319.mp4&fit=crop&fm=jpg&h=1920&w=1280";
  String _pdfURL = "https://www.irjet.net/archives/V5/i3/IRJET-V5I3124.pdf";
  String _zipURL = "https://www.1001freefonts.com/d/4063/admiration-pains.zip";

  Future<Directory> get getAppDir async {
    final appDocDir = await getExternalStorageDirectory();
    return appDocDir;
  }

  Future<Directory> get getExternalVisibleDir async {
    if (await Directory('/storage/emulated/0/MyEncFolder').exists()) {
      final externalDir = Directory('/storage/emulated/0/MyEncFolder');
      return externalDir;
    } else {
      await Directory('/storage/emulated/0/MyEncFolder')
          .create(recursive: true);
      final externalDir = Directory('/storage/emulated/0/MyEncFolder');
      return externalDir;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    requestStoragePermission();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RaisedButton(
              child: Text("Download Video"),
              onPressed: () async {
                if (_isGranted) {
                  Directory d = await getExternalVisibleDir;
                  // Directory hiddenDir = await getAppDir;
                  _downloadAndCreate(_videoURL, d, filename);
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
                  Directory d = await getExternalVisibleDir;
                  // Directory hiddenDir = await getAppDir;
                  _getNormalFile(d, filename);
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

_downloadAndCreate(String url, Directory d, filename) async {
  if (await canLaunch(url)) {
    print("Data downloading....");
    var resp = await http.get(url);

    var encResult = _encryptData(resp.bodyBytes);
    String p = await _writeData(encResult, d.path + '/$filename.aes');
    print("file encrypted successfully: $p");
  } else {
    print("Can't launch URL.");
  }
}

_getNormalFile(Directory d, filename) async {
  Uint8List encData = await _readData(d.path + '/$filename.aes');
  var plainData = await _decryptData(encData);
  String p = await _writeData(plainData, d.path + '/$filename');
  print("file decrypted successfully: $p");
}

_encryptData(plainString) {
  print("Encrypting File...");
  final encrypted =
      MyEncrypt.myEncrypter.encryptBytes(plainString, iv: MyEncrypt.myIv);
  return encrypted.bytes;
}

_decryptData(encData) {
  print("File decryption in progress...");
  enc.Encrypted en = new enc.Encrypted(encData);
  return MyEncrypt.myEncrypter.decryptBytes(en, iv: MyEncrypt.myIv);
}

Future<Uint8List> _readData(fileNameWithPath) async {
  print("Reading data...");
  File f = File(fileNameWithPath);
  return await f.readAsBytes();
}

Future<String> _writeData(dataToWrite, fileNameWithPath) async {
  print("Writting Data...");
  File f = File(fileNameWithPath);
  await f.writeAsBytes(dataToWrite);
  return f.absolute.toString();
}

class MyEncrypt {
  static final myKey = enc.Key.fromUtf8('TechWithVPTechWithVPTechWithVP12');
  static final myIv = enc.IV.fromUtf8("VivekPanchal1122");
  static final myEncrypter = enc.Encrypter(enc.AES(myKey));
}

// _getFilenameFromHeaders(Map<String, String> h) {
//   if (h.containsKey('content-disposition')) {
//     return h['content-disposition'].split("=")[1].replaceAll('"', '');
//   } else {
//     print("Filename not available.");
//   }
// }