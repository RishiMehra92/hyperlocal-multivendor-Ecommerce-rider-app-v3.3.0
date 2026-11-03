import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/language_bloc/language_list_bloc/language_list_bloc.dart';
import '../../l10n/default_en_labels.dart';
import '../../repo/language_repo.dart';

extension TranslationExtension on BuildContext {
  /// Resolves a dynamic translation label from [LanguageListBloc]
  /// with dynamic placeholder replacement: `{placeholder}` -> `value`.
  /// Automatically subscribes the calling widget to rebuild on label changes
  /// when called within [build].
  String tr(
    String key, {
    Map<String, dynamic>? args,
    List<dynamic>? positionalArgs,
    String? fallback,
  }) {
    String? text;

    try {
      LanguageListState? state;
      try {
        state = watch<LanguageListBloc>().state;
      } catch (_) {
        state = read<LanguageListBloc>().state;
      }
      if (state is LanguageListLoaded) {
        text = state.labels[key]?.toString();
      }
    } catch (_) {
      // In case context doesn't have LanguageListBloc in scope
    }

    if (text == null || text.trim().isEmpty) {
      text = LanguageRepo.activeLabels[key]?.toString();
    }

    if (text == null || text.trim().isEmpty) {
      text = defaultEnglishLabels[key] ??
          ((fallback != null && fallback.trim().isNotEmpty) ? fallback : key);
    }

    if (args != null && args.isNotEmpty) {
      args.forEach((placeholder, value) {
        text = text!.replaceAll('{$placeholder}', value.toString());
      });
    }

    if (positionalArgs != null && positionalArgs.isNotEmpty) {
      for (var i = 0; i < positionalArgs.length; i++) {
        text = text!.replaceAll('{$i}', positionalArgs[i].toString());
      }
      final regex = RegExp(r'\{[a-zA-Z0-9_]+\}');
      final matches = regex.allMatches(text!).toList();
      for (var i = 0; i < positionalArgs.length && i < matches.length; i++) {
        text = text!.replaceAll(matches[i].group(0)!, positionalArgs[i].toString());
      }
    }

    return text!;
  }
}
