import 'package:flutter/material.dart';
import 'package:reminder_app/home_page.dart';

void main() {
  runApp(const ReminderApp());
}

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminder',
      home: HomePage(),
    );
  }
}