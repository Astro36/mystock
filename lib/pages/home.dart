import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

import 'package:mystock/models/stock.dart';
import 'package:mystock/models/repository.dart';
import 'package:mystock/pages/calendar.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final Box<StockList> _stockListsBox = Hive.box('stockLists');
  final Box<Stock> _stocksBox = Hive.box('stocks');

  final TextEditingController _searchController = TextEditingController();

  late TabController? _tabController;
  int _focusedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    if (_stockListsBox.values.isEmpty) {
      _stockListsBox.add(StockList(name: '관심', tickers: ['AAPL']));
      _stocksBox.put('AAPL', Stock(ticker: 'AAPL', name: 'Apple Inc.', exchange: 'NMS'));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _stockListsBox.listenable(),
      builder: (BuildContext context, Box<StockList> stockListBox, _) {
        _initTabController();
        return Scaffold(
          appBar: AppBar(
            title: _buildSearchField(),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MyEarningsCalendarPage())),
              )
            ],
            bottom: PreferredSize(preferredSize: const Size.fromHeight(kTextTabBarHeight), child: _buildTabBar()),
            toolbarHeight: kToolbarHeight + 16.0,
          ),
          body: _buildTabBarView(),
        );
      },
    );
  }

  void _initTabController() {
    _tabController = TabController(length: _stockListsBox.values.length, vsync: this);
    _tabController?.index = _focusedTabIndex;
    _tabController?.addListener(() {
      _focusedTabIndex = _tabController!.index;
    });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '종목 검색',
        isDense: true,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: _searchController.clear),
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (String searchText) {
        if (searchText.isNotEmpty) {
          _showSearchResultDialog(searchText);
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
              tabs: _stockListsBox.values.map((StockList stockList) => Tab(child: Text(stockList.name))).toList(),
              controller: _tabController,
              isScrollable: true,
              dividerColor: Colors.transparent,
            ),
          ),
          Tab(child: IconButton(icon: const Icon(Icons.add), onPressed: _showNewListDialog)),
          Tab(child: IconButton(icon: const Icon(Icons.edit_note), onPressed: _showEditListDialog)),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: _stockListsBox.values.map((StockList stockList) {
        return ListView.builder(
          itemCount: stockList.tickers.length,
          itemBuilder: (BuildContext context, int index) {
            final ticker = stockList.tickers[index];
            final Stock stock = _stocksBox.get(ticker)!;
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
                _stocksBox.put(stock.ticker, stock);
                setState(() {});
              },
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('종목 삭제'),
                    content: const Text('해당 종목을 목록에서 삭제할까요?'),
                    actions: [
                      TextButton(
                        child: const Text('취소'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text('삭제'),
                        onPressed: () {
                          stockList.tickers.remove(stock.ticker);
                          _stockListsBox.putAt(_focusedTabIndex, stockList);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      }).toList(),
    );
  }

  void _showSearchResultDialog(String searchText) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('종목 추가'),
        content: FutureBuilder(
            future: YahooFinance.searchStock(searchText),
            builder: (BuildContext context, AsyncSnapshot<List<Stock>> snapshot) {
              if (snapshot.hasData) {
                List<Stock> result = snapshot.requireData;
                if (result.isNotEmpty) {
                  return SizedBox(
                    width: 560, // default max width
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: result.length,
                      itemBuilder: (BuildContext context, int index) {
                        final selectedStock = result[index];
                        return ListTile(
                          title: Text(selectedStock.ticker),
                          subtitle: Text(selectedStock.name),
                          trailing: Text(selectedStock.exchange),
                          onTap: () async {
                            final stockList = _stockListsBox.getAt(_focusedTabIndex)!;
                            if (!stockList.tickers.contains(selectedStock.ticker)) {
                              await selectedStock.price;
                              _stockListsBox.put(_focusedTabIndex, stockList..tickers.add(selectedStock.ticker));
                              _stocksBox.put(selectedStock.ticker, selectedStock);
                              setState(() {
                                _searchController.clear();
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('목록에 이미 추가된 종목이에요.')));
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
                return const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('종목을 찾을 수 없어요.'),
                  subtitle: Text('종목 코드가 올바른지 확인해 주세요.'),
                );
              } else if (snapshot.hasError) {
                return const ListTile(
                  leading: Icon(Icons.error_outline),
                  title: Text('종목을 찾을 수 없어요.'),
                  subtitle: Text('종목 코드나 영어 이름으로 검색해 주세요.'),
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

  void _showNewListDialog() {
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
            onPressed: () {
              var newListName = textFieldController.text;
              if (newListName.isNotEmpty) {
                _stockListsBox.add(StockList(name: newListName, tickers: []));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('목록 이름을 입력하세요.')));
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEditListDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('목록 수정'),
        content: StatefulBuilder(
          builder: (_, StateSetter setStateInner) {
            return SizedBox(
              width: 560, // default max size
              child: ReorderableListView(
                buildDefaultDragHandles: false,
                children: [
                  for (int index = 0; index < _stockListsBox.values.length; index += 1)
                    ListTile(
                      key: Key(index.toString()),
                      title: Text(_stockListsBox.getAt(index)!.name),
                      tileColor: const Color(0xFFF6E2EA),
                      leading: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle)),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              TextEditingController textFieldController = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  title: const Text('목록 이름 변경'),
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
                                      child: const Text('확인'),
                                      onPressed: () async {
                                        var newListName = textFieldController.text;
                                        if (newListName.isNotEmpty) {
                                          _stockListsBox.putAt(index, _stockListsBox.getAt(index)!..name = newListName);
                                          setStateInner(() {});
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
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _stockListsBox.deleteAt(index);
                              setState(() {});
                              setStateInner(() {});
                            },
                          ),
                        ],
                      ),
                    )
                ],
                onReorder: (int oldIndex, int newIndex) {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final tempList = _stockListsBox.getAt(oldIndex)!;
                  _stockListsBox.putAt(oldIndex, _stockListsBox.getAt(newIndex)!);
                  _stockListsBox.putAt(newIndex, tempList);
                  setState(() {});
                  setStateInner(() {});
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text('확인'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
