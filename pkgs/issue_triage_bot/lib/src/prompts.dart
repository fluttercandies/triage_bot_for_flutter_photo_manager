String assignAreaPrompt({
  required String title,
  required String body,
  String? lastComment,
}) {
  return '''
You are a software engineer for the `photo_manager` package.
You are responsible for triaging incoming issues from users.
With each issue, assign a label to represent the platform should be triaged into
('Platform: Android', 'Platform: iOS', 'Platform: macOS', 'Platform: OpenHarmony', 'Platform: Dart (package)')

Here are the descriptions of the different triage platforms:

'Platform: Android': For issues related to the Android platform, use 'Platform: Android'.
'Platform: iOS': For issues related to the iOS platform, use 'Platform: iOS'.
'Platform: macOS': For issues related to the macOS platform, use 'Platform: macOS'.
'Platform: OpenHarmony': For issues related to the OpenHarmony platform, use 'Platform: OpenHarmony'.
'Platform: Dart (package)': For issues related to the Flutter or Dart platform interfaces, use the 'Platform: Dart (package)'.

Don't make up a new platform.
If it's not clear which platform the issue should go in, don't apply an 'Platform: xxx' label.
Take your time when considering which platform to triage the issue into.

If the issue is clearly a feature request, then also apply the label 'Sort: Enhancement'.
If the issue is clearly a bug report, then also apply the label 'Sort: BUG'.
If the issue is mostly a question (How to use), then also apply the label 'Sort: Documents'.
Otherwise don't apply a 'Sort:' label.

If the issue was largely unchanged from our default issue template, 
then apply the 'Status: Need more info' label and don't assign any other label.
These issues will generally have a title of "[xxx]" 
and the body will start with "Version Platforms Device Model flutter info".

Return the labels as comma separated text.

Here are a series of few-shot examples:

<EXAMPLE>
INPUT: title: [xxx]

body: 
  ### Version

  ### Platforms

  ### Device Model

  ### flutter info

  ### How to reproduce?

  ### Logs

  ### Example code (optional)

OUTPUT: Status: Need more info
</EXAMPLE>

<EXAMPLE>
INPUT: title: [Bug report] setIgnorePermissionCheck in Android does not return a result

body: 
  ### Version
    2.8.0

  ### Platforms
    Android

  ### Device Model
    OnePlus 5T (Android 8.1.0), OnePlus 8 Pro (Android 13)

  ### flutter info
    ```
    [√] Flutter (Channel stable, 3.13.9, on Microsoft Windows [Version 10.0.19045.3570], locale ru-UA)
        • Flutter version 3.13.9 on channel stable at xxxxxx
        • Upstream repository https://github.com/flutter/flutter.git
        • Framework revision d211f42860 (2 weeks ago), 2023-10-25 13:42:25 -0700
        • Engine revision 0545f8705d
        • Dart version 3.1.5
        • DevTools version 2.25.0

    [√] Windows Version (Installed version of Windows is version 10 or higher)

    [!] Android toolchain - develop for Android devices (Android SDK version 33.0.2)
        • Android SDK at xxxxxx

    [√] Chrome - develop for the web
        • Chrome at xxxxxx

    [√] Visual Studio - develop Windows apps (Visual Studio Build Tools 2022 17.6.2)
        • Visual Studio at xxxxxx
        • Visual Studio Build Tools 2022 version 17.6.33723.286
        • Windows 10 SDK version 10.0.22000.0

    [√] Android Studio (version 2022.1)
        • Android Studio at xxxxxx
        • Flutter plugin can be installed from:
          https://plugins.jetbrains.com/plugin/9212-flutter
        • Dart plugin can be installed from:
          https://plugins.jetbrains.com/plugin/6351-dart
        • Java version OpenJDK Runtime Environment (build 11.0.15+0-b2043.56-9505619)

    [√] Connected device (4 available)
        • Windows (desktop) • windows  • windows-x64    • Microsoft Windows [Version 10.0.19045.3570]
        • Chrome (web)      • chrome   • web-javascript • Google Chrome 119.0.6045.123
        • Edge (web)        • edge     • web-javascript • Microsoft Edge 119.0.2151.44

    [√] Network resources
        • All expected network resources are available.

    ! Doctor found issues in 1 category.
    ```

  ### How to reproduce?
    Just call method
    await PhotoManager.setIgnorePermissionCheck(true);

    After calling this function, it does not return a result. That is, the code that comes after this line is not executed until it returns the result.
    And this is very strange behavior.
    If we wrap this line in try catch, then we do not catch any errors. It looks like the problem is that the native part doesn't return anything.
    I tested this on different versions of Android and the behavior remained the same.

    At the same time, Android works fine on version 2.7.2, but the same problem will occur on iOS.
    In version 2.8.0, iOS works fine, but Android no longer works.

  ### Logs
    No response

  ### Example code (optional)
    ```dart
    print('Code before setIgnorePermissionCheck');
        try{
          await PhotoManager.setIgnorePermissionCheck(value);
        }
        catch(e){
          print(e);
        }
        print('Code after setIgnorePermissionCheck');
    ```

OUTPUT: Platform: Android, Sort: BUG
</EXAMPLE>

The issue to triage follows:

title: $title

body: $body

${lastComment ?? ''}'''
      .trim();
}

String summarizeIssuePrompt({
  required String title,
  required String body,
  required bool needsInfo,
}) {
  const needsMoreInfo = '''
Our classification model determined that we'll need more information to triage
this issue. Thank them for their contribution and gently prompt them to provide
more information.
''';

  final responseLimit = needsInfo ? '' : ' (1-2 sentences, 24 words or less)';

  return '''
You are a software engineer for the `photo_manager` package.
You are responsible for triaging incoming issues from users.
For each issue, briefly summarize the issue $responseLimit.

${needsInfo ? needsMoreInfo : ''}

The issue to triage follows:

<issue>

title: $title

body: $body

</issue>

${containsChinese(title + body) ? '请你必须使用中文。' : ''}
''';
}

bool containsChinese(String str) => RegExp('[\u4e00-\u9fff]').hasMatch(str);
