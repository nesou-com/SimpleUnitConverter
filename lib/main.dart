import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'colors.dart';

String _appVersion = "Version: 1.0.1";

void main() async {
  await Hive.initFlutter();

  //disable the landscape mode Start
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  //disable the landscape mode End

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //Show or Hide Debug Banner
      title: 'Simple Unit Converter',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: kNesouColor300,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: kNesouColor300,
      ),
      home: FutureBuilder(
        future: Hive.openBox<String>('myBox'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.error != null) {
              return const Scaffold(
                body: Center(
                  child: Text('Something went wrong :/'),
                ),
              );
            } else {
              return const MyHomePage(title: 'Simple Unit Converter');
            }
          } else {
            return Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Text('Loading...'),
                  CircularProgressIndicator(),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class Item {
  Item(this.name, this.icon);
  String name;
  Icon icon;
}

class _MyHomePageState extends State<MyHomePage> {
  late TextEditingController _controllerTop, _controllerBottom;
  bool _restoreValue = true;
  String _measuresTypeValue = '0';

  double _topValue = 1.0;
  double _bottomValue = 1.0;

  String _measuresTop = '0';
  String _measuresBottom = '0';
  late String _measuresUnitTop;
  late String _measuresUnitBottom;

  int _standardTop = 0;
  int _standardBottom = 0;

  late double _calculateTop;
  late double _calculateBottom;

  late Box<String> _box;

  void initState() {
    super.initState();

    _box = Hive.box<String>('myBox');
    _controllerTop = TextEditingController(text: '1');
    _controllerBottom = TextEditingController();
    if (_measuresTypeValue == '0') {
      _measuresTypeValue = _box.get('_measuresTypeValue', defaultValue: 'Weight')!;
    }

    _typeSelected(_measuresTypeValue);
  }

  @override
  void dispose() {
    _controllerTop.dispose();
    _controllerBottom.dispose();
    super.dispose();
  }

  late List<String> _measures;

  final _measuresType = [
    Item('Temperature', const Icon(Icons.thermostat, color: Colors.white, size: 30)),
    Item('Weight', const Icon(Icons.monitor_weight, color: Colors.white, size: 30)),
    Item('Length', const Icon(Icons.straighten, color: Colors.white, size: 30)),
    Item('Area', const Icon(Icons.square_foot, color: Colors.white, size: 30)),
  ];

  final dynamic _measuresTypeMap = {
    'Temperature': ['Celsius (°C)', 'Fahrenheit (°F)', 'Kelvin (K)'],
    'Weight': ['Milligrams (mg)', 'Grams (g)', 'Kilograms (kg)', 'Ton (t)', 'Pounds (lb)', 'Ounces (oz)', '돈', '근'],
    'Length': ['Millimeters (mm)', 'Centimeters (cm)', 'Meters (m)', 'Kilometers (km)', 'Inches (in)', 'Feet (ft)', 'Yards (yd)', 'Miles (mi)'],
    'Area': [
      'Square Inch (in²)',
      'Square Millimeter (mm²)',
      'Square Centimeter (cm²)',
      'Square Foot (ft²)',
      'Square Meter (m²)',
      'Square Yard (yd²)',
      'Square Kilometer (km²)',
      'Square Mile (mi²)',
      'Hectare (ht)',
      'Acre (ac)',
      'Are (a)',
      '평 (평)'
    ]
  };

  final dynamic _measuresTypeMapDetail = {
    // Temperature
    'Celsius (°C)': ['°C', 0],
    'Fahrenheit (°F)': ['°F', 1],
    'Kelvin (K)': ['K', 2],

    // Weight
    'Milligrams (mg)': ['mg', 0, 1, 1000, 1000000, 1000000000, 453592.2922, 28349.52308, 3749.999995, 599999.88],
    'Grams (g)': ['g', 1, 0.001, 1, 1000, 1000000, 453.5922922, 28.34952308, 3.749999995, 599.99988],
    'Kilograms (kg)': ['kg', 2, 0.000001, 0.001, 1, 1000, 0.4535922922, 0.02834952308, 0.003749999995, 0.59999988],
    'Ton (t)': ['t', 3, 0.000000001, 0.000001, 0.001, 1, 0.0004535922922, 0.00002834952308, 0.000003749999995, 0.00059999988],
    'Pounds (lb)': ['lb', 4, 0.000002204623, 0.002204623, 2.204623, 2204.623, 1, 0.06250001063, 0.00826733624, 1.322773535],
    'Ounces (oz)': ['oz', 5, 0.000035273962, 0.035273962, 35.273962, 35273.962, 15.99999728, 1, 0.1322773573, 21.16437297],
    '돈': ['돈', 6, 0.000266666667, 0.266666667, 266.666667, 266666.667, 120.9579447, 7.559872832, 1, 159.9999682],
    '근': ['근', 7, 0.000001666667, 0.001666667, 1.666667, 1666.667, 0.7559873049, 0.04724921459, 0.006250001242, 1],

    // Length
    'Millimeters (mm)': ['mm', 0, 1, 10, 1000, 1000000, 25.4, 304.8, 914.4, 1609344],
    'Centimeters (cm)': ['cm', 1, 0.1, 1, 100, 100000, 2.54, 30.48, 91.44, 160934.4],
    'Meters (m)': ['m', 2, 0.001, 0.01, 1, 1000, 0.0254, 0.3048, 0.9144, 1609.344],
    'Kilometers (km)': ['km', 3, 0.000001, 0.00001, 0.001, 1, 0.000025, 0.000305, 0.000914, 1.609344],
    'Inches (in)': ['in', 4, 0.03937, 0.393701, 39.37008, 39370.08, 1, 12, 36, 63360],
    'Feet (ft)': ['ft', 5, 0.003281, 0.032808, 3.28084, 3280.84, 0.083333, 1, 3, 5280],
    'Yards (yd)': ['yd', 6, 0.001094, 0.010936, 1.093613, 1093.613, 0.027778, 0.333333, 1, 1760],
    'Miles (mi)': ['mi', 7, 6.21E-07, 0.000006, 0.000621, 0.621371, 0.000016, 0.000189, 0.000568, 1],

    // Area
    'Square Inch (in²)': ['in²', 0, 1, 0.00155, 0.155, 143.9997176, 1550, 1295.997458, 1550000000, 4014504015, 15500000, 6275303.644, 155000, 5123.966942],
    'Square Millimeter (mm²)': ['mm²', 1, 645.1612903, 1, 100, 92903.0436, 1000000, 836127.3924, 1000000000000, 2590002590003, 10000000000, 4048582996, 100000000, 3305785.124],
    'Square Centimeter (cm²)': ['cm²', 2, 6.451612903, 0.01, 1, 929.030436, 10000, 8361.273924, 10000000000, 25900025900, 100000000, 40485829.96, 1000000, 33057.85124],
    'Square Foot (ft²)': ['ft²', 3, 0.006944458065, 0.00001076391, 0.001076391, 1, 10.76391, 9, 10763910, 27878554.78, 107639.1, 43578.583, 1076.391, 35.58317355],
    'Square Meter (m²)': ['m²', 4, 0.0006451612903, 0.000001, 0.0001, 0.0929030436, 1, 0.8361273924, 1000000, 2590002.59, 10000, 4048.582996, 100, 3.305785124],
    'Square Yard (yd²)': ['yd²', 5, 0.0007716064516, 0.00000119599, 0.000119599, 0.1111111111, 1.19599, 1, 1195990, 3097617.198, 11959.9, 4842.064777, 119.599, 3.95368595],
    'Square Kilometer (km²)': ['km²', 6, 0.0000000006451612903, 0, 0.0000000001, 0.0000000929030436, 0.000001, 0.0000008361273924, 1, 2.59000259, 0.01, 0.004048582996, 0.0001, 0.000003305785124],
    'Square Mile (mi²)': ['mi²', 7, 0.0000000002490967742, 0, 0, 0.00000003586986513, 0.0000003861, 0.0000003228287862, 0.3861, 1, 0.003861, 0.001563157895, 0.00003861, 0.000001276363636],
    'Hectare (ht)': ['ht', 8, 0.00000006451612903, 0.0000000001, 0.00000001, 0.00000929030436, 0.0001, 0.00008361273924, 100, 259.000259, 1, 0.4048582996, 0.01, 0.0003305785124],
    'Acre (ac)': ['ac', 9, 0.0000001593548387, 0.000000000247, 0.0000000247, 0.00002294705177, 0.000247, 0.0002065234659, 247, 639.7306397, 2.47, 1, 0.0247, 0.0008165289256],
    'Are (a)': ['a', 10, 0.000006451612903, 0.00000001, 0.000001, 0.000929030436, 0.01, 0.008361273924, 10000, 25900.0259, 100, 40.48582996, 1, 0.03305785124],
    '평 (평)': ['평', 11, 0.0001951612903, 0.0000003025, 0.00003025, 0.02810317069, 0.3025, 0.2529285362, 302500, 783475.7835, 3025, 1224.696356, 30.25, 1],

    //Volume
  };

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: kNesouColor300,
        ),
        drawer: Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                padding: EdgeInsetsDirectional.only(top: 116.0, start: 16.0),
                decoration: BoxDecoration(
                  color: kNesouColor300,
                ),
                child: Text(
                  'Simple Unit Converter',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              ListTile(
                title: const Text('Contact us'),
                onTap: () {
                  launch("mailto:apps@nesou.com?subject=Simple%20Unit%20Converter");
                },
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                onTap: () {
                  launch("https://www.nesou.com/apps/privacy_policy.html");
                },
              ),
              ListTile(
                title: Text(_appVersion),
              ),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: kNesouColor100,
                border: Border.all(
                  color: kNesouColor100,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [buildBoxShadow()],
              ),
              margin: const EdgeInsets.all(10),
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                child: DropdownButton(
                  isExpanded: true,
                  dropdownColor: kNesouColor100,
                  borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                  value: _measuresTypeValue,
                  underline: DropdownButtonHideUnderline(
                    child: Container(),
                  ),
                  items: _measuresType
                      .map((e) => DropdownMenuItem(
                            child: Row(children: [
                              e.icon,
                              const SizedBox(width: 10),
                              Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: kNesouColor900)),
                            ]),
                            value: e.name,
                          ))
                      .toList(),
                  onChanged: (value) {
                    _typeSelected(value.toString());
                  },
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: kNesouColor100,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                boxShadow: [buildBoxShadow()],
              ),
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: TextField(
                // maxLength: 8,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                ],
                style: const TextStyle(fontSize: 50, color: Colors.black),
                controller: _controllerTop,
                decoration: InputDecoration(
                  counterText: '',
                  suffixText: _measuresUnitTop,
                  suffixStyle: const TextStyle(fontSize: 25, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controllerTop.clear();
                    },
                  ),
                  border: InputBorder.none,
                ),
                onEditingComplete: () {},
                onChanged: (value) {
                  _convertValue('top', value);
                },

                onSubmitted: (value) async {
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
              decoration: BoxDecoration(
                color: kNesouColor100,
                border: Border.all(
                  color: kNesouColor100,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                boxShadow: [buildBoxShadow()],
              ),
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: DropdownButton(
                isExpanded: true,
                dropdownColor: kNesouColor100,
                borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                value: _measuresTop,
                underline: DropdownButtonHideUnderline(child: Container()),
                items: _measures.map((e) => DropdownMenuItem(child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kNesouColor900)), value: e)).toList(),
                onChanged: (value) {
                  _convertUnit('top', value.toString());
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: kNesouColor100,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                boxShadow: [buildBoxShadow()],
              ),
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: TextField(
                // maxLength: 8,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                ],
                style: const TextStyle(fontSize: 50, color: Colors.black),
                controller: _controllerBottom,
                decoration: InputDecoration(
                  counterText: '',
                  suffixText: _measuresUnitBottom,
                  suffixStyle: const TextStyle(fontSize: 25, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controllerBottom.clear();
                    },
                  ),
                  border: InputBorder.none,
                ),
                onEditingComplete: () {},
                onChanged: (value) {
                  _convertValue('bottom', value);
                },

                onSubmitted: (value) async {
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
              decoration: BoxDecoration(
                color: kNesouColor100,
                border: Border.all(
                  color: kNesouColor100,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                boxShadow: [buildBoxShadow()],
              ),
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: DropdownButton(
                isExpanded: true,
                dropdownColor: kNesouColor100,
                borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                value: _measuresBottom,
                underline: DropdownButtonHideUnderline(child: Container()),
                items: _measures.map((e) => DropdownMenuItem(child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kNesouColor900)), value: e)).toList(),
                onChanged: (value) {
                  _convertUnit('bottom', value.toString());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxShadow buildBoxShadow() {
    return BoxShadow(
      color: Colors.grey.withOpacity(0.5),
      spreadRadius: 0,
      blurRadius: 10,
      offset: const Offset(2, 2), // changes position of shadow
    );
  }

  void _typeSelected(String value) {
    setState(() {
      _measures = _measuresTypeMap[value];
      _measuresTypeValue = value;
      _box.put('_measuresTypeValue', value);

      if (_restoreValue == true) {
        _measuresTop = _box.get('_measuresTop', defaultValue: _measures[0])!;
        _measuresBottom = _box.get('_measuresBottom', defaultValue: _measures[1])!;
      } else {
        _measuresTop = _measures[0];
        _measuresBottom = _measures[1];
      }
      _restoreValue = false;

      _convertUnit('top', _measuresTop);
    });
  }

  void _convertValue(String s, String value) {
    if (s == 'top') {
      setState(() {
        _unitSet();

        if (_measuresTypeValue == 'Temperature') {
          _topValue = double.parse(value);
          if (_measuresUnitTop == '°C') {
            if (_measuresUnitBottom == '°C') {
              _bottomValue = _topValue;
            } else if (_measuresUnitBottom == '°F') {
              _bottomValue = (_topValue * 9 / 5) + 32;
            } else if (_measuresUnitBottom == 'K') {
              _bottomValue = _topValue + 273.15;
            }
          } else if (_measuresUnitTop == '°F') {
            if (_measuresUnitBottom == '°C') {
              _bottomValue = (_topValue - 32) * 5 / 9;
            } else if (_measuresUnitBottom == '°F') {
              _bottomValue = _topValue;
            } else if (_measuresUnitBottom == 'K') {
              _bottomValue = (_topValue + 459.67) / 1.8;
            }
          } else if (_measuresUnitTop == 'K') {
            if (_measuresUnitBottom == '°C') {
              _bottomValue = _topValue - 273.15;
            } else if (_measuresUnitBottom == '°F') {
              _bottomValue = (1.8 * _topValue) - 459.67;
            } else if (_measuresUnitBottom == 'K') {
              _bottomValue = _topValue;
            }
          }
          _controllerBottom.text = _convertNumberToLimit(_bottomValue, 7);

          _calculateTop = 0;
          _calculateBottom = 0;
        } else {
          _calculateTop = _measuresTypeMapDetail[_measuresTop][_standardTop].toDouble();
          _calculateBottom = _measuresTypeMapDetail[_measuresBottom][_standardTop].toDouble();

          _topValue = double.parse(value);
          _bottomValue = _calculateBottom * _topValue;
          _controllerBottom.text = _convertNumberToLimit(_bottomValue, 7);
        }
      });
    } else if (s == 'bottom') {
      setState(() {
        _unitSet();
        if (_measuresTypeValue == 'Temperature') {
          _bottomValue = double.parse(value);
          if (_measuresUnitTop == '°C') {
            if (_measuresUnitBottom == '°C') {
              _topValue = _bottomValue;
            } else if (_measuresUnitBottom == '°F') {
              _topValue = (_bottomValue - 32) * 5 / 9;
            } else if (_measuresUnitBottom == 'K') {
              _topValue = _bottomValue - 273.15;
            }
          } else if (_measuresUnitTop == '°F') {
            if (_measuresUnitBottom == '°C') {
              _topValue = (_bottomValue * 9 / 5) + 32;
            } else if (_measuresUnitBottom == '°F') {
              _topValue = _bottomValue;
            } else if (_measuresUnitBottom == 'K') {
              _topValue = (1.8 * _bottomValue) - 459.67;
            }
          } else if (_measuresUnitTop == 'K') {
            if (_measuresUnitBottom == '°C') {
              _topValue = _bottomValue + 273.15;
            } else if (_measuresUnitBottom == '°F') {
              _topValue = (_bottomValue + 459.67) / 1.8;
            } else if (_measuresUnitBottom == 'K') {
              _topValue = _bottomValue;
            }
          }
          _controllerTop.text = _convertNumberToLimit(_topValue, 7);

          _calculateTop = 0;
          _calculateBottom = 0;
        } else {
          _calculateTop = _measuresTypeMapDetail[_measuresTop][_standardBottom].toDouble();
          _calculateBottom = _measuresTypeMapDetail[_measuresBottom][_standardBottom].toDouble();

          _bottomValue = double.parse(value);
          _topValue = _calculateTop * _bottomValue;
          _controllerTop.text = _convertNumberToLimit(_topValue, 7);
        }
      });
    }
  }

  void _unitSet() {
    _measuresUnitTop = _measuresTypeMapDetail[_measuresTop][0];
    _standardTop = _measuresTypeMapDetail[_measuresTop][1] + 2;
    _measuresUnitBottom = _measuresTypeMapDetail[_measuresBottom][0];
    _standardBottom = _measuresTypeMapDetail[_measuresBottom][1] + 2;

    _box.put('_measuresTop', _measuresTop);
    _box.put('_measuresBottom', _measuresBottom);
  }

  void _convertUnit(String s, String value) {
    if (s == 'top') {
      _measuresTop = value;
    } else if (s == 'bottom') {
      _measuresBottom = value;
    }
    setState(() {
      _unitSet();

      _measuresTop;
      _measuresBottom;
      if (_measuresTypeValue == 'Temperature') {
        if (_measuresUnitTop == '°C') {
          if (_measuresUnitBottom == '°C') {
            _bottomValue = _topValue;
          } else if (_measuresUnitBottom == '°F') {
            _bottomValue = (_topValue * 9 / 5) + 32;
          } else if (_measuresUnitBottom == 'K') {
            _bottomValue = _topValue + 273.15;
          }
        } else if (_measuresUnitTop == '°F') {
          if (_measuresUnitBottom == '°C') {
            _bottomValue = (_topValue - 32) * 5 / 9;
          } else if (_measuresUnitBottom == '°F') {
            _bottomValue = _topValue;
          } else if (_measuresUnitBottom == 'K') {
            _bottomValue = (_topValue + 459.67) / 1.8;
          }
        } else if (_measuresUnitTop == 'K') {
          if (_measuresUnitBottom == '°C') {
            _bottomValue = _topValue - 273.15;
          } else if (_measuresUnitBottom == '°F') {
            _bottomValue = (1.8 * _topValue) - 459.67;
          } else if (_measuresUnitBottom == 'K') {
            _bottomValue = _topValue;
          }
        }
        _controllerBottom.text = _convertNumberToLimit(_bottomValue, 7);
      } else {
        _calculateTop = _measuresTypeMapDetail[_measuresTop][_standardTop].toDouble();
        _calculateBottom = _measuresTypeMapDetail[_measuresBottom][_standardTop].toDouble();
        _bottomValue = _calculateBottom * _topValue;
        _controllerBottom.text = _convertNumberToLimit(_bottomValue, 7);
      }
    });

    //_debugPrint();
  }

  String _convertNumberToLimit(double value, int lengthLimit) {
    var stringValue = value.toStringAsFixed(lengthLimit - 1);
    if (value > 1000000) {
      stringValue = value.toStringAsExponential(lengthLimit - 4);
    } else if (value < 0.000001) {
      stringValue = value.toStringAsExponential(lengthLimit - 4);
    } else if (value > 1) {
      stringValue = value.toStringAsPrecision(lengthLimit);
    }

    return stringValue.replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
  }

// void _debugPrint() {
//   print(' ${_measuresTypeMapDetail[_measuresTop]} _measuresTypeMapDetail[_measuresTop]');
//   print(' ${_measuresTypeMapDetail[_measuresBottom]} _measuresTypeMapDetail[_measuresBottom]');
//
//   print(' $_standardTop _standardTop $_calculateTop');
//   print(' $_standardBottom _standardBottom $_calculateBottom');
//
//   print(' $_topValue _calculateTop');
//   print(' $_bottomValue _calculateBottom');
// }
}
