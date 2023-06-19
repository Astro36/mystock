import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

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
  final Storage _storage = Storage();
  final TextEditingController _searchController = TextEditingController();
  late TabController? _tabController;
  int _selectedIndex = 0;

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
      future: _storage.load(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          List<Portfolio> portfolios = snapshot.data!;
          _tabController = TabController(length: portfolios.length, vsync: this);
          _tabController?.index = _selectedIndex;
          return Scaffold(
            appBar: AppBar(
              toolbarHeight: kToolbarHeight + 16.0,
              title: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Ticker...',
                  contentPadding: EdgeInsets.all(8.0),
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (String searchText) {
                  var response = http.get(Uri.parse('https://www.investing.com/search/?q=$searchText'));
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Ticker'),
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
                                return SizedBox(
                                  width: double.minPositive,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: searchResult.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      return ListTile(
                                        title: Text(searchResult[index]['symbol']),
                                        subtitle: Text(searchResult[index]['name']),
                                        trailing: Text(searchResult[index]['exchange']),
                                        onTap: () async {
                                          print('Add new stock');
                                          portfolios[_tabController!.index].stocks.add(Stock(
                                              ticker: searchResult[index]['symbol'],
                                              name: searchResult[index]['name'],
                                              searchId: searchResult[index]['pairId'].toString()));
                                          await _storage.save(portfolios);
                                          setState(() {
                                            _selectedIndex = _tabController!.index;
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
                          child: const Text('Cancel'),
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
                          tabs: portfolios.map((e) => Text(e.name)).toList(),
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
                                title: const Text('New List'),
                                content: TextField(
                                  controller: textFieldController,
                                  decoration: const InputDecoration(hintText: 'List Name'),
                                  autofocus: true,
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  TextButton(
                                    child: const Text('Ok'),
                                    onPressed: () async {
                                      if (textFieldController.text.isNotEmpty) {
                                        print('Create new list');
                                        portfolios.add(Portfolio(name: textFieldController.text, stocks: []));
                                        await _storage.save(portfolios);
                                        setState(() {
                                          _selectedIndex = _tabController!.length;
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
            ),
            body: TabBarView(
              controller: _tabController,
              children: portfolios.map((Portfolio portfolio) {
                return ListView.builder(
                  itemCount: portfolio.stocks.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(portfolio.stocks[index].ticker),
                      subtitle: Text(portfolio.stocks[index].name),
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

  Stock({
    required this.ticker,
    required this.name,
    required this.searchId,
  });

  Stock.fromJson(Map<String, dynamic> json)
      : ticker = json['ticker'] as String,
        name = json['name'] as String,
        searchId = json['search_id'] as String;

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'name': name,
        'search_id': searchId,
      };
}

class Portfolio {
  String name;
  List<Stock> stocks;

  Portfolio({
    required this.name,
    required this.stocks,
  });

  Portfolio.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        stocks = (json['stocks'] as List).map((e) => Stock.fromJson(e as Map<String, dynamic>)).toList();

  Map<String, dynamic> toJson() => {
        'name': name,
        'stocks': stocks.map((e) => e.toJson()).toList(),
      };
}

class Storage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/stocks.json');
  }

  Future<List<Portfolio>> load() async {
    try {
      final file = await _localFile;
      final content = await file.readAsString();
      final portfolios = jsonDecode(content) as List<dynamic>;
      return portfolios.map((e) => Portfolio.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<File> save(List<Portfolio> favorites) async {
    final file = await _localFile;
    return file.writeAsString(jsonEncode(favorites));
  }
}
