import 'package:find_my_garage/Models/Garage.dart';
import 'package:find_my_garage/Screens/NewGarage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class Home extends StatefulWidget {
  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      showSnackBar("Could not launch", 1500);
    }
  }
  void viewOnMap(String longitudeLatitude){
    String url = "https://www.google.com/maps/search/?api=1&query=" + longitudeLatitude;
    launchURL(url);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Find My Garage Portal"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => NewGarage())),
        child: Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: Firestore.instance.collection('garages').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
          if (snapshot.hasData){
            if (snapshot.data.documents.length == 0){
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Center(
                      child: Text(
                        "No Garages",
                      )),
                ],
              );
            }
            else{
              return ListView.separated(
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Divider(
                    color: Colors.black,
                  ),
                ),

                itemCount: snapshot.data.documents.length,
                itemBuilder: (BuildContext context, int index){
                  Garage tempGarage = Garage.fromDocument(snapshot.data
                      .documents[index]);
                  return ListTile(
                    title: Text(tempGarage.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(height: 4,),
                        Text(tempGarage.telNo),
                        SizedBox(height: 4,),
                        Text(tempGarage.address),
                      ],
                    ),
                    leading: Text((index+1).toString()),
                    onLongPress: (){
                      viewOnMap(tempGarage.coordinates);
                    },
                  );
                },
              );
            }
          }
          else{
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(),
                    )),
              ],
            );
          }
          return SizedBox();
        },
      ),
      );
  }
}
