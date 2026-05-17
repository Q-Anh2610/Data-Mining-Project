import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/settings/settings_bloc.dart';
import 'app_translations.dart';

class TranslatorColors {
  static const blue = Color(0xFF1291EF);
  static const selectedBlue = Color(0xFF001CFF);
  static const yellow = Color(0xFFFFE47A);
  static const lavender = Color(0xFF9392F2);
  static const tile = Color(0xFFEFEFEF);
  static const border = Color(0xFFD0D5DD);
  static const softBorder = Color(0xFFD9D9D9);
  static const subtleBorder = Color(0xFFE0E0E0);
  static const softText = Color(0xFFA6A6A6);
  static const danger = Color(0xFFFF4148);
  static const green = Color(0xFF05B51F);
}

enum TranslatorFlagType { us, vietnam }

class TranslatorLanguageFlags {
  static TranslatorFlagType resolve(String language) {
    final normalized = language.toLowerCase().trim();

    if (normalized == 'en' ||
        normalized == 'eng' ||
        normalized == 'us' ||
        normalized == 'usa' ||
        normalized.contains('english') ||
        normalized.contains('anh') ||
        normalized.contains('america') ||
        normalized.contains('mỹ') ||
        normalized.contains('my')) {
      return TranslatorFlagType.us;
    }

    if (normalized == 'vi' ||
        normalized == 'vn' ||
        normalized == 'vie' ||
        normalized.contains('vietnam') ||
        normalized.contains('viet') ||
        normalized.contains('việt')) {
      return TranslatorFlagType.vietnam;
    }

    return TranslatorFlagType.vietnam;
  }
}

class TranslatorTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBack;
  final bool showCloud;
  final bool offline;
  final List<Widget> actions;
  final VoidCallback? onBack;

  const TranslatorTopBar({
    super.key,
    this.title,
    this.showBack = false,
    this.showCloud = true,
    this.offline = false,
    this.actions = const [],
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final foregroundColor = isDark
        ? const Color(0xFFE8EAED)
        : const Color(0xFF101828);
    final iconColor = foregroundColor.withValues(alpha: 0.78);
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: showBack
          ? IconButton(
              icon: Icon(
                Icons.chevron_left_rounded,
                color: iconColor,
                size: 30,
              ),
              onPressed: onBack ?? () => Navigator.maybePop(context),
            )
          : null,
      title: title == null
          ? null
          : Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
      centerTitle: true,
      actions: [
        ...actions,
        if (showCloud)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(
              offline ? Icons.cloud_off_outlined : Icons.cloud_outlined,
              color: iconColor,
              size: 24,
            ),
          ),
      ],
    );
  }
}

class TranslatorBottomNav extends StatelessWidget {
  final int currentIndex;

