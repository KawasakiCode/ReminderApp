import 'package:flutter/material.dart';
import 'package:reminder_app/home_page.dart';
import 'package:reminder_app/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();  

  runApp(
    ChangeNotifierProvider(create: (_) => SettingsProvider(prefs),
    child: const ReminderApp()),
  );
}

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(  
        actionIconTheme: ActionIconThemeData(  
          backButtonIconBuilder: (BuildContext context) {
            return const Icon(Icons.arrow_back_ios_new);
          },
        )
      ),
      title: 'Reminder',
      home: HomePage(),
    );
  }
}