// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'سفرة';

  @override
  String get lookSection => 'العرض واللغة';

  @override
  String get lookAppearance => 'المظهر';

  @override
  String get lookLight => 'فاتح';

  @override
  String get lookSystem => 'حسب الهاتف';

  @override
  String get lookDark => 'داكن';

  @override
  String get lookTextSize => 'حجم الخط';

  @override
  String get lookTextNormal => 'عادي';

  @override
  String get lookTextLarge => 'كبير';

  @override
  String get lookTextLarger => 'أكبر';

  @override
  String get lookGlyph => 'أ';

  @override
  String get lookColors => 'تمييز الألوان';

  @override
  String get lookColorsInfo => 'لمن يصعب عليه تمييز بعض الألوان: يغيّر ألوان التطبيق كله لتصبح أوضح، مثل «تصحيح الألوان» في إعدادات الهاتف.';

  @override
  String get lookMotion => 'تقليل الحركة';

  @override
  String get lookMotionInfo => 'انتقالات أهدأ دون ارتداد أو حركة في الخلفية.';

  @override
  String get lookLanguage => 'اللغة';

  @override
  String get lookLanguageArabic => 'العربية';

  @override
  String get lookLanguageEnglish => 'English';

  @override
  String get lookVisionNoneShort => 'عادي';

  @override
  String get lookVisionProtanShort => 'الأحمر';

  @override
  String get lookVisionDeutanShort => 'الأخضر';

  @override
  String get lookVisionTritanShort => 'الأزرق';

  @override
  String get lookVisionNone => 'دون تصحيح';

  @override
  String get lookVisionProtan => 'صعوبة تمييز الأحمر';

  @override
  String get lookVisionDeutan => 'صعوبة تمييز الأخضر';

  @override
  String get lookVisionTritan => 'صعوبة تمييز الأزرق';

  @override
  String get uiIncrease => 'زيادة العدد';

  @override
  String get uiDecrease => 'تقليل العدد';

  @override
  String get commTitle => 'مجتمع سفرة';

  @override
  String get commTagline => 'كلنا على سفرة واحدة';

  @override
  String get commKitchen => 'مطبخ البيت';

  @override
  String get commChallenge => 'تحدي الأسبوع';

  @override
  String get commPreviewNote => 'معاينة على الجهاز: ما تنشره هنا لا يصل لأحد، ويُحذف عند الإغلاق.';

  @override
  String get commPartHome => 'الرئيسية';

  @override
  String get commPartMine => 'وصفاتي';

  @override
  String get commPartPrices => 'أسعار منطقتي';

  @override
  String get commShareOwnRecipe => 'شارك وصفة من عندك';

  @override
  String get commRecipesLoadError => 'تعذّر جلب الوصفات. حاول مرة أخرى.';

  @override
  String get commMineEmptyWrite => 'اكتب وصفة من «وصفة من عندي»، ثم شاركها هنا.';

  @override
  String get commMineEmpty => 'لم تشارك وصفة بعد.';

  @override
  String get commNeedsAccount => 'هذا الجزء يحتاج إلى حساب. هذه النسخة محفوظة على الجهاز فقط.';

  @override
  String get commConnectionProblem => 'حدثت مشكلة في الاتصال. حاول مرة أخرى.';

  @override
  String get commNoInitial => '؟';

  @override
  String get commYourStory => 'قصتك';

  @override
  String get commChallengeNote => 'اطبخ وشارك';

  @override
  String get commKitchenNote => 'خزين واحد لأهل البيت';

  @override
  String get commYoutubeChefs => 'شيفات على يوتيوب';

  @override
  String get commFromSofraHomes => 'من بيوت سفرة';

  @override
  String get commShareRecipe => 'شارك وصفة';

  @override
  String get commFeedEmpty => 'لم يشارك أحد وصفة بعد. ابدأ أنت من «وصفة من عندي».';

  @override
  String get commOpenChannel => 'افتح القناة على يوتيوب';

  @override
  String get commShareFromYours => 'شارك وصفة من وصفاتك';

  @override
  String commSharedNotice(String name) {
    return 'شُوركت $name';
  }

  @override
  String get commShareFailed => 'تعذّرت المشاركة. حاول مرة أخرى.';

  @override
  String commFeedCounts(int ingredients, int steps) {
    return '$ingredients مكون · $steps خطوات';
  }

  @override
  String commServings(int count) {
    return '$count أفراد';
  }

  @override
  String get commStoryPrompt => 'ماذا طبخت اليوم؟';

  @override
  String get commStoryHint => 'اكتب قصتك';

  @override
  String get commStoryDishHint => 'اسم الأكلة (اختياري)';

  @override
  String get commStoryPost => 'انشر لمدة يوم';

  @override
  String commStoryHoursAgo(int hours) {
    return 'من $hours ساعة';
  }

  @override
  String get commStoryNow => 'الآن';

  @override
  String get commKitchenLoadError => 'تعذّر فتح بيانات المطبخ. حاول مرة أخرى.';

  @override
  String get commKitchenIntro => 'اجمع البيت كله على مطبخ واحد: المخزون نفسه، والخطة نفسها، وقائمة الشراء نفسها. ما في مطبخك الآن هو ما ستتم مشاركته.';

  @override
  String get commKitchenCreate => 'أنشئ مطبخًا مشتركًا';

  @override
  String get commHaveInvite => 'عندك كود دعوة؟';

  @override
  String get commCodeExample => 'مثلاً: K7PM2QXA';

  @override
  String get commKitchenJoin => 'ادخل المطبخ';

  @override
  String get commKitchenJoinNote => 'عند دخولك مطبخًا مشتركًا، يبقى مطبخك الشخصي محفوظًا وتعود إليه عند الخروج.';

  @override
  String get commSharedKitchen => 'المطبخ المشترك';

  @override
  String get commKitchenOwner => 'صاحب المطبخ';

  @override
  String get commInviteSend => 'أرسل هذا الرمز لأهل البيت (صالح لمدة أسبوع):';

  @override
  String get commInviteCreate => 'أنشئ رمز دعوة';

  @override
  String get commBackToMyKitchen => 'العودة إلى مطبخي الشخصي';

  @override
  String commByAuthor(String name) {
    return 'من $name';
  }

  @override
  String get commIngredients => 'المكونات';

  @override
  String get commMethod => 'الطريقة';

  @override
  String get commRatings => 'التقييمات';

  @override
  String get commNoRatings => 'لم يقيّمها أحد بعد.';

  @override
  String commRatingAverage(String average, String count) {
    return '$average من 5 ($count)';
  }

  @override
  String get commCommentHint => 'تعليقك (اختياري)';

  @override
  String get commSaveRating => 'احفظ تقييمي';

  @override
  String commChallengeCookPlanned(String goal) {
    return 'اطبخ $goal وجبات من خطتك';
  }

  @override
  String get commChallengeCookPlannedDetail => 'تُحسب كل وجبة مخططة طُبخت هذا الأسبوع.';

  @override
  String commChallengeDifferent(String goal) {
    return 'نوّع: $goal أكلات مختلفة';
  }

  @override
  String get commChallengeDifferentDetail => 'تُحسب كل وصفة مختلفة طُبخت هذا الأسبوع مرة واحدة.';

  @override
  String commChallengeNew(int goal) {
    String _temp0 = intl.Intl.pluralLogic(
      goal,
      locale: localeName,
      other: 'جرّب $goal وصفات أول مرة',
      two: 'جرّب وصفتين أول مرة',
    );
    return '$_temp0';
  }

  @override
  String get commChallengeNewDetail => 'وصفة لم تُطبخ من قبل في مطبخك.';

  @override
  String commChallengeProgress(String done, String goal) {
    return 'أنجزت $done من $goal';
  }

  @override
  String get commChallengeLog => 'سجّل تقدمي في اللوحة';

  @override
  String get commChallengeHomes => 'البيوت المشاركة';

  @override
  String get commBoardLoadError => 'تعذّر جلب اللوحة. حاول مرة أخرى.';

  @override
  String get commBoardEmpty => 'لم يسجّل أحد هذا الأسبوع بعد.';

  @override
  String get commLeaveTitle => 'الخروج من المطبخ المشترك؟';

  @override
  String get commLeaveBody => 'ستعود إلى مطبخك الشخصي ولن ترى تعديلات أهل البيت. للعودة تحتاج رمز دعوة جديدًا من صاحب المطبخ.';

  @override
  String get commCancel => 'إلغاء';

  @override
  String get commRetry => 'إعادة المحاولة';

  @override
  String get commDelete => 'حذف';

  @override
  String get commDeleteConfirm => 'هل تريد الحذف نهائيًا؟';

  @override
  String get commDeleteFailed => 'تعذّر الحذف. حاول مرة أخرى.';

  @override
  String get commDeleted => 'تم الحذف.';

  @override
  String get commStoryFailed => 'تعذّر نشر القصة.';

  @override
  String get commRatingFailed => 'تعذّر حفظ التقييم.';

  @override
  String get commChallengeFailed => 'تعذّر تسجيل التقدّم.';

  @override
  String get priceAreaSaveFailed => 'تعذّر حفظ المنطقة.';

  @override
  String get priceDeleteShared => 'حذف سعري المشارَك';

  @override
  String get commLeave => 'اخرج';

  @override
  String get detailOpenError => 'تعذّر فتح الوصفة. ارجع وحاول مرة أخرى.';

  @override
  String get detailPreparing => 'بنجهّز الطبخة…';

  @override
  String get detailCookNow => 'أطبخ الآن';

  @override
  String get detailCookNowNote => 'تُحفظ كوجبة لليوم لاستكمالها. لا خصم قبل التأكيد.';

  @override
  String get detailAddToPlan => 'أضيف للخطة';

  @override
  String detailPhotoCredit(String credit, String licence) {
    return 'الصورة: $credit · $licence';
  }

  @override
  String get detailServingsQuestion => 'نطبخ لكم شخصًا؟';

  @override
  String get detailServingsHint => 'تُضبط الكميات تلقائيًا';

  @override
  String get detailLogAs => 'أسجّل الطبخة كـ';

  @override
  String detailAllergyMatch(String matches) {
    return 'انتبه: $matches. المطابقة بالاسم بس، راجع المكونات والعبوات بنفسك.';
  }

  @override
  String detailAllergyMatchItem(String allergy, String lines) {
    return '«$allergy» في $lines';
  }

  @override
  String detailAllergyCheck(String allergies) {
    return 'راجع مكونات الوصفة والعبوات مع الحساسية المسجّلة: $allergies.';
  }

  @override
  String get detailListSeparator => '، ';

  @override
  String get detailGroupSeparator => '؛ ';

  @override
  String get detailIngredientsScaled => 'المكونات على قدركم';

  @override
  String get detailIngredientsSource => 'المكونات كما في المصدر';

  @override
  String get detailSteps => 'الخطوات';

  @override
  String get detailNoPricesNote => 'لا تظهر الأسعار والقيم الغذائية هنا حتى تُراجع من مصادرها. الكميات من المصدر.';

  @override
  String get detailToTaste => 'حسب الرغبة';

  @override
  String get detailYieldUnknown => 'لم يذكر المصدر عدد من تكفيهم هذه الوصفة';

  @override
  String get detailYieldAsk => 'لنضبط الكميات ونضعها على السفرة، أخبرنا كم فردًا تكفي الوصفة كلها تقريبًا. الوصفة الأصلية لن تتغير.';

  @override
  String detailYieldServes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تكفي $count فردًا',
      few: 'تكفي $count أفراد',
      two: 'تكفي فردين',
      one: 'تكفي فردًا واحدًا',
    );
    return '$_temp0';
  }

  @override
  String get servingsInfoLabel => 'كيف حُسب عدد الأفراد';

  @override
  String servingsInfoBasis(String amount, String ingredient, String norm) {
    return 'بناءً على $amount $ingredient، بمعدل $norm تقريبًا للفرد.';
  }

  @override
  String servingsInfoBasisMany(String list) {
    return 'بناءً على المكونات الأساسية معًا: $list.';
  }

  @override
  String get servingsInfoShared => 'يأخذ كل فرد جزءًا من كلٍّ منها.';

  @override
  String servingsInfoEstimated(String item, String weight) {
    return '$item (نحو $weight)';
  }

  @override
  String detailServingsScaled(int count, int people) {
    return 'الكميات معدّلة من $count إلى $people';
  }

  @override
  String get servingsInfoApply => 'تطبيق';

  @override
  String get servingsInfoLow => 'هذا تقدير تقريبي، فعدّله إن لم يكن مناسبًا.';

  @override
  String get servingsInfoAdjust => 'تعديل العدد';

  @override
  String get detailPlanned => 'الوجبة على السفرة، والمخزون لم يتغير';

  @override
  String detailWaysToMake(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طريقة لعملها',
      many: '$count طريقة لعملها',
      few: '$count طرق لعملها',
      two: 'طريقتان لعملها',
      one: 'طريقة واحدة لعملها',
    );
    return '$_temp0';
  }

  @override
  String get detailIngredients => 'المكونات';

  @override
  String get detailPronunciation => 'النطق';

  @override
  String get detailWaysOpenError => 'تعذّر فتح الطرق. ارجع وحاول مرة أخرى.';

  @override
  String get detailComparePickHint => 'اختر بلدًا من الشريط لترى الكميات والخطوات.';

  @override
  String get detailDefineConversion => 'حدد التحويل';

  @override
  String detailConversionQuestion(String from, String name, String to) {
    return '1 $from من $name = كم $to؟';
  }

  @override
  String get detailConversionHint => 'اكتب القياس من مطبخك. سيُحفظ لهذا المكوّن فقط.';

  @override
  String get detailEnterPositive => 'اكتب رقمًا أكبر من صفر';

  @override
  String get detailCancel => 'إلغاء';

  @override
  String get detailSave => 'حفظ';

  @override
  String detailConversionSaved(String from, String name, String factor, String to) {
    return 'حُفظ: 1 $from $name = $factor $to';
  }

  @override
  String get detailInStock => 'موجود عندك';

  @override
  String detailMissing(String amount, String unit) {
    return 'ناقص $amount $unit';
  }

  @override
  String get detailUnitMismatch => 'الوحدة مختلفة عن المخزون';

  @override
  String get detailUnmeasured => 'دون مقدار';

  @override
  String get detailOptional => 'اختياري';

  @override
  String get detailPlanWhen => 'متى نضعها على السفرة؟';

  @override
  String get detailToday => 'اليوم';

  @override
  String get detailTomorrow => 'غدًا';

  @override
  String get detailDayAfterTomorrow => 'بعد غد';

  @override
  String get detailDone => 'تم';

  @override
  String get detailCookOpenError => 'تعذّر فتح الوصفة.';

  @override
  String get detailFinishCooking => 'انتهى الطبخ · راجع الخصم';

  @override
  String get detailNoSteps => 'لا توجد خطوات مكتوبة لهذه الوصفة في المصدر.';

  @override
  String get detailNextStep => 'الخطوة التالية';

  @override
  String detailStepOf(String current, String total) {
    return '$current من $total';
  }

  @override
  String detailAboutMinutes(String minutes) {
    return 'حوالي $minutes دقيقة';
  }

  @override
  String get stepTimerStart => 'ابدأ المؤقت';

  @override
  String get stepTimerPause => 'إيقاف مؤقت';

  @override
  String get stepTimerReset => 'إعادة ضبط المؤقت';

  @override
  String get stepTimerDoneTitle => 'انتهى المؤقت';

  @override
  String stepTimerDone(String step) {
    return 'انتهى وقت الخطوة $step';
  }

  @override
  String get detailPreviousStep => 'الخطوة السابقة';

  @override
  String get detailEnjoy => 'بالهنا والشفا!';

  @override
  String detailCookedNote(String name) {
    return 'طُبخت $name، وخُصم ما أكدته من المخزون.';
  }

  @override
  String get detailShowKitchen => 'اعرض ما تبقى في مطبخك';

  @override
  String detailServings(String amount) {
    return '$amount حصة';
  }

  @override
  String get detailOneServing => '1 حصة';

  @override
  String detailLeftoversSaved(String servings) {
    return 'وضعنا $servings في الثلاجة، وستجدها في الميكروويف عندما تريد تسخينها.';
  }

  @override
  String get detailAnyLeftovers => 'هل تبقّى أكل؟';

  @override
  String get detailLeftoversHint => 'سجّله وسنضعه في الثلاجة لتسخّنه لاحقًا.';

  @override
  String get detailRemindAfter => 'ذكّرني بها بعد';

  @override
  String get detailRemindNone => 'دون';

  @override
  String detailRemindDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أيام',
      one: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String get detailPutInFridge => 'ضعه في الثلاجة';

  @override
  String detailHaveOf(String have, String total, String unit) {
    return 'عندك $have من $total $unit';
  }

  @override
  String detailUsingStock(String name, String stock) {
    return '$name · سنستخدم $stock';
  }

  @override
  String get detailBoughtRest => 'اشتريت الباقي';

  @override
  String get detailCookedLess => 'طبخت بأقل';

  @override
  String get detailBeforeDeduct => 'قبل الخصم من المخزون';

  @override
  String get detailWillDeduct => 'سيُخصم';

  @override
  String get detailWillDeductNote => 'موجود عندك بنفس الوحدة';

  @override
  String get detailPartial => 'عندك جزء فقط';

  @override
  String get detailPartialNote => 'هل اشتريت الباقي، أم طبخت بما عندك؟ في الحالتين يُخصم ما عندك.';

  @override
  String get detailNotDeducted => 'لن يُخصم';

  @override
  String get detailNotDeductedNote => 'ناقص أو مسجّل بوحدة مختلفة. ستبقى التكلفة غير معروفة.';

  @override
  String get detailUnmeasuredGroup => 'دون مقدار في الوصفة';

  @override
  String get detailUnmeasuredNote => 'مثل «حسب الرغبة»، لن يُخصم';

  @override
  String get detailConfirm => 'تأكيد';

  @override
  String get detailNotYet => 'ليس بعد';

  @override
  String get kitOpenKitchen3d => 'مطبخي 3D';

  @override
  String get kitShopping => 'المشتريات';

  @override
  String get kitLeftoversTitle => 'بواقي الأكل';

  @override
  String get kitLeftoversEmpty => 'لا توجد بواقي مسجلة.';

  @override
  String get kitLeftovers => 'البواقي';

  @override
  String get kitAddIngredientTitle => 'أضف مكوّنًا';

  @override
  String get kitAddIngredientDetail => 'ابحث واختر';

  @override
  String get kitReceiptTitle => 'فاتورة أو قائمة';

  @override
  String get kitReceiptDetail => 'صورة أو كتابة';

  @override
  String get kitAll => 'الكل';

  @override
  String kitAllCount(String count) {
    return 'الكل $count';
  }

  @override
  String get kitGettingToKnow => 'ما زلنا نتعرف على مطبخك';

  @override
  String get kitShelfEmpty => 'هذا الرف فارغ';

  @override
  String get kitEmptyHint => 'أضف بعض المكونات كبداية. لا نحتاج إلى جرد كامل للبدء.';

  @override
  String get kitTrySample => 'جرّب بمكونات جاهزة';

  @override
  String get kitSampleAdded => 'أُضيفت مكونات تجريبية إلى مطبخك';

  @override
  String get kitDeductNote => 'تُخصم الكميات بعد تأكيد الطبخ.';

  @override
  String get kitQuantityUnknown => 'كمية غير محددة';

  @override
  String kitEditItem(String name) {
    return 'تعديل $name';
  }

  @override
  String kitQuantityOf(String name) {
    return 'كمية $name';
  }

  @override
  String get kitQuantityInvalid => 'اكتب عددًا صحيحًا يساوي 0 أو أكثر';

  @override
  String kitQuantityLabel(String unit) {
    return 'الكمية ($unit)';
  }

  @override
  String get kitQuantityHelper => 'اكتب 0 إذا نفد';

  @override
  String get kitCancel => 'إلغاء';

  @override
  String get kitSave => 'حفظ';

  @override
  String kitQuantityUpdated(String name) {
    return 'حُدّثت كمية $name';
  }

  @override
  String get kitAddStockDone => 'تم، اعرض مطبخي';

  @override
  String get kitWhatDoYouHave => 'ماذا يوجد عندك؟';

  @override
  String get kitAddStockHint => 'اضغط + لإضافة سريعة، أو اضغط على المكوّن لكتابة الكمية والوحدة.';

  @override
  String get kitSearchIngredient => 'ابحث عن مكوّن';

  @override
  String get kitScanBarcode => 'امسح باركود';

  @override
  String get kitIngredientNotFound => 'المكوّن غير موجود في القائمة. جرّب اسمًا آخر.';

  @override
  String kitAddItem(String name) {
    return 'إضافة $name';
  }

  @override
  String kitAddedToKitchen(String name) {
    return 'أُضيف $name إلى مطبخك';
  }

  @override
  String kitYouHave(String amounts) {
    return 'عندك $amounts';
  }

  @override
  String get kitEnterAmount => 'اكتب كمية أكبر من صفر';

  @override
  String get kitEnterWeight => 'اكتب وزنًا أكبر من صفر أو اتركها فارغة';

  @override
  String get kitAmount => 'الكمية';

  @override
  String get kitUnit => 'الوحدة';

  @override
  String kitPieceGrams(String unit) {
    return 'كام جرام في الـ$unit؟ (اختياري)';
  }

  @override
  String kitPieceMl(String unit) {
    return 'كام مل في الـ$unit؟ (اختياري)';
  }

  @override
  String get kitPieceHelper => 'من ميزانك أو المكتوب على العبوة. يفيد في الوصفات.';

  @override
  String get kitGramsShort => 'جم';

  @override
  String get kitMlShort => 'مل';

  @override
  String get kitPlace => 'مكانه';

  @override
  String get kitAddToKitchen => 'أضفه إلى مطبخي';

  @override
  String kitServing(String count) {
    return '$count حصة';
  }

  @override
  String kitServings(String count) {
    return '$count حصة';
  }

  @override
  String get kitLeftoverDue => 'حان موعدها';

  @override
  String get kitHowManyWarmed => 'كم حصة سخّنت؟';

  @override
  String kitEatOf(String eaten, String total) {
    return '$eaten من $total';
  }

  @override
  String get kitNotYet => 'ليس بعد';

  @override
  String get kitWarmedAndAte => 'سخّنت وأكلت';

  @override
  String get kitEmptySoFar => 'فارغ حتى الآن.';

  @override
  String get kitSearchSomething => 'ابحث عن شيء';

  @override
  String get kitByKind => 'حسب النوع';

  @override
  String get kitLastAdded => 'آخر ما وُضع';

  @override
  String kitItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شيء',
      few: '$count أشياء',
      two: 'شيئان',
      one: 'شيء واحد',
      zero: 'فارغ',
    );
    return '$_temp0';
  }

  @override
  String get kitSearch => 'بحث';

  @override
  String get kitAdd => 'إضافة';

  @override
  String get kitAllStock => 'كل المخزون';

  @override
  String get kitClose => 'إغلاق';

  @override
  String get kitNothingByName => 'لا يوجد شيء بهذا الاسم هنا.';

  @override
  String kitItemSemantics(String label, String amount) {
    return '$label، $amount';
  }

  @override
  String get kitShoppingError => 'تعذّر تجهيز القائمة. حاول مرة أخرى.';

  @override
  String get kitShoppingTitle => 'قائمة الشراء للأسبوع';

  @override
  String get kitShareList => 'أرسلها (واتساب وغيره)';

  @override
  String get kitNothingMissing => 'لا ينقصك شيء للأكلات المخططة.';

  @override
  String kitAboutTotal(String amount, String currency) {
    return 'حوالي $amount $currency بأسعارك.';
  }

  @override
  String kitKnownSubtotal(String amount, String currency) {
    return 'المعروف سعره: $amount $currency، وبعض الأشياء دون سعر.';
  }

  @override
  String get kitPaidHint => 'كم دفعت؟ (اختياري)';

  @override
  String kitUnresolvedLines(int count) {
    return 'يوجد $count سطر دون كمية (مثل «حسب الرغبة») خارج القائمة.';
  }

  @override
  String kitUnconvertibleStock(String names) {
    return 'وحدة المخزون لـ $names لا تتحول إلى وحدة الوصفة؛ راجعها في المخزون.';
  }

  @override
  String get kitListSeparator => '، ';

  @override
  String get kitMarkBought => 'علّم ما اشتريته';

  @override
  String get kitPutBoughtAway => 'ضع ما اشتريته في المطبخ';

  @override
  String get kitPreviewNoYield => 'مكونات عندك؛ حدّد الحصص للتحقق من الكميات';

  @override
  String get kitPreviewReady => 'جاهزة بالموجود';

  @override
  String get kitPreviewNotEnough => 'لا توجد مقادير كافية للحكم';

  @override
  String kitPreviewMissingUnknown(int missing, int unknown) {
    return 'ناقص $missing · $unknown مقادير غير محسومة';
  }

  @override
  String kitPreviewUnknown(int unknown) {
    return '$unknown مقادير غير محسومة';
  }

  @override
  String kitPreviewMissing(int missing) {
    return 'ناقص $missing من المكونات';
  }

  @override
  String get mineNewRecipe => 'وصفة من عندي';

  @override
  String mineIngredientsSteps(int ingredients, int steps) {
    return '$ingredients مكونات · $steps خطوات';
  }

  @override
  String get mineTomorrow => 'غدًا';

  @override
  String get minePutOnTable => 'ضعها على السفرة';

  @override
  String get mineAddedToTable => 'أُضيفت إلى السفرة.';

  @override
  String get mineSaveFailed => 'لم تُحفظ الوصفة. حاول مرة أخرى.';

  @override
  String get mineSaved => 'حُفظت الوصفة في وصفاتك.';

  @override
  String get mineCuisineNeeded => 'اكتب مطبخًا محددًا للوصفة، مثل «مصري».';

  @override
  String get mineSaving => 'جارٍ الحفظ…';

  @override
  String get mineSave => 'احفظ الوصفة';

  @override
  String get mineDishName => 'اسم الأكلة';

  @override
  String get mineShortDescription => 'وصف قصير';

  @override
  String get mineCuisine => 'المطبخ';

  @override
  String get minePrepMinutes => 'التحضير (دقيقة)';

  @override
  String get mineCookMinutes => 'الطبخ (دقيقة)';

  @override
  String get mineServesHowMany => 'تكفي كم فردًا؟';

  @override
  String get mineIngredients => 'المكونات';

  @override
  String get mineAddIngredient => '+ مكوّن';

  @override
  String get mineToTaste => 'حسب الرغبة';

  @override
  String get mineWithoutAmount => 'دون كمية';

  @override
  String get mineWithAmount => 'بكمية';

  @override
  String get mineRemove => 'احذف';

  @override
  String get mineSteps => 'الخطوات';

  @override
  String get mineAddStep => '+ خطوة';

  @override
  String get mineStepHint => 'ماذا ستفعل';

  @override
  String get mineMinutesHint => 'دقيقة';

  @override
  String get mineNutritionUnknown => 'لن تُحسب القيم الغذائية لهذه الوصفة حتى تُربط مكوناتها بمصدر.';

  @override
  String get mineSearchIngredient => 'ابحث عن مكوّن';

  @override
  String get mineRecipeBookTitle => 'كتاب الوصفات';

  @override
  String mineWays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طريقة',
      few: '$count طرق',
      zero: '$count طرق',
      two: 'طريقتان',
      one: 'طريقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String mineCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بلدًا',
      few: '$count بلاد',
      zero: '$count بلاد',
      two: 'بلدان',
      one: 'بلد واحد',
    );
    return '$_temp0';
  }

  @override
  String mineDishTimeRange(String from, String to) {
    return '$from–$to دقيقة';
  }

  @override
  String get onbCountry => 'البلد';

  @override
  String get onbCountryEgypt => 'مصر · جنيه مصري';

  @override
  String get onbCountrySaudi => 'السعودية · ريال سعودي';

  @override
  String get onbEgypt => 'مصر';

  @override
  String get onbSaudi => 'السعودية';

  @override
  String get onbBack => 'رجوع';

  @override
  String get onbSkip => 'تخطي';

  @override
  String get onbStart => 'ابدأ';

  @override
  String get onbOpenSofra => 'افتح سفرتي';

  @override
  String get onbContinue => 'متابعة';

  @override
  String get onbWelcomeTitle => 'كل ما في مطبخك\nيصنع أكلة طيبة';

  @override
  String get onbNameTitle => 'ما اسمك؟';

  @override
  String get onbNameHint => 'مثلًا: مريم';

  @override
  String get onbPeopleTitle => 'لكم شخصًا تطبخ؟';

  @override
  String get onbYourMeals => 'وجباتك';

  @override
  String get onbCuisinesTitle => 'ما المطابخ التي تحبها؟';

  @override
  String get onbCuisines => 'المطابخ';

  @override
  String get onbQuickFirst => 'السريعة أولًا';

  @override
  String get onbHealthTitle => 'نراعي صحتك';

  @override
  String get onbHealthConditions => 'حالتك الصحية';

  @override
  String get onbHealthNote => 'تُحفظ في ملفك فقط، ولا تغني عن طبيبك.';

  @override
  String get onbAvoidFoods => 'أطعمة تتجنبها';

  @override
  String get onbAvoidNote => 'ننبهك إذا ظهرت في وصفة. راجع العبوات بنفسك.';

  @override
  String get onbHealthBloodPressure => 'ضغط الدم';

  @override
  String get onbHealthCholesterol => 'الكوليسترول';

  @override
  String get onbHealthKidneys => 'الكلى';

  @override
  String onbHello(String name) {
    return 'أهلًا يا $name';
  }

  @override
  String get onbReady => 'سفرتك جاهزة';

  @override
  String get onbStatPeople => 'أشخاص';

  @override
  String get onbStatMeals => 'وجبات';

  @override
  String get onbStatCuisines => 'مطابخ';

  @override
  String get onbStatCares => 'للانتباه';

  @override
  String onbStepOf(String step, String total) {
    return 'الخطوة $step من $total';
  }

  @override
  String get onbMore => 'المزيد';

  @override
  String onbMoreSelected(String count) {
    return 'المزيد، $count مختارة';
  }

  @override
  String onbAddCustom(String name) {
    return 'إضافة «$name»';
  }

  @override
  String get onbSearchOrType => 'ابحث أو اكتب اسمًا';

  @override
  String get onbSearch => 'ابحث';

  @override
  String get onbDone => 'تم';

  @override
  String get onbZoneFridge => 'الثلاجة';

  @override
  String get onbZoneFreezer => 'الفريزر';

  @override
  String get onbZonePantry => 'الدولاب';

  @override
  String onbCountOne(String thing) {
    return '$thing واحدة';
  }

  @override
  String onbMinutes(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get onbTimeUnknown => 'الوقت غير محدد';

  @override
  String get planSaturday => 'السبت';

  @override
  String get planSunday => 'الأحد';

  @override
  String get planMonday => 'الاثنين';

  @override
  String get planTuesday => 'الثلاثاء';

  @override
  String get planWednesday => 'الأربع';

  @override
  String get planThursday => 'الخميس';

  @override
  String get planFriday => 'الجمعة';

  @override
  String get planToday => 'اليوم';

  @override
  String get planTomorrow => 'غدًا';

  @override
  String get planMonthTitle => 'خطة الشهر';

  @override
  String get planMonthCalcError => 'تعذّر حساب هذه الخطة. راجع الأكلات وحاول مرة أخرى.';

  @override
  String get planConflictTitle => 'توجد أيام عليها أكل';

  @override
  String planConflictBody(int count) {
    return 'توجد $count وجبة مخططة في الأيام نفسها. ماذا نفعل بها؟';
  }

  @override
  String get planNotYet => 'ليس بعد';

  @override
  String get planReplace => 'استبدلها';

  @override
  String get planKeepExisting => 'أبقِ الموجود';

  @override
  String get planMonthAdded => 'أُضيفت الخطة إلى السفرة.';

  @override
  String get planMonthNotSaved => 'لم تُحفظ الخطة. احسبها مرة أخرى.';

  @override
  String get planPutOnTable => 'ضع الخطة على السفرة';

  @override
  String get planCalculating => 'جارٍ الحساب…';

  @override
  String get planCalculateMonth => 'احسب الشهر';

  @override
  String get planThisMonth => 'هذا الشهر';

  @override
  String get planNextMonth => 'الشهر القادم';

  @override
  String get planMonthBudget => 'ميزانية الأكل للشهر';

  @override
  String get planMealsToPlan => 'الوجبات التي سنخطط لها';

  @override
  String get planWeekMenu => 'منيو الأسبوع';

  @override
  String get planFillEmptyDays => 'أكمل الأيام الفارغة';

  @override
  String get planWeekMenuHint => 'يتكرر هذا الأسبوع طوال الشهر. يمكنك وضع أكلتين في الخانة نفسها، ونختار الأوفر.';

  @override
  String get planOmitUnmeasured => 'استبعد الأشياء التي ليس لها كمية من الحساب';

  @override
  String get planOmitUnmeasuredHint => 'مثل «ملح حسب الرغبة». إذا أوقفتها، ستبقى التكلفة غير معروفة.';

  @override
  String get planPick => '+ اختر';

  @override
  String planOrAlternative(String name) {
    return 'أو $name';
  }

  @override
  String get planSearchMeal => 'ابحث عن أكلة';

  @override
  String planMonthFits(String cost, String left) {
    return 'يكلّفك هذا الشهر شراء نحو $cost، ويتبقى من الميزانية $left.';
  }

  @override
  String planMonthOver(String over) {
    return 'أوفر اختيار يتجاوز الميزانية بـ $over. جرّب أكلات أوفر أو أضف بديلًا في بعض الخانات.';
  }

  @override
  String planMonthBestFits(String cost, String left) {
    return 'أوفر خطة وجدناها تكلّفك شراء نحو $cost، ويتبقى من الميزانية $left.';
  }

  @override
  String get planMonthUnknown => 'التكلفة الكاملة غير معروفة بعد.';

  @override
  String get planRecordPrices => 'سجّل هذه الأسعار';

  @override
  String get planRecordPricesHint => 'بسعرك أنت، من آخر مرة اشتريت. لا نخمّن الأسعار.';

  @override
  String get planUnresolvedUnits => 'بعض المكونات مسجّلة بوحدة لا تتحول إلى وحدة الوصفة. حدد التحويل من صفحة المخزون.';

  @override
  String planTruncated(int count) {
    return 'جرّبنا $count توليفة فقط من البدائل؛ قد توجد أوفر منها.';
  }

  @override
  String planUncounted(String items) {
    return 'غير محسوب: $items.';
  }

  @override
  String get planListSeparator => '، ';

  @override
  String get planSavePrice => 'حفظ السعر';

  @override
  String get planAddHereEmpty => 'أضف ما عندك هنا، وسنقترح ما تطبخه منه.';

  @override
  String get planLeftovers => 'بواقي الأكل';

  @override
  String get planLeftoversEmpty => 'لا توجد بواقٍ مسجّلة. عندما تطبخ ويتبقى شيء، ستجده هنا لتسخينه.';

  @override
  String get planMyStock => 'مخزون مطبخي';

  @override
  String get planGoodMorning => 'صباح الخير';

  @override
  String get planGoodDay => 'نهارك سعيد';

  @override
  String get planGoodEvening => 'مساء الخير';

  @override
  String get planKitchenStyle => 'شكل المطبخ';

  @override
  String get planSettings => 'الإعدادات';

  @override
  String planWhen(String slot, String day) {
    return '$slot · $day';
  }

  @override
  String get planStock => 'المخزون';

  @override
  String planLeftoversDue(String count) {
    return 'بواقٍ حان موعدها: $count';
  }

  @override
  String get planWhatToCookToday => 'ماذا نطبخ اليوم؟';

  @override
  String get planPickRecipeHint => 'اختر وصفة، ونعرض لك الناقص من مطبخك قبل البدء.';

  @override
  String get planPickRecipe => 'اختر وصفة';

  @override
  String planNextOnTable(String when) {
    return 'التالي على السفرة · $when';
  }

  @override
  String get planStartCooking => 'ابدأ الطبخ';

  @override
  String get planTableEmpty => 'السفرة فارغة';

  @override
  String get planTableEmptyHint => 'افتح كتاب الوصفات واختر أكلة لتظهر هنا.';

  @override
  String get planRecipeBook => 'كتاب الوصفات';

  @override
  String planOnTable(String day) {
    return 'على سفرة $day';
  }

  @override
  String get planShoppingList => 'قائمة الشراء';

  @override
  String get planUpcomingMeals => 'الأكلات القادمة';

  @override
  String get planAllPlans => 'كل الخطط';

  @override
  String get planNoMealsPlanned => 'لا توجد أكلات مخططة. اختر من كتاب الوصفات.';

  @override
  String get planWelcome => 'أهلًا بيك في سفرة';

  @override
  String planWelcomeName(String name) {
    return 'أهلًا يا $name';
  }

  @override
  String get planCookFromStockQuestion => 'نُعدّ أكلة طيبة مما لديك';

  @override
  String get planWhatCanICook => 'ماذا أطبخ مما لدي؟';

  @override
  String get planWhatCanICookHint => 'اقتراحات من خزينك، مع توضيح الكميات والناقص. لا نخصم أي شيء قبل تأكيد الطبخ.';

  @override
  String get planDiscoverFromStock => 'اكتشف من الموجود';

  @override
  String get planExploreAll => 'أو استكشف كل الوصفات';

  @override
  String planPantryCount(int count) {
    return 'الخزين · $count مكونات';
  }

  @override
  String get planArrangeMeals => 'رتّب وجباتك';

  @override
  String planLeftoversReminder(int count) {
    return 'عندك $count بواقي عليها تذكير';
  }

  @override
  String get planLeftoversNone => 'لا توجد بواقي مسجلة.';

  @override
  String get planSeeThem => 'شوفها';

  @override
  String get planTodayMeals => 'وجبات اليوم';

  @override
  String get planNoMealToday => 'لا توجد وجبة لليوم بعد.';

  @override
  String get planOpenPlan => 'افتح الخطة';

  @override
  String get planMonthAndBudget => 'خطة الشهر والميزانية';

  @override
  String get planShoppingItems => 'قائمة المشتريات';

  @override
  String get planTableWorthIt => 'سفرة تستحق اللمّة';

  @override
  String get planPickMealHint => 'اختر أكلة، وسنعرض الناقص قبل البدء.';

  @override
  String get planPickDishForTable => 'اختر طبخة للسفرة';

  @override
  String get planComingDays => 'السفرة في الأيام القادمة';

  @override
  String get planNoDeductNote => 'اختيار الوجبة لا يخصم من المخزون. يتم الخصم بعد تأكيد انتهاء الطبخ.';

  @override
  String get planMealLoadError => 'تعذّر تحميل وصفة هذه الوجبة.';

  @override
  String planSlotServings(String slot, int servings) {
    return '$slot · $servings أفراد';
  }

  @override
  String get planCooked => 'طُبخت';

  @override
  String planInStock(String count) {
    return '$count متوفر';
  }

  @override
  String planMissingCount(String count) {
    return 'ناقص $count';
  }

  @override
  String planOtherUnit(String count) {
    return '$count بوحدة مختلفة';
  }

  @override
  String planNoAmount(String count) {
    return '$count دون مقدار';
  }

  @override
  String get planBoughtMissing => 'اشتريت الناقص · أضفه للمخزون';

  @override
  String get planMissingAdded => 'أُضيف الناقص إلى المخزون بالكمية المطلوبة';

  @override
  String get planRemoveMeal => 'احذف الوجبة من السفرة';

  @override
  String planPerPortion(String kcal) {
    return 'للفرد: $kcal سعر';
  }

  @override
  String planNutrient(String label, String grams) {
    return ' · $label $grams جم';
  }

  @override
  String get planProtein => 'بروتين';

  @override
  String get planCarbs => 'كربوهيدرات';

  @override
  String get planFat => 'دهون';

  @override
  String get priceGroupVegetables => 'خضار';

  @override
  String get priceGroupFruit => 'فاكهة';

  @override
  String get priceGroupProtein => 'لحوم ودواجن وأسماك';

  @override
  String get priceGroupDairy => 'ألبان وبيض';

  @override
  String get priceGroupGrains => 'أرز وحبوب';

  @override
  String get priceGroupLegumes => 'بقوليات';

  @override
  String get priceGroupBread => 'خبز ومخبوزات';

  @override
  String get priceGroupOils => 'زيوت وسمن';

  @override
  String get priceGroupSpices => 'توابل وبهارات';

  @override
  String get priceGroupSauces => 'صوصات ومعلبات';

  @override
  String get priceGroupNuts => 'مكسرات';

  @override
  String get priceGroupDrinks => 'مشروبات';

  @override
  String get priceGroupOther => 'أخرى';

  @override
  String get priceLocationOff => 'خدمة الموقع مغلقة. اختر منطقتك من الخريطة أو البحث.';

  @override
  String get priceLocationDenied => 'لم يُسمح بالموقع. اختر منطقتك من الخريطة أو البحث.';

  @override
  String get priceNoAreaNearby => 'لا نعرف منطقة قريبة من موقعك. اختر من الخريطة.';

  @override
  String get priceLocateFailed => 'تعذّر تحديد موقعك. اختر منطقتك من الخريطة أو البحث.';

  @override
  String priceAreaNowYours(String area) {
    return 'منطقتك الآن: $area';
  }

  @override
  String get priceSearchArea => 'ابحث عن منطقة أو مدينة';

  @override
  String get priceClear => 'مسح';

  @override
  String get priceNoResults => 'لا نتائج';

  @override
  String get priceChooseArea => 'اختر منطقتك';

  @override
  String get priceMakeMyArea => 'اجعلها منطقتي';

  @override
  String get priceAreaInfo => 'سعر المنطقة هو ما دفعه الناس فيها في آخر 60 يومًا، ويظهر فقط عندما يشاركه بيتان أو أكثر.';

  @override
  String get priceAreaFetchFailed => 'تعذّر جلب أسعار المنطقة.';

  @override
  String get priceRetry => 'إعادة المحاولة';

  @override
  String get priceNoAreaHere => 'لا نعرف منطقة هنا. جرّب البحث.';

  @override
  String get priceMyLocation => 'موقعي';

  @override
  String priceKnownInArea(String count) {
    return '$count بسعر المنطقة';
  }

  @override
  String get priceAreaColumn => 'سعر المنطقة';

  @override
  String get priceYoursColumn => 'سعرك';

  @override
  String get priceNoAreaPrice => 'لا يوجد سعر للمنطقة';

  @override
  String get priceAreaTapToUse => 'سعر المنطقة، اضغط لتجعله سعرك';

  @override
  String get priceAddYours => 'أضف سعرك';

  @override
  String get priceYoursTapToEdit => 'سعرك، اضغط لتعديله';

  @override
  String get priceSaveFailed => 'تعذّر حفظ السعر. حاول مرة أخرى.';

  @override
  String get priceSaved => 'حُفظ سعرك';

  @override
  String get priceSavedShared => 'حُفظ سعرك وشاركته مع منطقتك';

  @override
  String get priceSavedShareFailed => 'حُفظ سعرك، وتعذّرت مشاركته.';

  @override
  String get priceHint => 'السعر';

  @override
  String get priceInvalid => 'اكتب سعرًا أكبر من صفر';

  @override
  String priceShareWith(String area) {
    return 'شاركه مع $area';
  }

  @override
  String get priceCancel => 'إلغاء';

  @override
  String get priceSave => 'حفظ';

  @override
  String get priceCurrencyEgp => 'ج.م';

  @override
  String get priceCurrencySar => 'ر.س';

  @override
  String get priceToday => 'اليوم';

  @override
  String get priceFridge => 'الثلاجة';

  @override
  String get profCountryEgypt => 'مصر';

  @override
  String get profCountrySaudi => 'السعودية';

  @override
  String get profStatPeople => 'أفراد';

  @override
  String get profStatMealsDaily => 'وجبات يوميًا';

  @override
  String get profStatSaved => 'محفوظة';

  @override
  String get profHousehold => 'أهل البيت';

  @override
  String get profHouseName => 'اسم البيت';

  @override
  String profHouseHint(String name) {
    return 'بيت $name';
  }

  @override
  String get profYourName => 'اسمك';

  @override
  String get profCountry => 'البلد';

  @override
  String get profArea => 'المنطقة';

  @override
  String get profAddArea => 'أضف منطقتك';

  @override
  String get profTableSize => 'أفراد السفرة';

  @override
  String get profTaste => 'ذوقك في الأكل';

  @override
  String get profCuisines => 'المطابخ';

  @override
  String get profAllCuisines => 'كل المطابخ';

  @override
  String get profMeals => 'الوجبات';

  @override
  String get profNoMeal => 'لم تختر وجبة';

  @override
  String get profQuickFirst => 'الوصفات السريعة أولًا';

  @override
  String get profHealth => 'الصحة';

  @override
  String get profAllergies => 'حساسية الأكل';

  @override
  String get profNoAllergies => 'لا توجد حساسية';

  @override
  String get profAllergiesInfo => 'تظهر كتنبيه بالاسم فقط، ويجب أن تراجع المكونات بنفسك.';

  @override
  String get profConditions => 'حالات صحية';

  @override
  String get profNoConditions => 'لا توجد حالات';

  @override
  String get profConditionsInfo => 'للتذكير فقط؛ لا يغيّر التطبيق الوصفات ولا يقدّم نصيحة طبية.';

  @override
  String get profCancel => 'إلغاء';

  @override
  String get profSave => 'حفظ';

  @override
  String profRemove(String label) {
    return 'إزالة $label';
  }

  @override
  String get profAdd => 'أضف';

  @override
  String get profCountryCurrency => 'البلد والعملة';

  @override
  String get profReminders => 'التذكيرات';

  @override
  String get profSaving => 'جاري حفظ التغييرات…';

  @override
  String get profUnsaved => 'توجد تغييرات لم تُحفظ';

  @override
  String get profSignOut => 'تسجيل الخروج';

  @override
  String get profFooter => 'صُنع بحب للبيوت';

  @override
  String get profMyAccount => 'حسابي';

  @override
  String get profAccountLine => 'حسابك وتفضيلات بيتك';

  @override
  String get profAm => 'ص';

  @override
  String get profPm => 'م';

  @override
  String get profMealTimesIntro => 'موعد كل وجبة عندك، لنذكّرك قبلها.';

  @override
  String get profNoReminder => 'دون تذكير';

  @override
  String get profClearReminder => 'احذف التذكير';

  @override
  String profMealTimeOf(String meal) {
    return 'موعد $meal';
  }

  @override
  String get profRemindBefore => 'ذكّرني قبلها بـ';

  @override
  String profMinutes(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get profRanOutTitle => 'عندما ينفد مكوّن';

  @override
  String get profRanOutSubtitle => 'تنبيه بعد الطبخ إذا استخدمت آخر ما في المخزون';

  @override
  String get profChannelName => 'تذكيرات سفرة';

  @override
  String get profChannelDescription => 'مواعيد الأكل، والبواقي، والأشياء التي نفدت';

  @override
  String profReminderMealTitle(String slot, String minutes) {
    return '$slot بعد $minutes دقيقة';
  }

  @override
  String profReminderMealBody(String meal) {
    return 'متخطط: $meal. ابدأ التحضير.';
  }

  @override
  String profReminderLeftoverTitle(String dish) {
    return 'بواقي $dish في الثلاجة';
  }

  @override
  String profReminderLeftoverBody(String servings) {
    return 'تبقّى $servings. سخّنها اليوم.';
  }

  @override
  String get profServingOne => '1 حصة';

  @override
  String profServings(String count) {
    return '$count حصة';
  }

  @override
  String get profStyleCabinets => 'طراز الخزائن';

  @override
  String get profStyleClassic => 'كلاسيكي';

  @override
  String get profStyleModern => 'عصري';

  @override
  String get profStyleJapandi => 'ياباندي';

  @override
  String get profStyleFridge => 'الثلاجة';

  @override
  String get profFridgeRetro => 'كريمية قديمة';

  @override
  String get profFridgeDouble => 'معدنية ببابين';

  @override
  String get profStyleRange => 'الموقد';

  @override
  String get profRangeFreestanding => 'موقد مستقل';

  @override
  String get profRangeBuiltin => 'سطح وفرن مدمجان';

  @override
  String get profStyleRug => 'السجادة';

  @override
  String get profRugNone => 'بلا سجادة';

  @override
  String get profRugPersian => 'حمراء منقوشة';

  @override
  String get profRugTeal => 'زرقاء حديثة';

  @override
  String get profRugOchre => 'كليم دافئ';

  @override
  String get profStyleCurtain => 'الستارة';

  @override
  String get profCurtainGingham => 'قماش مربعات';

  @override
  String get profCurtainBlind => 'شرائح بيضاء';

  @override
  String get profCurtainNone => 'بلا ستارة';

  @override
  String get profCabinetColor => 'لون الخزائن';

  @override
  String get profColorOriginal => 'الأصلي';

  @override
  String get profColorCream => 'كريمي';

  @override
  String get profColorBlueGray => 'أزرق رمادي';

  @override
  String get profColorTerracotta => 'تيراكوتا';

  @override
  String get profShotKitchen => 'المطبخ كله';

  @override
  String get profShotFridge => 'افتح الثلاجة';

  @override
  String get profShotFreezer => 'افتح الفريزر';

  @override
  String get profExtras => 'إضافات';

  @override
  String get profPlants => 'نباتات معلقة';

  @override
  String get profCane => 'أبواب خيزران';

  @override
  String get addTitle => 'أضف مشترياتك';

  @override
  String get addReadFailed => 'تعذّرت القراءة. تحقق من الاتصال، أو اكتب المشتريات بالأسفل.';

  @override
  String get addNothingFound => 'لم نجد مكونات هنا. جرّب صورة أوضح، أو اكتبها.';

  @override
  String get addCameraUnavailable => 'الكاميرا غير متاحة. اسمح بها من إعدادات الهاتف.';

  @override
  String get addPhotosFailed => 'تعذّر فتح الصور.';

  @override
  String get addMarkOne => 'علّم صنفًا واحدًا على الأقل';

  @override
  String get addPickOne => 'اختر مكوّنًا واحدًا على الأقل';

  @override
  String addToKitchen(String count) {
    return 'أضف $count إلى المطبخ';
  }

  @override
  String get addCameraTitle => 'صوّر الفاتورة';

  @override
  String get addCameraDetail => 'بالكاميرا';

  @override
  String get addGalleryTitle => 'من الصور';

  @override
  String get addGalleryDetail => 'لقطة طلب أو فاتورة';

  @override
  String get addTypeHint => 'أو اكتب: 2 كيلو طماطم';

  @override
  String get addLineTooltip => 'أضف السطر';

  @override
  String get addSaveFailed => 'لم تُحفظ المشتريات. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String addSavedNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مكوّن',
      few: '$count مكونات',
      two: 'مكوّنان',
      one: 'مكوّن واحدة',
    );
    return 'أُضيفت $_temp0 إلى مطبخك';
  }

  @override
  String get addRestart => 'ابدأ من جديد';

  @override
  String get addReading => 'نقرأ مشترياتك…';

  @override
  String addReadyCount(String count) {
    return '$count جاهزة';
  }

  @override
  String addCheckCount(String count) {
    return '$count للتأكد';
  }

  @override
  String addOpenCount(String count) {
    return '$count بلا مكوّن';
  }

  @override
  String get addAmountUnknown => 'الكمية؟';

  @override
  String get addChooseIngredient => 'اختر المكوّن';

  @override
  String get addRestore => 'أعِده';

  @override
  String get addRemove => 'احذفه';

  @override
  String get addWhichIngredient => 'أي مكوّن هذا؟';

  @override
  String get addSearchHint => 'رز، لبن، زيت…';

  @override
  String addAmountTitle(String name) {
    return 'كمية $name';
  }

  @override
  String get addAmountHint => 'الكمية';

  @override
  String get addSave => 'حفظ';

  @override
  String get addDontKnowAmount => 'لا أعرف الكمية';

  @override
  String get addNotKnownYet => 'لم نعرفه بعد';

  @override
  String addAsking(String text) {
    return 'نتعرف على «$text»…';
  }

  @override
  String get addScanTitle => 'امسح باركود المنتج';

  @override
  String get addScanCameraOff => 'الكاميرا غير متاحة. اسمح بها من إعدادات الهاتف، أو اكتب الرقم بالأسفل.';

  @override
  String get addScanManualHint => 'أو اكتب الرقم الموجود تحت الباركود';

  @override
  String get addScanGo => 'ابحث';

  @override
  String get addScanUnknownProduct => 'هذا المنتج غير موجود في بياناتنا بعد';

  @override
  String addScanPackage(String size) {
    return 'العبوة: $size';
  }

  @override
  String get addScanWhich => 'أي مكوّن في مطبخك هذا؟ سنتذكره في المرة القادمة.';

  @override
  String get addScanSearchHint => 'اكتب اسم المكوّن (رز، لبن، زيت…)';

  @override
  String get rcpSaveRecipe => 'حفظ الوصفة';

  @override
  String get rcpUnsaveRecipe => 'إلغاء الحفظ';

  @override
  String get rcpFilterAll => 'الكل';

  @override
  String get rcpFilterFromStock => 'من الموجود';

  @override
  String get rcpFilterReadyFromStock => 'جاهزة بالموجود';

  @override
  String get rcpFilterSaved => 'محفوظة';

  @override
  String get rcpKindSection => 'النوع';

  @override
  String get rcpTimeSection => 'الوقت';

  @override
  String get rcpTimeAny => 'أي وقت';

  @override
  String get rcpTime30 => '30 دقيقة أو أقل';

  @override
  String get rcpTime60 => 'ساعة أو أقل';

  @override
  String get rcpClearFilters => 'امسح الفلاتر';

  @override
  String get rcpSearchHint => 'ابحث باسم أكلة أو مكوّن';

  @override
  String get rcpFilters => 'الفلاتر';

  @override
  String get rcpAllCuisines => 'كل المطابخ';

  @override
  String rcpStockNote(String servings) {
    return 'الكميات محسوبة لـ$servings أفراد. المقادير غير المعروفة لا تُعتبر جاهزة.';
  }

  @override
  String get rcpLoadFailed => 'تعذّر تحميل الوصفات.';

  @override
  String get rcpTryAgain => 'حاول مرة أخرى';

  @override
  String get rcpFromStockTitle => 'اقتراحات من خزينك';

  @override
  String get rcpForYouTitle => 'وصفات على ذوقك';

  @override
  String rcpRecipeCount(int count) {
    return '$count وصفة';
  }

  @override
  String get rcpEmptyTitle => 'نبحث عن شيء آخر؟';

  @override
  String get rcpShowAll => 'عرض كل الوصفات';

  @override
  String rcpShowMore(String count) {
    return 'اعرض $count أخرى';
  }

  @override
  String get appRetrySave => 'إعادة الحفظ';

  @override
  String get appLoadFailed => 'تعذّر تحميل بيانات البيت. بياناتك لم تُحذف.';

  @override
  String get appTryAgain => 'حاول مرة أخرى';

  @override
  String get appBack => 'رجوع';

  @override
  String get appViewAddStock => 'نزوّد الخير';

  @override
  String get appViewRecipe => 'وصفة على قدرك';

  @override
  String get appViewKitchen3d => 'مطبخي 3D';

  @override
  String get appViewCooking => 'نطبخ معًا';

  @override
  String get appUnsaveRecipe => 'إلغاء الحفظ';

  @override
  String get appSaveRecipe => 'حفظ الوصفة';

  @override
  String get appHeaderToday => 'سُفرة';

  @override
  String get appTabRecipes => 'الوصفات';

  @override
  String get appTabStock => 'الخزين';

  @override
  String get appTabPlan => 'الخطة';

  @override
  String get appTabAccount => 'حسابي';

  @override
  String get appTabSettings => 'الإعدادات';

  @override
  String get appTabStyle => 'شكل المطبخ';

  @override
  String get appTabToday => 'اليوم';

  @override
  String get appCommunity => 'المجتمع';

  @override
  String get appMemoryStoreLabel => 'غير محفوظ (تجربة)';

  @override
  String get appDefaultName => 'صاحب السفرة';

  @override
  String appDefaultHouse(String name) {
    return 'بيت $name';
  }

  @override
  String get appMealFallback => 'وجبة';

  @override
  String get appSaveFull => 'امتلأت مساحة الحفظ في حسابك، فلم يُحفظ التعديل.';

  @override
  String get appSaveFailedOne => 'لم يُحفظ آخر تعديل. تحقق من الاتصال وأعد الحفظ قبل الخروج.';

  @override
  String appSaveFailedMany(String count) {
    return 'تعديلات لم تُحفظ: $count. تحقق من الاتصال وأعد الحفظ قبل الخروج.';
  }

  @override
  String get appShoppingListHeader => 'قائمة الشراء من سفرة:';

  @override
  String get appRanOutTitle => 'نفد من المطبخ';

  @override
  String appRanOutBody(String items) {
    return '$items. ضيفهم لقائمة الشراء.';
  }

  @override
  String get appListSeparator => '، ';

  @override
  String get appSessionOpenFailed => 'لا يمكن فتح بياناتك الآن. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get appRetry => 'إعادة المحاولة';

  @override
  String get appSignOut => 'تسجيل الخروج';

  @override
  String get appEnterEmailFirst => 'اكتب البريد الإلكتروني الأول.';

  @override
  String get appResetSent => 'إذا كان البريد مسجّلًا، سيصلك رابط استعادة كلمة المرور.';

  @override
  String get appAuthNetwork => 'تحقق من اتصال الإنترنت وحاول مرة أخرى.';

  @override
  String get appAuthTooMany => 'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';

  @override
  String get appAuthWeakPassword => 'اختر كلمة مرور أقوى.';

  @override
  String get appAuthEmailInUse => 'البريد مسجّل بالفعل. جرّب تسجيل الدخول.';

  @override
  String get appAuthInvalidEmail => 'راجع كتابة البريد الإلكتروني.';

  @override
  String get appAuthSignUpUnavailable => 'إنشاء الحساب غير متاح حاليًا. حاول لاحقًا.';

  @override
  String get appAuthFailed => 'تعذر الدخول. راجع البريد وكلمة المرور أو استعد حسابك.';

  @override
  String get appRequestFailed => 'تعذّر إكمال الطلب. حاول مرة أخرى.';

  @override
  String get appCreateAccountTitle => 'أنشئ حسابًا لسفرتك';

  @override
  String get appWelcome => 'أهلًا بك في سفرة';

  @override
  String get appSignInSubtitle => 'مكونات بيتك واختياراتك محفوظة في حسابك.';

  @override
  String get appEmailLabel => 'البريد الإلكتروني';

  @override
  String get appEmailInvalid => 'اكتب بريدًا صحيحًا';

  @override
  String get appPasswordLabel => 'كلمة المرور';

  @override
  String get appPasswordShort => 'كلمة المرور 6 أحرف على الأقل';

  @override
  String get appWait => 'لحظة…';

  @override
  String get appCreateAccount => 'إنشاء حساب';

  @override
  String get appSignIn => 'تسجيل الدخول';

  @override
  String get appHaveAccount => 'عندي حساب بالفعل';

  @override
  String get appFirstTime => 'أول مرة؟ أنشئ حسابًا';

  @override
  String get appForgotPassword => 'نسيت كلمة المرور';

  @override
  String get appSavedOnDevice => 'محفوظ على الجهاز';

  @override
  String get appSavedInAccount => 'محفوظ في حسابك';

  @override
  String get appSavedInSharedKitchen => 'محفوظ في المطبخ المشترك';

  @override
  String get appInviteNotFound => 'هذا الرمز غير موجود.';

  @override
  String get appInviteExpired => 'انتهت صلاحية هذا الرمز. اطلب رمزًا جديدًا.';

  @override
  String appChallengeCookPlannedTitle(String goal) {
    return 'اطبخ $goal وجبات من خطتك';
  }

  @override
  String get appChallengeCookPlannedDetail => 'تُحسب كل وجبة مخططة طُبخت هذا الأسبوع.';

  @override
  String appChallengeDifferentTitle(String goal) {
    return 'نوّع: $goal أكلات مختلفة';
  }

  @override
  String get appChallengeDifferentDetail => 'تُحسب كل وصفة مختلفة طُبخت هذا الأسبوع مرة واحدة.';

  @override
  String get appChallengeNewTitle => 'جرّب وصفتين أول مرة';

  @override
  String get appChallengeNewDetail => 'وصفة لم تُطبخ من قبل في مطبخك.';

  @override
  String get appHouseMember => 'فرد من البيت';

  @override
  String get appChefCelebrate => 'شيف سفرة سعيد وجاهز للطبخ';

  @override
  String get appChefIdle => 'شيف سفرة، طماطماية مرحة بقبعة شيف';

  @override
  String get dataToTaste => 'حسب الرغبة';

  @override
  String get kitchen3dAlt => 'المطبخ ثلاثي الأبعاد';

  @override
  String get kitchen3dError => 'تعذّر عرض المطبخ.';

  @override
  String get kitchen3dLoading => 'يُجهَّز المطبخ';

  @override
  String get librarySection => 'الوصفات على جهازك';

  @override
  String get libraryInfo => 'قائمة الوصفات محفوظة على جهازك دائمًا. تُحفظ الوصفة كاملة عند فتحها أو حفظها، والمحفوظة تبقى في حسابك أيضًا وإن حُذفت من المكتبة. تصل الوصفات الجديدة تلقائيًا دون تحديث التطبيق.';

  @override
  String get libraryOnDevice => 'على الجهاز';

  @override
  String get librarySaved => 'محفوظة';

  @override
  String get librarySize => 'المساحة';

  @override
  String librarySizeValue(String value) {
    return '$value ميجابايت';
  }

  @override
  String libraryUpdated(String date) {
    return 'آخر تحديث للمكتبة: $date';
  }

  @override
  String get libraryUpdateNow => 'تحديث الآن';

  @override
  String get libraryUpdating => 'جارٍ التحديث…';

  @override
  String get libraryUpToDate => 'المكتبة محدّثة';

  @override
  String get libraryUpdateFailed => 'تعذّر الاتصال بالمكتبة';

  @override
  String get recipeNotOnDevice => 'هذه الوصفة غير محفوظة على جهازك. اتصل بالإنترنت ثم حاول مرة أخرى.';

  @override
  String get recipeRetry => 'إعادة المحاولة';
}
