import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../shared/shared_widgets.dart';
import '../blocs/translation/translation_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../shared/app_translations.dart'; // Import từ điển

class DoneScreen extends StatelessWidget {
  const DoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy ngôn ngữ giao diện hiện tại
    final uiLang = context.watch<SettingsBloc>().state.language;

    return Scaffold(
      // Dịch tiêu đề AppBar
      appBar: buildFigmaAppBar(context, 'title'),
      body: BlocBuilder<TranslationBloc, TranslationState>(
        builder: (context, state) {
          if (state.sessionRecords.isNotEmpty) {
            // Lấy câu vừa dịch xong (câu cuối cùng trong danh sách)
            final record = state.sessionRecords.last;
            
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LanguageSelector(),
                  const SizedBox(height: 20),
                  
                  // Khung văn bản gốc
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dịch tên ngôn ngữ Nguồn
                      Text(AppTrans.t(uiLang, state.sourceLang), style: Theme.of(context).textTheme.bodySmall),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 24),
                        onPressed: () {
                          context.read<TranslationBloc>().add(ClearSessionEvent());
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                      ),
                    ],
                  ),
                  Text(record.sourceText, style: Theme.of(context).textTheme.bodyLarge),
                  
                  const SizedBox(height: 30),
                  
                  // Khung kết quả dịch
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Dịch tên ngôn ngữ Đích
                            Text(AppTrans.t(uiLang, state.targetLang), style: TextStyle(color: Colors.white70, fontSize: Theme.of(context).textTheme.bodySmall?.fontSize)),
                            const Icon(Icons.copy, color: Colors.white70, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          record.translatedText, 
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize, 
                            color: Colors.white, 
                            fontWeight: FontWeight.w500
                          )
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          // Dịch thông báo "Không có dữ liệu"
          return Center(child: Text(AppTrans.t(uiLang, 'no_data')));
        },
      ),
      bottomNavigationBar: const FigmaBottomNav(currentIndex: 0),
    );
  }
}