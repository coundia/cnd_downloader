import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/paths.dart';
import '../../data/download_models.dart';
import '../../viewmodels/download_list_vm.dart';
import 'logs_sheet.dart';
import 'settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchCtrl = TextEditingController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _q = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(listVmProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('$e'))),
      );
    });

    final tasksAsync = ref.watch(downloadListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CND Downloader'),
        actions: [
          IconButton(
            tooltip: 'Paramètres',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Rechercher par nom, état ou URL',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      suffixIcon: _q.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                FocusScope.of(context).unfocus();
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _openAddSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter des liens'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erreur de chargement')),
        data: (all) {
          final tasks = _filter(all, _q);
          if (tasks.isEmpty) {
            return const Center(child: Text('Aucun téléchargement'));
          }
          return LayoutBuilder(
            builder: (c, bc) {
              final w = bc.maxWidth;
              if (w < 900) {
                return _ListMode(tasks: tasks);
              } else {
                final cross = w >= 1400 ? 3 : 2;
                return _GridMode(tasks: tasks, crossAxisCount: cross);
              }
            },
          );
        },
      ),
      bottomNavigationBar: tasksAsync.maybeWhen(
        data: (all) => _BottomStats(tasks: _filter(all, _q)),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  List<DownloadTask> _filter(List<DownloadTask> items, String q) {
    if (q.isEmpty) return items;
    return items.where((t) {
      final s = '${t.fileName} ${t.state} ${t.url}'.toLowerCase();
      return s.contains(q);
    }).toList();
  }

  Future<void> _openAddSheet(BuildContext context) async {
    final urls = await showModalBottomSheet<List<String>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => const _AddUrlsSheet(),
    );
    if (urls == null || urls.isEmpty) return;
    String? dir = await FilePicker.platform.getDirectoryPath();
    dir ??= await defaultDownloadDir();
    final vm = ref.read(listVmProvider.notifier);
    for (final u in urls) {
      await vm.addOnly(u, dir);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Ajout de ${urls.length} lien(s) → $dir')),
        );
    }
  }
}

