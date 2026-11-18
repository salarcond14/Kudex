import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

// ==========================================
// 1. TEMA PRINCIPAL Y CONFIGURACIÓN
// ==========================================
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
          bodyMedium: TextStyle(color: Color(0xFFABB2BF)),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      home: const ResponsiveShell(),
    );
  }
}

// ==========================================
// 2. SHELL RESPONSIVO (BARRA DESLIZABLE Y SAFEAREA)
// ==========================================
class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int _selectedIndex = 0;

  final List<Map<String, Object>> _navItems = [
    {'icon': Icons.today, 'label': 'Daily'},
    {'icon': Icons.calendar_month, 'label': 'Calendario'},
    {'icon': Icons.check_box, 'label': 'Lists'},
    {'icon': Icons.push_pin, 'label': 'Notes'},
    {'icon': Icons.book, 'label': 'Cuaderno'},
    {'icon': Icons.view_week, 'label': 'Planner'},
  ];

  Widget _getCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return const DailyView();
      case 1:
        return const CalendarView();
      case 2:
        return const ListsView();
      case 3:
        return const NotesView();
      case 4:
        return const CuadernoView();
      case 5:
      default:
        return const PlannerView();
    }
  }

  void _showLoginModal() {
    showDialog(
      context: context,
      builder: (context) {
        final emailCtrl = TextEditingController();
        final passCtrl = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF282C34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF3E4451)),
          ),
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
                decoration: InputDecoration(
                  hintText: 'Correo electrónico...',
                  hintStyle: const TextStyle(color: Color(0xFF636D83)),
                  filled: true,
                  fillColor: const Color(0xFF181A1F),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Contraseña...',
                  hintStyle: const TextStyle(color: Color(0xFF636D83)),
                  filled: true,
                  fillColor: const Color(0xFF181A1F),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Registrarse', style: TextStyle(color: Color(0xFFABB2BF))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A7A),
                foregroundColor: const Color(0xFF1E222A),
              ),
              onPressed: () {
                Hive.box('kudexBox').put('userEmail', emailCtrl.text);
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sesión iniciada correctamente.')),
                  );
                }
              },
              child: const Text('Iniciar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 800;
        return Scaffold(
          backgroundColor: const Color(0xFF1E222A),
          body: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (!isMobile)
                  Container(
                    width: 230,
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/logo.png',
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome, color: Color(0xFFFF7A7A), size: 28),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text('Kudex Pro', style: TextStyle(color: Color(0xFFFF7A7A), fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        ...List.generate(_navItems.length, (i) {
                          return _buildSidebarItem(i, _navItems[i]['icon'] as IconData, _navItems[i]['label'] as String);
                        }),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: OutlinedButton.icon(
                            onPressed: _showLoginModal,
                            icon: const Icon(Icons.person, color: Colors.white),
                            label: const Text('Mi Cuenta', style: TextStyle(color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF3E4451)),
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Container(
                    color: const Color(0xFF1E222A),
                    child: _getCurrentView(),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isMobile
              ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: const Border(top: BorderSide(color: Color(0xFF2C313A), width: 1)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: List.generate(_navItems.length, (index) {
                          bool isSelected = _selectedIndex == index;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _selectedIndex = index),
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 78),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFF7A7A).withOpacity(0.14) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _navItems[index]['icon'] as IconData,
                                    color: isSelected ? const Color(0xFFFF7A7A) : const Color(0xFF636D83),
                                    size: 22,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _navItems[index]['label'] as String,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFFFF7A7A) : const Color(0xFF636D83),
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
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
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFFABB2BF),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. VISTA DAILY DASHBOARD
// ==========================================
class DailyView extends StatefulWidget {
  const DailyView({super.key});
  @override
  State<DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends State<DailyView> {
  String _timeString = "";
  late Timer _timer;
  final TextEditingController _quickNoteController = TextEditingController();
  final TextEditingController _newHabitController = TextEditingController();
  final _kudexBox = Hive.box('kudexBox');

  List _habits = [];
  String _climaTemp = "--";
  String _climaEstado = "Cargando clima...";
  List _timelineHoy = [];

  @override
  void initState() {
    super.initState();
    _timeString = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    _loadHabits();
    _fetchClima();
    _loadTodayTimeline();
  }

  @override
  void dispose() {
    _timer.cancel();
    _quickNoteController.dispose();
    _newHabitController.dispose();
    super.dispose();
  }

  void _getTime() {
    if (mounted) {
      setState(() {
        _timeString = _formatDateTime(DateTime.now());
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }

  String _todayIso() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
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
      if (mounted) {
        setState(() => _climaEstado = "Sin conexión");
      }
    }
  }

  String _interpretarCodigoClima(int code) {
    if (code == 0) return "Despejado ☀️";
    if (code == 1 || code == 2 || code == 3) return "Parcialmente nublado ⛅";
    if (code >= 51 && code <= 67) return "Lluvia 🌧️";
    return "Nublado ☁️";
  }

  // Carga eventos del calendario local, calendario .ics vinculado y tareas con fecha de hoy
  void _loadTodayTimeline() {
    final todayStr = _todayIso();
    List combined = [];

    final savedIcsEvents = _kudexBox.get('ics_events');
    if (savedIcsEvents != null) {
      for (var item in (savedIcsEvents as List)) {
        if (item['date'] == todayStr) {
          combined.add({
            'title': item['title'],
            'time': item['time'] ?? '00:00',
            'source': 'Calendario',
            'color': const Color(0xFF61AFEF),
          });
        }
      }
    }

    final savedLocalEvents = _kudexBox.get('local_events');
    if (savedLocalEvents != null) {
      for (var item in (savedLocalEvents as List)) {
        if (item['date'] == todayStr) {
          combined.add({
            'title': item['title'],
            'time': item['time'] ?? '09:00',
            'source': 'Evento',
            'color': const Color(0xFF98C379),
          });
        }
      }
    }

    final savedTasks = _kudexBox.get('tasks');
    if (savedTasks != null) {
      for (var item in (savedTasks as List)) {
        if (item['date'] == todayStr && !(item['done'] == true)) {
          combined.add({
            'title': "Tarea: ${item['title']}",
            'time': (item['time'] != null && item['time'].toString().isNotEmpty) ? item['time'] : 'Todo el día',
            'source': item['priority'] ?? 'Pendiente',
            'color': const Color(0xFFE5C07B),
          });
        }
      }
    }

    combined.sort((a, b) => a['time'].toString().compareTo(b['time'].toString()));
    if (mounted) {
      setState(() => _timelineHoy = combined);
    }
  }

  // --- GESTIÓN DINÁMICA DE HÁBITOS ---
  void _loadHabits() {
    final savedHabits = _kudexBox.get('habits');
    if (savedHabits != null && mounted) {
      setState(() {
        _habits = List.from((savedHabits as List).map((item) => Map.from(item as Map)));
      });
    } else if (mounted) {
      setState(() {
        _habits = [
          {'name': '💻 Estudiar / Programación', 'done': false},
          {'name': '💧 Tomar 2L de agua', 'done': false},
        ];
      });
      _saveHabits();
    }
  }

  void _saveHabits() => _kudexBox.put('habits', _habits);

  void _toggleHabit(int index, bool? value) {
    setState(() => _habits[index]['done'] = value ?? false);
    _saveHabits();
  }

  void _showHabitDialog([int? editIndex]) {
    _newHabitController.text = editIndex != null ? _habits[editIndex]['name'] : '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282C34),
        title: Text(editIndex != null ? 'Editar Hábito' : 'Nuevo Hábito', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: _newHabitController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ej. Leer 20 páginas, Meditar...',
            hintStyle: const TextStyle(color: Color(0xFF636D83)),
            filled: true,
            fillColor: const Color(0xFF181A1F),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A7A), foregroundColor: const Color(0xFF1E222A)),
            onPressed: () {
              final text = _newHabitController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  if (editIndex != null) {
                    _habits[editIndex]['name'] = text;
                  } else {
                    _habits.add({'name': text, 'done': false});
                  }
                });
                _saveHabits();
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteHabit(int index) {
    setState(() => _habits.removeAt(index));
    _saveHabits();
  }

  void _convertToPostIt() {
    final text = _quickNoteController.text.trim();
    if (text.isEmpty) return;
    List currentNotes = [];
    final savedNotes = _kudexBox.get('notes');
    if (savedNotes != null) {
      currentNotes = List.from((savedNotes as List).map((item) => Map.from(item as Map)));
    }
    currentNotes.add({
      'title': 'Nota Rápida',
      'text': text,
      'colorIndex': DateTime.now().millisecond % 4,
    });
    _kudexBox.put('notes', currentNotes);
    setState(() => _quickNoteController.clear());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📌 Nota enviada al tablero de corcho'), backgroundColor: Color(0xFFFF7A7A)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HOY', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                  const Text('Hola, Santiago', style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3E4451)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome, color: Color(0xFFFF7A7A), size: 32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              SizedBox(
                width: 340,
                child: Column(
                  children: [
                    // RELOJ CON ROBOTO MONO
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3E4451)),
                      ),
                      child: Column(
                        children: [
                          const Text('● DÍA EN CURSO', style: TextStyle(color: Color(0xFF98C379), fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text(
                            _timeString,
                            style: GoogleFonts.robotoMono(
                              fontSize: 38,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    // CLIMA
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3E4451)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$_climaTemp $_climaEstado', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const Text('Qro, MX', style: TextStyle(color: Color(0xFF636D83))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    // LÍNEA DE TIEMPO DEL DÍA (LIMPIA, SIN INPUT ICS)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3E4451)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('LÍNEA DE TIEMPO DE HOY', style: TextStyle(color: Color(0xFF61AFEF), fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Color(0xFF636D83), size: 18),
                                tooltip: 'Actualizar horario',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _loadTodayTimeline,
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          if (_timelineHoy.isEmpty)
                            const Text(
                              'No hay eventos ni tareas programadas para hoy. Agrégalos desde Calendario o Lists.',
                              style: TextStyle(color: Color(0xFF636D83), fontSize: 13),
                            )
                          else
                            ..._timelineHoy.map(
                              (evt) {
                                final Color accent = evt['color'] as Color;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 58,
                                        child: Text(
                                          evt['time'].toString(),
                                          style: const TextStyle(color: Color(0xFF636D83), fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: accent.withOpacity(0.15),
                                            border: Border(left: BorderSide(color: accent, width: 3)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(evt['title'].toString(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text(evt['source'].toString(), style: TextStyle(color: accent, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 400,
                child: Column(
                  children: [
                    // NOTAS RÁPIDAS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3E4451)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('NOTAS RÁPIDAS', style: TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.bold)),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7A7A),
                                  foregroundColor: const Color(0xFF1E222A),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: _convertToPostIt,
                                child: const Text('Convertir a Post-it', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _quickNoteController,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Anota algo rápido aquí...',
                              hintStyle: const TextStyle(color: Color(0xFF636D83)),
                              filled: true,
                              fillColor: const Color(0xFF181A1F),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    // HÁBITOS PERSONALIZABLES
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3E4451)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('HÁBITOS DIARIOS (${_habits.length})', style: const TextStyle(color: Color(0xFF61AFEF), fontWeight: FontWeight.bold)),
                              InkWell(
                                onTap: () => _showHabitDialog(),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF61AFEF).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.add, color: Color(0xFF61AFEF), size: 16),
                                      SizedBox(width: 4),
                                      Text('Agregar', style: TextStyle(color: Color(0xFF61AFEF), fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_habits.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No tienes hábitos configurados. Toca + Agregar para crear uno.', style: TextStyle(color: Color(0xFF636D83), fontSize: 13)),
                            )
                          else
                            ...List.generate(_habits.length, (index) {
                              final habit = _habits[index];
                              final bool isDone = habit['done'] == true;
                              return Row(
                                children: [
                                  Checkbox(
                                    activeColor: const Color(0xFFFF7A7A),
                                    value: isDone,
                                    onChanged: (val) => _toggleHabit(index, val),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showHabitDialog(index),
                                      child: Text(
                                        habit['name'].toString(),
                                        style: TextStyle(
                                          color: isDone ? const Color(0xFF636D83) : Colors.white,
                                          decoration: isDone ? TextDecoration.lineThrough : null,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF636D83)),
                                    onPressed: () => _showHabitDialog(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFE06C75)),
                                    onPressed: () => _deleteHabit(index),
                                  ),
                                ],
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. VISTA CALENDARIO NATIVO + CONFIGURACIÓN .ICS
// ==========================================
class CalendarView extends StatefulWidget {
  const CalendarView({super.key});
  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final _kudexBox = Hive.box('kudexBox');
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  List _localEvents = [];
  List _icsEvents = [];
  List _scheduledTasks = [];

  final List<String> _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    _loadAllCalendarData();
  }

  void _loadAllCalendarData() {
    final savedLocal = _kudexBox.get('local_events');
    final savedIcs = _kudexBox.get('ics_events');
    final savedTasks = _kudexBox.get('tasks');

    setState(() {
      _localEvents = savedLocal != null ? List.from((savedLocal as List).map((e) => Map.from(e as Map))) : [];
      _icsEvents = savedIcs != null ? List.from((savedIcs as List).map((e) => Map.from(e as Map))) : [];
      _scheduledTasks = savedTasks != null
          ? List.from((savedTasks as List).where((t) => t['date'] != null && t['date'].toString().isNotEmpty).map((e) => Map.from(e as Map)))
          : [];
    });
  }

  String _formatIso(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  List _getItemsForDay(DateTime day) {
    final iso = _formatIso(day);
    List items = [];
    for (var e in _localEvents) {
      if (e['date'] == iso) {
        items.add({...e, 'type': 'local', 'color': const Color(0xFF98C379)});
      }
    }
    for (var e in _icsEvents) {
      if (e['date'] == iso) {
        items.add({...e, 'type': 'ics', 'color': const Color(0xFF61AFEF)});
      }
    }
    for (var t in _scheduledTasks) {
      if (t['date'] == iso) {
        items.add({
          'title': "Tarea: ${t['title']}",
          'time': (t['time'] != null && t['time'].toString().isNotEmpty) ? t['time'] : 'Sin hora',
          'type': 'task',
          'color': const Color(0xFFE5C07B),
        });
      }
    }
    items.sort((a, b) => (a['time'] ?? '').toString().compareTo((b['time'] ?? '').toString()));
    return items;
  }

  void _showAddEventModal() {
    final titleCtrl = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF282C34),
          title: Text('Nuevo Evento (${_formatIso(_selectedDay)})', style: const TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Título del evento o clase...',
                  hintStyle: const TextStyle(color: Color(0xFF636D83)),
                  filled: true,
                  fillColor: const Color(0xFF181A1F),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3E4451)),
                  minimumSize: const Size(double.infinity, 44),
                ),
                onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: selectedTime);
                  if (picked != null) {
                    setModalState(() => selectedTime = picked);
                  }
                },
                icon: const Icon(Icons.access_time, color: Color(0xFFFF7A7A)),
                label: Text(
                  "Hora: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A7A), foregroundColor: const Color(0xFF1E222A)),
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _localEvents.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleCtrl.text.trim(),
                      'date': _formatIso(_selectedDay),
                      'time': "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                    });
                  });
                  _kudexBox.put('local_events', _localEvents);
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar Evento', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openLinkSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalendarLinkSettingsPage()),
    );
    _loadAllCalendarData();
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday; // 1 = Lunes, 7 = Domingo
    final dayEvents = _getItemsForDay(_selectedDay);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENCABEZADO CON BOTÓN DE VINCULACIÓN APARTE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Calendario', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF7A7A)),
                  foregroundColor: const Color(0xFFFF7A7A),
                ),
                onPressed: _openLinkSettings,
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Vincular', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // TARJETA DEL MES
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3E4451)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
                    ),
                    Text(
                      "${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}",
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                      .map((d) => SizedBox(
                            width: 36,
                            child: Center(child: Text(d, style: const TextStyle(color: Color(0xFF636D83), fontWeight: FontWeight.bold, fontSize: 12))),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
                  itemCount: (startWeekday - 1) + daysInMonth,
                  itemBuilder: (context, idx) {
                    if (idx < startWeekday - 1) return const SizedBox();
                    final dayNum = idx - (startWeekday - 1) + 1;
                    final currentDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                    final isSelected = currentDate.year == _selectedDay.year &&
                        currentDate.month == _selectedDay.month &&
                        currentDate.day == _selectedDay.day;
                    final hasItems = _getItemsForDay(currentDate).isNotEmpty;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = currentDate),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFF7A7A) : const Color(0xFF181A1F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF1E222A) : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                            if (hasItems)
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF1E222A) : const Color(0xFF61AFEF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // AGENDA DEL DÍA SELECCIONADO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Agenda: ${_selectedDay.day} de ${_monthNames[_selectedDay.month - 1]}",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A7A), foregroundColor: const Color(0xFF1E222A)),
                onPressed: _showAddEventModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Evento', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dayEvents.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3E4451)),
              ),
              child: const Text('No hay eventos ni tareas para este día.', style: TextStyle(color: Color(0xFF636D83))),
            )
          else
            ...dayEvents.map((evt) {
              final Color c = evt['color'] as Color;
              return Card(
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(evt['time'].toString(), style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  title: Text(evt['title'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  trailing: evt['type'] == 'local'
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFE06C75)),
                          onPressed: () {
                            setState(() {
                              _localEvents.removeWhere((e) => e['id'] == evt['id']);
                            });
                            _kudexBox.put('local_events', _localEvents);
                          },
                        )
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ==========================================
// PÁGINA APARTE: VINCULACIÓN DE CALENDARIOS (.ICS)
// ==========================================
class CalendarLinkSettingsPage extends StatefulWidget {
  const CalendarLinkSettingsPage({super.key});
  @override
  State<CalendarLinkSettingsPage> createState() => _CalendarLinkSettingsPageState();
}

class _CalendarLinkSettingsPageState extends State<CalendarLinkSettingsPage> {
  final _kudexBox = Hive.box('kudexBox');
  final TextEditingController _icsCtrl = TextEditingController();
  bool _syncing = false;
  String _statusMsg = '';

  @override
  void initState() {
    super.initState();
    _icsCtrl.text = (_kudexBox.get('ics_url') ?? '').toString();
  }

  Future<void> _syncIcs() async {
    final url = _icsCtrl.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _syncing = true;
      _statusMsg = 'Conectando y descargando eventos...';
    });
    _kudexBox.put('ics_url', url);

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final iCal = ICalendar.fromString(response.body);
        List parsedEvents = [];
        for (var event in iCal.data) {
          if (event['type'] == 'VEVENT' && event.containsKey('dtstart')) {
            final dtStart = event['dtstart'];
            DateTime? eventDate;
            if (dtStart is IcsDateTime) {
              eventDate = dtStart.toDateTime();
            } else if (dtStart is Map && dtStart['dt'] != null) {
              eventDate = DateTime.tryParse(dtStart['dt'].toString());
            }
            if (eventDate != null) {
              parsedEvents.add({
                'title': event['summary'] ?? 'Evento sincronizado',
                'date': "${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}",
                'time': "${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}",
              });
            }
          }
        }
        _kudexBox.put('ics_events', parsedEvents);
        setState(() {
          _syncing = false;
          _statusMsg = '✅ Sincronización exitosa: ${parsedEvents.length} eventos importados.';
        });
      } else {
        setState(() {
          _syncing = false;
          _statusMsg = '❌ El servidor respondió con error (${response.statusCode}). Verifica que el enlace sea público.';
        });
      }
    } catch (e) {
      setState(() {
        _syncing = false;
        _statusMsg = '❌ No se pudo leer el archivo .ics. Asegúrate de pegar el enlace secreto en formato iCal (.ics) y tener conexión a internet.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E222A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A1F),
        title: const Text('Vincular Calendario Externo', style: TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3E4451)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enlace de suscripción (.ics / iCal)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _icsCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'https://.../basic.ics',
                        hintStyle: const TextStyle(color: Color(0xFF636D83)),
                        filled: true,
                        fillColor: const Color(0xFF181A1F),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A7A),
                          foregroundColor: const Color(0xFF1E222A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _syncing ? null : _syncIcs,
                        icon: _syncing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E222A)))
                            : const Icon(Icons.sync),
                        label: Text(_syncing ? 'Sincronizando...' : 'Sincronizar Calendario', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (_statusMsg.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_statusMsg, style: const TextStyle(color: Color(0xFFE5C07B), fontSize: 13)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Instrucciones por plataforma', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildInstructionCard(
                'Google Calendar',
                '1. Abre calendar.google.com desde una computadora.\n'
                    '2. En el panel izquierdo, pasa el cursor sobre tu calendario, toca los 3 puntos y entra a "Configuración y uso compartido".\n'
                    '3. Baja hasta la sección "Integrar el calendario".\n'
                    '4. Copia el enlace que dice "Dirección secreta en formato iCal" (debe terminar en .ics) y pégalo arriba.',
              ),
              _buildInstructionCard(
                'Apple Calendar (iCloud / iPad / iPhone)',
                '1. Abre la app Calendario en tu iPad/iPhone o entra a icloud.com/calendar.\n'
                    '2. Toca el icono de información (i) o compartir junto al calendario que deseas vincular.\n'
                    '3. Activa la opción "Calendario público".\n'
                    '4. Toca "Compartir enlace" o "Copiar enlace" (comienza con webcal:// o https://) y pégalo arriba.',
              ),
              _buildInstructionCard(
                'Microsoft Outlook',
                '1. Entra a outlook.live.com desde el navegador y ve al icono de Calendario.\n'
                    '2. Haz clic en el engranaje de Configuración → "Calendario" → "Calendarios compartidos".\n'
                    '3. En "Publicar un calendario", elige tu calendario y selecciona el permiso "Puede ver todos los detalles".\n'
                    '4. Haz clic en Publicar, copia el enlace ICS y pégalo arriba.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard(String title, String body) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3E4451)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF61AFEF), fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: Color(0xFFABB2BF), fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

// ==========================================
// 5. VISTA LISTS (FECHA, HORARIO Y FILTROS)
// ==========================================
class ListsView extends StatefulWidget {
  const ListsView({super.key});
  @override
  State<ListsView> createState() => _ListsViewState();
}

class _ListsViewState extends State<ListsView> {
  final TextEditingController _taskController = TextEditingController();
  String _priority = 'Importante';
  String _filterPriority = 'Todas';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final _kudexBox = Hive.box('kudexBox');
  List tasks = [];

  final List<String> _priorities = ['Urgente', 'Importante', 'No tan importante'];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    final savedTasks = _kudexBox.get('tasks');
    if (savedTasks != null && mounted) {
      setState(() {
        tasks = List.from((savedTasks as List).map((item) => Map.from(item as Map)));
      });
    }
  }

  void _saveTasks() => _kudexBox.put('tasks', tasks);

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
      );
      setState(() {
        _selectedDate = pickedDate;
        _selectedTime = pickedTime;
      });
    }
  }

  void _addTask() {
    if (_taskController.text.trim().isNotEmpty) {
      String dateIso = '';
      String timeStr = '';
      if (_selectedDate != null) {
        dateIso = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      }
      if (_selectedTime != null) {
        timeStr = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}";
      }

      setState(() {
        tasks.insert(0, {
          'title': _taskController.text.trim(),
          'priority': _priority,
          'done': false,
          'date': dateIso,
          'time': timeStr,
        });
        _taskController.clear();
        _selectedDate = null;
        _selectedTime = null;
      });
      _saveTasks();
    }
  }

  void _toggleTask(int realIndex, bool? value) {
    setState(() => tasks[realIndex]['done'] = value ?? false);
    _saveTasks();
  }

  void _deleteTask(int realIndex) {
    setState(() => tasks.removeAt(realIndex));
    _saveTasks();
  }

  Color _getPriorityColor(String priority) {
    if (priority == 'Urgente') return const Color(0xFFE06C75);
    if (priority == 'Importante') return const Color(0xFFE5C07B);
    return const Color(0xFF61AFEF);
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filterPriority == 'Todas'
        ? tasks
        : tasks.where((t) => t['priority'] == _filterPriority).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gestor de Pendientes', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextField(
            controller: _taskController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nuevo pendiente...',
              hintStyle: const TextStyle(color: Color(0xFF636D83)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<String>(
                  value: _priority,
                  dropdownColor: Theme.of(context).cardColor,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: _priorities.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                  onChanged: (val) => setState(() => _priority = val!),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _selectedDate != null ? const Color(0xFF98C379) : const Color(0xFF3E4451)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onPressed: _pickDateTime,
                icon: Icon(Icons.event, size: 16, color: _selectedDate != null ? const Color(0xFF98C379) : const Color(0xFFABB2BF)),
                label: Text(
                  _selectedDate == null
                      ? 'Fecha / Hora'
                      : "${_selectedDate!.day}/${_selectedDate!.month}${_selectedTime != null ? ' ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}' : ''}",
                  style: TextStyle(color: _selectedDate != null ? const Color(0xFF98C379) : Colors.white, fontSize: 13),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A7A),
                  foregroundColor: const Color(0xFF1E222A),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                ),
                onPressed: _addTask,
                child: const Text('Agregar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // BARRA DE FILTROS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Todas', ..._priorities].map((filter) {
                final bool active = _filterPriority == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: active,
                    selectedColor: const Color(0xFFFF7A7A),
                    backgroundColor: Theme.of(context).cardColor,
                    labelStyle: TextStyle(
                      color: active ? const Color(0xFF1E222A) : const Color(0xFFABB2BF),
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _filterPriority = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(child: Text('No hay pendientes en esta categoría.', style: TextStyle(color: Color(0xFF636D83))))
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final int realIndex = tasks.indexOf(task);
                      final bool isDone = task['done'] == true;
                      final String title = task['title'].toString();
                      final String priority = (task['priority'] ?? 'Importante').toString();
                      final String date = (task['date'] ?? '').toString();
                      final String time = (task['time'] ?? '').toString();

                      return Card(
                        color: Theme.of(context).cardColor,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Checkbox(
                            value: isDone,
                            activeColor: const Color(0xFFFF7A7A),
                            onChanged: (bool? value) => _toggleTask(realIndex, value),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              color: isDone ? const Color(0xFF636D83) : Colors.white,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: date.isNotEmpty
                              ? Text(
                                  "📅 $date ${time.isNotEmpty ? '• ⏰ $time' : ''}",
                                  style: const TextStyle(color: Color(0xFF98C379), fontSize: 12),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(priority).withOpacity(0.2),
                                  border: Border.all(color: _getPriorityColor(priority)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  priority,
                                  style: TextStyle(color: _getPriorityColor(priority), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF636D83)),
                                onPressed: () => _deleteTask(realIndex),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. VISTA NOTES & CORCHO
// ==========================================
class NotesView extends StatefulWidget {
  const NotesView({super.key});
  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  final _kudexBox = Hive.box('kudexBox');
  List notes = [];

  final List<Color> postItColors = [
    const Color(0xFFFF8A80),
    const Color(0xFF80D8FF),
    const Color(0xFFFFD180),
    const Color(0xFFCCFF90),
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
        notes = List.from((savedNotes as List).map((item) => Map.from(item as Map)));
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
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(hintText: 'Título de la nota', hintStyle: TextStyle(color: Color(0xFF636D83))),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(color: postItColors[selectedColor], borderRadius: BorderRadius.circular(8)),
                      child: TextField(
                        controller: textCtrl,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(color: Colors.black87),
                        decoration: const InputDecoration(
                          hintText: 'Escribe tu idea...',
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(postItColors.length, (i) {
                        return GestureDetector(
                          onTap: () => setStateDialog(() => selectedColor = i),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: postItColors[i],
                              shape: BoxShape.circle,
                              border: Border.all(color: selectedColor == i ? Colors.white : Colors.transparent, width: 2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        notes.removeAt(index);
                        _saveNotes();
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Eliminar', style: TextStyle(color: Color(0xFFFF7A7A))),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A7A), foregroundColor: const Color(0xFF1E222A)),
                  onPressed: () {
                    setState(() {
                      final newNote = {'title': titleCtrl.text, 'text': textCtrl.text, 'colorIndex': selectedColor};
                      if (isEditing) {
                        notes[index] = newNote;
                      } else {
                        notes.add(newNote);
                      }
                      _saveNotes();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar 📌', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tablero de Ideas', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A7A), foregroundColor: const Color(0xFF1E222A)),
                onPressed: () => _showNoteModal(),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Nota', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8D5524),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF522F12), width: 3),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 1,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return GestureDetector(
                    onTap: () => _showNoteModal(index),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: postItColors[note['colorIndex']],
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(2, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note['title'],
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Expanded(
                            child: Text(note['text'], style: const TextStyle(color: Colors.black87, fontSize: 13), overflow: TextOverflow.fade),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 7. VISTA CUADERNO (MATERIAS, PÁGINAS Y DIBUJO)
// ==========================================
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
      setState(() {
        materias = jsonDecode(savedData);
      });
    } else if (mounted) {
      setState(() {
        materias = [
          {
            'nombre': 'Estática',
            'paginas': [
              {'nombre': 'Ejercicios 2D', 'texto': '', 'fondo': 'grid', 'trazos': []}
            ]
          }
        ];
      });
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
                    materias.add({
                      'nombre': ctrl.text,
                      'paginas': [
                        {'nombre': 'Página 1', 'texto': '', 'fondo': 'grid', 'trazos': []}
                      ]
                    });
                    materiaActiva = materias.length - 1;
                    paginaActiva = 0;
                  } else {
                    materias[materiaActiva]['paginas'].add({
                      'nombre': ctrl.text,
                      'texto': '',
                      'fondo': 'grid',
                      'trazos': [],
                    });
                    paginaActiva = materias[materiaActiva]['paginas'].length - 1;
                  }
                  _cargarPaginaEnPantalla();
                  _saveCuaderno();
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Crear', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deshacerTrazo() {
    if (lines.isNotEmpty) {
      setState(() {
        lines.removeLast();
        _saveCuaderno();
      });
    }
  }

  Future<void> _exportarPDF() async {
    try {
      RenderRepaintBoundary boundary = _pdfKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      final pdf = pw.Document();
      final imageProvider = pw.MemoryImage(pngBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Center(child: pw.Image(imageProvider)),
        ),
      );
      String pageName = materias[materiaActiva]['paginas'][paginaActiva]['nombre'];
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'Apunte_$pageName.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al exportar.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          final isCtrlOrMeta = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
          if (isCtrlOrMeta && event.logicalKey == LogicalKeyboardKey.keyZ) {
            _deshacerTrazo();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Row(
        children: [
          if (!isMobile)
            Container(
              width: 160,
              color: const Color(0xFF181A1F),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Materias', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () => _crearNueva('Materia'),
                          child: const Icon(Icons.add, color: Color(0xFFFF7A7A), size: 20),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: materias.length,
                      itemBuilder: (context, index) {
                        bool isActive = index == materiaActiva;
                        return ListTile(
                          title: Text(
                            materias[index]['nombre'],
                            style: TextStyle(color: isActive ? Colors.white : const Color(0xFFABB2BF), fontSize: 14),
                          ),
                          tileColor: isActive ? Theme.of(context).cardColor : Colors.transparent,
                          onTap: () {
                            _saveCuaderno();
                            setState(() {
                              materiaActiva = index;
                              paginaActiva = 0;
                              _cargarPaginaEnPantalla();
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          if (!isMobile)
            Container(
              width: 160,
              decoration: const BoxDecoration(
                color: Color(0xFF1E222A),
                border: Border(right: BorderSide(color: Color(0xFF3E4451))),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Páginas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () => _crearNueva('Página'),
                          child: const Icon(Icons.add, color: Color(0xFFFF7A7A), size: 20),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: materias.isEmpty
                        ? const SizedBox()
                        : ListView.builder(
                            itemCount: materias[materiaActiva]['paginas'].length,
                            itemBuilder: (context, index) {
                              bool isActive = index == paginaActiva;
                              return ListTile(
                                title: Text(
                                  materias[materiaActiva]['paginas'][index]['nombre'],
                                  style: TextStyle(color: isActive ? Colors.white : const Color(0xFFABB2BF), fontSize: 14),
                                ),
                                tileColor: isActive ? Theme.of(context).cardColor : Colors.transparent,
                                onTap: () {
                                  _saveCuaderno();
                                  setState(() {
                                    paginaActiva = index;
                                    _cargarPaginaEnPantalla();
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ToggleButtons(
                          isSelected: [isTextMode, !isTextMode],
                          onPressed: (index) => setState(() => isTextMode = index == 0),
                          fillColor: const Color(0xFFFF7A7A).withOpacity(0.2),
                          selectedColor: const Color(0xFFFF7A7A),
                          color: Colors.white,
                          borderColor: const Color(0xFF3E4451),
                          selectedBorderColor: const Color(0xFFFF7A7A),
                          constraints: const BoxConstraints(minHeight: 35, minWidth: 80),
                          children: const [Text('Texto'), Text('Dibujo')],
                        ),
                        const SizedBox(width: 15),
                        const Text('Tinta: ', style: TextStyle(color: Color(0xFF636D83), fontSize: 12)),
                        _colorBtn(Colors.white),
                        _colorBtn(const Color(0xFFFF7A7A)),
                        _colorBtn(const Color(0xFF61AFEF)),
                        _colorBtn(const Color(0xFFE5C07B)),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isEraser && !isTextMode ? const Color(0xFF2C313A) : Colors.transparent,
                            side: BorderSide(color: isEraser && !isTextMode ? const Color(0xFFFF7A7A) : const Color(0xFF3E4451)),
                          ),
                          onPressed: () => setState(() {
                            isEraser = true;
                            isTextMode = false;
                          }),
                          icon: Icon(Icons.cleaning_services, size: 16, color: isEraser && !isTextMode ? Colors.white : const Color(0xFFABB2BF)),
                          label: Text('Borrador', style: TextStyle(color: isEraser && !isTextMode ? Colors.white : const Color(0xFFABB2BF))),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: _deshacerTrazo,
                          icon: const Icon(Icons.undo, color: Color(0xFFABB2BF)),
                          tooltip: 'Deshacer',
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF98C379), foregroundColor: const Color(0xFF1E222A)),
                          onPressed: _exportarPDF,
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('Exportar PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFF14161A),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: RepaintBoundary(
                        key: _pdfKey,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 850),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181A1F),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF3E4451)),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(child: CustomPaint(painter: BackgroundPainter(currentFondo), child: Container())),
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: TextField(
                                    controller: _textController,
                                    maxLines: null,
                                    expands: true,
                                    enabled: isTextMode,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Escribe aquí...',
                                      hintStyle: TextStyle(color: Color(0xFF3E4451)),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  ignoring: isTextMode,
                                  child: GestureDetector(
                                    onPanStart: (details) => setState(
                                      () => currentLine = DrawnLine(
                                        [details.localPosition],
                                        strokeColor,
                                        isEraser ? 20.0 : strokeWidth,
                                        isEraser: isEraser,
                                      ),
                                    ),
                                    onPanUpdate: (details) => setState(() => currentLine?.path.add(details.localPosition)),
                                    onPanEnd: (details) {
                                      if (currentLine != null) {
                                        setState(() {
                                          lines.add(currentLine!);
                                          currentLine = null;
                                        });
                                        _saveCuaderno();
                                      }
                                    },
                                    child: CustomPaint(
                                      painter: DrawingPainter(lines: lines, currentLine: currentLine),
                                      child: Container(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorBtn(Color color) {
    bool isSelected = strokeColor == color && !isEraser && !isTextMode;
    return GestureDetector(
      onTap: () => setState(() {
        strokeColor = color;
        isTextMode = false;
        isEraser = false;
      }),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? const Color(0xFFFF7A7A) : Colors.transparent, width: 2),
        ),
      ),
    );
  }
}

// ==========================================
// 8. VISTA PLANNER (AL FINAL DE LA BARRA)
// ==========================================
class PlannerView extends StatelessWidget {
  const PlannerView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Vista de Planner (Próximamente)...', style: TextStyle(color: Colors.white, fontSize: 18)),
    );
  }
}

// ==========================================
// 9. PINTORES Y MODELO DE TRAZOS
// ==========================================
class BackgroundPainter extends CustomPainter {
  final String pattern;
  BackgroundPainter(this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;
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

  factory DrawnLine.fromJson(Map json) {
    return DrawnLine(
      (json['path'] as List)
          .map((e) => Offset((e['x'] as num).toDouble(), (e['y'] as num).toDouble()))
          .toList(),
      Color(json['color'] as int),
      (json['width'] as num).toDouble(),
      isEraser: (json['isEraser'] as bool?) ?? false,
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
    Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (var line in lines) {
      paint.color = line.color;
      paint.strokeWidth = line.width;
      paint.blendMode = line.isEraser ? BlendMode.clear : BlendMode.srcOver;
      for (int i = 0; i < line.path.length - 1; i++) {
        canvas.drawLine(line.path[i], line.path[i + 1], paint);
      }
    }
    if (currentLine != null) {
      paint.color = currentLine!.color;
      paint.strokeWidth = currentLine!.width;
      paint.blendMode = currentLine!.isEraser ? BlendMode.clear : BlendMode.srcOver;
      for (int i = 0; i < currentLine!.path.length - 1; i++) {
        canvas.drawLine(currentLine!.path[i], currentLine!.path[i + 1], paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}