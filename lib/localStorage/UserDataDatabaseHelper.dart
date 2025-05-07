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
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // 创建表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bank_accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bankName TEXT,
        cardNumber TEXT,
        cardHolder TEXT,
        expiryDate TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE contact_us(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        message TEXT,
        timestamp TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE feedbacks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rating INTEGER,
        comment TEXT,
        timestamp TEXT
      );
    ''');
  }

  // 插入银行卡数据
  Future<int> insertBankAccount(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('bank_accounts', data);
  }

  // 获取所有银行卡数据
  Future<List<Map<String, dynamic>>> getBankAccounts() async {
    final db = await database;
    return await db.query('bank_accounts');
  }

  // 插入 Contact Us 数据
  Future<int> insertContactUs(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('contact_us', data);
  }

  // 获取所有 Contact Us 数据
  Future<List<Map<String, dynamic>>> getContactUsMessages() async {
    final db = await database;
    return await db.query('contact_us');
  }

  // 插入反馈数据
  Future<int> insertFeedback(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('feedbacks', data);
  }

  // 获取所有反馈数据
  Future<List<Map<String, dynamic>>> getFeedbacks() async {
    final db = await database;
    return await db.query('feedbacks');
  }


}
