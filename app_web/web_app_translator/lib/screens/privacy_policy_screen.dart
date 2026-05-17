import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/settings/settings_bloc.dart';
import '../shared/app_translations.dart';
import '../shared/translator_ui.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsBloc>().state.language;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: TranslatorTopBar(
        title: AppTrans.t(lang, 'privacy_policy'),
        showCloud: false,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  AppTrans.t(lang, 'privacy_content') == 'privacy_content'
                      ? ''
                      : AppTrans.t(lang, 'privacy_content'),
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 194,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TranslatorColors.yellow,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppTrans.t(lang, 'ok_btn') == 'ok_btn'
                      ? 'OK'
                      : AppTrans.t(lang, 'ok_btn'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
