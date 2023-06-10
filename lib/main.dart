import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:localstorage/localstorage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final LocalStorage _storage = LocalStorage('some_key');
  final TextEditingController _searchController = TextEditingController();
  late TabController? _tabController;

  List<StockList> _stockLists = [
    StockList(
      name: 'Demo',
      items: [Stock('AAPL', 'Apple Inc', '6408')],
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _storage.ready,
      builder: (BuildContext context, snapshot) {
        if (snapshot.data == true) {
          _tabController = TabController(length: _stockLists.length, vsync: this);
          return Scaffold(
            appBar: AppBar(
              toolbarHeight: kToolbarHeight + 16.0,
              title: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '종목코드...',
                  contentPadding: EdgeInsets.all(8.0),
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (String searchText) {
                  var response = http.get(Uri.parse('https://www.investing.com/search/?q=$searchText'));
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('종목코드'),
                      content: FutureBuilder(
                          future: response,
                          builder: (BuildContext context, snapshot) {
                            if (snapshot.hasData) {
                              var res = snapshot.data as Response;
                              if (res.statusCode == 200) {
                                String html = res.body;
                                RegExp re = RegExp(r'window.allResultsQuotesDataArray = ([^;]+)');
                                RegExpMatch? match = re.firstMatch(html);
                                var jsonString = match![1];
                                var searchResult = jsonDecode(jsonString!);
                                print(searchResult);
                                return Container(
                                  width: double.minPositive,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: searchResult.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      return ListTile(
                                        title: Text(searchResult[index]['symbol'] + ' (' + searchResult[index]['exchange'] + ')'),
                                        subtitle: Text(searchResult[index]['name']),
                                        onTap: () {
                                          print(index);
                                          setState(() {
                                            _stockLists[_tabController!.index].items.add(
                                                Stock(searchResult[index]['symbol'], searchResult[index]['name'], searchResult[index]['pairId'].toString()));
                                          });
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  ),
                                );
                              } else {
                                print('Request failed with status: ${res.statusCode}.');
                              }
                            }
                            return const Center(child: CircularProgressIndicator());
                          }),
                      actions: [
                        TextButton(
                          child: const Text('취소'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(kTextTabBarHeight),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: TabBar(
                          tabs: _stockLists.map((StockList stockList) => Tab(text: stockList.name)).toList(),
                          controller: _tabController,
                          isScrollable: true,
                          dividerColor: Colors.transparent,
                        ),
                      ),
                      Tab(
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            TextEditingController textFieldController = TextEditingController();
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: const Text('새 목록 이름'),
                                content: TextField(
                                  controller: textFieldController,
                                  decoration: const InputDecoration(hintText: '목록 이름'),
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('취소'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  TextButton(
                                    child: const Text('확인'),
                                    onPressed: () {
                                      if (textFieldController.text.isNotEmpty) {
                                        _stockLists.add(StockList(name: textFieldController.text, items: []));
                                        setState(() {
                                          _tabController = TabController(
                                            initialIndex: _tabController!.index,
                                            length: _stockLists.length,
                                            vsync: this,
                                          );
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('목록 이름을 입력하세요.')));
                                      }
                                      Navigator.pop(context);
                                    },
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    print('settings');
                  },
                ),
              ],
            ),
            body: TabBarView(
              controller: _tabController,
              children: _stockLists.map((StockList stockList) {
                return ListView.builder(
                  itemCount: stockList.items.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(stockList.items[index].ticker),
                      subtitle: Text(stockList.items[index].name),
                    );
                  },
                );
              }).toList(),
            ),
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}

class Stock {
  final String ticker;
  final String name;
  final String searchId;

  Stock(this.ticker, this.name, this.searchId);
}

class StockList {
  final String name;
  final List<Stock> items;

  StockList({required this.name, required this.items});
}
