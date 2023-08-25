import "package:flutter_offline_first/database/database_service.dart";
import "package:flutter_offline_first/model/todo.dart";
import "package:sqflite/sqflite.dart";

class TodoDB {
  final tableName = 'todos';

  Future<void> createTable(Database database) async {
    await database.execute("""
      CREATE TABLE IF NOT EXISTS $tableName  (
        "id" INTEGER NOT NULL,
        "title" TEXT NOT NULL,
        "created_at" INTEGER NOT NULL DEFAULT (cast(strftime('%s', 'now', 'localtime') as int)),
        "updated_at" INTEGER,
        PRIMARY KEY("id" AUTOINCREMENT)
      );
    """);
  }

  Future<int> create({required String title}) async {
    final database = await DatabaseService().database;

    return await database.rawInsert(
      """
        INSERT INTO $tableName (title) VALUES (?)
      """,
      [title],
    );
  }

  Future<List<Todo>> fetchAll() async {
    final database = await DatabaseService().database;

    final todos = await database.rawQuery('''
      SELECT * FROM $tableName ORDER BY COALESCE(updated_at, created_at)
      ''');

    return todos.map((todo) => Todo.fromSqfliteDatabase(todo)).toList();
  }

  Future<Todo> fetchById(int id) async {
    final database = await DatabaseService().database;

    final todo = await database.rawQuery('''
      SELECT * FROM $tableName WHERE id = ?
      ''', [id]);

    return Todo.fromSqfliteDatabase(todo.first);
  }

  Future<int> update({required int id, required String title}) async {
    final database = await DatabaseService().database;

    return await database.update(
      tableName,
      {
        'title': title,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.rollback,
    );
  }

  Future<void> delete(int id) async {
    final database = await DatabaseService().database;

    await database.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
