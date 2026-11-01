import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'download_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:open_filex/open_filex.dart';

import 'theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/home/hub_pages.dart';
import 'features/bible/bible_screen.dart';
import 'features/visualisasi/visualisasi_screen.dart';
import 'data/official_pmk_data.dart';
import 'features/account/account_gateway.dart';
import 'features/account/account_controller.dart';
import 'features/account/account_page.dart';

const String kDefaultSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String kDefaultSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_PUBLIC_KEY',
);

const int kAppBuildNumber = 10;
const String kAppVersionName = '1.4.0';

const List<String> kInterviewQuestions = [
  'Pengalaman di PMK?',
  'Apa yang perlu diperbaiki (PMK dan Proker)?',
  'Paling enak ajak kerjasama?',
  'Paling ga enak?',
  'Lanjut jadi pengururs? Kalau ngga, kenapa & kesibukan apa?',
  'Top 5 nama cocok?',
  'Apakah bersedia kalau menjadi calon ketua?',
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AccountGateway accountGateway = const UnavailableAccountGateway();
  try {
    await Supabase.initialize(
      url: kDefaultSupabaseUrl,
      publishableKey: kDefaultSupabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    accountGateway = SupabaseAccountGateway(
      client: Supabase.instance.client,
      projectUrl: kDefaultSupabaseUrl,
      publicKey: kDefaultSupabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase initial setup: $e');
  }
  runApp(ChecklistApp(accountGateway: accountGateway));
}

class ChecklistApp extends StatefulWidget {
  final AccountGateway accountGateway;
  const ChecklistApp({
    super.key,
    this.accountGateway = const UnavailableAccountGateway(),
  });
  @override
  State<ChecklistApp> createState() => _ChecklistAppState();
}

class _ChecklistAppState extends State<ChecklistApp> {
  late final AccountController _account;
  @override
  void initState() {
    super.initState();
    _account = AccountController(widget.accountGateway);
    unawaited(_account.loadProviders());
  }

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AccountScope(
      controller: _account,
      child: Builder(
        builder: (context) {
          final user = AccountScope.of(context).user;
          return MaterialApp(
            key: ValueKey(user?.id ?? 'signed-out'),
            title: 'Daniels App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: user == null || !user.emailVerified
                ? const AccountPage()
                : user.name.trim().isEmpty
                ? const AccountPage(onboarding: true)
                : const DanielsMainHub(),
          );
        },
      ),
    );
  }
}

class DanielsMainHub extends StatefulWidget {
  const DanielsMainHub({super.key});

  @override
  State<DanielsMainHub> createState() => _DanielsMainHubState();
}

class _DanielsMainHubState extends State<DanielsMainHub> {
  int _currentIndex = 0;
  final GlobalKey<_ChecklistHomePageState> _interviewKey =
      GlobalKey<_ChecklistHomePageState>();
  bool _interviewOpened = false;

  Widget _retainInterview(Widget page) {
    _interviewOpened =
        _interviewOpened || _currentIndex == 1 || _currentIndex == 2;
    return _interviewOpened ? page : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(
              onOpenInterview: () => setState(() => _currentIndex = 1),
              onOpenVisualisasi: () => setState(() => _currentIndex = 2),
              onOpenBible: () => setState(() => _currentIndex = 3),
              onOpenSettings: () => setState(() => _currentIndex = 5),
              onFilterInterview: (query) {
                setState(() => _currentIndex = 1);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _interviewKey.currentState?.filterByQuery(query);
                });
              },
            ),
            _retainInterview(
              ChecklistHomePage(
                key: _interviewKey,
                onBackToHome: () => setState(() => _currentIndex = 0),
                onOpenVisualisasi: () => setState(() => _currentIndex = 2),
              ),
            ),
            VisualisasiScreen(
              items: _interviewKey.currentState?.items ?? [],
              onBackToHome: () => setState(() => _currentIndex = 0),
              onGoToInterview: () => setState(() => _currentIndex = 1),
              onLoadOfficialData: (seed) {
                _interviewKey.currentState?.loadSeedItems(seed);
                setState(() {});
              },
            ),
            const BibleScreen(),
            const FriendsPage(),
            HubSettingsPage(
              onCloudSettings: () {
                setState(() => _currentIndex = 1);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _interviewKey.currentState?.showRoomSettingsDialog();
                });
              },
              onInterview: () => setState(() => _currentIndex = 1),
              onVisualisasi: () => setState(() => _currentIndex = 2),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: AppTheme.border.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex == 4
                ? 1
                : (_currentIndex == 5 ? 2 : 0),
            onDestinationSelected: (idx) =>
                setState(() => _currentIndex = [0, 4, 5][idx]),
            height: 65,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(
                  Icons.people_rounded,
                  color: AppTheme.primary,
                ),
                label: 'Friend',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(
                  Icons.settings_rounded,
                  color: AppTheme.primary,
                ),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String cleanCandidateDisplayName(String name) {
  return name
      .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\u00A0\t\r\n]'), ' ')
      .replaceAll(
        RegExp(r'^\s*\d+[\.\)\-–\s]+'),
        '',
      ) // strip leading list numbers (1., 01), etc.)
      .replaceAll(RegExp(r'\s+'), ' ') // collapse multi-spaces
      .trim();
}

String normalizeCandidateName(String name) {
  return cleanCandidateDisplayName(name)
      .replaceAll(
        RegExp(r'[\.,;:]+$'),
        '',
      ) // strip trailing dots or punctuation
      .toLowerCase();
}

class NameItem {
  String id;
  String name;
  bool isChecked;
  int updatedAt;
  Map<String, String> notes;

  NameItem({
    required this.id,
    required this.name,
    this.isChecked = false,
    int? updatedAt,
    Map<String, String>? notes,
  }) : updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch,
       notes = notes ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isChecked': isChecked,
      'updatedAt': updatedAt,
      'notes': notes,
    };
  }

  factory NameItem.fromMap(Map<String, dynamic> map) {
    Map<String, String> parsedNotes = {};
    if (map['notes'] is Map) {
      (map['notes'] as Map).forEach((k, v) {
        parsedNotes[k.toString()] = v?.toString() ?? '';
      });
    }
    return NameItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      isChecked: map['isChecked'] == true || map['is_checked'] == true,
      updatedAt: map['updatedAt'] is int
          ? map['updatedAt']
          : DateTime.now().millisecondsSinceEpoch,
      notes: parsedNotes,
    );
  }

  int get answeredQuestionsCount {
    return notes.values.where((v) => v.trim().isNotEmpty).length;
  }
}

enum FilterOption { all, unchecked, checked }

class ChecklistHomePage extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final VoidCallback? onOpenVisualisasi;
  const ChecklistHomePage({
    super.key,
    this.onBackToHome,
    this.onOpenVisualisasi,
  });

  @override
  State<ChecklistHomePage> createState() => _ChecklistHomePageState();
}

class _ChecklistHomePageState extends State<ChecklistHomePage> {
  void showRoomSettingsDialog() => _showRoomSettingsDialog();
  void filterByQuery(String query) {
    setState(() {
      _searchQuery = query;
      _searchController.text = query;
    });
  }

  List<NameItem> get items => _items;

  void loadSeedItems(List<Map<String, dynamic>> rawList) {
    _mergeIncomingItems(rawList);
    _broadcastFullList();
    setState(() {});
  }

