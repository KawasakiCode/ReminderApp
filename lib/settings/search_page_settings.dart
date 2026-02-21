import 'package:flutter/material.dart';

class SearchSettingsPage extends StatefulWidget {
  const SearchSettingsPage({super.key});

  @override
  State<SearchSettingsPage> createState() => _SearchSettingsPageState();
}

class _SearchSettingsPageState extends State<SearchSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search Settings"),
        automaticallyImplyLeading: true,
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Material(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(
                30.0,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  30.0,
                ),
                splashColor: Colors.grey[500],
                onTap: () {
                  
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Show recent searches',
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: true,
                          onChanged: (bool newValue) {},
                          activeThumbColor: Colors.white,
                          inactiveThumbColor: Colors.white,
                          activeTrackColor: Colors.blueAccent,
                          inactiveTrackColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
