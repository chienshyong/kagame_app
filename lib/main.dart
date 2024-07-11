import 'package:flutter/material.dart';
import 'add/add_main.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //root of your application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<AddMainState> _addMainKey = GlobalKey<AddMainState>(); //Key allows you to call methods in the child

  int _index = 0;
  void _onItemTapped(int index) {
    setState(() {
      _index = index;
      if(index == 3){
        _addMainKey.currentState?.reset(); //Return back to Camera page
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      Placeholder(),
      Placeholder(),
      AddMain(key: _addMainKey),
      Placeholder(),
      Placeholder(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kagame Fluttershy'),
      ),
      body: Center(
        child: IndexedStack(
          index: _index,
          children: screens,
        )
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chrome_reader_mode_outlined),
            label: 'Wardrobe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.palette),
            label: 'Recommend',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _index,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.blueGrey,
        onTap: _onItemTapped,
      ),
    );
  }
}