  const TranslatorBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsBloc>().state.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1F20) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF303134)
        : const Color(0xFFE6ECF5);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            children: [
              _NavItem(
                index: 0,
                currentIndex: currentIndex,
                icon: Icons.home_rounded,
                label: AppTrans.t(lang, 'home'),
              ),
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                icon: Icons.history_rounded,
                label: AppTrans.t(lang, 'history'),
              ),
              _NavItem(
                index: 2,
                currentIndex: currentIndex,
                icon: Icons.settings_rounded,
                label: AppTrans.t(lang, 'settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark
        ? const Color(0xFFA8C7FA)
        : const Color(0xFF1769E8);
    final color = selected ? selectedColor : const Color(0xFF8E8E8E);
    final indicatorColor = isDark
        ? const Color(0xFF263B5E)
        : const Color(0xFFE4ECFF);
    final labelColor = selected
        ? selectedColor
        : (isDark ? const Color(0xFFB8BABF) : const Color(0xFF303030));

    return Expanded(
      child: InkWell(
        onTap: () {
          if (index == currentIndex) return;
          final args = {'from': currentIndex, 'to': index};
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home', arguments: args);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(
              context,
              '/history',
              arguments: args,
            );
          } else {
            Navigator.pushReplacementNamed(
              context,
              '/settings',
              arguments: args,
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: selected ? 58 : 46,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? indicatorColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageFlag extends StatelessWidget {
  final String language;
  final double size;

  const LanguageFlag({super.key, required this.language, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final flag = TranslatorLanguageFlags.resolve(language);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: flag == TranslatorFlagType.us
            ? Colors.white
            : const Color(0xFFE60021),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: flag == TranslatorFlagType.us
          ? _EnglishFlag(size: size)
          : _VietnamFlag(size: size),
    );
  }
}

class _VietnamFlag extends StatelessWidget {
  final double size;

  const _VietnamFlag({required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.star_rounded,
        color: const Color(0xFFFFE000),
        size: size * 0.55,
      ),
    );
  }
}

class _EnglishFlag extends StatelessWidget {
  final double size;

  const _EnglishFlag({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _UsFlagPainter());
  }
}

class _UsFlagPainter extends CustomPainter {
  static const _red = Color(0xFFB22234);
  static const _blue = Color(0xFF3C3B6E);

  @override
  void paint(Canvas canvas, Size size) {
    final stripeHeight = size.height / 13;
    final redPaint = Paint()..color = _red;
    final whitePaint = Paint()..color = Colors.white;
    final bluePaint = Paint()..color = _blue;

    for (var i = 0; i < 13; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        i.isEven ? redPaint : whitePaint,
      );
    }

    final cantonWidth = size.width * 0.58;
    final cantonHeight = stripeHeight * 7;
    canvas.drawRect(Rect.fromLTWH(0, 0, cantonWidth, cantonHeight), bluePaint);

    final starPaint = Paint()..color = Colors.white;
    final starRadius = (size.shortestSide * 0.028).clamp(0.9, 1.8).toDouble();
    const rows = 5;
    const cols = 6;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final dx = cantonWidth * (0.12 + col * 0.15);
        final dy = cantonHeight * (0.16 + row * 0.17);
        canvas.drawCircle(Offset(dx, dy), starRadius, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TranslatorLogo extends StatelessWidget {
  final double size;

  const TranslatorLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/logo.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Icon(
          Icons.translate_rounded,
          size: size * 0.7,
          color: TranslatorColors.blue,
        ),
      ),
    );
  }
}

class MockWorldMap extends StatelessWidget {
  final double height;

  const MockWorldMap({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _WorldMapPainter()),
    );
  }
}

class _WorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grey = Paint()..color = const Color(0xFFE5E8EB);
    final mint = Paint()..color = const Color(0xFF9BE2D7);

    Path blob(List<Offset> points) {
      final path = Path()
        ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      return path..close();
    }

    canvas.drawPath(
      blob(const [
        Offset(0.00, 0.12),
        Offset(0.16, 0.06),
        Offset(0.28, 0.12),
        Offset(0.24, 0.28),
        Offset(0.12, 0.34),
        Offset(0.03, 0.25),
      ]),
      grey,
    );
    canvas.drawPath(
      blob(const [
        Offset(0.05, 0.58),
        Offset(0.20, 0.52),
        Offset(0.28, 0.68),
        Offset(0.21, 0.90),
        Offset(0.09, 0.82),
      ]),
      mint,
    );
    canvas.drawPath(
      blob(const [
        Offset(0.31, 0.14),
        Offset(0.48, 0.09),
        Offset(0.59, 0.23),
        Offset(0.52, 0.42),
        Offset(0.38, 0.40),
      ]),
      grey,
    );
    canvas.drawPath(
      blob(const [
        Offset(0.39, 0.23),
        Offset(0.44, 0.20),
        Offset(0.47, 0.28),
        Offset(0.42, 0.32),
      ]),
      mint,
    );
    canvas.drawPath(
      blob(const [
        Offset(0.50, 0.27),
        Offset(0.63, 0.22),
        Offset(0.71, 0.47),
        Offset(0.61, 0.88),
        Offset(0.49, 0.74),
      ]),
      grey,
    );
    canvas.drawPath(
      blob(const [
        Offset(0.70, 0.20),
        Offset(0.95, 0.20),
        Offset(1.00, 0.36),
        Offset(0.87, 0.48),
        Offset(0.74, 0.39),
      ]),
      grey,
    );
    canvas.drawPath(
      blob(const [
        Offset(0.78, 0.25),
        Offset(0.95, 0.28),
        Offset(0.95, 0.43),
        Offset(0.82, 0.48),
        Offset(0.73, 0.39),
      ]),
      mint,
    );
    canvas.drawPath(
      blob(const [
        Offset(0.89, 0.66),
        Offset(0.98, 0.70),
        Offset(0.94, 0.87),
        Offset(0.86, 0.82),
      ]),
      grey,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
