import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: SearchBar(
                elevation: WidgetStateProperty.all(0),
                hintText: "Search",
                hintStyle: WidgetStateProperty.all(TextStyle(fontSize: 21)),
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        _isMenuOpen =
                            !_isMenuOpen;
                      });
                    },
                  ),

                  if (_isMenuOpen)
                    Positioned(
                      top: 0,
                      right: 10,
                      child: Material(
                        elevation: 0,
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(30),
                        clipBehavior: Clip
                            .antiAlias,
                        child: SizedBox(
                          width: 160.0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isMenuOpen = false;
                                  });
                                  
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Search Settings',
                                    style: TextStyle(color: Colors.white),
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
          ],
        ),
      ),
      body: Column(
        children: [
          //search bar results show on top of the whole page covering it completely
          //Colors container (colors indicate vacations and different types of reminders (work, free time, etc))
          //calendar container(Main calendar button (shows all events saved in calendar), vacation calendar (show all country vacations based on location))
        ],
      ),
    );
  }
}
