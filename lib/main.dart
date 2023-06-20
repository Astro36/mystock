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
  late List<Portfolio> _portfolios;

  final TextEditingController _searchController = TextEditingController();
  late TabController? _tabController;

  int _focusedTabIndex = 0;

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
          _portfolios = snapshot.data!;
          _tabController = TabController(length: _portfolios.length, vsync: this);
          _tabController?.index = _focusedTabIndex;
          return Scaffold(
            appBar: AppBar(
              toolbarHeight: kToolbarHeight + 16.0,
              title: _buildSearchForm(),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(kTextTabBarHeight),
                child: _buildTabBar(),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: _portfolios.map((Portfolio portfolio) {
                return ListView.builder(
                  itemCount: portfolio.stocks.length,
                  itemBuilder: (BuildContext context, int index) {
                    Stock stock = portfolio.stocks[index];
                    return ListTile(
                      title: Text(stock.ticker),
                      subtitle: Text(stock.name),
                      trailing: stock.price != null
                          ? Wrap(
                              spacing: 8,
                              children: [
                                Text(stock.price.toString(), style: const TextStyle(fontSize: 16, fontStyle: FontStyle.normal, fontWeight: FontWeight.w500)),
                                Text('${stock.priceChanges?.toStringAsFixed(2)}%', style: const TextStyle(color: Colors.red, fontSize: 16)),
                              ],
                            )
                          : FutureBuilder(
                              future: _fetchStockPrice(stock.ticker),
                              builder: (BuildContext context, AsyncSnapshot<StockUpdate> snapshot) {
                                if (snapshot.hasData) {
                                  StockUpdate update = snapshot.data!;
                                  if (update.price != null) {
                                    stock.price = update.price;
                                    stock.priceChanges = update.priceChanges;
                                    _storage.save(_portfolios);
                                    print('save');
                                  }
                                  return Wrap(
                                    spacing: 8,
                                    children: [
                                      Text(stock.price.toString(), style: const TextStyle(fontSize: 16)),
                                      Text('${stock.priceChanges?.toStringAsFixed(2)}%', style: const TextStyle(color: Colors.red, fontSize: 16)),
                                    ],
                                  );
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              },
                            ),
                      onTap: () {
                        setState(() {
                          stock.price = null;
                          stock.priceChanges = null;
                        });
                        _storage.save(_portfolios);
                      },
                    );
                  },
                );
              }).toList(),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildSearchForm() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Ticker...',
        contentPadding: EdgeInsets.all(8.0),
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      onSubmitted: (String searchText) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Ticker'),
            content: FutureBuilder(
                future: http.get(Uri.parse('https://query1.finance.yahoo.com/v1/finance/search?q=$searchText')),
                builder: (BuildContext context, AsyncSnapshot<Response> snapshot) {
                  if (snapshot.hasData) {
                    var res = snapshot.data as Response;
                    if (res.statusCode == 200) {
                      Map<String, dynamic> result = jsonDecode(res.body);
                      var matches = result['quotes'];
                      return SizedBox(
                        width: double.minPositive,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: matches.length,
                          itemBuilder: (BuildContext context, int index) {
                            return ListTile(
                              title: Text(matches[index]['symbol']),
                              subtitle: Text(matches[index]['longname']),
                              trailing: Text(matches[index]['exchange']),
                              onTap: () async {
                                print('Add new stock');
                                _portfolios[_tabController!.index].stocks.add(Stock(
                                      ticker: matches[index]['symbol'],
                                      name: matches[index]['longname'],
                                    ));
                                await _storage.save(_portfolios);
                                setState(() {
                                  _focusedTabIndex = _tabController!.index;
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
    );
  }

  Widget _buildTabBar() {
    return Container(
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
              tabs: _portfolios.map((e) => Text(e.name)).toList(),
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
                            _portfolios.add(Portfolio(name: textFieldController.text, stocks: []));
                            await _storage.save(_portfolios);
                            setState(() {
                              _focusedTabIndex = _tabController!.length;
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
    );
  }

  Future<StockUpdate> _fetchStockPrice(String ticker) async {
    var response = await http.get(Uri.parse('https://finance.yahoo.com/quote/$ticker'));
    if (response.statusCode == 200) {
      String html = response.body;
      RegExp pricePattern = RegExp(r'data-field="regularMarketPrice" data-trend="none" data-pricehint="2" value="([^"]+)"');
      RegExp priceChangesPattern =
          RegExp(r'data-field="regularMarketChangePercent" data-trend="txt" data-pricehint="2" data-template="\({fmt}\)" value="([^"]+)');
      RegExpMatch priceMatch = pricePattern.firstMatch(html)!;
      RegExpMatch priceChangesMatch = priceChangesPattern.firstMatch(html)!;
      return StockUpdate(
        price: double.parse(priceMatch[1]!),
        priceChanges: double.parse(priceChangesMatch[1]!) * 100,
      );
    }
    return StockUpdate();
  }
}

class Stock {
  final String ticker;
  final String name;
  double? price;
  double? priceChanges;

  Stock({
    required this.ticker,
    required this.name,
  });

  Stock.fromJson(Map<String, dynamic> json)
      : ticker = json['ticker'] as String,
        name = json['name'] as String,
        price = json['price'] as double?,
        priceChanges = json['priceChanges'] as double?;

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'name': name,
        'price': price,
        'priceChanges': priceChanges,
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

class StockUpdate {
  double? price;
  double? priceChanges;

  StockUpdate({
    this.price,
    this.priceChanges,
  });
}
