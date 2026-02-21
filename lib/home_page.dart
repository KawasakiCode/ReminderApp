import 'package:flutter/material.dart';
import 'package:reminder_app/settings/search_page_settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold (  
      appBar: AppBar(title: Text("Notes")),
      body: Column(  
        children: [
          IconButton(  
            onPressed: () {
              Navigator.push(  
                context,
                MaterialPageRoute(builder:(context) => SearchSettingsPage(),)
              );
            },
            icon: Icon(Icons.back_hand)
          ),
        ]
      )
    );
  }
}