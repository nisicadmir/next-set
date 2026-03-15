import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pages/create_edit_set_page.dart';
import 'pages/run_set_page.dart';
import 'pages/create_edit_training_page.dart';
import 'pages/run_training_page.dart';
import 'models/workout_set.dart';
import 'models/training.dart';
import 'services/set_storage_service.dart';
import 'services/training_storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterForegroundTask.initCommunicationPort();
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'nextset_foreground',
      channelName: 'NextSet workout',
      channelDescription: 'Shown while a workout timer is running.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      onlyAlertOnce: true,
      showWhen: true,
      playSound: false,
      enableVibration: false,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(1000),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: false,
    ),
  );

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themePrefKey = 'isDarkMode';

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themePrefKey) ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextSet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: HomePage(onThemeChanged: _toggleTheme),
    );
  }
}

class HomePage extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const HomePage({super.key, required this.onThemeChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;

  // Timer tab state
  final SetStorageService _setStorageService = SetStorageService();
  List<WorkoutSet> _sets = [];
  bool _setsLoading = true;

  // Training tab state
  final TrainingStorageService _trainingStorageService =
      TrainingStorageService();
  List<Training> _trainings = [];
  bool _trainingsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSets();
    _loadTrainings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSets() async {
    setState(() => _setsLoading = true);
    try {
      final sets = await _setStorageService.getAllSets();
      sets.sort((a, b) {
        if (a.lastUsedAt == null && b.lastUsedAt == null) return 0;
        if (a.lastUsedAt == null) return 1;
        if (b.lastUsedAt == null) return -1;
        return b.lastUsedAt!.compareTo(a.lastUsedAt!);
      });
      if (mounted) setState(() { _sets = sets; _setsLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _sets = []; _setsLoading = false; });
    }
  }

  Future<void> _loadTrainings() async {
    setState(() => _trainingsLoading = true);
    try {
      final trainings = await _trainingStorageService.getAllTrainings();
      trainings.sort((a, b) {
        if (a.lastUsedAt == null && b.lastUsedAt == null) return 0;
        if (a.lastUsedAt == null) return 1;
        if (b.lastUsedAt == null) return -1;
        return b.lastUsedAt!.compareTo(a.lastUsedAt!);
      });
      if (mounted) setState(() { _trainings = trainings; _trainingsLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _trainings = []; _trainingsLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('NextSet'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.timer), text: 'Timer'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Training'),
          ],
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menu',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dark Theme',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Switch(
                    value: isDarkMode,
                    onChanged: (value) => widget.onThemeChanged(value),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () async {
                      final url = Uri.parse(
                        'https://www.nisix.net/nextset/privacy.html',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: const Text(
                      'Privacy',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TimerTab(
            sets: _sets,
            isLoading: _setsLoading,
            onReload: _loadSets,
          ),
          _TrainingTab(
            trainings: _trainings,
            isLoading: _trainingsLoading,
            onReload: _loadTrainings,
          ),
        ],
      ),
    );
  }
}

// ─── Timer Tab ───────────────────────────────────────────────────────────────

class _TimerTab extends StatelessWidget {
  final List<WorkoutSet> sets;
  final bool isLoading;
  final VoidCallback onReload;

  const _TimerTab({
    required this.sets,
    required this.isLoading,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Sets',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: sets.isEmpty
                        ? _emptyState(
                            context,
                            icon: Icons.timer_outlined,
                            title: 'No sets created yet',
                            subtitle: 'Create a set to get started',
                          )
                        : ListView.builder(
                            itemCount: sets.length,
                            itemBuilder: (context, index) =>
                                _SetCard(set: sets[index], onReload: onReload),
                          ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CreateEditSetPage(),
                          ),
                        );
                        if (result != null) onReload();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Set'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SetCard extends StatelessWidget {
  final WorkoutSet set;
  final VoidCallback onReload;

  const _SetCard({required this.set, required this.onReload});

  @override
  Widget build(BuildContext context) {
    final int minutes = set.secondsPerSet ~/ 60;
    final int seconds = set.secondsPerSet % 60;
    final String timeDisplay =
        minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RunSetPage(workoutSet: set),
            ),
          );
          onReload();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      set.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _edit(context),
                        tooltip: 'Edit',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(context),
                        tooltip: 'Delete',
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${set.numberOfSets} sets',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeDisplay,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEditSetPage(existingSet: set),
      ),
    );
    if (result != null) onReload();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set'),
        content: Text('Are you sure you want to delete "${set.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await SetStorageService().deleteSet(set.id);
              onReload();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Set deleted')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Training Tab ─────────────────────────────────────────────────────────────

class _TrainingTab extends StatelessWidget {
  final List<Training> trainings;
  final bool isLoading;
  final VoidCallback onReload;

  const _TrainingTab({
    required this.trainings,
    required this.isLoading,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Trainings',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: trainings.isEmpty
                        ? _emptyState(
                            context,
                            icon: Icons.fitness_center,
                            title: 'No trainings created yet',
                            subtitle: 'Create a training to get started',
                          )
                        : ListView.builder(
                            itemCount: trainings.length,
                            itemBuilder: (context, index) => _TrainingCard(
                              training: trainings[index],
                              onReload: onReload,
                            ),
                          ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const CreateEditTrainingPage(),
                          ),
                        );
                        if (result != null) onReload();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Training'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  final Training training;
  final VoidCallback onReload;

  const _TrainingCard({required this.training, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RunTrainingPage(training: training),
            ),
          );
          onReload();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      training.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _edit(context),
                        tooltip: 'Edit',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(context),
                        tooltip: 'Delete',
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.loop,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${training.cycles.length} cycles',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${training.totalRepeats} total reps',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CreateEditTrainingPage(existingTraining: training),
      ),
    );
    if (result != null) onReload();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Training'),
        content: Text('Are you sure you want to delete "${training.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await TrainingStorageService().deleteTraining(training.id);
              onReload();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Training deleted')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _emptyState(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    ),
  );
}
