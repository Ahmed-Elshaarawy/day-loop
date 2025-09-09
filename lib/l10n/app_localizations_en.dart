// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Day Loop';

  @override
  String get homeTitle => 'Home';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle => 'English / Arabic';

  @override
  String get generalSectionTitle => 'General';

  @override
  String get accountSectionTitle => 'Account';

  @override
  String get logoutButton => 'Log Out';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get createAccount => 'Create Your Account';

  @override
  String get signInLink => 'Already have an account? Sign in';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign up';

  @override
  String get recordJourneyButton => 'Record Journey';

  @override
  String get stopRecordingButton => 'Stop Recording';

  @override
  String get todayJourney => 'Today\'s Journey';

  @override
  String get todayDate => 'Today • 8/29/2025';

  @override
  String get dayStreak => '7 Day Streak';

  @override
  String get morning => 'Morning';

  @override
  String get evening => 'Evening';

  @override
  String get historyTitle => 'History';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get name => 'Name';

  @override
  String get signUp => 'Sign Up';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get emptyStateTitle => 'Your journey starts here!';

  @override
  String get emptyStateSubtitle =>
      'Tap the microphone below and start talking to add your first task.';

  @override
  String get errorLoadingHistory => 'Failed to load history';

  @override
  String get errorLoadingDay => 'Failed to load tasks for this day';

  @override
  String get emptyHistoryTitle => 'No history yet.';

  @override
  String get emptyHistorySubtitle =>
      'Use the mic button in the home page to add today’s tasks.';

  @override
  String get authRequiredHistory => 'Please sign in to view your history.';

  @override
  String get emptyDayTitle => 'Nothing was logged for this day.';

  @override
  String get authRequiredDay => 'Please sign in to view this day.';

  @override
  String get clearHistoryTitle => 'Clear history';

  @override
  String get clearHistorySubtitle => 'Delete all saved tasks for this account';

  @override
  String get clearHistoryDialogTitle => 'Clear history?';

  @override
  String get clearHistoryDialogContent =>
      'This will permanently delete all your tasks and history for this account on this device. This action cannot be undone.';

  @override
  String get deleteButton => 'Delete';

  @override
  String get toastSignInRequired => 'You need to be signed in.';

  @override
  String get toastHistoryCleared => 'History cleared.';

  @override
  String toastHistoryClearFailed(Object error) {
    return 'Failed to clear history: $error';
  }

  @override
  String todayWithDate(String date) {
    return 'Today — $date';
  }

  @override
  String viewAllCount(int count) {
    return 'View all $count';
  }

  @override
  String get untitledTask => '(Untitled task)';

  @override
  String get authInvalidEmail => 'The email address is badly formatted.';

  @override
  String get authUserDisabled => 'This account has been disabled.';

  @override
  String get authInvalidCredentials => 'Invalid email or password.';

  @override
  String get authEmailInUse => 'An account already exists with this email.';

  @override
  String get authWeakPassword => 'That password is too weak.';

  @override
  String get authPopupClosed =>
      'The sign-in popup was closed before completing.';

  @override
  String get authAborted => 'Sign-in aborted by user.';

  @override
  String get authGoogleSignInError => 'Google sign-in failed.';

  @override
  String get authGenericFailure => 'Authentication failed. Please try again.';
}
