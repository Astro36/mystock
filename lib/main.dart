import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './model.dart';
import './repository.dart';

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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
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
      builder: (BuildContext context, AsyncSnapshot<List<Portfolio>> snapshot) {
        if (snapshot.hasData) {
          _portfolios = snapshot.data!;
          _tabController = TabController(length: _portfolios.length, vsync: this);
          _tabController?.index = _focusedTabIndex;
          return Scaffold(
            appBar: AppBar(
              title: _buildSearchField(),
              bottom: PreferredSize(preferredSize: const Size.fromHeight(kTextTabBarHeight), child: _buildTabBar()),
              toolbarHeight: kToolbarHeight + 16.0,
            ),
            body: _buildTabBarView(),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Ticker...',
        contentPadding: const EdgeInsets.all(8.0),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(onPressed: _searchController.clear, icon: const Icon(Icons.clear)),
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (String searchText) {
        if (searchText.isNotEmpty) {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Ticker'),
              content: FutureBuilder(
                  future: YahooFinance.searchStock(searchText),
                  builder: (BuildContext context, AsyncSnapshot<List<Stock>> snapshot) {
                    if (snapshot.hasData) {
                      List<Stock> result = snapshot.data!;
                      return SizedBox(
                        width: 560, // default max size
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: result.length,
                          itemBuilder: (BuildContext context, int index) {
                            final portfolio = _portfolios[_tabController!.index];
                            final stock = result[index];
                            return ListTile(
                              title: Text(stock.ticker),
                              subtitle: Text(stock.name),
                              trailing: Text(stock.exchange),
                              onTap: () async {
                                if (!portfolio.stocks.map((e) => e.ticker).contains(stock.ticker)) {
                                  portfolio.stocks.add(stock);
                                  await _storage.save(_portfolios);
                                  setState(() {
                                    _focusedTabIndex = _tabController!.index;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 목록에 추가된 종목입니다.')));
                                }
                                // use_build_context_synchronously
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            );
                          },
                        ),
                      );
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
        }
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant, width: 0.5))),
      child: Row(
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: TabBar(
              tabs: _portfolios.map((e) => Tab(child: Text(e.name))).toList(),
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
                          var portfolioName = textFieldController.text;
                          if (portfolioName.isNotEmpty) {
                            _portfolios.add(Portfolio(name: portfolioName));
                            await _storage.save(_portfolios);
                            setState(() {
                              _focusedTabIndex = _tabController!.length;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('목록 이름을 입력하세요.')));
                          }
                          // use_build_context_synchronously
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
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

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: _portfolios.map((Portfolio portfolio) {
        return ListView.builder(
          itemCount: portfolio.stocks.length,
          itemBuilder: (BuildContext context, int index) {
            final stock = portfolio.stocks[index];
            return Dismissible(
              key: Key('${portfolio.name}-${stock.ticker}'),
              child: ListTile(
                title: Text(stock.ticker),
                subtitle: Text(stock.name),
                trailing: FutureBuilder(
                  future: Future(() async {
                    if (DateTime.timestamp().difference(stock.priceUpdatedAt).inSeconds > 60) {
                      stock.price = await YahooFinance.fetchStockPrice(stock.ticker);
                    }
                    return stock.price;
                  }),
                  builder: (BuildContext context, AsyncSnapshot<StockPrice> snapshot) {
                    if (snapshot.hasData) {
                      final priceFormat = NumberFormat.simpleCurrency(name: stock.price.currency);
                      final priceChangesFormat = NumberFormat('+###.##%;-###.##%;');
                      return Wrap(
                        spacing: 8,
                        children: [
                          Text(
                            priceFormat.format(stock.price.value),
                            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.normal, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            priceChangesFormat.format(stock.price.changes),
                            style: TextStyle(color: stock.price.changes > 0 ? Colors.red : Colors.indigo, fontSize: 16),
                          ),
                        ],
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                onTap: () async {
                  stock.price = await YahooFinance.fetchStockPrice(stock.ticker);
                  await _storage.save(_portfolios);
                  setState(() {});
                },
              ),
              onDismissed: (direction) async {
                portfolio.stocks.removeAt(index);
                await _storage.save(_portfolios);
                setState(() {
                  _focusedTabIndex = _tabController!.index;
                });
              },
            );
          },
        );
      }).toList(),
    );
  }
}
