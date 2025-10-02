import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mensajes Emergentes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TodoHomePage(),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  _TodoHomePageState createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final List<String> _tasks = [];
  final List<bool> _completed = [];
  int? _editingIndex;

  // Mostrar SnackBar
  void _showSnackBar(String message,
      {String? actionLabel, VoidCallback? action}) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontStyle: FontStyle.italic),
      ),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.orange,
              onPressed: action!,
            )
          : null,
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.blueGrey,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Mostrar AlertDialog al eliminar
  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Eliminar Tarea'),
            ],
          ),
          content:
              Text('¿Estás seguro de eliminar la tarea "${_tasks[index]}"?'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Eliminar'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                setState(() {
                  String removedTask = _tasks.removeAt(index);
                  bool removedCompleted = _completed.removeAt(index);
                  _showSnackBar('Tarea "$removedTask" eliminada',
                      actionLabel: 'Deshacer', action: () {
                    setState(() {
                      _tasks.insert(index, removedTask);
                      _completed.insert(index, removedCompleted);
                    });
                  });
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Mostrar Toast
  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
      timeInSecForIosWeb: 1,
    );
  }

  void _addTask() {
    final taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Tarea'),
        content: TextField(
          controller: taskController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre de la tarea'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (taskController.text.isNotEmpty) {
                setState(() {
                  _tasks.add(taskController.text);
                  _completed.add(false);
                  _showSnackBar('Tarea "${taskController.text}" agregada');
                });
                Navigator.pop(context);
              } else {
                _showToast('Por favor, ingresa un nombre de tarea');
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _startEditing(int index) {
    setState(() {
      _editingIndex = index;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingIndex = null;
    });
  }

  void _saveTask(int index, String newTask) {
    if (newTask.isNotEmpty) {
      setState(() {
        _tasks[index] = newTask;
        _editingIndex = null;
      });
      _showSnackBar('Tarea actualizada correctamente');
    } else {
      _showToast('El nombre de la tarea no puede estar vacío');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tareas (${_tasks.length})'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Agregar Tarea'),
                ),
              ),
              Expanded(
                child: _tasks.isEmpty
                    ? const Center(child: Text('No hay tareas, ¡agrega una!'))
                    : ListView.builder(
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Checkbox(
                              value: _completed[index],
                              onChanged: (bool? value) {
                                setState(() {
                                  _completed[index] = value!;
                                });
                              },
                            ),
                            title: Text(
                              _tasks[index],
                              style: TextStyle(
                                decoration: _completed[index]
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _startEditing(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showDeleteDialog(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_editingIndex != null)
            DraggableEditDialog(
              initialTask: _tasks[_editingIndex!],
              onSave: (newTask) {
                _saveTask(_editingIndex!, newTask);
              },
              onCancel: _cancelEditing,
            ),
        ],
      ),
    );
  }
}

class DraggableEditDialog extends StatefulWidget {
  final String initialTask;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  const DraggableEditDialog({
    super.key,
    required this.initialTask,
    required this.onSave,
    required this.onCancel,
  });

  @override
  _DraggableEditDialogState createState() => _DraggableEditDialogState();
}

class _DraggableEditDialogState extends State<DraggableEditDialog> {
  late TextEditingController _controller;
  Offset position = const Offset(50, 50);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTask);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
        feedback: Material(
          elevation: 4.0,
          child: _buildDialog(),
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            position = details.offset;
          });
        },
        child: _buildDialog(),
      ),
    );
  }

  Widget _buildDialog() {
    return Card(
      elevation: 4,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16.0),
        color: const Color.fromARGB(255, 101, 219, 105),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Editar Tarea', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre de la tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => widget.onSave(_controller.text),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}