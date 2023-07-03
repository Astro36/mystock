import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:mystock/pages/home.dart';

void main() async {
  await initializeDateFormatting();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyStock',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFBB2649),
        fontFamily: 'Pretendard',
      ),
      home: const MyHomePage(),
    );
  }
}
