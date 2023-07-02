import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';

class MyEditorPage extends StatefulWidget {
  MyEditorPage({super.key});

  @override
  _MyEditorPageState createState() => _MyEditorPageState();
}

class _MyEditorPageState extends State<MyEditorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('목록 수정'),
        centerTitle: true,
      ),
      body: DragAndDropLists(
        children: [
          DragAndDropList(
            header: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(),
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Header',
                    ),
                  ),
                ),
              ],
            ),
            children: [
              DragAndDropItem(
                child: ListTile(
                  title: Text('item'),
                  subtitle: Text('subtitle'),
                ),
              ),
              DragAndDropItem(
                child: ListTile(
                  title: Text('item'),
                  subtitle: Text('subtitle'),
                ),
              )
            ],
          )
        ],
        axis: Axis.horizontal,
        listWidth: 150,
        listDraggingWidth: 150,
        listDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: const BorderRadius.all(Radius.circular(7.0)),
        ),
        listPadding: const EdgeInsets.all(8.0),
        onItemReorder: (int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {},
        onListReorder: (int oldListIndex, int newListIndex) {},
      ),
    );
  }
}
