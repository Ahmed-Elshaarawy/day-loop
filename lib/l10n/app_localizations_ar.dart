// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'داي لوب';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get languageSubtitle => 'العربية / الإنجليزية';

  @override
  String get generalSectionTitle => 'عام';

  @override
  String get accountSectionTitle => 'الحساب';

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String get welcomeBack => 'أهلاً بك مرة أخرى';

  @override
  String get createAccount => 'أنشئ حسابك';

  @override
  String get signInLink => 'هل لديك حساب بالفعل؟ تسجيل الدخول';

  @override
  String get dontHaveAccount => 'لا تملك حساب؟ أنشئ حساب';

  @override
  String get recordJourneyButton => 'سجل رحلتك';

  @override
  String get stopRecordingButton => 'إيقاف التسجيل';

  @override
  String get todayJourney => 'رحلة اليوم';

  @override
  String get todayDate => 'اليوم • 29/8/2025';

  @override
  String get dayStreak => '7 أيام متتالية';

  @override
  String get morning => 'الصباح';

  @override
  String get evening => 'المساء';

  @override
  String get historyTitle => 'السجل';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get name => 'الاسم';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام جوجل';

  @override
  String get emptyStateTitle => 'رحلتك تبدأ هنا!';

  @override
  String get emptyStateSubtitle =>
      'انقر على الميكروفون أدناه وابدأ التحدث لإضافة أول مهمة لك.';

  @override
  String get errorLoadingHistory => 'فشل في تحميل السجل';

  @override
  String get errorLoadingDay => 'فشل في تحميل مهام هذا اليوم';

  @override
  String get emptyHistoryTitle => 'لا يوجد سجل بعد.';

  @override
  String get emptyHistorySubtitle =>
      'استخدم زر الميكروفون في الصفحة الرئيسية لإضافة مهام اليوم.';

  @override
  String get authRequiredHistory => 'الرجاء تسجيل الدخول لعرض السجل.';

  @override
  String get emptyDayTitle => 'لا توجد مهام مسجلة لهذا اليوم.';

  @override
  String get authRequiredDay => 'الرجاء تسجيل الدخول لعرض مهام هذا اليوم.';

  @override
  String get clearHistoryTitle => 'مسح السجل';

  @override
  String get clearHistorySubtitle => 'حذف جميع المهام المحفوظة لهذا الحساب';

  @override
  String get clearHistoryDialogTitle => 'مسح السجل؟';

  @override
  String get clearHistoryDialogContent =>
      'سيؤدي هذا إلى حذف جميع مهامك وسجلك نهائيًا لهذا الحساب على هذا الجهاز. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get deleteButton => 'حذف';

  @override
  String get toastSignInRequired => 'يجب تسجيل الدخول.';

  @override
  String get toastHistoryCleared => 'تم مسح السجل.';

  @override
  String toastHistoryClearFailed(Object error) {
    return 'فشل في مسح السجل: $error';
  }

  @override
  String todayWithDate(String date) {
    return 'اليوم — $date';
  }

  @override
  String viewAllCount(int count) {
    return 'عرض الكل $count';
  }

  @override
  String get untitledTask => '(مهمة بلا عنوان)';

  @override
  String get authInvalidEmail => 'تنسيق البريد الإلكتروني غير صحيح.';

  @override
  String get authUserDisabled => 'تم تعطيل هذا الحساب.';

  @override
  String get authInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get authEmailInUse => 'يوجد حساب بالفعل بهذا البريد الإلكتروني.';

  @override
  String get authWeakPassword => 'كلمة المرور ضعيفة.';

  @override
  String get authPopupClosed => 'تم إغلاق نافذة تسجيل الدخول قبل الإكمال.';

  @override
  String get authAborted => 'تم إلغاء تسجيل الدخول من قبل المستخدم.';

  @override
  String get authGoogleSignInError => 'فشل تسجيل الدخول عبر جوجل.';

  @override
  String get authGenericFailure => 'فشل التحقق. حاول مرة أخرى.';
}
