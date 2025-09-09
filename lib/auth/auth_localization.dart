import '../l10n/app_localizations.dart';
import 'auth_service.dart';

String authErrorText(AppLocalizations l10n, Object error) {
  if (error is! AuthException) return l10n.authGenericFailure;

  switch (error.code) {
    case 'invalid-email':
      return l10n.authInvalidEmail;
    case 'user-disabled':
      return l10n.authUserDisabled;
    case 'user-not-found':
    case 'wrong-password':
      return l10n.authInvalidCredentials;
    case 'email-already-in-use':
      return l10n.authEmailInUse;
    case 'weak-password':
      return l10n.authWeakPassword;
    case 'popup-closed-by-user':
      return l10n.authPopupClosed;
    case 'aborted':
      return l10n.authAborted;
    case 'google_sign_in_error':
      return l10n.authGoogleSignInError;
    default:
    // fallback to service message if present, else generic
      return (error.message.isNotEmpty) ? error.message : l10n.authGenericFailure;
  }
}
