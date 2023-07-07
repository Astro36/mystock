import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:mystock/models/stock.dart';

class MyEarningsCalendarPage extends StatefulWidget {
  const MyEarningsCalendarPage({super.key});

  @override
  State createState() => _MyEarningsCalendarPageState();
}

class _MyEarningsCalendarPageState extends State<MyEarningsCalendarPage> {
  final Box<Stock> _stocksBox = Hive.box('stocks');

  DateTime _selectedDay = DateTime.utc(1970);
  List<Stock> _selectedDayEvents = [];
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('실적 발표 예정일'), centerTitle: true),
      body: FutureBuilder(
        future: Future(() async {
          var stockEarnings = LinkedHashMap<DateTime, List<Stock>>(equals: isSameDay, hashCode: _hashDate);
          for (Stock stock in _stocksBox.values.toList()) {
            stockEarnings.update(await stock.earningsDates, (list) => list..add(stock), ifAbsent: () => [stock]);
            _stocksBox.put(stock.ticker, stock);
          }
          return stockEarnings;
        }),
        builder: (BuildContext context, AsyncSnapshot<Map<DateTime, List<Stock>>> snapshot) {
          if (snapshot.hasData) {
            final stockEarnings = snapshot.requireData;
            final now = DateTime.now();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(now.year, 1, 1),
                  focusedDay: _focusedDay,
                  lastDay: DateTime.utc(now.year + 1, 12, 31),
                  locale: 'ko_KR',
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: Theme.of(context).textTheme.titleMedium!,
                  ),
                  calendarStyle: CalendarStyle(
                    markerDecoration: _buildCircleDecoration(Theme.of(context).colorScheme.primary),
                    todayDecoration: _buildCircleDecoration(Theme.of(context).colorScheme.secondary.withAlpha(128)),
                    selectedDecoration: _buildCircleDecoration(Theme.of(context).colorScheme.secondary.withAlpha(240)),
                  ),
                  eventLoader: (DateTime day) => stockEarnings[day] ?? [],
                  selectedDayPredicate: (DateTime day) => isSameDay(_selectedDay, day),
                  onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _selectedDayEvents = stockEarnings[selectedDay] ?? [];
                    });
                    _focusedDay = focusedDay;
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    _selectedDay.year > 1970 ? '${DateFormat.yMMMd('ko_KR').format(_selectedDay)} 발표' : '',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _selectedDayEvents.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_selectedDayEvents[index].ticker),
                        subtitle: Text(_selectedDayEvents[index].name),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline),
                  SizedBox(width: 8.0),
                  Text('정보를 불러오는 중에 문제가 발생했어요.'),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  BoxDecoration _buildCircleDecoration(Color color) {
    return BoxDecoration(color: color, shape: BoxShape.circle);
  }
}

int _hashDate(DateTime date) => date.year * 10000 + date.month * 100 + date.day;
