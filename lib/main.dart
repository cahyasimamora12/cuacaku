import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuacaku',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WeatherScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/splash.png',
              width: deviceWidth * 1.1, // You can adjust the factor according to your design
              height: deviceHeight * 1.0, // You can adjust the factor according to your design
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  final String apiKey = 'be75d74b786c7d2396a720bf8234c01f';
  final String weatherApiUrl = 'https://api.openweathermap.org/data/2.5/weather';
  TextEditingController cityController = TextEditingController();
  String cityName = '';
  String weatherDescription = '';
  String weatherIcon = '';
  double temperature = 0.0;
  bool isSearching = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2), // Adjust the duration as needed
    );

    // Initialize animation
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _getDefaultWeather();
  }

  Future<void> _getDefaultWeather() async {
    cityName = 'Bogor';
    await fetchWeather();
  }

  Future<void> fetchWeather() async {
    final Uri uri = Uri.parse('$weatherApiUrl?q=$cityName&appid=$apiKey');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        weatherDescription = data['weather'][0]['description'];
        weatherIcon = data['weather'][0]['icon'];
        temperature = (data['main']['temp'] - 273.15); // Convert to Celsius
      });

      // Trigger animation based on weather conditions
      _triggerAnimation();
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  void _triggerAnimation() {
    // Reset the animation
    _animationController.reset();

    // Add conditions based on weather for triggering animation
    if (weatherDescription.contains('rain') || weatherDescription.contains('broken clouds')) {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching ? buildSearchField() : Text('Cuacaku'),
        backgroundColor: getBackgroundColor(),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
              });
            },
            icon: Icon(isSearching ? Icons.cancel : Icons.search),
          ),
          if (isSearching)
            IconButton(
              onPressed: () {
                setState(() {
                  cityName = cityController.text;
                });
                fetchWeather();
              },
              icon: Icon(Icons.check),
            ),
        ],
      ),
      backgroundColor: getBackgroundColor(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (weatherDescription.isNotEmpty)
                FadeTransition(
                  opacity: _animation,
                  child: Container(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        children: [
                          Text(
                            'City: $cityName',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16.0),
                          Text('Temperature: ${temperature.toStringAsFixed(2)}°C'),
                          Text('Description: $weatherDescription'),
                          SizedBox(height: 16.0),
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(
                                  'https://openweathermap.org/img/w/$weatherIcon.png',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchField() {
    return TextField(
      controller: cityController,
      decoration: InputDecoration(
        labelText: 'Enter City',
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Color getBackgroundColor() {
    if (weatherDescription.contains('rain') || weatherDescription.contains('broken clouds')) {
      return Colors.blueGrey;
    } else if (weatherDescription.contains('clear')) {
      return Colors.yellow;
    } else if (weatherDescription.contains('cloud')) {
      return Colors.grey;
    } else {
      return Colors.white;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
