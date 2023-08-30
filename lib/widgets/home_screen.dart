import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https('flutter-prep-28bd7-default-rtdb.firebaseio.com',
          'shopping-list.json');
          final response = await http.get(url);

          if(response.statusCode >= 400) {
            setState(() {
              _error = 'Failed to fetch data. Please try again later';
            });
          }

          if(response.body == 'null') {
            setState(() {
              _isLoading = false;
            });
            return;
          }

          final Map<String, dynamic> listData = json.decode(response.body);
          final List<GroceryItem> loadedItems = [];
          for (final item in listData.entries) {
            final category = categories.entries.firstWhere((catItem) => catItem.value.title == item.value['category']).value;
            loadedItems.add(GroceryItem(
              id: item.key,
              name: item.value['name'],
              quantity: item.value['quantity'],
              category: category,
            ),
          );
          }
          setState(() {
            _groceryItems = loadedItems;
            _isLoading = false;
          });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
    MaterialPageRoute(builder: (ctx) => const NewItem()
    ),
    );

  if(newItem == null) {
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

    final url = Uri.https('flutter-prep-28bd7-default-rtdb.firebaseio.com',
          'shopping-list/${item.id}.json');

        final response = await http.delete(url);

        if(response.statusCode >= 400) {
          setState(() {
            _groceryItems.insert(index, item);
          });
        }
  }

  @override
  Widget build(BuildContext context) {
  Widget content = Center(child: Text('No items added yet!'));

  if(_isLoading) {
    content = Center(child: CircularProgressIndicator(),);
  }

  if(_groceryItems.isNotEmpty) {
    content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(
              _groceryItems[index].name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: Container(
              height: 24,
              width: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
  }

  if(_error != null) {
    content = Center(child: Text(_error!),);
  }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Groceries',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
              ),
        ),
        actions: [IconButton(onPressed: _addItem, icon: Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
