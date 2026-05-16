import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/translation/translation_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import 'app_translations.dart';

// --- AppBar dùng chung ---
AppBar buildFigmaAppBar(BuildContext context, String titleKey) {
  final lang = context.watch<SettingsBloc>().state.language;
  
  // XÓA BỎ MÀU CỨNG Ở ĐÂY. 
  // Để AppBar tự động lấy màu Nền (Đen/Xanh) và màu Chữ (Trắng/Xám) từ file main.dart
  return AppBar(
    elevation: 0,
    title: Text(AppTrans.t(lang, titleKey)), 
  );
}

// --- Bộ chọn Ngôn ngữ ---
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final uiLang = context.watch<SettingsBloc>().state.language; 
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Màu chữ và icon cho thanh chọn ngôn ngữ theo giao diện
    final textColor = isDark ? const Color(0xFFA8C7FA) : Colors.blue;

    return BlocBuilder<TranslationBloc, TranslationState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: Text(
                AppTrans.t(uiLang, state.sourceLang), 
                textAlign: TextAlign.right,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: IconButton(
                icon: Icon(Icons.swap_horiz, color: textColor),
                onPressed: () => context.read<TranslationBloc>().add(SwapLanguagesEvent()),
              ),
            ),
            Expanded(
              child: Text(
                AppTrans.t(uiLang, state.targetLang), 
                textAlign: TextAlign.left,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        );
      }
    );
  }
}

// --- Thanh Điều hướng Bottom ---
// --- Thanh Điều hướng Bottom ---
class FigmaBottomNav extends StatelessWidget {
  final int currentIndex;
  const FigmaBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsBloc>().state.language; 
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: isDark ? const Color(0xFF1E1F20) : Colors.white,
      selectedItemColor: isDark ? const Color(0xFFA8C7FA) : Colors.blue,
      unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey,
      onTap: (index) {
        if (index == currentIndex) return;
        
        // Truyền tham số báo cáo Vị trí hiện tại (from) và Vị trí sắp tới (to)
        final args = {'from': currentIndex, 'to': index};
        
        if (index == 0) Navigator.pushReplacementNamed(context, '/home', arguments: args);
        if (index == 1) Navigator.pushReplacementNamed(context, '/history', arguments: args);
        if (index == 2) Navigator.pushReplacementNamed(context, '/settings', arguments: args);
      },
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home), label: AppTrans.t(lang, 'home')),
        BottomNavigationBarItem(icon: const Icon(Icons.history), label: AppTrans.t(lang, 'history')),
        BottomNavigationBarItem(icon: const Icon(Icons.settings), label: AppTrans.t(lang, 'settings')),
      ],
    );
  }
}