import 'package:flutter/material.dart';

class SearchSettingsPage extends StatefulWidget {
  const SearchSettingsPage({super.key});

  @override
  State<SearchSettingsPage> createState() => _SearchSettingsPageState();
}

class _SearchSettingsPageState extends State<SearchSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold (  
      appBar: AppBar(title: Text("Search Settings")), //back button, search settings title
      body: Column(  
        children: [
          //one setting (Show recent settings) one toggle switch
        ]
      )
    );
  }
}