import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/core/locale/app_locale.dart';
import 'package:mpos_mobile/core/locale/app_localizations.dart';
import 'package:mpos_mobile/core/locale/locale_cubit.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';

void showLanguagePicker(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  AppDialog.show(
    title: l10n.chooseLanguage,
    leftButtonText: l10n.close,
    child: const _LanguageOptions(),
  );
}

class _LanguageOptions extends StatelessWidget {
  const _LanguageOptions();

  @override
  Widget build(BuildContext context) {
    final currentCode = context.watch<LocaleCubit>().state.languageCode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: AppLocale.languages.map((language) {
        return RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          value: language.code,
          groupValue: currentCode,
          title: Text(language.nativeName),
          subtitle: language.nativeName == language.englishName ? null : Text(language.englishName),
          onChanged: (value) {
            if (value == null) return;
            context.read<LocaleCubit>().setLocale(language.locale);
            Navigator.of(context).pop();
          },
        );
      }).toList(),
    );
  }
}
