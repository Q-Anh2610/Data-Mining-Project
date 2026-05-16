// File: lib/screens/start_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../shared/app_translations.dart';
import '../shared/translator_ui.dart';
import '../services/model_loader_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _isAccepted = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkAutoStart();
  }

  Future<void> _checkAutoStart() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAccepted = prefs.getBool('has_confirmed_policy_terms') ?? false;
    if (!mounted) return;

    if (!hasAccepted) {
      setState(() => _isAccepted = false);
      return;
    }

    setState(() => _isAccepted = true);
  }

  // ===========================================================================
  // LOGIC XỬ LÝ THEO WORKFLOW (ĐÃ NÂNG CẤP CHỐNG KẸT 100%)
  // ===========================================================================
  Future<void> _handleStart(BuildContext context) async {
    if (!_isAccepted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_confirmed_policy_terms', true);
    await prefs.setBool('has_accepted_pp', true);

    if (!context.mounted) return;
    await _continueAfterAccepted(context);
  }

  Future<void> _continueAfterAccepted(BuildContext context) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final modelService = ModelLoaderService();

      // 2. Chờ kiểm tra file, ép buộc tối đa 3 giây để CHỐNG TREO APP
      bool hasModel = await modelService.isModelDownloaded().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint("Quá thời gian kiểm tra Model! Bỏ qua để chống kẹt.");
          return false; // Mặc định là chưa có để đi tiếp
        },
      );

      if (!context.mounted) return;

      // 3. Tắt vòng tròn quay quay
      setState(() => _isChecking = false);

      // 4. CHUYỂN TRANG (Dùng pushNamedAndRemoveUntil để xóa sạch bộ nhớ đệm, chống đơ 100%)
      if (hasModel) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {'from': -1, 'to': 0},
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/instruction',
          (route) => false,
        );
      }
    } catch (e) {
      // NẾU CODE SERVICE CÓ LỖI (CRASH NGẦM), BẮT LỖI VÀ ÉP CHUYỂN TRANG BẢO VỆ APP
      if (!context.mounted) return;
      setState(() => _isChecking = false);

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/instruction',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsBloc>().state.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF131314) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 850) {
            return _buildWebLayout(context, lang, isDark, textColor);
          } else {
            return _buildMobileLayout(
              context,
              lang,
              isDark,
              textColor,
              bgColor,
            );
          }
        },
      ),
    );
  }

  // ===========================================================================
  // 1. GIAO DIỆN WEB
  // ===========================================================================
  Widget _buildWebLayout(
    BuildContext context,
    String lang,
    bool isDark,
    Color textColor,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/earth2.jpg',
          fit: BoxFit.cover,
          errorBuilder: (ctx, error, stackTrace) =>
              Container(color: const Color(0xFF131314)),
        ),
        Container(color: Colors.black.withValues(alpha: 0.58)),
        SafeArea(
          child: Row(
            children: [
              const Expanded(child: SizedBox.shrink()),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: Container(
                      width: 430,
                      padding: const EdgeInsets.fromLTRB(34, 34, 34, 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: _StartContent(
                        earthAsset: null,
                        earthSize: 0,
                        logo: _buildLogo(false),
                        title: AppTrans.t(lang, 'app_name'),
                        description: AppTrans.t(lang, 'app_desc'),
                        titleColor: Colors.black87,
                        descriptionColor: Colors.black87,
                        interaction: _buildInteractionArea(
                          context,
                          lang,
                          Colors.black87,
                          false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. GIAO DIỆN MOBILE
  // ===========================================================================
  Widget _buildMobileLayout(
    BuildContext context,
    String lang,
    bool isDark,
    Color textColor,
    Color bgColor,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final earthSize = (screenSize.shortestSide * 0.48)
        .clamp(150.0, 220.0)
        .toDouble();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48)
                    .clamp(0.0, double.infinity)
                    .toDouble(),
                maxWidth: double.infinity,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLandscape ? 700 : 420,
                  ),
                  child: isLandscape
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Center(
                                child: _StartEarthImage(size: earthSize * 0.85),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _StartContent(
                                earthAsset: null,
                                earthSize: 0,
                                logo: _buildLogo(isDark),
                                title: AppTrans.t(lang, 'app_name'),
                                description: AppTrans.t(lang, 'app_desc'),
                                titleColor: textColor,
                                descriptionColor: isDark
                                    ? Colors.white70
                                    : Colors.black87,
                                interaction: _buildInteractionArea(
                                  context,
                                  lang,
                                  textColor,
                                  isDark,
                                ),
                              ),
                            ),
                          ],
                        )
                      : _StartContent(
                          earthAsset: 'assets/images/earth.jpg',
                          earthSize: earthSize,
                          logo: _buildLogo(isDark),
                          title: AppTrans.t(lang, 'app_name'),
                          description: AppTrans.t(lang, 'app_desc'),
                          titleColor: textColor,
                          descriptionColor: isDark
                              ? Colors.white70
                              : Colors.black87,
                          interaction: _buildInteractionArea(
                            context,
                            lang,
                            textColor,
                            isDark,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return const TranslatorLogo(size: 78);
  }

  // ===========================================================================
  // KHU VỰC TƯƠNG TÁC
  // ===========================================================================
  Widget _buildInteractionArea(
    BuildContext context,
    String lang,
    Color textColor,
    bool isDark,
  ) {
    final privacyRow = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppTrans.t(lang, 'i_accept'),
            style: TextStyle(color: textColor, fontSize: 15),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/privacy'),
            child: Text(
              AppTrans.t(lang, 'privacy_policy'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textColor,
                fontSize: 15,
                decoration: TextDecoration.underline,
                decorationColor: textColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _PrivacyCheckBox(
            selected: _isAccepted,
            isDark: isDark,
            onTap: () => setState(() => _isAccepted = !_isAccepted),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        privacyRow,
        const SizedBox(height: 34),
        SizedBox(
          width: 176,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TranslatorColors.yellow,
              disabledBackgroundColor: isDark
                  ? const Color(0xFF333333)
                  : Colors.grey.shade300,
              foregroundColor: Colors.black87,
              disabledForegroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
              elevation: 0,
            ),
            onPressed: (_isAccepted && !_isChecking)
                ? () => _handleStart(context)
                : null,
            child: _isChecking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black87,
                    ),
                  )
                : Text(
                    AppTrans.t(lang, 'start_btn').toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _StartContent extends StatelessWidget {
  final String? earthAsset;
  final double earthSize;
  final Widget logo;
  final String title;
  final String description;
  final Color titleColor;
  final Color descriptionColor;
  final Widget interaction;

  const _StartContent({
    required this.earthAsset,
    required this.earthSize,
    required this.logo,
    required this.title,
    required this.description,
    required this.titleColor,
    required this.descriptionColor,
    required this.interaction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (earthAsset != null) ...[
          _StartEarthImage(size: earthSize),
          const SizedBox(height: 18),
        ],
        logo,
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            color: titleColor,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, height: 1.3, color: descriptionColor),
        ),
        const SizedBox(height: 34),
        interaction,
      ],
    );
  }
}

class _PrivacyCheckBox extends StatelessWidget {
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _PrivacyCheckBox({
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? Colors.white : Colors.black87;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.7),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, size: 17, color: Colors.black)
            : null,
      ),
    );
  }
}

class _StartEarthImage extends StatelessWidget {
  final double size;

  const _StartEarthImage({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/earth.jpg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (ctx, error, stackTrace) => SizedBox(
        width: size,
        height: size,
        child: MockWorldMap(height: size),
      ),
    );
  }
}