class _BottomStats extends ConsumerWidget {
  final List<DownloadTask> tasks;
  const _BottomStats({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = tasks.length;
    final running = tasks.where((t) => t.state == 'running').length;
    final queued = tasks.where((t) => t.state == 'queued').length;
    final errors = tasks.where((t) => t.state == 'error').length;
    final speed = tasks.fold<double>(0, (a, b) => a + b.speedBps);
    final vm = ref.read(listVmProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Text(
            'Total $total  •  En cours $running  •  En file $queued  •  Erreurs $errors  •  ${_fmtBytes(speed)}/s',
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final list = tasks
                      .where((t) => t.state == 'queued' || t.state == 'paused')
                      .toList();
                  for (final t in list) {
                    await vm.start(t.id);
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Tout démarrer'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final list = tasks
                      .where((t) => t.state == 'running')
                      .toList();
                  for (final t in list) {
                    await vm.pause(t.id);
                  }
                },
                icon: const Icon(Icons.pause),
                label: const Text('Tout mettre en pause'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final list = tasks.where((t) => t.state == 'error').toList();
                  for (final t in list) {
                    await vm.retry(t.id);
                  }
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Relancer les erreurs'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListMode extends StatelessWidget {
  final List<DownloadTask> tasks;
  const _ListMode({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (c, i) => _DownloadTile(task: tasks[i]),
    );
  }
}

class _GridMode extends StatelessWidget {
  final List<DownloadTask> tasks;
  final int crossAxisCount;
  const _GridMode({required this.tasks, required this.crossAxisCount});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tasks.length,
      itemBuilder: (c, i) => _DownloadCard(task: tasks[i]),
    );
  }
}

class _DownloadCard extends ConsumerWidget {
  final DownloadTask task;
  const _DownloadCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(listVmProvider.notifier);
    final p = task.total > 0 ? task.downloaded / task.total : 0.0;
    final sizeStr = '${_fmtBytes(task.downloaded)} / ${_fmtBytes(task.total)}';
    final speed = task.speedBps > 0 ? '${_fmtBytes(task.speedBps)}/s' : '';
    final eta = _fmtEta(task.etaSeconds);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                _StateChip(state: task.state),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: p),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(sizeStr),
                const Spacer(),
                if (speed.isNotEmpty) Text(speed),
                if (eta.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('ETA $eta'),
                ],
              ],
            ),
            const Spacer(),
            Row(
              children: [
                IconButton(
                  tooltip: 'Logs',
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    builder: (_) => LogsSheet(taskId: task.id),
                  ),
                  icon: const Icon(Icons.article),
                ),
                const Spacer(),
                if (task.state == 'running')
                  IconButton(
                    onPressed: () => vm.pause(task.id),
                    icon: const Icon(Icons.pause),
                  ),
                if (task.state == 'paused' || task.state == 'queued')
                  IconButton(
                    onPressed: () => vm.start(task.id),
                    icon: const Icon(Icons.play_arrow),
                  ),
                if (task.state == 'error')
                  IconButton(
                    tooltip: 'Retry (real URL)',
                    onPressed: () => vm.retry(task.id),
                    icon: const Icon(Icons.refresh),
                  ),
                IconButton(
                  tooltip: 'Full retry (origin URL)',
                  onPressed: () => vm.fullRetry(task.id),
                  icon: const Icon(Icons.refresh_outlined),
                ),
                IconButton(
                  onPressed: () => vm.delete(task.id),
                  icon: const Icon(Icons.delete_forever),
                ),
                if (task.state == 'completed')
                  IconButton(
                    onPressed: () => vm.open(task.id),
                    icon: const Icon(Icons.open_in_new),
                  ),
                IconButton(
                  onPressed: () => vm.reveal(task.id),
                  icon: const Icon(Icons.folder_open),
                ),
                IconButton(
                  onPressed: () => vm.verify(task.id),
                  icon: const Icon(Icons.check_circle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  final DownloadTask task;
  const _DownloadTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(listVmProvider.notifier);
    final p = task.total > 0 ? task.downloaded / task.total : 0.0;
    final sizeStr = '${_fmtBytes(task.downloaded)} / ${_fmtBytes(task.total)}';
    final speed = task.speedBps > 0 ? '${_fmtBytes(task.speedBps)}/s' : '';
    final eta = _fmtEta(task.etaSeconds);

    return ListTile(
      title: Text(task.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: p),
          const SizedBox(height: 6),
          Text(
            [
              sizeStr,
              if (speed.isNotEmpty) speed,
              if (eta.isNotEmpty) 'ETA $eta',
              task.state,
            ].join(' • '),
          ),
        ],
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            tooltip: 'Logs',
            onPressed: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (_) => LogsSheet(taskId: task.id),
            ),
            icon: const Icon(Icons.article),
          ),
          if (task.state == 'running')
            IconButton(
              onPressed: () => vm.pause(task.id),
              icon: const Icon(Icons.pause),
            ),
          if (task.state == 'paused' || task.state == 'queued')
            IconButton(
              onPressed: () => vm.start(task.id),
              icon: const Icon(Icons.play_arrow),
            ),
          if (task.state == 'error')
            IconButton(
              tooltip: 'Retry (real URL)',
              onPressed: () => vm.retry(task.id),
              icon: const Icon(Icons.refresh),
            ),
          IconButton(
            tooltip: 'Full retry (origin URL)',
            onPressed: () => vm.fullRetry(task.id),
            icon: const Icon(Icons.refresh_outlined),
          ),
          IconButton(
            onPressed: () => vm.delete(task.id),
            icon: const Icon(Icons.delete_forever),
          ),
          if (task.state == 'completed')
            IconButton(
              onPressed: () => vm.open(task.id),
              icon: const Icon(Icons.open_in_new),
            ),
          IconButton(
            onPressed: () => vm.reveal(task.id),
            icon: const Icon(Icons.folder_open),
          ),
          IconButton(
            onPressed: () => vm.verify(task.id),
            icon: const Icon(Icons.check_circle),
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final String state;
  const _StateChip({required this.state});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    switch (state) {
      case 'running':
        bg = cs.primaryContainer;
        break;
      case 'queued':
        bg = cs.secondaryContainer;
        break;
      case 'paused':
        bg = cs.tertiaryContainer;
        break;
      case 'completed':
        bg = Colors.green.withOpacity(.2);
        break;
      case 'error':
        bg = Colors.red.withOpacity(.2);
        break;
      default:
        bg = cs.surfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(state),
    );
  }
}

class _AddUrlsSheet extends StatefulWidget {
  const _AddUrlsSheet();

  @override
  State<_AddUrlsSheet> createState() => _AddUrlsSheetState();
}

class _AddUrlsSheetState extends State<_AddUrlsSheet> {
  final ctrl = TextEditingController();
  bool valid = false;

  @override
  void initState() {
    super.initState();
    ctrl.addListener(_validate);
  }

  @override
  void dispose() {
    ctrl.removeListener(_validate);
    ctrl.dispose();
    super.dispose();
  }

  void _validate() {
    final lines = _extract(ctrl.text);
    setState(() => valid = lines.isNotEmpty);
  }

  List<String> _extract(String raw) {
    return raw
        .split(RegExp(r'[\n\r;,\t ]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .where((s) => s.startsWith('http://') || s.startsWith('https://'))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxW = mq.size.width > 600 ? 560.0 : mq.size.width - 24;
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Ajouter des URLs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Coller',
                      onPressed: () async {
                        final data = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        if ((data?.text ?? '').isNotEmpty) {
                          ctrl.text = data!.text!;
                        }
                      },
                      icon: const Icon(Icons.paste),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: TextField(
                    controller: ctrl,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      hintText: 'Une URL par ligne',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: valid
                          ? () {
                              final lines = _extract(ctrl.text);
                              Navigator.pop(context, lines);
                            }
                          : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _fmtBytes(num b) {
  if (b <= 0) return '0 B';
  const u = ['B', 'KB', 'MB', 'GB', 'TB'];
  int i = 0;
  double v = b.toDouble();
  while (v >= 1024 && i < u.length - 1) {
    v /= 1024;
    i++;
  }
  final d = v >= 100
      ? 0
      : v >= 10
      ? 1
      : 2;
  return '${v.toStringAsFixed(d)} ${u[i]}';
}

String _fmtEta(int s) {
  if (s <= 0) return '';
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}';
  if (m > 0) return '${m}m${sec.toString().padLeft(2, '0')}s';
  return '${sec}s';
}
