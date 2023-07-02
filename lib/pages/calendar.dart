import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../model.dart';
import '../repository.dart';

class MyCalendarPage extends StatefulWidget {
  List<Stock> stocks;

  MyCalendarPage({super.key, required this.stocks});

  @override
  _MyCalendarPageState createState() => _MyCalendarPageState();
}

class _MyCalendarPageState extends State<MyCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Stock> _selectedEvents = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('실적 발표 예정일'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: Future(() async {
          for (var stock in widget.stocks) {
            if (DateTime.timestamp().difference(stock.earningsDatesUpdatedAt).inDays > 7) {
              stock.earningsDates = await YahooFinance.fetchStockEarningsDate(stock.ticker);
            }
          }
          return widget.stocks;
        }),
        builder: (BuildContext context, AsyncSnapshot<List<Stock>> snapshot) {
          if (snapshot.hasData) {
            return Column(
              children: [
                TableCalendar(
                  locale: 'ko_KR',
                  firstDay: DateTime.utc(2023, 1, 1),
                  lastDay: DateTime.utc(2024, 12, 31),
                  focusedDay: _focusedDay,
                  headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
                  calendarStyle: CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withAlpha(128),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withAlpha(240),
                      shape: BoxShape.circle,
                    ),
                  ),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _selectedEvents = widget.stocks.where((stock) => isSameDay(stock.earningsDates, selectedDay)).toList();
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: (DateTime day) {
                    return widget.stocks.where((stock) => isSameDay(stock.earningsDates, day)).map((stock) => stock.ticker).toList();
                  },
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_selectedEvents[index].ticker),
                        subtitle: Text(_selectedEvents[index].name),
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
}
