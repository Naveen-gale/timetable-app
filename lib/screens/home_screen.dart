import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/timetable_entry.dart';
import '../screens/add_class_screen.dart';
import '../screens/edit_class_screen.dart';
import '../screens/settings_screen.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/day_utils.dart';
import '../utils/time_utils.dart';
import '../widgets/break_card.dart';
import '../widgets/day_selector.dart';
import '../widgets/empty_timetable.dart';
import '../widgets/next_class_card.dart';
import '../widgets/timetable_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSettingsChanged;

  const HomeScreen({super.key, required this.onSettingsChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDay = DayUtils.today();
  List<TimetableEntry> _entries = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
    setState(() {
      _entries = StorageService.instance.getEntriesForDay(_selectedDay);
    });
  }

  List<TimetableEntry> get _filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    final q = _searchQuery.toLowerCase();
    return _entries.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.teacher.toLowerCase().contains(q) ||
          e.room.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _addEntry({required bool isClass}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddClassScreen(day: _selectedDay, isClass: isClass),
      ),
    );
    _loadEntries();
  }

  Future<void> _editEntry(TimetableEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditClassScreen(entry: entry)),
    );
    _loadEntries();
  }

  Future<void> _deleteEntry(TimetableEntry entry) async {
    await NotificationService.instance.cancelNotificationForEntry(entry.id);
    await StorageService.instance.deleteEntry(entry.id);
    _loadEntries();
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.school_rounded),
              title: const Text('Add Class'),
              onTap: () {
                Navigator.pop(ctx);
                _addEntry(isClass: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.free_breakfast_outlined),
              title: const Text('Add Break'),
              onTap: () {
                Navigator.pop(ctx);
                _addEntry(isClass: false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = StorageService.instance.getSettings();
    final todayEntries =
        StorageService.instance.getEntriesForDay(DayUtils.today());

    // Progress: classes that have ended today.
    final nowMinutes = TimeUtils.totalMinutes(TimeOfDay.now());
    final totalClasses = todayEntries.where((e) => e.isClass).length;
    final doneClasses = todayEntries
        .where((e) => e.isClass && e.endTotalMinutes <= nowMinutes)
        .length;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _loadEntries(),
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              floating: true,
              pinned: false,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()} 👋',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMMM').format(DateTime.now()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'Search',
                  onPressed: () async {
                    final q = await showSearch<String>(
                      context: context,
                      delegate: _TimetableSearchDelegate(
                          StorageService.instance.getAllEntries()),
                    );
                    if (q != null) {
                      setState(() => _searchQuery = q);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          onChanged: () {
                            widget.onSettingsChanged();
                            _loadEntries();
                          },
                        ),
                      ),
                    );
                    _loadEntries();
                  },
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Search chip if active
                  if (_searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text('Search: "$_searchQuery"'),
                            onSelected: (_) =>
                                setState(() => _searchQuery = ''),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () =>
                                setState(() => _searchQuery = ''),
                            selected: true,
                          ),
                        ],
                      ),
                    ),

                  // ── Next Class Card ──
                  if (_searchQuery.isEmpty && _selectedDay == DayUtils.today())
                    ...[
                    NextClassCard(todayEntries: todayEntries),
                    const SizedBox(height: 20),
                  ],

                  // ── Progress ──
                  if (_searchQuery.isEmpty &&
                      _selectedDay == DayUtils.today() &&
                      totalClasses > 0) ...[
                    _buildProgressRow(
                        context, doneClasses, totalClasses, colorScheme),
                    const SizedBox(height: 20),
                  ],

                  // ── Day Selector ──
                  if (_searchQuery.isEmpty) ...[
                    Text(
                      'TODAY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            letterSpacing: 1.4,
                          ),
                    ),
                    const SizedBox(height: 8),
                    DaySelector(
                      selectedDay: _selectedDay,
                      availableDays: settings.selectedDays,
                      onDaySelected: (day) {
                        setState(() {
                          _selectedDay = day;
                          _searchQuery = '';
                        });
                        _loadEntries();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Entry List ──
                  if (_filteredEntries.isEmpty)
                    EmptyTimetable(
                      onAddClass: () => _addEntry(isClass: true),
                    )
                  else
                    ..._filteredEntries.map((entry) {
                      if (entry.isClass) {
                        return TimetableCard(
                          entry: entry,
                          onEdit: () => _editEntry(entry),
                          onDelete: () => _deleteEntry(entry),
                        );
                      } else {
                        return BreakCard(
                          entry: entry,
                          onEdit: () => _editEntry(entry),
                          onDelete: () => _deleteEntry(entry),
                        );
                      }
                    }),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMenu,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildProgressRow(
    BuildContext context,
    int done,
    int total,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.track_changes_rounded,
              size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Today's classes",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '$done / $total completed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Search Delegate ──────────────────────────────

class _TimetableSearchDelegate extends SearchDelegate<String> {
  final List<TimetableEntry> allEntries;

  _TimetableSearchDelegate(this.allEntries);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        )
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search classes…'));
    }

    final q = query.toLowerCase();
    final results = allEntries.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.teacher.toLowerCase().contains(q) ||
          e.room.toLowerCase().contains(q);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Text('No results for "$query"',
            style: Theme.of(context).textTheme.bodyLarge),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (ctx, i) {
        final entry = results[i];
        return ListTile(
          leading: Icon(
            entry.isClass ? Icons.school_rounded : Icons.free_breakfast_outlined,
          ),
          title: Text(entry.title),
          subtitle: Text(
              '${DayUtils.fullName(entry.day)} • ${TimeUtils.formatHM(entry.startHour, entry.startMinute)}'),
          onTap: () => close(context, entry.title),
        );
      },
    );
  }
}
