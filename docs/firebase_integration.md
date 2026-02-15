# Firebase Integration Guide

This document explains how Firebase services have been integrated into the Re-Word Game and how to use them effectively.

## Overview

The following Firebase services have been integrated:

1. **Crash Reporting** - Automatically captures and reports app crashes
2. **Performance Monitoring** - Tracks app performance metrics
3. **User Analytics** - Collects data about user behavior
4. **App Distribution** - Facilitates beta testing

> **Note:** Firebase services have different levels of support across platforms:
> - **Mobile (Android/iOS)**: Full support for all Firebase services
> - **Web**: Support for most Firebase services
> - **Desktop (Windows/macOS/Linux)**: Limited support, primarily Firebase Core
>
> The app automatically detects the platform and only uses Firebase services that are supported on that platform.

## Setup

The Firebase integration has already been set up with the following steps:

1. Firebase CLI was installed
2. `flutterfire configure` was run to generate configuration files
3. Firebase services were integrated into the app

## How It Works

### Firebase Initialization

Firebase is initialized in `main.dart` before the app starts:

```dart
// Initialize Firebase
await FirebaseService.instance.initialize();

// Initialize error reporting (now uses Firebase Crashlytics)
await ErrorReporting.initialize();

// Track app startup time
PerformanceService.instance.trackAppStartup();

// Log app open event
AnalyticsService.instance.logGameSessionStart();

// Initialize app distribution service for beta testing
await AppDistributionService.instance.initialize();
```

### Service Architecture

The Firebase integration is organized into several service classes:

- `FirebaseService` - Core Firebase functionality
- `ErrorReporting` - Crash reporting with Firebase Crashlytics
- `PerformanceService` - Performance monitoring
- `AnalyticsService` - User analytics
- `AppDistributionService` - Beta testing

## Using Firebase Services

### Crash Reporting

Crash reporting is automatically enabled. Uncaught exceptions are automatically reported to Firebase Crashlytics. You can also manually report errors:

```dart
try {
  // Some code that might throw an exception
} catch (e, stackTrace) {
  ErrorReporting.reportException(e, stackTrace, context: 'Operation context');
}
```

For non-fatal errors or warnings:

```dart
ErrorReporting.reportWarning('Something unusual happened', 
  context: 'Operation context',
  additionalData: {'key': 'value'});
```

### Performance Monitoring

Performance monitoring tracks app startup time automatically. You can also track custom operations:

```dart
// Track a specific operation
final result = await PerformanceService.instance.trackOperation(
  name: 'operation_name',
  operation: () async {
    // Your operation code here
    return result;
  },
  attributes: {'key': 'value'},
);

// Or manually create traces
final trace = PerformanceService.instance.startTrace('operation_name');
try {
  // Your operation code
  PerformanceService.instance.putMetric(trace, 'metric_name', value);
} finally {
  PerformanceService.instance.stopTrace(trace);
}
```

HTTP requests made with Dio are automatically tracked if you add the performance interceptor:

```dart
final dio = Dio();
dio.interceptors.add(PerformanceService.instance.createDioInterceptor());
```

### User Analytics

User analytics automatically tracks app opens. You can track custom events:

```dart
// Log a custom event
AnalyticsService.instance.logEvent(
  name: 'event_name',
  parameters: {'key': 'value'},
);

// Log a screen view
AnalyticsService.instance.logScreenView(screenName: 'screen_name');

// Set user properties
AnalyticsService.instance.setUserProperty(name: 'property_name', value: 'value');
```

Game-specific events are also available:

```dart
// Log game session start/end
AnalyticsService.instance.logGameSessionStart();
AnalyticsService.instance.logGameSessionEnd(
  durationSeconds: 300,
  score: 1000,
  wordsSpelled: 20,
);

// Log a word spelled
AnalyticsService.instance.logWordSpelled(
  word: 'example',
  wordLength: 7,
  wordScore: 10,
);
```

### App Distribution for Beta Testing

The app includes a custom implementation for beta testing features since Firebase App Distribution is not available as a Flutter plugin. The implementation uses shared preferences to store beta testing information and Firebase Analytics to track beta tester feedback.

You can detect if the app is a beta version:

```dart
if (AppDistributionService.instance.isBetaVersion) {
  // This is a beta version
}
```

You can collect feedback from beta testers:

```dart
// Show feedback dialog
AppDistributionService.instance.showFeedbackDialog(context);

// Or manually submit feedback
AppDistributionService.instance.submitFeedback(
  feedback: 'Feedback text',
  category: 'Bug',
  additionalData: {'key': 'value'},
);
```

To distribute beta versions to testers, you'll need to use the Firebase Console or Firebase CLI directly, as the Flutter plugin for App Distribution is not available.

## Firebase Console

You can view all the collected data in the Firebase Console:

1. Go to [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Select your project
3. Navigate to the appropriate section:
   - **Crashlytics** for crash reports
   - **Performance** for performance data
   - **Analytics** for user analytics
   - **App Distribution** for beta testing

## Best Practices

1. **Crash Reporting**
   - Always include context when manually reporting errors
   - Use `reportWarning` for non-fatal issues

2. **Performance Monitoring**
   - Create traces for operations that might affect user experience
   - Add custom metrics to traces for more detailed analysis

3. **User Analytics**
   - Don't track personally identifiable information
   - Use consistent naming conventions for events
   - Group related events with common prefixes

4. **App Distribution**
   - Clearly communicate to beta testers how to provide feedback
   - Respond to beta tester feedback promptly

## Troubleshooting

If you encounter issues with Firebase integration:

1. Check that Firebase is properly initialized in `main.dart`
2. Verify that the correct Firebase configuration files are included
3. Ensure that the required Firebase dependencies are in `pubspec.yaml`
4. Check the Firebase Console for any service-specific issues
5. Review the app logs for Firebase-related errors

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview/)
- [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics)
- [Firebase Performance Monitoring](https://firebase.google.com/docs/perf-mon)
- [Firebase Analytics](https://firebase.google.com/docs/analytics)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
