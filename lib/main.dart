import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // Initialize Awesome Notifications
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'event_reminder_channel',
        channelName: 'Event Reminders',
        channelDescription: 'Notificações para lembretes de eventos',
        importance: NotificationImportance.Max,
        defaultColor: const Color(0xFF6C63FF),
        ledColor: kIsWeb ? null : Colors.white, // Skip on web
        vibrationPattern: kIsWeb ? null : highVibrationPattern, // Skip on web
        enableLights: kIsWeb ? false : true, // Skip on web
        enableVibration: kIsWeb ? false : true, // Skip on web
        playSound: kIsWeb ? true : true,
        soundSource: kIsWeb ? null : 'resource://raw/res_notification', // Skip on web
      ),
    ],
    debug: true,
  );

  // Request notification permissions
  bool permission = await AwesomeNotifications().isNotificationAllowed();
  print('Permissão inicial de notificação: $permission');
  if (!permission) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  final String? recurrence;
  final DateTime? recurrenceEndDate;

  const Event({
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.backgroundColor = const Color(0xFF6C63FF),
    this.location = '',
    this.category = 'Geral',
    this.participants = const [],
    this.recurrence,
    this.recurrenceEndDate,
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
  String? _selectedRecurrence = 'Nenhuma';
  DateTime? _recurrenceEndDate;
  late TabController _tabController;
  final List<String> _categories = ['Reunião', 'Pessoal', 'Trabalho', 'Viagem', 'Aniversário', 'Outro'];
  final List<String> _recurrenceOptions = ['Nenhuma', 'Diária', 'Semanal', 'Mensal', 'Anual'];
  bool _showAddOptions = false;
  Timer? _notificationCheckTimer;
  List<Event> _upcomingNotifications = [];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(hours: 2));
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
    _startNotificationCheckTimer();
  }

  void _startNotificationCheckTimer() {
    _notificationCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForUpcomingNotifications();
    });
    _checkForUpcomingNotifications();
  }

  void _checkForUpcomingNotifications() {
    final now = DateTime.now();
    print('Verificando notificações em $now');
    final notificationWindow = now.add(const Duration(minutes: 15));
    final upcoming = <Event>[];

    _events.forEach((day, events) {
      for (var event in events) {
        final timeDifference = event.startTime.difference(now);
        print('Evento: ${event.title}, Início: ${event.startTime}, Diferença: ${timeDifference.inMinutes} min');
        if (event.startTime.isAfter(now) &&
            event.startTime.isBefore(notificationWindow) &&
            timeDifference.inMinutes <= 15) {
          print('Evento próximo encontrado: ${event.title}');
          upcoming.add(event);
        }
      }
    });

    setState(() {
      _upcomingNotifications = upcoming;
      print('Notificações próximas: ${upcoming.length}');
    });
  }

  void _loadEvents() {
    final Map<DateTime, List<Event>> events = {};
    final now = DateTime.now();

    final testEvent = Event(
      title: 'Evento de Teste',
      description: 'Teste de notificação push',
      startTime: DateTime(now.year, now.month, now.day, 21, 9), // 15 min from 20:54
      endTime: DateTime(now.year, now.month, now.day, 21, 10),
      backgroundColor: const Color(0xFF6C63FF),
      location: 'Online',
      category: 'Teste',
    );

    final sampleEvent1 = Event(
      title: 'Reunião de projeto',
      description: 'Apresentação do novo design',
      startTime: DateTime(now.year, now.month, now.day, 10, 0),
      endTime: DateTime(now.year, now.month, now.day, 12, 0),
      backgroundColor: const Color(0xFF6C63FF),
      location: 'Sala A',
      category: 'Trabalho',
      participants: ['Maria', 'João'],
    );

    final sampleEvent2 = Event(
      title: 'Aniversário de Ana',
      description: 'Festa de aniversário',
      startTime: DateTime(now.year, now.month, now.day + 3, 18, 0),
      endTime: DateTime(now.year, now.month, now.day + 3, 22, 0),
      backgroundColor: const Color(0xFFFF2D55),
      location: 'Casa de Ana',
      category: 'Aniversário',
      participants: ['João', 'Carlos'],
      recurrence: 'Anual',
      recurrenceEndDate: DateTime(now.year + 2, now.month, now.day + 3),
    );

    final day1 = DateTime(now.year, now.month, now.day);
    final day2 = DateTime(now.year, now.month, now.day + 3);
    events[day1] = [testEvent, sampleEvent1];
    events[day2] = [sampleEvent2];

    _addRecurringEvents(events, sampleEvent2);

    setState(() {
      _events = events;
    });

    _scheduleNotification(testEvent);
  }

  void _addRecurringEvents(Map<DateTime, List<Event>> events, Event event) {
    if (event.recurrence == null || event.recurrenceEndDate == null) return;

    DateTime currentDate = event.startTime;
    final endDate = event.recurrenceEndDate!;
    const maxOccurrences = 100;
    int occurrenceCount = 0;

    while (currentDate.isBefore(endDate) && occurrenceCount < maxOccurrences) {
      occurrenceCount++;
      DateTime nextDate;

      switch (event.recurrence) {
        case 'Diária':
          nextDate = currentDate.add(const Duration(days: 1));
          break;
        case 'Semanal':
          nextDate = currentDate.add(const Duration(days: 7));
          break;
        case 'Mensal':
          nextDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day, currentDate.hour, currentDate.minute);
          break;
        case 'Anual':
          nextDate = DateTime(currentDate.year + 1, currentDate.month, currentDate.day, currentDate.hour, currentDate.minute);
          break;
        default:
          return;
      }

      if (nextDate.isBefore(endDate)) {
        final normalizedDay = DateTime(nextDate.year, nextDate.month, nextDate.day);
        final recurringEvent = Event(
          title: event.title,
          description: event.description,
          startTime: nextDate,
          endTime: nextDate.add(event.endTime.difference(event.startTime)),
          backgroundColor: event.backgroundColor,
          location: event.location,
          category: event.category,
          participants: event.participants,
          recurrence: event.recurrence,
          recurrenceEndDate: event.recurrenceEndDate,
        );

        if (events[normalizedDay] == null) {
          events[normalizedDay] = [];
        }
        events[normalizedDay]!.add(recurringEvent);
      }

      currentDate = nextDate;
    }
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
                    Tab(text: 'Notificações'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCalendarView(),
                      _buildAgendaView(),
                      _buildNotificationsView(),
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

  Widget _buildNotificationsView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notificações',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
              ),
              IconButton(
                icon: Icon(Icons.notification_add, color: Theme.of(context).colorScheme.primary),
                onPressed: () {
                  final testEvent = Event(
                    title: 'Teste Manual',
                    description: 'Notificação de teste',
                    startTime: DateTime.now().add(const Duration(minutes: 1)),
                    endTime: DateTime.now().add(const Duration(minutes: 10)),
                    backgroundColor: const Color(0xFF6C63FF),
                    location: 'Online',
                    category: 'Teste',
                  );
                  _scheduleImmediateNotification(testEvent);
                  setState(() {
                    _upcomingNotifications.add(testEvent);
                  });
                },
                tooltip: 'Testar Notificação',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_upcomingNotifications.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Sem notificações próximas', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  Text('Eventos aparecerão aqui 15 minutos antes', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _upcomingNotifications.length,
                itemBuilder: (context, index) {
                  final event = _upcomingNotifications[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: Icon(Icons.notifications_active, color: event.backgroundColor, size: 30),
                      title: Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Início: ${DateFormat('HH:mm', 'pt_BR').format(event.startTime)}', style: TextStyle(color: Colors.grey[600])),
                          if (event.location.isNotEmpty) Text('Local: ${event.location}', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[400]),
                        onPressed: () {
                          setState(() {
                            _upcomingNotifications.removeAt(index);
                          });
                          AwesomeNotifications().cancel(event.hashCode);
                        },
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

  Widget _buildCalendarView() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
              titleTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.primary),
              rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle),
              weekendTextStyle: const TextStyle(color: Colors.red),
            ),
          ),
        ),
        Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildEventList())),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("Sem eventos para este dia", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            Text("Toque no + para criar um novo evento", style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: eventsList.length,
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) => _buildEventCard(eventsList[index]),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: event.backgroundColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: event.backgroundColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(_getCategoryIcon(event.category), color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}${event.recurrence != null ? ' (Recorrente: ${event.recurrence})' : ''}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _showEventDetails(event)),
              ],
            ),
          ),
          if (event.location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.location, style: TextStyle(fontSize: 14, color: Colors.grey[600]))),
                ],
              ),
            ),
          if (event.participants.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.participants.join(', '), style: TextStyle(fontSize: 14, color: Colors.grey[600]))),
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
            transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(scale: animation, child: child),
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
                color: _showAddOptions ? Colors.red : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _showAddOptions ? Icons.close : Icons.add,
                  key: ValueKey(_showAddOptions ? 'close' : 'add'),
                  color: Colors.white,
                  size: 30,
                ),
                transitionBuilder: (Widget child, Animation<double> animation) => RotationTransition(turns: animation, child: ScaleTransition(scale: animation, child: child)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOptionButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 16)),
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
    _selectedRecurrence = 'Nenhuma';
    _recurrenceEndDate = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: _getCategoryColor(_selectedCategory), borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Novo Evento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.event_note),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Local',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Categoria', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = category),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? _getCategoryColor(category) : _getCategoryColor(category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getCategoryIcon(category), size: 16, color: isSelected ? Colors.white : _getCategoryColor(category)),
                                const SizedBox(width: 6),
                                Text(category, style: TextStyle(color: isSelected ? Colors.white : _getCategoryColor(category), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Recorrência', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedRecurrence,
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.repeat)),
                      items: _recurrenceOptions.map((option) => DropdownMenuItem<String>(value: option, child: Text(option))).toList(),
                      onChanged: (value) => setState(() {
                        _selectedRecurrence = value;
                        if (value == 'Nenhuma') _recurrenceEndDate = null;
                      }),
                    ),
                    if (_selectedRecurrence != 'Nenhuma') ...[
                      const SizedBox(height: 20),
                      const Text('Fim da Recorrência', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate.add(const Duration(days: 30)),
                            firstDate: _startDate,
                            lastDate: DateTime(2030),
                            builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _getCategoryColor(_selectedCategory))), child: child!),
                          );
                          if (date != null) setState(() => _recurrenceEndDate = DateTime(date.year, date.month, date.day, 23, 59));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _recurrenceEndDate != null ? DateFormat('dd/MM/yyyy').format(_recurrenceEndDate!) : 'Selecionar data de término',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              Icon(Icons.calendar_today, size: 16, color: _getCategoryColor(_selectedCategory)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Início', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                    builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _getCategoryColor(_selectedCategory))), child: child!),
                                  );
                                  if (date != null) {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(_startDate),
                                      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _getCategoryColor(_selectedCategory))), child: child!),
                                    );
                                    if (time != null) {
                                      setState(() {
                                        _startDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                        _endDate = _startDate.add(const Duration(hours: 2));
                                      });
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat('dd/MM/yyyy HH:mm').format(_startDate), style: TextStyle(color: Colors.grey[700])),
                                      Icon(Icons.calendar_today, size: 16, color: _getCategoryColor(_selectedCategory)),
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
                              const Text('Fim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                    builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _getCategoryColor(_selectedCategory))), child: child!),
                                  );
                                  if (date != null) {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(_endDate),
                                      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _getCategoryColor(_selectedCategory))), child: child!),
                                    );
                                    if (time != null) setState(() => _endDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat('dd/MM/yyyy HH:mm').format(_endDate), style: TextStyle(color: Colors.grey[700])),
                                      Icon(Icons.calendar_today, size: 16, color: _getCategoryColor(_selectedCategory)),
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
                    const Text('Participantes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(backgroundColor: _getCategoryColor(_selectedCategory), radius: 18, child: const Icon(Icons.person, color: Colors.white, size: 18)),
                              const SizedBox(width: 12),
                              const Expanded(child: Text('Adicionar participantes', style: TextStyle(color: Colors.grey))),
                              IconButton(icon: Icon(Icons.person_add, color: _getCategoryColor(_selectedCategory)), onPressed: () {}),
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
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
                child: ElevatedButton(
                  onPressed: () {
                    _saveEvent();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCategoryColor(_selectedCategory),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Salvar Evento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scheduleNotification(Event event) async {
    final scheduledTime = event.startTime.subtract(const Duration(minutes: 15));
    print('Agendando notificação para ${event.title} em $scheduledTime');
    bool allowed = await AwesomeNotifications().isNotificationAllowed();
    print('Notificações permitidas: $allowed');
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
      allowed = await AwesomeNotifications().isNotificationAllowed();
      print('Permissão após solicitação: $allowed');
      if (!allowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, permita notificações no navegador')),
        );
        return;
      }
    }
    if (scheduledTime.isAfter(DateTime.now())) {
      try {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: event.hashCode,
            channelKey: 'event_reminder_channel',
            title: 'Lembrete: ${event.title}',
            body: 'O evento começa às ${DateFormat('HH:mm', 'pt_BR').format(event.startTime)}',
            notificationLayout: NotificationLayout.Default,
            displayOnForeground: true,
            displayOnBackground: true,
          ),
          schedule: kIsWeb
              ? NotificationInterval(
            interval: (scheduledTime.difference(DateTime.now()).inSeconds),
            timeZone: 'America/Sao_Paulo',
            preciseAlarm: false,
          )
              : NotificationCalendar.fromDate(
            date: scheduledTime,
            allowWhileIdle: true,
            preciseAlarm: true,
          ),
        );
        print('Notificação agendada com sucesso para ${event.title}');
      } catch (e) {
        print('Erro ao agendar notificação para ${event.title}: $e');
      }
    } else {
      print('Não agendado: Horário no passado ($scheduledTime)');
    }
  }

  Future<void> _scheduleImmediateNotification(Event event) async {
    bool allowed = await AwesomeNotifications().isNotificationAllowed();
    print('Permissão para notificação imediata: $allowed');
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
      allowed = await AwesomeNotifications().isNotificationAllowed();
      if (!allowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, permita notificações no navegador')),
        );
        return;
      }
    }
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: event.hashCode,
          channelKey: 'event_reminder_channel',
          title: 'Lembrete: ${event.title}',
          body: 'Notificação de teste imediata',
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
      );
      print('Notificação imediata disparada para ${event.title}');
    } catch (e) {
      print('Erro ao disparar notificação imediata: $e');
    }
  }

  void _saveEvent() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O título do evento é obrigatório')));
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A data de término deve ser posterior à data de início')));
      return;
    }
    if (_selectedRecurrence != 'Nenhuma' && _recurrenceEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecione uma data de término para a recorrência')));
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
      recurrence: _selectedRecurrence != 'Nenhuma' ? _selectedRecurrence : null,
      recurrenceEndDate: _recurrenceEndDate,
    );

    setState(() {
      final normalizedDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
      if (_events[normalizedDay] == null) _events[normalizedDay] = [];
      _events[normalizedDay]!.add(newEvent);
      _selectedDay = normalizedDay;
      if (newEvent.recurrence != null) _addRecurringEvents(_events, newEvent);
    });

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
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: event.backgroundColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(DateFormat('EEEE, d MMMM', 'pt_BR').format(event.startTime), style: const TextStyle(fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildDetailItem(icon: Icons.access_time, color: event.backgroundColor, title: 'Horário', content: '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}'),
                  if (event.recurrence != null)
                    _buildDetailItem(
                      icon: Icons.repeat,
                      color: event.backgroundColor,
                      title: 'Recorrência',
                      content: '${event.recurrence} até ${DateFormat('dd/MM/yyyy').format(event.recurrenceEndDate!)}',
                    ),
                  if (event.location.isNotEmpty) _buildDetailItem(icon: Icons.location_on, color: event.backgroundColor, title: 'Local', content: event.location),
                  _buildDetailItem(icon: _getCategoryIcon(event.category), color: event.backgroundColor, title: 'Categoria', content: event.category),
                  if (event.description.isNotEmpty) _buildDetailItem(icon: Icons.description, color: event.backgroundColor, title: 'Descrição', content: event.description),
                  if (event.participants.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: event.backgroundColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.people, size: 20, color: event.backgroundColor),
                            ),
                            const SizedBox(width: 16),
                            const Text('Participantes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...event.participants.map((participant) => Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 46),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: event.backgroundColor.withOpacity(0.2),
                                radius: 18,
                                child: Text(participant.substring(0, 1), style: TextStyle(color: event.backgroundColor, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Text(participant, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        )),
                      ],
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Excluir', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: event.backgroundColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Compartilhar', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildDetailItem({required IconData icon, required Color color, required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: color)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(content, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
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
        events.removeWhere((event) => event.title == eventToDelete.title && event.startTime == eventToDelete.startTime && event.recurrence == eventToDelete.recurrence);
        if (events.isEmpty) _events.remove(day);
      });
      _upcomingNotifications.remove(eventToDelete);
    });
    AwesomeNotifications().cancel(eventToDelete.hashCode);
    if (eventToDelete.recurrence != null) {
      for (int i = 1; i <= 100; i++) AwesomeNotifications().cancel('${eventToDelete.hashCode}_$i'.hashCode);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _tabController.dispose();
    _notificationCheckTimer?.cancel();
    super.dispose();
  }
}
