// File: lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../shared/app_translations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsBloc>().state.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xFF131314) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    
    // Nhuộm xám nhạt các ô chức năng ở chế độ Sáng để dễ thao tác
    final boxColor = isDark ? const Color(0xFF282A2C) : Colors.grey.shade100;
    final borderColor = isDark ? Colors.transparent : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        title: Text(AppTrans.t(lang, 'settings'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1, color: dividerColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 1. Ô Đổi Theme (Giao diện)
          _buildSettingItem(
            context, 
            icon: Icons.palette_outlined, 
            title: 'Theme', 
            currentValue: context.watch<SettingsBloc>().state.themeMode, 
            items: ['Light', 'Dark'], 
            onChanged: (val) {
              if (val != null) context.read<SettingsBloc>().add(UpdateSettingsEvent(themeMode: val, language: lang, textSize: context.read<SettingsBloc>().state.textSize));
            },
            boxColor: boxColor,
            borderColor: borderColor,
            textColor: textColor,
            lang: lang,
            isDark: isDark
          ),
          const SizedBox(height: 16),
          
          // 2. Ô Đổi Ngôn Ngữ
          _buildSettingItem(
            context, 
            icon: Icons.language_outlined, 
            title: 'Language', 
            currentValue: lang, 
            items: ['English', 'Vietnamese'], 
            onChanged: (val) {
              if (val != null) context.read<SettingsBloc>().add(UpdateSettingsEvent(themeMode: context.read<SettingsBloc>().state.themeMode, language: val, textSize: context.read<SettingsBloc>().state.textSize));
            },
            boxColor: boxColor,
            borderColor: borderColor,
            textColor: textColor,
            lang: lang,
            isDark: isDark
          ),
        ],
      ),
      bottomNavigationBar: _buildMobileBottomNav(context, lang, isDark, dividerColor),
    );
  }

  // WIDGET DỰNG Ô CÀI ĐẶT
  Widget _buildSettingItem(BuildContext context, {required IconData icon, required String title, required String currentValue, required List<String> items, required Function(String?) onChanged, required Color boxColor, required Color borderColor, required Color textColor, required String lang, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5) // Viền đậm 1.5 để nổi bật
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: currentValue,
                dropdownColor: isDark ? const Color(0xFF282A2C) : Colors.white,
                borderRadius: BorderRadius.circular(16), // Bo góc menu trượt
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: textColor),
                items: items.map((String value) => DropdownMenuItem<String>(
                  value: value, 
                  child: Text(AppTrans.t(lang, value.toLowerCase() == 'light' || value.toLowerCase() == 'dark' ? value.toLowerCase() : value), style: TextStyle(color: textColor, fontSize: 16))
                )).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // THANH ĐIỀU HƯỚNG DƯỚI
  Widget _buildMobileBottomNav(BuildContext context, String lang, bool isDark, Color dividerColor) {
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: dividerColor, width: 1.0))),
      child: BottomNavigationBar(
        currentIndex: 2, // Đang ở Tab Settings
        elevation: 0, 
        backgroundColor: isDark ? const Color(0xFF1E1F20) : Colors.white,
        selectedItemColor: isDark ? const Color(0xFFA8C7FA) : Colors.blue,
        unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey,
        onTap: (index) {
          if (index == 2) return;
          final args = {'from': 2, 'to': index};
          if (index == 0) Navigator.pushReplacementNamed(context, '/home', arguments: args);
          if (index == 1) Navigator.pushReplacementNamed(context, '/history', arguments: args);
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: AppTrans.t(lang, 'home')),
          BottomNavigationBarItem(icon: const Icon(Icons.history), label: AppTrans.t(lang, 'history')),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: AppTrans.t(lang, 'settings')),
        ],
      ),
    );
  }
}