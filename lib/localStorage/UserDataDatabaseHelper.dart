import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UserDataDatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'user_data.db');
    debugPrint("DB path >>> $path");
    return openDatabase(path, version: 2, onCreate: _onCreate);
  }

  Future<void> deleteOldDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'user_data.db');
    debugPrint("Deleting DB at: $path");
    await deleteDatabase(path);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bank_accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userID TEXT,
        bankName TEXT,
        cardNumber TEXT,
        cardHolder TEXT,
        expiryDate TEXT,
        cvv TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE shipping_addresses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        address TEXT,
        timestamp TEXT
      );
    ''');
  }

  // 插入银行卡数据
  Future<int> insertBankAccount(Map<String, dynamic> data) async {
    final db = await database;
    print('Inserting bank account: $data');
    return await db.insert('bank_accounts', data);
  }

  // 删除银行卡
  Future<int> deleteBankAccount(int id) async {
    final db = await database;
    return await db.delete('bank_accounts', where: 'id = ?', whereArgs: [id]);
  }

  // 获取所有银行卡
  Future<List<Map<String, dynamic>>> getBankAccounts() async {
    final db = await database;
    return await db.query('bank_accounts');
  }

  // 根据 userID 获取银行卡
  Future<List<Map<String, dynamic>>> getBankAccountsByUserID(String userID) async {
    final db = await database;
    return await db.query(
      'bank_accounts',
      where: 'userID = ?',
      whereArgs: [userID],
    );
  }

  // 插入新地址
  Future<int> insertAddress(String address) async {
    final db = await database;
    return await db.insert('shipping_addresses', {
      'address': address,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // 获取保存地址
  Future<List<String>> getSavedAddresses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('shipping_addresses');
    return List.generate(maps.length, (i) => maps[i]['address'] as String);
  }
}
