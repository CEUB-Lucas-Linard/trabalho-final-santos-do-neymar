import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  // Inicializa a formatação de data para pt_BR
  await initializeDateFormatting('pt_BR', null);

  // Inicializa as notificações locais
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const EventApp());
}

class EventApp extends StatelessWidget {
  const EventApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EventApp',
      theme: ThemeData(
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFFFF7D54),
          tertiary: const Color(0xFF4ECDC4),
          background: const Color(0xFFF8F9FE),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF2D3748)),
          bodyLarge: TextStyle(color: Color(0xFF4A5568)),
          bodyMedium: TextStyle(color: Color(0xFF718096)),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
      ),
      home: const EventCalendarScreen(),
    );
  }
}

class Event {
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final Color backgroundColor;
  final String location;
  final String category;
  final List<String> participants;

  const Event({
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.backgroundColor = const Color(0xFF6C63FF),
    this.location = '',
    this.category = 'Geral',
    this.participants = const [],
  });
}

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({Key? key}) : super(key: key);

  @override
  _EventCalendarScreenState createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Event>> _events = {};
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedCategory = 'Reunião';
  late TabController _tabController;
  final List<String> _categories = ['Reunião', 'Pessoal', 'Trabalho', 'Viagem', 'Aniversário', 'Outro'];
  bool _showAddOptions = false;

  // Instância do plugin de notificações
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(hours: 2));
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
    _initializeNotifications();
  }

  // Inicializa as configurações de notificação
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _loadEvents() {
    final Map<DateTime, List<Event>> events = {};
    final now = DateTime.now();

    final sampleEvent1 = Event(
      title: 'Reunião de projeto',
      description: 'Apresentação do novo design para o cliente',
      startTime: DateTime(now.year, now.month, now.day, 10, 0),
      endTime: DateTime(now.year, now.month, now.day, 12, 0),
      backgroundColor: const Color(0xFF6C63FF),
      location: 'Sala de Conferências A',
      category: 'Trabalho',
      participants: ['Maria Silva', 'João Oliveira'],
    );

    final sampleEvent2 = Event(
      title: 'Almoço com parceiros',
      description: 'Restaurante Italiano - Centro',
      startTime: DateTime(now.year, now.month, now.day + 2, 13, 0),
      endTime: DateTime(now.year, now.month, now.day + 2, 14, 30),
      backgroundColor: const Color(0xFFFF7D54),
      location: 'Restaurante Bella Italia',
      category: 'Networking',
      participants: ['Carlos Souza', 'Ana Mendes'],
    );

    final sampleEvent3 = Event(
      title: 'Consulta médica',
      description: 'Check-up anual',
      startTime: DateTime(now.year, now.month, now.day - 1, 15, 0),
      endTime: DateTime(now.year, now.month, now.day - 1, 16, 0),
      backgroundColor: const Color(0xFF4ECDC4),
      location: 'Clínica Central',
      category: 'Pessoal',
      participants: [],
    );

    final sampleEvent4 = Event(
      title: 'Aniversário de Maria',
      description: 'Festa de aniversário',
      startTime: DateTime(now.year, now.month, now.day + 3, 18, 0),
      endTime: DateTime(now.year, now.month, now.day + 3, 22, 0),
      backgroundColor: const Color(0xFFFF2D55),
      location: 'Casa de Maria',
      category: 'Aniversário',
      participants: ['João', 'Ana', 'Carlos'],
    );

    final day1 = DateTime(now.year, now.month, now.day);
    final day2 = DateTime(now.year, now.month, now.day + 2);
    final day3 = DateTime(now.year, now.month, now.day - 1);
    final day4 = DateTime(now.year, now.month, now.day + 3);

    events[day1] = [sampleEvent1];
    events[day2] = [sampleEvent2];
    events[day3] = [sampleEvent3];
    events[day4] = [sampleEvent4];

    setState(() {
      _events = events;
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Reunião':
        return const Color(0xFF6C63FF);
      case 'Pessoal':
        return const Color(0xFF4ECDC4);
      case 'Trabalho':
        return const Color(0xFFFF7D54);
      case 'Viagem':
        return const Color(0xFFFFBE0B);
      case 'Aniversário':
        return const Color(0xFFFF2D55);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Reunião':
        return Icons.groups;
      case 'Pessoal':
        return Icons.person;
      case 'Trabalho':
        return Icons.work;
      case 'Viagem':
        return Icons.flight;
      case 'Aniversário':
        return Icons.cake;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: const [
                    Tab(text: 'Calendário'),
                    Tab(text: 'Agenda'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCalendarView(),
                      _buildAgendaView(),
                    ],
                  ),
                ),
              ],
            ),
            _buildCustomAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EventApp',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM', 'pt_BR').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                radius: 24,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Theme.of(context).colorScheme.primary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: const TextStyle(color: Colors.red),
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildEventList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaView() {
    final allEvents = <DateTime, List<Event>>{};
    _events.forEach((day, events) {
      final normalizedDay = DateTime(day.year, day.month, day.day);
      allEvents[normalizedDay] = events;
    });

    final sortedDays = allEvents.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final events = allEvents[day]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                DateFormat('EEEE, d MMMM', 'pt_BR').format(day),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...events.map((event) => _buildEventCard(event)).toList(),
            const Divider(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildEventList() {
    final eventsList = _getEventsForDay(_selectedDay);

    if (eventsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              "Sem eventos para este dia",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Toque no + para criar um novo evento",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: eventsList.length,
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) {
        return _buildEventCard(eventsList[index]);
      },
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: event.backgroundColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: event.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(event.category),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showEventDetails(event),
                ),
              ],
            ),
          ),
          if (event.location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (event.participants.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.participants.join(', '),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
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

  Widget _buildCustomAddButton() {
    return Positioned(
      right: 24,
      bottom: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _showAddOptions
                ? Column(
                    key: const ValueKey('options'),
                    children: [
                      _buildAddOptionButton(
                        icon: Icons.work,
                        color: const Color(0xFFFF7D54),
                        label: 'Trabalho',
                        onTap: () {
                          setState(() {
                            _selectedCategory = 'Trabalho';
                            _showAddOptions = false;
                          });
                          _showAddEventDialog();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildAddOptionButton(
                        icon: Icons.person,
                        color: const Color(0xFF4ECDC4),
                        label: 'Pessoal',
                        onTap: () {
                          setState(() {
                            _selectedCategory = 'Pessoal';
                            _showAddOptions = false;
                          });
                          _showAddEventDialog();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildAddOptionButton(
                        icon: Icons.groups,
                        color: const Color(0xFF6C63FF),
                        label: 'Reunião',
                        onTap: () {
                          setState(() {
                            _selectedCategory = 'Reunião';
                            _showAddOptions = false;
                          });
                          _showAddEventDialog();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildAddOptionButton(
                        icon: Icons.cake,
                        color: const Color(0xFFFF2D55),
                        label: 'Aniversário',
                        onTap: () {
                          setState(() {
                            _selectedCategory = 'Aniversário';
                            _showAddOptions = false;
                          });
                          _showAddEventDialog();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showAddOptions = !_showAddOptions;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _showAddOptions
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _showAddOptions ? Icons.close : Icons.add,
                  key: ValueKey(_showAddOptions ? 'close' : 'add'),
                  color: Colors.white,
                  size: 30,
                ),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return RotationTransition(
                    turns: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
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

  Widget _buildAddOptionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    _titleController.clear();
    _descController.clear();
    _locationController.clear();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(hours: 2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(_selectedCategory),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Novo Evento',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Título do Evento',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.event_note),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Local',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Categoria',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _getCategoryColor(category)
                                    : _getCategoryColor(category).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getCategoryIcon(category),
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : _getCategoryColor(category),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : _getCategoryColor(category),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Início',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: _getCategoryColor(_selectedCategory),
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (date != null) {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(_startDate),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: _getCategoryColor(_selectedCategory),
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _startDate = DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('dd/MM/yyyy HH:mm').format(_startDate),
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: _getCategoryColor(_selectedCategory),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fim',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: _getCategoryColor(_selectedCategory),
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (date != null) {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(_endDate),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: _getCategoryColor(_selectedCategory),
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _endDate = DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('dd/MM/yyyy HH:mm').format(_endDate),
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: _getCategoryColor(_selectedCategory),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Participantes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _getCategoryColor(_selectedCategory),
                                  radius: 18,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Adicionar participantes',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.person_add,
                                    color: _getCategoryColor(_selectedCategory),
                                  ),
                                  onPressed: () {
                                    // Implementar lógica para adicionar participantes
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      _saveEvent();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getCategoryColor(_selectedCategory),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Salvar Evento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Método para agendar notificação
  Future<void> _scheduleNotification(Event event) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'event_reminder_channel',
      'Event Reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final scheduledTime = event.startTime.subtract(const Duration(minutes: 15));
    if (scheduledTime.isAfter(DateTime.now())) {
      await flutterLocalNotificationsPlugin.schedule(
        event.hashCode, // ID único baseado no hash do evento
        'Lembrete: ${event.title}',
        'O evento começa às ${DateFormat('HH:mm', 'pt_BR').format(event.startTime)}',
        scheduledTime,
        platformChannelSpecifics,
      );
    }
  }

  void _saveEvent() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O título do evento é obrigatório')),
      );
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A data de término deve ser posterior à data de início')),
      );
      return;
    }

    final newEvent = Event(
      title: _titleController.text,
      description: _descController.text,
      startTime: _startDate,
      endTime: _endDate,
      backgroundColor: _getCategoryColor(_selectedCategory),
      location: _locationController.text,
      category: _selectedCategory,
      participants: [],
    );

    final normalizedDay = DateTime(_startDate.year, _startDate.month, _startDate.day);

    setState(() {
      if (_events[normalizedDay] != null) {
        _events[normalizedDay]!.add(newEvent);
      } else {
        _events[normalizedDay] = [newEvent];
      }
      _selectedDay = normalizedDay;
    });

    // Agendar notificação para o novo evento
    _scheduleNotification(newEvent);
  }

  void _showEventDetails(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: event.backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, d MMMM', 'pt_BR').format(event.startTime),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          // Implementar edição do evento
                          Navigator.pop(context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildDetailItem(
                    icon: Icons.access_time,
                    color: event.backgroundColor,
                    title: 'Horário',
                    content: '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                  ),
                  if (event.location.isNotEmpty)
                    _buildDetailItem(
                      icon: Icons.location_on,
                      color: event.backgroundColor,
                      title: 'Local',
                      content: event.location,
                    ),
                  _buildDetailItem(
                    icon: _getCategoryIcon(event.category),
                    color: event.backgroundColor,
                    title: 'Categoria',
                    content: event.category,
                  ),
                  if (event.description.isNotEmpty)
                    _buildDetailItem(
                      icon: Icons.description,
                      color: event.backgroundColor,
                      title: 'Descrição',
                      content: event.description,
                    ),
                  if (event.participants.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: event.backgroundColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.people,
                                size: 20,
                                color: event.backgroundColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Participantes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...event.participants.map((participant) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12, left: 46),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: event.backgroundColor.withOpacity(0.2),
                                  radius: 18,
                                  child: Text(
                                    participant.substring(0, 1),
                                    style: TextStyle(
                                      color: event.backgroundColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  participant,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _deleteEvent(event);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Excluir',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Implementar ação de compartilhar evento
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: event.backgroundColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Compartilhar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteEvent(Event eventToDelete) {
    setState(() {
      _events.forEach((day, events) {
        events.removeWhere((event) =>
            event.title == eventToDelete.title &&
            event.startTime == eventToDelete.startTime);

        if (events.isEmpty) {
          _events.remove(day);
        }
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
