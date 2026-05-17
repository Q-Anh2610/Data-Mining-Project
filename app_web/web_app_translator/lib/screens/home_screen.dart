// File: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../blocs/translation/translation_bloc.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../models/translation_record.dart';
import '../shared/app_translations.dart';
import '../shared/translator_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FlutterTts _flutterTts;
  bool _isOfflineMode = false;
  bool _showWebSettingsPanel = false;
  bool _showWebFavoritePanel = false;
  String _lastSubmittedText = '';

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      if (mounted) setState(() {});
    });
    _initTts();
  }

  @override
  void dispose() {
    _stop();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();

    _flutterTts.setStartHandler(() {
      debugPrint('TTS started');
    });

    _flutterTts.setCompletionHandler(() {
      debugPrint('TTS completed');
    });

    _flutterTts.setErrorHandler((message) {
      debugPrint('TTS error handler: $message');
    });

    // Default TTS parameters used before every speak call.
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  void _handleTranslate() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _lastSubmittedText = text;
    context.read<TranslationBloc>().add(
      TranslateTextEvent(text, isOffline: _isOfflineMode),
    );
    _inputController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String _getTargetLanguageCode(String mode) {
    final normalizedMode = mode.toLowerCase();
    final sourceMode = normalizedMode.split('->').first.trim();

    if (sourceMode.contains('english') || sourceMode.contains('anh')) {
      return 'vi-VN';
    }

    if (sourceMode.contains('vietnamese') ||
        sourceMode.contains('viet') ||
        sourceMode.contains('vi\u1ec7t')) {
      return 'en-US';
    }

    if (normalizedMode.contains('-> vietnamese') ||
        normalizedMode.contains('-> vi') ||
        normalizedMode.contains('-> vi\u1ec7t')) {
      return 'vi-VN';
    }

    if (normalizedMode.contains('-> english') ||
        normalizedMode.contains('-> anh')) {
      return 'en-US';
    }

    return 'en-US';
  }

  String _getLanguageCode(String language) {
    final normalized = language.toLowerCase();
    if (normalized.contains('vietnamese') ||
        normalized.contains('viet') ||
        normalized.contains('việt')) {
      return 'vi-VN';
    }
    return 'en-US';
  }

  String _getRecordMode(TranslationRecord record) {
    final sourceLang = record.sourceLang.toLowerCase();
    final targetLang = record.targetLang.toLowerCase();

    if (sourceLang == 'english' && targetLang == 'vietnamese') {
      return 'Anh -> Vi\u1ec7t';
    }

    if (sourceLang == 'vietnamese' && targetLang == 'english') {
      return 'Vi\u1ec7t -> Anh';
    }

    return '${record.sourceLang} -> ${record.targetLang}';
  }

  Future<void> _speak(String text, String mode) async {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      debugPrint('TTS skipped: translated text is empty');
      return;
    }

    final languageCode = _getTargetLanguageCode(mode);

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang đọc văn bản'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      await _flutterTts.stop();

      debugPrint('TTS text: $trimmedText');
      debugPrint('TTS mode: $mode');
      debugPrint('TTS language: $languageCode');

      final isAvailable = await _flutterTts.isLanguageAvailable(languageCode);
      debugPrint('TTS language available: $isAvailable');

      await _flutterTts.setLanguage(languageCode);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      final result = await _flutterTts.speak(trimmedText);
      debugPrint('TTS speak result: $result');
    } catch (e, stack) {
      debugPrint('TTS error: $e');
      debugPrint('$stack');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể đọc văn bản: $e')));
    }
  }

  Future<void> _speakSourceText(String text, String sourceLanguage) async {
    await _speakWithLanguage(text, _getLanguageCode(sourceLanguage));
  }

  Future<void> _speakWithLanguage(String text, String languageCode) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang đọc văn bản'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      await _flutterTts.stop();
      await _flutterTts.setLanguage(languageCode);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(trimmedText);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể đọc văn bản: $e')));
    }
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
  }

  void _toggleOfflineMode() {
    setState(() {
      _isOfflineMode = !_isOfflineMode;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isOfflineMode
              ? "Đã chuyển sang Offline Mode"
              : "Đã kết nối Cloud API",
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFavoriteRecord(
    BuildContext context,
    String recordId,
    bool isFavorite, {
    bool showFavoritePanel = false,
  }) {
    final nextFavorite = !isFavorite;
    context.read<HistoryBloc>().add(
      ToggleHistoryFavoriteEvent(recordId: recordId, isFavorite: nextFavorite),
    );

    context.read<TranslationBloc>().add(
      UpdateRecordFavoriteEvent(recordId: recordId, isFavorite: nextFavorite),
    );

    if (showFavoritePanel) {
      setState(() {
        _showWebFavoritePanel = true;
        _showWebSettingsPanel = false;
      });
    }
  }

  void _toggleFavoriteSession(
    BuildContext context,
    String sessionId,
    bool isFavorite,
  ) {
    final nextFavorite = !isFavorite;
    context.read<HistoryBloc>().add(
      ToggleHistorySessionFavoriteEvent(
        sessionId: sessionId,
        isFavorite: nextFavorite,
      ),
    );

    context.read<TranslationBloc>().add(
      UpdateSessionFavoriteEvent(
        sessionId: sessionId,
        isFavorite: nextFavorite,
      ),
    );

    setState(() {
      _showWebFavoritePanel = true;
      _showWebSettingsPanel = false;
    });
  }

  bool _isFavoriteRecord(HistoryState historyState, TranslationRecord record) {
    if (historyState is! HistoryLoaded) return record.isFavorite;

    if (historyState.favoriteRecords.any((item) => item.id == record.id)) {
      return true;
    }

    final matchingHistoryRecord = historyState.records.where(
      (item) => item.id == record.id,
    );
    if (matchingHistoryRecord.isNotEmpty) {
      return matchingHistoryRecord.first.isFavorite;
    }

    return record.isFavorite;
  }

  String _flagLanguageForFavorite(TranslationRecord record, bool source) {
    final language = source ? record.sourceLang : record.targetLang;
    final normalized = language.toLowerCase();
    if (normalized.contains('en') ||
        normalized.contains('anh') ||
        normalized.contains('english') ||
        normalized.contains('us')) {
      return 'English';
    }
    if (normalized.contains('vi') ||
        normalized.contains('viet') ||
        normalized.contains('vietnam')) {
      return 'Vietnamese';
    }

    final mode = record.mode.toLowerCase();
    if (mode.contains('en_vi')) return source ? 'English' : 'Vietnamese';
    if (mode.contains('vi_en')) return source ? 'Vietnamese' : 'English';
    return language;
  }

  void _updateRecordRating(
    BuildContext context,
    TranslationRecord record,
    int rating,
  ) {
    context.read<TranslationBloc>().add(
      UpdateRecordRatingEvent(recordId: record.id, rating: rating),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          rating == 0 ? 'Đã bỏ đánh giá!' : 'Đã đánh giá $rating sao!',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa bản dịch này khỏi lịch sử không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final translationBloc = context.read<TranslationBloc>();
              final isCurrentSession =
                  translationBloc.state.currentSessionId == sessionId;

              context.read<HistoryBloc>().add(
                DeleteHistoryItemEvent(sessionId),
              );

              if (isCurrentSession) {
                translationBloc.add(ClearSessionEvent());
                _inputController.clear();
              }

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa khỏi lịch sử'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showClearAllConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xóa toàn bộ lịch sử',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'Bạn sắp xóa TẤT CẢ lịch sử dịch thuật. Bạn có chắc chắn không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              context.read<HistoryBloc>().add(ClearAllHistoryEvent());
              context.read<TranslationBloc>().add(ClearSessionEvent());
              _inputController.clear();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa toàn bộ lịch sử'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final orientation = MediaQuery.of(context).orientation;
        if (constraints.maxWidth >= 850 ||
            orientation == Orientation.landscape) {
          return _buildWebLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  // ===========================================================================
  // 1. GIAO DIỆN WEB
  // ===========================================================================
  Widget _buildWebLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final webBgColor = isDark ? const Color(0xFF0E0E0E) : Colors.grey.shade200;
    final panelColor = isDark ? const Color(0xFF1E1F20) : Colors.white;
    final panelBorder = isDark
        ? null
        : Border.all(color: Colors.grey.shade400, width: 1.0);
    final panelShadow = BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    );

    return Scaffold(
      backgroundColor: webBgColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(24),
                border: panelBorder,
                boxShadow: [panelShadow],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildWebSidebar(context, isDark),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(24),
                  border: panelBorder,
                  boxShadow: [panelShadow],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: _buildChatArea(context, isDark, isWeb: true),
                    ),
                  ),
                ),
              ),
            ),
            if (_showWebSettingsPanel) _buildWebSettingsPanel(context, isDark),
            if (_showWebFavoritePanel) _buildWebFavoritePanel(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildWebSidebar(BuildContext context, bool isDark) {
    final uiLang = context.watch<SettingsBloc>().state.language;
    final textColor = isDark ? const Color(0xFFE3E3E3) : Colors.black87;
    final hintColor = isDark ? const Color(0xFF8E918F) : Colors.grey.shade600;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Row(
            children: [
              Image.asset(
                'assets/images/logo.jpg',
                width: 36,
                height: 36,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.language, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppTrans.t(uiLang, 'app_name'),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTrans.t(uiLang, 'history'),
                style: TextStyle(
                  color: hintColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                    onPressed: () => _showClearAllConfirm(context),
                    child: Text(
                      AppTrans.t(uiLang, 'clear_all'),
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        _showWebFavoritePanel = !_showWebFavoritePanel;
                        if (_showWebFavoritePanel) {
                          _showWebSettingsPanel = false;
                        }
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state is HistoryLoaded) {
                if (state.records.isEmpty) {
                  return Center(
                    child: Text(
                      AppTrans.t(uiLang, 'empty_history'),
                      style: TextStyle(color: hintColor, fontSize: 13),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.records.length,
                  itemBuilder: (context, index) {
                    final record = state.records[index];
                    final isStarred = record.isFavorite;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF282A2C)
                            : Colors.grey.shade100,
                        border: isDark
                            ? null
                            : Border.all(
                                color: isStarred
                                    ? Colors.amber.shade400
                                    : Colors.grey.shade300,
                                width: isStarred ? 1.5 : 1.0,
                              ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isStarred
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 24,
                            color: isStarred ? Colors.amber : hintColor,
                          ),
                          onPressed: () => _toggleFavoriteSession(
                            context,
                            record.sessionId,
                            isStarred,
                          ),
                        ),
                        title: Text(
                          record.sourceText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: isStarred
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.red.shade400,
                          ),
                          onPressed: () =>
                              _showDeleteConfirm(context, record.sessionId),
                        ),
                        onTap: () => context.read<TranslationBloc>().add(
                          LoadSessionEvent(record.sessionId),
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        Divider(height: 1, color: dividerColor),

        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTrans.t(uiLang, 'settings'),
                style: TextStyle(
                  color: hintColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildWebSidebarAction(
                icon: Icons.settings_outlined,
                title: AppTrans.t(uiLang, 'settings'),
                subtitle: AppTrans.t(uiLang, 'app_language'),
                textColor: textColor,
                hintColor: hintColor,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _showWebSettingsPanel = !_showWebSettingsPanel;
                    if (_showWebSettingsPanel) {
                      _showWebFavoritePanel = false;
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebSidebarAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color hintColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF282A2C) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? null
              : Border.all(color: Colors.grey.shade400, width: 1.0),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: hintColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: hintColor),
          ],
        ),
      ),
    );
  }

  Widget _buildWebSettingsPanel(BuildContext context, bool isDark) {
    final state = context.watch<SettingsBloc>().state;
    final uiLang = state.language;
    final textColor = isDark ? const Color(0xFFE3E3E3) : Colors.black87;
    final hintColor = isDark ? const Color(0xFF8E918F) : Colors.grey.shade600;
    final boxColor = isDark ? const Color(0xFF282A2C) : Colors.grey.shade100;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Container(
      width: 360,
      margin: const EdgeInsets.only(left: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F20) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? null
            : Border.all(color: Colors.grey.shade400, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppTrans.t(uiLang, 'settings'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showWebSettingsPanel = false;
                      });
                    },
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    AppTrans.t(uiLang, 'app_language'),
                    style: TextStyle(
                      color: hintColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWebSettingBox(
                    icon: Icons.language_outlined,
                    value: state.language,
                    items: const ['English', 'Vietnamese'],
                    uiLang: uiLang,
                    isDark: isDark,
                    textColor: textColor,
                    onChanged: (newVal) {
                      if (newVal != null) {
                        context.read<SettingsBloc>().add(
                          UpdateSettingsEvent(
                            textSize: state.textSize,
                            language: newVal,
                            themeMode: state.themeMode,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppTrans.t(uiLang, 'text_size'),
                    style: TextStyle(
                      color: hintColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWebSettingBox(
                    icon: Icons.text_fields_rounded,
                    value: state.textSize,
                    items: const ['Small', 'Medium', 'Large'],
                    uiLang: uiLang,
                    isDark: isDark,
                    textColor: textColor,
                    onChanged: (newVal) {
                      if (newVal != null) {
                        context.read<SettingsBloc>().add(
                          UpdateSettingsEvent(
                            textSize: newVal,
                            language: state.language,
                            themeMode: state.themeMode,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppTrans.t(uiLang, 'theme'),
                    style: TextStyle(
                      color: hintColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWebSettingBox(
                    icon: Icons.palette_outlined,
                    value: state.themeMode,
                    items: const ['Light', 'Dark'],
                    uiLang: uiLang,
                    isDark: isDark,
                    textColor: textColor,
                    onChanged: (newVal) {
                      if (newVal != null) {
                        context.read<SettingsBloc>().add(
                          UpdateSettingsEvent(
                            textSize: state.textSize,
                            language: state.language,
                            themeMode: newVal,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppTrans.t(uiLang, 'about'),
                    style: TextStyle(
                      color: hintColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.groups_rounded, color: textColor),
                          title: Text(
                            AppTrans.t(uiLang, 'our_team'),
                            style: TextStyle(color: textColor),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: hintColor,
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(
                                  AppTrans.t(uiLang, 'our_team'),
                                  style: TextStyle(color: textColor),
                                ),
                                content: const SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: Text(
                                      'Danh sách thành viên đang được cập nhật...',
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Đóng'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: borderColor),
                        ListTile(
                          leading: Icon(
                            Icons.new_releases_outlined,
                            color: textColor,
                          ),
                          title: Text(
                            AppTrans.t(uiLang, 'version'),
                            style: TextStyle(color: textColor),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: hintColor,
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
      ),
    );
  }

  Widget _buildWebFavoritePanel(BuildContext context, bool isDark) {
    final uiLang = context.watch<SettingsBloc>().state.language;
    final textColor = isDark ? const Color(0xFFE3E3E3) : Colors.black87;
    final hintColor = isDark ? const Color(0xFF8E918F) : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final itemColor = isDark ? const Color(0xFF282A2C) : Colors.grey.shade100;

    return Container(
      width: 360,
      margin: const EdgeInsets.only(left: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F20) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? null
            : Border.all(color: Colors.grey.shade400, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Favorites',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showWebFavoritePanel = false;
                      });
                    },
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<HistoryBloc, HistoryState>(
                builder: (context, state) {
                  if (state is HistoryLoading || state is HistoryInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is! HistoryLoaded ||
                      state.favoriteRecords.isEmpty) {
                    return Center(
                      child: Text(
                        'No favorites yet',
                        style: TextStyle(color: hintColor, fontSize: 14),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.favoriteRecords.length,
                    itemBuilder: (context, index) {
                      final record = state.favoriteRecords[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: itemColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 1.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              LanguageFlag(
                                language: _flagLanguageForFavorite(
                                  record,
                                  true,
                                ),
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              LanguageFlag(
                                language: _flagLanguageForFavorite(
                                  record,
                                  false,
                                ),
                                size: 24,
                              ),
                            ],
                          ),
                          title: Text(
                            record.sourceText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hintColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              record.translatedText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: textColor, fontSize: 14),
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: 'Remove favorite',
                            icon: const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                            ),
                            onPressed: () => _toggleFavoriteRecord(
                              context,
                              record.id,
                              true,
                              showFavoritePanel: true,
                            ),
                          ),
                          onTap: () {
                            context.read<TranslationBloc>().add(
                              LoadSessionEvent(record.sessionId),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppTrans.t(uiLang, 'history')),
                                duration: const Duration(milliseconds: 800),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebSettingBox({
    required IconData icon,
    required String value,
    required List<String> items,
    required String uiLang,
    required bool isDark,
    required Color textColor,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282A2C) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? null
            : Border.all(color: Colors.grey.shade400, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                dropdownColor: isDark ? const Color(0xFF282A2C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                items: items
                    .map(
                      (String val) => DropdownMenuItem<String>(
                        value: val,
                        child: Text(
                          AppTrans.t(uiLang, val.toLowerCase()),
                          style: TextStyle(color: textColor, fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // KHUNG CHAT (NƠI ĐÃ SỬA LỖI NÚT SWAP VÀ LOWERCASE)
  // ===========================================================================
  Widget _buildChatHeader(
    BuildContext context,
    bool isDark,
    bool isWeb,
    String uiLang,
    Color sendBtnColor,
    Color hintColor,
    Color textColor,
  ) {
    return BlocBuilder<TranslationBloc, TranslationState>(
      builder: (context, state) {
        Widget languageSwitcher = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                AppTrans.t(uiLang, state.sourceLang.toLowerCase()),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: sendBtnColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isWeb ? 16 : 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: IconButton(
                icon: Icon(
                  Icons.swap_horiz,
                  color: sendBtnColor,
                  size: isWeb ? 24 : 20,
                ),
                onPressed: () =>
                    context.read<TranslationBloc>().add(SwapLanguagesEvent()),
              ),
            ),
            Flexible(
              child: Text(
                AppTrans.t(uiLang, state.targetLang.toLowerCase()),
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: sendBtnColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isWeb ? 16 : 14,
                ),
              ),
            ),
          ],
        );

        Widget actionButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWeb) ...[
              IconButton(
                icon: Icon(
                  _isOfflineMode
                      ? Icons.cloud_off_rounded
                      : Icons.cloud_rounded,
                  size: 24,
                ),
                color: _isOfflineMode ? Colors.orange : hintColor,
                tooltip: _isOfflineMode ? "Chế độ Offline" : "Chế độ Online",
                onPressed: _toggleOfflineMode,
              ),
              const SizedBox(width: 8),
            ],
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.blue,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: isWeb
                    ? null
                    : const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
              onPressed: () =>
                  context.read<TranslationBloc>().add(ClearSessionEvent()),
              icon: Icon(
                Icons.add,
                size: 18,
                color: isDark ? textColor : Colors.blue,
              ),
              label: Text(
                AppTrans.t(uiLang, 'new'),
                style: TextStyle(
                  color: isDark ? textColor : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );

        if (isWeb) {
          return SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(width: 320, child: languageSwitcher),
                ),
                Align(alignment: Alignment.centerRight, child: actionButtons),
              ],
            ),
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: languageSwitcher),
              const SizedBox(width: 8),
              actionButtons,
            ],
          );
        }
      },
    );
  }

  Widget _buildMobileChatArea(BuildContext context, bool isDark) {
    final uiLang = context.watch<SettingsBloc>().state.language;
    return BlocConsumer<TranslationBloc, TranslationState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        }
        if (!state.isLoading && state.sessionRecords.isNotEmpty) {
          _scrollToBottom();
          context.read<HistoryBloc>().add(LoadHistoryEvent());
        }
      },
      builder: (context, state) {
        return ColoredBox(
          color: isDark ? const Color(0xFF131314) : const Color(0xFFF8FAFF),
          child: Column(
            children: [
              _MobileHomeHeader(
                uiLang: uiLang,
                sourceLang: state.sourceLang,
                targetLang: state.targetLang,
                offline: _isOfflineMode,
                onCloudTap: _toggleOfflineMode,
                onNewTap: () {
                  context.read<TranslationBloc>().add(ClearSessionEvent());
                  _inputController.clear();
                },
                onSwap: () =>
                    context.read<TranslationBloc>().add(SwapLanguagesEvent()),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: state.sessionRecords.isEmpty && !state.isLoading
                      ? _MobileEmptyState(uiLang: uiLang)
                      : BlocBuilder<HistoryBloc, HistoryState>(
                          builder: (context, historyState) {
                            return ListView.builder(
                              key: const ValueKey('mobile-results-list'),
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                18,
                                16,
                                20,
                              ),
                              itemCount:
                                  state.sessionRecords.length +
                                  (state.isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == state.sessionRecords.length) {
                                  return _MobileInlineLoading(
                                    sourceText: _lastSubmittedText,
                                  );
                                }

                                final record = state.sessionRecords[index];
                                return _buildMobileRecordResult(
                                  context,
                                  uiLang,
                                  historyState,
                                  record,
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
              _MobileInputBar(
                controller: _inputController,
                uiLang: uiLang,
                sourceLanguage: state.sourceLang,
                onSpeak: () =>
                    _speakSourceText(_inputController.text, state.sourceLang),
                onSubmit: _handleTranslate,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileRecordResult(
    BuildContext context,
    String uiLang,
    HistoryState historyState,
    TranslationRecord record,
  ) {
    final isStarred = _isFavoriteRecord(historyState, record);
    return _MobileResultContent(
      record: record,
      uiLang: uiLang,
      isStarred: isStarred,
      onEdit: () {
        _inputController.text = record.sourceText;
        _inputController.selection = TextSelection.collapsed(
          offset: _inputController.text.length,
        );
      },
      onSpeakSource: () =>
          _speakSourceText(record.sourceText, record.sourceLang),
      onSpeakTarget: () =>
          _speak(record.translatedText, _getRecordMode(record)),
      onCopy: () {
        Clipboard.setData(ClipboardData(text: record.translatedText));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã sao chép văn bản!')));
      },
      onRatingChanged: (rating) => _updateRecordRating(context, record, rating),
      onFavorite: () => _toggleFavoriteRecord(context, record.id, isStarred),
    );
  }

  // ignore: unused_element
  Widget _buildMobileChatHeader(
    BuildContext context,
    String uiLang,
    bool isDark,
    Color textColor,
    Color hintColor,
    Color accentColor,
  ) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16181D) : const Color(0xFFF7F9FC),
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFE4E7EC),
            ),
          ),
        ),
        child: BlocBuilder<TranslationBloc, TranslationState>(
          builder: (context, state) {
            return Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF202329) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFE4E7EC),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppTrans.t(uiLang, state.sourceLang.toLowerCase()),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: InkResponse(
                            radius: 22,
                            onTap: () => context.read<TranslationBloc>().add(
                              SwapLanguagesEvent(),
                            ),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                color: accentColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            AppTrans.t(uiLang, state.targetLang.toLowerCase()),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildMobileHeaderButton(
                  icon: Icons.add_rounded,
                  color: accentColor,
                  tooltip: AppTrans.t(uiLang, 'new'),
                  onPressed: () =>
                      context.read<TranslationBloc>().add(ClearSessionEvent()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileHeaderButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMobileEmptyState(
    String uiLang,
    Color hintColor,
    Color accentColor,
  ) {
    return Center(
      key: const ValueKey('mobile-empty-state'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.translate_rounded,
                size: 42,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppTrans.t(uiLang, 'start_chat'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: hintColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMobileLoadingBubble(
    bool isDark,
    Color bubbleColor,
    Color accentColor,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18, right: 72),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          border: Border.all(
            color: isDark ? Colors.white24 : TranslatorColors.border,
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: accentColor,
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMobileMessagePair({
    required BuildContext context,
    required TranslationRecord record,
    required String uiLang,
    required bool isDark,
    required bool isStarred,
    required Color textColor,
    required Color hintColor,
    required Color accentColor,
    required Color sourceBubbleColor,
    required Color targetBubbleColor,
  }) {
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE4E7EC);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: Container(
                margin: const EdgeInsets.only(left: 56, bottom: 8),
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                decoration: BoxDecoration(
                  color: sourceBubbleColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border.all(color: borderColor, width: 1.3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.16 : 0.05,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppTrans.t(uiLang, record.sourceLang.toLowerCase()),
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.sourceText,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMobileInlineAction(
                      icon: Icons.edit_outlined,
                      color: hintColor,
                      onTap: () {
                        _inputController.text = record.sourceText;
                        _inputController.selection = TextSelection.collapsed(
                          offset: _inputController.text.length,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Container(
                margin: const EdgeInsets.only(right: 34),
                padding: const EdgeInsets.fromLTRB(16, 12, 14, 10),
                decoration: BoxDecoration(
                  color: targetBubbleColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: isDark ? Colors.white24 : TranslatorColors.border,
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.16 : 0.05,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTrans.t(uiLang, record.targetLang.toLowerCase()),
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.translatedText,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFD7E5FF)
                            : const Color(0xFF173B72),
                        fontSize: 16,
                        height: 1.42,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _RatingBar(
                          rating: record.rating,
                          onRatingChanged: (rating) =>
                              _updateRecordRating(context, record, rating),
                        ),
                        _buildMobileInlineAction(
                          icon: Icons.volume_up_outlined,
                          color: accentColor,
                          onTap: () => _speak(
                            record.translatedText,
                            _getRecordMode(record),
                          ),
                        ),
                        _buildMobileInlineAction(
                          icon: Icons.copy_rounded,
                          color: accentColor,
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: record.translatedText),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép văn bản!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        _buildMobileInlineAction(
                          icon: isStarred
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: isStarred ? Colors.amber : accentColor,
                          onTap: () => _toggleFavoriteRecord(
                            context,
                            record.id,
                            isStarred,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInlineAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMobileComposer(
    BuildContext context,
    String uiLang,
    bool isDark,
    Color textColor,
    Color hintColor,
    Color composerColor,
    Color accentColor,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16181D) : const Color(0xFFF7F9FC),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFE4E7EC),
            ),
          ),
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _inputController,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: composerColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: hasText
                            ? accentColor.withValues(alpha: 0.38)
                            : (isDark
                                  ? Colors.white10
                                  : TranslatorColors.border),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.18 : 0.06,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _inputController,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: AppTrans.t(uiLang, 'type_here'),
                        hintStyle: TextStyle(fontSize: 15, color: hintColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.fromLTRB(
                          18,
                          14,
                          8,
                          14,
                        ),
                        suffixIcon: hasText
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                color: hintColor,
                                onPressed: _inputController.clear,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: hasText
                        ? accentColor
                        : accentColor.withValues(alpha: isDark ? 0.22 : 0.16),
                    shape: BoxShape.circle,
                    boxShadow: hasText
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: IconButton(
                    onPressed: hasText ? _handleTranslate : null,
                    icon: Icon(
                      Icons.send_rounded,
                      color: hasText
                          ? (isDark ? const Color(0xFF102A43) : Colors.white)
                          : accentColor,
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

  Widget _buildChatArea(
    BuildContext context,
    bool isDark, {
    required bool isWeb,
  }) {
    if (!isWeb) {
      return _buildMobileChatArea(context, isDark);
    }

    final uiLang = context.watch<SettingsBloc>().state.language;
    final textColor = isDark ? const Color(0xFFE3E3E3) : Colors.black87;
    final hintColor = isDark ? const Color(0xFF8E918F) : Colors.grey.shade600;
    final sourceBubbleColor = isDark
        ? const Color(0xFF282A2C)
        : Colors.grey.shade100;
    final targetBubbleColor = isDark
        ? const Color(0xFF0D293E)
        : Colors.blue.shade50;
    final targetLabelColor = isDark
        ? const Color(0xFFA8C7FA)
        : Colors.blue.shade600;
    final targetTextColor = isDark
        ? const Color(0xFFA8C7FA)
        : Colors.blue.shade900;
    final inputFillColor = isDark
        ? const Color(0xFF282A2C)
        : Colors.grey.shade100;
    final sendBtnColor = isDark ? const Color(0xFFA8C7FA) : Colors.blue;
    final sendIconColor = isDark ? const Color(0xFF0D293E) : Colors.white;
    final double paddingHorizontal = isWeb ? 28.0 : 16.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            paddingHorizontal,
            isWeb ? 18 : 12,
            paddingHorizontal,
            12,
          ),
          child: _buildChatHeader(
            context,
            isDark,
            isWeb,
            uiLang,
            sendBtnColor,
            hintColor,
            textColor,
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        Expanded(
          child: Container(
            color: isDark ? Colors.transparent : Colors.white,
            child: BlocConsumer<TranslationBloc, TranslationState>(
              listener: (context, state) {
                if (state.error != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.error!)));
                }
                if (!state.isLoading && state.sessionRecords.isNotEmpty) {
                  _scrollToBottom();
                  context.read<HistoryBloc>().add(LoadHistoryEvent());
                }
              },
              builder: (context, state) {
                if (state.sessionRecords.isEmpty && !state.isLoading) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            size: 80,
                            color: hintColor.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppTrans.t(uiLang, 'start_chat'),
                            style: TextStyle(color: hintColor, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return BlocBuilder<HistoryBloc, HistoryState>(
                  builder: (context, historyState) {
                    return ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: paddingHorizontal,
                        vertical: 18,
                      ),
                      itemCount:
                          state.sessionRecords.length +
                          (state.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.sessionRecords.length &&
                            state.isLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final record = state.sessionRecords[index];
                        final isStarred = _isFavoriteRecord(
                          historyState,
                          record,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(
                                  bottom: 10,
                                  left: 48,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: sourceBubbleColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white24
                                        : TranslatorColors.border,
                                    width: 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.18 : 0.05,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 7),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppTrans.t(
                                        uiLang,
                                        record.sourceLang.toLowerCase(),
                                      ),
                                      style: TextStyle(
                                        color: hintColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      record.sourceText,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => _speakSourceText(
                                            record.sourceText,
                                            record.sourceLang,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: Icon(
                                              Icons.volume_up_outlined,
                                              size: 16,
                                              color: hintColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        InkWell(
                                          onTap: () => _inputController.text =
                                              record.sourceText,
                                          child: Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: Icon(
                                              Icons.edit_outlined,
                                              size: 16,
                                              color: hintColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(
                                  bottom: 24,
                                  right: 48,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: targetBubbleColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white24
                                        : TranslatorColors.border,
                                    width: 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.18 : 0.05,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 7),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTrans.t(
                                        uiLang,
                                        record.targetLang.toLowerCase(),
                                      ),
                                      style: TextStyle(
                                        color: targetLabelColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      record.translatedText,
                                      style: TextStyle(
                                        color: targetTextColor,
                                        fontSize: 15,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Divider(
                                      height: 1,
                                      color: isDark
                                          ? Colors.blue.withValues(alpha: 0.1)
                                          : Colors.blue.shade100,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        _RatingBar(
                                          rating: record.rating,
                                          onRatingChanged: (rating) =>
                                              _updateRecordRating(
                                                context,
                                                record,
                                                rating,
                                              ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () => _speak(
                                                record.translatedText,
                                                _getRecordMode(record),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  4.0,
                                                ),
                                                child: Icon(
                                                  Icons.volume_up_outlined,
                                                  size: 20,
                                                  color: targetLabelColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            InkWell(
                                              onTap: () {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: record.translatedText,
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Đã sao chép văn bản!",
                                                    ),
                                                    duration: Duration(
                                                      seconds: 1,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  4.0,
                                                ),
                                                child: Icon(
                                                  Icons.copy_rounded,
                                                  size: 18,
                                                  color: targetLabelColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            InkWell(
                                              onTap: () {
                                                _toggleFavoriteRecord(
                                                  context,
                                                  record.id,
                                                  isStarred,
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      isStarred
                                                          ? 'Đã bỏ Yêu thích!'
                                                          : 'Đã thêm vào mục Yêu thích!',
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 1,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  4.0,
                                                ),
                                                child: Icon(
                                                  isStarred
                                                      ? Icons.star_rounded
                                                      : Icons
                                                            .star_border_rounded,
                                                  size: 24,
                                                  color: isStarred
                                                      ? Colors.amber
                                                      : targetLabelColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              paddingHorizontal,
              10,
              paddingHorizontal,
              isWeb ? 24 : 14,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.transparent : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.05,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _inputController,
                      minLines: isWeb ? 2 : 1,
                      maxLines: 8,
                      style: TextStyle(fontSize: 15, color: textColor),
                      decoration: InputDecoration(
                        hintText: AppTrans.t(uiLang, 'type_here'),
                        hintStyle: TextStyle(fontSize: 15, color: hintColor),
                        filled: true,
                        fillColor: inputFillColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        suffixIcon: _inputController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                color: hintColor,
                                onPressed: () {
                                  _inputController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey.shade700
                                : TranslatorColors.border,
                            width: 1.4,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: sendBtnColor,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: EdgeInsets.only(bottom: isWeb ? 10.0 : 4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sendBtnColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: sendBtnColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: sendIconColor,
                        size: 22,
                      ),
                      onPressed: _handleTranslate,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. GIAO DIỆN MOBILE
  // ===========================================================================
  Widget _buildMobileLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131314)
          : const Color(0xFFF8FAFF),
      body: SafeArea(
        top: true,
        bottom: false,
        child: _buildChatArea(context, isDark, isWeb: false),
      ),
      bottomNavigationBar: const TranslatorBottomNav(currentIndex: 0),
    );
  }

  // ignore: unused_element
  Widget _buildMobileBottomNav(BuildContext context, String lang, bool isDark) {
    final accentColor = isDark
        ? const Color(0xFFA8C7FA)
        : const Color(0xFF2563EB);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181D) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE4E7EC),
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: 0,
        height: 66,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF16181D) : Colors.white,
        indicatorColor: accentColor.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          if (index == 0) return;
          final args = {'from': 0, 'to': index};
          if (index == 1) {
            Navigator.pushReplacementNamed(
              context,
              '/history',
              arguments: args,
            );
          }
          if (index == 2) {
            Navigator.pushReplacementNamed(
              context,
              '/settings',
              arguments: args,
            );
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: accentColor),
            label: AppTrans.t(lang, 'home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded, color: accentColor),
            label: AppTrans.t(lang, 'history'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: accentColor),
            label: AppTrans.t(lang, 'settings'),
          ),
        ],
      ),
    );
  }
}

class _MobileHomeHeader extends StatelessWidget {
  final String uiLang;
  final String sourceLang;
  final String targetLang;
  final bool offline;
  final VoidCallback onCloudTap;
  final VoidCallback onNewTap;
  final VoidCallback onSwap;

  const _MobileHomeHeader({
    required this.uiLang,
    required this.sourceLang,
    required this.targetLang,
    required this.offline,
    required this.onCloudTap,
    required this.onNewTap,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF131314)
        : const Color(0xFFF8FAFF);
    final surfaceColor = isDark ? const Color(0xFF1E1F20) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF303134)
        : const Color(0xFFE0E5EE);
    final textColor = isDark
        ? const Color(0xFFE8EAED)
        : const Color(0xFF101828);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const TranslatorLogo(size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppTrans.t(uiLang, 'app_name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _RoundHeaderButton(
                icon: offline ? Icons.cloud_off_rounded : Icons.cloud_rounded,
                onTap: onCloudTap,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.035),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppTrans.t(uiLang, sourceLang.toLowerCase()),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      InkResponse(
                        radius: 24,
                        onTap: onSwap,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE9F0FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: Color(0xFF1769E8),
                            size: 22,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          AppTrans.t(uiLang, targetLang.toLowerCase()),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _RoundHeaderButton(icon: Icons.add_rounded, onTap: onNewTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundHeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF263B5E) : const Color(0xFFE4ECFF),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: isDark ? const Color(0xFFA8C7FA) : const Color(0xFF1769E8),
            size: 25,
          ),
        ),
      ),
    );
  }
}

class _MobileInlineLoading extends StatelessWidget {
  final String sourceText;

  const _MobileInlineLoading({required this.sourceText});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark
        ? const Color(0xFFA8C7FA)
        : const Color(0xFF1769E8);
    final hintColor = isDark
        ? const Color(0xFFBDC1C6)
        : const Color(0xFF697386);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: accentColor,
              strokeWidth: 2.2,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              sourceText.isEmpty ? 'Translating...' : sourceText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: hintColor, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileEmptyState extends StatelessWidget {
  final String uiLang;

  const _MobileEmptyState({required this.uiLang});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark
        ? const Color(0xFFBDC1C6)
        : const Color(0xFF697386);
    return Center(
      key: const ValueKey('mobile-empty'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF263B5E) : const Color(0xFFE4ECFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.translate_rounded,
              color: isDark ? const Color(0xFFA8C7FA) : const Color(0xFF1769E8),
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppTrans.t(uiLang, 'start_chat'),
            style: TextStyle(
              color: hintColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _MobileResultContent extends StatelessWidget {
  final TranslationRecord record;
  final String uiLang;
  final bool isStarred;
  final VoidCallback onEdit;
  final VoidCallback onSpeakSource;
  final VoidCallback onSpeakTarget;
  final VoidCallback onCopy;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onFavorite;

  const _MobileResultContent({
    required this.record,
    required this.uiLang,
    required this.isStarred,
    required this.onEdit,
    required this.onSpeakSource,
    required this.onSpeakTarget,
    required this.onCopy,
    required this.onRatingChanged,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sourceCardColor = isDark ? const Color(0xFF242528) : Colors.white;
    final targetCardColor = isDark
        ? const Color(0xFF102A43)
        : const Color(0xFFEAF2FF);
    final borderColor = isDark
        ? const Color(0xFF303134)
        : const Color(0xFFE2E6EE);
    final textColor = isDark
        ? const Color(0xFFE8EAED)
        : const Color(0xFF101828);
    final hintColor = isDark
        ? const Color(0xFFBDC1C6)
        : const Color(0xFF667085);
    final accentColor = isDark
        ? const Color(0xFFA8C7FA)
        : const Color(0xFF1769E8);
    return Padding(
      key: ValueKey('mobile-result-${record.id}'),
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: sourceCardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppTrans.t(uiLang, record.sourceLang.toLowerCase()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record.sourceText,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _SoftCircleIcon(
                          icon: Icons.volume_up_outlined,
                          onTap: onSpeakSource,
                        ),
                        const SizedBox(width: 8),
                        _SoftCircleIcon(
                          icon: Icons.edit_outlined,
                          onTap: onEdit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                decoration: BoxDecoration(
                  color: targetCardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF244965)
                        : const Color(0xFFDCE9FF),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1769E8).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTrans.t(uiLang, record.targetLang.toLowerCase()),
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      record.translatedText,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _MobileRatingStars(
                          rating: record.rating,
                          onRatingChanged: onRatingChanged,
                        ),
                        const Spacer(),
                        _BlueCircleIcon(
                          icon: Icons.volume_up_outlined,
                          onTap: onSpeakTarget,
                        ),
                        const SizedBox(width: 8),
                        _BlueCircleIcon(
                          icon: Icons.copy_rounded,
                          onTap: onCopy,
                        ),
                        const SizedBox(width: 8),
                        _BlueCircleIcon(
                          icon: isStarred
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          iconColor: isStarred ? Colors.amber : null,
                          onTap: onFavorite,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileRatingStars extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const _MobileRatingStars({
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedRating = rating.clamp(0, 5).toInt();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        final selected = value <= normalizedRating;
        return InkResponse(
          radius: 20,
          onTap: () => onRatingChanged(value == normalizedRating ? 0 : value),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              selected ? Icons.star_rounded : Icons.star_border_rounded,
              color: const Color(0xFFFFC400),
              size: 21,
            ),
          ),
        );
      }),
    );
  }
}

class _MobileInputBar extends StatelessWidget {
  final TextEditingController controller;
  final String uiLang;
  final String sourceLanguage;
  final VoidCallback onSpeak;
  final VoidCallback onSubmit;

  const _MobileInputBar({
    required this.controller,
    required this.uiLang,
    required this.sourceLanguage,
    required this.onSpeak,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF131314)
        : const Color(0xFFF8FAFF);
    final surfaceColor = isDark ? const Color(0xFF1E1F20) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF303134)
        : const Color(0xFFE0E5EE);
    final textColor = isDark
        ? const Color(0xFFE8EAED)
        : const Color(0xFF101828);
    final hintColor = isDark
        ? const Color(0xFFBDC1C6)
        : const Color(0xFF697386);
    final accentColor = isDark
        ? const Color(0xFFA8C7FA)
        : const Color(0xFF1769E8);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                style: TextStyle(color: textColor, fontSize: 16, height: 1.2),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: AppTrans.t(uiLang, 'type_here'),
                  hintStyle: TextStyle(color: hintColor, fontSize: 16),
                  contentPadding: const EdgeInsets.fromLTRB(18, 15, 6, 13),
                  suffixIcon: hasText
                      ? IconButton(
                          tooltip: 'TTS $sourceLanguage',
                          icon: const Icon(Icons.volume_up_outlined),
                          color: accentColor,
                          onPressed: onSpeak,
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: isDark ? const Color(0xFF263B5E) : const Color(0xFFE4ECFF),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSubmit,
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.send_rounded, color: accentColor, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SoftCircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF303134) : const Color(0xFFF1F4F9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            color: isDark ? const Color(0xFFBDC1C6) : const Color(0xFF667085),
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _BlueCircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _BlueCircleIcon({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor = isDark
        ? const Color(0xFFA8C7FA)
        : const Color(0xFF1769E8);
    return Material(
      color: isDark ? const Color(0xFF263B5E) : const Color(0xFFDDEAFF),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: iconColor ?? defaultIconColor, size: 20),
        ),
      ),
    );
  }
}

class _RatingBar extends StatefulWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const _RatingBar({required this.rating, required this.onRatingChanged});

  @override
  State<_RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<_RatingBar> {
  @override
  Widget build(BuildContext context) {
    final normalizedRating = widget.rating.clamp(0, 5).toInt();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        return GestureDetector(
          onTap: () =>
              widget.onRatingChanged(value == normalizedRating ? 0 : value),
          child: Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Icon(
              value <= normalizedRating
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: Colors.amber,
              size: 24,
            ),
          ),
        );
      }),
    );
  }
}
