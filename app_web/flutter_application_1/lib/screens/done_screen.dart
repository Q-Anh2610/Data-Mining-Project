import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/settings/settings_bloc.dart';
import '../blocs/translation/translation_bloc.dart';
import '../shared/app_translations.dart';
import '../shared/translator_ui.dart';

class DoneScreen extends StatelessWidget {
  const DoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uiLang = context.watch<SettingsBloc>().state.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = isDark ? const Color(0xFF1E1F20) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF303134)
        : TranslatorColors.subtleBorder;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const TranslatorTopBar(),
      body: BlocBuilder<TranslationBloc, TranslationState>(
        builder: (context, state) {
          if (state.sessionRecords.isEmpty) {
            return Center(child: Text(AppTrans.t(uiLang, 'no_data')));
          }

          final record = state.sessionRecords.last;
          return Column(
            children: [
              SizedBox(
                height: 104,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(36, 38, 36, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppTrans.t(uiLang, state.sourceLang.toLowerCase()),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFA8C7FA)
                                : TranslatorColors.selectedBlue,
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.grey,
                        size: 31,
                      ),
                      Expanded(
                        child: Text(
                          AppTrans.t(uiLang, state.targetLang.toLowerCase()),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFA8C7FA)
                                : TranslatorColors.selectedBlue,
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.volume_up_outlined,
                            color: TranslatorColors.softText,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppTrans.t(uiLang, record.sourceLang.toLowerCase()),
                            style: const TextStyle(
                              color: TranslatorColors.softText,
                              fontSize: 20,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: TranslatorColors.softText,
                              size: 30,
                            ),
                            onPressed: () {
                              context.read<TranslationBloc>().add(
                                ClearSessionEvent(),
                              );
                              Navigator.pushReplacementNamed(context, '/home');
                            },
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.035),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          record.sourceText,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 25,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 58),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 34),
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
                        constraints: const BoxConstraints(minHeight: 140),
                        decoration: BoxDecoration(
                          color: TranslatorColors.blue,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF0A7BD0),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TranslatorColors.blue.withValues(
                                alpha: 0.22,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    AppTrans.t(
                                      uiLang,
                                      record.targetLang.toLowerCase(),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    color: Colors.white,
                                    size: 29,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: record.translatedText,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã sao chép văn bản!'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                record.translatedText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  height: 1.18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const TranslatorBottomNav(currentIndex: 0),
    );
  }
}
