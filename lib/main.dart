import 'dart:convert';

import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;

void main() => runApp(WeatherApp());

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  int temperature;
  int woeid = 922137;
  String location = 'Kharkiv';
  String weather = 'clear';
  String abbrevation = '';
  String errorMessage = '';
  Position _currentPosition;
  // String _currentAddress;

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';
  String locationApiUrl = 'https://www.metaweather.com/api/location/';
  String getLocationUsingCordApiUrl =
      'https://www.metaweather.com/api/location/search/?lattlong=';

  // Position _positionItem;
  // String _currentAddress;
  // void getposition() async {
  //   Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);
  //   print(position);

  //   setState(() {
  //     correntPosition = position;
  //   });
  // }

  _getCurrentLocation() {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });
      print(_currentPosition);

      _getCity();
    }).catchError((e) {
      print(e);
    });
  }

  // _getAddressFromLatLng() async {
  //   //call this async method from whereever you need

  //   final coordinates =
  //       // new Coordinates(_currentPosition.latitude, _currentPosition.longitude);
  //       new Coordinates(22.334045050096638, 114.17622894161046);
  //   // print(coordinates);
  //   Locale locale = new Locale('en', 'EN');
  //   // final geocoder = new Geocoder(this, locale);
  //   var addresses = await Geocoder.local.findAddressesFromCoordinates(
  //     coordinates,
  //   );
  //   var first = addresses.first;
  //   // print(first);
  //   // print(
  //   //     ' ${first.locality}, ${first.adminArea},${first.subLocality}, ${first.subAdminArea},${first.addressLine}, ${first.featureName},${first.thoroughfare}, ${first.subThoroughfare}');
  //   print(
  //       ' ${first.locality},${first.subLocality}, ${first.subAdminArea},${first.addressLine}, ${first.featureName},${first.thoroughfare}, ${first.subThoroughfare}');
  //   return first;
  // }

  _getCity() async {
    try {
      var citylocation = await http.get(
          'https://www.metaweather.com/api/location/search/?lattlong=${_currentPosition.latitude},${_currentPosition.longitude}');
      var result = json.decode(citylocation.body)[0];

      setState(() {
        location = result['title'];
      });
      onTextFieldSubmitted(location);
    } catch (error) {
      setState(() {
        errorMessage =
            "Sorry, we don't have information about this sity. Try another one.";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  void fetchSearch(String input) async {
    try {
      var searchResult = await http.get(searchApiUrl + input);
      var result = json.decode(searchResult.body)[0];

      setState(() {
        location = result['title'];
        woeid = result['woeid'];
        errorMessage = '';
      });
    } catch (error) {
      setState(() {
        errorMessage =
            "Sorry, we don't have information about this sity. Try another one.";
      });
    }
  }

  void fetchLocation() async {
    var locationResult = await http.get(locationApiUrl + woeid.toString());
    var result = json.decode(locationResult.body);
    var consolidatedWeather = result["consolidated_weather"];
    var data = consolidatedWeather[0];

    setState(() {
      temperature = data["the_temp"].round();
      weather = data["weather_state_name"].replaceAll(' ', '').toLowerCase();
      abbrevation = data["weather_state_abbr"];
    });
  }

  void onTextFieldSubmitted(String input) async {
    await fetchSearch(input);
    await fetchLocation();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('images/$weather.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: temperature == null
          ? Center(child: CircularProgressIndicator())
          : Scaffold(
              appBar: AppBar(
                actions: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: GestureDetector(
                      onTap: () {
                        _getCurrentLocation();
                      },
                      child: Icon(Icons.location_city, size: 36.0),
                    ),
                  )
                ],
                backgroundColor: Colors.transparent,
                elevation: 0.0,
              ),
              backgroundColor: Colors.transparent,
              body: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Center(
                          child: Image.network(
                        'https://www.metaweather.com/static/img/weather/png/' +
                            abbrevation +
                            '.png',
                        width: 100,
                      )),
                      Center(
                        child: Text(
                          temperature.toString() + ' °C',
                          style: TextStyle(color: Colors.white, fontSize: 60.0),
                        ),
                      ),
                      Center(
                        child: Text(
                          location,
                          style: TextStyle(color: Colors.white, fontSize: 40.0),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Container(
                        width: 250,
                        child: TextField(
                          onSubmitted: (String input) {
                            onTextFieldSubmitted(input);
                          },
                          style: TextStyle(color: Colors.white, fontSize: 25),
                          decoration: InputDecoration(
                            hintText: 'Search location...',
                            hintStyle:
                                TextStyle(color: Colors.white, fontSize: 18),
                            prefixIcon: Icon(Icons.search, color: Colors.white),
                          ),
                        ),
                      ),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: Platform.isAndroid ? 15 : 20,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
    ));
  }
}
