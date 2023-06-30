import 'package:flutter/material.dart';
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
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          Text(stock.price.toString(), style: const TextStyle(fontSize: 16, fontStyle: FontStyle.normal, fontWeight: FontWeight.w500)),
                          Text('${stock.priceChanges.toStringAsFixed(2)}%', style: const TextStyle(color: Colors.red, fontSize: 16)),
                        ],
                      ),
                      onTap: () async {
                        var result = await YahooFinance.fetchStockPrice(stock.ticker);
                        stock.price = result.price;
                        stock.priceChanges = result.priceChanges;
                        await _storage.save(_portfolios);
                        setState(() {});
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
                        width: 560.0,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: result.length,
                          itemBuilder: (BuildContext context, int index) {
                            return ListTile(
                              title: Text(result[index].ticker),
                              subtitle: Text(result[index].name),
                              trailing: Text(result[index].exchange),
                              onTap: () async {
                                _portfolios[_tabController!.index].stocks.add(result[index]);
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
}
