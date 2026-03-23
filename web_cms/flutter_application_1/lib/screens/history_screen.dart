// File: lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/translation/translation_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../shared/app_translations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Tải lại danh sách lịch sử khi mở màn hình này
    context.read<HistoryBloc>().add(LoadHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    final uiLang = context.watch<SettingsBloc>().state.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xFF131314) : Colors.grey.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? const Color(0xFF8E918F) : Colors.grey.shade600;
    final cardColor = isDark ? const Color(0xFF1E1F20) : Colors.white;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        title: Text(AppTrans.t(uiLang, 'history'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              context.read<HistoryBloc>().add(ClearAllHistoryEvent());
            },
            child: Text(AppTrans.t(uiLang, 'clear_all'), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1, color: dividerColor),
        ),
      ),
      
      // DANH SÁCH LỊCH SỬ CHAT (SESSIONS)
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HistoryLoaded) {
            if (state.records.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, size: 80, color: hintColor.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(AppTrans.t(uiLang, 'empty_history'), style: TextStyle(color: hintColor, fontSize: 16)),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.records.length,
              itemBuilder: (context, index) {
                final record = state.records[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.blue),
                    ),
                    title: Text(
                      record.sourceText, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis, 
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        record.translatedText, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis, 
                        style: TextStyle(color: hintColor, fontSize: 14)
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                      onPressed: () {
                        // Xóa nguyên phiên chat
                        context.read<HistoryBloc>().add(DeleteHistoryItemEvent(record.sessionId));
                      },
                    ),
                    onTap: () {
                      // 1. Nạp dữ liệu của phiên chat này vào Não (TranslationBloc)
                      context.read<TranslationBloc>().add(LoadSessionEvent(record.sessionId));
                      
                      // 2. Chuyển người dùng quay lại Tab Home (Màn hình chat chính)
                      Navigator.pushReplacementNamed(context, '/home', arguments: {'from': 1, 'to': 0});
                    },
                  ),
                );
              },
            );
          } else if (state is HistoryError) {
            return Center(child: Text("Lỗi: ${state.message}", style: const TextStyle(color: Colors.red)));
          }
          return const SizedBox();
        },
      ),
      
      // THANH ĐIỀU HƯỚNG DƯỚI ĐÁY (Giữ nguyên cấu trúc điều hướng Mobile)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: dividerColor, width: 1.0))),
        child: BottomNavigationBar(
          currentIndex: 1, // Tab Lịch sử đang được chọn
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1E1F20) : Colors.white,
          selectedItemColor: isDark ? const Color(0xFFA8C7FA) : Colors.blue,
          unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey,
          onTap: (index) {
            if (index == 1) return;
            final args = {'from': 1, 'to': index};
            if (index == 0) Navigator.pushReplacementNamed(context, '/home', arguments: args);
            if (index == 2) Navigator.pushReplacementNamed(context, '/settings', arguments: args);
          },
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home), label: AppTrans.t(uiLang, 'home')),
            BottomNavigationBarItem(icon: const Icon(Icons.history), label: AppTrans.t(uiLang, 'history')),
            BottomNavigationBarItem(icon: const Icon(Icons.settings), label: AppTrans.t(uiLang, 'settings')),
          ],
        ),
      ),
    );
  }
}