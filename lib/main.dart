import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SQFliteExample());
}

class SQFliteExample extends StatefulWidget {
  const SQFliteExample({super.key});

  @override
  State<SQFliteExample> createState() => _SQFliteExampleState();
}

class _SQFliteExampleState extends State<SQFliteExample> {
  int? _selectedID;
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: TextField(controller: _controller),
        ),
        body: FutureBuilder<List<Grocery>>(
            future: DataBaseHelper.instance.getGroceries(),
            builder:
                (BuildContext context, AsyncSnapshot<List<Grocery>> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: Text('Loading...'));
              }
              return snapshot.data!.isEmpty
                  ? Center(child: Text('No Groceries in List.'))
                  : ListView(
                      children: snapshot.data!.map((grocery) {
                        return Center(
                          child: ListTile(
                            title: Text(grocery.name),
                          ),
                        );
                      }).toList(),
                    );
            }),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.save),
          onPressed: () async{
            await DataBaseHelper.instance.add(
              Grocery(name: _controller.text),
            );
            setState(() {
              _controller.clear();
            });
          },
        ),
      ),
    );
  }
}

class Grocery {
  final int? id;
  final String name;

  Grocery({this.id, required this.name});
  factory Grocery.fromMap(Map<String, dynamic> json) => new Grocery(
        id: json['id'],
        name: json['name'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class DataBaseHelper {
  DataBaseHelper._privateConsructor();
  static final DataBaseHelper instance = DataBaseHelper._privateConsructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'groceries.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE groceries(
      id INTEGER PRIMARY KEY,
      name TEXT
    )''');
  }

  Future<List<Grocery>> getGroceries() async {
    Database db = await instance.database;
    var groceries = await db.query('groceries', orderBy: 'name');
    List<Grocery> groceryList = groceries.isNotEmpty
        ? groceries.map((e) => Grocery.fromMap(e)).toList()
        : [];
    return groceryList;
  }

  Future<int> add(Grocery grocery) async {
    Database db = await instance.database;
    return await db.insert('groceries', grocery.toMap());
  }

  Future<int> remove(int id) async {
    Database db = await instance.database;
    return await db.delete('groceries', where: 'id = ?', whereArgs: [id]);
  }
}