  final List<NameItem> _items = [];
  String _searchQuery = '';
  FilterOption _currentFilter = FilterOption.all;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Realtime & Supabase States
  String _supabaseUrl = kDefaultSupabaseUrl;
  String _supabaseAnonKey = kDefaultSupabaseAnonKey;
  String _roomCode = 'INTERVIEW-1';
  bool _isRealtimeConnected = false;
  bool _isConnecting = false;
  bool _isSupabaseInitialized = false;
  RealtimeChannel? _roomChannel;
  bool _isDisposing = false;
  Timer? _reconnectTimer;
  String? _recentlyUpdatedItemId;
  DateTime? _lastBackPressTime;
  late final String _senderId =
      '${DateTime.now().microsecondsSinceEpoch}_${(1000 + (DateTime.now().millisecond * 7) % 9000)}';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  @override
  void dispose() {
    _isDisposing = true;
    _reconnectTimer?.cancel();
    _searchController.dispose();
    _roomChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _initApp() async {
    await _loadLocalSettingsAndItems();
    await _initSupabaseAndRealtime();
    await _tryRestoreFromCloudBackupIfEmpty();
    _checkForAppUpdates();
  }

  Future<void> _loadLocalSettingsAndItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _supabaseUrl = prefs.getString('supabase_url') ?? kDefaultSupabaseUrl;
      if (_supabaseUrl.isEmpty) _supabaseUrl = kDefaultSupabaseUrl;
      _supabaseAnonKey =
          prefs.getString('supabase_anon_key') ?? kDefaultSupabaseAnonKey;
      if (_supabaseAnonKey.isEmpty) _supabaseAnonKey = kDefaultSupabaseAnonKey;
      _roomCode = prefs.getString('room_code') ?? 'INTERVIEW-1';
      if (_roomCode.isEmpty) _roomCode = 'INTERVIEW-1';

      final String? rawJson = prefs.getString('checklist_items_$_roomCode');
      if (rawJson != null) {
        final List<dynamic> decoded = jsonDecode(rawJson);
        setState(() {
          _items.clear();
          for (var item in decoded) {
            if (item is Map<String, dynamic>) {
              _items.add(NameItem.fromMap(item));
            }
          }
          final cleaned = _deduplicateItems();
          if (cleaned > 0) {
            debugPrint('Cleaned $cleaned duplicate items on load');
          }
        });
        _saveLocalItems();
      } else {
        // Public source ships without private interview records.
        final seed = getOfficialSeedItems();
        setState(() {
          _items.clear();
          for (var item in seed) {
            _items.add(NameItem.fromMap(item));
          }
        });
        _saveLocalItems();
      }
    } catch (e) {
      debugPrint('Error loading items: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _deduplicateItems() {
    final Map<String, NameItem> uniqueByName = {};
    int removedCount = 0;
    for (var item in _items) {
      item.name = cleanCandidateDisplayName(item.name);
      final key = normalizeCandidateName(item.name);
      if (key.isEmpty) continue;

      if (!uniqueByName.containsKey(key)) {
        uniqueByName[key] = item;
      } else {
        removedCount++;
        final existing = uniqueByName[key]!;
        if (item.isChecked && !existing.isChecked) {
          existing.isChecked = true;
        }
        if (item.updatedAt > existing.updatedAt) {
          existing.updatedAt = item.updatedAt;
        }
        item.notes.forEach((qKey, qVal) {
          final val = qVal.trim();
          if (val.isNotEmpty) {
            final cur = existing.notes[qKey] ?? '';
            if (cur.trim().isEmpty) {
              existing.notes[qKey] = val;
            } else if (cur != val && !cur.contains(val)) {
              existing.notes[qKey] = '$cur\n$val';
            }
          }
        });
      }
    }
    _items.clear();
    _items.addAll(uniqueByName.values);
    return removedCount;
  }

  Future<void> _saveLocalItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> rawList = _items
          .map((item) => item.toMap())
          .toList();
      await prefs.setString('checklist_items_$_roomCode', jsonEncode(rawList));
      _autoBackupToCloud(silent: true);
    } catch (e) {
      debugPrint('Error saving items: $e');
    }
  }

  Future<void> _initSupabaseAndRealtime() async {
    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) return;

    try {
      if (!_isSupabaseInitialized) {
        try {
          await Supabase.initialize(
            url: _supabaseUrl,
            publishableKey: _supabaseAnonKey,
          );
          _isSupabaseInitialized = true;
        } catch (_) {
          // Might already be initialized
          _isSupabaseInitialized = true;
        }
      }

      await _connectToRoomChannel();
    } catch (e) {
      debugPrint('Supabase init error: $e');
      setState(() {
        _isRealtimeConnected = false;
      });
    }
  }

  Future<void> _connectToRoomChannel() async {
    if (!_isSupabaseInitialized) {
      await _initSupabaseAndRealtime();
      return;
    }

    if (mounted) {
      setState(() {
        _isConnecting = true;
      });
    }

    try {
      final client = Supabase.instance.client;
      if (_roomChannel != null) {
        try {
          await client.removeChannel(_roomChannel!);
        } catch (_) {
          try {
            await _roomChannel!.unsubscribe();
          } catch (_) {}
        }
        _roomChannel = null;
      }

      final channelName =
          'room_${_roomCode.toUpperCase().replaceAll(' ', '_')}';
      _roomChannel = client.channel(channelName);

      _roomChannel!
          .onBroadcast(
            event: 'item_toggle',
            callback: (payload) {
              if (payload['senderId'] == _senderId) return;
              final String id = payload['id']?.toString() ?? '';
              final String name = payload['name']?.toString() ?? '';
              final bool isChecked = payload['isChecked'] == true;
              final int updatedAt = payload['updatedAt'] is int
                  ? payload['updatedAt']
                  : DateTime.now().millisecondsSinceEpoch;
              setState(() {
                final index = _items.indexWhere(
                  (e) =>
                      (id.isNotEmpty && e.id == id) ||
                      (name.isNotEmpty &&
                          e.name.trim().toLowerCase() ==
                              name.trim().toLowerCase()),
                );
                if (index != -1) {
                  if (updatedAt >= _items[index].updatedAt) {
                    _items[index].isChecked = isChecked;
                    _items[index].updatedAt = updatedAt;
                  }
                }
              });
              _saveLocalItems();
            },
          )
          .onBroadcast(
            event: 'item_notes',
            callback: (payload) {
              if (payload['senderId'] == _senderId) return;
              final String id = payload['id']?.toString() ?? '';
              final String name = payload['name']?.toString() ?? '';
              final int updatedAt = payload['updatedAt'] is int
                  ? payload['updatedAt']
                  : DateTime.now().millisecondsSinceEpoch;
              Map<String, String> incomingNotes = {};
              if (payload['notes'] is Map) {
                (payload['notes'] as Map).forEach((k, v) {
                  incomingNotes[k.toString()] = v?.toString() ?? '';
                });
              }
              setState(() {
                final index = _items.indexWhere(
                  (e) =>
                      (id.isNotEmpty && e.id == id) ||
                      (name.isNotEmpty &&
                          e.name.trim().toLowerCase() ==
                              name.trim().toLowerCase()),
                );
                if (index != -1) {
                  final existing = _items[index];
                  incomingNotes.forEach((k, v) {
                    final val = v.trim();
                    if (val.isNotEmpty) {
                      final cur = existing.notes[k] ?? '';
                      if (cur.trim().isEmpty ||
                          updatedAt >= existing.updatedAt) {
                        existing.notes[k] = val;
                      }
                    }
                  });
                  if (updatedAt > existing.updatedAt) {
                    existing.updatedAt = updatedAt;
                  }
                }
              });
              _saveLocalItems();
            },
          )
          .onBroadcast(
            event: 'item_add',
            callback: (payload) {
              if (payload['senderId'] == _senderId) return;
              final newItem = NameItem.fromMap(payload);
              final normName = newItem.name.trim().toLowerCase();
              if (normName.isEmpty) return;

              setState(() {
                final existingIdx = _items.indexWhere(
                  (e) =>
                      e.id == newItem.id ||
                      e.name.trim().toLowerCase() == normName,
                );
                if (existingIdx == -1) {
                  _items.add(newItem);
                } else {
                  final existing = _items[existingIdx];
                  existing.name = newItem.name;
                  if (newItem.updatedAt > existing.updatedAt) {
                    existing.isChecked = newItem.isChecked;
                    existing.updatedAt = newItem.updatedAt;
                  }
                  newItem.notes.forEach((k, v) {
                    final val = v.trim();
                    if (val.isNotEmpty &&
                        (existing.notes[k] ?? '').trim().isEmpty) {
                      existing.notes[k] = val;
                    }
                  });
                }
                _deduplicateItems();
              });
              _saveLocalItems();
            },
          )
          .onBroadcast(
            event: 'item_delete',
            callback: (payload) {
              if (payload['senderId'] == _senderId) return;
              final String id = payload['id']?.toString() ?? '';
              final String name = payload['name']?.toString() ?? '';
              setState(() {
                _items.removeWhere(
                  (e) =>
                      (id.isNotEmpty && e.id == id) ||
                      (name.isNotEmpty &&
                          e.name.trim().toLowerCase() ==
                              name.trim().toLowerCase()),
                );
              });
              _saveLocalItems();
            },
          )
          .onBroadcast(
            event: 'item_reset_all',
            callback: (payload) {
              if (payload['senderId'] == _senderId) return;
              setState(() {
                for (var item in _items) {
                  item.isChecked = false;
                  item.updatedAt = DateTime.now().millisecondsSinceEpoch;
                }
              });
              _saveLocalItems();
            },
          )
          .onBroadcast(
            event: 'item_check_all',
            callback: (payload) {
              if (payload['senderId'] == _senderId) return;
              setState(() {
                for (var item in _items) {
                  item.isChecked = true;
                  item.updatedAt = DateTime.now().millisecondsSinceEpoch;
                }
              });
              _saveLocalItems();
            },
          )
          .onBroadcast(
            event: 'sync_request',
            callback: (payload) {
              if (payload['senderId'] == _senderId) return;
              if (payload['action'] == 'pull_request') {
                if (_items.isNotEmpty) {
                  _broadcastFullList();
                }
                return;
              }
              if (payload['items'] is List) {
                _mergeIncomingItems(payload['items'] as List<dynamic>);
              }
              if (_items.isNotEmpty) {
                _broadcastFullList();
              }
            },
          )
          .onBroadcast(
            event: 'sync_response',
            callback: (payload) {
              if (payload['senderId'] == _senderId) return;
              if (payload['items'] is List) {
                _mergeIncomingItems(payload['items'] as List<dynamic>);
              }
            },
          );

      _roomChannel!.subscribe((status, error) {
        if (_isDisposing || !mounted) return;
        debugPrint('Room subscribe status: $status, error: $error');
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _isRealtimeConnected =
                (status == RealtimeSubscribeStatus.subscribed);
          });
        }
        if (status == RealtimeSubscribeStatus.subscribed) {
          if (_items.isNotEmpty) {
            _broadcastFullList();
          }
          _roomChannel!.sendBroadcastMessage(
            event: 'sync_request',
            payload: {
              'senderId': _senderId,
              'action': 'pull_request',
              'hasItems': _items.isNotEmpty,
              'from': DateTime.now().toIso8601String(),
            },
          );
        } else if (status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.timedOut ||
            status == RealtimeSubscribeStatus.closed) {
          _scheduleReconnect();
        }
      });
    } catch (e) {
      debugPrint('Error connecting room: $e');
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isRealtimeConnected = false;
        });
      }
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isRealtimeConnected) {
        _connectToRoomChannel();
      }
    });
  }

  void _mergeIncomingItems(List<dynamic> incoming) {
    bool changed = false;
    setState(() {
      for (var raw in incoming) {
        if (raw is! Map<String, dynamic>) continue;
        final incomingItem = NameItem.fromMap(raw);
        final normName = incomingItem.name.trim().toLowerCase();
        if (normName.isEmpty) continue;

        final incomingNorm = normalizeCandidateName(incomingItem.name);
        final existingIdx = _items.indexWhere(
          (e) =>
              normalizeCandidateName(e.name) == incomingNorm ||
              (incomingItem.id.isNotEmpty && e.id == incomingItem.id),
        );

        if (existingIdx != -1) {
          final existing = _items[existingIdx];
          if (incomingItem.updatedAt > existing.updatedAt) {
            existing.isChecked = incomingItem.isChecked;
            existing.updatedAt = incomingItem.updatedAt;
            changed = true;
          } else if (incomingItem.isChecked && !existing.isChecked) {
            existing.isChecked = true;
            changed = true;
          }

          incomingItem.notes.forEach((qKey, qVal) {
            final val = qVal.trim();
            if (val.isNotEmpty) {
              final cur = existing.notes[qKey] ?? '';
              if (cur.trim().isEmpty) {
                existing.notes[qKey] = val;
                changed = true;
              } else if (cur != val && !cur.contains(val)) {
                existing.notes[qKey] = '$cur\n$val';
                changed = true;
              }
            }
          });
        } else {
          _items.add(incomingItem);
          changed = true;
        }
      }

      final removed = _deduplicateItems();
      if (removed > 0) changed = true;
    });

    if (changed) {
      _saveLocalItems();
    }
  }

  void _broadcastFullList() {
    if (_roomChannel != null && _isRealtimeConnected) {
      _roomChannel!.sendBroadcastMessage(
        event: 'sync_response',
        payload: {
          'senderId': _senderId,
          'items': _items.map((e) => e.toMap()).toList(),
        },
      );
    }
  }

  void _addItem(String name) {
    final trimmed = cleanCandidateDisplayName(name);
    if (trimmed.isEmpty) return;

    final norm = normalizeCandidateName(trimmed);
    if (_items.any((e) => normalizeCandidateName(e.name) == norm)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nama "$trimmed" sudah ada di daftar!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newItem = NameItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmed,
      isChecked: false,
    );
    setState(() {
      _items.add(newItem);
    });
    _saveLocalItems();

    // Broadcast Realtime
    if (_isRealtimeConnected && _roomChannel != null) {
      _roomChannel!.sendBroadcastMessage(
        event: 'item_add',
        payload: {...newItem.toMap(), 'senderId': _senderId},
      );
    }
  }

  void _addBulkItems(String text) {
    final lines = text.split(RegExp(r'[\n,;]+'));
    int added = 0;
    int duplicatesSkipped = 0;
    setState(() {
      for (var line in lines) {
        final trimmed = cleanCandidateDisplayName(line);
        if (trimmed.isNotEmpty) {
          final norm = normalizeCandidateName(trimmed);
          if (_items.any((e) => normalizeCandidateName(e.name) == norm)) {
            duplicatesSkipped++;
            continue;
          }
          final item = NameItem(
            id: (DateTime.now().millisecondsSinceEpoch + added).toString(),
            name: trimmed,
            isChecked: false,
          );
          _items.add(item);
          if (_isRealtimeConnected && _roomChannel != null) {
            _roomChannel!.sendBroadcastMessage(
              event: 'item_add',
              payload: {...item.toMap(), 'senderId': _senderId},
            );
          }
          added++;
        }
      }
      _deduplicateItems();
    });
    _saveLocalItems();

    if (mounted) {
      if (added > 0) {
        String msg = '$added nama berhasil ditambahkan & disinkronkan!';
        if (duplicatesSkipped > 0) {
          msg += ' ($duplicatesSkipped nama duplikat dilewati)';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
      } else if (duplicatesSkipped > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Semua nama ($duplicatesSkipped) sudah ada di daftar.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleItem(NameItem item) {
    setState(() {
      item.isChecked = !item.isChecked;
      item.updatedAt = DateTime.now().millisecondsSinceEpoch;
    });
    _saveLocalItems();

    // Broadcast Realtime
    if (_isRealtimeConnected && _roomChannel != null) {
      _roomChannel!.sendBroadcastMessage(
        event: 'item_toggle',
        payload: {
          'id': item.id,
          'name': item.name,
          'isChecked': item.isChecked,
          'updatedAt': item.updatedAt,
          'senderId': _senderId,
        },
      );
    }
  }

  void _deleteItem(NameItem item) {
    setState(() {
      _items.removeWhere(
        (element) =>
            element.id == item.id ||
            element.name.trim().toLowerCase() == item.name.trim().toLowerCase(),
      );
    });
    _saveLocalItems();

    // Broadcast Realtime
    if (_isRealtimeConnected && _roomChannel != null) {
      _roomChannel!.sendBroadcastMessage(
        event: 'item_delete',
        payload: {'id': item.id, 'name': item.name, 'senderId': _senderId},
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${item.name}" dihapus'),
        action: SnackBarAction(
          label: 'Batal',
          onPressed: () {
            _addItem(item.name);
          },
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetAllCheckboxes() {
    if (_items.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Checklist?'),
        content: const Text(
          'Semua tanda centang di semua perangkat yang terhubung akan di-reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                for (var item in _items) {
                  item.isChecked = false;
                  item.updatedAt = DateTime.now().millisecondsSinceEpoch;
                }
              });
              _saveLocalItems();

              if (_isRealtimeConnected && _roomChannel != null) {
                _roomChannel!.sendBroadcastMessage(
                  event: 'item_reset_all',
                  payload: {'senderId': _senderId},
                );
              }

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua checklist berhasil di-reset'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _checkAll() {
    if (_items.isEmpty) return;
    setState(() {
      for (var item in _items) {
        item.isChecked = true;
        item.updatedAt = DateTime.now().millisecondsSinceEpoch;
      }
    });
    _saveLocalItems();

    if (_isRealtimeConnected && _roomChannel != null) {
      _roomChannel!.sendBroadcastMessage(
        event: 'item_check_all',
        payload: {'senderId': _senderId},
      );
    }
  }

  void _clearAllItems() {
    if (_items.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Nama?'),
        content: const Text(
          'Seluruh daftar nama di ruangan ini akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _items.clear();
              });
              _saveLocalItems();
              _broadcastFullList();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua nama telah dihapus'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  void _copySummary() {
    if (_items.isEmpty) return;
    final int checkedCount = _items.where((e) => e.isChecked).length;
    final buffer = StringBuffer();
    buffer.writeln('=== REKAP CHECKLIST NAMA (RUANG: $_roomCode) ===');
    buffer.writeln(
      'Total: ${_items.length} | Sudah: $checkedCount | Belum: ${_items.length - checkedCount}\n',
    );
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final status = item.isChecked ? '[V]' : '[ ]';
      buffer.writeln('${i + 1}. $status ${item.name}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rekap teks checklist berhasil disalin ke Clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyFullInterviewRecap() {
    if (_items.isEmpty) return;
    final int withNotesCount = _items
        .where((e) => e.answeredQuestionsCount > 0)
        .length;
    final buffer = StringBuffer();
    buffer.writeln('=== REKAP LENGKAP HASIL WAWANCARA PMK ===');
    buffer.writeln('Ruang: $_roomCode');
    buffer.writeln(
      'Total Peserta: ${_items.length} | Terdata Catatan: $withNotesCount\n',
    );

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final status = item.isChecked ? '[SUDAH WAWANCARA]' : '[BELUM]';
      buffer.writeln('--------------------------------------------------');
      buffer.writeln('${i + 1}. ${item.name} - $status');
      if (item.notes.isEmpty || item.answeredQuestionsCount == 0) {
        buffer.writeln('(Belum ada catatan wawancara)');
      } else {
        for (int q = 0; q < kInterviewQuestions.length; q++) {
          final question = kInterviewQuestions[q];
          final answer = item.notes[question]?.trim();
          if (answer != null && answer.isNotEmpty) {
            buffer.writeln('• $question');
            buffer.writeln('  👉 $answer');
          }
        }
      }
      buffer.writeln('');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rekap Lengkap Catatan Wawancara berhasil disalin!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveItemNotes(NameItem item, Map<String, String> newNotes) {
    setState(() {
      item.notes = newNotes;
      item.updatedAt = DateTime.now().millisecondsSinceEpoch;
    });
    _saveLocalItems();

    if (_isRealtimeConnected && _roomChannel != null) {
      _roomChannel!.sendBroadcastMessage(
        event: 'item_notes',
        payload: {
          'id': item.id,
          'name': item.name,
          'notes': item.notes,
          'updatedAt': item.updatedAt,
          'senderId': _senderId,
        },
      );
    }
  }

  Future<void> _autoBackupToCloud({bool silent = true}) async {
    if (_items.isEmpty) return;
    try {
      final client = Supabase.instance.client;
      final jsonStr = jsonEncode({
        'room_code': _roomCode,
        'backup_time': DateTime.now().toIso8601String(),
        'total_candidates': _items.length,
        'checked_count': _items.where((e) => e.isChecked).length,
        'items': _items.map((e) => e.toMap()).toList(),
      });
      final jsonBytes = utf8.encode(jsonStr);
      await client.storage
          .from('interview_backups')
          .uploadBinary(
            'backup_$_roomCode.json',
            jsonBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final csvStr = _generateCsvString();
      final csvBytes = utf8.encode(csvStr);
      await client.storage
          .from('interview_backups')
          .uploadBinary(
            'rekap_$_roomCode.csv',
            csvBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data berhasil dicadangkan ke Cloud Database! (${_items.length} peserta)',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Cloud backup error: $e');
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencadangkan ke cloud: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _restoreFromCloudBackup() async {
    try {
      final client = Supabase.instance.client;
      final bytes = await client.storage
          .from('interview_backups')
          .download('backup_$_roomCode.json');
      final content = utf8.decode(bytes);
      final Map<String, dynamic> data = jsonDecode(content);
      if (data['items'] is List) {
        _mergeIncomingItems(data['items'] as List<dynamic>);
        _broadcastFullList();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Berhasil memulihkan data dari Cloud! (${_items.length} peserta)',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Restore error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Belum ada cadangan di cloud atau gagal memulihkan: $e',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _tryRestoreFromCloudBackupIfEmpty() async {
    try {
      final client = Supabase.instance.client;
      final bytes = await client.storage
          .from('interview_backups')
          .download('backup_$_roomCode.json');
      final content = utf8.decode(bytes);
      final Map<String, dynamic> data = jsonDecode(content);
      if (data['items'] is List && (data['items'] as List).isNotEmpty) {
        setState(() {
          _items.removeWhere(
            (e) =>
                e.name == 'Ahmad Fauzi' ||
                e.name == 'Budi Santoso' ||
                e.name == 'Citra Dewi' ||
                e.name == 'Doni Pratama',
          );
        });
        _mergeIncomingItems(data['items'] as List<dynamic>);
        debugPrint('Auto-restored from cloud backup!');
      }
    } catch (e) {
      debugPrint('No cloud backup found: $e');
    }
  }

  String _generateCsvString() {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    final headers = [
      'No',
      'Nama Peserta',
      'Status Wawancara',
      'Terakhir Diperbarui',
      ...kInterviewQuestions,
    ];
    buffer.writeln(headers.map(_csvEscape).join(','));

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final dt = DateTime.fromMillisecondsSinceEpoch(item.updatedAt);
      final dtStr =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      final row = [
        (i + 1).toString(),
        item.name,
        item.isChecked ? 'SUDAH WAWANCARA' : 'BELUM',
        dtStr,
        ...kInterviewQuestions.map((q) => item.notes[q] ?? ''),
      ];
      buffer.writeln(row.map(_csvEscape).join(','));
    }
    return buffer.toString();
  }

  String _csvEscape(String text) {
    if (text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  Future<List<int>> _generateExcelBytes() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Rekap Wawancara'];
    excel.setDefaultSheet('Rekap Wawancara');
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final headers = [
      'No',
      'Nama Peserta',
      'Status Wawancara',
      'Terakhir Diperbarui',
      ...kInterviewQuestions,
    ];
    sheet.appendRow(headers.map((h) => xl.TextCellValue(h)).toList());

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final dt = DateTime.fromMillisecondsSinceEpoch(item.updatedAt);
      final dtStr =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

      final row = <xl.CellValue>[
        xl.IntCellValue(i + 1),
        xl.TextCellValue(item.name),
        xl.TextCellValue(item.isChecked ? 'SUDAH WAWANCARA' : 'BELUM'),
        xl.TextCellValue(dtStr),
        ...kInterviewQuestions.map(
          (q) => xl.TextCellValue(item.notes[q] ?? ''),
        ),
      ];
      sheet.appendRow(row);
    }

    return excel.encode() ?? [];
  }

  Future<void> _exportAndShareExcel() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daftar peserta masih kosong!')),
      );
      return;
    }
    try {
      final bytes = await _generateExcelBytes();
      final nowStr = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Rekap_Wawancara_${_roomCode}_$nowStr.xlsx';
      await downloadFile(
        bytes,
        fileName,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File Excel "$fileName" berhasil diunduh / dibagikan!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Export Excel error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat file Excel: $e')));
      }
    }
  }

  Future<void> _exportAndShareCsv() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daftar peserta masih kosong!')),
      );
      return;
    }
    try {
      final csvString = _generateCsvString();
      final bytes = utf8.encode(csvString);
      final nowStr = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Rekap_Wawancara_${_roomCode}_$nowStr.csv';
      await downloadFile(bytes, fileName, 'text/csv');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File CSV "$fileName" berhasil diunduh / dibagikan!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Export CSV error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat file CSV: $e')));
      }
    }
  }

  void _copyCsvToClipboard() {
    if (_items.isEmpty) return;
    final csv = _generateCsvString();
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Teks format CSV disalin! Bisa langsung di-paste ke Google Sheets / Excel.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showExportAndBackupDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.file_download,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ekspor, Unduh & Cadangan Data',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Format Excel (.xlsx), CSV, dan Cloud Backup',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF107C41),
                      child: Icon(
                        Icons.table_view,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Unduh File Excel (.xlsx)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Format spreadsheet Microsoft Excel asli dengan seluruh soal & jawaban.',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _exportAndShareExcel();
                    },
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade700,
                      child: const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Unduh File CSV (.csv)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Kompatibel dengan Google Sheets, Excel, WPS Office, dan LibreOffice.',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _exportAndShareCsv();
                    },
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.shade800,
                      child: const Icon(
                        Icons.copy_all,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: const Text('Salin Format CSV ke Clipboard'),
                    subtitle: const Text(
                      'Bisa langsung di-paste ke Google Sheets / Excel di komputer.',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _copyCsvToClipboard();
                    },
                  ),
                  const Divider(height: 16),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade700,
                      child: const Icon(
                        Icons.cloud_upload,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: const Text('Cadangkan Data ke Cloud Sekarang'),
                    subtitle: const Text(
                      'Simpan salinan data lengkap ke Cloud Storage Supabase.',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _autoBackupToCloud(silent: false);
                    },
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepOrange.shade700,
                      child: const Icon(
                        Icons.cloud_download,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: const Text('Pulihkan Data dari Cloud (Restore)'),
                    subtitle: const Text(
                      'Ambil cadangan terakhir yang tersimpan di cloud ruangan ini.',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _restoreFromCloudBackup();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkForAppUpdates({bool manual = false}) async {
    try {
      final bytes = await Supabase.instance.client.storage
          .from('app_updates')
          .download('version.json');
      final content = utf8.decode(bytes);
      final Map<String, dynamic> data = jsonDecode(content);
      final int remoteBuild = data['build_number'] ?? 0;
      final String remoteVersion = data['version'] ?? '';
      final String notes = data['notes'] ?? 'Pembaruan aplikasi tersedia.';
      final String apkUrl =
          data['apk_url'] ??
          'https://xnbiaaxwltofdiklxhnw.supabase.co/storage/v1/object/public/app_updates/List_Interview.apk';

      if (remoteBuild > kAppBuildNumber && mounted) {
        _showUpdateDialog(remoteVersion, notes, apkUrl);
      } else if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aplikasi sudah versi terbaru (v$kAppVersionName)!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Check update error: $e');
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal memeriksa pembaruan. Pastikan internet aktif.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showUpdateDialog(String version, String notes, String apkUrl) {
    bool isDownloading = false;
    double progress = 0.0;
    String statusText = '';
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dContext, setDialogState) {
          Future<void> startDownload() async {
            if (kIsWeb) {
              launchUrl(
                Uri.parse(apkUrl),
                mode: LaunchMode.externalApplication,
              );
              return;
            }

            setDialogState(() {
              isDownloading = true;
              progress = 0.0;
              statusText = 'Menghubungkan ke server unduhan...';
              errorMessage = null;
            });

            try {
              final client = HttpClient();
              final request = await client.getUrl(Uri.parse(apkUrl));
              final response = await request.close();

              if (response.statusCode != 200) {
                throw Exception(
                  'Server mengembalikan status HTTP ${response.statusCode}',
                );
              }

              final totalBytes = response.contentLength;
              final tempDir = await getTemporaryDirectory();
              final savePath = '${tempDir.path}/update_v$version.apk';
              final file = File(savePath);
              if (await file.exists()) {
                await file.delete();
              }
              final sink = file.openWrite();

              int receivedBytes = 0;
              await for (var chunk in response) {
                sink.add(chunk);
                receivedBytes += chunk.length;
                if (totalBytes > 0) {
                  final curProg = receivedBytes / totalBytes;
                  final curMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(
                    1,
                  );
                  final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(
                    1,
                  );
                  setDialogState(() {
                    progress = curProg;
                    statusText =
                        'Mengunduh: ${(curProg * 100).toInt()}% ($curMb MB / $totalMb MB)';
                  });
                }
              }

              await sink.flush();
              await sink.close();

              setDialogState(() {
                progress = 1.0;
                statusText = 'Unduhan selesai! Membuka penginstal Android...';
              });

              final openResult = await OpenFilex.open(
                savePath,
                type: 'application/vnd.android.package-archive',
              );

              if (openResult.type != ResultType.done) {
                setDialogState(() {
                  errorMessage =
                      'Buka penginstal otomatis: ${openResult.message}. Silakan pasang dari folder Unduhan HP atau buka di browser.';
                });
              }
            } catch (e) {
              setDialogState(() {
                isDownloading = false;
                errorMessage = 'Gagal mengunduh langsung: $e';
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update, color: Colors.teal),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Pembaruan Aplikasi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Versi Baru v$version Tersedia',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(notes, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  if (isDownloading) ...[
                    LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!isDownloading) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '💡 Tautan unduh APK manual (buka di Chrome):',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            apkUrl,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!isDownloading)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Nanti Saja'),
                ),
              if (!isDownloading)
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: apkUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tautan unduhan berhasil disalin!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Salin Link'),
                ),
              FilledButton.icon(
                onPressed: isDownloading ? null : startDownload,
                icon: const Icon(Icons.download),
                label: Text(
                  isDownloading ? 'Mengunduh...' : 'Perbarui Sekarang',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInterviewNotesSheet(NameItem item) {
    final Map<String, TextEditingController> controllers = {};
    for (var q in kInterviewQuestions) {
      controllers[q] = TextEditingController(text: item.notes[q] ?? '');
    }

    final initialNotes = Map<String, String>.from(item.notes);
    Timer? autoSaveDebounce;
    String saveStatus = 'Tersimpan';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void saveDraft({bool syncToCloud = false}) {
              final Map<String, String> currentNotes = {};
              for (var entry in controllers.entries) {
                currentNotes[entry.key] = entry.value.text.trim();
              }
              if (syncToCloud) {
                _saveItemNotes(item, currentNotes);
              } else {
                setState(() {
                  item.notes = currentNotes;
                  item.updatedAt = DateTime.now().millisecondsSinceEpoch;
                });
                _saveLocalItems();
              }
            }

            void onFieldChanged() {
              setSheetState(() {
                saveStatus = 'Menyimpan...';
              });
              autoSaveDebounce?.cancel();
              autoSaveDebounce = Timer(const Duration(milliseconds: 500), () {
                saveDraft(syncToCloud: false);
                setSheetState(() {
                  saveStatus = '✓ Tersimpan';
                });
              });
            }

            Future<bool> handleConfirmExit() async {
              autoSaveDebounce?.cancel();
              bool hasChanges = false;
              for (var q in kInterviewQuestions) {
                if ((controllers[q]?.text.trim() ?? '') !=
                    (initialNotes[q] ?? '')) {
                  hasChanges = true;
                  break;
                }
              }

              if (!hasChanges) {
                return true;
              }

              final messenger = ScaffoldMessenger.of(context);
              final result = await showDialog<String>(
                context: context,
                builder: (dCtx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade900,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Simpan Catatan?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'Anda sedang mengisi catatan wawancara untuk "${item.name}".\n\nCatatan draf sudah aman tersimpan di perangkat ini. Ingin menyimpan dan menyinkronkannya sekarang?',
                    style: const TextStyle(fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dCtx, 'cancel'),
                      child: const Text('Lanjut Mengisi'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dCtx, 'discard'),
                      child: Text(
                        'Buang Perubahan',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(dCtx, 'save'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Simpan & Keluar'),
                    ),
                  ],
                ),
              );

              if (result == 'save') {
                saveDraft(syncToCloud: true);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Catatan "${item.name}" disimpan & disinkronkan!',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return true;
              } else if (result == 'discard') {
                item.notes = Map<String, String>.from(initialNotes);
                _saveLocalItems();
                return true;
              }
              return false;
            }

            int answeredCount = controllers.values
                .where((c) => c.text.trim().isNotEmpty)
                .length;

            final currentIndex = _items.indexWhere((it) => it.id == item.id);
            final NameItem? nextCandidate =
                (currentIndex >= 0 && currentIndex < _items.length - 1)
                ? _items[currentIndex + 1]
                : null;

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                final shouldPop = await handleConfirmExit();
                if (shouldPop && ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        'Catatan PMK • $answeredCount/${kInterviewQuestions.length} Terisi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: saveStatus.contains('✓')
                                              ? Colors.green.shade50
                                              : Colors.teal.shade50,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: saveStatus.contains('✓')
                                                ? Colors.green.shade300
                                                : Colors.teal.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          saveStatus,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: saveStatus.contains('✓')
                                                ? Colors.green.shade800
                                                : Colors.teal.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Tutup',
                              onPressed: () async {
                                final shouldPop = await handleConfirmExit();
                                if (shouldPop && ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            Card(
                              color: item.isChecked
                                  ? Colors.green.shade50
                                  : null,
                              child: CheckboxListTile(
                                value: item.isChecked,
                                activeColor: Colors.green,
                                title: Text(
                                  item.isChecked
                                      ? 'Status: Sudah Wawancara'
                                      : 'Status: Belum Wawancara',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: item.isChecked
                                        ? Colors.green.shade800
                                        : null,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Centang jika wawancara peserta ini telah selesai',
                                ),
                                onChanged: (val) {
                                  setSheetState(() {
                                    _toggleItem(item);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 12),

                            _buildQuestionCard(
                              questionNumber: 1,
                              question: 'Pengalaman di PMK?',
                              hint:
                                  'Divisi, kepanitiaan, atau peran selama di PMK...',
                              controller: controllers['Pengalaman di PMK?']!,
                              onChanged: onFieldChanged,
                            ),

                            _buildQuestionCard(
                              questionNumber: 2,
                              question:
                                  'Apa yang perlu diperbaiki (PMK dan Proker)?',
                              hint:
                                  'Kekurangan, hal yang perlu dievaluasi di PMK & proker...',
                              controller:
                                  controllers['Apa yang perlu diperbaiki (PMK dan Proker)?']!,
                              onChanged: onFieldChanged,
                            ),

                            _buildQuestionCard(
                              questionNumber: 3,
                              question: 'Paling enak ajak kerjasama?',
                              hint:
                                  'Nama rekan yang komunikatif, solid, dan saling dukung...',
                              controller:
                                  controllers['Paling enak ajak kerjasama?']!,
                              onChanged: onFieldChanged,
                            ),

                            _buildQuestionCard(
                              questionNumber: 4,
                              question: 'Paling ga enak?',
                              hint:
                                  'Nama atau kendala karakter dalam kerja sama...',
                              controller: controllers['Paling ga enak?']!,
                              onChanged: onFieldChanged,
                            ),

                            _buildQuestionCard(
                              questionNumber: 5,
                              question:
                                  'Lanjut jadi pengururs? Kalau ngga, kenapa & kesibukan apa?',
                              hint:
                                  'Alasan, kesibukan kuliah/skripsi/organisasi lain...',
                              controller:
                                  controllers['Lanjut jadi pengururs? Kalau ngga, kenapa & kesibukan apa?']!,
                              chips: [
                                'Lanjut',
                                'Tidak Lanjut',
                                'Masih Ragu-ragu',
                              ],
                              onChanged: onFieldChanged,
                            ),

                            _buildQuestionCard(
                              questionNumber: 6,
                              question: 'Top 5 nama cocok?',
                              hint: '1. ...\n2. ...\n3. ...\n4. ...\n5. ...',
                              controller: controllers['Top 5 nama cocok?']!,
                              maxLines: 4,
                              onChanged: onFieldChanged,
                            ),

                            _buildQuestionCard(
                              questionNumber: 7,
                              question:
                                  'Apakah bersedia kalau menjadi calon ketua?',
                              hint:
                                  'Tanggapan, komitmen, atau catatan khusus calon...',
                              controller:
                                  controllers['Apakah bersedia kalau menjadi calon ketua?']!,
                              chips: [
                                'Bersedia',
                                'Bersedia jika dipercaya',
                                'Perlu Doa/Pikirkan',
                                'Tidak Bersedia',
                              ],
                              onChanged: onFieldChanged,
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              offset: const Offset(0, -2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  final buffer = StringBuffer();
                                  buffer.writeln(
                                    '📋 HASIL WAWANCARA: ${item.name}',
                                  );
                                  buffer.writeln(
                                    'Status: ${item.isChecked ? "SUDAH WAWANCARA" : "BELUM"}',
                                  );
                                  buffer.writeln('');
                                  for (var q in kInterviewQuestions) {
                                    final ans = controllers[q]?.text.trim();
                                    buffer.writeln('• $q');
                                    buffer.writeln(
                                      '  👉 ${ans != null && ans.isNotEmpty ? ans : "-"}',
                                    );
                                    buffer.writeln('');
                                  }
                                  Clipboard.setData(
                                    ClipboardData(text: buffer.toString()),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Catatan wawancara ${item.name} berhasil disalin!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('Salin'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    saveDraft(syncToCloud: true);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Catatan "${item.name}" disimpan & disinkronkan!',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.check),
                                  label: const Text('Simpan'),
                                ),
                              ),
                              if (nextCandidate != null) ...[
                                const SizedBox(width: 8),
                                FilledButton.tonalIcon(
                                  onPressed: () {
                                    saveDraft(syncToCloud: true);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Catatan "${item.name}" tersimpan! Beralih ke ${nextCandidate.name}...',
                                        ),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    _showInterviewNotesSheet(nextCandidate);
                                  },
                                  icon: const Icon(Icons.skip_next),
                                  label: const Text('Lanjut'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuestionCard({
    required int questionNumber,
    required String question,
    required String hint,
    required TextEditingController controller,
    required VoidCallback onChanged,
    List<String>? chips,
    int maxLines = 3,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$questionNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (chips != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: chips.map((chipText) {
                  final isSelected = controller.text.contains(chipText);
                  return ActionChip(
                    label: Text(chipText, style: const TextStyle(fontSize: 11)),
                    backgroundColor: isSelected ? Colors.teal.shade100 : null,
                    side: isSelected
                        ? const BorderSide(color: Colors.teal)
                        : null,
                    onPressed: () {
                      if (controller.text.isEmpty) {
                        controller.text = chipText;
                      } else if (!controller.text.contains(chipText)) {
                        controller.text = '$chipText - ${controller.text}';
                      }
                      onChanged();
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: maxLines,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                isDense: true,
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDanielsAppDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/logo_pmk.png',
                width: 36,
                height: 36,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.church, color: Color(0xFF00796B)),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Daniels App',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Versi 1.2.0 (Build 6)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aplikasi resmi PMK Daniel FILKOM Universitas Brawijaya untuk menunjang kegiatan pelayanan dan operasional organisasi.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF00796B),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Fitur #1: List Interview',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF00796B),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Checklist kandidat, sinkronisasi realtime multi-pewawancara via Supabase, pencatatan 7 soal evaluasi, dan ekspor Excel/CSV.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showRoomSettingsDialog() {
    final roomController = TextEditingController(text: _roomCode);
    final urlController = TextEditingController(text: _supabaseUrl);
    final keyController = TextEditingController(text: _supabaseAnonKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_tethering, color: Colors.teal),
            SizedBox(width: 8),
            Text('Koneksi Multi-User'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perangkat dengan Kode Ruangan yang sama akan tersinkronisasi secara Realtime otomatis.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: roomController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Kode Ruangan (Room Code)',
                  hintText: 'Contoh: INTERVIEW-1, PANITIA',
                  prefixIcon: Icon(Icons.meeting_room),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Konfigurasi Cloud Backend (Supabase):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Supabase URL',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: keyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Supabase Anon Key',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () async {
              final newRoom = roomController.text.trim().toUpperCase();
              final targetRoom = newRoom.isEmpty ? 'INTERVIEW-1' : newRoom;
              final newUrl = urlController.text.trim().isEmpty
                  ? kDefaultSupabaseUrl
                  : urlController.text.trim();
              final newKey = keyController.text.trim().isEmpty
                  ? kDefaultSupabaseAnonKey
                  : keyController.text.trim();

              Navigator.pop(ctx);

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('room_code', targetRoom);
              await prefs.setString('supabase_url', newUrl);
              await prefs.setString('supabase_anon_key', newKey);

              if (!mounted) return;
              setState(() {
                _roomCode = targetRoom;
                _supabaseUrl = newUrl;
                _supabaseAnonKey = newKey;
              });

              await _loadLocalSettingsAndItems();
              await _initSupabaseAndRealtime();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Berpindah ke Ruangan: $_roomCode'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Simpan & Hubungkan'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final singleController = TextEditingController();
    final bulkController = TextEditingController();
    bool isBulkMode = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBulkMode ? 'Tambah Banyak Nama' : 'Tambah Satu Nama',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            isBulkMode = !isBulkMode;
                          });
                        },
                        icon: Icon(isBulkMode ? Icons.person : Icons.group_add),
                        label: Text(isBulkMode ? 'Mode Satuan' : 'Mode Banyak'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!isBulkMode)
                    TextField(
                      controller: singleController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        hintText: 'Contoh: Rina Melati',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          _addItem(val);
                          Navigator.pop(ctx);
                        }
                      },
                    )
                  else
                    TextField(
                      controller: bulkController,
                      autofocus: true,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Tempel / Ketik Banyak Nama',
                        hintText:
                            'Pisahkan dengan baris baru atau koma.\nContoh:\nBudi Santoso\nSiti Rahma\nAgus Wijaya',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      if (!isBulkMode) {
                        if (singleController.text.trim().isNotEmpty) {
                          _addItem(singleController.text);
                          Navigator.pop(ctx);
                        }
                      } else {
                        if (bulkController.text.trim().isNotEmpty) {
                          _addBulkItems(bulkController.text);
                          Navigator.pop(ctx);
                        }
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Simpan & Bagikan ke Tim'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(NameItem item) {
    final editController = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Nama'),
        content: TextField(
          controller: editController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  item.name = newName;
                  item.updatedAt = DateTime.now().millisecondsSinceEpoch;
                });
                _deduplicateItems();
                _saveLocalItems();
                if (_isRealtimeConnected && _roomChannel != null) {
                  _roomChannel!.sendBroadcastMessage(
                    event: 'item_add',
                    payload: {...item.toMap(), 'senderId': _senderId},
                  );
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  List<NameItem> get _filteredItems {
    return _items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      if (!matchesSearch) return false;

      switch (_currentFilter) {
        case FilterOption.checked:
          return item.isChecked;
        case FilterOption.unchecked:
          return !item.isChecked;
        case FilterOption.all:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCount = _items.length;
    final checkedCount = _items.where((e) => e.isChecked).length;
    final uncheckedCount = totalCount - checkedCount;
    final double progress = totalCount == 0 ? 0.0 : checkedCount / totalCount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.onBackToHome != null) {
          widget.onBackToHome!();
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tekan sekali lagi untuk keluar dari aplikasi'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo_pmk.png',
                          width: 48,
                          height: 48,
                          errorBuilder: (ctx, err, st) => const Icon(
                            Icons.church,
                            size: 40,
                            color: Color(0xFF00796B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Daniels App',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'PMK Daniel FILKOM UB',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'FITUR AKTIF',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.assignment_turned_in,
                  color: theme.colorScheme.primary,
                ),
                title: const Text(
                  'List Interview',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Fitur #1 • Wawancara & Realtime Sync',
                  style: TextStyle(fontSize: 11),
                ),
                selected: true,
                selectedTileColor: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.35),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFFD97706),
                ),
                title: const Text(
                  'Visualisasi & Matriks',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Fitur #2 • Matriks 23x23 & Bursa Calon Ketua',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onOpenVisualisasi != null) {
                    widget.onOpenVisualisasi!();
                  }
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'FITUR MENDATANG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.how_to_reg_outlined,
                  color: Colors.grey,
                ),
                title: const Text(
                  'Presensi Kegiatan PMK',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Segera',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Fitur Presensi Kegiatan akan hadir pada rilis berikutnya.',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.campaign_outlined,
                  color: Colors.grey,
                ),
                title: const Text(
                  'Warta & Jadwal Ibadah',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Segera',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Fitur Warta & Jadwal akan terhubung langsung ke website PMK Daniel.',
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.wifi_tethering),
                title: const Text('Koneksi Ruang Cloud'),
                onTap: () {
                  Navigator.pop(context);
                  _showRoomSettingsDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Tentang Daniels App'),
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDanielsAppDialog();
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          leading: widget.onBackToHome != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Kembali ke Beranda',
                  onPressed: widget.onBackToHome,
                )
              : null,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo_pmk.png',
                    width: 30,
                    height: 30,
                    errorBuilder: (ctx, err, st) => const Icon(
                      Icons.church,
                      size: 24,
                      color: Color(0xFF00796B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Daniels App',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'List Interview',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        if (!_isRealtimeConnected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Menghubungkan ke Realtime Cloud...',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          _connectToRoomChannel();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Realtime Aktif! Terhubung ke Ruangan: $_roomCode',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRealtimeConnected
                                  ? Colors.greenAccent
                                  : (_isConnecting
                                        ? Colors.amber
                                        : Colors.orange),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              _isRealtimeConnected
                                  ? 'Online ($_roomCode)'
                                  : (_isConnecting
                                        ? 'Menghubungkan... ($_roomCode)'
                                        : 'Offline ($_roomCode) • Sambungkan'),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                decoration: _isRealtimeConnected
                                    ? null
                                    : TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isRealtimeConnected ? Icons.cloud_done : Icons.cloud_queue,
                color: _isRealtimeConnected ? Colors.green : null,
              ),
              tooltip: 'Koneksi Multi-User / Ganti Ruang',
              onPressed: _showRoomSettingsDialog,
            ),
            IconButton(
              icon: const Icon(
                Icons.insights_rounded,
                color: Color(0xFFD97706),
              ),
              tooltip: 'Visualisasi & Matriks Regenerasi',
              onPressed: () {
                if (widget.onOpenVisualisasi != null) {
                  widget.onOpenVisualisasi!();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Salin Rekap Teks',
              onPressed: _copySummary,
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Unduh Excel / CSV & Cadangan',
              onPressed: _showExportAndBackupDialog,
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'open_visualisasi') {
                  if (widget.onOpenVisualisasi != null)
                    widget.onOpenVisualisasi!();
                }
                if (val == 'load_official') {
                  loadSeedItems(getOfficialSeedItems());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Data awal pribadi tidak disertakan. Impor cadangan milikmu.',
                      ),
                    ),
                  );
                }
                if (val == 'export_backup') _showExportAndBackupDialog();
                if (val == 'cloud_backup') _autoBackupToCloud(silent: false);
                if (val == 'cloud_restore') _restoreFromCloudBackup();
                if (val == 'reset') _resetAllCheckboxes();
                if (val == 'check_all') _checkAll();
                if (val == 'sort_asc') {
                  setState(() {
                    _items.sort(
                      (a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                    );
                  });
                  _saveLocalItems();
                }
                if (val == 'sort_desc') {
                  setState(() {
                    _items.sort(
                      (a, b) =>
                          b.name.toLowerCase().compareTo(a.name.toLowerCase()),
                    );
                  });
                  _saveLocalItems();
                }
                if (val == 'clean_duplicates') {
                  setState(() {
                    final removed = _deduplicateItems();
                    _saveLocalItems();
                    if (removed > 0) {
                      _broadcastFullList();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$removed nama duplikat berhasil dibersihkan!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Daftar sudah bersih, tidak ada nama ganda.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  });
                }
                if (val == 'copy_full_notes') _copyFullInterviewRecap();
                if (val == 'check_update') _checkForAppUpdates(manual: true);
                if (val == 'settings') _showRoomSettingsDialog();
                if (val == 'about_app') _showAboutDanielsAppDialog();
                if (val == 'clear') _clearAllItems();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'open_visualisasi',
                  child: Row(
                    children: [
                      Icon(Icons.insights, size: 20, color: Color(0xFFD97706)),
                      SizedBox(width: 8),
                      Text(
                        'Buka Visualisasi & Matriks',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'load_official',
                  child: Row(
                    children: [
                      Icon(Icons.sync, size: 20, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Periksa data awal'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'export_backup',
                  child: Row(
                    children: [
                      Icon(
                        Icons.table_chart,
                        size: 20,
                        color: Color(0xFF107C41),
                      ),
                      SizedBox(width: 8),
                      Text('Unduh Excel (.xlsx) / CSV'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cloud_backup',
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 20,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 8),
                      Text('Cadangkan ke Cloud (Backup)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cloud_restore',
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_download_outlined,
                        size: 20,
                        color: Colors.deepOrange,
                      ),
                      SizedBox(width: 8),
                      Text('Pulihkan dari Cloud (Restore)'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'clean_duplicates',
                  child: Row(
                    children: [
                      Icon(
                        Icons.cleaning_services,
                        size: 20,
                        color: Colors.teal,
                      ),
                      SizedBox(width: 8),
                      Text('Bersihkan Duplikat'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy_full_notes',
                  child: Row(
                    children: [
                      Icon(Icons.assignment, size: 20, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Salin Rekap Catatan Lengkap'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.restart_alt, size: 20),
                      SizedBox(width: 8),
                      Text('Reset Semua Centang'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'check_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 8),
                      Text('Centang Semua'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'sort_asc',
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha, size: 20),
                      SizedBox(width: 8),
                      Text('Urutkan A - Z'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'sort_desc',
                  child: Row(
                    children: [
                      Icon(Icons.sort, size: 20),
                      SizedBox(width: 8),
                      Text('Urutkan Z - A'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'check_update',
                  child: Row(
                    children: [
                      Icon(Icons.system_update, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Periksa Pembaruan App'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Pengaturan Ruang'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'about_app',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Tentang Daniels App'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Hapus Semua Nama',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (!_isRealtimeConnected)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isConnecting ? Icons.sync : Icons.cloud_off,
                            size: 18,
                            color: Colors.orange.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isConnecting
                                  ? 'Sedang menghubungkan ke server...'
                                  : 'Offline. Perubahan disimpan lokal di HP.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (!_isConnecting)
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: _connectToRoomChannel,
                              child: const Text(
                                'Hubungkan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Header Stats Card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  'Total',
                                  '$totalCount',
                                  Icons.people_outline,
                                  Colors.blueGrey,
                                ),
                                _buildStatItem(
                                  'Sudah',
                                  '$checkedCount',
                                  Icons.check_circle_outline,
                                  Colors.green,
                                ),
                                _buildStatItem(
                                  'Belum',
                                  '$uncheckedCount',
                                  Icons.radio_button_unchecked,
                                  Colors.orange,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress == 1.0
                                      ? Colors.green
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ruang: $_roomCode',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}% Selesai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari nama...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),

                  // Filter Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'Semua ($totalCount)',
                          FilterOption.all,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Belum ($uncheckedCount)',
                          FilterOption.unchecked,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Sudah ($checkedCount)',
                          FilterOption.checked,
                        ),
                      ],
                    ),
                  ),

                  // Name List
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _items.isEmpty
                                      ? Icons.playlist_add
                                      : Icons.search_off,
                                  size: 56,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _items.isEmpty
                                      ? 'Belum ada nama di checklist (Ruang: $_roomCode)'
                                      : 'Tidak ada nama yang cocok',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                if (_items.isEmpty) ...[
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _showAddDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Tambah Nama Sekarang'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              if (_isRealtimeConnected &&
                                  _roomChannel != null) {
                                _roomChannel!.sendBroadcastMessage(
                                  event: 'sync_request',
                                  payload: {
                                    'from': DateTime.now().toIso8601String(),
                                    'items': _items
                                        .map((e) => e.toMap())
                                        .toList(),
                                  },
                                );
                              } else {
                                await _connectToRoomChannel();
                              }
                              await Future.delayed(
                                const Duration(milliseconds: 600),
                              );
                            },
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 6,
                                bottom: 80,
                              ),
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                final isRecentlyUpdated =
                                    item.id == _recentlyUpdatedItemId;
                                return Dismissible(
                                  key: Key(item.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onDismissed: (direction) => _deleteItem(item),
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: isRecentlyUpdated
                                          ? const BorderSide(
                                              color: Colors.teal,
                                              width: 2,
                                            )
                                          : BorderSide.none,
                                    ),
                                    color: item.isChecked
                                        ? theme
                                              .colorScheme
                                              .surfaceContainerHighest
                                        : theme.colorScheme.surface,
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 4,
                                          ),
                                      leading: Transform.scale(
                                        scale: 1.2,
                                        child: Checkbox(
                                          value: item.isChecked,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          onChanged: (val) => _toggleItem(item),
                                        ),
                                      ),
                                      title: Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: item.isChecked
                                              ? FontWeight.normal
                                              : FontWeight.w600,
                                          decoration: item.isChecked
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: item.isChecked
                                              ? theme.colorScheme.outline
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              item.answeredQuestionsCount > 0
                                                  ? Icons.assignment_turned_in
                                                  : Icons.assignment_outlined,
                                              size: 14,
                                              color:
                                                  item.answeredQuestionsCount >
                                                      0
                                                  ? Colors.teal
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.answeredQuestionsCount > 0
                                                  ? 'Catatan: ${item.answeredQuestionsCount}/7 Soal Terisi'
                                                  : 'Belum ada catatan wawancara',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    item.answeredQuestionsCount >
                                                        0
                                                    ? Colors.teal
                                                    : Colors.grey.shade600,
                                                fontWeight:
                                                    item.answeredQuestionsCount >
                                                        0
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              item.answeredQuestionsCount > 0
                                                  ? Icons.edit_note
                                                  : Icons.note_add_outlined,
                                              color:
                                                  item.answeredQuestionsCount >
                                                      0
                                                  ? Colors.teal
                                                  : Colors.grey,
                                              size: 24,
                                            ),
                                            tooltip: 'Buka Catatan Wawancara',
                                            onPressed: () =>
                                                _showInterviewNotesSheet(item),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(
                                              Icons.more_vert,
                                              size: 20,
                                            ),
                                            onSelected: (action) {
                                              if (action == 'notes')
                                                _showInterviewNotesSheet(item);
                                              if (action == 'edit')
                                                _showEditDialog(item);
                                              if (action == 'delete')
                                                _deleteItem(item);
                                            },
                                            itemBuilder: (ctx) => [
                                              const PopupMenuItem(
                                                value: 'notes',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.assignment,
                                                      size: 18,
                                                      color: Colors.teal,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text('Buka Catatan'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Edit Nama'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete,
                                                      size: 18,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Hapus',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      onTap: () =>
                                          _showInterviewNotesSheet(item),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Nama'),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, FilterOption option) {
    final isSelected = _currentFilter == option;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentFilter = option;
          });
        }
      },
    );
  }
}
