String summarizeIssueTitlePrompt({required String title, required String body}) {
  return '''
You are a software engineer for the `photo_manager` package.
You need to summarize the body content to generate a title (one sentence, 12 words or less, concise and clear).

The title must start with '[xxx]', where 'xxx' is a short description of the issue type.

Here are the descriptions of the different types:
'[Bug report]': For issues related to bugs or unexpected behaviors in the package.
'[Feature request]': For issues suggesting new features or enhancements.
'[How to use]': For issues where users are seeking guidance on using the package.

Don't make up a new type.
If it's not clear which type the issue should go in, don't apply an '[xxx]'.
Take your time when considering which type to triage the issue into.

Do not include 'photo_manager' in the title.
(The title content itself is intended for 'photo_manager')

The final returned title format should be: '[type] title content'.

Here are a series of few-shot examples:

<EXAMPLE>
INPUT:
body: 
[Bug report] setIgnorePermissionCheck
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

OUTPUT: [Bug report] setIgnorePermissionCheck in Android doesn't return a result
</EXAMPLE>

The issue is as follows:

body: $title
$body
''';
}
