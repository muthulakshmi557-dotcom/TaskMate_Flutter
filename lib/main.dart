import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TaskMateApp());
}

class TaskMateApp extends StatelessWidget {
  const TaskMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskMate',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5FF),
        colorSchemeSeed: const Color(0xFF7043C2),
      ),
      home: const TodoHome(),
    );
  }
}

class TodoHome extends StatefulWidget {
  const TodoHome({super.key});

  @override
  State<TodoHome> createState() => _TodoHomeState();
}

class _TodoHomeState extends State<TodoHome> {
  final List<Map<String, dynamic>> tasks = [];
  final TextEditingController controller = TextEditingController();

  String selectedFilter = 'All';
  bool isLoading = true;

  static const purple = Color(0xFF6038B5);
  static const darkPurple = Color(0xFF382071);

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('taskmate_tasks');

    if (saved != null) {
      final List<dynamic> data = jsonDecode(saved);
      tasks.addAll(
        data.map((item) => Map<String, dynamic>.from(item)),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('taskmate_tasks', jsonEncode(tasks));
  }

  void addTask(BuildContext dialogContext) {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      tasks.insert(0, {
        'title': text,
        'completed': false,
      });
    });

    saveTasks();
    controller.clear();
    Navigator.pop(dialogContext);
  }

  void showAddTaskDialog() {
    controller.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create a task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(
            hintText: 'What do you need to do?',
            prefixIcon: Icon(Icons.edit_note_rounded),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => addTask(dialogContext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => addTask(dialogContext),
            child: const Text('Add task'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get filteredTasks {
    if (selectedFilter == 'Pending') {
      return tasks.where((t) => t['completed'] != true).toList();
    }
    if (selectedFilter == 'Completed') {
      return tasks.where((t) => t['completed'] == true).toList();
    }
    return tasks;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((t) => t['completed'] == true).length;
    final pending = tasks.length - completed;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5FF),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: purple, size: 30),
            SizedBox(width: 9),
            Text(
              'TaskMate',
              style: TextStyle(
                color: darkPurple,
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFE9DFFF),
              child: const Icon(Icons.person_outline, color: purple),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddTaskDialog,
        backgroundColor: purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(23),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [purple, darkPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: purple.withOpacity(0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOUR PERSONAL WORKSPACE',
                            style: TextStyle(
                              color: Colors.white70,
                              letterSpacing: 1.2,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Make today count.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$pending tasks left to complete',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: statCard(
                                  'Total',
                                  tasks.length,
                                  Icons.list_alt_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: statCard(
                                  'Done',
                                  completed,
                                  Icons.task_alt_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: statCard(
                                  'Pending',
                                  pending,
                                  Icons.hourglass_bottom_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: tasks.isEmpty
                                  ? 0
                                  : completed / tasks.length,
                              minHeight: 7,
                              backgroundColor: Colors.white24,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                Color(0xFFD7FFB8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            tasks.isEmpty
                                ? 'Start with your first task'
                                : '${(completed / tasks.length * 100).round()}% completed',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'My Tasks',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: darkPurple,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Wrap(
                      spacing: 9,
                      children: ['All', 'Pending', 'Completed'].map((filter) {
                        final selected = selectedFilter == filter;
                        return ChoiceChip(
                          label: Text(filter),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: purple,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : darkPurple,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: selected
                                ? purple
                                : const Color(0xFFE5DDF5),
                          ),
                          onSelected: (_) {
                            setState(() => selectedFilter = filter);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredTasks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    selectedFilter == 'Completed'
                                        ? Icons.emoji_events_outlined
                                        : Icons.checklist_rounded,
                                    size: 66,
                                    color: const Color(0xFFB8A4DF),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    tasks.isEmpty
                                        ? 'Nothing planned yet'
                                        : 'No $selectedFilter tasks',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Your tasks will appear here.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final task = filteredTasks[index];
                                final isDone = task['completed'] == true;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 11),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFEDE7F8),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    leading: Checkbox(
                                      value: isDone,
                                      activeColor: purple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          task['completed'] = value ?? false;
                                        });
                                        saveTasks();
                                      },
                                    ),
                                    title: Text(
                                      task['title'] as String,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDone
                                            ? Colors.grey
                                            : darkPurple,
                                        decoration: isDone
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Delete task',
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          tasks.remove(task);
                                        });
                                        saveTasks();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget statCard(String title, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 21),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 23,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}