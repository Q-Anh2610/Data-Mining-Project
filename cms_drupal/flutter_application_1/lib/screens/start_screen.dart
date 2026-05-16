// File: lib/screens/start_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../shared/app_translations.dart';
import '../services/model_loader_service.dart'; // Import service kiểm tra file

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _isAccepted = false;
  bool _isChecking = false; // Trạng thái đang quét file model

  // ===========================================================================
  // LOGIC XỬ LÝ THEO WORKFLOW (BƯỚC 1)
  // ===========================================================================
  void _handleStart(BuildContext context) async {
    setState(() => _isChecking = true);

    final modelService = ModelLoaderService();
    // Gọi hàm kiểm tra file .tflite trong máy
    bool hasModel = await modelService.isModelDownloaded();

    setState(() => _isChecking = false);

    if (!mounted) return;

    if (hasModel) {
      // NHÁNH YES: Vào thẳng Home
      Navigator.pushReplacementNamed(context, '/home', arguments: {'from': -1, 'to': 0});
    } else {
      // NHÁNH NO: Hiện màn hình Note hướng dẫn (Instruction)
      Navigator.pushNamed(context, '/instruction');
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
            return _buildMobileLayout(context, lang, isDark, textColor, bgColor);
          }
        },
      ),
    );
  }

  // ===========================================================================
  // 1. GIAO DIỆN WEB (GIỮ NGUYÊN STYLE, CHỈ CẬP NHẬT NÚT BẤM)
  // ===========================================================================
  Widget _buildWebLayout(BuildContext context, String lang, bool isDark, Color textColor) {
    final cardColor = isDark ? const Color(0xFF1E1F20) : Colors.white;
    
    return Stack(
      fit: StackFit.expand, 
      children: [
        Image.asset(
          'assets/images/earth2.jpg', 
          fit: BoxFit.cover, 
          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF131314)),
        ),
        Container(color: Colors.black.withOpacity(0.65)),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100), 
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 12, 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTrans.t(lang, 'app_name'), 
                          style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1.0)
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppTrans.t(lang, 'app_desc'), 
                          style: TextStyle(fontSize: 20, color: Colors.white.withOpacity(0.8), letterSpacing: 0.5)
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40), 
                  Expanded(
                    flex: 10, 
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 48.0),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40, offset: const Offset(0, 20)),
                        ]
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogo(isDark),
                          const SizedBox(height: 32),
                          Text(
                            AppTrans.t(lang, 'start_chat'), 
                            textAlign: TextAlign.center, 
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
                          ),
                          const SizedBox(height: 40),
                          _buildInteractionArea(context, lang, isDark ? Colors.white : Colors.black87, isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  // ===========================================================================
  // 2. GIAO DIỆN MOBILE (GIỮ NGUYÊN STYLE, CHỈ CẬP NHẬT NÚT BẤM)
  // ===========================================================================
  Widget _buildMobileLayout(BuildContext context, String lang, bool isDark, Color textColor, Color bgColor) {
    final bottomSheetColor = isDark ? const Color(0xFF1E1F20) : const Color(0xFFF8F9FA);

    return Stack(
      children: [
        Positioned(
          top: 0, left: 0, right: 0,
          height: MediaQuery.of(context).size.height * 0.55,
          child: Opacity(
            opacity: isDark ? 0.15 : 0.8,
            child: Image.asset('assets/images/earth.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.public, size: 200, color: Colors.grey.withOpacity(0.2))),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          height: MediaQuery.of(context).size.height * 0.55,
          child: Container(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgColor.withOpacity(0.1), bgColor.withOpacity(0.5), bgColor])),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildLogo(isDark),
              const SizedBox(height: 28),
              Text(AppTrans.t(lang, 'app_name'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              Text(AppTrans.t(lang, 'app_desc'), style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.grey.shade600, letterSpacing: 0.2)),
              const Spacer(flex: 3),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: bottomSheetColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -5))]
                ),
                child: _buildInteractionArea(context, lang, textColor, isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282A2C) : Colors.white, 
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 20, offset: const Offset(0, 8))]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset('assets/images/logo.jpg', width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.g_translate, size: 60, color: Colors.redAccent)),
      ),
    );
  }

  // ===========================================================================
  // KHU VỰC TƯƠNG TÁC (NÚT START ĐÃ CẬP NHẬT LOGIC KIỂM TRA)
  // ===========================================================================
  Widget _buildInteractionArea(BuildContext context, String lang, Color textColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24, height: 24,
              child: Checkbox(
                value: _isAccepted,
                activeColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onChanged: (value) => setState(() => _isAccepted = value ?? false),
              ),
            ),
            const SizedBox(width: 12),
            Text(AppTrans.t(lang, 'i_accept'), style: TextStyle(color: textColor, fontSize: 14)),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/privacy'), 
              child: Text(AppTrans.t(lang, 'privacy_policy'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade600, decoration: TextDecoration.underline, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F), 
              disabledBackgroundColor: isDark ? const Color(0xFF333333) : Colors.grey.shade300, 
              foregroundColor: Colors.black87,
              disabledForegroundColor: Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: _isAccepted ? 4 : 0,
              shadowColor: const Color(0xFFFFD54F).withOpacity(0.5),
            ),
            // CẬP NHẬT: Thay vì gọi Navigator trực tiếp, ta gọi hàm xử lý _handleStart
            onPressed: (_isAccepted && !_isChecking) ? () => _handleStart(context) : null,
            child: _isChecking 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
              : Text(AppTrans.t(lang, 'start_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
          ),
        ),
      ],
    );
  }
}