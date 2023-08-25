import 'package:flutter/material.dart';
import 'package:flutter_offline_first/database/todo_db.dart';
import 'package:flutter_offline_first/model/todo.dart';
import 'package:flutter_offline_first/widget/create_todo_widget.dart';
import 'package:intl/intl.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  Future<List<Todo>>? futureTodos;
  final todoDB = TodoDB();

  @override
  void initState() {
    super.initState();

    fetchTodos();
  }

  void fetchTodos() {
    setState(() {
      futureTodos = todoDB.fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ToDo List')),
        body: FutureBuilder<List<Todo>>(
            future: futureTodos,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else {
                final todos = snapshot.data!;

                return todos.isEmpty
                    ? const Center(
                        child: Text('No todos to show',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 28)))
                    : ListView.separated(
                        itemBuilder: (context, index) {
                          final todo = todos[index];
                          final subtitle = DateFormat('dd/MM/yyyy', 'pt-BR')
                              .format(DateTime.parse(
                                  todo.updatedAt ?? todo.createdAt));

                          return ListTile(
                            title: Text(todo.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(subtitle),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await todoDB.delete(todo.id);
                                fetchTodos();
                              },
                            ),
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (context) => CreateTodoWidget(
                                        onSubmit: (title) async {
                                          await todoDB.update(
                                              id: todo.id, title: title);
                                          fetchTodos();
                                          if (!mounted) return;
                                          Navigator.of(context).pop();
                                        },
                                        todo: todo,
                                      ));
                            },
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemCount: todos.length);
              }
            }),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            showDialog(
                context: context,
                builder: (_) => CreateTodoWidget(
                      onSubmit: (title) async {
                        await todoDB.create(title: title);
                        if (!mounted) return;
                        fetchTodos();
                        Navigator.of(context).pop();
                      },
                    ));
          },
        ),
      );
}
