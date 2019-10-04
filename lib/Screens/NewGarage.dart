import 'dart:io';
import 'dart:ui';
import 'package:find_my_garage/Models/Garage.dart';
import 'package:find_my_garage/Screens/UploadDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:find_my_garage/Models/Globals.dart' as Globals;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

class NewGarage extends StatefulWidget {
  @override
  NewGarageState createState() => NewGarageState();
}

class NewGarageState extends State<NewGarage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  var openTimeTextController = TextEditingController();
  var closeTimeTextController = TextEditingController();
  var coordinateTextController = TextEditingController();

  Geolocator geoLocator;
  bool autoValidate = false;

  String name = "";
  String address = "";
  String telNo = "";
  String vehicleCategory = "";
  String specializedIn = "";
  String openTime = "";
  String closeTime = "";
  String closedDates = "";
  String coordinates = "";
  bool canHandleCritical = false;
  List<String> images = new List<String>();

  Future<TimeOfDay> selectTime(BuildContext context, int hour, int minute) {
    return showTimePicker(
        context: context, initialTime: TimeOfDay(hour: hour, minute: minute));
  }
  Future<Position> getCurrentLocation() async {
    var currentLocation;
    try {
      currentLocation = await geoLocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
    } catch (e) {
      currentLocation = null;
      print(e);
    }
    return currentLocation;
  }
  Future getImageFromCamera() async {
    var imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
    if (imageFile == null) return;
    List<File> tempFileList = new List<File>();
    tempFileList = Globals.images.where((File item){
      if (item.path == imageFile.path) return true;
      else return false;
    }).toList();
    if (tempFileList.length == 0){
      setState((){
        Globals.images.add(imageFile);
      });
    }
    else{
      showSnackBar("Alreay exists", 1000);
    }
  }
  Future getImageFromGallery() async {
    var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;
    List<File> tempFileList = new List<File>();
    tempFileList = Globals.images.where((File item){
      if (item.path == imageFile.path) return true;
      else return false;
    }).toList();
    if (tempFileList.length == 0){
      setState((){
        Globals.images.add(imageFile);
      });
    }
    else{
      showSnackBar("Alreay exists", 1000);
    }
  }

  Widget imageList(){
    return Container(
      height: 100.0 * Globals.images.length,
      child: ListView.separated(
        separatorBuilder: (BuildContext context, int index){
          return Divider();
        },
        itemBuilder: (BuildContext context, int index){
          return Row(
            children: <Widget>[
              Image.file(Globals.images[index], fit:
              BoxFit.contain, width: 160, height: 90,),
              SizedBox(width: 20,),
              IconButton(
                onPressed: () => removePicture(index),
                icon: Icon(Icons.close),
              ),
            ],
          );
        },
        itemCount: Globals.images.length,
        scrollDirection: Axis.vertical,
        physics: NeverScrollableScrollPhysics(),
      ),
    );
  }

  void setOpenTime() async {
    final selectedTime = await selectTime(context, 8, 30);
    if (selectedTime != null) {
      setState(() {
        openTime = selectedTime.format(context);
        openTimeTextController.text = openTime;
      });
    }
  }
  void setCloseTime() async {
    final selectedTime = await selectTime(context, 17, 0);
    if (selectedTime != null) {
      setState(() {
        closeTime = selectedTime.format(context);
        closeTimeTextController.text = closeTime;
      });
    }
  }
  void setCurrentCoordinates(){
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return WillPopScope(
              onWillPop: () => null,
              child: Material(
                type: MaterialType.transparency,
                child: Stack(
                  children: <Widget>[
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5,sigmaY: 5),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Center(
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
          );
        }
    );
    getCurrentLocation().then((position){
      String currentCoordinates = position.latitude.toString() + "," + position
          .longitude.toString();
      Navigator.of(context).pop();
      setState(() {
        coordinates = currentCoordinates;
        coordinateTextController.text = coordinates;
      });
    }).catchError((e){
      Navigator.of(context).pop();
      showSnackBar(e, 2000);
    }).timeout(Duration(seconds: 10), onTimeout: (){
      Navigator.of(context).pop();
      showSnackBar("Time out, check your settings", 2000);
    });
  }
  void onSaved(){
    setState(() {
      autoValidate = true;
    });
    if(_formKey.currentState.validate()){
      _formKey.currentState.save();
      Garage newGarage = new Garage(name, address, telNo, vehicleCategory,
          specializedIn, openTime, closeTime, closedDates, coordinates,
          canHandleCritical, images);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return WillPopScope(
              onWillPop: () => null,
              child: UploadDialog(newGarage),
          );
        }
      );
    }
    else{
      showSnackBar("check all the fields", 1000);
    }
  }
  void viewOnMap(String longitudeLatitude){
    String url = "https://www.google.com/maps/search/?api=1&query=" + longitudeLatitude;
    launchURL(url);
  }
  void launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      showSnackBar("Could not launch", 1500);
    }
  }
  void removePicture(int index){
    setState(() {
      Globals.images.removeAt(index);
    });
  }
  void showSnackBar(String title, int duration){
    _scaffoldKey.currentState.hideCurrentSnackBar(reason:
    SnackBarClosedReason.remove);
    _scaffoldKey.currentState.showSnackBar
      (SnackBar(
      content: Row(
        children: <Widget>[
          Text(title)
        ],
      ),
      duration: Duration(milliseconds: duration),));
    HapticFeedback.mediumImpact();
  }

  @override
  void initState() {
    super.initState();
    geoLocator = Geolocator()..forceAndroidLocationManager;
    openTimeTextController.text = openTime;
    closeTimeTextController.text = closeTime;
    coordinateTextController.text = coordinates;
    Globals.images.clear();
    Globals.scaffoldKey = _scaffoldKey;
  }

  @override
  void dispose() {
    Globals.images.clear();
    Globals.scaffoldKey = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("New Garage"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      autovalidate: autoValidate,
                      validator: (value){
                        if (value.isEmpty) return "*required";
                        return null;
                      },
                      onSaved: (value){
                        name = value.trim();
                      },
                      decoration: InputDecoration(
                          border: OutlineInputBorder(), labelText: "Name"),
                    ),
                    SizedBox(height: 20,),
                    TextFormField(
                      maxLines: 3,
                      autovalidate: autoValidate,
                      validator: (value){
                        if (value.isEmpty) return "*required";
                        return null;
                      },
                      onSaved: (value){
                        address = value.trim();
                      },
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Address"),
                    ),
                    SizedBox(height: 20,),
                    TextFormField(
                      autovalidate: autoValidate,
                      validator: (value){
                        RegExp regex = RegExp(r"^[0-9]{10}$");
                        if (value.isEmpty) return "*required";
                        if (value.length != 10) return "invalid";
                        if (!regex.hasMatch(value)) return "invalid";
                        return null;
                      },
                      onSaved: (value){
                        telNo = value.trim();
                      },
                      maxLength: 10,
                      maxLengthEnforced: true,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Tel No."),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      autovalidate: autoValidate,
                      validator: (value){
                        if (value.isEmpty) return "*required";
                        return null;
                      },
                      onSaved: (value){
                        vehicleCategory = value.trim();
                      },
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Vehical Category"),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      autovalidate: autoValidate,
                      validator: (value){
                        if (value.isEmpty) return "*required";
                        return null;
                      },
                      onSaved: (value){
                        specializedIn = value.trim();
                      },
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Specialized In"),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            autovalidate: autoValidate,
                            readOnly: true,
                            onTap: setOpenTime,
                            validator: (value){
                              if (value.isEmpty) return "*required";
                              return null;
                            },
                            controller: openTimeTextController,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Open At"
                            ),
                          ),
                        ),
                        SizedBox(width: 20,),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            autovalidate: autoValidate,
                            readOnly: true,
                            onTap: setCloseTime,
                            validator: (value){
                              if (value.isEmpty) return "*required";
                              return null;
                            },
                            controller: closeTimeTextController,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Close At"
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      autovalidate: autoValidate,
                      validator: (value){
                        if (value.isEmpty) return "*required";
                        return null;
                      },
                      onSaved: (value){
                        closedDates = value.trim();
                      },
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Closed Days"),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: <Widget>[
                        SizedBox(
                          width: 250,
                          child: TextFormField(
                            autovalidate: autoValidate,
                            validator: (value){
                              if (value.isEmpty) return "*required";
                              return null;
                            },
                            controller: coordinateTextController,
                            readOnly: true,
                            onTap: setCurrentCoordinates,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Coordinates"),
                          ),
                        ),
                        SizedBox(width: 10,),
                        (coordinates.isEmpty)?SizedBox():IconButton(
                            icon: Icon(Icons.map),
                            iconSize: 40,
                            onPressed: (){
                              viewOnMap(coordinates);
                            }
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: <Widget>[
                        Text("Can react for critical situations"),
                        Checkbox(
                          value: canHandleCritical,
                          onChanged: (value) {
                            setState(() {
                              canHandleCritical = value;
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.photo),
                          iconSize: 40,
                          onPressed: getImageFromGallery,
                        ),
                        SizedBox(width: 50,),
                        IconButton(
                          iconSize: 40,
                          icon: Icon(Icons.camera_alt),
                          onPressed: getImageFromCamera,
                        ),
                      ],
                    ),
                    SizedBox(height: 20,),
                    (Globals.images.length == 0)?SizedBox():imageList(),
                    SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        RaisedButton(
                          onPressed: onSaved,
                          color: Theme.of(context).primaryColor,
                          child: Text("SAVE", style: TextStyle(color: Colors
                              .white),),
                        ),
                      ],
                    ),
                    SizedBox(height: 20,)
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
