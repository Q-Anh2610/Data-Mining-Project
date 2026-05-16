import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/history/history_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/translation/translation_bloc.dart';
import '../models/translation_record.dart';
import '../shared/app_translations.dart';
import '../shared/translator_ui.dart';

class HistoryScreen extends StatelessWidget {
  final bool favoritesOnly;

  const HistoryScreen({super.key, this.favoritesOnly = false});

  void _showDeleteOneConfirm(BuildContext context, TranslationRecord record) {
    _showDeleteConfirm(
      context: context,
      title: 'Xác nhận xóa',
      message: 'Bạn có chắc muốn xóa mục này không?',
      onDelete: () {
        if (favoritesOnly) {
          context.read<HistoryBloc>().add(
            ToggleHistoryFavoriteEvent(recordId: record.id, isFavorite: false),
          );
          context.read<TranslationBloc>().add(
            UpdateRecordFavoriteEvent(recordId: record.id, isFavorite: false),
          );
          return;
        }

        final translationBloc = context.read<TranslationBloc>();
        final isCurrentSession =
            translationBloc.state.currentSessionId == record.sessionId;

        context.read<HistoryBloc>().add(
          DeleteHistoryItemEvent(record.sessionId),
        );

        if (isCurrentSession) {
          translationBloc.add(ClearSessionEvent());
        }
      },
    );
  }

  void _showClearAllConfirm(
    BuildContext context,
    List<TranslationRecord> records,
  ) {
    _showDeleteConfirm(
      context: context,
      title: 'Xác nhận xóa',
      message: favoritesOnly
          ? 'Bạn có chắc muốn xóa toàn bộ mục yêu thích không?'
          : 'Bạn có chắc muốn xóa toàn bộ lịch sử không?',
      onDelete: () {
        if (favoritesOnly) {
          final favoriteIds = records
              .where((record) => record.isFavorite)
              .map((record) => record.id)
              .toList();
          context.read<HistoryBloc>().add(
            ClearFavoriteRecordsEvent(favoriteIds),
          );
          for (final record in records.where((record) => record.isFavorite)) {
            context.read<TranslationBloc>().add(
              UpdateRecordFavoriteEvent(recordId: record.id, isFavorite: false),
            );
          }
        } else {
          context.read<HistoryBloc>().add(ClearAllHistoryEvent());
          context.read<TranslationBloc>().add(ClearSessionEvent());
        }
      },
    );
  }

  void _showDeleteConfirm({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onDelete,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.12),
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 55),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 56, 28, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 102,
                height: 102,
                decoration: BoxDecoration(
                  color: TranslatorColors.danger.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: TranslatorColors.danger.withValues(alpha: 0.24),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFFF2D2D),
                      size: 42,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.0,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 172,
                height: 37,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: TranslatorColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.5),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                  child: const Text(
                    'Xóa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Hủy',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsBloc>().state.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF131314)
        : const Color(0xFFF8FAFF);
    final textColor = isDark
        ? const Color(0xFFE8EAED)
        : const Color(0xFF101828);
    final borderColor = isDark
        ? const Color(0xFF303134)
        : const Color(0xFFE6ECF5);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading || state is HistoryInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HistoryError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: TranslatorColors.danger),
              ),
            );
          }

          if (state is! HistoryLoaded) return const SizedBox.shrink();

          final records = favoritesOnly ? state.favoriteRecords : state.records;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                bottom: false,
                child: Container(
                  height: 126,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      if (favoritesOnly)
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            size: 36,
                          ),
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            '/history',
                            arguments: {'from': 1, 'to': 1},
                          ),
                        ),
                      Expanded(
                        child: Text(
                          favoritesOnly
                              ? 'Favorites'
                              : AppTrans.t(lang, 'history'),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: records.isEmpty
                            ? null
                            : () => _showClearAllConfirm(context, records),
                        child: Text(
                          AppTrans.t(lang, 'clear_all'),
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFF1D9BF0),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: favoritesOnly ? 'Favorites' : 'View favorites',
                        icon: Icon(
                          favoritesOnly
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFFFB800),
                          size: 34,
                        ),
                        onPressed: favoritesOnly
                            ? () {}
                            : () => Navigator.pushReplacementNamed(
                                context,
                                '/favorite',
                                arguments: {'from': 1, 'to': 1},
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: records.isEmpty
                    ? _EmptyHistory(favoritesOnly: favoritesOnly)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return _HistoryTile(
                            record: record,
                            onOpen: () {
                              context.read<TranslationBloc>().add(
                                LoadSessionEvent(record.sessionId),
                              );
                              Navigator.pushReplacementNamed(
                                context,
                                '/home',
                                arguments: {'from': 1, 'to': 0},
                              );
                            },
                            onDelete: () =>
                                _showDeleteOneConfirm(context, record),
                            onToggleFavorite: () {
                              final nextFavorite = !record.isFavorite;
                              if (favoritesOnly) {
                                context.read<HistoryBloc>().add(
                                  ToggleHistoryFavoriteEvent(
                                    recordId: record.id,
                                    isFavorite: nextFavorite,
                                  ),
                                );
                                context.read<TranslationBloc>().add(
                                  UpdateRecordFavoriteEvent(
                                    recordId: record.id,
                                    isFavorite: nextFavorite,
                                  ),
                                );
                              } else {
                                context.read<HistoryBloc>().add(
                                  ToggleHistorySessionFavoriteEvent(
                                    sessionId: record.sessionId,
                                    isFavorite: nextFavorite,
                                  ),
                                );
                                context.read<TranslationBloc>().add(
                                  UpdateSessionFavoriteEvent(
                                    sessionId: record.sessionId,
                                    isFavorite: nextFavorite,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const TranslatorBottomNav(currentIndex: 1),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TranslationRecord record;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _HistoryTile({
    required this.record,
    required this.onOpen,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1F20) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF303134)
        : const Color(0xFFE2E6EE);
    final textColor = isDark ? const Color(0xFFE8EAED) : Colors.black;
    final hintColor = isDark
        ? const Color(0xFFBDC1C6)
        : TranslatorColors.softText;
    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onOpen,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LanguageFlag(language: record.sourceLang, size: 31),
                  const SizedBox(height: 17),
                  LanguageFlag(language: record.targetLang, size: 31),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.sourceText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: hintColor, fontSize: 18),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      record.translatedText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor, fontSize: 18),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  record.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: record.isFavorite
                      ? const Color(0xFFFFB800)
                      : Colors.grey,
                  size: 38,
                ),
                onPressed: onToggleFavorite,
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: TranslatorColors.danger,
                  size: 29,
                ),
                onPressed: onDelete,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final bool favoritesOnly;

  const _EmptyHistory({required this.favoritesOnly});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            favoritesOnly ? Icons.star_border_rounded : Icons.history_rounded,
            size: 96,
            color: isDark ? const Color(0xFF5F6368) : const Color(0xFFC9C9C9),
          ),
          const SizedBox(height: 24),
          Text(
            favoritesOnly ? 'No favorites yet' : 'No history yet',
            style: TextStyle(
              color: isDark ? const Color(0xFFBDC1C6) : const Color(0xFF707070),
              fontSize: 21,
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
