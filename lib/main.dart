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
  final LocalStorage storage = new LocalStorage('some_key');

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Ticker...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (String searchText) {
                  print(searchText);
                  print(_tabController.index);

                  setState(() {
                    _categories[_tabController.index].items.add(searchText);
                  });
                },
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: _categories.map((Category category) {
              return Tab(text: category.name);
            }).toList(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                print("settings");

                setState(() {
                  _categories.add(Category(name: "Test", items: []));
                  _tabController =
                      TabController(length: _categories.length, vsync: this);
                });
              },
            ),
          ],
        ),
        body: FutureBuilder(
          future: storage.ready,
          builder: (BuildContext context, snapshot) {
            if (snapshot.data == true) {
              return TabBarView(
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
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        ));
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
