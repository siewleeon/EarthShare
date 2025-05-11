import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UserDataDatabaseHelper {
  static Database? _database;

  // 初始化数据库
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 打开数据库
  _initDatabase() async {
    String path = join(await getDatabasesPath(), 'user_data.db');
    debugPrint("DB >>>>>>>>>>>>>" + path);
    return openDatabase(path, version: 2, onCreate: _onCreate);
  }

  // 创建表
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
  }

  // 插入银行卡数据
  Future<int> insertBankAccount(Map<String, dynamic> data) async {
    final db = await database;
    print('Inserting bank account: $data');
    return await db.insert('bank_accounts', data);
  }

  Future<int> deleteBankAccount(int id) async {
    final db = await database;
    return await db.delete('bank_accounts', where: 'id = ?', whereArgs: [id]);
  }

  // 获取所有银行卡数据
  Future<List<Map<String, dynamic>>> getBankAccounts() async {
    final db = await database;
    return await db.query('bank_accounts');
  }

  // 获取指定用户的银行卡数据
  Future<List<Map<String, dynamic>>> getBankAccountsByUserID(
      String userID) async {
    final db = await database;
    return await db.query(
      'bank_accounts',
      where: 'userID = ?', // Condition to match userID
      whereArgs: [userID], // Pass userID as argument
    );
  }


  // 插入新地址
  Future<int> insertAddress(String address) async {
    final db = await database;
    return await db.insert('shipping_addresses', {
      'address': address,
      'timestamp': DateTime.now().toString(),
    });
  }

  // 获取所有保存的地址
  Future<List<String>> getSavedAddresses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
        'shipping_addresses');
    return List.generate(maps.length, (i) => maps[i]['address'] as String);
  }
}
