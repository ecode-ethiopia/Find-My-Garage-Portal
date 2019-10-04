import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_my_garage/Models/Garage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:find_my_garage/Models/Globals.dart' as Globals;
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';

class UploadDialog extends StatefulWidget {
  @override
  UploadDialogState createState() => UploadDialogState(this.garage);

  final Garage garage;
  UploadDialog(this.garage);
}

class UploadDialogState extends State<UploadDialog> {
  UploadDialogState(this.garage);

  StorageUploadTask uploadTask;
  Garage garage;

  int currentUploadCount = 0;
  List<String> images = new List<String>();

  Future uploadImage(String fileName, File file)async{
    StorageReference storageReference = FirebaseStorage.instance.ref()
        .child("images").child(fileName);
    setState(() {
      uploadTask = storageReference.putFile(file);
    });
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    await taskSnapshot.ref.getDownloadURL().then((value){
      String downloadURL = value.toString();
      images.add(downloadURL);
      setState(() {
        currentUploadCount++;
      });
      if (currentUploadCount >= Globals.images.length){
        Garage tempGarage = new Garage(
            this.garage.name,
            this.garage.address,
            this.garage.telNo,
            this.garage.vehicleCategory,
            this.garage.specializedIn,
            this.garage.openTime,
            this.garage.closeTime,
            this.garage.closedDates,
            this.garage.coordinates,
            this.garage.canHandleCritical,
            this.images,
        );
        newGarageToFireStore(tempGarage);
      }
    });
  }

  void showSnackBar(String title, int duration){
    Globals.scaffoldKey.currentState.hideCurrentSnackBar(reason:
    SnackBarClosedReason.remove);
    Globals.scaffoldKey.currentState.showSnackBar
      (SnackBar(
      content: Row(
        children: <Widget>[
          Text(title)
        ],
      ),
      duration: Duration(milliseconds: duration),));
    HapticFeedback.mediumImpact();
  }
  void uploadAllImagesToFirebaseStorage(){
    Globals.images.forEach((File file){
      String fileName = this.garage.name + "_" + file.path.split('/').last;
      uploadImage(fileName, file);
    });
  }
  void newGarageToFireStore(Garage newGarage)async{
    await Firestore.instance
        .collection("garages")
        .add(newGarage.toDocument()).then((value){
      currentUploadCount = 0;
      Navigator.of(context).pop();
      showSnackBar("Saved", 1000);
    }).catchError((e){
      Navigator.of(context).pop();
      showSnackBar(e.toString(), 2000);
    }).timeout(Duration(seconds: 10), onTimeout: (){
      Navigator.of(context).pop();
      showSnackBar("Time out, check your internet connection", 2000);
    });
  }

  @override
  void initState() {
    super.initState();
    if (Globals.images.length !=0)uploadAllImagesToFirebaseStorage();
    else{
      newGarageToFireStore(this.garage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: Alignment.center,
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              (uploadTask == null)?SizedBox():StreamBuilder<StorageTaskEvent>(
                stream: uploadTask.events,
                builder: (_, snapshot){
                  var event = snapshot?.data?.snapshot;
                  double progressPercent = 0;
                  if (uploadTask.isInProgress){
                    progressPercent = (event != null)?event
                        .bytesTransferred/event.totalByteCount:0;
                  }
                  if (uploadTask.isComplete) progressPercent = 1;
                  return SizedBox(
                    width: 300,
                    height: 300,
                    child: CircularPercentIndicator(
                      radius: 120.0,
                      lineWidth: 13.0,
                      animation: true,
                      animateFromLastPercent: true,
                      percent: progressPercent,
                      center: new Text(
                        (progressPercent*100).toInt().toString()+"%",
                        style:
                        new TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 20.0, color: Colors.white),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: Theme.of(context).primaryColor,
                    ),
                  );
                },
              ),
              SizedBox(height: 50,),
              SizedBox(
                height: 5,
                width: MediaQuery.of(context).size.width,
                child: LinearProgressIndicator(),
              ),
              SizedBox(height: 30,),
              Shimmer.fromColors(
                baseColor: Colors.white,
                highlightColor: Colors.grey.withOpacity(0.5),
                period: Duration(seconds: 2),
                child: (uploadTask == null)?Text(
                  "Saving...",
                  style:
                  new TextStyle(fontWeight: FontWeight.normal, fontSize: 24.0,
                      color: Colors.white),
                ):Text(
                  "Saving...("+(((currentUploadCount+1) < Globals.images.length)
                      ?(currentUploadCount+1):Globals.images.length)
                      .toString()
                      +"/"+Globals.images.length.toString()+")",
                  style:
                  new TextStyle(fontWeight: FontWeight.normal, fontSize: 24.0,
                      color: Colors.white),
                ),
              ),
              SizedBox(height: 50,),
            ],
          ),
        ],
      ),
    );
  }
}