import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('kudexBox');
  runApp(const KudexApp());
}

class KudexApp extends StatelessWidget {
  const KudexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kudex Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF1E222A),
        cardColor: const Color(0xFF282C34),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF7A7A),
          secondary: Color(0xFFE5C07B),
          surface: Color(0xFF181A1F),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFABB2BF), fontFamily: 'Segoe UI'),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      home: const ResponsiveShell(),
    );
  }
}

class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const DailyView(),
    const PlannerView(),
    const ListsView(),
    const NotesView(),
    const CuadernoView(),
  ];

  void _showLoginModal() {
    showDialog(
      context: context,
      builder: (context) {
        final emailCtrl = TextEditingController();
        final passCtrl = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF282C34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF3E4451))),
          title: const Text('Mi Cuenta Kudex', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Guarda tus notas y pendientes sincronizados en la nube.', style: TextStyle(color: Color(0xFF636D83), fontSize: 14)),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Correo electrónico...', hintStyle: const TextStyle(color: Color(0xFF636D83)), filled: true, fillColor: const Color(0xFF181A1F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Contraseña...', hintStyle: const TextStyle(color: Color(0xFF636D83)), filled: true, fillColor: const Color(0xFF181A1F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Registrarse', style: TextStyle(color: Color(0xFFABB2BF)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A7A), foregroundColor: const Color(0xFF1E222A)),
              onPressed: () {
                Hive.box('kudexBox').put('userEmail', emailCtrl.text);
                Navigator.pop(context);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesión iniciada correctamente.')));
              },
              child: const Text('Iniciar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 800;
        return Scaffold(
          body: Row(
            children: [
              if (!isMobile)
                Container(
                  width: 230,
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('Kudex Pro', style: TextStyle(color: Color(0xFFFF7A7A), fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      _buildSidebarItem(0, Icons.calendar_today, 'Daily'),
                      _buildSidebarItem(1, Icons.view_week, 'Planner'),
                      _buildSidebarItem(2, Icons.check_box, 'Lists'),
                      _buildSidebarItem(3, Icons.push_pin, 'Notes & Corcho'),
                      _buildSidebarItem(4, Icons.book, 'Cuaderno'),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: OutlinedButton.icon(
                          onPressed: _showLoginModal,
                          icon: const Icon(Icons.person, color: Colors.white),
                          label: const Text('Mi Cuenta', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF3E4451)), minimumSize: const Size(double.infinity, 45)),
                        ),
                      )
                    ],
                  ),
                ),
              Expanded(
                child: Container(
                  color: const Color(0xFF1E222A),
                  child: _views[_selectedIndex],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isMobile
              ? BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedItemColor: const Color(0xFFFF7A7A),
                  unselectedItemColor: const Color(0xFF636D83),
                  type: BottomNavigationBarType.fixed,
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Daily'),
                    BottomNavigationBarItem(icon: Icon(Icons.view_week), label: 'Planner'),
                    BottomNavigationBarItem(icon: Icon(Icons.check_box), label: 'Lists'),
                    BottomNavigationBarItem(icon: Icon(Icons.push_pin), label: 'Notes'),
                    BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Cuaderno'),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    bool isActive = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        color: isActive ? Theme.of(context).cardColor : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : const Color(0xFFABB2BF), size: 18),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: isActive ? Colors.white : const Color(0xFFABB2BF), fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class DailyView extends StatefulWidget {
  const DailyView({super.key});
  @override
  State<DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends State<DailyView> {
  String _timeString = "";
  late Timer _timer;
  final TextEditingController _quickNoteController = TextEditingController();
  final TextEditingController _icsController = TextEditingController();
  final _kudexBox = Hive.box('kudexBox');

  List<Map<String, dynamic>> _habits = [
    {'name': '💻 Estudiar R / Programación', 'done': false},
    {'name': '💧 Tomar 2L de agua', 'done': false},
    {'name': '🏋️ Hacer ejercicio', 'done': false},
  ];

  String _climaTemp = "--";
  String _climaEstado = "Cargando clima...";
  List<Map<String, dynamic>> _eventosHoy = [];
  bool _cargandoEventos = false;

  @override
  void initState() {
    super.initState();
    _timeString = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    _loadHabits();
    _fetchClima();
    final savedIcs = _kudexBox.get('ics_url');
    if (savedIcs != null && savedIcs.toString().isNotEmpty) {
      _icsController.text = savedIcs;
      _fetchCalendario(savedIcs);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _quickNoteController.dispose();
    _icsController.dispose();
    super.dispose();
  }

  void _getTime() {
    if (mounted) setState(() { _timeString = _formatDateTime(DateTime.now()); });
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }

  Future<void> _fetchClima() async {
    try {
      final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=20.5881&longitude=-100.3881&current_weather=true');
      final response = await http.get(url);
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _climaTemp = "${data['current_weather']['temperature'].round()}°C";
          _climaEstado = _interpretarCodigoClima(data['current_weather']['weathercode']);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _climaEstado = "Sin conexión");
    }
  }

  String _interpretarCodigoClima(int code) {
    if (code == 0) return "Despejado ☀️";
    if (code == 1 || code == 2 || code == 3) return "Parcialmente nublado ⛅";
    if (code >= 51 && code <= 67) return "Lluvia 🌧️";
    return "Nublado ☁️";
  }

  Future<void> _fetchCalendario(String urlString) async {
    if (urlString.isEmpty) return;
    if (mounted) setState(() => _cargandoEventos = true);
    _kudexBox.put('ics_url', urlString);
    try {
      final response = await http.get(Uri.parse(urlString));
      if (response.statusCode == 200) {
        final iCal = ICalendar.fromString(response.body);
        final hoy = DateTime.now();
        List<Map<String, dynamic>> eventosFiltrados = [];
        for (var event in iCal.data) {
          if (event['type'] == 'VEVENT' && event.containsKey('dtstart')) {
            final dtStart = event['dtstart'] as IcsDateTime;
            final eventDate = dtStart.toDateTime();
            if (eventDate != null && eventDate.year == hoy.year && eventDate.month == hoy.month && eventDate.day == hoy.day) {
              eventosFiltrados.add({
                'title': event['summary'] ?? 'Evento sin título',
                'time': "${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}",
                'hourInt': eventDate.hour
              });
            }
          }
        }
        eventosFiltrados.sort((a, b) => (a['hourInt'] as int).compareTo(b['hourInt'] as int));
        if (mounted) {
          setState(() {
            _eventosHoy = eventosFiltrados;
            _cargandoEventos = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargandoEventos = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al leer el calendario.')));
      }
    }
  }

  void _loadHabits() {
    final savedHabits = _kudexBox.get('habits');
    if (savedHabits != null && mounted) {
      setState(() {
        _habits = List<Map<String, dynamic>>.from((savedHabits as List).map((item) => Map<String, dynamic>.from(item as Map)));
      });
    }
  }

  void _saveHabits() => _kudexBox.put('habits', _habits);

  void _toggleHabit(int index, bool? value) {
    setState(() => _habits[index]['done'] = value ?? false);
    _saveHabits();
  }

  void _convertToPostIt() {
    final text = _quickNoteController.text.trim();
    if (text.isEmpty) return;
    List<Map<String, dynamic>> currentNotes = [];
    final savedNotes = _kudexBox.get('notes');
    if (savedNotes != null) {
      currentNotes = List<Map<String, dynamic>>.from((savedNotes as List).map((item) => Map<String, dynamic>.from(item as Map)));
    }
    currentNotes.add({'title': 'Nota Rápida', 'text': text, 'colorIndex': DateTime.now().millisecond % 4});
    _kudexBox.put('notes', currentNotes);
    setState(() => _quickNoteController.clear());
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📌 Nota enviada al tablero de corcho'), backgroundColor: Color(0xFFFF7A7A)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOY', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
          const Text('Hola, Santiago', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20, runSpacing: 20, crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF3E4451))),
                      child: Column(
                        children: [
                          const Text('● DÍA EN CURSO', style: TextStyle(color: Color(0xFF98C379), fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 10),
                          Text(_timeString, style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF3E4451))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$_climaTemp $_climaEstado', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const Text('Qro, MX', style: TextStyle(color: Color(0xFF636D83))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF3E4451))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LÍNEA DE TIEMPO', style: TextStyle(color: Color(0xFF61AFEF), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          if (_cargandoEventos)
                            const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A7A)))
                          else if (_eventosHoy.isEmpty)
                            const Text('No hay eventos sincronizados para hoy.', style: TextStyle(color: Color(0xFF636D83), fontSize: 13))
                          else
                            ..._eventosHoy.map((evt) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 45, child: Text(evt['time'], style: const TextStyle(color: Color(0xFF636D83), fontWeight: FontWeight.bold, fontSize: 12))),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: const Color(0xFF61AFEF).withOpacity(0.15), border: const Border(left: BorderSide(color: Color(0xFF61AFEF), width: 3)), borderRadius: BorderRadius.circular(4)),
                                      child: Text(evt['title'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    ),
                                  )
                                ],
                              ),
                            )),
                          const Divider(color: Color(0xFF3E4451), height: 30),
                          const Text('Sincronizar Calendario (.ics)', style: TextStyle(color: Colors.white, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _icsController,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  decoration: InputDecoration(hintText: 'URL de Google Calendar...', hintStyle: const TextStyle(color: Color(0xFF636D83)), filled: true, fillColor: const Color(0xFF181A1F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                                ),
                              ),
                              const SizedBox(width: 5),
                              IconButton(icon: const Icon(Icons.sync, color: Color(0xFFFF7A7A)), onPressed: () => _fetchCalendario(_icsController.text.trim()))
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                width: 400,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF3E4451))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('NOTAS RÁPIDAS', style: TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.bold)),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A7A), foregroundColor: const Color(0xFF1E222A), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), minimumSize: Size.zero),
                                onPressed: _convertToPostIt,
                                child: const Text('Convertir a Post-it', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _quickNoteController, maxLines: 4, style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(hintText: 'Anota algo rápido aquí...', hintStyle: const TextStyle(color: Color(0xFF636D83)), filled: true, fillColor: const Color(0xFF181A1F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF3E4451))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('HÁBITOS DIARIOS', style: TextStyle(color: Color(0xFF61AFEF), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          ...List.generate(_habits.length, (index) {
                            final habit = _habits[index];
                            final bool isDone = habit['done'] as bool;
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, activeColor: const Color(0xFFFF7A7A),
                              value: isDone, onChanged: (val) => _toggleHabit(index, val),
                              title: Text(habit['name'] as String, style: TextStyle(color: isDone ? const Color(0xFF636D83) : Colors.white, decoration: isDone ? TextDecoration.lineThrough : null, fontSize: 14)),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class PlannerView extends StatelessWidget {
  const PlannerView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Vista de Planner en desarrollo...', style: TextStyle(color: Colors.white, fontSize: 18)));
  }
}

class ListsView extends StatefulWidget {
  const ListsView({super.key});
  @override
  State<ListsView> createState() => _ListsViewState();
}

class _ListsViewState extends State<ListsView> {
  final TextEditingController _taskController = TextEditingController();
  String _priority = 'Importante';
  final _kudexBox = Hive.box('kudexBox');
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    final savedTasks = _kudexBox.get('tasks');
    if (savedTasks != null && mounted) {
      setState(() {
        tasks = List<Map<String, dynamic>>.from((savedTasks as List).map((item) => Map<String, dynamic>.from(item as Map)));
      });
    }
  }

  void _saveTasks() => _kudexBox.put('tasks', tasks);

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        tasks.insert(0, {'title': _taskController.text, 'priority': _priority, 'done': false});
        _taskController.clear();
      });
      _saveTasks();
    }
  }

  void _toggleTask(int index, bool? value) {
    setState(() => tasks[index]['done'] = value ?? false);
    _saveTasks();
  }

  Color _getPriorityColor(String priority) {
    if (priority == 'Urgente') return const Color(0xFFE06C75);
    if (priority == 'Importante') return const Color(0xFFE5C07B);
    return const Color(0xFF61AFEF);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gestor Avanzado de Pendientes', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _taskController, style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: 'Nuevo pendiente...', hintStyle: const TextStyle(color: Color(0xFF636D83)), filled: true, fillColor: Theme.of(context).cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<String>(
                  value: _priority, dropdownColor: Theme.of(context).cardColor, underline: const SizedBox(), style: const TextStyle(color: Colors.white),
                  items: ['Urgente', 'Importante', 'Rutina'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                  onChanged: (val) => setState(() => _priority = val!),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A7A), foregroundColor: const Color(0xFF1E222A), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                onPressed: _addTask, child: const Text('Agregar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final bool isDone = task['done'] as bool;
                final String title = task['title'] as String;
                final String priority = task['priority'] as String;

                return Card(
                  color: Theme.of(context).cardColor, margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Checkbox(value: isDone, activeColor: const Color(0xFFFF7A7A), onChanged: (bool? value) => _toggleTask(index, value)),
                    title: Text(title, style: TextStyle(color: isDone ? const Color(0xFF636D83) : Colors.white, decoration: isDone ? TextDecoration.lineThrough : null)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _getPriorityColor(priority).withOpacity(0.2), border: Border.all(color: _getPriorityColor(priority)), borderRadius: BorderRadius.circular(4)),
                      child: Text(priority, style: TextStyle(color: _getPriorityColor(priority), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class NotesView extends StatefulWidget {
  const NotesView({super.key});
  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  final _kudexBox = Hive.box('kudexBox');
  List<Map<String, dynamic>> notes = [];

  final List<Color> postItColors = [
    const Color(0xFFFF8A80), const Color(0xFF80D8FF), const Color(0xFFFFD180), const Color(0xFFCCFF90),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    final savedNotes = _kudexBox.get('notes');
    if (savedNotes != null && mounted) {
      setState(() {
        notes = List<Map<String, dynamic>>.from((savedNotes as List).map((item) => Map<String, dynamic>.from(item as Map)));
      });
    }
  }

  void _saveNotes() => _kudexBox.put('notes', notes);

  void _showNoteModal([int? index]) {
    final bool isEditing = index != null;
    final TextEditingController titleCtrl = TextEditingController(text: isEditing ? notes[index]['title'] : '');
    final TextEditingController textCtrl = TextEditingController(text: isEditing ? notes[index]['text'] : '');
    int selectedColor = isEditing ? notes[index]['colorIndex'] : 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF282C34),
              title: Text(isEditing ? 'Editar Post-it' : 'Nuevo Post-it', style: const TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), decoration: const InputDecoration(hintText: 'Título de la nota', hintStyle: TextStyle(color: Color(0xFF636D83)))),
                    const SizedBox(height: 15),
                    Container(
                      height: 200, decoration: BoxDecoration(color: postItColors[selectedColor], borderRadius: BorderRadius.circular(8)),
                      child: TextField(controller: textCtrl, maxLines: null, expands: true, style: const TextStyle(color: Colors.black87), decoration: const InputDecoration(hintText: 'Escribe tu idea...', hintStyle: TextStyle(color: Colors.black54), border: InputBorder.none, contentPadding: EdgeInsets.all(15))),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(postItColors.length, (i) {
                        return GestureDetector(
                          onTap: () => setStateDialog(() => selectedColor = i),
                          child: Container(width: 30, height: 30, decoration: BoxDecoration(color: postItColors[i], shape: BoxShape.circle, border: Border.all(color: selectedColor == i ? Colors.white : Colors.transparent, width: 2))),
                        );
                      }),
                    )
                  ],
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(onPressed: () { setState(() { notes.removeAt(index); _saveNotes(); }); Navigator.pop(context); }, child: const Text('Eliminar', style: TextStyle(color: Color(0xFFFF7A7A)))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A7A), foregroundColor: const Color(0xFF1E222A)),
                  onPressed: () {
                    setState(() {
                      final newNote = {'title': titleCtrl.text, 'text': textCtrl.text, 'colorIndex': selectedColor};
                      if (isEditing) notes[index] = newNote; else notes.add(newNote);
                      _saveNotes();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar 📌', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tablero de Ideas', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A7A), foregroundColor: const Color(0xFF1E222A)), onPressed: () => _showNoteModal(), icon: const Icon(Icons.add), label: const Text('Nueva Nota', style: TextStyle(fontWeight: FontWeight.bold)))
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF8D5524), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF522F12), width: 3), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)]),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, childAspectRatio: 1, crossAxisSpacing: 20, mainAxisSpacing: 20),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return GestureDetector(
                    onTap: () => _showNoteModal(index),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: postItColors[note['colorIndex']], borderRadius: BorderRadius.circular(4), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(2, 4))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note['title'], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 5),
                          Expanded(child: Text(note['text'], style: const TextStyle(color: Colors.black87, fontSize: 13), overflow: TextOverflow.fade)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CuadernoView extends StatefulWidget {
  const CuadernoView({super.key});
  @override
  State<CuadernoView> createState() => _CuadernoViewState();
}

class _CuadernoViewState extends State<CuadernoView> {
  final _kudexBox = Hive.box('kudexBox');
  final TextEditingController _textController = TextEditingController();
  final GlobalKey _pdfKey = GlobalKey();

  List<dynamic> materias = [];
  int materiaActiva = 0;
  int paginaActiva = 0;

  bool isTextMode = true;
  Color strokeColor = const Color(0xFFFF7A7A);
  double strokeWidth = 3.0;
  bool isEraser = false;

  List<DrawnLine> lines = [];
  DrawnLine? currentLine;
  String currentFondo = 'grid';

  @override
  void initState() {
    super.initState();
    _loadCuaderno();
    _textController.addListener(() {
      if (materias.isNotEmpty && materias[materiaActiva]['paginas'].isNotEmpty) {
        materias[materiaActiva]['paginas'][paginaActiva]['texto'] = _textController.text;
        _saveCuaderno();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _loadCuaderno() {
    final String? savedData = _kudexBox.get('cuaderno_data');
    if (savedData != null && mounted) {
      setState(() { materias = jsonDecode(savedData); });
    } else if (mounted) {
      setState(() { materias = [{'nombre': 'Estática', 'paginas': [{'nombre': 'Ejercicios 2D', 'texto': '', 'fondo': 'grid', 'trazos': []}]}]; });
    }
    _cargarPaginaEnPantalla();
  }

  void _saveCuaderno() {
    if (materias.isNotEmpty && materias[materiaActiva]['paginas'].isNotEmpty) {
      materias[materiaActiva]['paginas'][paginaActiva]['trazos'] = lines.map((l) => l.toJson()).toList();
    }
    _kudexBox.put('cuaderno_data', jsonEncode(materias));
  }

  void _cargarPaginaEnPantalla() {
    if (materias.isNotEmpty && materias[materiaActiva]['paginas'].isNotEmpty) {
      final pag = materias[materiaActiva]['paginas'][paginaActiva];
      _textController.text = pag['texto'] ?? '';
      currentFondo = pag['fondo'] ?? 'grid';
      if (pag['trazos'] != null) {
        lines = (pag['trazos'] as List).map((t) => DrawnLine.fromJson(t)).toList();
      } else {
        lines = [];
      }
    }
  }

  void _crearNueva(String tipo) {
    final TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282C34),
        title: Text('Nueva $tipo', style: const TextStyle(color: Colors.white)),
        content: TextField(controller: ctrl, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A7A), foregroundColor: const Color(0xFF1E222A)),
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(() {
                  if (tipo == 'Materia') {
                    materias.add({'nombre': ctrl.text, 'paginas': [{'nombre': 'Página 1', 'texto': '', 'fondo': 'grid', 'trazos': []}]});
                    materiaActiva = materias.length - 1; paginaActiva = 0;
                  } else {
                    materias[materiaActiva]['paginas'].add({'nombre': ctrl.text, 'texto': '', 'fondo': 'grid', 'trazos': []});
                    paginaActiva = materias[materiaActiva]['paginas'].length - 1;
                  }
                  _cargarPaginaEnPantalla();
                  _saveCuaderno();
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Crear', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _deshacerTrazo() {
    if (lines.isNotEmpty) setState(() { lines.removeLast(); _saveCuaderno(); });
  }

  Future<void> _exportarPDF() async {
    try {
      RenderRepaintBoundary boundary = _pdfKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      final pdf = pw.Document();
      final imageProvider = pw.MemoryImage(pngBytes);
      pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (pw.Context context) => pw.Center(child: pw.Image(imageProvider))));
      String pageName = materias[materiaActiva]['paginas'][paginaActiva]['nombre'];
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'Apunte_$pageName.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al exportar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
           (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed) &&
            event.logicalKey == LogicalKeyboardKey.keyZ) {
          _deshacerTrazo();
        }
      },
      child: Row(
        children: [
          if (!isMobile)
            Container(
              width: 160, color: const Color(0xFF181A1F),
              child: Column(
                children: [
                  Padding(padding: const EdgeInsets.all(15.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Materias', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), GestureDetector(onTap: () => _crearNueva('Materia'), child: const Icon(Icons.add, color: Color(0xFFFF7A7A), size: 20))])),
                  Expanded(child: ListView.builder(
                    itemCount: materias.length,
                    itemBuilder: (context, index) {
                      bool isActive = index == materiaActiva;
                      return ListTile(
                        title: Text(materias[index]['nombre'], style: TextStyle(color: isActive ? Colors.white : const Color(0xFFABB2BF), fontSize: 14)),
                        tileColor: isActive ? Theme.of(context).cardColor : Colors.transparent,
                        onTap: () { _saveCuaderno(); setState(() { materiaActiva = index; paginaActiva = 0; _cargarPaginaEnPantalla(); }); },
                      );
                    },
                  ))
                ],
              ),
            ),
          if (!isMobile)
            Container(
              width: 160, color: const Color(0xFF1E222A), decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFF3E4451)))),
              child: Column(
                children: [
                  Padding(padding: const EdgeInsets.all(15.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Páginas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), GestureDetector(onTap: () => _crearNueva('Página'), child: const Icon(Icons.add, color: Color(0xFFFF7A7A), size: 20))])),
                  Expanded(child: materias.isEmpty ? const SizedBox() : ListView.builder(
                    itemCount: materias[materiaActiva]['paginas'].length,
                    itemBuilder: (context, index) {
                      bool isActive = index == paginaActiva;
                      return ListTile(
                        title: Text(materias[materiaActiva]['paginas'][index]['nombre'], style: TextStyle(color: isActive ? Colors.white : const Color(0xFFABB2BF), fontSize: 14)),
                        tileColor: isActive ? Theme.of(context).cardColor : Colors.transparent,
                        onTap: () { _saveCuaderno(); setState(() { paginaActiva = index; _cargarPaginaEnPantalla(); }); },
                      );
                    },
                  ))
                ],
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).cardColor, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ToggleButtons(isSelected: [isTextMode, !isTextMode], onPressed: (index) => setState(() => isTextMode = index == 0), fillColor: const Color(0xFFFF7A7A).withOpacity(0.2), selectedColor: const Color(0xFFFF7A7A), color: Colors.white, borderColor: const Color(0xFF3E4451), selectedBorderColor: const Color(0xFFFF7A7A), constraints: const BoxConstraints(minHeight: 35, minWidth: 90), children: const [Text('Texto'), Text('Dibujo')]),
                        const SizedBox(width: 15), const Text('Tinta: ', style: TextStyle(color: Color(0xFF636D83), fontSize: 12)),
                        _colorBtn(Colors.white), _colorBtn(const Color(0xFFFF7A7A)), _colorBtn(const Color(0xFF61AFEF)), _colorBtn(const Color(0xFFE5C07B)), const SizedBox(width: 15),
                        OutlinedButton.icon(style: OutlinedButton.styleFrom(backgroundColor: isEraser && !isTextMode ? const Color(0xFF2C313A) : Colors.transparent, side: BorderSide(color: isEraser && !isTextMode ? const Color(0xFFFF7A7A) : const Color(0xFF3E4451))), onPressed: () => setState(() { isEraser = true; isTextMode = false; }), icon: Icon(Icons.cleaning_services, size: 16, color: isEraser && !isTextMode ? Colors.white : const Color(0xFFABB2BF)), label: Text('Borrador', style: TextStyle(color: isEraser && !isTextMode ? Colors.white : const Color(0xFFABB2BF)))),
                        const SizedBox(width: 15), IconButton(onPressed: _deshacerTrazo, icon: const Icon(Icons.undo, color: Color(0xFFABB2BF)), tooltip: 'Deshacer (Cmd+Z)'), const SizedBox(width: 15),
                        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF98C379), foregroundColor: const Color(0xFF1E222A)), onPressed: _exportarPDF, icon: const Icon(Icons.picture_as_pdf, size: 16), label: const Text('Exportar PDF', style: TextStyle(fontWeight: FontWeight.bold)))
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFF14161A), padding: const EdgeInsets.all(20),
                    child: Center(
                      child: RepaintBoundary(
                        key: _pdfKey,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 850), decoration: BoxDecoration(color: const Color(0xFF181A1F), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3E4451))),
                          child: Stack(
                            children: [
                              Positioned.fill(child: CustomPaint(painter: BackgroundPainter(currentFondo), child: Container())),
                              Positioned.fill(child: Padding(padding: const EdgeInsets.all(20.0), child: TextField(controller: _textController, maxLines: null, expands: true, enabled: isTextMode, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6), decoration: const InputDecoration(border: InputBorder.none, hintText: 'Escribe aquí...', hintStyle: TextStyle(color: Color(0xFF3E4451)))))),
                              Positioned.fill(
                                child: IgnorePointer(
                                  ignoring: isTextMode,
                                  child: GestureDetector(
                                    onPanStart: (details) => setState(() => currentLine = DrawnLine([details.localPosition], strokeColor, isEraser ? 20.0 : strokeWidth, isEraser: isEraser)),
                                    onPanUpdate: (details) => setState(() => currentLine?.path.add(details.localPosition)),
                                    onPanEnd: (details) { setState(() { lines.add(currentLine!); currentLine = null; }); _saveCuaderno(); },
                                    child: CustomPaint(painter: DrawingPainter(lines: lines, currentLine: currentLine), child: Container()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorBtn(Color color) {
    bool isSelected = strokeColor == color && !isEraser && !isTextMode;
    return GestureDetector(onTap: () => setState(() { strokeColor = color; isTextMode = false; isEraser = false; }), child: Container(margin: const EdgeInsets.only(right: 8), width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: isSelected ? const Color(0xFFFF7A7A) : Colors.transparent, width: 2))));
  }
}

class BackgroundPainter extends CustomPainter {
  final String pattern;
  BackgroundPainter(this.pattern);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 1.0;
    if (pattern == 'grid') {
      for (double i = 0; i < size.width; i += 24) {
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
      }
      for (double i = 0; i < size.height; i += 24) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
      }
    } else if (pattern == 'lines') {
      for (double i = 0; i < size.height; i += 28) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawnLine {
  final List<Offset> path;
  final Color color;
  final double width;
  final bool isEraser;
  DrawnLine(this.path, this.color, this.width, {this.isEraser = false});

  Map<String, dynamic> toJson() => {
    'path': path.map((e) => {'x': e.dx, 'y': e.dy}).toList(),
    'color': color.value,
    'width': width,
    'isEraser': isEraser,
  };

  factory DrawnLine.fromJson(Map<String, dynamic> json) {
    return DrawnLine(
      (json['path'] as List).map((e) => Offset(e['x'], e['y'])).toList(),
      Color(json['color']), json['width'], isEraser: json['isEraser'] ?? false,
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawnLine> lines;
  final DrawnLine? currentLine;
  DrawingPainter({required this.lines, this.currentLine});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    Paint paint = Paint()..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    for (var line in lines) {
      paint.color = line.color; paint.strokeWidth = line.width; paint.blendMode = line.isEraser ? BlendMode.clear : BlendMode.srcOver;
      for (int i = 0; i < line.path.length - 1; i++) {
        canvas.drawLine(line.path[i], line.path[i + 1], paint);
      }
    }
    if (currentLine != null) {
      paint.color = currentLine!.color; paint.strokeWidth = currentLine!.width; paint.blendMode = currentLine!.isEraser ? BlendMode.clear : BlendMode.srcOver;
      for (int i = 0; i < currentLine!.path.length - 1; i++) {
        canvas.drawLine(currentLine!.path[i], currentLine!.path[i + 1], paint);
      }
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
