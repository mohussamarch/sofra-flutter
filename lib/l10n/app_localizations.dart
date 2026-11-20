import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'سفرة'**
  String get appTitle;

  /// No description provided for @lookSection.
  ///
  /// In ar, this message translates to:
  /// **'العرض واللغة'**
  String get lookSection;

  /// No description provided for @lookAppearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get lookAppearance;

  /// No description provided for @lookLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get lookLight;

  /// No description provided for @lookSystem.
  ///
  /// In ar, this message translates to:
  /// **'حسب الهاتف'**
  String get lookSystem;

  /// No description provided for @lookDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get lookDark;

  /// No description provided for @lookTextSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط'**
  String get lookTextSize;

  /// No description provided for @lookTextNormal.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get lookTextNormal;

  /// No description provided for @lookTextLarge.
  ///
  /// In ar, this message translates to:
  /// **'كبير'**
  String get lookTextLarge;

  /// No description provided for @lookTextLarger.
  ///
  /// In ar, this message translates to:
  /// **'أكبر'**
  String get lookTextLarger;

  /// Sample letter drawn at three sizes in the text size control.
  ///
  /// In ar, this message translates to:
  /// **'أ'**
  String get lookGlyph;

  /// No description provided for @lookColors.
  ///
  /// In ar, this message translates to:
  /// **'تمييز الألوان'**
  String get lookColors;

  /// No description provided for @lookColorsInfo.
  ///
  /// In ar, this message translates to:
  /// **'لمن يصعب عليه تمييز بعض الألوان: يغيّر ألوان التطبيق كله لتصبح أوضح، مثل «تصحيح الألوان» في إعدادات الهاتف.'**
  String get lookColorsInfo;

  /// No description provided for @lookMotion.
  ///
  /// In ar, this message translates to:
  /// **'تقليل الحركة'**
  String get lookMotion;

  /// No description provided for @lookMotionInfo.
  ///
  /// In ar, this message translates to:
  /// **'انتقالات أهدأ دون ارتداد أو حركة في الخلفية.'**
  String get lookMotionInfo;

  /// No description provided for @lookLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get lookLanguage;

  /// No description provided for @lookLanguageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get lookLanguageArabic;

  /// No description provided for @lookLanguageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get lookLanguageEnglish;

  /// No description provided for @lookVisionNoneShort.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get lookVisionNoneShort;

  /// No description provided for @lookVisionProtanShort.
  ///
  /// In ar, this message translates to:
  /// **'الأحمر'**
  String get lookVisionProtanShort;

  /// No description provided for @lookVisionDeutanShort.
  ///
  /// In ar, this message translates to:
  /// **'الأخضر'**
  String get lookVisionDeutanShort;

  /// No description provided for @lookVisionTritanShort.
  ///
  /// In ar, this message translates to:
  /// **'الأزرق'**
  String get lookVisionTritanShort;

  /// No description provided for @lookVisionNone.
  ///
  /// In ar, this message translates to:
  /// **'دون تصحيح'**
  String get lookVisionNone;

  /// No description provided for @lookVisionProtan.
  ///
  /// In ar, this message translates to:
  /// **'صعوبة تمييز الأحمر'**
  String get lookVisionProtan;

  /// No description provided for @lookVisionDeutan.
  ///
  /// In ar, this message translates to:
  /// **'صعوبة تمييز الأخضر'**
  String get lookVisionDeutan;

  /// No description provided for @lookVisionTritan.
  ///
  /// In ar, this message translates to:
  /// **'صعوبة تمييز الأزرق'**
  String get lookVisionTritan;

  /// No description provided for @uiIncrease.
  ///
  /// In ar, this message translates to:
  /// **'زيادة العدد'**
  String get uiIncrease;

  /// No description provided for @uiDecrease.
  ///
  /// In ar, this message translates to:
  /// **'تقليل العدد'**
  String get uiDecrease;

  /// No description provided for @commTitle.
  ///
  /// In ar, this message translates to:
  /// **'مجتمع سفرة'**
  String get commTitle;

  /// No description provided for @commTagline.
  ///
  /// In ar, this message translates to:
  /// **'كلنا على سفرة واحدة'**
  String get commTagline;

  /// No description provided for @commKitchen.
  ///
  /// In ar, this message translates to:
  /// **'مطبخ البيت'**
  String get commKitchen;

  /// No description provided for @commChallenge.
  ///
  /// In ar, this message translates to:
  /// **'تحدي الأسبوع'**
  String get commChallenge;

  /// No description provided for @commPreviewNote.
  ///
  /// In ar, this message translates to:
  /// **'معاينة على الجهاز: ما تنشره هنا لا يصل لأحد، ويُحذف عند الإغلاق.'**
  String get commPreviewNote;

  /// No description provided for @commPartHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get commPartHome;

  /// No description provided for @commPartMine.
  ///
  /// In ar, this message translates to:
  /// **'وصفاتي'**
  String get commPartMine;

  /// No description provided for @commPartPrices.
  ///
  /// In ar, this message translates to:
  /// **'أسعار منطقتي'**
  String get commPartPrices;

  /// No description provided for @commShareOwnRecipe.
  ///
  /// In ar, this message translates to:
  /// **'شارك وصفة من عندك'**
  String get commShareOwnRecipe;

  /// No description provided for @commRecipesLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب الوصفات. حاول مرة أخرى.'**
  String get commRecipesLoadError;

  /// No description provided for @commMineEmptyWrite.
  ///
  /// In ar, this message translates to:
  /// **'اكتب وصفة من «وصفة من عندي»، ثم شاركها هنا.'**
  String get commMineEmptyWrite;

  /// No description provided for @commMineEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تشارك وصفة بعد.'**
  String get commMineEmpty;

  /// No description provided for @commNeedsAccount.
  ///
  /// In ar, this message translates to:
  /// **'هذا الجزء يحتاج إلى حساب. هذه النسخة محفوظة على الجهاز فقط.'**
  String get commNeedsAccount;

  /// No description provided for @commConnectionProblem.
  ///
  /// In ar, this message translates to:
  /// **'حدثت مشكلة في الاتصال. حاول مرة أخرى.'**
  String get commConnectionProblem;

  /// Avatar letter when a name is empty
  ///
  /// In ar, this message translates to:
  /// **'؟'**
  String get commNoInitial;

  /// No description provided for @commYourStory.
  ///
  /// In ar, this message translates to:
  /// **'قصتك'**
  String get commYourStory;

  /// No description provided for @commChallengeNote.
  ///
  /// In ar, this message translates to:
  /// **'اطبخ وشارك'**
  String get commChallengeNote;

  /// No description provided for @commKitchenNote.
  ///
  /// In ar, this message translates to:
  /// **'خزين واحد لأهل البيت'**
  String get commKitchenNote;

  /// No description provided for @commYoutubeChefs.
  ///
  /// In ar, this message translates to:
  /// **'شيفات على يوتيوب'**
  String get commYoutubeChefs;

  /// No description provided for @commFromSofraHomes.
  ///
  /// In ar, this message translates to:
  /// **'من بيوت سفرة'**
  String get commFromSofraHomes;

  /// No description provided for @commShareRecipe.
  ///
  /// In ar, this message translates to:
  /// **'شارك وصفة'**
  String get commShareRecipe;

  /// No description provided for @commFeedEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم يشارك أحد وصفة بعد. ابدأ أنت من «وصفة من عندي».'**
  String get commFeedEmpty;

  /// No description provided for @commOpenChannel.
  ///
  /// In ar, this message translates to:
  /// **'افتح القناة على يوتيوب'**
  String get commOpenChannel;

  /// No description provided for @commShareFromYours.
  ///
  /// In ar, this message translates to:
  /// **'شارك وصفة من وصفاتك'**
  String get commShareFromYours;

  /// No description provided for @commSharedNotice.
  ///
  /// In ar, this message translates to:
  /// **'شُوركت {name}'**
  String commSharedNotice(String name);

  /// No description provided for @commShareFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت المشاركة. حاول مرة أخرى.'**
  String get commShareFailed;

  /// No description provided for @commFeedCounts.
  ///
  /// In ar, this message translates to:
  /// **'{ingredients} مكون · {steps} خطوات'**
  String commFeedCounts(int ingredients, int steps);

  /// No description provided for @commServings.
  ///
  /// In ar, this message translates to:
  /// **'{count} أفراد'**
  String commServings(int count);

  /// No description provided for @commStoryPrompt.
  ///
  /// In ar, this message translates to:
  /// **'ماذا طبخت اليوم؟'**
  String get commStoryPrompt;

  /// No description provided for @commStoryHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب قصتك'**
  String get commStoryHint;

  /// No description provided for @commStoryDishHint.
  ///
  /// In ar, this message translates to:
  /// **'اسم الأكلة (اختياري)'**
  String get commStoryDishHint;

  /// No description provided for @commStoryPost.
  ///
  /// In ar, this message translates to:
  /// **'انشر لمدة يوم'**
  String get commStoryPost;

  /// No description provided for @commStoryHoursAgo.
  ///
  /// In ar, this message translates to:
  /// **'من {hours} ساعة'**
  String commStoryHoursAgo(int hours);

  /// No description provided for @commStoryNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get commStoryNow;

  /// No description provided for @commKitchenLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح بيانات المطبخ. حاول مرة أخرى.'**
  String get commKitchenLoadError;

  /// No description provided for @commKitchenIntro.
  ///
  /// In ar, this message translates to:
  /// **'اجمع البيت كله على مطبخ واحد: المخزون نفسه، والخطة نفسها، وقائمة الشراء نفسها. ما في مطبخك الآن هو ما ستتم مشاركته.'**
  String get commKitchenIntro;

  /// No description provided for @commKitchenCreate.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ مطبخًا مشتركًا'**
  String get commKitchenCreate;

  /// No description provided for @commHaveInvite.
  ///
  /// In ar, this message translates to:
  /// **'عندك كود دعوة؟'**
  String get commHaveInvite;

  /// No description provided for @commCodeExample.
  ///
  /// In ar, this message translates to:
  /// **'مثلاً: K7PM2QXA'**
  String get commCodeExample;

  /// No description provided for @commKitchenJoin.
  ///
  /// In ar, this message translates to:
  /// **'ادخل المطبخ'**
  String get commKitchenJoin;

  /// No description provided for @commKitchenJoinNote.
  ///
  /// In ar, this message translates to:
  /// **'عند دخولك مطبخًا مشتركًا، يبقى مطبخك الشخصي محفوظًا وتعود إليه عند الخروج.'**
  String get commKitchenJoinNote;

  /// No description provided for @commSharedKitchen.
  ///
  /// In ar, this message translates to:
  /// **'المطبخ المشترك'**
  String get commSharedKitchen;

  /// No description provided for @commKitchenOwner.
  ///
  /// In ar, this message translates to:
  /// **'صاحب المطبخ'**
  String get commKitchenOwner;

  /// No description provided for @commInviteSend.
  ///
  /// In ar, this message translates to:
  /// **'أرسل هذا الرمز لأهل البيت (صالح لمدة أسبوع):'**
  String get commInviteSend;

  /// No description provided for @commInviteCreate.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ رمز دعوة'**
  String get commInviteCreate;

  /// No description provided for @commBackToMyKitchen.
  ///
  /// In ar, this message translates to:
  /// **'العودة إلى مطبخي الشخصي'**
  String get commBackToMyKitchen;

  /// No description provided for @commByAuthor.
  ///
  /// In ar, this message translates to:
  /// **'من {name}'**
  String commByAuthor(String name);

  /// No description provided for @commIngredients.
  ///
  /// In ar, this message translates to:
  /// **'المكونات'**
  String get commIngredients;

  /// No description provided for @commMethod.
  ///
  /// In ar, this message translates to:
  /// **'الطريقة'**
  String get commMethod;

  /// No description provided for @commRatings.
  ///
  /// In ar, this message translates to:
  /// **'التقييمات'**
  String get commRatings;

  /// No description provided for @commNoRatings.
  ///
  /// In ar, this message translates to:
  /// **'لم يقيّمها أحد بعد.'**
  String get commNoRatings;

  /// No description provided for @commRatingAverage.
  ///
  /// In ar, this message translates to:
  /// **'{average} من 5 ({count})'**
  String commRatingAverage(String average, String count);

  /// No description provided for @commCommentHint.
  ///
  /// In ar, this message translates to:
  /// **'تعليقك (اختياري)'**
  String get commCommentHint;

  /// No description provided for @commSaveRating.
  ///
  /// In ar, this message translates to:
  /// **'احفظ تقييمي'**
  String get commSaveRating;

  /// No description provided for @commChallengeCookPlanned.
  ///
  /// In ar, this message translates to:
  /// **'اطبخ {goal} وجبات من خطتك'**
  String commChallengeCookPlanned(String goal);

  /// No description provided for @commChallengeCookPlannedDetail.
  ///
  /// In ar, this message translates to:
  /// **'تُحسب كل وجبة مخططة طُبخت هذا الأسبوع.'**
  String get commChallengeCookPlannedDetail;

  /// No description provided for @commChallengeDifferent.
  ///
  /// In ar, this message translates to:
  /// **'نوّع: {goal} أكلات مختلفة'**
  String commChallengeDifferent(String goal);

  /// No description provided for @commChallengeDifferentDetail.
  ///
  /// In ar, this message translates to:
  /// **'تُحسب كل وصفة مختلفة طُبخت هذا الأسبوع مرة واحدة.'**
  String get commChallengeDifferentDetail;

  /// No description provided for @commChallengeNew.
  ///
  /// In ar, this message translates to:
  /// **'{goal, plural, =2{جرّب وصفتين أول مرة} other{جرّب {goal} وصفات أول مرة}}'**
  String commChallengeNew(int goal);

  /// No description provided for @commChallengeNewDetail.
  ///
  /// In ar, this message translates to:
  /// **'وصفة لم تُطبخ من قبل في مطبخك.'**
  String get commChallengeNewDetail;

  /// No description provided for @commChallengeProgress.
  ///
  /// In ar, this message translates to:
  /// **'أنجزت {done} من {goal}'**
  String commChallengeProgress(String done, String goal);

  /// No description provided for @commChallengeLog.
  ///
  /// In ar, this message translates to:
  /// **'سجّل تقدمي في اللوحة'**
  String get commChallengeLog;

  /// No description provided for @commChallengeHomes.
  ///
  /// In ar, this message translates to:
  /// **'البيوت المشاركة'**
  String get commChallengeHomes;

  /// No description provided for @commBoardLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب اللوحة. حاول مرة أخرى.'**
  String get commBoardLoadError;

  /// No description provided for @commBoardEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم يسجّل أحد هذا الأسبوع بعد.'**
  String get commBoardEmpty;

  /// No description provided for @commLeaveTitle.
  ///
  /// In ar, this message translates to:
  /// **'الخروج من المطبخ المشترك؟'**
  String get commLeaveTitle;

  /// No description provided for @commLeaveBody.
  ///
  /// In ar, this message translates to:
  /// **'ستعود إلى مطبخك الشخصي ولن ترى تعديلات أهل البيت. للعودة تحتاج رمز دعوة جديدًا من صاحب المطبخ.'**
  String get commLeaveBody;

  /// No description provided for @commCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get commCancel;

  /// No description provided for @commLeave.
  ///
  /// In ar, this message translates to:
  /// **'اخرج'**
  String get commLeave;

  /// No description provided for @detailOpenError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الوصفة. ارجع وحاول مرة أخرى.'**
  String get detailOpenError;

  /// No description provided for @detailPreparing.
  ///
  /// In ar, this message translates to:
  /// **'بنجهّز الطبخة…'**
  String get detailPreparing;

  /// No description provided for @detailCookNow.
  ///
  /// In ar, this message translates to:
  /// **'أطبخ الآن'**
  String get detailCookNow;

  /// No description provided for @detailCookNowNote.
  ///
  /// In ar, this message translates to:
  /// **'تُحفظ كوجبة لليوم لاستكمالها. لا خصم قبل التأكيد.'**
  String get detailCookNowNote;

  /// No description provided for @detailAddToPlan.
  ///
  /// In ar, this message translates to:
  /// **'أضيف للخطة'**
  String get detailAddToPlan;

  /// No description provided for @detailPhotoCredit.
  ///
  /// In ar, this message translates to:
  /// **'الصورة: {credit} · {licence}'**
  String detailPhotoCredit(String credit, String licence);

  /// No description provided for @detailServingsQuestion.
  ///
  /// In ar, this message translates to:
  /// **'نطبخ لكم شخصًا؟'**
  String get detailServingsQuestion;

  /// No description provided for @detailServingsHint.
  ///
  /// In ar, this message translates to:
  /// **'تُضبط الكميات تلقائيًا'**
  String get detailServingsHint;

  /// No description provided for @detailLogAs.
  ///
  /// In ar, this message translates to:
  /// **'أسجّل الطبخة كـ'**
  String get detailLogAs;

  /// No description provided for @detailAllergyMatch.
  ///
  /// In ar, this message translates to:
  /// **'انتبه: {matches}. المطابقة بالاسم بس، راجع المكونات والعبوات بنفسك.'**
  String detailAllergyMatch(String matches);

  /// No description provided for @detailAllergyMatchItem.
  ///
  /// In ar, this message translates to:
  /// **'«{allergy}» في {lines}'**
  String detailAllergyMatchItem(String allergy, String lines);

  /// No description provided for @detailAllergyCheck.
  ///
  /// In ar, this message translates to:
  /// **'راجع مكونات الوصفة والعبوات مع الحساسية المسجّلة: {allergies}.'**
  String detailAllergyCheck(String allergies);

  /// Joins items of a list, with its trailing space.
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get detailListSeparator;

  /// Joins groups of a list, with its trailing space.
  ///
  /// In ar, this message translates to:
  /// **'؛ '**
  String get detailGroupSeparator;

  /// No description provided for @detailIngredientsScaled.
  ///
  /// In ar, this message translates to:
  /// **'المكونات على قدركم'**
  String get detailIngredientsScaled;

  /// No description provided for @detailIngredientsSource.
  ///
  /// In ar, this message translates to:
  /// **'المكونات كما في المصدر'**
  String get detailIngredientsSource;

  /// No description provided for @detailSteps.
  ///
  /// In ar, this message translates to:
  /// **'الخطوات'**
  String get detailSteps;

  /// No description provided for @detailNoPricesNote.
  ///
  /// In ar, this message translates to:
  /// **'لا تظهر الأسعار والقيم الغذائية هنا حتى تُراجع من مصادرها. الكميات من المصدر.'**
  String get detailNoPricesNote;

  /// No description provided for @detailToTaste.
  ///
  /// In ar, this message translates to:
  /// **'حسب الرغبة'**
  String get detailToTaste;

  /// No description provided for @detailYieldUnknown.
  ///
  /// In ar, this message translates to:
  /// **'لم يذكر المصدر عدد من تكفيهم هذه الوصفة'**
  String get detailYieldUnknown;

  /// No description provided for @detailYieldAsk.
  ///
  /// In ar, this message translates to:
  /// **'لنضبط الكميات ونضعها على السفرة، أخبرنا كم فردًا تكفي الوصفة كلها تقريبًا. الوصفة الأصلية لن تتغير.'**
  String get detailYieldAsk;

  /// No description provided for @detailYieldServes.
  ///
  /// In ar, this message translates to:
  /// **'تكفي {count} أفراد'**
  String detailYieldServes(int count);

  /// No description provided for @detailPlanned.
  ///
  /// In ar, this message translates to:
  /// **'الوجبة على السفرة، والمخزون لم يتغير'**
  String get detailPlanned;

  /// No description provided for @detailWaysToMake.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{طريقة واحدة لعملها} =2{طريقتان لعملها} few{{count} طرق لعملها} many{{count} طريقة لعملها} other{{count} طريقة لعملها}}'**
  String detailWaysToMake(int count);

  /// No description provided for @detailIngredients.
  ///
  /// In ar, this message translates to:
  /// **'المكونات'**
  String get detailIngredients;

  /// No description provided for @detailWaysOpenError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الطرق. ارجع وحاول مرة أخرى.'**
  String get detailWaysOpenError;

  /// No description provided for @detailComparePickHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر بلدًا من الشريط لترى الكميات والخطوات.'**
  String get detailComparePickHint;

  /// No description provided for @detailDefineConversion.
  ///
  /// In ar, this message translates to:
  /// **'حدد التحويل'**
  String get detailDefineConversion;

  /// No description provided for @detailConversionQuestion.
  ///
  /// In ar, this message translates to:
  /// **'1 {from} من {name} = كم {to}؟'**
  String detailConversionQuestion(String from, String name, String to);

  /// No description provided for @detailConversionHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب القياس من مطبخك. سيُحفظ لهذا المكوّن فقط.'**
  String get detailConversionHint;

  /// No description provided for @detailEnterPositive.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقمًا أكبر من صفر'**
  String get detailEnterPositive;

  /// No description provided for @detailCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get detailCancel;

  /// No description provided for @detailSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get detailSave;

  /// No description provided for @detailConversionSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ: 1 {from} {name} = {factor} {to}'**
  String detailConversionSaved(
    String from,
    String name,
    String factor,
    String to,
  );

  /// No description provided for @detailInStock.
  ///
  /// In ar, this message translates to:
  /// **'موجود عندك'**
  String get detailInStock;

  /// No description provided for @detailMissing.
  ///
  /// In ar, this message translates to:
  /// **'ناقص {amount} {unit}'**
  String detailMissing(String amount, String unit);

  /// No description provided for @detailUnitMismatch.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة مختلفة عن المخزون'**
  String get detailUnitMismatch;

  /// No description provided for @detailUnmeasured.
  ///
  /// In ar, this message translates to:
  /// **'دون مقدار'**
  String get detailUnmeasured;

  /// No description provided for @detailOptional.
  ///
  /// In ar, this message translates to:
  /// **'اختياري'**
  String get detailOptional;

  /// No description provided for @detailPlanWhen.
  ///
  /// In ar, this message translates to:
  /// **'متى نضعها على السفرة؟'**
  String get detailPlanWhen;

  /// No description provided for @detailToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get detailToday;

  /// No description provided for @detailTomorrow.
  ///
  /// In ar, this message translates to:
  /// **'غدًا'**
  String get detailTomorrow;

  /// No description provided for @detailDayAfterTomorrow.
  ///
  /// In ar, this message translates to:
  /// **'بعد غد'**
  String get detailDayAfterTomorrow;

  /// No description provided for @detailDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get detailDone;

  /// No description provided for @detailCookOpenError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الوصفة.'**
  String get detailCookOpenError;

  /// No description provided for @detailFinishCooking.
  ///
  /// In ar, this message translates to:
  /// **'انتهى الطبخ · راجع الخصم'**
  String get detailFinishCooking;

  /// No description provided for @detailNoSteps.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد خطوات مكتوبة لهذه الوصفة في المصدر.'**
  String get detailNoSteps;

  /// No description provided for @detailNextStep.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة التالية'**
  String get detailNextStep;

  /// No description provided for @detailStepOf.
  ///
  /// In ar, this message translates to:
  /// **'{current} من {total}'**
  String detailStepOf(String current, String total);

  /// No description provided for @detailAboutMinutes.
  ///
  /// In ar, this message translates to:
  /// **'حوالي {minutes} دقيقة'**
  String detailAboutMinutes(String minutes);

  /// No description provided for @detailPreviousStep.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة السابقة'**
  String get detailPreviousStep;

  /// No description provided for @detailEnjoy.
  ///
  /// In ar, this message translates to:
  /// **'بالهنا والشفا!'**
  String get detailEnjoy;

  /// No description provided for @detailCookedNote.
  ///
  /// In ar, this message translates to:
  /// **'طُبخت {name}، وخُصم ما أكدته من المخزون.'**
  String detailCookedNote(String name);

  /// No description provided for @detailShowKitchen.
  ///
  /// In ar, this message translates to:
  /// **'اعرض ما تبقى في مطبخك'**
  String get detailShowKitchen;

  /// No description provided for @detailServings.
  ///
  /// In ar, this message translates to:
  /// **'{amount} حصة'**
  String detailServings(String amount);

  /// No description provided for @detailOneServing.
  ///
  /// In ar, this message translates to:
  /// **'1 حصة'**
  String get detailOneServing;

  /// No description provided for @detailLeftoversSaved.
  ///
  /// In ar, this message translates to:
  /// **'وضعنا {servings} في الثلاجة، وستجدها في الميكروويف عندما تريد تسخينها.'**
  String detailLeftoversSaved(String servings);

  /// No description provided for @detailAnyLeftovers.
  ///
  /// In ar, this message translates to:
  /// **'هل تبقّى أكل؟'**
  String get detailAnyLeftovers;

  /// No description provided for @detailLeftoversHint.
  ///
  /// In ar, this message translates to:
  /// **'سجّله وسنضعه في الثلاجة لتسخّنه لاحقًا.'**
  String get detailLeftoversHint;

  /// No description provided for @detailRemindAfter.
  ///
  /// In ar, this message translates to:
  /// **'ذكّرني بها بعد'**
  String get detailRemindAfter;

  /// No description provided for @detailRemindNone.
  ///
  /// In ar, this message translates to:
  /// **'دون'**
  String get detailRemindNone;

  /// No description provided for @detailRemindDays.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{يوم} other{{count} أيام}}'**
  String detailRemindDays(int count);

  /// No description provided for @detailPutInFridge.
  ///
  /// In ar, this message translates to:
  /// **'ضعه في الثلاجة'**
  String get detailPutInFridge;

  /// No description provided for @detailHaveOf.
  ///
  /// In ar, this message translates to:
  /// **'عندك {have} من {total} {unit}'**
  String detailHaveOf(String have, String total, String unit);

  /// No description provided for @detailUsingStock.
  ///
  /// In ar, this message translates to:
  /// **'{name} · سنستخدم {stock}'**
  String detailUsingStock(String name, String stock);

  /// No description provided for @detailBoughtRest.
  ///
  /// In ar, this message translates to:
  /// **'اشتريت الباقي'**
  String get detailBoughtRest;

  /// No description provided for @detailCookedLess.
  ///
  /// In ar, this message translates to:
  /// **'طبخت بأقل'**
  String get detailCookedLess;

  /// No description provided for @detailBeforeDeduct.
  ///
  /// In ar, this message translates to:
  /// **'قبل الخصم من المخزون'**
  String get detailBeforeDeduct;

  /// No description provided for @detailWillDeduct.
  ///
  /// In ar, this message translates to:
  /// **'سيُخصم'**
  String get detailWillDeduct;

  /// No description provided for @detailWillDeductNote.
  ///
  /// In ar, this message translates to:
  /// **'موجود عندك بنفس الوحدة'**
  String get detailWillDeductNote;

  /// No description provided for @detailPartial.
  ///
  /// In ar, this message translates to:
  /// **'عندك جزء فقط'**
  String get detailPartial;

  /// No description provided for @detailPartialNote.
  ///
  /// In ar, this message translates to:
  /// **'هل اشتريت الباقي، أم طبخت بما عندك؟ في الحالتين يُخصم ما عندك.'**
  String get detailPartialNote;

  /// No description provided for @detailNotDeducted.
  ///
  /// In ar, this message translates to:
  /// **'لن يُخصم'**
  String get detailNotDeducted;

  /// No description provided for @detailNotDeductedNote.
  ///
  /// In ar, this message translates to:
  /// **'ناقص أو مسجّل بوحدة مختلفة. ستبقى التكلفة غير معروفة.'**
  String get detailNotDeductedNote;

  /// No description provided for @detailUnmeasuredGroup.
  ///
  /// In ar, this message translates to:
  /// **'دون مقدار في الوصفة'**
  String get detailUnmeasuredGroup;

  /// No description provided for @detailUnmeasuredNote.
  ///
  /// In ar, this message translates to:
  /// **'مثل «حسب الرغبة»، لن يُخصم'**
  String get detailUnmeasuredNote;

  /// No description provided for @detailConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get detailConfirm;

  /// No description provided for @detailNotYet.
  ///
  /// In ar, this message translates to:
  /// **'ليس بعد'**
  String get detailNotYet;

  /// No description provided for @kitOpenKitchen3d.
  ///
  /// In ar, this message translates to:
  /// **'مطبخي 3D'**
  String get kitOpenKitchen3d;

  /// No description provided for @kitShopping.
  ///
  /// In ar, this message translates to:
  /// **'المشتريات'**
  String get kitShopping;

  /// No description provided for @kitLeftoversTitle.
  ///
  /// In ar, this message translates to:
  /// **'بواقي الأكل'**
  String get kitLeftoversTitle;

  /// No description provided for @kitLeftoversEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بواقي مسجلة.'**
  String get kitLeftoversEmpty;

  /// No description provided for @kitLeftovers.
  ///
  /// In ar, this message translates to:
  /// **'البواقي'**
  String get kitLeftovers;

  /// No description provided for @kitAddIngredientTitle.
  ///
  /// In ar, this message translates to:
  /// **'أضف مكوّنًا'**
  String get kitAddIngredientTitle;

  /// No description provided for @kitAddIngredientDetail.
  ///
  /// In ar, this message translates to:
  /// **'ابحث واختر'**
  String get kitAddIngredientDetail;

  /// No description provided for @kitReceiptTitle.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة أو قائمة'**
  String get kitReceiptTitle;

  /// No description provided for @kitReceiptDetail.
  ///
  /// In ar, this message translates to:
  /// **'صورة أو كتابة'**
  String get kitReceiptDetail;

  /// No description provided for @kitAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get kitAll;

  /// No description provided for @kitAllCount.
  ///
  /// In ar, this message translates to:
  /// **'الكل {count}'**
  String kitAllCount(String count);

  /// No description provided for @kitGettingToKnow.
  ///
  /// In ar, this message translates to:
  /// **'ما زلنا نتعرف على مطبخك'**
  String get kitGettingToKnow;

  /// No description provided for @kitShelfEmpty.
  ///
  /// In ar, this message translates to:
  /// **'هذا الرف فارغ'**
  String get kitShelfEmpty;

  /// No description provided for @kitEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف بعض المكونات كبداية. لا نحتاج إلى جرد كامل للبدء.'**
  String get kitEmptyHint;

  /// No description provided for @kitTrySample.
  ///
  /// In ar, this message translates to:
  /// **'جرّب بمكونات جاهزة'**
  String get kitTrySample;

  /// No description provided for @kitSampleAdded.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت مكونات تجريبية إلى مطبخك'**
  String get kitSampleAdded;

  /// No description provided for @kitDeductNote.
  ///
  /// In ar, this message translates to:
  /// **'تُخصم الكميات بعد تأكيد الطبخ.'**
  String get kitDeductNote;

  /// No description provided for @kitQuantityUnknown.
  ///
  /// In ar, this message translates to:
  /// **'كمية غير محددة'**
  String get kitQuantityUnknown;

  /// No description provided for @kitEditItem.
  ///
  /// In ar, this message translates to:
  /// **'تعديل {name}'**
  String kitEditItem(String name);

  /// No description provided for @kitQuantityOf.
  ///
  /// In ar, this message translates to:
  /// **'كمية {name}'**
  String kitQuantityOf(String name);

  /// No description provided for @kitQuantityInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب عددًا صحيحًا يساوي 0 أو أكثر'**
  String get kitQuantityInvalid;

  /// No description provided for @kitQuantityLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكمية ({unit})'**
  String kitQuantityLabel(String unit);

  /// No description provided for @kitQuantityHelper.
  ///
  /// In ar, this message translates to:
  /// **'اكتب 0 إذا نفد'**
  String get kitQuantityHelper;

  /// No description provided for @kitCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get kitCancel;

  /// No description provided for @kitSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get kitSave;

  /// No description provided for @kitQuantityUpdated.
  ///
  /// In ar, this message translates to:
  /// **'حُدّثت كمية {name}'**
  String kitQuantityUpdated(String name);

  /// No description provided for @kitAddStockDone.
  ///
  /// In ar, this message translates to:
  /// **'تم، اعرض مطبخي'**
  String get kitAddStockDone;

  /// No description provided for @kitWhatDoYouHave.
  ///
  /// In ar, this message translates to:
  /// **'ماذا يوجد عندك؟'**
  String get kitWhatDoYouHave;

  /// No description provided for @kitAddStockHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط + لإضافة سريعة، أو اضغط على المكوّن لكتابة الكمية والوحدة.'**
  String get kitAddStockHint;

  /// No description provided for @kitSearchIngredient.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مكوّن'**
  String get kitSearchIngredient;

  /// No description provided for @kitScanBarcode.
  ///
  /// In ar, this message translates to:
  /// **'امسح باركود'**
  String get kitScanBarcode;

  /// No description provided for @kitIngredientNotFound.
  ///
  /// In ar, this message translates to:
  /// **'المكوّن غير موجود في القائمة. جرّب اسمًا آخر.'**
  String get kitIngredientNotFound;

  /// No description provided for @kitAddItem.
  ///
  /// In ar, this message translates to:
  /// **'إضافة {name}'**
  String kitAddItem(String name);

  /// No description provided for @kitAddedToKitchen.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف {name} إلى مطبخك'**
  String kitAddedToKitchen(String name);

  /// No description provided for @kitYouHave.
  ///
  /// In ar, this message translates to:
  /// **'عندك {amounts}'**
  String kitYouHave(String amounts);

  /// No description provided for @kitEnterAmount.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كمية أكبر من صفر'**
  String get kitEnterAmount;

  /// No description provided for @kitEnterWeight.
  ///
  /// In ar, this message translates to:
  /// **'اكتب وزنًا أكبر من صفر أو اتركها فارغة'**
  String get kitEnterWeight;

  /// No description provided for @kitAmount.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get kitAmount;

  /// No description provided for @kitUnit.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة'**
  String get kitUnit;

  /// No description provided for @kitPieceGrams.
  ///
  /// In ar, this message translates to:
  /// **'كام جرام في الـ{unit}؟ (اختياري)'**
  String kitPieceGrams(String unit);

  /// No description provided for @kitPieceMl.
  ///
  /// In ar, this message translates to:
  /// **'كام مل في الـ{unit}؟ (اختياري)'**
  String kitPieceMl(String unit);

  /// No description provided for @kitPieceHelper.
  ///
  /// In ar, this message translates to:
  /// **'من ميزانك أو المكتوب على العبوة. يفيد في الوصفات.'**
  String get kitPieceHelper;

  /// No description provided for @kitGramsShort.
  ///
  /// In ar, this message translates to:
  /// **'جم'**
  String get kitGramsShort;

  /// No description provided for @kitMlShort.
  ///
  /// In ar, this message translates to:
  /// **'مل'**
  String get kitMlShort;

  /// No description provided for @kitPlace.
  ///
  /// In ar, this message translates to:
  /// **'مكانه'**
  String get kitPlace;

  /// No description provided for @kitAddToKitchen.
  ///
  /// In ar, this message translates to:
  /// **'أضفه إلى مطبخي'**
  String get kitAddToKitchen;

  /// Leftover servings when exactly one
  ///
  /// In ar, this message translates to:
  /// **'{count} حصة'**
  String kitServing(String count);

  /// No description provided for @kitServings.
  ///
  /// In ar, this message translates to:
  /// **'{count} حصة'**
  String kitServings(String count);

  /// No description provided for @kitLeftoverDue.
  ///
  /// In ar, this message translates to:
  /// **'حان موعدها'**
  String get kitLeftoverDue;

  /// No description provided for @kitHowManyWarmed.
  ///
  /// In ar, this message translates to:
  /// **'كم حصة سخّنت؟'**
  String get kitHowManyWarmed;

  /// No description provided for @kitEatOf.
  ///
  /// In ar, this message translates to:
  /// **'{eaten} من {total}'**
  String kitEatOf(String eaten, String total);

  /// No description provided for @kitNotYet.
  ///
  /// In ar, this message translates to:
  /// **'ليس بعد'**
  String get kitNotYet;

  /// No description provided for @kitWarmedAndAte.
  ///
  /// In ar, this message translates to:
  /// **'سخّنت وأكلت'**
  String get kitWarmedAndAte;

  /// No description provided for @kitEmptySoFar.
  ///
  /// In ar, this message translates to:
  /// **'فارغ حتى الآن.'**
  String get kitEmptySoFar;

  /// No description provided for @kitSearchSomething.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن شيء'**
  String get kitSearchSomething;

  /// No description provided for @kitByKind.
  ///
  /// In ar, this message translates to:
  /// **'حسب النوع'**
  String get kitByKind;

  /// No description provided for @kitLastAdded.
  ///
  /// In ar, this message translates to:
  /// **'آخر ما وُضع'**
  String get kitLastAdded;

  /// No description provided for @kitItemCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{فارغ} =1{شيء واحد} =2{شيئان} few{{count} أشياء} other{{count} شيء}}'**
  String kitItemCount(int count);

  /// No description provided for @kitSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get kitSearch;

  /// No description provided for @kitAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get kitAdd;

  /// No description provided for @kitAllStock.
  ///
  /// In ar, this message translates to:
  /// **'كل المخزون'**
  String get kitAllStock;

  /// No description provided for @kitClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get kitClose;

  /// No description provided for @kitNothingByName.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد شيء بهذا الاسم هنا.'**
  String get kitNothingByName;

  /// No description provided for @kitItemSemantics.
  ///
  /// In ar, this message translates to:
  /// **'{label}، {amount}'**
  String kitItemSemantics(String label, String amount);

  /// No description provided for @kitShoppingError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تجهيز القائمة. حاول مرة أخرى.'**
  String get kitShoppingError;

  /// No description provided for @kitShoppingTitle.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الشراء للأسبوع'**
  String get kitShoppingTitle;

  /// No description provided for @kitShareList.
  ///
  /// In ar, this message translates to:
  /// **'أرسلها (واتساب وغيره)'**
  String get kitShareList;

  /// No description provided for @kitNothingMissing.
  ///
  /// In ar, this message translates to:
  /// **'لا ينقصك شيء للأكلات المخططة.'**
  String get kitNothingMissing;

  /// No description provided for @kitAboutTotal.
  ///
  /// In ar, this message translates to:
  /// **'حوالي {amount} {currency} بأسعارك.'**
  String kitAboutTotal(String amount, String currency);

  /// No description provided for @kitKnownSubtotal.
  ///
  /// In ar, this message translates to:
  /// **'المعروف سعره: {amount} {currency}، وبعض الأشياء دون سعر.'**
  String kitKnownSubtotal(String amount, String currency);

  /// No description provided for @kitPaidHint.
  ///
  /// In ar, this message translates to:
  /// **'كم دفعت؟ (اختياري)'**
  String get kitPaidHint;

  /// No description provided for @kitUnresolvedLines.
  ///
  /// In ar, this message translates to:
  /// **'يوجد {count} سطر دون كمية (مثل «حسب الرغبة») خارج القائمة.'**
  String kitUnresolvedLines(int count);

  /// No description provided for @kitUnconvertibleStock.
  ///
  /// In ar, this message translates to:
  /// **'وحدة المخزون لـ {names} لا تتحول إلى وحدة الوصفة؛ راجعها في المخزون.'**
  String kitUnconvertibleStock(String names);

  /// Joins names in a list
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get kitListSeparator;

  /// No description provided for @kitMarkBought.
  ///
  /// In ar, this message translates to:
  /// **'علّم ما اشتريته'**
  String get kitMarkBought;

  /// No description provided for @kitPutBoughtAway.
  ///
  /// In ar, this message translates to:
  /// **'ضع ما اشتريته في المطبخ'**
  String get kitPutBoughtAway;

  /// No description provided for @kitPreviewNoYield.
  ///
  /// In ar, this message translates to:
  /// **'مكونات عندك؛ حدّد الحصص للتحقق من الكميات'**
  String get kitPreviewNoYield;

  /// No description provided for @kitPreviewReady.
  ///
  /// In ar, this message translates to:
  /// **'جاهزة بالموجود'**
  String get kitPreviewReady;

  /// No description provided for @kitPreviewNotEnough.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مقادير كافية للحكم'**
  String get kitPreviewNotEnough;

  /// No description provided for @kitPreviewMissingUnknown.
  ///
  /// In ar, this message translates to:
  /// **'ناقص {missing} · {unknown} مقادير غير محسومة'**
  String kitPreviewMissingUnknown(int missing, int unknown);

  /// No description provided for @kitPreviewUnknown.
  ///
  /// In ar, this message translates to:
  /// **'{unknown} مقادير غير محسومة'**
  String kitPreviewUnknown(int unknown);

  /// No description provided for @kitPreviewMissing.
  ///
  /// In ar, this message translates to:
  /// **'ناقص {missing} من المكونات'**
  String kitPreviewMissing(int missing);

  /// No description provided for @mineNewRecipe.
  ///
  /// In ar, this message translates to:
  /// **'وصفة من عندي'**
  String get mineNewRecipe;

  /// Under a recipe's name: how many ingredients and steps.
  ///
  /// In ar, this message translates to:
  /// **'{ingredients} مكونات · {steps} خطوات'**
  String mineIngredientsSteps(int ingredients, int steps);

  /// No description provided for @mineTomorrow.
  ///
  /// In ar, this message translates to:
  /// **'غدًا'**
  String get mineTomorrow;

  /// No description provided for @minePutOnTable.
  ///
  /// In ar, this message translates to:
  /// **'ضعها على السفرة'**
  String get minePutOnTable;

  /// No description provided for @mineAddedToTable.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت إلى السفرة.'**
  String get mineAddedToTable;

  /// No description provided for @mineSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'لم تُحفظ الوصفة. حاول مرة أخرى.'**
  String get mineSaveFailed;

  /// No description provided for @mineSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت الوصفة في وصفاتك.'**
  String get mineSaved;

  /// No description provided for @mineCuisineNeeded.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مطبخًا محددًا للوصفة، مثل «مصري».'**
  String get mineCuisineNeeded;

  /// No description provided for @mineSaving.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الحفظ…'**
  String get mineSaving;

  /// No description provided for @mineSave.
  ///
  /// In ar, this message translates to:
  /// **'احفظ الوصفة'**
  String get mineSave;

  /// No description provided for @mineDishName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الأكلة'**
  String get mineDishName;

  /// No description provided for @mineShortDescription.
  ///
  /// In ar, this message translates to:
  /// **'وصف قصير'**
  String get mineShortDescription;

  /// No description provided for @mineCuisine.
  ///
  /// In ar, this message translates to:
  /// **'المطبخ'**
  String get mineCuisine;

  /// No description provided for @minePrepMinutes.
  ///
  /// In ar, this message translates to:
  /// **'التحضير (دقيقة)'**
  String get minePrepMinutes;

  /// No description provided for @mineCookMinutes.
  ///
  /// In ar, this message translates to:
  /// **'الطبخ (دقيقة)'**
  String get mineCookMinutes;

  /// No description provided for @mineServesHowMany.
  ///
  /// In ar, this message translates to:
  /// **'تكفي كم فردًا؟'**
  String get mineServesHowMany;

  /// No description provided for @mineIngredients.
  ///
  /// In ar, this message translates to:
  /// **'المكونات'**
  String get mineIngredients;

  /// No description provided for @mineAddIngredient.
  ///
  /// In ar, this message translates to:
  /// **'+ مكوّن'**
  String get mineAddIngredient;

  /// No description provided for @mineToTaste.
  ///
  /// In ar, this message translates to:
  /// **'حسب الرغبة'**
  String get mineToTaste;

  /// No description provided for @mineWithoutAmount.
  ///
  /// In ar, this message translates to:
  /// **'دون كمية'**
  String get mineWithoutAmount;

  /// No description provided for @mineWithAmount.
  ///
  /// In ar, this message translates to:
  /// **'بكمية'**
  String get mineWithAmount;

  /// No description provided for @mineRemove.
  ///
  /// In ar, this message translates to:
  /// **'احذف'**
  String get mineRemove;

  /// No description provided for @mineSteps.
  ///
  /// In ar, this message translates to:
  /// **'الخطوات'**
  String get mineSteps;

  /// No description provided for @mineAddStep.
  ///
  /// In ar, this message translates to:
  /// **'+ خطوة'**
  String get mineAddStep;

  /// No description provided for @mineStepHint.
  ///
  /// In ar, this message translates to:
  /// **'ماذا ستفعل'**
  String get mineStepHint;

  /// No description provided for @mineMinutesHint.
  ///
  /// In ar, this message translates to:
  /// **'دقيقة'**
  String get mineMinutesHint;

  /// No description provided for @mineNutritionUnknown.
  ///
  /// In ar, this message translates to:
  /// **'لن تُحسب القيم الغذائية لهذه الوصفة حتى تُربط مكوناتها بمصدر.'**
  String get mineNutritionUnknown;

  /// No description provided for @mineSearchIngredient.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مكوّن'**
  String get mineSearchIngredient;

  /// No description provided for @mineRecipeBookTitle.
  ///
  /// In ar, this message translates to:
  /// **'كتاب الوصفات'**
  String get mineRecipeBookTitle;

  /// How many ways (recipes) a dish has.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{طريقة واحدة} =2{طريقتان} zero{{count} طرق} few{{count} طرق} other{{count} طريقة}}'**
  String mineWays(int count);

  /// How many countries make a dish.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{بلد واحد} =2{بلدان} zero{{count} بلاد} few{{count} بلاد} other{{count} بلدًا}}'**
  String mineCountries(int count);

  /// Shortest and longest time of a dish's ways, in minutes.
  ///
  /// In ar, this message translates to:
  /// **'{from}–{to} دقيقة'**
  String mineDishTimeRange(String from, String to);

  /// No description provided for @onbCountry.
  ///
  /// In ar, this message translates to:
  /// **'البلد'**
  String get onbCountry;

  /// No description provided for @onbCountryEgypt.
  ///
  /// In ar, this message translates to:
  /// **'مصر · جنيه مصري'**
  String get onbCountryEgypt;

  /// No description provided for @onbCountrySaudi.
  ///
  /// In ar, this message translates to:
  /// **'السعودية · ريال سعودي'**
  String get onbCountrySaudi;

  /// No description provided for @onbEgypt.
  ///
  /// In ar, this message translates to:
  /// **'مصر'**
  String get onbEgypt;

  /// No description provided for @onbSaudi.
  ///
  /// In ar, this message translates to:
  /// **'السعودية'**
  String get onbSaudi;

  /// No description provided for @onbBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get onbBack;

  /// No description provided for @onbSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get onbSkip;

  /// No description provided for @onbStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get onbStart;

  /// No description provided for @onbOpenSofra.
  ///
  /// In ar, this message translates to:
  /// **'افتح سفرتي'**
  String get onbOpenSofra;

  /// No description provided for @onbContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get onbContinue;

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'كل ما في مطبخك\nيصنع أكلة طيبة'**
  String get onbWelcomeTitle;

  /// No description provided for @onbNameTitle.
  ///
  /// In ar, this message translates to:
  /// **'ما اسمك؟'**
  String get onbNameTitle;

  /// No description provided for @onbNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثلًا: مريم'**
  String get onbNameHint;

  /// No description provided for @onbPeopleTitle.
  ///
  /// In ar, this message translates to:
  /// **'لكم شخصًا تطبخ؟'**
  String get onbPeopleTitle;

  /// No description provided for @onbYourMeals.
  ///
  /// In ar, this message translates to:
  /// **'وجباتك'**
  String get onbYourMeals;

  /// No description provided for @onbCuisinesTitle.
  ///
  /// In ar, this message translates to:
  /// **'ما المطابخ التي تحبها؟'**
  String get onbCuisinesTitle;

  /// No description provided for @onbCuisines.
  ///
  /// In ar, this message translates to:
  /// **'المطابخ'**
  String get onbCuisines;

  /// No description provided for @onbQuickFirst.
  ///
  /// In ar, this message translates to:
  /// **'السريعة أولًا'**
  String get onbQuickFirst;

  /// No description provided for @onbHealthTitle.
  ///
  /// In ar, this message translates to:
  /// **'نراعي صحتك'**
  String get onbHealthTitle;

  /// No description provided for @onbHealthConditions.
  ///
  /// In ar, this message translates to:
  /// **'حالتك الصحية'**
  String get onbHealthConditions;

  /// No description provided for @onbHealthNote.
  ///
  /// In ar, this message translates to:
  /// **'تُحفظ في ملفك فقط، ولا تغني عن طبيبك.'**
  String get onbHealthNote;

  /// No description provided for @onbAvoidFoods.
  ///
  /// In ar, this message translates to:
  /// **'أطعمة تتجنبها'**
  String get onbAvoidFoods;

  /// No description provided for @onbAvoidNote.
  ///
  /// In ar, this message translates to:
  /// **'ننبهك إذا ظهرت في وصفة. راجع العبوات بنفسك.'**
  String get onbAvoidNote;

  /// Short label for the stored condition high blood pressure.
  ///
  /// In ar, this message translates to:
  /// **'ضغط الدم'**
  String get onbHealthBloodPressure;

  /// Short label for the stored condition high cholesterol.
  ///
  /// In ar, this message translates to:
  /// **'الكوليسترول'**
  String get onbHealthCholesterol;

  /// Short label for the stored condition kidney disease.
  ///
  /// In ar, this message translates to:
  /// **'الكلى'**
  String get onbHealthKidneys;

  /// No description provided for @onbHello.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا يا {name}'**
  String onbHello(String name);

  /// No description provided for @onbReady.
  ///
  /// In ar, this message translates to:
  /// **'سفرتك جاهزة'**
  String get onbReady;

  /// No description provided for @onbStatPeople.
  ///
  /// In ar, this message translates to:
  /// **'أشخاص'**
  String get onbStatPeople;

  /// No description provided for @onbStatMeals.
  ///
  /// In ar, this message translates to:
  /// **'وجبات'**
  String get onbStatMeals;

  /// No description provided for @onbStatCuisines.
  ///
  /// In ar, this message translates to:
  /// **'مطابخ'**
  String get onbStatCuisines;

  /// No description provided for @onbStatCares.
  ///
  /// In ar, this message translates to:
  /// **'للانتباه'**
  String get onbStatCares;

  /// No description provided for @onbStepOf.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {step} من {total}'**
  String onbStepOf(String step, String total);

  /// No description provided for @onbMore.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get onbMore;

  /// No description provided for @onbMoreSelected.
  ///
  /// In ar, this message translates to:
  /// **'المزيد، {count} مختارة'**
  String onbMoreSelected(String count);

  /// No description provided for @onbAddCustom.
  ///
  /// In ar, this message translates to:
  /// **'إضافة «{name}»'**
  String onbAddCustom(String name);

  /// No description provided for @onbSearchOrType.
  ///
  /// In ar, this message translates to:
  /// **'ابحث أو اكتب اسمًا'**
  String get onbSearchOrType;

  /// No description provided for @onbSearch.
  ///
  /// In ar, this message translates to:
  /// **'ابحث'**
  String get onbSearch;

  /// No description provided for @onbDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get onbDone;

  /// No description provided for @onbZoneFridge.
  ///
  /// In ar, this message translates to:
  /// **'الثلاجة'**
  String get onbZoneFridge;

  /// No description provided for @onbZoneFreezer.
  ///
  /// In ar, this message translates to:
  /// **'الفريزر'**
  String get onbZoneFreezer;

  /// No description provided for @onbZonePantry.
  ///
  /// In ar, this message translates to:
  /// **'الدولاب'**
  String get onbZonePantry;

  /// Count phrase for exactly one; thing is the singular noun the caller passes.
  ///
  /// In ar, this message translates to:
  /// **'{thing} واحدة'**
  String onbCountOne(String thing);

  /// No description provided for @onbMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقيقة'**
  String onbMinutes(String minutes);

  /// No description provided for @onbTimeUnknown.
  ///
  /// In ar, this message translates to:
  /// **'الوقت غير محدد'**
  String get onbTimeUnknown;

  /// No description provided for @planSaturday.
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get planSaturday;

  /// No description provided for @planSunday.
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get planSunday;

  /// No description provided for @planMonday.
  ///
  /// In ar, this message translates to:
  /// **'الاثنين'**
  String get planMonday;

  /// No description provided for @planTuesday.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get planTuesday;

  /// No description provided for @planWednesday.
  ///
  /// In ar, this message translates to:
  /// **'الأربع'**
  String get planWednesday;

  /// No description provided for @planThursday.
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get planThursday;

  /// No description provided for @planFriday.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get planFriday;

  /// No description provided for @planToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get planToday;

  /// No description provided for @planTomorrow.
  ///
  /// In ar, this message translates to:
  /// **'غدًا'**
  String get planTomorrow;

  /// No description provided for @planMonthTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطة الشهر'**
  String get planMonthTitle;

  /// No description provided for @planMonthCalcError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حساب هذه الخطة. راجع الأكلات وحاول مرة أخرى.'**
  String get planMonthCalcError;

  /// No description provided for @planConflictTitle.
  ///
  /// In ar, this message translates to:
  /// **'توجد أيام عليها أكل'**
  String get planConflictTitle;

  /// No description provided for @planConflictBody.
  ///
  /// In ar, this message translates to:
  /// **'توجد {count} وجبة مخططة في الأيام نفسها. ماذا نفعل بها؟'**
  String planConflictBody(int count);

  /// No description provided for @planNotYet.
  ///
  /// In ar, this message translates to:
  /// **'ليس بعد'**
  String get planNotYet;

  /// No description provided for @planReplace.
  ///
  /// In ar, this message translates to:
  /// **'استبدلها'**
  String get planReplace;

  /// No description provided for @planKeepExisting.
  ///
  /// In ar, this message translates to:
  /// **'أبقِ الموجود'**
  String get planKeepExisting;

  /// No description provided for @planMonthAdded.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت الخطة إلى السفرة.'**
  String get planMonthAdded;

  /// No description provided for @planMonthNotSaved.
  ///
  /// In ar, this message translates to:
  /// **'لم تُحفظ الخطة. احسبها مرة أخرى.'**
  String get planMonthNotSaved;

  /// No description provided for @planPutOnTable.
  ///
  /// In ar, this message translates to:
  /// **'ضع الخطة على السفرة'**
  String get planPutOnTable;

  /// No description provided for @planCalculating.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الحساب…'**
  String get planCalculating;

  /// No description provided for @planCalculateMonth.
  ///
  /// In ar, this message translates to:
  /// **'احسب الشهر'**
  String get planCalculateMonth;

  /// No description provided for @planThisMonth.
  ///
  /// In ar, this message translates to:
  /// **'هذا الشهر'**
  String get planThisMonth;

  /// No description provided for @planNextMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر القادم'**
  String get planNextMonth;

  /// No description provided for @planMonthBudget.
  ///
  /// In ar, this message translates to:
  /// **'ميزانية الأكل للشهر'**
  String get planMonthBudget;

  /// No description provided for @planMealsToPlan.
  ///
  /// In ar, this message translates to:
  /// **'الوجبات التي سنخطط لها'**
  String get planMealsToPlan;

  /// No description provided for @planWeekMenu.
  ///
  /// In ar, this message translates to:
  /// **'منيو الأسبوع'**
  String get planWeekMenu;

  /// No description provided for @planFillEmptyDays.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الأيام الفارغة'**
  String get planFillEmptyDays;

  /// No description provided for @planWeekMenuHint.
  ///
  /// In ar, this message translates to:
  /// **'يتكرر هذا الأسبوع طوال الشهر. يمكنك وضع أكلتين في الخانة نفسها، ونختار الأوفر.'**
  String get planWeekMenuHint;

  /// No description provided for @planOmitUnmeasured.
  ///
  /// In ar, this message translates to:
  /// **'استبعد الأشياء التي ليس لها كمية من الحساب'**
  String get planOmitUnmeasured;

  /// No description provided for @planOmitUnmeasuredHint.
  ///
  /// In ar, this message translates to:
  /// **'مثل «ملح حسب الرغبة». إذا أوقفتها، ستبقى التكلفة غير معروفة.'**
  String get planOmitUnmeasuredHint;

  /// No description provided for @planPick.
  ///
  /// In ar, this message translates to:
  /// **'+ اختر'**
  String get planPick;

  /// No description provided for @planOrAlternative.
  ///
  /// In ar, this message translates to:
  /// **'أو {name}'**
  String planOrAlternative(String name);

  /// No description provided for @planSearchMeal.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن أكلة'**
  String get planSearchMeal;

  /// No description provided for @planMonthFits.
  ///
  /// In ar, this message translates to:
  /// **'يكلّفك هذا الشهر شراء نحو {cost}، ويتبقى من الميزانية {left}.'**
  String planMonthFits(String cost, String left);

  /// No description provided for @planMonthOver.
  ///
  /// In ar, this message translates to:
  /// **'أوفر اختيار يتجاوز الميزانية بـ {over}. جرّب أكلات أوفر أو أضف بديلًا في بعض الخانات.'**
  String planMonthOver(String over);

  /// No description provided for @planMonthBestFits.
  ///
  /// In ar, this message translates to:
  /// **'أوفر خطة وجدناها تكلّفك شراء نحو {cost}، ويتبقى من الميزانية {left}.'**
  String planMonthBestFits(String cost, String left);

  /// No description provided for @planMonthUnknown.
  ///
  /// In ar, this message translates to:
  /// **'التكلفة الكاملة غير معروفة بعد.'**
  String get planMonthUnknown;

  /// No description provided for @planRecordPrices.
  ///
  /// In ar, this message translates to:
  /// **'سجّل هذه الأسعار'**
  String get planRecordPrices;

  /// No description provided for @planRecordPricesHint.
  ///
  /// In ar, this message translates to:
  /// **'بسعرك أنت، من آخر مرة اشتريت. لا نخمّن الأسعار.'**
  String get planRecordPricesHint;

  /// No description provided for @planUnresolvedUnits.
  ///
  /// In ar, this message translates to:
  /// **'بعض المكونات مسجّلة بوحدة لا تتحول إلى وحدة الوصفة. حدد التحويل من صفحة المخزون.'**
  String get planUnresolvedUnits;

  /// No description provided for @planTruncated.
  ///
  /// In ar, this message translates to:
  /// **'جرّبنا {count} توليفة فقط من البدائل؛ قد توجد أوفر منها.'**
  String planTruncated(int count);

  /// No description provided for @planUncounted.
  ///
  /// In ar, this message translates to:
  /// **'غير محسوب: {items}.'**
  String planUncounted(String items);

  /// No description provided for @planListSeparator.
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get planListSeparator;

  /// No description provided for @planSavePrice.
  ///
  /// In ar, this message translates to:
  /// **'حفظ السعر'**
  String get planSavePrice;

  /// No description provided for @planAddHereEmpty.
  ///
  /// In ar, this message translates to:
  /// **'أضف ما عندك هنا، وسنقترح ما تطبخه منه.'**
  String get planAddHereEmpty;

  /// No description provided for @planLeftovers.
  ///
  /// In ar, this message translates to:
  /// **'بواقي الأكل'**
  String get planLeftovers;

  /// No description provided for @planLeftoversEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بواقٍ مسجّلة. عندما تطبخ ويتبقى شيء، ستجده هنا لتسخينه.'**
  String get planLeftoversEmpty;

  /// No description provided for @planMyStock.
  ///
  /// In ar, this message translates to:
  /// **'مخزون مطبخي'**
  String get planMyStock;

  /// No description provided for @planGoodMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير'**
  String get planGoodMorning;

  /// No description provided for @planGoodDay.
  ///
  /// In ar, this message translates to:
  /// **'نهارك سعيد'**
  String get planGoodDay;

  /// No description provided for @planGoodEvening.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير'**
  String get planGoodEvening;

  /// No description provided for @planKitchenStyle.
  ///
  /// In ar, this message translates to:
  /// **'شكل المطبخ'**
  String get planKitchenStyle;

  /// No description provided for @planSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get planSettings;

  /// No description provided for @planWhen.
  ///
  /// In ar, this message translates to:
  /// **'{slot} · {day}'**
  String planWhen(String slot, String day);

  /// No description provided for @planStock.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get planStock;

  /// No description provided for @planLeftoversDue.
  ///
  /// In ar, this message translates to:
  /// **'بواقٍ حان موعدها: {count}'**
  String planLeftoversDue(String count);

  /// No description provided for @planWhatToCookToday.
  ///
  /// In ar, this message translates to:
  /// **'ماذا نطبخ اليوم؟'**
  String get planWhatToCookToday;

  /// No description provided for @planPickRecipeHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر وصفة، ونعرض لك الناقص من مطبخك قبل البدء.'**
  String get planPickRecipeHint;

  /// No description provided for @planPickRecipe.
  ///
  /// In ar, this message translates to:
  /// **'اختر وصفة'**
  String get planPickRecipe;

  /// No description provided for @planNextOnTable.
  ///
  /// In ar, this message translates to:
  /// **'التالي على السفرة · {when}'**
  String planNextOnTable(String when);

  /// No description provided for @planStartCooking.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الطبخ'**
  String get planStartCooking;

  /// No description provided for @planTableEmpty.
  ///
  /// In ar, this message translates to:
  /// **'السفرة فارغة'**
  String get planTableEmpty;

  /// No description provided for @planTableEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'افتح كتاب الوصفات واختر أكلة لتظهر هنا.'**
  String get planTableEmptyHint;

  /// No description provided for @planRecipeBook.
  ///
  /// In ar, this message translates to:
  /// **'كتاب الوصفات'**
  String get planRecipeBook;

  /// No description provided for @planOnTable.
  ///
  /// In ar, this message translates to:
  /// **'على سفرة {day}'**
  String planOnTable(String day);

  /// No description provided for @planShoppingList.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الشراء'**
  String get planShoppingList;

  /// No description provided for @planUpcomingMeals.
  ///
  /// In ar, this message translates to:
  /// **'الأكلات القادمة'**
  String get planUpcomingMeals;

  /// No description provided for @planAllPlans.
  ///
  /// In ar, this message translates to:
  /// **'كل الخطط'**
  String get planAllPlans;

  /// No description provided for @planNoMealsPlanned.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أكلات مخططة. اختر من كتاب الوصفات.'**
  String get planNoMealsPlanned;

  /// No description provided for @planWelcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بيك في سفرة'**
  String get planWelcome;

  /// No description provided for @planWelcomeName.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا يا {name}'**
  String planWelcomeName(String name);

  /// No description provided for @planCookFromStockQuestion.
  ///
  /// In ar, this message translates to:
  /// **'نُعدّ أكلة طيبة مما لديك'**
  String get planCookFromStockQuestion;

  /// No description provided for @planWhatCanICook.
  ///
  /// In ar, this message translates to:
  /// **'ماذا أطبخ مما لدي؟'**
  String get planWhatCanICook;

  /// No description provided for @planWhatCanICookHint.
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات من خزينك، مع توضيح الكميات والناقص. لا نخصم أي شيء قبل تأكيد الطبخ.'**
  String get planWhatCanICookHint;

  /// No description provided for @planDiscoverFromStock.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف من الموجود'**
  String get planDiscoverFromStock;

  /// No description provided for @planExploreAll.
  ///
  /// In ar, this message translates to:
  /// **'أو استكشف كل الوصفات'**
  String get planExploreAll;

  /// No description provided for @planPantryCount.
  ///
  /// In ar, this message translates to:
  /// **'الخزين · {count} مكونات'**
  String planPantryCount(int count);

  /// No description provided for @planArrangeMeals.
  ///
  /// In ar, this message translates to:
  /// **'رتّب وجباتك'**
  String get planArrangeMeals;

  /// No description provided for @planLeftoversReminder.
  ///
  /// In ar, this message translates to:
  /// **'عندك {count} بواقي عليها تذكير'**
  String planLeftoversReminder(int count);

  /// No description provided for @planLeftoversNone.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بواقي مسجلة.'**
  String get planLeftoversNone;

  /// No description provided for @planSeeThem.
  ///
  /// In ar, this message translates to:
  /// **'شوفها'**
  String get planSeeThem;

  /// No description provided for @planTodayMeals.
  ///
  /// In ar, this message translates to:
  /// **'وجبات اليوم'**
  String get planTodayMeals;

  /// No description provided for @planNoMealToday.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد وجبة لليوم بعد.'**
  String get planNoMealToday;

  /// No description provided for @planOpenPlan.
  ///
  /// In ar, this message translates to:
  /// **'افتح الخطة'**
  String get planOpenPlan;

  /// No description provided for @planMonthAndBudget.
  ///
  /// In ar, this message translates to:
  /// **'خطة الشهر والميزانية'**
  String get planMonthAndBudget;

  /// No description provided for @planShoppingItems.
  ///
  /// In ar, this message translates to:
  /// **'قائمة المشتريات'**
  String get planShoppingItems;

  /// No description provided for @planTableWorthIt.
  ///
  /// In ar, this message translates to:
  /// **'سفرة تستحق اللمّة'**
  String get planTableWorthIt;

  /// No description provided for @planPickMealHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر أكلة، وسنعرض الناقص قبل البدء.'**
  String get planPickMealHint;

  /// No description provided for @planPickDishForTable.
  ///
  /// In ar, this message translates to:
  /// **'اختر طبخة للسفرة'**
  String get planPickDishForTable;

  /// No description provided for @planComingDays.
  ///
  /// In ar, this message translates to:
  /// **'السفرة في الأيام القادمة'**
  String get planComingDays;

  /// No description provided for @planNoDeductNote.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الوجبة لا يخصم من المخزون. يتم الخصم بعد تأكيد انتهاء الطبخ.'**
  String get planNoDeductNote;

  /// No description provided for @planMealLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل وصفة هذه الوجبة.'**
  String get planMealLoadError;

  /// No description provided for @planSlotServings.
  ///
  /// In ar, this message translates to:
  /// **'{slot} · {servings} أفراد'**
  String planSlotServings(String slot, int servings);

  /// No description provided for @planCooked.
  ///
  /// In ar, this message translates to:
  /// **'طُبخت'**
  String get planCooked;

  /// No description provided for @planInStock.
  ///
  /// In ar, this message translates to:
  /// **'{count} متوفر'**
  String planInStock(String count);

  /// No description provided for @planMissingCount.
  ///
  /// In ar, this message translates to:
  /// **'ناقص {count}'**
  String planMissingCount(String count);

  /// No description provided for @planOtherUnit.
  ///
  /// In ar, this message translates to:
  /// **'{count} بوحدة مختلفة'**
  String planOtherUnit(String count);

  /// No description provided for @planNoAmount.
  ///
  /// In ar, this message translates to:
  /// **'{count} دون مقدار'**
  String planNoAmount(String count);

  /// No description provided for @planBoughtMissing.
  ///
  /// In ar, this message translates to:
  /// **'اشتريت الناقص · أضفه للمخزون'**
  String get planBoughtMissing;

  /// No description provided for @planMissingAdded.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف الناقص إلى المخزون بالكمية المطلوبة'**
  String get planMissingAdded;

  /// No description provided for @planRemoveMeal.
  ///
  /// In ar, this message translates to:
  /// **'احذف الوجبة من السفرة'**
  String get planRemoveMeal;

  /// No description provided for @planPerPortion.
  ///
  /// In ar, this message translates to:
  /// **'للفرد: {kcal} سعر'**
  String planPerPortion(String kcal);

  /// No description provided for @planNutrient.
  ///
  /// In ar, this message translates to:
  /// **' · {label} {grams} جم'**
  String planNutrient(String label, String grams);

  /// No description provided for @planProtein.
  ///
  /// In ar, this message translates to:
  /// **'بروتين'**
  String get planProtein;

  /// No description provided for @planCarbs.
  ///
  /// In ar, this message translates to:
  /// **'كربوهيدرات'**
  String get planCarbs;

  /// No description provided for @planFat.
  ///
  /// In ar, this message translates to:
  /// **'دهون'**
  String get planFat;

  /// No description provided for @priceGroupVegetables.
  ///
  /// In ar, this message translates to:
  /// **'خضار'**
  String get priceGroupVegetables;

  /// No description provided for @priceGroupFruit.
  ///
  /// In ar, this message translates to:
  /// **'فاكهة'**
  String get priceGroupFruit;

  /// No description provided for @priceGroupProtein.
  ///
  /// In ar, this message translates to:
  /// **'لحوم ودواجن وأسماك'**
  String get priceGroupProtein;

  /// No description provided for @priceGroupDairy.
  ///
  /// In ar, this message translates to:
  /// **'ألبان وبيض'**
  String get priceGroupDairy;

  /// No description provided for @priceGroupGrains.
  ///
  /// In ar, this message translates to:
  /// **'أرز وحبوب'**
  String get priceGroupGrains;

  /// No description provided for @priceGroupLegumes.
  ///
  /// In ar, this message translates to:
  /// **'بقوليات'**
  String get priceGroupLegumes;

  /// No description provided for @priceGroupBread.
  ///
  /// In ar, this message translates to:
  /// **'خبز ومخبوزات'**
  String get priceGroupBread;

  /// No description provided for @priceGroupOils.
  ///
  /// In ar, this message translates to:
  /// **'زيوت وسمن'**
  String get priceGroupOils;

  /// No description provided for @priceGroupSpices.
  ///
  /// In ar, this message translates to:
  /// **'توابل وبهارات'**
  String get priceGroupSpices;

  /// No description provided for @priceGroupSauces.
  ///
  /// In ar, this message translates to:
  /// **'صوصات ومعلبات'**
  String get priceGroupSauces;

  /// No description provided for @priceGroupNuts.
  ///
  /// In ar, this message translates to:
  /// **'مكسرات'**
  String get priceGroupNuts;

  /// No description provided for @priceGroupDrinks.
  ///
  /// In ar, this message translates to:
  /// **'مشروبات'**
  String get priceGroupDrinks;

  /// No description provided for @priceGroupOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get priceGroupOther;

  /// No description provided for @priceLocationOff.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع مغلقة. اختر منطقتك من الخريطة أو البحث.'**
  String get priceLocationOff;

  /// No description provided for @priceLocationDenied.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسمح بالموقع. اختر منطقتك من الخريطة أو البحث.'**
  String get priceLocationDenied;

  /// No description provided for @priceNoAreaNearby.
  ///
  /// In ar, this message translates to:
  /// **'لا نعرف منطقة قريبة من موقعك. اختر من الخريطة.'**
  String get priceNoAreaNearby;

  /// No description provided for @priceLocateFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد موقعك. اختر منطقتك من الخريطة أو البحث.'**
  String get priceLocateFailed;

  /// No description provided for @priceAreaNowYours.
  ///
  /// In ar, this message translates to:
  /// **'منطقتك الآن: {area}'**
  String priceAreaNowYours(String area);

  /// No description provided for @priceSearchArea.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن منطقة أو مدينة'**
  String get priceSearchArea;

  /// No description provided for @priceClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get priceClear;

  /// No description provided for @priceNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج'**
  String get priceNoResults;

  /// No description provided for @priceChooseArea.
  ///
  /// In ar, this message translates to:
  /// **'اختر منطقتك'**
  String get priceChooseArea;

  /// No description provided for @priceMakeMyArea.
  ///
  /// In ar, this message translates to:
  /// **'اجعلها منطقتي'**
  String get priceMakeMyArea;

  /// No description provided for @priceAreaInfo.
  ///
  /// In ar, this message translates to:
  /// **'سعر المنطقة هو ما دفعه الناس فيها في آخر 60 يومًا، ويظهر فقط عندما يشاركه بيتان أو أكثر.'**
  String get priceAreaInfo;

  /// No description provided for @priceAreaFetchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب أسعار المنطقة.'**
  String get priceAreaFetchFailed;

  /// No description provided for @priceRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get priceRetry;

  /// No description provided for @priceNoAreaHere.
  ///
  /// In ar, this message translates to:
  /// **'لا نعرف منطقة هنا. جرّب البحث.'**
  String get priceNoAreaHere;

  /// No description provided for @priceMyLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقعي'**
  String get priceMyLocation;

  /// No description provided for @priceKnownInArea.
  ///
  /// In ar, this message translates to:
  /// **'{count} بسعر المنطقة'**
  String priceKnownInArea(String count);

  /// No description provided for @priceAreaColumn.
  ///
  /// In ar, this message translates to:
  /// **'سعر المنطقة'**
  String get priceAreaColumn;

  /// No description provided for @priceYoursColumn.
  ///
  /// In ar, this message translates to:
  /// **'سعرك'**
  String get priceYoursColumn;

  /// No description provided for @priceNoAreaPrice.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد سعر للمنطقة'**
  String get priceNoAreaPrice;

  /// No description provided for @priceAreaTapToUse.
  ///
  /// In ar, this message translates to:
  /// **'سعر المنطقة، اضغط لتجعله سعرك'**
  String get priceAreaTapToUse;

  /// No description provided for @priceAddYours.
  ///
  /// In ar, this message translates to:
  /// **'أضف سعرك'**
  String get priceAddYours;

  /// No description provided for @priceYoursTapToEdit.
  ///
  /// In ar, this message translates to:
  /// **'سعرك، اضغط لتعديله'**
  String get priceYoursTapToEdit;

  /// No description provided for @priceSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ السعر. حاول مرة أخرى.'**
  String get priceSaveFailed;

  /// No description provided for @priceSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ سعرك'**
  String get priceSaved;

  /// No description provided for @priceSavedShared.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ سعرك وشاركته مع منطقتك'**
  String get priceSavedShared;

  /// No description provided for @priceSavedShareFailed.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ سعرك، وتعذّرت مشاركته.'**
  String get priceSavedShareFailed;

  /// No description provided for @priceHint.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get priceHint;

  /// No description provided for @priceInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سعرًا أكبر من صفر'**
  String get priceInvalid;

  /// No description provided for @priceShareWith.
  ///
  /// In ar, this message translates to:
  /// **'شاركه مع {area}'**
  String priceShareWith(String area);

  /// No description provided for @priceCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get priceCancel;

  /// No description provided for @priceSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get priceSave;

  /// Short Egyptian pound label after a price
  ///
  /// In ar, this message translates to:
  /// **'ج.م'**
  String get priceCurrencyEgp;

  /// Short Saudi riyal label after a price
  ///
  /// In ar, this message translates to:
  /// **'ر.س'**
  String get priceCurrencySar;

  /// No description provided for @priceToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get priceToday;

  /// No description provided for @priceFridge.
  ///
  /// In ar, this message translates to:
  /// **'الثلاجة'**
  String get priceFridge;

  /// No description provided for @profCountryEgypt.
  ///
  /// In ar, this message translates to:
  /// **'مصر'**
  String get profCountryEgypt;

  /// No description provided for @profCountrySaudi.
  ///
  /// In ar, this message translates to:
  /// **'السعودية'**
  String get profCountrySaudi;

  /// Under the household size number
  ///
  /// In ar, this message translates to:
  /// **'أفراد'**
  String get profStatPeople;

  /// Under the number of daily meals
  ///
  /// In ar, this message translates to:
  /// **'وجبات يوميًا'**
  String get profStatMealsDaily;

  /// Under the number of saved recipes
  ///
  /// In ar, this message translates to:
  /// **'محفوظة'**
  String get profStatSaved;

  /// No description provided for @profHousehold.
  ///
  /// In ar, this message translates to:
  /// **'أهل البيت'**
  String get profHousehold;

  /// No description provided for @profHouseName.
  ///
  /// In ar, this message translates to:
  /// **'اسم البيت'**
  String get profHouseName;

  /// No description provided for @profHouseHint.
  ///
  /// In ar, this message translates to:
  /// **'بيت {name}'**
  String profHouseHint(String name);

  /// No description provided for @profYourName.
  ///
  /// In ar, this message translates to:
  /// **'اسمك'**
  String get profYourName;

  /// No description provided for @profCountry.
  ///
  /// In ar, this message translates to:
  /// **'البلد'**
  String get profCountry;

  /// No description provided for @profArea.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get profArea;

  /// No description provided for @profAddArea.
  ///
  /// In ar, this message translates to:
  /// **'أضف منطقتك'**
  String get profAddArea;

  /// No description provided for @profTableSize.
  ///
  /// In ar, this message translates to:
  /// **'أفراد السفرة'**
  String get profTableSize;

  /// No description provided for @profTaste.
  ///
  /// In ar, this message translates to:
  /// **'ذوقك في الأكل'**
  String get profTaste;

  /// No description provided for @profCuisines.
  ///
  /// In ar, this message translates to:
  /// **'المطابخ'**
  String get profCuisines;

  /// No description provided for @profAllCuisines.
  ///
  /// In ar, this message translates to:
  /// **'كل المطابخ'**
  String get profAllCuisines;

  /// No description provided for @profMeals.
  ///
  /// In ar, this message translates to:
  /// **'الوجبات'**
  String get profMeals;

  /// No description provided for @profNoMeal.
  ///
  /// In ar, this message translates to:
  /// **'لم تختر وجبة'**
  String get profNoMeal;

  /// No description provided for @profQuickFirst.
  ///
  /// In ar, this message translates to:
  /// **'الوصفات السريعة أولًا'**
  String get profQuickFirst;

  /// No description provided for @profHealth.
  ///
  /// In ar, this message translates to:
  /// **'الصحة'**
  String get profHealth;

  /// No description provided for @profAllergies.
  ///
  /// In ar, this message translates to:
  /// **'حساسية الأكل'**
  String get profAllergies;

  /// No description provided for @profNoAllergies.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حساسية'**
  String get profNoAllergies;

  /// No description provided for @profAllergiesInfo.
  ///
  /// In ar, this message translates to:
  /// **'تظهر كتنبيه بالاسم فقط، ويجب أن تراجع المكونات بنفسك.'**
  String get profAllergiesInfo;

  /// No description provided for @profConditions.
  ///
  /// In ar, this message translates to:
  /// **'حالات صحية'**
  String get profConditions;

  /// No description provided for @profNoConditions.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حالات'**
  String get profNoConditions;

  /// No description provided for @profConditionsInfo.
  ///
  /// In ar, this message translates to:
  /// **'للتذكير فقط؛ لا يغيّر التطبيق الوصفات ولا يقدّم نصيحة طبية.'**
  String get profConditionsInfo;

  /// No description provided for @profCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get profCancel;

  /// No description provided for @profSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get profSave;

  /// No description provided for @profRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة {label}'**
  String profRemove(String label);

  /// No description provided for @profAdd.
  ///
  /// In ar, this message translates to:
  /// **'أضف'**
  String get profAdd;

  /// No description provided for @profCountryCurrency.
  ///
  /// In ar, this message translates to:
  /// **'البلد والعملة'**
  String get profCountryCurrency;

  /// No description provided for @profReminders.
  ///
  /// In ar, this message translates to:
  /// **'التذكيرات'**
  String get profReminders;

  /// No description provided for @profSaving.
  ///
  /// In ar, this message translates to:
  /// **'جاري حفظ التغييرات…'**
  String get profSaving;

  /// No description provided for @profUnsaved.
  ///
  /// In ar, this message translates to:
  /// **'توجد تغييرات لم تُحفظ'**
  String get profUnsaved;

  /// No description provided for @profSignOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get profSignOut;

  /// No description provided for @profFooter.
  ///
  /// In ar, this message translates to:
  /// **'سفرة · صُنع بحب للبيوت'**
  String get profFooter;

  /// No description provided for @profMyAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get profMyAccount;

  /// No description provided for @profAccountLine.
  ///
  /// In ar, this message translates to:
  /// **'حسابك وتفضيلات بيتك'**
  String get profAccountLine;

  /// No description provided for @profAm.
  ///
  /// In ar, this message translates to:
  /// **'ص'**
  String get profAm;

  /// No description provided for @profPm.
  ///
  /// In ar, this message translates to:
  /// **'م'**
  String get profPm;

  /// No description provided for @profMealTimesIntro.
  ///
  /// In ar, this message translates to:
  /// **'موعد كل وجبة عندك، لنذكّرك قبلها.'**
  String get profMealTimesIntro;

  /// No description provided for @profNoReminder.
  ///
  /// In ar, this message translates to:
  /// **'دون تذكير'**
  String get profNoReminder;

  /// No description provided for @profClearReminder.
  ///
  /// In ar, this message translates to:
  /// **'احذف التذكير'**
  String get profClearReminder;

  /// No description provided for @profMealTimeOf.
  ///
  /// In ar, this message translates to:
  /// **'موعد {meal}'**
  String profMealTimeOf(String meal);

  /// No description provided for @profRemindBefore.
  ///
  /// In ar, this message translates to:
  /// **'ذكّرني قبلها بـ'**
  String get profRemindBefore;

  /// No description provided for @profMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقيقة'**
  String profMinutes(String minutes);

  /// No description provided for @profRanOutTitle.
  ///
  /// In ar, this message translates to:
  /// **'عندما ينفد مكوّن'**
  String get profRanOutTitle;

  /// No description provided for @profRanOutSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه بعد الطبخ إذا استخدمت آخر ما في المخزون'**
  String get profRanOutSubtitle;

  /// Android notification channel name
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات سفرة'**
  String get profChannelName;

  /// No description provided for @profChannelDescription.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد الأكل، والبواقي، والأشياء التي نفدت'**
  String get profChannelDescription;

  /// No description provided for @profReminderMealTitle.
  ///
  /// In ar, this message translates to:
  /// **'{slot} بعد {minutes} دقيقة'**
  String profReminderMealTitle(String slot, String minutes);

  /// No description provided for @profReminderMealBody.
  ///
  /// In ar, this message translates to:
  /// **'متخطط: {meal}. ابدأ التحضير.'**
  String profReminderMealBody(String meal);

  /// No description provided for @profReminderLeftoverTitle.
  ///
  /// In ar, this message translates to:
  /// **'بواقي {dish} في الثلاجة'**
  String profReminderLeftoverTitle(String dish);

  /// No description provided for @profReminderLeftoverBody.
  ///
  /// In ar, this message translates to:
  /// **'تبقّى {servings}. سخّنها اليوم.'**
  String profReminderLeftoverBody(String servings);

  /// No description provided for @profServingOne.
  ///
  /// In ar, this message translates to:
  /// **'1 حصة'**
  String get profServingOne;

  /// No description provided for @profServings.
  ///
  /// In ar, this message translates to:
  /// **'{count} حصة'**
  String profServings(String count);

  /// No description provided for @profStyleCabinets.
  ///
  /// In ar, this message translates to:
  /// **'طراز الخزائن'**
  String get profStyleCabinets;

  /// No description provided for @profStyleClassic.
  ///
  /// In ar, this message translates to:
  /// **'كلاسيكي'**
  String get profStyleClassic;

  /// No description provided for @profStyleModern.
  ///
  /// In ar, this message translates to:
  /// **'عصري'**
  String get profStyleModern;

  /// No description provided for @profStyleJapandi.
  ///
  /// In ar, this message translates to:
  /// **'ياباندي'**
  String get profStyleJapandi;

  /// No description provided for @profStyleFridge.
  ///
  /// In ar, this message translates to:
  /// **'الثلاجة'**
  String get profStyleFridge;

  /// No description provided for @profFridgeRetro.
  ///
  /// In ar, this message translates to:
  /// **'كريمية قديمة'**
  String get profFridgeRetro;

  /// No description provided for @profFridgeDouble.
  ///
  /// In ar, this message translates to:
  /// **'معدنية ببابين'**
  String get profFridgeDouble;

  /// No description provided for @profStyleRange.
  ///
  /// In ar, this message translates to:
  /// **'الموقد'**
  String get profStyleRange;

  /// No description provided for @profRangeFreestanding.
  ///
  /// In ar, this message translates to:
  /// **'موقد مستقل'**
  String get profRangeFreestanding;

  /// No description provided for @profRangeBuiltin.
  ///
  /// In ar, this message translates to:
  /// **'سطح وفرن مدمجان'**
  String get profRangeBuiltin;

  /// No description provided for @profStyleRug.
  ///
  /// In ar, this message translates to:
  /// **'السجادة'**
  String get profStyleRug;

  /// No description provided for @profRugNone.
  ///
  /// In ar, this message translates to:
  /// **'بلا سجادة'**
  String get profRugNone;

  /// No description provided for @profRugPersian.
  ///
  /// In ar, this message translates to:
  /// **'حمراء منقوشة'**
  String get profRugPersian;

  /// No description provided for @profRugTeal.
  ///
  /// In ar, this message translates to:
  /// **'زرقاء حديثة'**
  String get profRugTeal;

  /// No description provided for @profRugOchre.
  ///
  /// In ar, this message translates to:
  /// **'كليم دافئ'**
  String get profRugOchre;

  /// No description provided for @profStyleCurtain.
  ///
  /// In ar, this message translates to:
  /// **'الستارة'**
  String get profStyleCurtain;

  /// No description provided for @profCurtainGingham.
  ///
  /// In ar, this message translates to:
  /// **'قماش مربعات'**
  String get profCurtainGingham;

  /// No description provided for @profCurtainBlind.
  ///
  /// In ar, this message translates to:
  /// **'شرائح بيضاء'**
  String get profCurtainBlind;

  /// No description provided for @profCurtainNone.
  ///
  /// In ar, this message translates to:
  /// **'بلا ستارة'**
  String get profCurtainNone;

  /// No description provided for @profCabinetColor.
  ///
  /// In ar, this message translates to:
  /// **'لون الخزائن'**
  String get profCabinetColor;

  /// No description provided for @profColorOriginal.
  ///
  /// In ar, this message translates to:
  /// **'الأصلي'**
  String get profColorOriginal;

  /// No description provided for @profColorCream.
  ///
  /// In ar, this message translates to:
  /// **'كريمي'**
  String get profColorCream;

  /// No description provided for @profColorBlueGray.
  ///
  /// In ar, this message translates to:
  /// **'أزرق رمادي'**
  String get profColorBlueGray;

  /// No description provided for @profColorTerracotta.
  ///
  /// In ar, this message translates to:
  /// **'تيراكوتا'**
  String get profColorTerracotta;

  /// No description provided for @profShotKitchen.
  ///
  /// In ar, this message translates to:
  /// **'المطبخ كله'**
  String get profShotKitchen;

  /// No description provided for @profShotFridge.
  ///
  /// In ar, this message translates to:
  /// **'افتح الثلاجة'**
  String get profShotFridge;

  /// No description provided for @profShotFreezer.
  ///
  /// In ar, this message translates to:
  /// **'افتح الفريزر'**
  String get profShotFreezer;

  /// No description provided for @profExtras.
  ///
  /// In ar, this message translates to:
  /// **'إضافات'**
  String get profExtras;

  /// No description provided for @profPlants.
  ///
  /// In ar, this message translates to:
  /// **'نباتات معلقة'**
  String get profPlants;

  /// No description provided for @profCane.
  ///
  /// In ar, this message translates to:
  /// **'أبواب خيزران'**
  String get profCane;

  /// No description provided for @addTitle.
  ///
  /// In ar, this message translates to:
  /// **'أضف مشترياتك'**
  String get addTitle;

  /// No description provided for @addReadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت القراءة. تحقق من الاتصال، أو اكتب المشتريات بالأسفل.'**
  String get addReadFailed;

  /// No description provided for @addNothingFound.
  ///
  /// In ar, this message translates to:
  /// **'لم نجد مكونات هنا. جرّب صورة أوضح، أو اكتبها.'**
  String get addNothingFound;

  /// No description provided for @addCameraUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا غير متاحة. اسمح بها من إعدادات الهاتف.'**
  String get addCameraUnavailable;

  /// No description provided for @addPhotosFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الصور.'**
  String get addPhotosFailed;

  /// No description provided for @addMarkOne.
  ///
  /// In ar, this message translates to:
  /// **'علّم صنفًا واحدًا على الأقل'**
  String get addMarkOne;

  /// No description provided for @addPickOne.
  ///
  /// In ar, this message translates to:
  /// **'اختر مكوّنًا واحدًا على الأقل'**
  String get addPickOne;

  /// No description provided for @addToKitchen.
  ///
  /// In ar, this message translates to:
  /// **'أضف {count} إلى المطبخ'**
  String addToKitchen(String count);

  /// No description provided for @addCameraTitle.
  ///
  /// In ar, this message translates to:
  /// **'صوّر الفاتورة'**
  String get addCameraTitle;

  /// No description provided for @addCameraDetail.
  ///
  /// In ar, this message translates to:
  /// **'بالكاميرا'**
  String get addCameraDetail;

  /// No description provided for @addGalleryTitle.
  ///
  /// In ar, this message translates to:
  /// **'من الصور'**
  String get addGalleryTitle;

  /// No description provided for @addGalleryDetail.
  ///
  /// In ar, this message translates to:
  /// **'لقطة طلب أو فاتورة'**
  String get addGalleryDetail;

  /// No description provided for @addTypeHint.
  ///
  /// In ar, this message translates to:
  /// **'أو اكتب: 2 كيلو طماطم'**
  String get addTypeHint;

  /// No description provided for @addLineTooltip.
  ///
  /// In ar, this message translates to:
  /// **'أضف السطر'**
  String get addLineTooltip;

  /// No description provided for @addSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'لم تُحفظ المشتريات. تحقق من الاتصال وحاول مرة أخرى.'**
  String get addSaveFailed;

  /// No description provided for @addSavedNotice.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت {count, plural, =1{مكوّن واحدة} =2{مكوّنان} few{{count} مكونات} other{{count} مكوّن}} إلى مطبخك'**
  String addSavedNotice(int count);

  /// No description provided for @addRestart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ من جديد'**
  String get addRestart;

  /// No description provided for @addReading.
  ///
  /// In ar, this message translates to:
  /// **'نقرأ مشترياتك…'**
  String get addReading;

  /// No description provided for @addReadyCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} جاهزة'**
  String addReadyCount(String count);

  /// No description provided for @addCheckCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} للتأكد'**
  String addCheckCount(String count);

  /// No description provided for @addOpenCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} بلا مكوّن'**
  String addOpenCount(String count);

  /// No description provided for @addAmountUnknown.
  ///
  /// In ar, this message translates to:
  /// **'الكمية؟'**
  String get addAmountUnknown;

  /// No description provided for @addChooseIngredient.
  ///
  /// In ar, this message translates to:
  /// **'اختر المكوّن'**
  String get addChooseIngredient;

  /// No description provided for @addRestore.
  ///
  /// In ar, this message translates to:
  /// **'أعِده'**
  String get addRestore;

  /// No description provided for @addRemove.
  ///
  /// In ar, this message translates to:
  /// **'احذفه'**
  String get addRemove;

  /// No description provided for @addWhichIngredient.
  ///
  /// In ar, this message translates to:
  /// **'أي مكوّن هذا؟'**
  String get addWhichIngredient;

  /// No description provided for @addSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'رز، لبن، زيت…'**
  String get addSearchHint;

  /// No description provided for @addAmountTitle.
  ///
  /// In ar, this message translates to:
  /// **'كمية {name}'**
  String addAmountTitle(String name);

  /// No description provided for @addAmountHint.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get addAmountHint;

  /// No description provided for @addSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get addSave;

  /// No description provided for @addDontKnowAmount.
  ///
  /// In ar, this message translates to:
  /// **'لا أعرف الكمية'**
  String get addDontKnowAmount;

  /// No description provided for @addNotKnownYet.
  ///
  /// In ar, this message translates to:
  /// **'لم نعرفه بعد'**
  String get addNotKnownYet;

  /// No description provided for @addAsking.
  ///
  /// In ar, this message translates to:
  /// **'نتعرف على «{text}»…'**
  String addAsking(String text);

  /// No description provided for @addScanTitle.
  ///
  /// In ar, this message translates to:
  /// **'امسح باركود المنتج'**
  String get addScanTitle;

  /// No description provided for @addScanCameraOff.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا غير متاحة. اسمح بها من إعدادات الهاتف، أو اكتب الرقم بالأسفل.'**
  String get addScanCameraOff;

  /// No description provided for @addScanManualHint.
  ///
  /// In ar, this message translates to:
  /// **'أو اكتب الرقم الموجود تحت الباركود'**
  String get addScanManualHint;

  /// No description provided for @addScanGo.
  ///
  /// In ar, this message translates to:
  /// **'ابحث'**
  String get addScanGo;

  /// No description provided for @addScanUnknownProduct.
  ///
  /// In ar, this message translates to:
  /// **'هذا المنتج غير موجود في بياناتنا بعد'**
  String get addScanUnknownProduct;

  /// No description provided for @addScanPackage.
  ///
  /// In ar, this message translates to:
  /// **'العبوة: {size}'**
  String addScanPackage(String size);

  /// No description provided for @addScanWhich.
  ///
  /// In ar, this message translates to:
  /// **'أي مكوّن في مطبخك هذا؟ سنتذكره في المرة القادمة.'**
  String get addScanWhich;

  /// No description provided for @addScanSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم المكوّن (رز، لبن، زيت…)'**
  String get addScanSearchHint;

  /// No description provided for @rcpSaveRecipe.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الوصفة'**
  String get rcpSaveRecipe;

  /// No description provided for @rcpUnsaveRecipe.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحفظ'**
  String get rcpUnsaveRecipe;

  /// No description provided for @rcpFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get rcpFilterAll;

  /// No description provided for @rcpFilterFromStock.
  ///
  /// In ar, this message translates to:
  /// **'من الموجود'**
  String get rcpFilterFromStock;

  /// No description provided for @rcpFilterReadyFromStock.
  ///
  /// In ar, this message translates to:
  /// **'جاهزة بالموجود'**
  String get rcpFilterReadyFromStock;

  /// No description provided for @rcpFilterSaved.
  ///
  /// In ar, this message translates to:
  /// **'محفوظة'**
  String get rcpFilterSaved;

  /// No description provided for @rcpKindSection.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get rcpKindSection;

  /// No description provided for @rcpTimeSection.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get rcpTimeSection;

  /// No description provided for @rcpTimeAny.
  ///
  /// In ar, this message translates to:
  /// **'أي وقت'**
  String get rcpTimeAny;

  /// No description provided for @rcpTime30.
  ///
  /// In ar, this message translates to:
  /// **'30 دقيقة أو أقل'**
  String get rcpTime30;

  /// No description provided for @rcpTime60.
  ///
  /// In ar, this message translates to:
  /// **'ساعة أو أقل'**
  String get rcpTime60;

  /// No description provided for @rcpClearFilters.
  ///
  /// In ar, this message translates to:
  /// **'امسح الفلاتر'**
  String get rcpClearFilters;

  /// No description provided for @rcpSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث باسم أكلة أو مكوّن'**
  String get rcpSearchHint;

  /// No description provided for @rcpFilters.
  ///
  /// In ar, this message translates to:
  /// **'الفلاتر'**
  String get rcpFilters;

  /// No description provided for @rcpAllCuisines.
  ///
  /// In ar, this message translates to:
  /// **'كل المطابخ'**
  String get rcpAllCuisines;

  /// No description provided for @rcpStockNote.
  ///
  /// In ar, this message translates to:
  /// **'الكميات محسوبة لـ{servings} أفراد. المقادير غير المعروفة لا تُعتبر جاهزة.'**
  String rcpStockNote(String servings);

  /// No description provided for @rcpLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الوصفات.'**
  String get rcpLoadFailed;

  /// No description provided for @rcpTryAgain.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get rcpTryAgain;

  /// No description provided for @rcpFromStockTitle.
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات من خزينك'**
  String get rcpFromStockTitle;

  /// No description provided for @rcpForYouTitle.
  ///
  /// In ar, this message translates to:
  /// **'وصفات على ذوقك'**
  String get rcpForYouTitle;

  /// No description provided for @rcpRecipeCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} وصفة'**
  String rcpRecipeCount(int count);

  /// No description provided for @rcpEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'نبحث عن شيء آخر؟'**
  String get rcpEmptyTitle;

  /// No description provided for @rcpShowAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل الوصفات'**
  String get rcpShowAll;

  /// No description provided for @rcpShowMore.
  ///
  /// In ar, this message translates to:
  /// **'اعرض {count} أخرى'**
  String rcpShowMore(String count);

  /// No description provided for @appRetrySave.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الحفظ'**
  String get appRetrySave;

  /// No description provided for @appLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل بيانات البيت. بياناتك لم تُحذف.'**
  String get appLoadFailed;

  /// No description provided for @appTryAgain.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get appTryAgain;

  /// No description provided for @appBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get appBack;

  /// No description provided for @appViewAddStock.
  ///
  /// In ar, this message translates to:
  /// **'نزوّد الخير'**
  String get appViewAddStock;

  /// No description provided for @appViewRecipe.
  ///
  /// In ar, this message translates to:
  /// **'وصفة على قدرك'**
  String get appViewRecipe;

  /// No description provided for @appViewKitchen3d.
  ///
  /// In ar, this message translates to:
  /// **'مطبخي 3D'**
  String get appViewKitchen3d;

  /// No description provided for @appViewCooking.
  ///
  /// In ar, this message translates to:
  /// **'نطبخ معًا'**
  String get appViewCooking;

  /// No description provided for @appUnsaveRecipe.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحفظ'**
  String get appUnsaveRecipe;

  /// No description provided for @appSaveRecipe.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الوصفة'**
  String get appSaveRecipe;

  /// Header title on the Today tab (the brand name).
  ///
  /// In ar, this message translates to:
  /// **'سُفرة'**
  String get appHeaderToday;

  /// No description provided for @appTabRecipes.
  ///
  /// In ar, this message translates to:
  /// **'الوصفات'**
  String get appTabRecipes;

  /// No description provided for @appTabStock.
  ///
  /// In ar, this message translates to:
  /// **'الخزين'**
  String get appTabStock;

  /// No description provided for @appTabPlan.
  ///
  /// In ar, this message translates to:
  /// **'الخطة'**
  String get appTabPlan;

  /// No description provided for @appTabAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get appTabAccount;

  /// No description provided for @appTabSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get appTabSettings;

  /// No description provided for @appTabStyle.
  ///
  /// In ar, this message translates to:
  /// **'شكل المطبخ'**
  String get appTabStyle;

  /// No description provided for @appTabToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get appTabToday;

  /// No description provided for @appCommunity.
  ///
  /// In ar, this message translates to:
  /// **'المجتمع'**
  String get appCommunity;

  /// No description provided for @appMemoryStoreLabel.
  ///
  /// In ar, this message translates to:
  /// **'غير محفوظ (تجربة)'**
  String get appMemoryStoreLabel;

  /// Shown when the user has not typed a name.
  ///
  /// In ar, this message translates to:
  /// **'صاحب السفرة'**
  String get appDefaultName;

  /// Home name when the user has not typed one.
  ///
  /// In ar, this message translates to:
  /// **'بيت {name}'**
  String appDefaultHouse(String name);

  /// No description provided for @appMealFallback.
  ///
  /// In ar, this message translates to:
  /// **'وجبة'**
  String get appMealFallback;

  /// No description provided for @appSaveFull.
  ///
  /// In ar, this message translates to:
  /// **'امتلأت مساحة الحفظ في حسابك، فلم يُحفظ التعديل.'**
  String get appSaveFull;

  /// No description provided for @appSaveFailedOne.
  ///
  /// In ar, this message translates to:
  /// **'لم يُحفظ آخر تعديل. تحقق من الاتصال وأعد الحفظ قبل الخروج.'**
  String get appSaveFailedOne;

  /// No description provided for @appSaveFailedMany.
  ///
  /// In ar, this message translates to:
  /// **'تعديلات لم تُحفظ: {count}. تحقق من الاتصال وأعد الحفظ قبل الخروج.'**
  String appSaveFailedMany(String count);

  /// No description provided for @appShoppingListHeader.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الشراء من سفرة:'**
  String get appShoppingListHeader;

  /// No description provided for @appRanOutTitle.
  ///
  /// In ar, this message translates to:
  /// **'نفد من المطبخ'**
  String get appRanOutTitle;

  /// No description provided for @appRanOutBody.
  ///
  /// In ar, this message translates to:
  /// **'{items}. ضيفهم لقائمة الشراء.'**
  String appRanOutBody(String items);

  /// Separator between items in a list written as one line.
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get appListSeparator;

  /// No description provided for @appSessionOpenFailed.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن فتح بياناتك الآن. تحقق من الاتصال وحاول مرة أخرى.'**
  String get appSessionOpenFailed;

  /// No description provided for @appRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get appRetry;

  /// No description provided for @appSignOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get appSignOut;

  /// No description provided for @appEnterEmailFirst.
  ///
  /// In ar, this message translates to:
  /// **'اكتب البريد الإلكتروني الأول.'**
  String get appEnterEmailFirst;

  /// No description provided for @appResetSent.
  ///
  /// In ar, this message translates to:
  /// **'إذا كان البريد مسجّلًا، سيصلك رابط استعادة كلمة المرور.'**
  String get appResetSent;

  /// No description provided for @appAuthNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من اتصال الإنترنت وحاول مرة أخرى.'**
  String get appAuthNetwork;

  /// No description provided for @appAuthTooMany.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.'**
  String get appAuthTooMany;

  /// No description provided for @appAuthWeakPassword.
  ///
  /// In ar, this message translates to:
  /// **'اختر كلمة مرور أقوى.'**
  String get appAuthWeakPassword;

  /// No description provided for @appAuthEmailInUse.
  ///
  /// In ar, this message translates to:
  /// **'البريد مسجّل بالفعل. جرّب تسجيل الدخول.'**
  String get appAuthEmailInUse;

  /// No description provided for @appAuthInvalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'راجع كتابة البريد الإلكتروني.'**
  String get appAuthInvalidEmail;

  /// No description provided for @appAuthSignUpUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب غير متاح حاليًا. حاول لاحقًا.'**
  String get appAuthSignUpUnavailable;

  /// No description provided for @appAuthFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الدخول. راجع البريد وكلمة المرور أو استعد حسابك.'**
  String get appAuthFailed;

  /// No description provided for @appRequestFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إكمال الطلب. حاول مرة أخرى.'**
  String get appRequestFailed;

  /// No description provided for @appCreateAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حسابًا لسفرتك'**
  String get appCreateAccountTitle;

  /// No description provided for @appWelcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بك في سفرة'**
  String get appWelcome;

  /// No description provided for @appSignInSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مكونات بيتك واختياراتك محفوظة في حسابك.'**
  String get appSignInSubtitle;

  /// No description provided for @appEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get appEmailLabel;

  /// No description provided for @appEmailInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب بريدًا صحيحًا'**
  String get appEmailInvalid;

  /// No description provided for @appPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get appPasswordLabel;

  /// No description provided for @appPasswordShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور 6 أحرف على الأقل'**
  String get appPasswordShort;

  /// No description provided for @appWait.
  ///
  /// In ar, this message translates to:
  /// **'لحظة…'**
  String get appWait;

  /// No description provided for @appCreateAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get appCreateAccount;

  /// No description provided for @appSignIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get appSignIn;

  /// No description provided for @appHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'عندي حساب بالفعل'**
  String get appHaveAccount;

  /// No description provided for @appFirstTime.
  ///
  /// In ar, this message translates to:
  /// **'أول مرة؟ أنشئ حسابًا'**
  String get appFirstTime;

  /// No description provided for @appForgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور'**
  String get appForgotPassword;

  /// No description provided for @appSavedOnDevice.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ على الجهاز'**
  String get appSavedOnDevice;

  /// No description provided for @appSavedInAccount.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ في حسابك'**
  String get appSavedInAccount;

  /// No description provided for @appSavedInSharedKitchen.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ في المطبخ المشترك'**
  String get appSavedInSharedKitchen;

  /// No description provided for @appInviteNotFound.
  ///
  /// In ar, this message translates to:
  /// **'هذا الرمز غير موجود.'**
  String get appInviteNotFound;

  /// No description provided for @appInviteExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية هذا الرمز. اطلب رمزًا جديدًا.'**
  String get appInviteExpired;

  /// No description provided for @appChallengeCookPlannedTitle.
  ///
  /// In ar, this message translates to:
  /// **'اطبخ {goal} وجبات من خطتك'**
  String appChallengeCookPlannedTitle(String goal);

  /// No description provided for @appChallengeCookPlannedDetail.
  ///
  /// In ar, this message translates to:
  /// **'تُحسب كل وجبة مخططة طُبخت هذا الأسبوع.'**
  String get appChallengeCookPlannedDetail;

  /// No description provided for @appChallengeDifferentTitle.
  ///
  /// In ar, this message translates to:
  /// **'نوّع: {goal} أكلات مختلفة'**
  String appChallengeDifferentTitle(String goal);

  /// No description provided for @appChallengeDifferentDetail.
  ///
  /// In ar, this message translates to:
  /// **'تُحسب كل وصفة مختلفة طُبخت هذا الأسبوع مرة واحدة.'**
  String get appChallengeDifferentDetail;

  /// No description provided for @appChallengeNewTitle.
  ///
  /// In ar, this message translates to:
  /// **'جرّب وصفتين أول مرة'**
  String get appChallengeNewTitle;

  /// No description provided for @appChallengeNewDetail.
  ///
  /// In ar, this message translates to:
  /// **'وصفة لم تُطبخ من قبل في مطبخك.'**
  String get appChallengeNewDetail;

  /// No description provided for @appHouseMember.
  ///
  /// In ar, this message translates to:
  /// **'فرد من البيت'**
  String get appHouseMember;

  /// No description provided for @appChefCelebrate.
  ///
  /// In ar, this message translates to:
  /// **'شيف سفرة سعيد وجاهز للطبخ'**
  String get appChefCelebrate;

  /// No description provided for @appChefIdle.
  ///
  /// In ar, this message translates to:
  /// **'شيف سفرة، طماطماية مرحة بقبعة شيف'**
  String get appChefIdle;

  /// Amount shown for a recipe ingredient that has no measured quantity.
  ///
  /// In ar, this message translates to:
  /// **'حسب الرغبة'**
  String get dataToTaste;

  /// No description provided for @kitchen3dAlt.
  ///
  /// In ar, this message translates to:
  /// **'المطبخ ثلاثي الأبعاد'**
  String get kitchen3dAlt;

  /// No description provided for @librarySection.
  ///
  /// In ar, this message translates to:
  /// **'الوصفات على جهازك'**
  String get librarySection;

  /// No description provided for @libraryInfo.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الوصفات محفوظة على جهازك دائمًا. تُحفظ الوصفة كاملة عند فتحها أو حفظها، والمحفوظة تبقى في حسابك أيضًا وإن حُذفت من المكتبة. تصل الوصفات الجديدة تلقائيًا دون تحديث التطبيق.'**
  String get libraryInfo;

  /// No description provided for @libraryOnDevice.
  ///
  /// In ar, this message translates to:
  /// **'على الجهاز'**
  String get libraryOnDevice;

  /// No description provided for @librarySaved.
  ///
  /// In ar, this message translates to:
  /// **'محفوظة'**
  String get librarySaved;

  /// No description provided for @librarySize.
  ///
  /// In ar, this message translates to:
  /// **'المساحة'**
  String get librarySize;

  /// Storage the recipe library uses, in megabytes.
  ///
  /// In ar, this message translates to:
  /// **'{value} ميجابايت'**
  String librarySizeValue(String value);

  /// Date the recipe library on the device was published.
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث للمكتبة: {date}'**
  String libraryUpdated(String date);

  /// No description provided for @libraryUpdateNow.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الآن'**
  String get libraryUpdateNow;

  /// No description provided for @libraryUpdating.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحديث…'**
  String get libraryUpdating;

  /// No description provided for @libraryUpToDate.
  ///
  /// In ar, this message translates to:
  /// **'المكتبة محدّثة'**
  String get libraryUpToDate;

  /// No description provided for @libraryUpdateFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بالمكتبة'**
  String get libraryUpdateFailed;

  /// No description provided for @recipeNotOnDevice.
  ///
  /// In ar, this message translates to:
  /// **'هذه الوصفة غير محفوظة على جهازك. اتصل بالإنترنت ثم حاول مرة أخرى.'**
  String get recipeNotOnDevice;

  /// No description provided for @recipeRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get recipeRetry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
