// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sofra';

  @override
  String get lookSection => 'Display & language';

  @override
  String get lookAppearance => 'Appearance';

  @override
  String get lookLight => 'Light';

  @override
  String get lookSystem => 'Same as phone';

  @override
  String get lookDark => 'Dark';

  @override
  String get lookTextSize => 'Text size';

  @override
  String get lookTextNormal => 'Normal';

  @override
  String get lookTextLarge => 'Large';

  @override
  String get lookTextLarger => 'Larger';

  @override
  String get lookGlyph => 'A';

  @override
  String get lookColors => 'Color correction';

  @override
  String get lookColorsInfo =>
      'For people who find some colors hard to tell apart: shifts the whole app\'s colors so they\'re clearer, like “Color correction” in your phone\'s settings.';

  @override
  String get lookMotion => 'Reduce motion';

  @override
  String get lookMotionInfo =>
      'Calmer transitions, with no bounce or background movement.';

  @override
  String get lookLanguage => 'Language';

  @override
  String get lookLanguageArabic => 'العربية';

  @override
  String get lookLanguageEnglish => 'English';

  @override
  String get lookVisionNoneShort => 'Normal';

  @override
  String get lookVisionProtanShort => 'Red';

  @override
  String get lookVisionDeutanShort => 'Green';

  @override
  String get lookVisionTritanShort => 'Blue';

  @override
  String get lookVisionNone => 'No correction';

  @override
  String get lookVisionProtan => 'Hard to see red';

  @override
  String get lookVisionDeutan => 'Hard to see green';

  @override
  String get lookVisionTritan => 'Hard to see blue';

  @override
  String get uiIncrease => 'Increase';

  @override
  String get uiDecrease => 'Decrease';

  @override
  String get commTitle => 'Sofra community';

  @override
  String get commTagline => 'All of us at one table';

  @override
  String get commKitchen => 'Home kitchen';

  @override
  String get commChallenge => 'Weekly challenge';

  @override
  String get commPreviewNote =>
      'On-device preview: nothing you post here reaches anyone, and it\'s deleted when you close the app.';

  @override
  String get commPartHome => 'Home';

  @override
  String get commPartMine => 'My recipes';

  @override
  String get commPartPrices => 'Local prices';

  @override
  String get commShareOwnRecipe => 'Share one of your recipes';

  @override
  String get commRecipesLoadError => 'Couldn\'t load recipes. Try again.';

  @override
  String get commMineEmptyWrite =>
      'Write a recipe in “My own recipe”, then share it here.';

  @override
  String get commMineEmpty => 'You haven\'t shared a recipe yet.';

  @override
  String get commNeedsAccount =>
      'This part needs an account. This copy is saved on this device only.';

  @override
  String get commConnectionProblem =>
      'There was a connection problem. Try again.';

  @override
  String get commNoInitial => '?';

  @override
  String get commYourStory => 'Your story';

  @override
  String get commChallengeNote => 'Cook and share';

  @override
  String get commKitchenNote => 'One pantry for the whole home';

  @override
  String get commYoutubeChefs => 'Chefs on YouTube';

  @override
  String get commFromSofraHomes => 'From Sofra homes';

  @override
  String get commShareRecipe => 'Share a recipe';

  @override
  String get commFeedEmpty =>
      'No one has shared a recipe yet. Start with “My own recipe”.';

  @override
  String get commOpenChannel => 'Open the channel on YouTube';

  @override
  String get commShareFromYours => 'Share one of your recipes';

  @override
  String commSharedNotice(String name) {
    return 'Shared $name';
  }

  @override
  String get commShareFailed => 'Couldn\'t share. Try again.';

  @override
  String commFeedCounts(int ingredients, int steps) {
    String _temp0 = intl.Intl.pluralLogic(
      ingredients,
      locale: localeName,
      other: '$ingredients ingredients',
      one: '1 ingredient',
    );
    String _temp1 = intl.Intl.pluralLogic(
      steps,
      locale: localeName,
      other: '$steps steps',
      one: '1 step',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String commServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get commStoryPrompt => 'What did you cook today?';

  @override
  String get commStoryHint => 'Write your story';

  @override
  String get commStoryDishHint => 'Dish name (optional)';

  @override
  String get commStoryPost => 'Post for one day';

  @override
  String commStoryHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get commStoryNow => 'Now';

  @override
  String get commKitchenLoadError => 'Couldn\'t open the kitchen. Try again.';

  @override
  String get commKitchenIntro =>
      'Bring the whole home to one kitchen: the same pantry, the same plan and the same shopping list. What\'s in your kitchen now is what will be shared.';

  @override
  String get commKitchenCreate => 'Create a shared kitchen';

  @override
  String get commHaveInvite => 'Have an invite code?';

  @override
  String get commCodeExample => 'For example: K7PM2QXA';

  @override
  String get commKitchenJoin => 'Join the kitchen';

  @override
  String get commKitchenJoinNote =>
      'When you join a shared kitchen, your own kitchen stays saved and you go back to it when you leave.';

  @override
  String get commSharedKitchen => 'Shared kitchen';

  @override
  String get commKitchenOwner => 'Kitchen owner';

  @override
  String get commInviteSend =>
      'Send this code to your household (valid for one week):';

  @override
  String get commInviteCreate => 'Create an invite code';

  @override
  String get commBackToMyKitchen => 'Back to my own kitchen';

  @override
  String commByAuthor(String name) {
    return 'By $name';
  }

  @override
  String get commIngredients => 'Ingredients';

  @override
  String get commMethod => 'Method';

  @override
  String get commRatings => 'Ratings';

  @override
  String get commNoRatings => 'No one has rated it yet.';

  @override
  String commRatingAverage(String average, String count) {
    return '$average out of 5 ($count)';
  }

  @override
  String get commCommentHint => 'Your comment (optional)';

  @override
  String get commSaveRating => 'Save my rating';

  @override
  String commChallengeCookPlanned(String goal) {
    return 'Cook $goal meals from your plan';
  }

  @override
  String get commChallengeCookPlannedDetail =>
      'Every planned meal cooked this week counts.';

  @override
  String commChallengeDifferent(String goal) {
    return 'Mix it up: $goal different dishes';
  }

  @override
  String get commChallengeDifferentDetail =>
      'Each different recipe cooked this week counts once.';

  @override
  String commChallengeNew(int goal) {
    String _temp0 = intl.Intl.pluralLogic(
      goal,
      locale: localeName,
      other: 'Try $goal new recipes',
      one: 'Try 1 new recipe',
    );
    return '$_temp0';
  }

  @override
  String get commChallengeNewDetail =>
      'A recipe never cooked before in your kitchen.';

  @override
  String commChallengeProgress(String done, String goal) {
    return '$done of $goal done';
  }

  @override
  String get commChallengeLog => 'Add my progress to the board';

  @override
  String get commChallengeHomes => 'Taking part';

  @override
  String get commBoardLoadError => 'Couldn\'t load the board. Try again.';

  @override
  String get commBoardEmpty => 'No one has joined this week yet.';

  @override
  String get commLeaveTitle => 'Leave the shared kitchen?';

  @override
  String get commLeaveBody =>
      'You\'ll go back to your own kitchen and won\'t see your household\'s changes. To come back, you\'ll need a new invite code from the kitchen owner.';

  @override
  String get commCancel => 'Cancel';

  @override
  String get commLeave => 'Leave';

  @override
  String get detailOpenError =>
      'Couldn\'t open the recipe. Go back and try again.';

  @override
  String get detailPreparing => 'Getting it ready…';

  @override
  String get detailCookNow => 'Cook now';

  @override
  String get detailCookNowNote =>
      'Saved as today\'s meal so you can finish it. Nothing is deducted until you confirm.';

  @override
  String get detailAddToPlan => 'Add to plan';

  @override
  String detailPhotoCredit(String credit, String licence) {
    return 'Photo: $credit · $licence';
  }

  @override
  String get detailServingsQuestion => 'Cooking for how many?';

  @override
  String get detailServingsHint => 'Amounts adjust automatically';

  @override
  String get detailLogAs => 'Log this meal as';

  @override
  String detailAllergyMatch(String matches) {
    return 'Heads up: $matches. This only matches names, so check the ingredients and packaging yourself.';
  }

  @override
  String detailAllergyMatchItem(String allergy, String lines) {
    return '“$allergy” in $lines';
  }

  @override
  String detailAllergyCheck(String allergies) {
    return 'Check the recipe\'s ingredients and packaging against your saved allergies: $allergies.';
  }

  @override
  String get detailListSeparator => ', ';

  @override
  String get detailGroupSeparator => '; ';

  @override
  String get detailIngredientsScaled => 'Ingredients for your servings';

  @override
  String get detailIngredientsSource => 'Ingredients as in the source';

  @override
  String get detailSteps => 'Steps';

  @override
  String get detailNoPricesNote =>
      'Prices and nutrition aren\'t shown here until they\'re checked against their sources. Amounts are from the source.';

  @override
  String get detailToTaste => 'to taste';

  @override
  String get detailYieldUnknown =>
      'The source doesn\'t say how many this recipe serves';

  @override
  String get detailYieldAsk =>
      'To scale the amounts and put it on your table, tell us roughly how many people the whole recipe serves. The original recipe won\'t change.';

  @override
  String detailYieldServes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Serves $count',
      one: 'Serves 1',
    );
    return '$_temp0';
  }

  @override
  String get servingsInfoLabel => 'How the number of people was worked out';

  @override
  String servingsInfoBasis(String amount, String ingredient, String norm) {
    return 'Based on $amount $ingredient, about $norm per person.';
  }

  @override
  String servingsInfoBasisMany(String list) {
    return 'Based on the main ingredients together: $list.';
  }

  @override
  String get servingsInfoApply => 'Apply';

  @override
  String get servingsInfoLow =>
      'This is a rough estimate. Adjust it if it seems off.';

  @override
  String get servingsInfoAdjust => 'Adjust the number';

  @override
  String get detailPlanned =>
      'The meal is on your table, and your stock hasn\'t changed';

  @override
  String detailWaysToMake(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ways to make it',
      one: '1 way to make it',
    );
    return '$_temp0';
  }

  @override
  String get detailIngredients => 'Ingredients';

  @override
  String get detailPronunciation => 'Pronunciation';

  @override
  String get detailWaysOpenError =>
      'Couldn\'t open the ways. Go back and try again.';

  @override
  String get detailComparePickHint =>
      'Pick a country from the bar to see the amounts and steps.';

  @override
  String get detailDefineConversion => 'Set conversion';

  @override
  String detailConversionQuestion(String from, String name, String to) {
    return '1 $from of $name = how many $to?';
  }

  @override
  String get detailConversionHint =>
      'Use a measurement from your kitchen. It\'s saved for this ingredient only.';

  @override
  String get detailEnterPositive => 'Enter a number greater than zero';

  @override
  String get detailCancel => 'Cancel';

  @override
  String get detailSave => 'Save';

  @override
  String detailConversionSaved(
    String from,
    String name,
    String factor,
    String to,
  ) {
    return 'Saved: 1 $from $name = $factor $to';
  }

  @override
  String get detailInStock => 'You have it';

  @override
  String detailMissing(String amount, String unit) {
    return 'Need $amount $unit more';
  }

  @override
  String get detailUnitMismatch => 'Unit differs from your stock';

  @override
  String get detailUnmeasured => 'No amount';

  @override
  String get detailOptional => 'Optional';

  @override
  String get detailPlanWhen => 'When should it go on the table?';

  @override
  String get detailToday => 'Today';

  @override
  String get detailTomorrow => 'Tomorrow';

  @override
  String get detailDayAfterTomorrow => 'Day after tomorrow';

  @override
  String get detailDone => 'Done';

  @override
  String get detailCookOpenError => 'Couldn\'t open the recipe.';

  @override
  String get detailFinishCooking => 'Done cooking · Review stock';

  @override
  String get detailNoSteps =>
      'The source has no written steps for this recipe.';

  @override
  String get detailNextStep => 'Next step';

  @override
  String detailStepOf(String current, String total) {
    return '$current of $total';
  }

  @override
  String detailAboutMinutes(String minutes) {
    return 'About $minutes min';
  }

  @override
  String get detailPreviousStep => 'Previous step';

  @override
  String get detailEnjoy => 'Enjoy your meal!';

  @override
  String detailCookedNote(String name) {
    return '$name is cooked, and what you confirmed was taken out of your stock.';
  }

  @override
  String get detailShowKitchen => 'See what\'s left in your kitchen';

  @override
  String detailServings(String amount) {
    return '$amount servings';
  }

  @override
  String get detailOneServing => '1 serving';

  @override
  String detailLeftoversSaved(String servings) {
    return 'We put $servings in the fridge. You\'ll find it in the microwave when you want to heat it up.';
  }

  @override
  String get detailAnyLeftovers => 'Any food left over?';

  @override
  String get detailLeftoversHint =>
      'Log it and we\'ll put it in the fridge so you can heat it up later.';

  @override
  String get detailRemindAfter => 'Remind me in';

  @override
  String get detailRemindNone => 'None';

  @override
  String detailRemindDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get detailPutInFridge => 'Put it in the fridge';

  @override
  String detailHaveOf(String have, String total, String unit) {
    return 'You have $have of $total $unit';
  }

  @override
  String detailUsingStock(String name, String stock) {
    return '$name · using $stock';
  }

  @override
  String get detailBoughtRest => 'I bought the rest';

  @override
  String get detailCookedLess => 'I used less';

  @override
  String get detailBeforeDeduct => 'Before updating your stock';

  @override
  String get detailWillDeduct => 'Will be taken out';

  @override
  String get detailWillDeductNote => 'In your stock, in the same unit';

  @override
  String get detailPartial => 'You only have part';

  @override
  String get detailPartialNote =>
      'Did you buy the rest, or cook with what you had? Either way, what you have is taken out.';

  @override
  String get detailNotDeducted => 'Won\'t be taken out';

  @override
  String get detailNotDeductedNote =>
      'Missing, or logged in a different unit. The cost stays unknown.';

  @override
  String get detailUnmeasuredGroup => 'No amount in the recipe';

  @override
  String get detailUnmeasuredNote => 'Like “to taste”. It won\'t be taken out.';

  @override
  String get detailConfirm => 'Confirm';

  @override
  String get detailNotYet => 'Not yet';

  @override
  String get kitOpenKitchen3d => 'My kitchen 3D';

  @override
  String get kitShopping => 'Shopping';

  @override
  String get kitLeftoversTitle => 'Leftovers';

  @override
  String get kitLeftoversEmpty => 'No leftovers saved.';

  @override
  String get kitLeftovers => 'Leftovers';

  @override
  String get kitAddIngredientTitle => 'Add an ingredient';

  @override
  String get kitAddIngredientDetail => 'Search and pick';

  @override
  String get kitReceiptTitle => 'Receipt or list';

  @override
  String get kitReceiptDetail => 'Photo or text';

  @override
  String get kitAll => 'All';

  @override
  String kitAllCount(String count) {
    return 'All $count';
  }

  @override
  String get kitGettingToKnow => 'We\'re still getting to know your kitchen';

  @override
  String get kitShelfEmpty => 'This shelf is empty';

  @override
  String get kitEmptyHint =>
      'Add a few ingredients to start. No need for a full inventory.';

  @override
  String get kitTrySample => 'Try with sample ingredients';

  @override
  String get kitSampleAdded => 'Sample ingredients added to your kitchen';

  @override
  String get kitDeductNote => 'Stock updates after you confirm cooking.';

  @override
  String get kitQuantityUnknown => 'Amount not set';

  @override
  String kitEditItem(String name) {
    return 'Edit $name';
  }

  @override
  String kitQuantityOf(String name) {
    return 'Amount of $name';
  }

  @override
  String get kitQuantityInvalid => 'Enter a number, 0 or more';

  @override
  String kitQuantityLabel(String unit) {
    return 'Amount ($unit)';
  }

  @override
  String get kitQuantityHelper => 'Enter 0 if it ran out';

  @override
  String get kitCancel => 'Cancel';

  @override
  String get kitSave => 'Save';

  @override
  String kitQuantityUpdated(String name) {
    return '$name amount updated';
  }

  @override
  String get kitAddStockDone => 'Done, show my kitchen';

  @override
  String get kitWhatDoYouHave => 'What do you have?';

  @override
  String get kitAddStockHint =>
      'Tap + to add quickly, or tap an ingredient to enter the amount and unit.';

  @override
  String get kitSearchIngredient => 'Search for an ingredient';

  @override
  String get kitScanBarcode => 'Scan a barcode';

  @override
  String get kitIngredientNotFound =>
      'That ingredient isn\'t on the list. Try another name.';

  @override
  String kitAddItem(String name) {
    return 'Add $name';
  }

  @override
  String kitAddedToKitchen(String name) {
    return '$name added to your kitchen';
  }

  @override
  String kitYouHave(String amounts) {
    return 'You have $amounts';
  }

  @override
  String get kitEnterAmount => 'Enter an amount above zero';

  @override
  String get kitEnterWeight => 'Enter a weight above zero, or leave it empty';

  @override
  String get kitAmount => 'Amount';

  @override
  String get kitUnit => 'Unit';

  @override
  String kitPieceGrams(String unit) {
    return 'How many grams in one $unit? (optional)';
  }

  @override
  String kitPieceMl(String unit) {
    return 'How many ml in one $unit? (optional)';
  }

  @override
  String get kitPieceHelper =>
      'From your scale or the package label. Helps with recipes.';

  @override
  String get kitGramsShort => 'g';

  @override
  String get kitMlShort => 'ml';

  @override
  String get kitPlace => 'Where it goes';

  @override
  String get kitAddToKitchen => 'Add to my kitchen';

  @override
  String kitServing(String count) {
    return '$count serving';
  }

  @override
  String kitServings(String count) {
    return '$count servings';
  }

  @override
  String get kitLeftoverDue => 'due now';

  @override
  String get kitHowManyWarmed => 'How many servings did you warm up?';

  @override
  String kitEatOf(String eaten, String total) {
    return '$eaten of $total';
  }

  @override
  String get kitNotYet => 'Not yet';

  @override
  String get kitWarmedAndAte => 'Warmed up and eaten';

  @override
  String get kitEmptySoFar => 'Empty for now.';

  @override
  String get kitSearchSomething => 'Search for something';

  @override
  String get kitByKind => 'By kind';

  @override
  String get kitLastAdded => 'Last added';

  @override
  String kitItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get kitSearch => 'Search';

  @override
  String get kitAdd => 'Add';

  @override
  String get kitAllStock => 'All stock';

  @override
  String get kitClose => 'Close';

  @override
  String get kitNothingByName => 'Nothing by that name here.';

  @override
  String kitItemSemantics(String label, String amount) {
    return '$label, $amount';
  }

  @override
  String get kitShoppingError => 'Couldn\'t prepare the list. Try again.';

  @override
  String get kitShoppingTitle => 'This week\'s shopping list';

  @override
  String get kitShareList => 'Send it (WhatsApp and more)';

  @override
  String get kitNothingMissing => 'You have everything for the planned meals.';

  @override
  String kitAboutTotal(String amount, String currency) {
    return 'About $amount $currency at your prices.';
  }

  @override
  String kitKnownSubtotal(String amount, String currency) {
    return 'Priced items: $amount $currency. Some items have no price.';
  }

  @override
  String get kitPaidHint => 'How much did you pay? (optional)';

  @override
  String kitUnresolvedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count lines have no amount (like “to taste”) and are left off the list.',
      one: '1 line has no amount (like “to taste”) and is left off the list.',
    );
    return '$_temp0';
  }

  @override
  String kitUnconvertibleStock(String names) {
    return 'The stock unit for $names doesn\'t convert to the recipe unit. Check it in your stock.';
  }

  @override
  String get kitListSeparator => ', ';

  @override
  String get kitMarkBought => 'Check off what you bought';

  @override
  String get kitPutBoughtAway => 'Put what you bought in the kitchen';

  @override
  String get kitPreviewNoYield =>
      'You have the ingredients. Set servings to check amounts';

  @override
  String get kitPreviewReady => 'Ready with what you have';

  @override
  String get kitPreviewNotEnough => 'Not enough amounts to tell';

  @override
  String kitPreviewMissingUnknown(int missing, int unknown) {
    return '$missing missing · $unknown unclear';
  }

  @override
  String kitPreviewUnknown(int unknown) {
    String _temp0 = intl.Intl.pluralLogic(
      unknown,
      locale: localeName,
      other: '$unknown amounts unclear',
      one: '1 amount unclear',
    );
    return '$_temp0';
  }

  @override
  String kitPreviewMissing(int missing) {
    String _temp0 = intl.Intl.pluralLogic(
      missing,
      locale: localeName,
      other: '$missing ingredients missing',
      one: '1 ingredient missing',
    );
    return '$_temp0';
  }

  @override
  String get mineNewRecipe => 'My own recipe';

  @override
  String mineIngredientsSteps(int ingredients, int steps) {
    String _temp0 = intl.Intl.pluralLogic(
      ingredients,
      locale: localeName,
      other: '$ingredients ingredients',
      one: '1 ingredient',
    );
    String _temp1 = intl.Intl.pluralLogic(
      steps,
      locale: localeName,
      other: '$steps steps',
      one: '1 step',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get mineTomorrow => 'Tomorrow';

  @override
  String get minePutOnTable => 'Put it on the table';

  @override
  String get mineAddedToTable => 'Added to the table.';

  @override
  String get mineSaveFailed => 'The recipe wasn\'t saved. Try again.';

  @override
  String get mineSaved => 'Saved to your recipes.';

  @override
  String get mineCuisineNeeded =>
      'Enter a specific cuisine for the recipe, like “Egyptian.”';

  @override
  String get mineSaving => 'Saving…';

  @override
  String get mineSave => 'Save recipe';

  @override
  String get mineDishName => 'Dish name';

  @override
  String get mineShortDescription => 'Short description';

  @override
  String get mineCuisine => 'Cuisine';

  @override
  String get minePrepMinutes => 'Prep (min)';

  @override
  String get mineCookMinutes => 'Cook (min)';

  @override
  String get mineServesHowMany => 'How many people does it serve?';

  @override
  String get mineIngredients => 'Ingredients';

  @override
  String get mineAddIngredient => '+ Ingredient';

  @override
  String get mineToTaste => 'To taste';

  @override
  String get mineWithoutAmount => 'No amount';

  @override
  String get mineWithAmount => 'With amount';

  @override
  String get mineRemove => 'Remove';

  @override
  String get mineSteps => 'Steps';

  @override
  String get mineAddStep => '+ Step';

  @override
  String get mineStepHint => 'What to do';

  @override
  String get mineMinutesHint => 'min';

  @override
  String get mineNutritionUnknown =>
      'Nutrition won\'t be calculated for this recipe until its ingredients are linked to a source.';

  @override
  String get mineSearchIngredient => 'Search for an ingredient';

  @override
  String get mineRecipeBookTitle => 'Recipe book';

  @override
  String mineWays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ways',
      one: 'One way',
    );
    return '$_temp0';
  }

  @override
  String mineCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count countries',
      one: 'One country',
    );
    return '$_temp0';
  }

  @override
  String mineDishTimeRange(String from, String to) {
    return '$from–$to min';
  }

  @override
  String get onbCountry => 'Country';

  @override
  String get onbCountryEgypt => 'Egypt · Egyptian pound';

  @override
  String get onbCountrySaudi => 'Saudi Arabia · Saudi riyal';

  @override
  String get onbEgypt => 'Egypt';

  @override
  String get onbSaudi => 'Saudi Arabia';

  @override
  String get onbBack => 'Back';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbStart => 'Get started';

  @override
  String get onbOpenSofra => 'Open my Sofra';

  @override
  String get onbContinue => 'Continue';

  @override
  String get onbWelcomeTitle => 'Everything in your kitchen makes a good meal';

  @override
  String get onbNameTitle => 'What\'s your name?';

  @override
  String get onbNameHint => 'e.g. Maryam';

  @override
  String get onbPeopleTitle => 'How many people do you cook for?';

  @override
  String get onbYourMeals => 'Your meals';

  @override
  String get onbCuisinesTitle => 'Which cuisines do you like?';

  @override
  String get onbCuisines => 'Cuisines';

  @override
  String get onbQuickFirst => 'Quick meals first';

  @override
  String get onbHealthTitle => 'We care about your health';

  @override
  String get onbHealthConditions => 'Your health';

  @override
  String get onbHealthNote =>
      'Saved only in your profile. Not a substitute for your doctor.';

  @override
  String get onbAvoidFoods => 'Foods you avoid';

  @override
  String get onbAvoidNote =>
      'We\'ll let you know if one shows up in a recipe. Check packaging yourself.';

  @override
  String get onbHealthBloodPressure => 'Blood pressure';

  @override
  String get onbHealthCholesterol => 'Cholesterol';

  @override
  String get onbHealthKidneys => 'Kidneys';

  @override
  String onbHello(String name) {
    return 'Hi, $name';
  }

  @override
  String get onbReady => 'Your Sofra is ready';

  @override
  String get onbStatPeople => 'People';

  @override
  String get onbStatMeals => 'Meals';

  @override
  String get onbStatCuisines => 'Cuisines';

  @override
  String get onbStatCares => 'To watch';

  @override
  String onbStepOf(String step, String total) {
    return 'Step $step of $total';
  }

  @override
  String get onbMore => 'More';

  @override
  String onbMoreSelected(String count) {
    return 'More, $count selected';
  }

  @override
  String onbAddCustom(String name) {
    return 'Add “$name”';
  }

  @override
  String get onbSearchOrType => 'Search or type a name';

  @override
  String get onbSearch => 'Search';

  @override
  String get onbDone => 'Done';

  @override
  String get onbZoneFridge => 'Fridge';

  @override
  String get onbZoneFreezer => 'Freezer';

  @override
  String get onbZonePantry => 'Pantry';

  @override
  String onbCountOne(String thing) {
    return '1 $thing';
  }

  @override
  String onbMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get onbTimeUnknown => 'Time not set';

  @override
  String get planSaturday => 'Sat';

  @override
  String get planSunday => 'Sun';

  @override
  String get planMonday => 'Mon';

  @override
  String get planTuesday => 'Tue';

  @override
  String get planWednesday => 'Wed';

  @override
  String get planThursday => 'Thu';

  @override
  String get planFriday => 'Fri';

  @override
  String get planToday => 'Today';

  @override
  String get planTomorrow => 'Tomorrow';

  @override
  String get planMonthTitle => 'Month plan';

  @override
  String get planMonthCalcError =>
      'Couldn\'t work out this plan. Check the meals and try again.';

  @override
  String get planConflictTitle => 'Some days already have meals';

  @override
  String planConflictBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count meals are already planned on these days. What should we do with them?',
      one:
          '1 meal is already planned on these days. What should we do with it?',
    );
    return '$_temp0';
  }

  @override
  String get planNotYet => 'Not yet';

  @override
  String get planReplace => 'Replace them';

  @override
  String get planKeepExisting => 'Keep them';

  @override
  String get planMonthAdded => 'Plan added to the table.';

  @override
  String get planMonthNotSaved => 'The plan wasn\'t saved. Work it out again.';

  @override
  String get planPutOnTable => 'Put the plan on the table';

  @override
  String get planCalculating => 'Working it out…';

  @override
  String get planCalculateMonth => 'Work out the month';

  @override
  String get planThisMonth => 'This month';

  @override
  String get planNextMonth => 'Next month';

  @override
  String get planMonthBudget => 'Food budget for the month';

  @override
  String get planMealsToPlan => 'Meals to plan';

  @override
  String get planWeekMenu => 'Weekly menu';

  @override
  String get planFillEmptyDays => 'Fill empty days';

  @override
  String get planWeekMenuHint =>
      'This week repeats all month. You can put two meals in one slot, and we\'ll pick the cheaper one.';

  @override
  String get planOmitUnmeasured => 'Leave out items with no amount';

  @override
  String get planOmitUnmeasuredHint =>
      'Like “salt to taste”. If you turn this off, the cost stays unknown.';

  @override
  String get planPick => '+ Pick';

  @override
  String planOrAlternative(String name) {
    return 'or $name';
  }

  @override
  String get planSearchMeal => 'Search for a meal';

  @override
  String planMonthFits(String cost, String left) {
    return 'This month costs you about $cost in shopping, leaving $left of the budget.';
  }

  @override
  String planMonthOver(String over) {
    return 'The cheapest choice goes $over over budget. Try cheaper meals or add an alternative in some slots.';
  }

  @override
  String planMonthBestFits(String cost, String left) {
    return 'The cheapest plan we found costs about $cost in shopping, leaving $left of the budget.';
  }

  @override
  String get planMonthUnknown => 'The full cost isn\'t known yet.';

  @override
  String get planRecordPrices => 'Add these prices';

  @override
  String get planRecordPricesHint =>
      'Your own price, from the last time you bought it. We don\'t guess prices.';

  @override
  String get planUnresolvedUnits =>
      'Some ingredients are stored in a unit that doesn\'t convert to the recipe\'s unit. Set the conversion on the stock page.';

  @override
  String planTruncated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'We only tried $count combinations of alternatives; there may be a cheaper one.',
      one: 'We only tried 1 combination of alternatives; there may be a cheaper one.',
    );
    return '$_temp0';
  }

  @override
  String planUncounted(String items) {
    return 'Not counted: $items.';
  }

  @override
  String get planListSeparator => ', ';

  @override
  String get planSavePrice => 'Save price';

  @override
  String get planAddHereEmpty =>
      'Add what you have here, and we\'ll suggest what to cook with it.';

  @override
  String get planLeftovers => 'Leftovers';

  @override
  String get planLeftoversEmpty =>
      'No leftovers saved. When you cook and something\'s left, you\'ll find it here to warm up.';

  @override
  String get planMyStock => 'My kitchen stock';

  @override
  String get planGoodMorning => 'Good morning';

  @override
  String get planGoodDay => 'Good afternoon';

  @override
  String get planGoodEvening => 'Good evening';

  @override
  String get planKitchenStyle => 'Kitchen style';

  @override
  String get planSettings => 'Settings';

  @override
  String planWhen(String slot, String day) {
    return '$slot · $day';
  }

  @override
  String get planStock => 'Stock';

  @override
  String planLeftoversDue(String count) {
    return 'Leftovers due: $count';
  }

  @override
  String get planWhatToCookToday => 'What are we cooking today?';

  @override
  String get planPickRecipeHint =>
      'Pick a recipe, and we\'ll show what your kitchen is missing before you start.';

  @override
  String get planPickRecipe => 'Pick a recipe';

  @override
  String planNextOnTable(String when) {
    return 'Next on the table · $when';
  }

  @override
  String get planStartCooking => 'Start cooking';

  @override
  String get planTableEmpty => 'The table is empty';

  @override
  String get planTableEmptyHint =>
      'Open the recipe book and pick a meal to see it here.';

  @override
  String get planRecipeBook => 'Recipe book';

  @override
  String planOnTable(String day) {
    return '$day\'s table';
  }

  @override
  String get planShoppingList => 'Shopping list';

  @override
  String get planUpcomingMeals => 'Upcoming meals';

  @override
  String get planAllPlans => 'All plans';

  @override
  String get planNoMealsPlanned =>
      'No meals planned. Pick one from the recipe book.';

  @override
  String get planWelcome => 'Welcome to Sofra';

  @override
  String planWelcomeName(String name) {
    return 'Hi, $name';
  }

  @override
  String get planCookFromStockQuestion =>
      'Cook something good from what you have';

  @override
  String get planWhatCanICook => 'What can I cook with what I have?';

  @override
  String get planWhatCanICookHint =>
      'Ideas from your pantry, with amounts and what\'s missing. Nothing is taken off until you confirm you cooked.';

  @override
  String get planDiscoverFromStock => 'Discover from what you have';

  @override
  String get planExploreAll => 'Or explore all recipes';

  @override
  String planPantryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pantry · $count ingredients',
      one: 'Pantry · 1 ingredient',
    );
    return '$_temp0';
  }

  @override
  String get planArrangeMeals => 'Plan your meals';

  @override
  String planLeftoversReminder(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count leftovers with reminders',
      one: 'You have 1 leftover with a reminder',
    );
    return '$_temp0';
  }

  @override
  String get planLeftoversNone => 'No leftovers saved.';

  @override
  String get planSeeThem => 'See them';

  @override
  String get planTodayMeals => 'Today\'s meals';

  @override
  String get planNoMealToday => 'No meal planned for today yet.';

  @override
  String get planOpenPlan => 'Open the plan';

  @override
  String get planMonthAndBudget => 'Month plan and budget';

  @override
  String get planShoppingItems => 'Shopping list';

  @override
  String get planTableWorthIt => 'A table worth gathering around';

  @override
  String get planPickMealHint =>
      'Pick a meal, and we\'ll show what\'s missing before you start.';

  @override
  String get planPickDishForTable => 'Pick a dish for the table';

  @override
  String get planComingDays => 'The table in the coming days';

  @override
  String get planNoDeductNote =>
      'Picking a meal doesn\'t take anything from your stock. That happens once you confirm you\'re done cooking.';

  @override
  String get planMealLoadError => 'Couldn\'t load this meal\'s recipe.';

  @override
  String planSlotServings(String slot, int servings) {
    String _temp0 = intl.Intl.pluralLogic(
      servings,
      locale: localeName,
      other: '$slot · $servings people',
      one: '$slot · 1 person',
    );
    return '$_temp0';
  }

  @override
  String get planCooked => 'Cooked';

  @override
  String planInStock(String count) {
    return '$count in stock';
  }

  @override
  String planMissingCount(String count) {
    return '$count missing';
  }

  @override
  String planOtherUnit(String count) {
    return '$count in another unit';
  }

  @override
  String planNoAmount(String count) {
    return '$count with no amount';
  }

  @override
  String get planBoughtMissing => 'Bought what\'s missing · Add to stock';

  @override
  String get planMissingAdded =>
      'Missing items added to stock in the amounts needed';

  @override
  String get planRemoveMeal => 'Remove the meal from the table';

  @override
  String planPerPortion(String kcal) {
    return 'Per person: $kcal kcal';
  }

  @override
  String planNutrient(String label, String grams) {
    return ' · $label $grams g';
  }

  @override
  String get planProtein => 'protein';

  @override
  String get planCarbs => 'carbs';

  @override
  String get planFat => 'fat';

  @override
  String get priceGroupVegetables => 'Vegetables';

  @override
  String get priceGroupFruit => 'Fruit';

  @override
  String get priceGroupProtein => 'Meat, poultry and fish';

  @override
  String get priceGroupDairy => 'Dairy and eggs';

  @override
  String get priceGroupGrains => 'Rice and grains';

  @override
  String get priceGroupLegumes => 'Legumes';

  @override
  String get priceGroupBread => 'Bread and baked goods';

  @override
  String get priceGroupOils => 'Oils and ghee';

  @override
  String get priceGroupSpices => 'Spices and seasonings';

  @override
  String get priceGroupSauces => 'Sauces and canned goods';

  @override
  String get priceGroupNuts => 'Nuts';

  @override
  String get priceGroupDrinks => 'Drinks';

  @override
  String get priceGroupOther => 'Other';

  @override
  String get priceLocationOff =>
      'Location is off. Pick your area on the map or search for it.';

  @override
  String get priceLocationDenied =>
      'Location access wasn\'t allowed. Pick your area on the map or search for it.';

  @override
  String get priceNoAreaNearby =>
      'We don\'t know an area near you. Pick one on the map.';

  @override
  String get priceLocateFailed =>
      'Couldn\'t find your location. Pick your area on the map or search for it.';

  @override
  String priceAreaNowYours(String area) {
    return 'Your area is now $area';
  }

  @override
  String get priceSearchArea => 'Search for an area or city';

  @override
  String get priceClear => 'Clear';

  @override
  String get priceNoResults => 'No results';

  @override
  String get priceChooseArea => 'Choose your area';

  @override
  String get priceMakeMyArea => 'Make it my area';

  @override
  String get priceAreaInfo =>
      'The area price is what people there paid in the last 60 days. It shows only when two or more homes share it.';

  @override
  String get priceAreaFetchFailed => 'Couldn\'t load the area\'s prices.';

  @override
  String get priceRetry => 'Try again';

  @override
  String get priceNoAreaHere => 'We don\'t know an area here. Try searching.';

  @override
  String get priceMyLocation => 'My location';

  @override
  String priceKnownInArea(String count) {
    return '$count with area price';
  }

  @override
  String get priceAreaColumn => 'Area price';

  @override
  String get priceYoursColumn => 'Your price';

  @override
  String get priceNoAreaPrice => 'No area price';

  @override
  String get priceAreaTapToUse => 'Area price, tap to make it yours';

  @override
  String get priceAddYours => 'Add your price';

  @override
  String get priceYoursTapToEdit => 'Your price, tap to edit';

  @override
  String get priceSaveFailed => 'Couldn\'t save the price. Try again.';

  @override
  String get priceSaved => 'Your price is saved';

  @override
  String get priceSavedShared =>
      'Your price is saved and shared with your area';

  @override
  String get priceSavedShareFailed =>
      'Your price is saved, but it couldn\'t be shared.';

  @override
  String get priceHint => 'Price';

  @override
  String get priceInvalid => 'Enter a price above zero';

  @override
  String priceShareWith(String area) {
    return 'Share it with $area';
  }

  @override
  String get priceCancel => 'Cancel';

  @override
  String get priceSave => 'Save';

  @override
  String get priceCurrencyEgp => 'EGP';

  @override
  String get priceCurrencySar => 'SAR';

  @override
  String get priceToday => 'Today';

  @override
  String get priceFridge => 'Fridge';

  @override
  String get profCountryEgypt => 'Egypt';

  @override
  String get profCountrySaudi => 'Saudi Arabia';

  @override
  String get profStatPeople => 'people';

  @override
  String get profStatMealsDaily => 'meals a day';

  @override
  String get profStatSaved => 'saved';

  @override
  String get profHousehold => 'Household';

  @override
  String get profHouseName => 'Home name';

  @override
  String profHouseHint(String name) {
    return '$name\'s home';
  }

  @override
  String get profYourName => 'Your name';

  @override
  String get profCountry => 'Country';

  @override
  String get profArea => 'Area';

  @override
  String get profAddArea => 'Add your area';

  @override
  String get profTableSize => 'People at the table';

  @override
  String get profTaste => 'Your taste';

  @override
  String get profCuisines => 'Cuisines';

  @override
  String get profAllCuisines => 'All cuisines';

  @override
  String get profMeals => 'Meals';

  @override
  String get profNoMeal => 'No meal chosen';

  @override
  String get profQuickFirst => 'Quick recipes first';

  @override
  String get profHealth => 'Health';

  @override
  String get profAllergies => 'Food allergies';

  @override
  String get profNoAllergies => 'No allergies';

  @override
  String get profAllergiesInfo =>
      'Shown as a name-only warning. Always check the ingredients yourself.';

  @override
  String get profConditions => 'Health conditions';

  @override
  String get profNoConditions => 'No conditions';

  @override
  String get profConditionsInfo =>
      'A reminder only. The app doesn\'t change recipes or give medical advice.';

  @override
  String get profCancel => 'Cancel';

  @override
  String get profSave => 'Save';

  @override
  String profRemove(String label) {
    return 'Remove $label';
  }

  @override
  String get profAdd => 'Add';

  @override
  String get profCountryCurrency => 'Country and currency';

  @override
  String get profReminders => 'Reminders';

  @override
  String get profSaving => 'Saving changes…';

  @override
  String get profUnsaved => 'Some changes aren\'t saved';

  @override
  String get profSignOut => 'Sign out';

  @override
  String get profFooter => 'Sofra · Made with love for homes';

  @override
  String get profMyAccount => 'My account';

  @override
  String get profAccountLine => 'Your account and home preferences';

  @override
  String get profAm => 'AM';

  @override
  String get profPm => 'PM';

  @override
  String get profMealTimesIntro =>
      'Set each meal\'s time and we\'ll remind you before it.';

  @override
  String get profNoReminder => 'No reminder';

  @override
  String get profClearReminder => 'Remove reminder';

  @override
  String profMealTimeOf(String meal) {
    return '$meal time';
  }

  @override
  String get profRemindBefore => 'Remind me ahead by';

  @override
  String profMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get profRanOutTitle => 'When an ingredient runs out';

  @override
  String get profRanOutSubtitle =>
      'A notice after cooking if you used the last of it';

  @override
  String get profChannelName => 'Sofra reminders';

  @override
  String get profChannelDescription =>
      'Meal times, leftovers and things that ran out';

  @override
  String profReminderMealTitle(String slot, String minutes) {
    return '$slot in $minutes min';
  }

  @override
  String profReminderMealBody(String meal) {
    return 'Planned: $meal. Time to start cooking.';
  }

  @override
  String profReminderLeftoverTitle(String dish) {
    return 'Leftover $dish in the fridge';
  }

  @override
  String profReminderLeftoverBody(String servings) {
    return '$servings left. Heat it up today.';
  }

  @override
  String get profServingOne => '1 serving';

  @override
  String profServings(String count) {
    return '$count servings';
  }

  @override
  String get profStyleCabinets => 'Cabinet style';

  @override
  String get profStyleClassic => 'Classic';

  @override
  String get profStyleModern => 'Modern';

  @override
  String get profStyleJapandi => 'Japandi';

  @override
  String get profStyleFridge => 'Fridge';

  @override
  String get profFridgeRetro => 'Cream retro';

  @override
  String get profFridgeDouble => 'Steel, two doors';

  @override
  String get profStyleRange => 'Stove';

  @override
  String get profRangeFreestanding => 'Freestanding stove';

  @override
  String get profRangeBuiltin => 'Built-in hob and oven';

  @override
  String get profStyleRug => 'Rug';

  @override
  String get profRugNone => 'No rug';

  @override
  String get profRugPersian => 'Red patterned';

  @override
  String get profRugTeal => 'Modern blue';

  @override
  String get profRugOchre => 'Warm kilim';

  @override
  String get profStyleCurtain => 'Curtain';

  @override
  String get profCurtainGingham => 'Gingham fabric';

  @override
  String get profCurtainBlind => 'White blinds';

  @override
  String get profCurtainNone => 'No curtain';

  @override
  String get profCabinetColor => 'Cabinet color';

  @override
  String get profColorOriginal => 'Original';

  @override
  String get profColorCream => 'Cream';

  @override
  String get profColorBlueGray => 'Blue gray';

  @override
  String get profColorTerracotta => 'Terracotta';

  @override
  String get profShotKitchen => 'Whole kitchen';

  @override
  String get profShotFridge => 'Open the fridge';

  @override
  String get profShotFreezer => 'Open the freezer';

  @override
  String get profExtras => 'Extras';

  @override
  String get profPlants => 'Hanging plants';

  @override
  String get profCane => 'Cane doors';

  @override
  String get addTitle => 'Add your shopping';

  @override
  String get addReadFailed =>
      'Couldn\'t read that. Check your connection, or type your purchases below.';

  @override
  String get addNothingFound =>
      'No ingredients found here. Try a clearer photo, or type them.';

  @override
  String get addCameraUnavailable =>
      'The camera isn\'t available. Allow it in your phone settings.';

  @override
  String get addPhotosFailed => 'Couldn\'t open your photos.';

  @override
  String get addMarkOne => 'Tick at least one item';

  @override
  String get addPickOne => 'Choose at least one ingredient';

  @override
  String addToKitchen(String count) {
    return 'Add $count to the kitchen';
  }

  @override
  String get addCameraTitle => 'Snap the receipt';

  @override
  String get addCameraDetail => 'With the camera';

  @override
  String get addGalleryTitle => 'From photos';

  @override
  String get addGalleryDetail => 'An order screenshot or a receipt';

  @override
  String get addTypeHint => 'Or type: 2 kg tomatoes';

  @override
  String get addLineTooltip => 'Add line';

  @override
  String get addSaveFailed =>
      'Your purchases weren\'t saved. Check your connection and try again.';

  @override
  String addSavedNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count ingredients to your kitchen',
      one: 'Added 1 ingredient to your kitchen',
    );
    return '$_temp0';
  }

  @override
  String get addRestart => 'Start over';

  @override
  String get addReading => 'Reading your purchases…';

  @override
  String addReadyCount(String count) {
    return '$count ready';
  }

  @override
  String addCheckCount(String count) {
    return '$count to check';
  }

  @override
  String addOpenCount(String count) {
    return '$count unmatched';
  }

  @override
  String get addAmountUnknown => 'Amount?';

  @override
  String get addChooseIngredient => 'Choose the ingredient';

  @override
  String get addRestore => 'Put back';

  @override
  String get addRemove => 'Remove';

  @override
  String get addWhichIngredient => 'Which ingredient is this?';

  @override
  String get addSearchHint => 'Rice, milk, oil…';

  @override
  String addAmountTitle(String name) {
    return 'Amount of $name';
  }

  @override
  String get addAmountHint => 'Amount';

  @override
  String get addSave => 'Save';

  @override
  String get addDontKnowAmount => 'I don\'t know the amount';

  @override
  String get addNotKnownYet => 'Not recognized yet';

  @override
  String addAsking(String text) {
    return 'Looking up “$text”…';
  }

  @override
  String get addScanTitle => 'Scan the product barcode';

  @override
  String get addScanCameraOff =>
      'The camera isn\'t available. Allow it in your phone settings, or type the number below.';

  @override
  String get addScanManualHint => 'Or type the number under the barcode';

  @override
  String get addScanGo => 'Search';

  @override
  String get addScanUnknownProduct => 'This product isn\'t in our data yet';

  @override
  String addScanPackage(String size) {
    return 'Pack: $size';
  }

  @override
  String get addScanWhich =>
      'Which ingredient in your kitchen is this? We\'ll remember it next time.';

  @override
  String get addScanSearchHint => 'Type the ingredient name (rice, milk, oil…)';

  @override
  String get rcpSaveRecipe => 'Save recipe';

  @override
  String get rcpUnsaveRecipe => 'Remove from saved';

  @override
  String get rcpFilterAll => 'All';

  @override
  String get rcpFilterFromStock => 'From my pantry';

  @override
  String get rcpFilterReadyFromStock => 'Ready with my pantry';

  @override
  String get rcpFilterSaved => 'Saved';

  @override
  String get rcpKindSection => 'Type';

  @override
  String get rcpTimeSection => 'Time';

  @override
  String get rcpTimeAny => 'Any time';

  @override
  String get rcpTime30 => '30 minutes or less';

  @override
  String get rcpTime60 => '1 hour or less';

  @override
  String get rcpClearFilters => 'Clear filters';

  @override
  String get rcpSearchHint => 'Search by dish or ingredient';

  @override
  String get rcpFilters => 'Filters';

  @override
  String get rcpAllCuisines => 'All cuisines';

  @override
  String rcpStockNote(String servings) {
    return 'Amounts are for $servings people. Unknown amounts don\'t count as ready.';
  }

  @override
  String get rcpLoadFailed => 'Couldn\'t load recipes.';

  @override
  String get rcpTryAgain => 'Try again';

  @override
  String get rcpFromStockTitle => 'Ideas from your pantry';

  @override
  String get rcpForYouTitle => 'Recipes you\'ll like';

  @override
  String rcpRecipeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
    );
    return '$_temp0';
  }

  @override
  String get rcpEmptyTitle => 'Looking for something else?';

  @override
  String get rcpShowAll => 'Show all recipes';

  @override
  String rcpShowMore(String count) {
    return 'Show $count more';
  }

  @override
  String get appRetrySave => 'Save again';

  @override
  String get appLoadFailed =>
      'Couldn\'t load your home\'s data. Nothing was deleted.';

  @override
  String get appTryAgain => 'Try again';

  @override
  String get appBack => 'Back';

  @override
  String get appViewAddStock => 'Stock up';

  @override
  String get appViewRecipe => 'A recipe sized for you';

  @override
  String get appViewKitchen3d => 'My 3D kitchen';

  @override
  String get appViewCooking => 'Let\'s cook';

  @override
  String get appUnsaveRecipe => 'Unsave';

  @override
  String get appSaveRecipe => 'Save recipe';

  @override
  String get appHeaderToday => 'Sofra';

  @override
  String get appTabRecipes => 'Recipes';

  @override
  String get appTabStock => 'Pantry';

  @override
  String get appTabPlan => 'Plan';

  @override
  String get appTabAccount => 'My account';

  @override
  String get appTabSettings => 'Settings';

  @override
  String get appTabStyle => 'Kitchen style';

  @override
  String get appTabToday => 'Today';

  @override
  String get appCommunity => 'Community';

  @override
  String get appMemoryStoreLabel => 'Not saved (demo)';

  @override
  String get appDefaultName => 'Host';

  @override
  String appDefaultHouse(String name) {
    return '$name\'s home';
  }

  @override
  String get appMealFallback => 'Meal';

  @override
  String get appSaveFull =>
      'Your account\'s storage is full, so the change wasn\'t saved.';

  @override
  String get appSaveFailedOne =>
      'Your last change wasn\'t saved. Check your connection and save again before you leave.';

  @override
  String appSaveFailedMany(String count) {
    return 'Unsaved changes: $count. Check your connection and save again before you leave.';
  }

  @override
  String get appShoppingListHeader => 'Shopping list from Sofra:';

  @override
  String get appRanOutTitle => 'Ran out in the kitchen';

  @override
  String appRanOutBody(String items) {
    return '$items. Add them to your shopping list.';
  }

  @override
  String get appListSeparator => ', ';

  @override
  String get appSessionOpenFailed =>
      'Can\'t open your data right now. Check your connection and try again.';

  @override
  String get appRetry => 'Retry';

  @override
  String get appSignOut => 'Sign out';

  @override
  String get appEnterEmailFirst => 'Enter your email first.';

  @override
  String get appResetSent =>
      'If this email has an account, you\'ll get a link to reset your password.';

  @override
  String get appAuthNetwork => 'Check your internet connection and try again.';

  @override
  String get appAuthTooMany => 'Too many tries. Wait a bit, then try again.';

  @override
  String get appAuthWeakPassword => 'Choose a stronger password.';

  @override
  String get appAuthEmailInUse =>
      'This email already has an account. Try signing in.';

  @override
  String get appAuthInvalidEmail => 'Check how the email is written.';

  @override
  String get appAuthSignUpUnavailable =>
      'Creating an account isn\'t available right now. Try later.';

  @override
  String get appAuthFailed =>
      'Couldn\'t sign in. Check your email and password, or recover your account.';

  @override
  String get appRequestFailed => 'Couldn\'t finish that. Try again.';

  @override
  String get appCreateAccountTitle => 'Create an account for your Sofra';

  @override
  String get appWelcome => 'Welcome to Sofra';

  @override
  String get appSignInSubtitle =>
      'Your home\'s ingredients and choices are kept in your account.';

  @override
  String get appEmailLabel => 'Email';

  @override
  String get appEmailInvalid => 'Enter a valid email';

  @override
  String get appPasswordLabel => 'Password';

  @override
  String get appPasswordShort => 'Password must be at least 6 characters';

  @override
  String get appWait => 'One moment…';

  @override
  String get appCreateAccount => 'Create account';

  @override
  String get appSignIn => 'Sign in';

  @override
  String get appHaveAccount => 'I already have an account';

  @override
  String get appFirstTime => 'First time? Create an account';

  @override
  String get appForgotPassword => 'Forgot password';

  @override
  String get appSavedOnDevice => 'Saved on this device';

  @override
  String get appSavedInAccount => 'Saved in your account';

  @override
  String get appSavedInSharedKitchen => 'Saved in the shared kitchen';

  @override
  String get appInviteNotFound => 'This code doesn\'t exist.';

  @override
  String get appInviteExpired => 'This code has expired. Ask for a new one.';

  @override
  String appChallengeCookPlannedTitle(String goal) {
    return 'Cook $goal meals from your plan';
  }

  @override
  String get appChallengeCookPlannedDetail =>
      'Every planned meal cooked this week counts.';

  @override
  String appChallengeDifferentTitle(String goal) {
    return 'Mix it up: $goal different dishes';
  }

  @override
  String get appChallengeDifferentDetail =>
      'Each different recipe cooked this week counts once.';

  @override
  String get appChallengeNewTitle => 'Try 2 recipes for the first time';

  @override
  String get appChallengeNewDetail =>
      'A recipe never cooked in your kitchen before.';

  @override
  String get appHouseMember => 'Household member';

  @override
  String get appChefCelebrate => 'Sofra\'s chef, happy and ready to cook';

  @override
  String get appChefIdle => 'Sofra\'s chef, a cheerful tomato in a chef\'s hat';

  @override
  String get dataToTaste => 'to taste';

  @override
  String get kitchen3dAlt => '3D kitchen';

  @override
  String get librarySection => 'Recipes on your device';

  @override
  String get libraryInfo =>
      'The recipe list is always on your device. A full recipe is kept once you open or save it, and saved ones also stay in your account even if the library drops them. New recipes arrive on their own, without an app update.';

  @override
  String get libraryOnDevice => 'On device';

  @override
  String get librarySaved => 'Saved';

  @override
  String get librarySize => 'Storage';

  @override
  String librarySizeValue(String value) {
    return '$value MB';
  }

  @override
  String libraryUpdated(String date) {
    return 'Library updated: $date';
  }

  @override
  String get libraryUpdateNow => 'Update now';

  @override
  String get libraryUpdating => 'Updating…';

  @override
  String get libraryUpToDate => 'Library is up to date';

  @override
  String get libraryUpdateFailed => 'Couldn\'t reach the library';

  @override
  String get recipeNotOnDevice =>
      'This recipe isn\'t on your device yet. Connect to the internet and try again.';

  @override
  String get recipeRetry => 'Try again';
}
