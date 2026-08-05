import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_localizations_delegate.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String>? _localizedStrings;

  AppLocalizations(this.locale);

  Future<bool> load() async {
    final jsonString = await rootBundle.loadString(
      'packages/core/lib/localization/l10n/${locale.languageCode}.json',
    );
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    _localizedStrings = jsonMap.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    return true;
  }

  String? translate(String key) {
    return _localizedStrings?[key];
  }

  String t(String key) {
    return _localizedStrings?[key] ?? key;
  }

  String tWithParams(String key, Map<String, String> params) {
    var text = _localizedStrings?[key];
    if (text == null) return key;
    for (final entry in params.entries) {
      text = text!.replaceAll('{${entry.key}}', entry.value);
    }
    return text!;
  }

  String? translateWithParams(String key, Map<String, String> params) {
    var text = _localizedStrings?[key];
    if (text == null) return null;
    for (final entry in params.entries) {
      text = text!.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('ar', 'SA'),
  ];
}
