// File: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/translation/translation_bloc.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../shared/app_translations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isOfflineMode = false; 

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      setState(() {}); 
    });
  }

  void _handleTranslate() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    context.read<TranslationBloc>().add(TranslateTextEvent(text));
    _inputController.clear(); 
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeOut
        );
      }
    });
  }

  void _toggleOfflineMode() {
    setState(() {
      _isOfflineMode = !_isOfflineMode;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isOfflineMode ? "Đã chuyển sang Offline Mode" : "Đã kết nối Cloud API"),
        duration: const Duration(seconds: 2),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 850) {
          return _buildWebLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  // ===========================================================================
  // 1. GIAO DIỆN WEB
  // ===========================================================================
  Widget _buildWebLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final webBgColor = isDark ? const Color(0xFF0E0E0E) : Colors.grey.shade200; 
    final panelColor = isDark ? const Color(0xFF1E1F20) : Colors.white;
    
    final panelBorder = isDark ? null : Border.all(color: Colors.grey.shade400, width: 1.0);
    final panelShadow = BoxShadow(
      color: Colors.black.withOpacity(isDark ? 0.2 : 0.08), 
      blurRadius: 20, 
      offset: const Offset(0, 8)
    );

    return Scaffold(
      backgroundColor: webBgColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0), 
        child: Row(
          children: [
            Container(
              width: 320, 
              decoration: BoxDecoration(
                color: panelColor, 
                borderRadius: BorderRadius.circular(24), 
                border: panelBorder, 
                boxShadow: [panelShadow]
              ),
              child: ClipRRect(borderRadius: BorderRadius.circular(24), child: _buildWebSidebar(context, isDark)),
            ),
            
            const SizedBox(width: 24), 
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: panelColor, 
                  borderRadius: BorderRadius.circular(24), 
                  border: panelBorder, 
                  boxShadow: [panelShadow]
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(24), child: _buildChatArea(context, isDark, isWeb: true)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // KHUNG SIDEBAR TRÁI 
  Widget _buildWebSidebar(BuildContext context, bool isDark) {
    final uiLang = context.watch<SettingsBloc>().state.language;
    final textColor = isDark ? const Color(0xFFE3E3E3) : Colors.black87;
    final hintColor = isDark ? const Color(0xFF8E918F) : Colors.grey.shade600;
    
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Row(
            children: [
              Image.asset('assets/images/logo.jpg', width: 36, height: 36, errorBuilder: (_, __, ___) => const Icon(Icons.language, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: Text(AppTrans.t(uiLang, 'app_name'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20))),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppTrans.t(uiLang, 'history'), style: TextStyle(color: hintColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                onPressed: () => context.read<HistoryBloc>().add(ClearAllHistoryEvent()),
                child: Text(AppTrans.t(uiLang, 'clear_all'), style: const TextStyle(fontSize: 12, color: Colors.blue)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        Expanded(
          child: BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state is HistoryLoaded) {
                if (state.records.isEmpty) return Center(child: Text(AppTrans.t(uiLang, 'empty_history'), style: TextStyle(color: hintColor, fontSize: 13)));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.records.length,
                  itemBuilder: (context, index) {
                    final record = state.records[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF282A2C) : Colors.grey.shade100,
                        border: isDark ? null : Border.all(color: Colors.grey.shade300, width: 1.0),
                        borderRadius: BorderRadius.circular(16)
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Icon(Icons.chat_bubble_outline, size: 18, color: hintColor),
                        title: Text(record.sourceText, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                        trailing: IconButton(icon: Icon(Icons.close, size: 16, color: hintColor), onPressed: () => context.read<HistoryBloc>().add(DeleteHistoryItemEvent(record.sessionId))),
                        onTap: () => context.read<TranslationBloc>().add(LoadSessionEvent(record.sessionId)),
                      ),
                    );
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        
        Divider(height: 1, color: dividerColor), 
        
        // KHU VỰC CÀI ĐẶT WEB (Đã màu xám và bo góc)
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppTrans.t(uiLang, 'settings'), style: TextStyle(color: hintColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF282A2C) : Colors.grey.shade100, 
                      borderRadius: BorderRadius.circular(16), 
                      border: isDark ? null : Border.all(color: Colors.grey.shade400, width: 1.0) 
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.palette_outlined, size: 20, color: textColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true, 
                              value: state.themeMode, 
                              dropdownColor: isDark ? const Color(0xFF282A2C) : Colors.white,
                              borderRadius: BorderRadius.circular(16), 
                              items: ['Light', 'Dark'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(AppTrans.t(uiLang, value.toLowerCase()), style: TextStyle(color: textColor, fontSize: 14)))).toList(),
                              onChanged: (newVal) { if (newVal != null) context.read<SettingsBloc>().add(UpdateSettingsEvent(textSize: state.textSize, language: state.language, themeMode: newVal)); },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF282A2C) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16), 
                      border: isDark ? null : Border.all(color: Colors.grey.shade400, width: 1.0) 
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.language_outlined, size: 20, color: textColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true, 
                              value: state.language, 
                              dropdownColor: isDark ? const Color(0xFF282A2C) : Colors.white,
                              borderRadius: BorderRadius.circular(16), 
                              items: ['English', 'Vietnamese'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(AppTrans.t(uiLang, value), style: TextStyle(color: textColor, fontSize: 14)))).toList(),
                              onChanged: (newVal) { if (newVal != null) context.read<SettingsBloc>().add(UpdateSettingsEvent(textSize: state.textSize, language: newVal, themeMode: state.themeMode)); },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // KHUNG CHAT (Nhuộm xám các ô trắng để dễ phân biệt trên mọi nền)
  // ===========================================================================
  Widget _buildChatArea(BuildContext context, bool isDark, {required bool isWeb}) {
    final uiLang = context.watch<SettingsBloc>().state.language; 
    
    final textColor = isDark ? const Color(0xFFE3E3E3) : Colors.black87;
    final hintColor = isDark ? const Color(0xFF8E918F) : Colors.grey.shade600;
    
    // [THAY ĐỔI QUAN TRỌNG 1] Đổi bong bóng nguồn thành màu xám nhạt thay vì trắng
    final sourceBubbleColor = isDark ? const Color(0xFF282A2C) : Colors.grey.shade100;
    final targetBubbleColor = isDark ? const Color(0xFF0D293E) : Colors.blue.shade50;
    final targetLabelColor = isDark ? const Color(0xFFA8C7FA) : Colors.blue.shade600;
    final targetTextColor = isDark ? const Color(0xFFA8C7FA) : Colors.blue.shade900;
    
    // [THAY ĐỔI QUAN TRỌNG 2] Đổi ô nhập liệu thành màu xám nhạt thay vì trắng
    final inputFillColor = isDark ? const Color(0xFF282A2C) : Colors.grey.shade100; 
    final sendBtnColor = isDark ? const Color(0xFFA8C7FA) : Colors.blue;
    final sendIconColor = isDark ? const Color(0xFF0D293E) : Colors.white;
    
    final double paddingHorizontal = isWeb ? 40.0 : 16.0; 

    return Column(
      children: [
        // 1. THANH HEADER
        Padding(
          padding: EdgeInsets.fromLTRB(paddingHorizontal, isWeb ? 24 : 16, paddingHorizontal, 16),
          child: BlocBuilder<TranslationBloc, TranslationState>(
            builder: (context, state) {
              return SizedBox(
                height: 56, 
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppTrans.t(uiLang, state.sourceLang), style: TextStyle(color: sendBtnColor, fontWeight: FontWeight.bold, fontSize: 16)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12), 
                            child: IconButton(
                              icon: Icon(Icons.swap_horiz, color: sendBtnColor), 
                              onPressed: () => context.read<TranslationBloc>().add(SwapLanguagesEvent())
                            )
                          ),
                          Text(AppTrans.t(uiLang, state.targetLang), style: TextStyle(color: sendBtnColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(_isOfflineMode ? Icons.cloud_off_rounded : Icons.cloud_rounded, size: 24),
                            color: _isOfflineMode ? Colors.orange : hintColor,
                            tooltip: _isOfflineMode ? "Chế độ Offline" : "Chế độ Online",
                            onPressed: _toggleOfflineMode,
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.blue, width: 1.5), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                            ),
                            onPressed: () => context.read<TranslationBloc>().add(ClearSessionEvent()), 
                            icon: Icon(Icons.add, size: 18, color: isDark ? textColor : Colors.blue),
                            label: Text("Mới", style: TextStyle(color: isDark ? textColor : Colors.blue, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        ),
        
        Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        
        // 2. KHU VỰC CHAT
        Expanded(
          child: Container(
            color: isDark ? Colors.transparent : Colors.white, 
            child: BlocConsumer<TranslationBloc, TranslationState>(
              listener: (context, state) {
                if (state.error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
                if (!state.isLoading && state.sessionRecords.isNotEmpty) {
                  _scrollToBottom();
                  context.read<HistoryBloc>().add(LoadHistoryEvent());
                }
              },
              builder: (context, state) {
                if (state.sessionRecords.isEmpty && !state.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.translate_rounded, size: 80, color: hintColor.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text(AppTrans.t(uiLang, 'start_chat'), style: TextStyle(color: hintColor, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 24), 
                  itemCount: state.sessionRecords.length + (state.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.sessionRecords.length && state.isLoading) {
                      return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: CircularProgressIndicator()));
                    }
                    final record = state.sessionRecords[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight, 
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12, left: 60), 
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), 
                            decoration: BoxDecoration(
                              color: sourceBubbleColor, // <-- Đã đổi xám
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(24), bottomRight: Radius.circular(8)),
                              border: isDark ? null : Border.all(color: Colors.grey.shade300, width: 1.5) 
                            ), 
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end, 
                              children: [
                                Text(AppTrans.t(uiLang, state.sourceLang), style: TextStyle(color: hintColor, fontSize: 12, fontWeight: FontWeight.bold)), 
                                const SizedBox(height: 4), 
                                Text(record.sourceText, style: TextStyle(color: textColor, fontSize: 16)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _inputController.text = record.sourceText,
                                  child: Padding(padding: const EdgeInsets.all(2.0), child: Icon(Icons.edit_outlined, size: 16, color: hintColor)),
                                )
                              ]
                            )
                          )
                        ),
                        
                        Align(
                          alignment: Alignment.centerLeft, 
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 32, right: 60), 
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), 
                            decoration: BoxDecoration(
                              color: targetBubbleColor, 
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomRight: Radius.circular(24), bottomLeft: Radius.circular(8)),
                              border: isDark ? null : Border.all(color: Colors.blue.shade200, width: 1.5) 
                            ), 
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, 
                              children: [
                                Text(AppTrans.t(uiLang, state.targetLang), style: TextStyle(color: targetLabelColor, fontSize: 12, fontWeight: FontWeight.bold)), 
                                const SizedBox(height: 4), 
                                Text(record.translatedText, style: TextStyle(color: targetTextColor, fontSize: 16, height: 1.4, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang đọc văn bản..."), duration: Duration(seconds: 1))),
                                      child: Padding(padding: const EdgeInsets.all(4.0), child: Icon(Icons.volume_up_outlined, size: 20, color: targetLabelColor)),
                                    ),
                                    const SizedBox(width: 16),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: record.translatedText));
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu vào bộ nhớ tạm (Copied!)"), duration: Duration(seconds: 1)));
                                      },
                                      child: Padding(padding: const EdgeInsets.all(4.0), child: Icon(Icons.copy_rounded, size: 18, color: targetLabelColor)),
                                    ),
                                    const SizedBox(width: 16),
                                    InkWell(
                                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm vào mục Yêu thích!"), duration: Duration(seconds: 1))),
                                      child: Padding(padding: const EdgeInsets.all(4.0), child: Icon(Icons.star_border_rounded, size: 20, color: targetLabelColor)),
                                    ),
                                  ],
                                )
                              ]
                            )
                          )
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        
        // 3. Ô NHẬP LIỆU
        Container(
          padding: EdgeInsets.fromLTRB(paddingHorizontal, 16, paddingHorizontal, isWeb ? 32 : 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.transparent : Colors.white,
            border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 1.0))
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end, 
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 8))]
                  ),
                  child: TextField(
                    controller: _inputController, 
                    minLines: isWeb ? 3 : 1, 
                    maxLines: 8, 
                    style: TextStyle(fontSize: 16, color: textColor), 
                    decoration: InputDecoration(
                      hintText: AppTrans.t(uiLang, 'type_here'), 
                      hintStyle: TextStyle(fontSize: 16, color: hintColor), 
                      filled: true, 
                      fillColor: inputFillColor, // <-- Đã đổi xám
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), 
                      suffixIcon: _inputController.text.isNotEmpty 
                        ? IconButton(icon: const Icon(Icons.close_rounded), color: hintColor, onPressed: () { _inputController.clear(); setState(() {}); }) 
                        : null,

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24), 
                        borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400, width: 1.5)
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24), 
                        borderSide: BorderSide(color: sendBtnColor, width: 2.0)
                      )
                    )
                  ),
                )
              ), 
              const SizedBox(width: 16), 
              Padding(
                padding: EdgeInsets.only(bottom: isWeb ? 16.0 : 4.0), 
                child: Container(
                  decoration: BoxDecoration(color: sendBtnColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: sendBtnColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]), 
                  child: IconButton(icon: Icon(Icons.send_rounded, color: sendIconColor, size: 26), onPressed: _handleTranslate)
                ),
              )
            ]
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. GIAO DIỆN MOBILE
  // ===========================================================================
  Widget _buildMobileLayout(BuildContext context) {
    final uiLang = context.watch<SettingsBloc>().state.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF131314) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        title: Row(
          children: [
            Image.asset('assets/images/logo.jpg', width: 24, height: 24, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.language, color: isDark ? Colors.white : Colors.blue)),
            const SizedBox(width: 8),
            Text(AppTrans.t(uiLang, 'title'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isOfflineMode ? Icons.cloud_off_rounded : Icons.cloud_rounded, size: 24),
            color: _isOfflineMode ? Colors.orange : Colors.blue,
            onPressed: _toggleOfflineMode,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1, color: dividerColor),
        ),
      ),
      body: _buildChatArea(context, isDark, isWeb: false),
      bottomNavigationBar: _buildMobileBottomNav(context, uiLang, isDark),
    );
  }

  Widget _buildMobileBottomNav(BuildContext context, String lang, bool isDark) {
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: dividerColor, width: 1.0))),
      child: BottomNavigationBar(
        currentIndex: 0,
        elevation: 0, 
        backgroundColor: isDark ? const Color(0xFF1E1F20) : Colors.white,
        selectedItemColor: isDark ? const Color(0xFFA8C7FA) : Colors.blue,
        unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey,
        onTap: (index) {
          if (index == 0) return;
          final args = {'from': 0, 'to': index};
          if (index == 1) Navigator.pushReplacementNamed(context, '/history', arguments: args);
          if (index == 2) Navigator.pushReplacementNamed(context, '/settings', arguments: args);
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