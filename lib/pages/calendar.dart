import 'dart:collection';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../model.dart';

class MyEarningsCalendarPage extends StatefulWidget {
  final List<Stock> stocks;

  const MyEarningsCalendarPage({super.key, required this.stocks});

  @override
  _MyEarningsCalendarPageState createState() => _MyEarningsCalendarPageState();
}

class _MyEarningsCalendarPageState extends State<MyEarningsCalendarPage> {
  DateTime _selectedDay = DateTime.utc(1970);
  List<Stock> _selectedDayEvents = [];
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('실적 발표 예정일'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: Future(() async {
          var stocks = LinkedHashMap<DateTime, List<Stock>>(
            equals: isSameDay,
            hashCode: (key) => key.year * 10000 + key.month * 100 + key.day,
          );
          for (Stock stock in widget.stocks) {
            stocks.update(await stock.earningsDates, (list) => list..add(stock), ifAbsent: () => [stock]);
          }
          return stocks;
        }),
        builder: (BuildContext context, AsyncSnapshot<Map<DateTime, List<Stock>>> snapshot) {
          if (snapshot.hasData) {
            final stockEarnings = snapshot.data!;
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
