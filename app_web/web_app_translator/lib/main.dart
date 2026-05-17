import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// BLocs
import 'blocs/translation/translation_bloc.dart';
import 'blocs/history/history_bloc.dart';
import 'blocs/settings/settings_bloc.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/done_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/start_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/instruction_screen.dart';
import 'shared/translator_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ──────────────────────────────────────────────────────────────────
  // Khởi tạo Supabase (Project ref: nlasggmriqfqtvfsgodo)
  // Lấy anon key từ: Supabase Dashboard → Settings → API → anon public
  // ──────────────────────────────────────────────────────────────────
  await Supabase.initialize(
    url: 'https://jkaazcjahfqozwizhpvk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprYWF6Y2phaGZxb3p3aXpocHZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTY4OTUsImV4cCI6MjA5MzA3Mjg5NX0.tl4MCIUt8yrtHLeK1xdMr3ltzZYdzGmxp9lfblgAN8A',
  );

  runApp(const ACDHLTranslatorApp());
}

class ACDHLTranslatorApp extends StatelessWidget {
  const ACDHLTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TranslationBloc()),
        BlocProvider(create: (_) => HistoryBloc()..add(LoadHistoryEvent())),
        BlocProvider(create: (_) => SettingsBloc()),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            title: 'ACDHL Translator',
            debugShowCheckedModeBanner: false,

            // --- GIAO DIỆN SÁNG ---
            theme: ThemeData(
              brightness: Brightness.light,
              useMaterial3: true,
              fontFamily: 'Roboto',
              colorScheme: ColorScheme.fromSeed(
                seedColor: TranslatorColors.blue,
                primary: TranslatorColors.blue,
              ),
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: TranslatorColors.blue,
                iconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(
                  fontSize: 20.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Colors.white,
                selectedItemColor: TranslatorColors.selectedBlue,
                unselectedItemColor: Colors.black,
              ),
            ),

            // --- GIAO DIỆN TỐI (STYLE GEMINI CỦA BẠN) ---
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF131314),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF131314),
                elevation: 1,
                iconTheme: IconThemeData(color: Color(0xFFE3E3E3)),
                titleTextStyle: TextStyle(
                  fontSize: 20.0,
                  color: Color(0xFFE3E3E3),
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Color(0xFF1E1F20),
                selectedItemColor: Color(0xFFA8C7FA),
                unselectedItemColor: Colors.grey,
              ),
              colorScheme: const ColorScheme.dark(
                primary: TranslatorColors.blue,
                surface: Color(0xFF1E1F20),
              ),
            ),

            // Sửa lỗi getter bằng cách so sánh String trực tiếp theo BLoc của bạn
            themeMode: settingsState.themeMode == 'Dark'
                ? ThemeMode.dark
                : ThemeMode.light,

            builder: (context, child) {
              double scale = 1.0;
              if (settingsState.textSize == 'Small') scale = 0.85;
              if (settingsState.textSize == 'Large') scale = 1.25;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              );
            },

            initialRoute: '/start',

            onGenerateRoute: (settings) {
              Widget page;
              switch (settings.name) {
                case '/start':
                  page = const StartScreen();
                  break;
                case '/privacy':
                  page = const PrivacyPolicyScreen();
                  break;
                case '/instruction':
                  page = const InstructionScreen();
                  break;
                case '/home':
                  page = const HomeScreen();
                  break;
                case '/history':
                  page = const HistoryScreen();
                  break;
                case '/settings':
                  page = const SettingsScreen();
                  break;
                case '/favorite':
                  page = const HistoryScreen(favoritesOnly: true);
                  break;
                case '/app-language':
                  page = const AppLanguageScreen();
                  break;
                case '/translation-language':
                  page = const TranslationLanguageScreen();
                  break;
                case '/offline-mode':
                  page = const OfflineModeScreen();
                  break;
                case '/about':
                  page = const AboutScreen();
                  break;
                case '/our-team':
                  page = const OurTeamScreen();
                  break;
                case '/version':
                  page = const VersionScreen();
                  break;
                case '/done':
                  page = const DoneScreen();
                  break;
                default:
                  page = const StartScreen();
              }

              // Logic hiệu ứng trượt màn hình mượt mà
              final args = settings.arguments as Map<String, int>?;
              final fromIndex = args?['from'] ?? 0;
              final toIndex = args?['to'] ?? 0;

              final isInitial = args == null;
              final dx = (toIndex > fromIndex) ? 1.0 : -1.0;

              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => page,
                transitionDuration: const Duration(milliseconds: 450),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
                          .animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                          );

                      var slideAnimation =
                          Tween<Offset>(
                            begin: isInitial ? Offset.zero : Offset(dx, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutQuart,
                            ),
                          );
                      return SlideTransition(
                        position: slideAnimation,
                        child: FadeTransition(
                          opacity: fadeAnimation,
                          child: child,
                        ),
                      );
                    },
              );
            },
          );
        },
      ),
    );
  }
}
