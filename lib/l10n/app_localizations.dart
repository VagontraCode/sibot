import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Sibot Engineering'**
  String get appTitle;

  /// No description provided for @brandName.
  ///
  /// In en, this message translates to:
  /// **'Sibot'**
  String get brandName;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get brandTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get navProjects;

  /// No description provided for @navField.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get navField;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @commonSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get commonSwitch;

  /// No description provided for @commonProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get commonProject;

  /// No description provided for @commonProjectEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get commonProjectEyebrow;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get commonSaving;

  /// No description provided for @commonUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get commonUntitled;

  /// No description provided for @commonPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get commonPlanned;

  /// No description provided for @commonPhase.
  ///
  /// In en, this message translates to:
  /// **'Phase {n}'**
  String commonPhase(int n);

  /// No description provided for @commonBeta.
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get commonBeta;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get commonReview;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String timeHoursAgo(int n);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} d ago'**
  String timeDaysAgo(int n);

  /// No description provided for @timeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {when}'**
  String timeUpdated(String when);

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get statusArchived;

  /// No description provided for @statusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statusAll;

  /// No description provided for @dashGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get dashGreetingMorning;

  /// No description provided for @dashGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get dashGreetingAfternoon;

  /// No description provided for @dashGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get dashGreetingEvening;

  /// No description provided for @dashHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Model, analyse and design,\nright from the site.'**
  String get dashHeroTitle;

  /// No description provided for @dashNewProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get dashNewProject;

  /// No description provided for @dashOpenProjects.
  ///
  /// In en, this message translates to:
  /// **'Open projects'**
  String get dashOpenProjects;

  /// No description provided for @dashStatProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get dashStatProjects;

  /// No description provided for @dashStatCalculations.
  ///
  /// In en, this message translates to:
  /// **'Calculations'**
  String get dashStatCalculations;

  /// No description provided for @dashStatModules.
  ///
  /// In en, this message translates to:
  /// **'Design modules'**
  String get dashStatModules;

  /// No description provided for @dashStatRoadmap.
  ///
  /// In en, this message translates to:
  /// **'On the roadmap'**
  String get dashStatRoadmap;

  /// No description provided for @dashRecentProjects.
  ///
  /// In en, this message translates to:
  /// **'Recent projects'**
  String get dashRecentProjects;

  /// No description provided for @dashDesignModules.
  ///
  /// In en, this message translates to:
  /// **'Design modules'**
  String get dashDesignModules;

  /// No description provided for @dashDesignModulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reinforced concrete, Eurocode 2 and BAEL'**
  String get dashDesignModulesSubtitle;

  /// No description provided for @dashRoadmap.
  ///
  /// In en, this message translates to:
  /// **'Roadmap'**
  String get dashRoadmap;

  /// No description provided for @dashRoadmapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis, steel, timber, masonry and more'**
  String get dashRoadmapSubtitle;

  /// No description provided for @dashOpenModuleIn.
  ///
  /// In en, this message translates to:
  /// **'Open {module} in…'**
  String dashOpenModuleIn(String module);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language, appearance and design defaults.'**
  String get settingsSubtitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsDefaultCode.
  ///
  /// In en, this message translates to:
  /// **'Default design code'**
  String get settingsDefaultCode;

  /// No description provided for @settingsDefaultCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Used when you open a design module.'**
  String get settingsDefaultCodeHelp;

  /// No description provided for @projectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every calculation, photo and report, grouped by project.'**
  String get projectsSubtitle;

  /// No description provided for @projectsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load projects'**
  String get projectsLoadError;

  /// No description provided for @projectsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get projectsEmptyTitle;

  /// No description provided for @projectsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a project to keep its calculations and field data together.'**
  String get projectsEmptyMessage;

  /// No description provided for @projectsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, location or engineer'**
  String get projectsSearchHint;

  /// No description provided for @projectsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching projects'**
  String get projectsNoMatch;

  /// No description provided for @projectUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled project'**
  String get projectUntitled;

  /// No description provided for @projectFormNew.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectFormNew;

  /// No description provided for @projectFormEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get projectFormEdit;

  /// No description provided for @projectFormName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectFormName;

  /// No description provided for @projectFormNameError.
  ///
  /// In en, this message translates to:
  /// **'Give the project a name'**
  String get projectFormNameError;

  /// No description provided for @projectFormLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get projectFormLocation;

  /// No description provided for @projectFormEngineer.
  ///
  /// In en, this message translates to:
  /// **'Engineer'**
  String get projectFormEngineer;

  /// No description provided for @projectFormDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get projectFormDescription;

  /// No description provided for @projectFormStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get projectFormStatus;

  /// No description provided for @projectFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get projectFormSave;

  /// No description provided for @projectFormCreate.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get projectFormCreate;

  /// No description provided for @projectPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a project'**
  String get projectPickerTitle;

  /// No description provided for @projectLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load project'**
  String get projectLoadError;

  /// No description provided for @projectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Project not found'**
  String get projectNotFound;

  /// No description provided for @projectNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted.'**
  String get projectNotFoundMessage;

  /// No description provided for @projectExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get projectExportPdf;

  /// No description provided for @projectEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get projectEdit;

  /// No description provided for @projectDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get projectDelete;

  /// No description provided for @projectDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete project?'**
  String get projectDeleteTitle;

  /// No description provided for @projectDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed from this device. Its saved calculations and field data stay in storage but will no longer be listed.'**
  String projectDeleteMessage(String name);

  /// No description provided for @projectDesignModules.
  ///
  /// In en, this message translates to:
  /// **'Design modules'**
  String get projectDesignModules;

  /// No description provided for @projectField.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get projectField;

  /// No description provided for @projectCalculations.
  ///
  /// In en, this message translates to:
  /// **'Calculations'**
  String get projectCalculations;

  /// No description provided for @projectCalcLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load calculations'**
  String get projectCalcLoadError;

  /// No description provided for @projectCalcEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No calculations yet'**
  String get projectCalcEmptyTitle;

  /// No description provided for @projectCalcEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Results you calculate in a module are saved here.'**
  String get projectCalcEmptyMessage;

  /// No description provided for @countPhotos.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{no photos} =1{1 photo} other{{n} photos}}'**
  String countPhotos(int n);

  /// No description provided for @countReports.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{no reports} =1{1 report} other{{n} reports}}'**
  String countReports(int n);

  /// No description provided for @countOpen.
  ///
  /// In en, this message translates to:
  /// **'{n} open'**
  String countOpen(int n);

  /// No description provided for @catAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Structural analysis'**
  String get catAnalysis;

  /// No description provided for @catConcrete.
  ///
  /// In en, this message translates to:
  /// **'Reinforced concrete'**
  String get catConcrete;

  /// No description provided for @catSteel.
  ///
  /// In en, this message translates to:
  /// **'Steel'**
  String get catSteel;

  /// No description provided for @catTimber.
  ///
  /// In en, this message translates to:
  /// **'Timber'**
  String get catTimber;

  /// No description provided for @catMasonry.
  ///
  /// In en, this message translates to:
  /// **'Masonry'**
  String get catMasonry;

  /// No description provided for @catGeotech.
  ///
  /// In en, this message translates to:
  /// **'Geotechnics'**
  String get catGeotech;

  /// No description provided for @catLoads.
  ///
  /// In en, this message translates to:
  /// **'Loads'**
  String get catLoads;

  /// No description provided for @catTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get catTools;

  /// No description provided for @modFrame2d.
  ///
  /// In en, this message translates to:
  /// **'2D Frame Analysis'**
  String get modFrame2d;

  /// No description provided for @modFrame2dSub.
  ///
  /// In en, this message translates to:
  /// **'Frames, trusses, continuous beams'**
  String get modFrame2dSub;

  /// No description provided for @modFrame3d.
  ///
  /// In en, this message translates to:
  /// **'3D Frame Analysis'**
  String get modFrame3d;

  /// No description provided for @modFrame3dSub.
  ///
  /// In en, this message translates to:
  /// **'Space frames, modal analysis'**
  String get modFrame3dSub;

  /// No description provided for @modBeam.
  ///
  /// In en, this message translates to:
  /// **'Beam'**
  String get modBeam;

  /// No description provided for @modBeamSub.
  ///
  /// In en, this message translates to:
  /// **'Bending, shear'**
  String get modBeamSub;

  /// No description provided for @modColumn.
  ///
  /// In en, this message translates to:
  /// **'Column'**
  String get modColumn;

  /// No description provided for @modColumnSub.
  ///
  /// In en, this message translates to:
  /// **'N–M, slenderness'**
  String get modColumnSub;

  /// No description provided for @modSlab.
  ///
  /// In en, this message translates to:
  /// **'Slab'**
  String get modSlab;

  /// No description provided for @modSlabSub.
  ///
  /// In en, this message translates to:
  /// **'One-way, two-way'**
  String get modSlabSub;

  /// No description provided for @modFooting.
  ///
  /// In en, this message translates to:
  /// **'Footing'**
  String get modFooting;

  /// No description provided for @modFootingSub.
  ///
  /// In en, this message translates to:
  /// **'Pad footing, punching'**
  String get modFootingSub;

  /// No description provided for @modRetainingWall.
  ///
  /// In en, this message translates to:
  /// **'Retaining Wall'**
  String get modRetainingWall;

  /// No description provided for @modRetainingWallSub.
  ///
  /// In en, this message translates to:
  /// **'Stability, pre-sizing'**
  String get modRetainingWallSub;

  /// No description provided for @modSteelMember.
  ///
  /// In en, this message translates to:
  /// **'Steel Member'**
  String get modSteelMember;

  /// No description provided for @modSteelMemberSub.
  ///
  /// In en, this message translates to:
  /// **'EC3 checks, buckling'**
  String get modSteelMemberSub;

  /// No description provided for @modTimberMember.
  ///
  /// In en, this message translates to:
  /// **'Timber Member'**
  String get modTimberMember;

  /// No description provided for @modTimberMemberSub.
  ///
  /// In en, this message translates to:
  /// **'EC5 checks'**
  String get modTimberMemberSub;

  /// No description provided for @modMasonryWall.
  ///
  /// In en, this message translates to:
  /// **'Masonry Wall'**
  String get modMasonryWall;

  /// No description provided for @modMasonryWallSub.
  ///
  /// In en, this message translates to:
  /// **'EC6 vertical capacity'**
  String get modMasonryWallSub;

  /// No description provided for @modBearing.
  ///
  /// In en, this message translates to:
  /// **'Bearing & Settlement'**
  String get modBearing;

  /// No description provided for @modBearingSub.
  ///
  /// In en, this message translates to:
  /// **'EC7 soil checks'**
  String get modBearingSub;

  /// No description provided for @modSlope.
  ///
  /// In en, this message translates to:
  /// **'Slope Stability'**
  String get modSlope;

  /// No description provided for @modSlopeSub.
  ///
  /// In en, this message translates to:
  /// **'Factor of safety'**
  String get modSlopeSub;

  /// No description provided for @modWindSnow.
  ///
  /// In en, this message translates to:
  /// **'Wind & Snow'**
  String get modWindSnow;

  /// No description provided for @modWindSnowSub.
  ///
  /// In en, this message translates to:
  /// **'EC1 actions'**
  String get modWindSnowSub;

  /// No description provided for @modSeismic.
  ///
  /// In en, this message translates to:
  /// **'Seismic'**
  String get modSeismic;

  /// No description provided for @modSeismicSub.
  ///
  /// In en, this message translates to:
  /// **'EC8 / PS92 spectra'**
  String get modSeismicSub;

  /// No description provided for @modSections.
  ///
  /// In en, this message translates to:
  /// **'Section Properties'**
  String get modSections;

  /// No description provided for @modSectionsSub.
  ///
  /// In en, this message translates to:
  /// **'A, I, W, i'**
  String get modSectionsSub;

  /// No description provided for @modQuantities.
  ///
  /// In en, this message translates to:
  /// **'Quantities'**
  String get modQuantities;

  /// No description provided for @modQuantitiesSub.
  ///
  /// In en, this message translates to:
  /// **'Concrete, rebar take-off'**
  String get modQuantitiesSub;

  /// No description provided for @modPileCap.
  ///
  /// In en, this message translates to:
  /// **'Pile Cap'**
  String get modPileCap;

  /// No description provided for @modPileCapSub.
  ///
  /// In en, this message translates to:
  /// **'Pile group, cap design'**
  String get modPileCapSub;

  /// No description provided for @modSeptic.
  ///
  /// In en, this message translates to:
  /// **'Septic Tank'**
  String get modSeptic;

  /// No description provided for @modSepticSub.
  ///
  /// In en, this message translates to:
  /// **'Volume sizing'**
  String get modSepticSub;

  /// No description provided for @modPlannedFor.
  ///
  /// In en, this message translates to:
  /// **'{module} is planned for Phase {phase} of the roadmap.'**
  String modPlannedFor(String module, int phase);

  /// No description provided for @calcCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calcCalculate;

  /// No description provided for @calcCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get calcCalculating;

  /// No description provided for @calcCheckInputs.
  ///
  /// In en, this message translates to:
  /// **'Check the inputs'**
  String get calcCheckInputs;

  /// No description provided for @calcBetaTitle.
  ///
  /// In en, this message translates to:
  /// **'Beta: independent verification pending'**
  String get calcBetaTitle;

  /// No description provided for @calcBetaMessage.
  ///
  /// In en, this message translates to:
  /// **'Calculations follow the cited clauses and pass hand-calculation tests, but have not yet been checked against published worked examples or RSA. Verify results before using them for construction.'**
  String get calcBetaMessage;

  /// No description provided for @calcResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get calcResults;

  /// No description provided for @calcResultsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Fill in the parameters and tap Calculate.'**
  String get calcResultsPlaceholder;

  /// No description provided for @calcMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get calcMaterials;

  /// No description provided for @calcConcreteFck.
  ///
  /// In en, this message translates to:
  /// **'Concrete fck'**
  String get calcConcreteFck;

  /// No description provided for @calcSteelFyk.
  ///
  /// In en, this message translates to:
  /// **'Steel fyk'**
  String get calcSteelFyk;

  /// No description provided for @calcSpan.
  ///
  /// In en, this message translates to:
  /// **'Span'**
  String get calcSpan;

  /// No description provided for @beamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rectangular section: bending, shear and deflection.'**
  String get beamSubtitle;

  /// No description provided for @beamGeometryLoad.
  ///
  /// In en, this message translates to:
  /// **'Geometry & load'**
  String get beamGeometryLoad;

  /// No description provided for @beamWidth.
  ///
  /// In en, this message translates to:
  /// **'Width b'**
  String get beamWidth;

  /// No description provided for @beamDepth.
  ///
  /// In en, this message translates to:
  /// **'Depth h'**
  String get beamDepth;

  /// No description provided for @beamBending.
  ///
  /// In en, this message translates to:
  /// **'Bending reinforcement'**
  String get beamBending;

  /// No description provided for @beamSteelRequired.
  ///
  /// In en, this message translates to:
  /// **'Steel area required'**
  String get beamSteelRequired;

  /// No description provided for @beamMomentRatio.
  ///
  /// In en, this message translates to:
  /// **'Moment ratio'**
  String get beamMomentRatio;

  /// No description provided for @columnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rectangular column: axial force, bending and slenderness.'**
  String get columnSubtitle;

  /// No description provided for @columnLoadGeometry.
  ///
  /// In en, this message translates to:
  /// **'Load & geometry'**
  String get columnLoadGeometry;

  /// No description provided for @columnAxialLoad.
  ///
  /// In en, this message translates to:
  /// **'Axial load'**
  String get columnAxialLoad;

  /// No description provided for @slabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-way or two-way slab, simple or continuous.'**
  String get slabSubtitle;

  /// No description provided for @slabSpanLoad.
  ///
  /// In en, this message translates to:
  /// **'Span & load'**
  String get slabSpanLoad;

  /// No description provided for @footingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pad footing under a column: sizing, steel and punching.'**
  String get footingSubtitle;

  /// No description provided for @footingDesignBasis.
  ///
  /// In en, this message translates to:
  /// **'Design basis'**
  String get footingDesignBasis;

  /// No description provided for @footingCode.
  ///
  /// In en, this message translates to:
  /// **'Design code'**
  String get footingCode;

  /// No description provided for @codeEurocode.
  ///
  /// In en, this message translates to:
  /// **'Eurocode'**
  String get codeEurocode;

  /// No description provided for @codeBael.
  ///
  /// In en, this message translates to:
  /// **'BAEL 99'**
  String get codeBael;

  /// No description provided for @footingColumnActions.
  ///
  /// In en, this message translates to:
  /// **'Column actions'**
  String get footingColumnActions;

  /// No description provided for @footingSoil.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get footingSoil;

  /// No description provided for @footingUnitWeight.
  ///
  /// In en, this message translates to:
  /// **'Unit weight'**
  String get footingUnitWeight;

  /// No description provided for @footingDimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get footingDimensions;

  /// No description provided for @footingLxB.
  ///
  /// In en, this message translates to:
  /// **'Length × width'**
  String get footingLxB;

  /// No description provided for @footingThickness.
  ///
  /// In en, this message translates to:
  /// **'Thickness'**
  String get footingThickness;

  /// No description provided for @footingReinforcement.
  ///
  /// In en, this message translates to:
  /// **'Reinforcement'**
  String get footingReinforcement;

  /// No description provided for @wallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cantilever wall: stability and stem reinforcement.'**
  String get wallSubtitle;

  /// No description provided for @wallWallSoil.
  ///
  /// In en, this message translates to:
  /// **'Wall & soil'**
  String get wallWallSoil;

  /// No description provided for @wallRetainedHeight.
  ///
  /// In en, this message translates to:
  /// **'Retained height'**
  String get wallRetainedHeight;

  /// No description provided for @wallSoilUnitWeight.
  ///
  /// In en, this message translates to:
  /// **'Soil unit weight'**
  String get wallSoilUnitWeight;

  /// No description provided for @wallFrictionAngle.
  ///
  /// In en, this message translates to:
  /// **'Friction angle φ'**
  String get wallFrictionAngle;

  /// No description provided for @wallStability.
  ///
  /// In en, this message translates to:
  /// **'Stability'**
  String get wallStability;

  /// No description provided for @wallFosOverturning.
  ///
  /// In en, this message translates to:
  /// **'Factor of safety, overturning'**
  String get wallFosOverturning;

  /// No description provided for @wallActiveThrust.
  ///
  /// In en, this message translates to:
  /// **'Active earth thrust'**
  String get wallActiveThrust;

  /// No description provided for @wallBaseThickness.
  ///
  /// In en, this message translates to:
  /// **'Base thickness'**
  String get wallBaseThickness;

  /// No description provided for @fieldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photos, daily reports and punch lists from the site.'**
  String get fieldSubtitle;

  /// No description provided for @fieldEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Field data is filed under a project. Create one first.'**
  String get fieldEmptyMessage;

  /// No description provided for @fieldTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get fieldTools;

  /// No description provided for @fieldPhotosCaption.
  ///
  /// In en, this message translates to:
  /// **'photos'**
  String get fieldPhotosCaption;

  /// No description provided for @fieldReportsCaption.
  ///
  /// In en, this message translates to:
  /// **'reports'**
  String get fieldReportsCaption;

  /// No description provided for @fieldOpenItemsCaption.
  ///
  /// In en, this message translates to:
  /// **'open items'**
  String get fieldOpenItemsCaption;

  /// No description provided for @photoLog.
  ///
  /// In en, this message translates to:
  /// **'Photo log'**
  String get photoLog;

  /// No description provided for @photoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get photoAdd;

  /// No description provided for @photoLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load photos'**
  String get photoLoadError;

  /// No description provided for @photoEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get photoEmptyTitle;

  /// No description provided for @photoEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Document progress, defects and rebar before pours.'**
  String get photoEmptyMessage;

  /// No description provided for @photoCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get photoCamera;

  /// No description provided for @photoGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get photoGallery;

  /// No description provided for @photoDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get photoDescription;

  /// No description provided for @photoLocation.
  ///
  /// In en, this message translates to:
  /// **'Location on site'**
  String get photoLocation;

  /// No description provided for @photoLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grid B-3, level 2'**
  String get photoLocationHint;

  /// No description provided for @photoSave.
  ///
  /// In en, this message translates to:
  /// **'Save photo'**
  String get photoSave;

  /// No description provided for @reportDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily reports'**
  String get reportDaily;

  /// No description provided for @reportNew.
  ///
  /// In en, this message translates to:
  /// **'New report'**
  String get reportNew;

  /// No description provided for @reportLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load reports'**
  String get reportLoadError;

  /// No description provided for @reportEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get reportEmptyTitle;

  /// No description provided for @reportEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Log weather, workforce, progress and safety each day.'**
  String get reportEmptyMessage;

  /// No description provided for @reportNoSummary.
  ///
  /// In en, this message translates to:
  /// **'No summary'**
  String get reportNoSummary;

  /// No description provided for @reportWorkers.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 worker} other{{n} workers}}'**
  String reportWorkers(int n);

  /// No description provided for @reportWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get reportWeather;

  /// No description provided for @reportWorkersOnSite.
  ///
  /// In en, this message translates to:
  /// **'Workers on site'**
  String get reportWorkersOnSite;

  /// No description provided for @reportWorkersField.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get reportWorkersField;

  /// No description provided for @reportProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get reportProgress;

  /// No description provided for @reportSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get reportSafety;

  /// No description provided for @reportSafetyNotes.
  ///
  /// In en, this message translates to:
  /// **'Safety notes'**
  String get reportSafetyNotes;

  /// No description provided for @reportDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily report'**
  String get reportDailyTitle;

  /// No description provided for @reportSave.
  ///
  /// In en, this message translates to:
  /// **'Save report'**
  String get reportSave;

  /// No description provided for @punchList.
  ///
  /// In en, this message translates to:
  /// **'Punch list'**
  String get punchList;

  /// No description provided for @punchAdd.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get punchAdd;

  /// No description provided for @punchLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the punch list'**
  String get punchLoadError;

  /// No description provided for @punchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to fix yet'**
  String get punchEmptyTitle;

  /// No description provided for @punchEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Track defects and snags until they are closed out.'**
  String get punchEmptyMessage;

  /// No description provided for @punchOpenTab.
  ///
  /// In en, this message translates to:
  /// **'Open · {n}'**
  String punchOpenTab(int n);

  /// No description provided for @punchClosedTab.
  ///
  /// In en, this message translates to:
  /// **'Closed · {n}'**
  String punchClosedTab(int n);

  /// No description provided for @punchNothingClosed.
  ///
  /// In en, this message translates to:
  /// **'Nothing closed yet'**
  String get punchNothingClosed;

  /// No description provided for @punchAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get punchAllClear;

  /// No description provided for @punchSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to close an item, left to delete it.'**
  String get punchSwipeHint;

  /// No description provided for @punchAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}'**
  String punchAssignedTo(String name);

  /// No description provided for @punchNew.
  ///
  /// In en, this message translates to:
  /// **'New punch item'**
  String get punchNew;

  /// No description provided for @punchWhat.
  ///
  /// In en, this message translates to:
  /// **'What needs fixing?'**
  String get punchWhat;

  /// No description provided for @punchAssignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get punchAssignedLabel;

  /// No description provided for @punchPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get punchPriority;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @reportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PDF calculation notes and site records.'**
  String get reportsSubtitle;

  /// No description provided for @reportsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Reports are generated per project.'**
  String get reportsEmptyMessage;

  /// No description provided for @reportsGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get reportsGenerate;

  /// No description provided for @reportsSummary.
  ///
  /// In en, this message translates to:
  /// **'Project summary'**
  String get reportsSummary;

  /// No description provided for @reportsSummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Footing and beam calculations, and the punch list, in one PDF.'**
  String get reportsSummaryDesc;

  /// No description provided for @reportsCalcNotes.
  ///
  /// In en, this message translates to:
  /// **'Calculation notes'**
  String get reportsCalcNotes;

  /// No description provided for @reportsCalcNotesDesc.
  ///
  /// In en, this message translates to:
  /// **'Formulas, code clauses and diagrams for each module.'**
  String get reportsCalcNotesDesc;

  /// No description provided for @reportsFieldAudit.
  ///
  /// In en, this message translates to:
  /// **'Field audit'**
  String get reportsFieldAudit;

  /// No description provided for @reportsFieldAuditDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily reports, photos and punch list.'**
  String get reportsFieldAuditDesc;

  /// No description provided for @librarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Design codes, material data and quick tools.'**
  String get librarySubtitle;

  /// No description provided for @libraryConverter.
  ///
  /// In en, this message translates to:
  /// **'Unit converter'**
  String get libraryConverter;

  /// No description provided for @libraryLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get libraryLength;

  /// No description provided for @libraryForce.
  ///
  /// In en, this message translates to:
  /// **'Force'**
  String get libraryForce;

  /// No description provided for @libraryPressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get libraryPressure;

  /// No description provided for @libraryValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get libraryValue;

  /// No description provided for @librarySwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get librarySwap;

  /// No description provided for @libraryMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get libraryMaterials;

  /// No description provided for @libraryConcrete.
  ///
  /// In en, this message translates to:
  /// **'Concrete'**
  String get libraryConcrete;

  /// No description provided for @librarySteel.
  ///
  /// In en, this message translates to:
  /// **'Structural steel'**
  String get librarySteel;

  /// No description provided for @libraryRebar.
  ///
  /// In en, this message translates to:
  /// **'Reinforcing bars'**
  String get libraryRebar;

  /// No description provided for @libraryTable.
  ///
  /// In en, this message translates to:
  /// **'{code}, Table {table}'**
  String libraryTable(String code, String table);

  /// No description provided for @libraryRebarSource.
  ///
  /// In en, this message translates to:
  /// **'Area πd²/4, mass at 7850 kg/m³'**
  String get libraryRebarSource;

  /// No description provided for @libraryColClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get libraryColClass;

  /// No description provided for @libraryColGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get libraryColGrade;

  /// No description provided for @libraryColArea.
  ///
  /// In en, this message translates to:
  /// **'Area mm²'**
  String get libraryColArea;

  /// No description provided for @libraryColMass.
  ///
  /// In en, this message translates to:
  /// **'Mass kg/m'**
  String get libraryColMass;

  /// No description provided for @libraryCodes.
  ///
  /// In en, this message translates to:
  /// **'Design codes'**
  String get libraryCodes;

  /// No description provided for @libraryCodesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Codes the suite is being built to support'**
  String get libraryCodesSubtitle;

  /// No description provided for @codeEc0.
  ///
  /// In en, this message translates to:
  /// **'Basis of design, combinations'**
  String get codeEc0;

  /// No description provided for @codeEc1.
  ///
  /// In en, this message translates to:
  /// **'Actions: loads, wind, snow'**
  String get codeEc1;

  /// No description provided for @codeEc2.
  ///
  /// In en, this message translates to:
  /// **'Concrete structures'**
  String get codeEc2;

  /// No description provided for @codeEc3.
  ///
  /// In en, this message translates to:
  /// **'Steel structures'**
  String get codeEc3;

  /// No description provided for @codeEc5.
  ///
  /// In en, this message translates to:
  /// **'Timber structures'**
  String get codeEc5;

  /// No description provided for @codeEc6.
  ///
  /// In en, this message translates to:
  /// **'Masonry structures'**
  String get codeEc6;

  /// No description provided for @codeEc7.
  ///
  /// In en, this message translates to:
  /// **'Geotechnical design'**
  String get codeEc7;

  /// No description provided for @codeEc8.
  ///
  /// In en, this message translates to:
  /// **'Earthquake resistance'**
  String get codeEc8;

  /// No description provided for @codeBaelDesc.
  ///
  /// In en, this message translates to:
  /// **'Reinforced concrete (FR)'**
  String get codeBaelDesc;

  /// No description provided for @codePs92Desc.
  ///
  /// In en, this message translates to:
  /// **'Seismic rules (FR)'**
  String get codePs92Desc;

  /// No description provided for @calcCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get calcCover;

  /// No description provided for @loadPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent load g'**
  String get loadPermanent;

  /// No description provided for @loadVariable.
  ///
  /// In en, this message translates to:
  /// **'Variable load q'**
  String get loadVariable;

  /// No description provided for @loadPermanentArea.
  ///
  /// In en, this message translates to:
  /// **'Permanent load g'**
  String get loadPermanentArea;

  /// No description provided for @loadVariableArea.
  ///
  /// In en, this message translates to:
  /// **'Variable load q'**
  String get loadVariableArea;

  /// No description provided for @loadPermanentPoint.
  ///
  /// In en, this message translates to:
  /// **'Permanent load G'**
  String get loadPermanentPoint;

  /// No description provided for @loadVariablePoint.
  ///
  /// In en, this message translates to:
  /// **'Variable load Q'**
  String get loadVariablePoint;

  /// No description provided for @loadSelfWeightNote.
  ///
  /// In en, this message translates to:
  /// **'Characteristic loads. Self-weight is added automatically; ULS combination 1.35G + 1.5Q.'**
  String get loadSelfWeightNote;

  /// No description provided for @beamSupport.
  ///
  /// In en, this message translates to:
  /// **'Supports'**
  String get beamSupport;

  /// No description provided for @beamSimplySupported.
  ///
  /// In en, this message translates to:
  /// **'Simple span'**
  String get beamSimplySupported;

  /// No description provided for @beamCantilever.
  ///
  /// In en, this message translates to:
  /// **'Cantilever'**
  String get beamCantilever;

  /// No description provided for @resultDesignForces.
  ///
  /// In en, this message translates to:
  /// **'Design forces'**
  String get resultDesignForces;

  /// No description provided for @resultUlsLoad.
  ///
  /// In en, this message translates to:
  /// **'ULS load'**
  String get resultUlsLoad;

  /// No description provided for @resultMoment.
  ///
  /// In en, this message translates to:
  /// **'Design moment'**
  String get resultMoment;

  /// No description provided for @resultShear.
  ///
  /// In en, this message translates to:
  /// **'Design shear'**
  String get resultShear;

  /// No description provided for @resultEffectiveDepth.
  ///
  /// In en, this message translates to:
  /// **'Effective depth'**
  String get resultEffectiveDepth;

  /// No description provided for @resultBottomBars.
  ///
  /// In en, this message translates to:
  /// **'Bottom bars'**
  String get resultBottomBars;

  /// No description provided for @resultTopBars.
  ///
  /// In en, this message translates to:
  /// **'Top bars'**
  String get resultTopBars;

  /// No description provided for @resultLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get resultLinks;

  /// No description provided for @checksTitle.
  ///
  /// In en, this message translates to:
  /// **'Checks'**
  String get checksTitle;

  /// No description provided for @checkBendingSteel.
  ///
  /// In en, this message translates to:
  /// **'Bending reinforcement'**
  String get checkBendingSteel;

  /// No description provided for @checkMinSteel.
  ///
  /// In en, this message translates to:
  /// **'Minimum reinforcement'**
  String get checkMinSteel;

  /// No description provided for @checkMaxSteel.
  ///
  /// In en, this message translates to:
  /// **'Maximum reinforcement'**
  String get checkMaxSteel;

  /// No description provided for @checkBarSpacing.
  ///
  /// In en, this message translates to:
  /// **'Clear bar spacing'**
  String get checkBarSpacing;

  /// No description provided for @checkShearConcrete.
  ///
  /// In en, this message translates to:
  /// **'Shear (concrete)'**
  String get checkShearConcrete;

  /// No description provided for @checkShearLinks.
  ///
  /// In en, this message translates to:
  /// **'Shear reinforcement'**
  String get checkShearLinks;

  /// No description provided for @checkLinkSpacing.
  ///
  /// In en, this message translates to:
  /// **'Link spacing'**
  String get checkLinkSpacing;

  /// No description provided for @checkDeflection.
  ///
  /// In en, this message translates to:
  /// **'Deflection'**
  String get checkDeflection;

  /// No description provided for @checkSlenderness.
  ///
  /// In en, this message translates to:
  /// **'Slenderness'**
  String get checkSlenderness;

  /// No description provided for @checkAxialBending.
  ///
  /// In en, this message translates to:
  /// **'Axial force and bending'**
  String get checkAxialBending;

  /// No description provided for @checkBearing.
  ///
  /// In en, this message translates to:
  /// **'Bearing pressure'**
  String get checkBearing;

  /// No description provided for @checkPunching.
  ///
  /// In en, this message translates to:
  /// **'Punching shear'**
  String get checkPunching;

  /// No description provided for @checkOverturning.
  ///
  /// In en, this message translates to:
  /// **'Overturning'**
  String get checkOverturning;

  /// No description provided for @checkSliding.
  ///
  /// In en, this message translates to:
  /// **'Sliding'**
  String get checkSliding;

  /// No description provided for @checkEccentricity.
  ///
  /// In en, this message translates to:
  /// **'Eccentricity'**
  String get checkEccentricity;

  /// No description provided for @verdictOk.
  ///
  /// In en, this message translates to:
  /// **'All checks satisfied'**
  String get verdictOk;

  /// No description provided for @verdictFail.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 check not satisfied} other{{n} checks not satisfied}}'**
  String verdictFail(int n);

  /// No description provided for @verdictUtilisation.
  ///
  /// In en, this message translates to:
  /// **'Highest utilisation {pct} %'**
  String verdictUtilisation(String pct);

  /// No description provided for @problemMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter {field}.'**
  String problemMissing(String field);

  /// No description provided for @problemNotPositive.
  ///
  /// In en, this message translates to:
  /// **'{field} must be greater than 0.'**
  String problemNotPositive(String field);

  /// No description provided for @problemOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'{field} is outside the range this method covers.'**
  String problemOutOfRange(String field);

  /// No description provided for @problemGeometry.
  ///
  /// In en, this message translates to:
  /// **'{field} is not consistent with the other dimensions.'**
  String problemGeometry(String field);

  /// No description provided for @noteCompressionSteel.
  ///
  /// In en, this message translates to:
  /// **'The moment exceeds the limit for a singly reinforced section: compression steel is required.'**
  String get noteCompressionSteel;

  /// No description provided for @noteBarsDoNotFit.
  ///
  /// In en, this message translates to:
  /// **'No standard bar arrangement fits in one layer. Increase the section.'**
  String get noteBarsDoNotFit;

  /// No description provided for @noteLinksNotFound.
  ///
  /// In en, this message translates to:
  /// **'Links up to Ø12 cannot carry the shear. Increase the section.'**
  String get noteLinksNotFound;

  /// No description provided for @noteDeflectionNotCovered.
  ///
  /// In en, this message translates to:
  /// **'The BAEL deflection exemption does not cover cantilevers: calculate the deflection.'**
  String get noteDeflectionNotCovered;

  /// No description provided for @columnWidthB.
  ///
  /// In en, this message translates to:
  /// **'Width b'**
  String get columnWidthB;

  /// No description provided for @columnDepthH.
  ///
  /// In en, this message translates to:
  /// **'Depth h (bending direction)'**
  String get columnDepthH;

  /// No description provided for @columnBucklingLength.
  ///
  /// In en, this message translates to:
  /// **'Buckling length l0'**
  String get columnBucklingLength;

  /// No description provided for @columnMoment.
  ///
  /// In en, this message translates to:
  /// **'First-order moment'**
  String get columnMoment;

  /// No description provided for @columnCreep.
  ///
  /// In en, this message translates to:
  /// **'Effective creep ratio φef'**
  String get columnCreep;

  /// No description provided for @columnUlsNote.
  ///
  /// In en, this message translates to:
  /// **'ULS design values. Bending acts about the axis parallel to b.'**
  String get columnUlsNote;

  /// No description provided for @columnSlendernessTitle.
  ///
  /// In en, this message translates to:
  /// **'Slenderness and moments'**
  String get columnSlendernessTitle;

  /// No description provided for @columnImperfection.
  ///
  /// In en, this message translates to:
  /// **'Imperfection eccentricity'**
  String get columnImperfection;

  /// No description provided for @columnSecondOrder.
  ///
  /// In en, this message translates to:
  /// **'Second-order eccentricity'**
  String get columnSecondOrder;

  /// No description provided for @columnLongitudinalBars.
  ///
  /// In en, this message translates to:
  /// **'Longitudinal bars'**
  String get columnLongitudinalBars;

  /// No description provided for @columnAxialResistance.
  ///
  /// In en, this message translates to:
  /// **'Axial resistance'**
  String get columnAxialResistance;

  /// No description provided for @columnMomentResistance.
  ///
  /// In en, this message translates to:
  /// **'Moment resistance at NEd'**
  String get columnMomentResistance;

  /// No description provided for @columnInteraction.
  ///
  /// In en, this message translates to:
  /// **'N–M interaction diagram'**
  String get columnInteraction;

  /// No description provided for @noteSecondOrder.
  ///
  /// In en, this message translates to:
  /// **'λ > λlim: second-order moment added by the nominal curvature method (EN 1992-1-1 5.8.8).'**
  String get noteSecondOrder;

  /// No description provided for @noteBaelCentred.
  ///
  /// In en, this message translates to:
  /// **'Centred compression: BAEL B.8.4 α method.'**
  String get noteBaelCentred;

  /// No description provided for @noteSlendernessOutOfScope.
  ///
  /// In en, this message translates to:
  /// **'Slenderness beyond the method\'s range: a buckling analysis is required.'**
  String get noteSlendernessOutOfScope;

  /// No description provided for @noteSectionTooSmall.
  ///
  /// In en, this message translates to:
  /// **'The maximum steel ratio is not enough. Increase the section.'**
  String get noteSectionTooSmall;

  /// No description provided for @slabType.
  ///
  /// In en, this message translates to:
  /// **'Slab type'**
  String get slabType;

  /// No description provided for @slabOneWayShort.
  ///
  /// In en, this message translates to:
  /// **'One-way'**
  String get slabOneWayShort;

  /// No description provided for @slabTwoWayShort.
  ///
  /// In en, this message translates to:
  /// **'Two-way'**
  String get slabTwoWayShort;

  /// No description provided for @slabContinuous.
  ///
  /// In en, this message translates to:
  /// **'Continuous'**
  String get slabContinuous;

  /// No description provided for @slabShortSpan.
  ///
  /// In en, this message translates to:
  /// **'Short span lx'**
  String get slabShortSpan;

  /// No description provided for @slabLongSpan.
  ///
  /// In en, this message translates to:
  /// **'Long span ly'**
  String get slabLongSpan;

  /// No description provided for @slabThicknessInput.
  ///
  /// In en, this message translates to:
  /// **'Thickness h'**
  String get slabThicknessInput;

  /// No description provided for @slabCoefficients.
  ///
  /// In en, this message translates to:
  /// **'Panel coefficients'**
  String get slabCoefficients;

  /// No description provided for @slabMomentXSpan.
  ///
  /// In en, this message translates to:
  /// **'Span moment, x'**
  String get slabMomentXSpan;

  /// No description provided for @slabMomentSupport.
  ///
  /// In en, this message translates to:
  /// **'Support moment'**
  String get slabMomentSupport;

  /// No description provided for @slabMomentYSpan.
  ///
  /// In en, this message translates to:
  /// **'Span moment, y'**
  String get slabMomentYSpan;

  /// No description provided for @slabBarsXSpan.
  ///
  /// In en, this message translates to:
  /// **'Bottom, x direction'**
  String get slabBarsXSpan;

  /// No description provided for @slabBarsSupport.
  ///
  /// In en, this message translates to:
  /// **'Top, over supports'**
  String get slabBarsSupport;

  /// No description provided for @slabBarsYSpan.
  ///
  /// In en, this message translates to:
  /// **'Bottom, y direction'**
  String get slabBarsYSpan;

  /// No description provided for @slabDistribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution bars'**
  String get slabDistribution;

  /// No description provided for @noteTreatedAsOneWay.
  ///
  /// In en, this message translates to:
  /// **'lx/ly < 0.4: the panel is designed as one-way.'**
  String get noteTreatedAsOneWay;

  /// No description provided for @noteBaelPanel.
  ///
  /// In en, this message translates to:
  /// **'Two-way moments from BAEL 91 Annexe E3 coefficients (ν = 0 at ULS).'**
  String get noteBaelPanel;

  /// No description provided for @noteContinuityCoefficients.
  ///
  /// In en, this message translates to:
  /// **'Continuity by simplified coefficients: 0.75 M0 in span, 0.5 M0 over supports (BAEL A.8.2.32).'**
  String get noteContinuityCoefficients;

  /// No description provided for @footingColumnA.
  ///
  /// In en, this message translates to:
  /// **'Column a (moment direction)'**
  String get footingColumnA;

  /// No description provided for @footingColumnB.
  ///
  /// In en, this message translates to:
  /// **'Column b'**
  String get footingColumnB;

  /// No description provided for @footingMomentG.
  ///
  /// In en, this message translates to:
  /// **'Moment from G'**
  String get footingMomentG;

  /// No description provided for @footingMomentQ.
  ///
  /// In en, this message translates to:
  /// **'Moment from Q'**
  String get footingMomentQ;

  /// No description provided for @footingAllowable.
  ///
  /// In en, this message translates to:
  /// **'Allowable bearing pressure'**
  String get footingAllowable;

  /// No description provided for @footingDepthInput.
  ///
  /// In en, this message translates to:
  /// **'Founding depth'**
  String get footingDepthInput;

  /// No description provided for @footingCharacteristicNote.
  ///
  /// In en, this message translates to:
  /// **'Characteristic (service) column loads. Sizing at SLS, steel at ULS.'**
  String get footingCharacteristicNote;

  /// No description provided for @footingSelfWeight.
  ///
  /// In en, this message translates to:
  /// **'Footing and backfill weight'**
  String get footingSelfWeight;

  /// No description provided for @footingPressure.
  ///
  /// In en, this message translates to:
  /// **'Ground pressure'**
  String get footingPressure;

  /// No description provided for @footingBarsAlongA.
  ///
  /// In en, this message translates to:
  /// **'Bars parallel to A'**
  String get footingBarsAlongA;

  /// No description provided for @footingBarsAlongB.
  ///
  /// In en, this message translates to:
  /// **'Bars parallel to B'**
  String get footingBarsAlongB;

  /// No description provided for @noteSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'The footing would exceed 10 m: check the soil or the loads.'**
  String get noteSizeLimit;

  /// No description provided for @noteFootingBael.
  ///
  /// In en, this message translates to:
  /// **'Rigid footing designed by the strut-and-tie method (méthode des bielles); pressure at 3/4 width.'**
  String get noteFootingBael;

  /// No description provided for @noteFootingEc2.
  ///
  /// In en, this message translates to:
  /// **'Bending at 0.15a inside the column face (EN 1992-1-1 9.8.2.2); pressure on the effective area (EN 1997-1 Annex D).'**
  String get noteFootingEc2;

  /// No description provided for @wallGeometry.
  ///
  /// In en, this message translates to:
  /// **'Geometry'**
  String get wallGeometry;

  /// No description provided for @wallPresizeButton.
  ///
  /// In en, this message translates to:
  /// **'Pre-size from height'**
  String get wallPresizeButton;

  /// No description provided for @wallToeLength.
  ///
  /// In en, this message translates to:
  /// **'Toe length'**
  String get wallToeLength;

  /// No description provided for @wallHeelLength.
  ///
  /// In en, this message translates to:
  /// **'Heel length'**
  String get wallHeelLength;

  /// No description provided for @wallStemTop.
  ///
  /// In en, this message translates to:
  /// **'Stem thickness, top'**
  String get wallStemTop;

  /// No description provided for @wallStemBottom.
  ///
  /// In en, this message translates to:
  /// **'Stem thickness, base'**
  String get wallStemBottom;

  /// No description provided for @wallSurcharge.
  ///
  /// In en, this message translates to:
  /// **'Surcharge q'**
  String get wallSurcharge;

  /// No description provided for @wallToe.
  ///
  /// In en, this message translates to:
  /// **'toe'**
  String get wallToe;

  /// No description provided for @wallHeel.
  ///
  /// In en, this message translates to:
  /// **'heel'**
  String get wallHeel;

  /// No description provided for @wallKa.
  ///
  /// In en, this message translates to:
  /// **'Active pressure coefficient'**
  String get wallKa;

  /// No description provided for @wallFosSliding.
  ///
  /// In en, this message translates to:
  /// **'Factor of safety, sliding'**
  String get wallFosSliding;

  /// No description provided for @wallStem.
  ///
  /// In en, this message translates to:
  /// **'Stem'**
  String get wallStem;

  /// No description provided for @wallStemBars.
  ///
  /// In en, this message translates to:
  /// **'Vertical bars, soil face'**
  String get wallStemBars;

  /// No description provided for @noteWallMethod.
  ///
  /// In en, this message translates to:
  /// **'Stability with Rankine active pressure and global factors of safety of 1.5. EC7 partial-factor design comes with the geotechnics module.'**
  String get noteWallMethod;

  /// No description provided for @noteWallShearKey.
  ///
  /// In en, this message translates to:
  /// **'Sliding is not satisfied: add a shear key or lengthen the heel.'**
  String get noteWallShearKey;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
