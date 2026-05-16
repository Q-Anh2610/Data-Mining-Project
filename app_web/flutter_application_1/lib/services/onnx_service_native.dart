import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

class OnnxTranslationService {
  OrtSession? _encoderSession;
  OrtSession? _decoderSession;
  String _currentMode = '';

  Map<String, int> _vocab = {};
  Map<int, String> _reverseVocab = {};
  int _decoderStartTokenId = 0;
  int _eosTokenId = 0;

  Future<void> loadModel(String mode) async {
    if (_currentMode == mode &&
        _encoderSession != null &&
        _decoderSession != null) {
      return;
    }

    try {
      dispose();
      OrtEnv.instance.init();
      final sessionOptions = OrtSessionOptions()..setIntraOpNumThreads(4);

      final folderName = mode == 'en_vi'
          ? 'mobile_translator_en_vi'
          : 'mobile_translator_vi_en';

      final encoderRawData = await rootBundle.load(
        'assets/$folderName/encoder_model.onnx',
      );
      _encoderSession = OrtSession.fromBuffer(
        encoderRawData.buffer.asUint8List(),
        sessionOptions,
      );

      final decoderRawData = await rootBundle.load(
        'assets/$folderName/decoder_model.onnx',
      );
      _decoderSession = OrtSession.fromBuffer(
        decoderRawData.buffer.asUint8List(),
        sessionOptions,
      );

      final vocabString = await rootBundle.loadString(
        'assets/$folderName/vocab.json',
      );
      final vocabJson = jsonDecode(vocabString) as Map<String, dynamic>;
      _vocab = vocabJson.map((key, value) => MapEntry(key, value as int));
      _reverseVocab = _vocab.map((key, value) => MapEntry(value, key));

      final configString = await rootBundle.loadString(
        'assets/$folderName/config.json',
      );
      final configJson = jsonDecode(configString) as Map<String, dynamic>;
      _decoderStartTokenId =
          (configJson['decoder_start_token_id'] as num?)?.toInt() ?? 53738;
      _eosTokenId = (configJson['eos_token_id'] as num?)?.toInt() ?? 0;

      sessionOptions.release();
      _currentMode = mode;
      debugPrint('ONNX model loaded: $mode');
    } catch (error) {
      debugPrint('ONNX model load failed: $error');
      dispose();
      rethrow;
    }
  }

  Future<String> translateText(String text, String mode) async {
    await loadModel(mode);

    if (_encoderSession == null || _decoderSession == null || _vocab.isEmpty) {
      return 'Loi: Model offline chua san sang.';
    }

    OrtRunOptions? runOptions;
    OrtValueTensor? inputTensor;
    OrtValueTensor? attentionMaskTensor;
    List<OrtValue?>? encoderOutputs;

    try {
      final inputIds = _tokenizeText(text);
      inputTensor = OrtValueTensor.createTensorWithDataList(
        Int64List.fromList(inputIds),
        [1, inputIds.length],
      );
      attentionMaskTensor = OrtValueTensor.createTensorWithDataList(
        Int64List.fromList(List<int>.filled(inputIds.length, 1)),
        [1, inputIds.length],
      );

      runOptions = OrtRunOptions();
      encoderOutputs = await _encoderSession!.runAsync(runOptions, {
        'input_ids': inputTensor,
        'attention_mask': attentionMaskTensor,
      });

      if (encoderOutputs == null || encoderOutputs.isEmpty) {
        return 'Loi: Encoder ONNX khong tra ve ket qua.';
      }

      final decoderOutputIds = <int>[_decoderStartTokenId];
      for (var i = 0; i < 50; i++) {
        final decoderInputTensor = OrtValueTensor.createTensorWithDataList(
          Int64List.fromList(decoderOutputIds),
          [1, decoderOutputIds.length],
        );

        List<OrtValue?>? decoderStepOutput;
        try {
          decoderStepOutput = await _decoderSession!.runAsync(runOptions, {
            'input_ids': decoderInputTensor,
            'encoder_hidden_states': encoderOutputs[0]!,
            'encoder_attention_mask': attentionMaskTensor,
          });

          final logits = decoderStepOutput?[0]?.value;
          if (logits is! List) {
            return 'Loi: Decoder ONNX tra ve logits khong hop le.';
          }

          final batchLogits = logits.first;
          if (batchLogits is! List ||
              decoderOutputIds.length - 1 >= batchLogits.length) {
            return 'Loi: Decoder ONNX tra ve shape khong hop le.';
          }

          final lastTokenLogits = batchLogits[decoderOutputIds.length - 1];
          if (lastTokenLogits is! List) {
            return 'Loi: Decoder ONNX tra ve token logits khong hop le.';
          }

          final nextTokenId = _argmax(lastTokenLogits);
          decoderOutputIds.add(nextTokenId);

          if (nextTokenId == _eosTokenId) break;
          await Future<void>.delayed(Duration.zero);
        } finally {
          decoderInputTensor.release();
          decoderStepOutput?.forEach((output) => output?.release());
        }
      }

      return _detokenize(decoderOutputIds);
    } catch (error) {
      debugPrint('ONNX inference failed: $error');
      return 'Loi suy luan Offline: $error';
    } finally {
      runOptions?.release();
      inputTensor?.release();
      attentionMaskTensor?.release();
      encoderOutputs?.forEach((output) => output?.release());
    }
  }

  int _argmax(List values) {
    var maxLogit = double.negativeInfinity;
    var maxIndex = 0;

    for (var index = 0; index < values.length; index++) {
      final value = (values[index] as num).toDouble();
      if (value > maxLogit) {
        maxLogit = value;
        maxIndex = index;
      }
    }

    return maxIndex;
  }

  List<int> _tokenizeText(String text) {
    final ids = <int>[];
    var processed = text.replaceAll(' ', '\u2581');
    if (!processed.startsWith('\u2581')) {
      processed = '\u2581$processed';
    }

    var index = 0;
    while (index < processed.length) {
      var matched = false;
      for (var length = processed.length - index; length > 0; length--) {
        final token = processed.substring(index, index + length);
        final tokenId = _vocab[token];
        if (tokenId != null) {
          ids.add(tokenId);
          index += length;
          matched = true;
          break;
        }
      }

      if (!matched) {
        ids.add(1);
        index++;
      }
    }

    ids.add(_eosTokenId);
    return ids;
  }

  String _detokenize(List<int> ids) {
    final buffer = StringBuffer();
    for (final id in ids) {
      if (id == _eosTokenId || id == _decoderStartTokenId) continue;

      final token = _reverseVocab[id];
      if (token == null ||
          token.contains('<pad>') ||
          token.contains('<s>') ||
          token.contains('</s>')) {
        continue;
      }

      buffer.write(token);
    }

    return buffer.toString().replaceAll('\u2581', ' ').trim();
  }

  void dispose() {
    _encoderSession?.release();
    _encoderSession = null;
    _decoderSession?.release();
    _decoderSession = null;
    _vocab.clear();
    _reverseVocab.clear();
    _currentMode = '';
  }
}
