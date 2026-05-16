import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/settings/settings_bloc.dart';
import '../blocs/translation/translation_bloc.dart';
import '../shared/app_translations.dart';
import '../shared/translator_ui.dart';

String _settingsOptionLabel(String lang, String value) {
  return AppTrans.t(lang, value.toLowerCase());
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  children: [
                    Center(
                      child: Text(
                        AppTrans.t(lang, 'settings'),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    _SettingsSectionLabel(AppTrans.t(lang, 'app_language')),
                    _SettingsSelectCard(
                      lang: lang,
                      icon: Icons.language_rounded,
                      value: state.language,
                      items: const ['English', 'Vietnamese'],
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(
                          UpdateSettingsEvent(
                            textSize: state.textSize,
                            language: value,
                            themeMode: state.themeMode,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _SettingsSectionLabel(AppTrans.t(lang, 'text_size')),
                    _SettingsSelectCard(
                      lang: lang,
                      icon: Icons.text_fields_rounded,
                      value: state.textSize,
                      items: const ['Small', 'Medium', 'Large'],
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(
                          UpdateSettingsEvent(
                            textSize: value,
                            language: state.language,
                            themeMode: state.themeMode,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _SettingsSectionLabel(AppTrans.t(lang, 'theme')),
                    _SettingsSelectCard(
                      lang: lang,
                      icon: Icons.palette_outlined,
                      value: state.themeMode,
                      items: const ['Light', 'Dark'],
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(
                          UpdateSettingsEvent(
                            textSize: state.textSize,
                            language: state.language,
                            themeMode: value,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _SettingsSectionLabel(AppTrans.t(lang, 'about')),
                    _SettingsAboutCard(
                      lang: lang,
                      onTeamTap: () =>
                          Navigator.pushNamed(context, '/our-team'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const TranslatorBottomNav(currentIndex: 2),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  final String label;

  const _SettingsSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 14),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: isDark ? const Color(0xFFBDC1C6) : const Color(0xFF6F6F6F),
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class _SettingsSelectCard extends StatelessWidget {
  final String lang;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _SettingsSelectCard({
    required this.lang,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1F20) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF303134)
        : const Color(0xFFE0E0E0);
    final textColor = isDark
        ? const Color(0xFFE8EAED)
        : const Color(0xFF202124);
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: surfaceColor,
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item,
              child: Text(
                _settingsOptionLabel(lang, item),
                style: TextStyle(color: textColor),
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 25),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                _settingsOptionLabel(lang, value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: textColor, size: 24),
          ],
        ),
      ),
    );
  }
}

class _SettingsAboutCard extends StatelessWidget {
  final String lang;
  final VoidCallback onTeamTap;

  const _SettingsAboutCard({required this.lang, required this.onTeamTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1F20) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF303134)
        : const Color(0xFFE0E0E0);
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            onTap: onTeamTap,
            child: _AboutRow(
              icon: Icons.groups_rounded,
              title: AppTrans.t(lang, 'our_team'),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6F6F6F),
                size: 28,
              ),
            ),
          ),
          Divider(height: 1, color: borderColor),
          _AboutRow(
            icon: Icons.new_releases_outlined,
            title: AppTrans.t(lang, 'version'),
            trailing: const Text(
              '1.0.0',
              style: TextStyle(color: Color(0xFF777777), fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;

  const _AboutRow({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? const Color(0xFFE8EAED)
        : const Color(0xFF202124);
    return SizedBox(
      height: 66,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 25),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class AppLanguageScreen extends StatelessWidget {
  const AppLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingsBloc>().state;

    return _SettingsSubPage(
      title: AppTrans.t(state.language, 'app_language'),
      child: Column(
        children: [
          _LanguageChoiceTile(
            lang: state.language,
            language: 'English',
            selected: state.language == 'English',
            onTap: () => context.read<SettingsBloc>().add(
              UpdateSettingsEvent(
                textSize: state.textSize,
                language: 'English',
                themeMode: state.themeMode,
              ),
            ),
          ),
          _LanguageChoiceTile(
            lang: state.language,
            language: 'Vietnamese',
            selected: state.language == 'Vietnamese',
            onTap: () => context.read<SettingsBloc>().add(
              UpdateSettingsEvent(
                textSize: state.textSize,
                language: 'Vietnamese',
                themeMode: state.themeMode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TranslationLanguageScreen extends StatelessWidget {
  const TranslationLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsBloc>().state.language;
    final translationState = context.watch<TranslationBloc>().state;

    void selectLanguage(String language) {
      if (translationState.sourceLang != language) {
        context.read<TranslationBloc>().add(SwapLanguagesEvent());
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTrans.t(lang, 'translation_language_updated')),
        ),
      );
    }

    return _SettingsSubPage(
      title: AppTrans.t(lang, 'translation_language'),
      child: Column(
        children: [
          _LanguageChoiceTile(
            lang: lang,
            language: 'English',
            selected: translationState.sourceLang == 'English',
            onTap: () => selectLanguage('English'),
          ),
          _LanguageChoiceTile(
            lang: lang,
            language: 'Vietnamese',
            selected: translationState.sourceLang == 'Vietnamese',
            onTap: () => selectLanguage('Vietnamese'),
          ),
        ],
      ),
    );
  }
}

class OfflineModeScreen extends StatelessWidget {
  const OfflineModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsBloc>().state.language;

    void showMessage(String key) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppTrans.t(lang, key))));
    }

    return _SettingsSubPage(
      title: AppTrans.t(lang, 'offline_mode'),
      child: Column(
        children: [
          _PlainActionRow(
            icon: Icons.file_download_outlined,
            title: AppTrans.t(lang, 'download_offline_mode'),
            onTap: () => showMessage('offline_mode_ready'),
          ),
          _PlainActionRow(
            icon: Icons.delete_outline_rounded,
            title: AppTrans.t(lang, 'delete_offline_mode'),
            onTap: () => showMessage('offline_mode_not_downloaded'),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsBloc>().state.language;

    return _SettingsSubPage(
      title: AppTrans.t(lang, 'about'),
      child: Column(
        children: [
          _SettingsNavRow(
            icon: Icons.diversity_3_rounded,
            title: AppTrans.t(lang, 'our_team'),
            onTap: () => Navigator.pushNamed(context, '/our-team'),
          ),
          _SettingsNavRow(
            icon: Icons.extension_rounded,
            title: AppTrans.t(lang, 'version'),
            onTap: () => Navigator.pushNamed(context, '/version'),
          ),
        ],
      ),
    );
  }
}

class OurTeamScreen extends StatelessWidget {
  const OurTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsBloc>().state.language;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: TranslatorTopBar(title: AppTrans.t(lang, 'our_team')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(38, 24, 34, 24),
        child: Text(
          AppTrans.t(lang, 'team_description'),
          style: TextStyle(
            fontSize: 20,
            height: 1.08,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      bottomNavigationBar: const TranslatorBottomNav(currentIndex: 2),
    );
  }
}

class VersionScreen extends StatelessWidget {
  const VersionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsBloc>().state.language;

    return _SettingsSubPage(
      title: AppTrans.t(lang, 'version'),
      child: const SizedBox.shrink(),
    );
  }
}

class _SettingsSubPage extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSubPage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: TranslatorTopBar(title: title),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
        child: child,
      ),
      bottomNavigationBar: const TranslatorBottomNav(currentIndex: 2),
    );
  }
}

class _SettingsNavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsNavRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 36, child: Icon(icon, color: textColor, size: 28)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20, color: textColor),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textColor, size: 30),
          ],
        ),
      ),
    );
  }
}

class _PlainActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _PlainActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 36, child: Icon(icon, color: textColor, size: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 20, color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageChoiceTile extends StatelessWidget {
  final String lang;
  final String language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChoiceTile({
    required this.lang,
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1F20) : Colors.white;
    final borderColor = selected
        ? (isDark ? const Color(0xFFA8C7FA) : TranslatorColors.selectedBlue)
        : (isDark ? const Color(0xFF303134) : TranslatorColors.softBorder);
    final textColor = isDark ? const Color(0xFFE8EAED) : Colors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 68,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: selected ? 1.4 : 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            LanguageFlag(language: language, size: 30),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                _settingsOptionLabel(lang, language),
                style: TextStyle(fontSize: 20, color: textColor),
              ),
            ),
            if (selected)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: TranslatorColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
