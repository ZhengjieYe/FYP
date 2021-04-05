import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:fyp_yzj/pages/alarm/alarm_page.dart';
import 'package:fyp_yzj/pages/fakeCall/fake_call_page.dart';
import 'package:fyp_yzj/pages/main/widget/friend_list_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fyp_yzj/pages/main/picker_data.dart';
import 'package:fyp_yzj/pages/countdown/countdown_page.dart';
import 'package:get/get.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:fyp_yzj/pages/main/widget/map_feature_icon.dart';
import 'package:fyp_yzj/pages/main/widget/floating_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:easy_dialog/easy_dialog.dart';
import 'package:fyp_yzj/pages/video/video_list_page.dart';
import 'package:fyp_yzj/util/uploadFile.dart';

import 'package:path_provider/path_provider.dart';
import 'package:picovoice/picovoice_manager.dart';
import 'package:picovoice/picovoice_error.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  final Telephony telephony = Telephony.instance;

  PicovoiceManager _picovoiceManager;

  final ImagePicker _picker = ImagePicker();
  PickedFile _imageFile;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  GoogleMapController mapController;

  String _mapStyle;

  Position position;

  Set<Marker> _markers = {};

  LatLng mapCenter;
  BitmapDescriptor customIcon;

  Timer _timer;
  int _start = 10;

  bool _isPicoVoiceRunning = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentLocation();

    rootBundle.loadString('assets/map/map_style.txt').then((string) {
      _mapStyle = string;
    });

    _initPicovoice();
  }

  @override
  void dispose() {
    _timer.cancel();
    _picovoiceManager?.delete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Expanded(
                child: mapCenter == null
                    ? Container(
                        color: Color(0xff102439),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: mapCenter,
                          zoom: 17.0,
                        ),
                        markers: _markers,
                      ),
              ),
              Container(
                height: 60,
                color: Color(0xff102439),
              )
            ],
          ),
          Container(
            padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
            child: FloatingIcons(
              icon1Tap: () {
                showBarModalBottomSheet(
                  expand: true,
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => FriendListWidget(),
                );
              },
              icon4Tap: () {
                if (_isPicoVoiceRunning) {
                  EasyLoading.showInfo('Stop voice listening.');
                  _picovoiceManager.stop();
                } else {
                  EasyLoading.showSuccess('Start voice listening.');
                  _picovoiceManager.start();
                }
                setState(() {
                  _isPicoVoiceRunning = !_isPicoVoiceRunning;
                });
              },
              icon4: _isPicoVoiceRunning
                  ? Icon(Icons.mic_off_outlined)
                  : Icon(Icons.keyboard_voice),
              icon4Color: _isPicoVoiceRunning ? Colors.red : Colors.white,
            ),
          )
        ],
      ),
      floatingActionButton: FabCircularMenu(
        alignment: Alignment.bottomLeft,
        fabColor: Colors.white,
        fabOpenColor: Colors.black,
        fabMargin: EdgeInsets.fromLTRB(0, 0, 10, 100),
        fabOpenIcon: Icon(
          Icons.menu,
          color: Colors.black,
        ),
        fabCloseIcon: Icon(
          Icons.close,
          color: Colors.white,
        ),
        ringColor: Color(0xff202A30),
        children: <Widget>[
          MapFeatureIcon(
            name: "Alarm",
            color: Color(0xffcc0000),
            icon: Icons.notifications,
            context: context,
            tap: () {
              _alarmDialog(context);
            },
          ),
          MapFeatureIcon(
            name: "Fake",
            color: Color(0xff3333cc),
            icon: Icons.call,
            context: context,
            tap: () {
              showPickerArray(context);
            },
          ),
          MapFeatureIcon(
            name: "List",
            color: Colors.blue,
            icon: Icons.list,
            context: context,
            tap: () async {
              Get.toNamed(VideoListPage.routeName);
            },
          ),
          MapFeatureIcon(
            name: "Video",
            color: Colors.blue,
            icon: Icons.video_call,
            context: context,
            tap: () async {
              final PickedFile file = await _picker.getVideo(
                  source: ImageSource.camera,
                  maxDuration: Duration(seconds: 300));
              if (file != null) {
                EasyLoading.show(status: 'Uploading...');

                bool isUploaded = await uploadFile(".mp4", file.path, context);

                EasyLoading.dismiss();
                if (isUploaded) {
                  EasyDialog(
                    title: Text(
                      "Success",
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textScaleFactor: 1.2,
                    ),
                    description: Text(
                      "Upload successfully.",
                      textScaleFactor: 1.1,
                      textAlign: TextAlign.center,
                    ),
                  ).show(context);
                } else {
                  EasyDialog(
                    title: Text(
                      "Error",
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textScaleFactor: 1.2,
                    ),
                    description: Text(
                      "Uploading failed. Please check your internet.",
                      textScaleFactor: 1.1,
                      textAlign: TextAlign.center,
                    ),
                  ).show(context);
                }

                setState(() {
                  _imageFile = file;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  final SmsSendStatusListener listener = (SendStatus status) {
    print(status);
  };

  void _setSMS(String phone) {
    telephony.sendSms(
        to: phone,
        message:
            "HELP! I am in DANGER! Here is my position: http://maps.google.com/maps?q=" +
                mapCenter.latitude.toString() +
                "," +
                mapCenter.longitude.toString() +
                "&ll=" +
                mapCenter.latitude.toString() +
                "," +
                mapCenter.longitude.toString() +
                "&z=17. FROM Patronus.",
        statusListener: listener);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.setMapStyle(_mapStyle);
  }

  void getCurrentLocation() async {
    Position res = await Geolocator.getCurrentPosition();
    print(res);

    await BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(12, 12)),
            'assets/images/icon/icon_white.png')
        .then((d) {
      customIcon = d;
      _markers.add(Marker(
        markerId: MarkerId(LatLng(res.latitude, res.longitude).toString()),
        position: LatLng(res.latitude, res.longitude),
        infoWindow: InfoWindow(
          title: 'I am here',
        ),
        icon: customIcon,
      ));
    });

    setState(() {
      mapCenter = LatLng(res.latitude, res.longitude);
    });
  }

  void _alarm() async {
    List<CameraDescription> cameras = await availableCameras();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmPage(
          cameras: cameras,
        ),
      ),
    );
  }

  void _fakeCall() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return FakeCallPage();
    }));
  }

  void _countDown(int hour, int minute, int second) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return CountdownPage(
        hour: hour,
        minute: minute,
        second: second,
      );
    }));
  }

  showPickerArray(BuildContext context) {
    Picker(
        adapter: PickerDataAdapter<String>(
          pickerdata: JsonDecoder().convert(PickerData2),
          isArray: true,
        ),
        hideHeader: true,
        selecteds: [0, 0, 0],
        title: Text("Setting countdown time"),
        selectedTextStyle: TextStyle(color: Colors.blue),
        cancel: FlatButton(
            onPressed: () {
              Get.toNamed(FakeCallPage.routeName);
            },
            child: Text("Right Now")),
        onConfirm: (Picker picker, List value) {
          print(value.toString());
          print(picker.getSelectedValues());
          _countDown(
            int.parse(picker.getSelectedValues()[0]),
            int.parse(picker.getSelectedValues()[1]),
            int.parse(picker.getSelectedValues()[2]),
          );
        }).showDialog(context);
  }

  void _alarmDialog(BuildContext context) async {
    final SharedPreferences prefs = await _prefs;

    EasyDialog(
        closeButton: false,
        cornerRadius: 10.0,
        fogOpacity: 0.1,
        width: 280,
        height: 188,
        title: Text(
          "Countdown to Alarm",
          style: TextStyle(fontWeight: FontWeight.bold),
          textScaleFactor: 1.2,
        ),
        descriptionPadding:
            EdgeInsets.only(left: 17.5, right: 17.5, bottom: 15.0),
        description: Text(
            "After the countdown is over, the current location will be sent to ${prefs.getString('currentEmergencyContact')}, and the video will be recorded and an alarm will be issued at the same time."),
        contentPadding:
            EdgeInsets.only(top: 12.0), // Needed for the button design
        contentList: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0))),
            child: TextButton(
              onPressed: () {
                _timer.cancel();
                _start = 10;
                Navigator.of(context).pop();
              },
              child: StatefulBuilder(
                builder: (BuildContext context,
                    void Function(void Function()) setState) {
                  void startTimer() {
                    const oneSec = const Duration(seconds: 1);
                    _timer = new Timer.periodic(
                      oneSec,
                      (Timer timer) {
                        if (_start != 0) {
                          setState(() {
                            _start--;
                          });
                        } else {
                          timer.cancel();
                          _timer.cancel();
                          _start = 10;
                          Navigator.of(context).pop();
                          _setSMS("+353894168881");
                          _alarm();
                        }
                        timer.cancel();
                      },
                    );
                  }

                  startTimer();
                  return Text(
                    "Cancel($_start)",
                    style: TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ]).show(context);
  }

  void _initPicovoice() async {
    String keywordAsset = "assets/audio/patronus_android.ppn";
    String keywordPath = await _extractAsset(keywordAsset);
    String contextAsset = "assets/audio/fyp_en.rhn";
    String contextPath = await _extractAsset(contextAsset);

    try {
      _picovoiceManager = await PicovoiceManager.create(
          keywordPath, _wakeWordCallback, contextPath, _inferenceCallback);
      _picovoiceManager.start();
    } on PvError catch (ex) {
      print(ex);
    }
  }

  void _wakeWordCallback(int keywordIndex) {
    print("wake word detected!");
  }

  void _inferenceCallback(Map<String, dynamic> inference) {
    print(inference);
    print(inference["isUnderstood"]);
    if (inference["isUnderstood"] && inference["intent"] == "searchHelp") {
      _alarmDialog(context);
    }
  }

  Future<String> _extractAsset(String resourcePath) async {
    String resourceDirectory = (await getApplicationDocumentsDirectory()).path;
    String outputPath = '$resourceDirectory/$resourcePath';
    File outputFile = new File(outputPath);

    ByteData data = await rootBundle.load(resourcePath);
    final buffer = data.buffer;

    await outputFile.create(recursive: true);
    await outputFile.writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    return outputPath;
  }
}
