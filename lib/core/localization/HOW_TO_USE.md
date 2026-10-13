# WeSafe languages (English / සිංහල / தமிழ்)

## 1. Fixed text (buttons, labels, titles)
1. Add a line in `app_strings.dart`:  `'my_key': ['English', 'සිංහල', 'தமிழ்'],`
2. In your screen: `Text(tr('my_key'))`   (remove `const` in front of that widget)
   With values: `tr('hello_name', {'name': user.name})`  and  `'Hello {name}'` in the map.
3. Do NOT translate data values you save/compare in Firestore (district names, 'Critical', etc.)
   - translate only what is displayed.

## 2. Text other people write (warnings, chat, hazard-report descriptions)
- Showing it:  `TranslatedText(report.description, style: ...)`  instead of `Text(...)`.
  It translates to the viewer's language and shows "Show original".
- Official warnings (saved once, free to read, works offline):
  `final t = await TranslationService.instance.translateAll(msg);`
  save `description_en / _si / _ta`, read with `TranslationService.pickLocalized(data, 'description')`.

## 3. API key
`flutter run --dart-define=TRANSLATE_API_KEY=YOUR_KEY`  (Google Cloud Translation API).
Without a key the app works; posted text stays in its original language.

## 4. Language button anywhere
`const LanguageButton()`  (e.g. in an AppBar's actions or the profile page).

## 5. Wrapping a whole screen quickly (script)
After merging new screens/code from teammates, run in the project root:

    python tools/wesafe_translate.py lib

It wraps the English text of every screen with tr() (safe to run many times) and
writes `untranslated_strings.txt` - the English texts that still have no
Sinhala/Tamil line in `app_strings_auto.dart`. Add a line like

    'English text': ['සිංහල', 'தமிழ்'],

for each of them (or send the txt file to get them translated).
