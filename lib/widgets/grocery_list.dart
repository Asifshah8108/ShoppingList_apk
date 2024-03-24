import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isloading = true;
  String? _error;

  void loadItems() async {
    final url = Uri.https(
        'flutter-prep-e8c50-default-rtdb.firebaseio.com', 'Shopping-List.json');
    final response = await http.get(url);
    if (response.statusCode > 400) {
      setState(() {
        _error = "Failed to fetch data. Please try again later.";
      });
    }
    if (response.body == 'null') {
      setState(() {
        _isloading = false;
      });
      return;
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItems.add(GroceryItem(
        id: item.key,
        name: item.value['name'],
        quantity: item.value['quantity'],
        category: category,
      ));
    }
    setState(() {
      _groceryItems = loadedItems;
      _isloading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    loadItems();
    super.initState();
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https('flutter-prep-e8c50-default-rtdb.firebaseio.com',
        'Shopping-List/${item.id}.json');
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Item not deleted due to an error',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );

        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            _error!,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Grocery List"),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: _isloading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show CircularProgressIndicator while loading
          : _groceryItems.isEmpty
              ? const Center(child: Text("No Items added yet!"))
              : ListView.builder(
                  itemCount: _groceryItems.length,
                  itemBuilder: (ctx, index) => Dismissible(
                        key: ValueKey(_groceryItems[index].id),
                        onDismissed: (direction) {
                          _removeItem(_groceryItems[index]);
                        },
                        child: ListTile(
                          title: Text(_groceryItems[index].name),
                          leading: Container(
                            width: 24,
                            height: 24,
                            color: _groceryItems[index].category.color,
                          ),
                          trailing:
                              Text(_groceryItems[index].quantity.toString()),
                        ),
                      )),
    );
  }
}
