import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kib_crud_app/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  // await Hive.deleteBoxFromDisk('shopping_box');
  await Hive.openBox('shopping_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Shopping Box',
      theme: ThemeData(
        primarySwatch: primaryColor,
      ),
      home: const HomePage(),
    );
  }
}

// Home Page
class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _items = [];

  final _shoppingBox = Hive.box('shopping_box');

  @override
  void initState() {
    super.initState();
    _refreshItems(); // Load data when app starts
  }

  // Get all items from the database
  void _refreshItems() {
    final data = _shoppingBox.keys.map((key) {
      final value = _shoppingBox.get(key);
      return {"key": key, "name": value["name"], "quantity": value['quantity']};
    }).toList();

    setState(() {
      _items = data.reversed.toList();
    });
  }

  // Create new item
  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _shoppingBox.add(newItem);
    _refreshItems(); // update the UI
  }

  // Retrieve a single item from the database by using its key
  // Our app won't use this function but I put it here for your reference
  Map<String, dynamic> _readItem(int key) {
    final item = _shoppingBox.get(key);
    return item;
  }

  // Update a single item
  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async {
    await _shoppingBox.put(itemKey, item);
    _refreshItems(); // Update the UI
  }

  // Delete a single item
  Future<void> _deleteItem(int itemKey) async {
    await _shoppingBox.delete(itemKey);
    _refreshItems(); // update the UI

    // Display a snackbar
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(snackBarTextMessage)));
  }

  // TextFields' controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(BuildContext ctx, int itemKey) async {
    // itemKey == null -> create new item
    // itemKey != null -> update an existing item

    if (itemKey != null) {
      final existingItem =
          _items.firstWhere((element) => element['key'] == itemKey);
      _nameController.text = existingItem['name'];
      _quantityController.text = existingItem['quantity'];
    }

    displayBottomSheet(ctx, itemKey);
  }

  void displayBottomSheet(BuildContext ctx, int itemKey) {
    showModalBottomSheet(
        context: ctx,
        elevation: space5,
        shape: bottomSheetBorderRadius(),
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  top: space15,
                  left: space15,
                  right: space15),
              child: displayBottomSheetContent(itemKey),
            )).whenComplete(() {
      setState(() {
        _nameController.text = "";
        _quantityController.text = "";
      });
    });
  }

  RoundedRectangleBorder bottomSheetBorderRadius() {
    return const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(space15),
          topRight: Radius.circular(space15)),
    );
  }

  Column displayBottomSheetContent(int itemKey) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        drawNameText(),
        spacer20(),
        drawQuantityText(),
        spacer20(),
        drawElevationButton(itemKey),
        spacer20(),
      ],
    );
  }

  SizedBox spacer20() {
    return const SizedBox(
      height: space20,
    );
  }

  TextField drawNameText() {
    return TextField(
      controller: _nameController,
      decoration: const InputDecoration(hintText: hintNameText),
    );
  }

  TextField drawQuantityText() {
    return TextField(
      controller: _quantityController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(hintText: hintQuantityText),
    );
  }

  ElevatedButton drawElevationButton(int itemKey) {
    return ElevatedButton(
      onPressed: () async {
        // Save new item
        onBottomSheetButtonAction(itemKey); // Close the bottom sheet
      },
      child: Text(itemKey == null ? createNewText : textUpdate),
    );
  }

  void onBottomSheetButtonAction(int itemKey) {
    // Save new item
    if (itemKey == null) {
      _createItem(
          {"name": _nameController.text, "quantity": _quantityController.text});
    }

    // update an existing item
    if (itemKey != null) {
      _updateItem(itemKey, {
        'name': _nameController.text.trim(),
        'quantity': _quantityController.text.trim()
      });
    }

    // Clear the text fields
    _nameController.text = '';
    _quantityController.text = '';

    Navigator.of(context).pop(); // Close the bottom sheet
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
      ),
      body: _items.isEmpty ? displayEmptyView() : itemsList(context),
      // Add new item button
      floatingActionButton: displayFloatingActionButton(context),
    );
  }

  Center displayEmptyView() {
    return Center(
      child: Column(
        children: const [
          Text(
            emptyViewTitle,
            style: TextStyle(fontSize: 30),
          ),
          Text(
            emptyViewSubTitle,
            style: TextStyle(fontSize: 30),
          ),
        ],
      ),
    );
  }

  FloatingActionButton displayFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showForm(context, null),
      child: const Icon(Icons.add),
    );
  }

  ListView itemsList(BuildContext context) => ListView.builder(
      // the list of items
      itemCount: _items.length,
      itemBuilder: (_, index) {
        final currentItem = _items[index];
        return displayListItem(currentItem, context);
      });

  Card displayListItem(Map<String, dynamic> currentItem, BuildContext context) {
    return Card(
      color: secondaryColor,
      margin: const EdgeInsets.all(space10),
      elevation: 0,
      child: drawListTile(currentItem, context),
    );
  }

  ListTile drawListTile(
      Map<String, dynamic> currentItem, BuildContext context) {
    return ListTile(
        title: Text(currentItem['name']),
        subtitle: Text(currentItem['quantity'].toString()),
        trailing: drawTrailingWidget(currentItem, context));
  }

  Row drawTrailingWidget(
      Map<String, dynamic> currentItem, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edit button
        generalIcon(currentItem, () => _showForm(context, currentItem['key']),
            Icons.edit),

        // Delete button
        generalIcon(
            currentItem, () => _deleteItem(currentItem['key']), Icons.delete),
      ],
    );
  }

  IconButton generalIcon(
      Map<String, dynamic> currentItem, Function onActionPress, IconData icon) {
    return IconButton(
      icon: Icon(
        icon,
        color: iconColor,
      ),
      onPressed: onActionPress,
    );
  }
}
