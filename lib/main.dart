import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/widgets/week_forecast.dart';

void main() => runApp(WeatherApp());

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  int temperature;
  var minTemperatureForecast = new List(7);
  var maxTemperatureForecast = new List(7);
  String location = 'Kharkiv';
  int woeid = 922137;
  String weather = '1';
  String abbrevation = '';
  final abbreviationForecast = new List(7);
  String errorMessage = '';

  Position _currentPosition;
  final _controller = TextEditingController();

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';
  String locationApiUrl = 'https://www.metaweather.com/api/location/';
  String getLocationUsingCordApiUrl =
      'https://www.metaweather.com/api/location/search/?lattlong=';

  @override
  void initState() {
    super.initState();
    fetchLocation();
    fetchLocationDay();
  }

  Future<void> fetchSearch(String input) async {
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

  Future<void> fetchLocation() async {
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

  Future<void> fetchLocationDay() async {
    var today = new DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationDayResult = await http.get(locationApiUrl +
          woeid.toString() +
          '/' +
          new DateFormat('y/M/d')
              .format(today.add(new Duration(days: i + 1)))
              .toString());
      var result = json.decode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTemperatureForecast[i] = data["min_temp"].round();
        maxTemperatureForecast[i] = data["max_temp"].round();
        abbreviationForecast[i] = data["weather_state_abbr"];
      });
    }
  }

  void onTextFieldSubmitted(String input) async {
    await fetchSearch(input);
    await fetchLocation();
    await fetchLocationDay();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage('images/$weather.png'),
            fit: BoxFit.cover,
            colorFilter: new ColorFilter.mode(
                Colors.black.withOpacity(0.6), BlendMode.dstATop)),
      ),
      child: maxTemperatureForecast[6] == null
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
                      child: Icon(Icons.add_location_outlined, size: 36.0),
                    ),
                  )
                ],
                backgroundColor: Colors.transparent,
                elevation: 0.0,
              ),
              resizeToAvoidBottomInset: false,
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        for (var i = 0; i < 7; i++)
                          forecastElement(
                              i + 1,
                              abbreviationForecast[i],
                              minTemperatureForecast[i],
                              maxTemperatureForecast[i]),
                      ],
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      Container(
                        width: 250,
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (String input) {
                            onTextFieldSubmitted(input);
                            _controller.clear();
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
                      Container(
                        margin: EdgeInsets.all(10),
                        height: 50.0,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                  side: BorderSide(color: Colors.transparent)),
                              padding: EdgeInsets.all(10.0),
                              primary: Colors.transparent,
                              textStyle:
                                  TextStyle(color: Colors.white, fontSize: 17),
                            ),
                            onPressed: _getCurrentLocation,
                            child: Text('Use current location!')),
                      ),
                    ],
                  )
                ],
              ),
            ),
    ));
  }
}

Widget forecastElement(
    daysFromNow, abbreviation, minTemperature, maxTemperature) {
  var now = new DateTime.now();
  var oneDayFromNow = now.add(new Duration(days: daysFromNow));
  return Padding(
    padding: const EdgeInsets.only(left: 16.0),
    child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(205, 212, 228, 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              new DateFormat.E().format(oneDayFromNow),
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            Text(
              new DateFormat.MMMd().format(oneDayFromNow),
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: Image.network(
                'https://www.metaweather.com/static/img/weather/png/' +
                    abbreviation +
                    '.png',
                width: 50,
              ),
            ),
            Text(
              'High: ' + maxTemperature.toString() + ' °C',
              style: TextStyle(color: Colors.white, fontSize: 20.0),
            ),
            Text(
              'Low: ' + minTemperature.toString() + ' °C',
              style: TextStyle(color: Colors.white, fontSize: 20.0),
            ),
          ],
        ),
      ),
    ),
  );
}
