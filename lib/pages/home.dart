import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './calendar.dart';
import './editor.dart';
import '../model.dart';
import '../repository.dart';

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
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                MyEarningsCalendarPage(stocks: _portfolios.map((e) => e.stocks.toSet()).reduce((value, element) => value.union(element)).toList())));
                  },
                )
              ],
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
        hintText: '종목코드...',
        contentPadding: const EdgeInsets.all(8.0),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: _searchController.clear),
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (String searchText) {
        if (searchText.isNotEmpty) {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('종목코드'),
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
                  child: const Text('취소'),
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
                    title: const Text('새 목록'),
                    content: TextField(
                      controller: textFieldController,
                      decoration: const InputDecoration(hintText: '목록 이름'),
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        child: const Text('취소'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text('생성'),
                        onPressed: () async {
                          var portfolioName = textFieldController.text;
                          if (portfolioName.isNotEmpty) {
                            _portfolios.add(Portfolio(name: portfolioName, stocks: []));
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
          Tab(
            child: IconButton(
              icon: const Icon(Icons.edit_note),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => MyEditorPage()));
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
            return ListTile(
              title: Text(stock.ticker),
              subtitle: Text(stock.name),
              trailing: FutureBuilder(
                future: stock.price,
                builder: (BuildContext context, AsyncSnapshot<StockPrice> snapshot) {
                  if (snapshot.hasData) {
                    final price = snapshot.data!;
                    final priceFormat = NumberFormat.simpleCurrency(name: price.currency);
                    final priceChangesFormat = NumberFormat('+###.##%;-###.##%');
                    return Wrap(
                      spacing: 8,
                      children: [
                        Text(
                          priceFormat.format(price.value),
                          style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.normal),
                        ),
                        Text(
                          priceChangesFormat.format(price.changes),
                          style: TextStyle(
                            color: price.changes >= 0
                                ? (price.changes >= 0.1 ? Colors.redAccent[400] : Colors.red[700])
                                : (price.changes <= -0.1 ? Colors.indigoAccent[400] : Colors.indigo),
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
              onTap: () async {
                await stock.updatePrice();
                await _storage.save(_portfolios);
                setState(() {});
              },
            );
          },
        );
      }).toList(),
    );
  }
}
