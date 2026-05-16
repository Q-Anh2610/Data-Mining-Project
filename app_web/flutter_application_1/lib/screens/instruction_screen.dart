import 'package:flutter/material.dart';

import '../shared/translator_ui.dart';

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const TranslatorTopBar(title: 'Note', showCloud: false),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(34, 34, 34, 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Download offline language pack\nto translate without internet!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                height: 1.06,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 94),
            Text(
              'How to download:\n'
              '  • First, please go to “Settings”\n\n'
              '  • Then click “Offline mode”\n'
              '     and choose “Download\n'
              '     Offline mode”',
              style: TextStyle(fontSize: 24, height: 1.12, color: textColor),
            ),
            const Spacer(),
            Center(
              child: SizedBox(
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
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                      arguments: {'from': -1, 'to': 0},
                    );
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
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
