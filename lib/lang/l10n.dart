import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

    Future<AppLocalizations> load() async {
    String jsonString = await rootBundle
        .loadString('assets/languages/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings =
        jsonMap.map((key, value) => MapEntry(key, value.toString()));

    return this;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? '**$key**';
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'de', 'el'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations(locale).load();

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
