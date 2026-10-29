import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/performance_service.dart';

class StatisticsHistoryPage extends StatefulWidget {
  const StatisticsHistoryPage({super.key});

  @override
  State<StatisticsHistoryPage> createState() => _StatisticsHistoryPageState();
}

class _StatisticsHistoryPageState extends State<StatisticsHistoryPage> {
  Future<List<StatisticsHistoryEntry>> _loadHistory() async {
    return PerformanceService.loadStatisticsHistory(
      uid: AuthService.currentUser?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Statistics History'),
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.lightBlue.shade50),
        child: SafeArea(
          child: FutureBuilder<List<StatisticsHistoryEntry>>(
            future: _loadHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final entries = snapshot.data ?? const <StatisticsHistoryEntry>[];
              if (entries.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Your statistics history will appear here after your performance statistics are saved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final subjectEntries = entry.subjectAverages.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.lightBlue.shade200,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.formattedTimestamp,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HistoryPill(
                              label: 'Best',
                              value: entry.bestSubject != null
                                  ? '${entry.bestSubject} • ${entry.bestAverage?.toStringAsFixed(1) ?? '0.0'}%'
                                  : 'N/A',
                              color: Colors.green,
                            ),
                            _HistoryPill(
                              label: 'Lowest',
                              value: entry.lowestSubject != null
                                  ? '${entry.lowestSubject} • ${entry.lowestAverage?.toStringAsFixed(1) ?? '0.0'}%'
                                  : 'N/A',
                              color: Colors.orange,
                            ),
                            _HistoryPill(
                              label: 'Overall',
                              value:
                                  '${entry.overallAverage.toStringAsFixed(1)}%',
                              color: Colors.blue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Completed assessments: ${entry.completedAssessments}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...subjectEntries.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.key,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${item.value.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: (item.value / 100).clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: theme.colorScheme.onSurface
                                        .withOpacity(0.08),
                                    valueColor: const AlwaysStoppedAnimation(
                                      Colors.lightBlueAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HistoryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HistoryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
