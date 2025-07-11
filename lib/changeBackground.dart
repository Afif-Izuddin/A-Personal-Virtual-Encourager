import 'package:flutter/material.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundScreen extends StatefulWidget {
  @override
  _BackgroundScreenState createState() => _BackgroundScreenState();
}

class _BackgroundScreenState extends State<BackgroundScreen> {
  String? _selectedBackground;
  Color _selectedFontColor = Colors.black;
  double _selectedFontSize = 20.0;

  @override
  void initState() {
    super.initState();
    _loadSelectedBackground();
    _loadFontPreferences();
  }

  Future<void> _loadSelectedBackground() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedBackground = prefs.getString('selectedBackground');
    });
  }

  Future<void> _saveSelectedBackground(String background) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedBackground', background);
    setState(() {
      _selectedBackground = background;
    });
  }

  Future<void> _loadFontPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedFontColor = Color(prefs.getInt('fontColor') ?? Colors.black.value);
      _selectedFontSize = prefs.getDouble('fontSize') ?? 20.0;
    });
  }

  Future<void> _saveFontColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    print("Saving font color: $color");
    await prefs.setInt('fontColor', color.value);
    setState(() {
      _selectedFontColor = color;
    });
  }

  Future<void> _saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
    setState(() {
      _selectedFontSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Background", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 9 / 16,
                ),
                itemCount: 3,
                itemBuilder: (context, index) {
                  List<String> imagePaths = [
                    "assets/background1.jpg",
                    "assets/background2.jpg",
                    "assets/background3.jpg",
                  ];
                  return _buildBackgroundOption(imagePaths[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text("Font Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Color:", style: TextStyle(fontSize: 16)),
                      DropdownButton<Color>(
                        value: _selectedFontColor,
                        items: [
                          Colors.black,
                          Colors.white,
                          Color(0xff2196f3),
                          Color(0xfff44336),
                          Color(0xff4caf50),
                        ].map((Color color) {
                          return DropdownMenuItem<Color>(
                            value: color,
                            child: Container(
                              width: 30,
                              height: 30,
                              color: color,
                            ),
                          );
                        }).toList(),
                        onChanged: (Color? newValue) {
                          if (newValue != null) {
                            _saveFontColor(newValue);
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Size:", style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Slider(
                          value: _selectedFontSize,
                          min: 12.0,
                          max: 30.0,
                          divisions: 18,
                          label: _selectedFontSize.round().toString(),
                          onChanged: (double newValue) {
                            _saveFontSize(newValue);
                          },
                        ),
                      ),
                      Text(_selectedFontSize.round().toString(), style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => QuoteScreen()));
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Done', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundOption(String imagePath) {
    return GestureDetector(
      onTap: () => _saveSelectedBackground(imagePath),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedBackground == imagePath ? Colors.blue : Colors.grey,
            width: 2,
          ),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}