import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold (  
      appBar: AppBar(title: Text("Search")), //back icon, search bar, 3 dots button leading to search settings
      body: Column(  
        children: [
          //search bar results show on top of the whole page covering it completely
          //Colors container (colors indicate vacations and different types of reminders (work, free time, etc))
          //calendar container(Main calendar button (shows all events saved in calendar), vacation calendar (show all country vacations based on location))
        ]
      )
    );
  }
}