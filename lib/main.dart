import 'package:flutter/material.dart';
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
          _tabController = TabController(length: _categories.length, vsync: this);
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
                  print(searchText);
                  print(_tabController!.index);
                  setState(() {
                    _categories[_tabController!.index].items.add(searchText);
                  });
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
                          tabs: _categories.map((Category category) => Tab(text: category.name)).toList(),
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
                                title: const Text('목록'),
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
                                        _categories.add(Category(name: textFieldController.text, items: []));
                                        setState(() {
                                          _tabController = TabController(
                                            initialIndex: _tabController!.index,
                                            length: _categories.length,
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
              children: _categories.map((Category category) {
                return ListView.builder(
                  itemCount: category.items.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(category.items[index]),
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

class Category {
  final String name;
  final List<String> items;

  Category({required this.name, required this.items});
}

List<Category> _categories = [
  Category(
    name: 'Test1',
    items: ['Apple'],
  ),
];

// [
//   Category(
//     name: 'Fruits',
//     items: ['Apple', 'Banana', 'Orange', 'Mango'],
//   ),
//   Category(
//     name: 'Vegetables',
//     items: ['Carrot', 'Broccoli', 'Tomato', 'Cabbage'],
//   ),
//   Category(
//     name: 'Animals',
//     items: ['Dog', 'Cat', 'Elephant', 'Lion'],
//   ),
// ];
