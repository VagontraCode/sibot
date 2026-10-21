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
  /// **'Analysis, concrete, foundations and tools'**
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
  /// **'Isolated, strip, combined'**
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
  /// **'Isolated, strip or combined footing: sizing, steel, punching.'**
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
  /// **'ULS design values. The h-direction moment bends the section across h; the b-direction moment across b.'**
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

  /// No description provided for @columnDiameter.
  ///
  /// In en, this message translates to:
  /// **'Diameter D'**
  String get columnDiameter;

  /// No description provided for @columnMomentH.
  ///
  /// In en, this message translates to:
  /// **'Moment, h direction'**
  String get columnMomentH;

  /// No description provided for @columnMomentB.
  ///
  /// In en, this message translates to:
  /// **'Moment, b direction'**
  String get columnMomentB;

  /// No description provided for @columnMomentX.
  ///
  /// In en, this message translates to:
  /// **'Moment Mx'**
  String get columnMomentX;

  /// No description provided for @columnMomentY.
  ///
  /// In en, this message translates to:
  /// **'Moment My'**
  String get columnMomentY;

  /// No description provided for @columnShape.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get columnShape;

  /// No description provided for @columnRectangular.
  ///
  /// In en, this message translates to:
  /// **'Rectangular'**
  String get columnRectangular;

  /// No description provided for @columnCircular.
  ///
  /// In en, this message translates to:
  /// **'Circular'**
  String get columnCircular;

  /// No description provided for @columnUlsNoteCircle.
  ///
  /// In en, this message translates to:
  /// **'ULS design values. The two moments are combined vectorially.'**
  String get columnUlsNoteCircle;

  /// No description provided for @columnBarsPerFace.
  ///
  /// In en, this message translates to:
  /// **'Bars per face'**
  String get columnBarsPerFace;

  /// No description provided for @noteBiaxial.
  ///
  /// In en, this message translates to:
  /// **'Moments in both directions: biaxial check EN 1992-1-1 5.8.9(4).'**
  String get noteBiaxial;

  /// No description provided for @noteImperfectionOneDirection.
  ///
  /// In en, this message translates to:
  /// **'Imperfection and minimum eccentricity are applied in one direction at a time (EN 1992-1-1 5.8.9(2)); the worse case governs.'**
  String get noteImperfectionOneDirection;

  /// No description provided for @checkConcreteStress.
  ///
  /// In en, this message translates to:
  /// **'Concrete stress (SLS)'**
  String get checkConcreteStress;

  /// No description provided for @checkSteelStress.
  ///
  /// In en, this message translates to:
  /// **'Steel stress (SLS)'**
  String get checkSteelStress;

  /// No description provided for @checkCrackWidth.
  ///
  /// In en, this message translates to:
  /// **'Crack width'**
  String get checkCrackWidth;

  /// No description provided for @diagramShear.
  ///
  /// In en, this message translates to:
  /// **'Shear force V'**
  String get diagramShear;

  /// No description provided for @diagramMoment.
  ///
  /// In en, this message translates to:
  /// **'Bending moment M'**
  String get diagramMoment;

  /// No description provided for @slsTitle.
  ///
  /// In en, this message translates to:
  /// **'Serviceability'**
  String get slsTitle;

  /// No description provided for @slsCracking.
  ///
  /// In en, this message translates to:
  /// **'Cracking class'**
  String get slsCracking;

  /// No description provided for @slsCrackingSlight.
  ///
  /// In en, this message translates to:
  /// **'Not harmful'**
  String get slsCrackingSlight;

  /// No description provided for @slsCrackingHarmful.
  ///
  /// In en, this message translates to:
  /// **'Harmful'**
  String get slsCrackingHarmful;

  /// No description provided for @slsCrackingVeryHarmful.
  ///
  /// In en, this message translates to:
  /// **'Very harmful'**
  String get slsCrackingVeryHarmful;

  /// No description provided for @slsPsi2.
  ///
  /// In en, this message translates to:
  /// **'Quasi-permanent factor ψ2'**
  String get slsPsi2;

  /// No description provided for @slsCrackLimit.
  ///
  /// In en, this message translates to:
  /// **'Crack width limit wmax'**
  String get slsCrackLimit;

  /// No description provided for @slsCharMoment.
  ///
  /// In en, this message translates to:
  /// **'Characteristic moment'**
  String get slsCharMoment;

  /// No description provided for @slsConcreteStress.
  ///
  /// In en, this message translates to:
  /// **'Concrete stress'**
  String get slsConcreteStress;

  /// No description provided for @slsSteelStress.
  ///
  /// In en, this message translates to:
  /// **'Steel stress'**
  String get slsSteelStress;

  /// No description provided for @slsQpMoment.
  ///
  /// In en, this message translates to:
  /// **'Quasi-permanent moment'**
  String get slsQpMoment;

  /// No description provided for @slsCrackSpacing.
  ///
  /// In en, this message translates to:
  /// **'Maximum crack spacing'**
  String get slsCrackSpacing;

  /// No description provided for @punchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Punching (optional)'**
  String get punchingTitle;

  /// No description provided for @punchingType.
  ///
  /// In en, this message translates to:
  /// **'Load type'**
  String get punchingType;

  /// No description provided for @punchingColumn.
  ///
  /// In en, this message translates to:
  /// **'Interior column'**
  String get punchingColumn;

  /// No description provided for @punchingPointLoad.
  ///
  /// In en, this message translates to:
  /// **'Point load'**
  String get punchingPointLoad;

  /// No description provided for @punchingOptionalNote.
  ///
  /// In en, this message translates to:
  /// **'Leave the load empty to skip punching. ULS load on a c1 × c2 area.'**
  String get punchingOptionalNote;

  /// No description provided for @punchingLoad.
  ///
  /// In en, this message translates to:
  /// **'Punching load VEd'**
  String get punchingLoad;

  /// No description provided for @punchingC1.
  ///
  /// In en, this message translates to:
  /// **'Loaded area c1'**
  String get punchingC1;

  /// No description provided for @punchingC2.
  ///
  /// In en, this message translates to:
  /// **'Loaded area c2'**
  String get punchingC2;

  /// No description provided for @punchingPerimeter.
  ///
  /// In en, this message translates to:
  /// **'Control perimeter'**
  String get punchingPerimeter;

  /// No description provided for @punchingDemand.
  ///
  /// In en, this message translates to:
  /// **'Punching action'**
  String get punchingDemand;

  /// No description provided for @punchingResistance.
  ///
  /// In en, this message translates to:
  /// **'Resistance without reinforcement'**
  String get punchingResistance;

  /// No description provided for @punchingReinforcement.
  ///
  /// In en, this message translates to:
  /// **'Punching reinforcement per perimeter (sr = 0.75d)'**
  String get punchingReinforcement;

  /// No description provided for @footingTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Footing type'**
  String get footingTypeLabel;

  /// No description provided for @footingIsolatedType.
  ///
  /// In en, this message translates to:
  /// **'Isolated'**
  String get footingIsolatedType;

  /// No description provided for @footingStripType.
  ///
  /// In en, this message translates to:
  /// **'Strip'**
  String get footingStripType;

  /// No description provided for @footingCombinedType.
  ///
  /// In en, this message translates to:
  /// **'Combined'**
  String get footingCombinedType;

  /// No description provided for @footingWallActions.
  ///
  /// In en, this message translates to:
  /// **'Wall actions (per metre)'**
  String get footingWallActions;

  /// No description provided for @footingWallThickness.
  ///
  /// In en, this message translates to:
  /// **'Wall thickness'**
  String get footingWallThickness;

  /// No description provided for @footingCol1A.
  ///
  /// In en, this message translates to:
  /// **'Column 1, a (along footing)'**
  String get footingCol1A;

  /// No description provided for @footingCol1B.
  ///
  /// In en, this message translates to:
  /// **'Column 1, b'**
  String get footingCol1B;

  /// No description provided for @footingCol2A.
  ///
  /// In en, this message translates to:
  /// **'Column 2, a (along footing)'**
  String get footingCol2A;

  /// No description provided for @footingCol2B.
  ///
  /// In en, this message translates to:
  /// **'Column 2, b'**
  String get footingCol2B;

  /// No description provided for @footingSpacingInput.
  ///
  /// In en, this message translates to:
  /// **'Column spacing (centres)'**
  String get footingSpacingInput;

  /// No description provided for @footingG1.
  ///
  /// In en, this message translates to:
  /// **'Column 1, G'**
  String get footingG1;

  /// No description provided for @footingQ1.
  ///
  /// In en, this message translates to:
  /// **'Column 1, Q'**
  String get footingQ1;

  /// No description provided for @footingG2.
  ///
  /// In en, this message translates to:
  /// **'Column 2, G'**
  String get footingG2;

  /// No description provided for @footingQ2.
  ///
  /// In en, this message translates to:
  /// **'Column 2, Q'**
  String get footingQ2;

  /// No description provided for @footingWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get footingWidth;

  /// No description provided for @footingTransverseBars.
  ///
  /// In en, this message translates to:
  /// **'Transverse bars'**
  String get footingTransverseBars;

  /// No description provided for @footingOverhang.
  ///
  /// In en, this message translates to:
  /// **'Overhang beyond column 1'**
  String get footingOverhang;

  /// No description provided for @footingLongBottom.
  ///
  /// In en, this message translates to:
  /// **'Longitudinal, bottom'**
  String get footingLongBottom;

  /// No description provided for @footingLongTop.
  ///
  /// In en, this message translates to:
  /// **'Longitudinal, top'**
  String get footingLongTop;

  /// No description provided for @footingTransverseUnder.
  ///
  /// In en, this message translates to:
  /// **'Transverse under column {n}'**
  String footingTransverseUnder(int n);

  /// No description provided for @noteCombinedFooting.
  ///
  /// In en, this message translates to:
  /// **'Length set so the service resultant is at mid-length; designed as a beam on a linear soil reaction. Thickness increased until no shear links are needed.'**
  String get noteCombinedFooting;

  /// No description provided for @noteSoilEc7.
  ///
  /// In en, this message translates to:
  /// **'Bearing resistance from EN 1997-1 Annex D, design approach 2 (γR,v = 1.4), vertical load.'**
  String get noteSoilEc7;

  /// No description provided for @soilBearingMode.
  ///
  /// In en, this message translates to:
  /// **'Bearing check'**
  String get soilBearingMode;

  /// No description provided for @soilModeAllowable.
  ///
  /// In en, this message translates to:
  /// **'Allowable pressure'**
  String get soilModeAllowable;

  /// No description provided for @soilModeParameters.
  ///
  /// In en, this message translates to:
  /// **'Soil parameters (EC7)'**
  String get soilModeParameters;

  /// No description provided for @soilDrainage.
  ///
  /// In en, this message translates to:
  /// **'Soil condition'**
  String get soilDrainage;

  /// No description provided for @soilDrained.
  ///
  /// In en, this message translates to:
  /// **'Drained (c′, φ′)'**
  String get soilDrained;

  /// No description provided for @soilUndrained.
  ///
  /// In en, this message translates to:
  /// **'Undrained (cu)'**
  String get soilUndrained;

  /// No description provided for @soilCohesion.
  ///
  /// In en, this message translates to:
  /// **'Cohesion c′'**
  String get soilCohesion;

  /// No description provided for @soilPhi.
  ///
  /// In en, this message translates to:
  /// **'Friction angle φ′'**
  String get soilPhi;

  /// No description provided for @soilCu.
  ///
  /// In en, this message translates to:
  /// **'Undrained strength cu'**
  String get soilCu;

  /// No description provided for @soilModulus.
  ///
  /// In en, this message translates to:
  /// **'Young\'s modulus E'**
  String get soilModulus;

  /// No description provided for @soilPoisson.
  ///
  /// In en, this message translates to:
  /// **'Poisson\'s ratio ν'**
  String get soilPoisson;

  /// No description provided for @wallBase.
  ///
  /// In en, this message translates to:
  /// **'Base slab'**
  String get wallBase;

  /// No description provided for @wallUlsPressure.
  ///
  /// In en, this message translates to:
  /// **'ULS base pressure, toe / heel'**
  String get wallUlsPressure;

  /// No description provided for @wallToeMoment.
  ///
  /// In en, this message translates to:
  /// **'Toe, bottom bars'**
  String get wallToeMoment;

  /// No description provided for @wallHeelMoment.
  ///
  /// In en, this message translates to:
  /// **'Heel, top bars'**
  String get wallHeelMoment;

  /// No description provided for @wallEqu.
  ///
  /// In en, this message translates to:
  /// **'EQU overturning'**
  String get wallEqu;

  /// No description provided for @wallDa2Sliding.
  ///
  /// In en, this message translates to:
  /// **'DA2 sliding'**
  String get wallDa2Sliding;

  /// No description provided for @noteWallEc7.
  ///
  /// In en, this message translates to:
  /// **'EC7: overturning by EQU (γG,dst 1.1, γG,stb 0.9, γφ′ 1.25), sliding by DA2 (1.35 / 1.5, γR,h 1.1). Global factors are shown for information.'**
  String get noteWallEc7;

  /// No description provided for @bearingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'EC7 bearing resistance and settlement of a shallow footing.'**
  String get bearingSubtitle;

  /// No description provided for @bearingWidth.
  ///
  /// In en, this message translates to:
  /// **'Width B'**
  String get bearingWidth;

  /// No description provided for @bearingLength.
  ///
  /// In en, this message translates to:
  /// **'Length L'**
  String get bearingLength;

  /// No description provided for @bearingLoadNote.
  ///
  /// In en, this message translates to:
  /// **'Characteristic loads including the footing and backfill weight.'**
  String get bearingLoadNote;

  /// No description provided for @bearingResistance.
  ///
  /// In en, this message translates to:
  /// **'Bearing resistance'**
  String get bearingResistance;

  /// No description provided for @bearingFactors.
  ///
  /// In en, this message translates to:
  /// **'Bearing factors'**
  String get bearingFactors;

  /// No description provided for @bearingUltimate.
  ///
  /// In en, this message translates to:
  /// **'Ultimate bearing pressure'**
  String get bearingUltimate;

  /// No description provided for @bearingDesignResistance.
  ///
  /// In en, this message translates to:
  /// **'Design resistance'**
  String get bearingDesignResistance;

  /// No description provided for @bearingDesignPressure.
  ///
  /// In en, this message translates to:
  /// **'Design pressure (1.35G + 1.5Q)'**
  String get bearingDesignPressure;

  /// No description provided for @bearingSettlement.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get bearingSettlement;

  /// No description provided for @bearingServicePressure.
  ///
  /// In en, this message translates to:
  /// **'Service pressure'**
  String get bearingServicePressure;

  /// No description provided for @noteSettlementEstimate.
  ///
  /// In en, this message translates to:
  /// **'Settlement is an elastic estimate for a rigid footing (equivalent circle); use oedometer results for clays.'**
  String get noteSettlementEstimate;

  /// No description provided for @sectionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Area, inertia and section moduli.'**
  String get sectionsSubtitle;

  /// No description provided for @sectionShape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get sectionShape;

  /// No description provided for @sectionRect.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get sectionRect;

  /// No description provided for @sectionCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get sectionCircle;

  /// No description provided for @sectionHollow.
  ///
  /// In en, this message translates to:
  /// **'Hollow'**
  String get sectionHollow;

  /// No description provided for @sectionI.
  ///
  /// In en, this message translates to:
  /// **'I'**
  String get sectionI;

  /// No description provided for @sectionT.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get sectionT;

  /// No description provided for @sectionWidth.
  ///
  /// In en, this message translates to:
  /// **'Width b'**
  String get sectionWidth;

  /// No description provided for @sectionHeight.
  ///
  /// In en, this message translates to:
  /// **'Height h'**
  String get sectionHeight;

  /// No description provided for @sectionThickness.
  ///
  /// In en, this message translates to:
  /// **'Wall thickness t'**
  String get sectionThickness;

  /// No description provided for @sectionFlange.
  ///
  /// In en, this message translates to:
  /// **'Flange thickness tf'**
  String get sectionFlange;

  /// No description provided for @sectionWeb.
  ///
  /// In en, this message translates to:
  /// **'Web thickness tw'**
  String get sectionWeb;

  /// No description provided for @sectionResults.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get sectionResults;

  /// No description provided for @sectionArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get sectionArea;

  /// No description provided for @sectionCentroid.
  ///
  /// In en, this message translates to:
  /// **'Centroid from top'**
  String get sectionCentroid;

  /// No description provided for @sectionInertiaY.
  ///
  /// In en, this message translates to:
  /// **'Second moment, strong axis'**
  String get sectionInertiaY;

  /// No description provided for @sectionInertiaZ.
  ///
  /// In en, this message translates to:
  /// **'Second moment, weak axis'**
  String get sectionInertiaZ;

  /// No description provided for @sectionWelTop.
  ///
  /// In en, this message translates to:
  /// **'Elastic modulus, top'**
  String get sectionWelTop;

  /// No description provided for @sectionWelBottom.
  ///
  /// In en, this message translates to:
  /// **'Elastic modulus, bottom'**
  String get sectionWelBottom;

  /// No description provided for @sectionWpl.
  ///
  /// In en, this message translates to:
  /// **'Plastic modulus'**
  String get sectionWpl;

  /// No description provided for @sectionRadii.
  ///
  /// In en, this message translates to:
  /// **'Radii of gyration'**
  String get sectionRadii;

  /// No description provided for @noteSectionNoFillets.
  ///
  /// In en, this message translates to:
  /// **'Root fillets are not included; tabulated values for rolled sections are slightly higher.'**
  String get noteSectionNoFillets;

  /// No description provided for @quantitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Concrete materials, formwork and rebar weights.'**
  String get quantitiesSubtitle;

  /// No description provided for @qtyElements.
  ///
  /// In en, this message translates to:
  /// **'Elements'**
  String get qtyElements;

  /// No description provided for @qtyLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get qtyLength;

  /// No description provided for @qtyWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get qtyWidth;

  /// No description provided for @qtyHeight.
  ///
  /// In en, this message translates to:
  /// **'Height / thickness'**
  String get qtyHeight;

  /// No description provided for @qtyCount.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get qtyCount;

  /// No description provided for @qtyFormworkType.
  ///
  /// In en, this message translates to:
  /// **'Formwork faces'**
  String get qtyFormworkType;

  /// No description provided for @qtyColumnWall.
  ///
  /// In en, this message translates to:
  /// **'Column / wall'**
  String get qtyColumnWall;

  /// No description provided for @qtyMix.
  ///
  /// In en, this message translates to:
  /// **'Mix per m³'**
  String get qtyMix;

  /// No description provided for @qtyCement.
  ///
  /// In en, this message translates to:
  /// **'Cement'**
  String get qtyCement;

  /// No description provided for @qtySand.
  ///
  /// In en, this message translates to:
  /// **'Sand'**
  String get qtySand;

  /// No description provided for @qtyGravel.
  ///
  /// In en, this message translates to:
  /// **'Gravel'**
  String get qtyGravel;

  /// No description provided for @qtyWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get qtyWater;

  /// No description provided for @qtyWaste.
  ///
  /// In en, this message translates to:
  /// **'Waste allowance'**
  String get qtyWaste;

  /// No description provided for @qtyRebar.
  ///
  /// In en, this message translates to:
  /// **'Reinforcement'**
  String get qtyRebar;

  /// No description provided for @qtyBarDiameter.
  ///
  /// In en, this message translates to:
  /// **'Bar diameter'**
  String get qtyBarDiameter;

  /// No description provided for @qtyBarCount.
  ///
  /// In en, this message translates to:
  /// **'Number of bars'**
  String get qtyBarCount;

  /// No description provided for @qtyBarLength.
  ///
  /// In en, this message translates to:
  /// **'Bar length'**
  String get qtyBarLength;

  /// No description provided for @qtyLap.
  ///
  /// In en, this message translates to:
  /// **'Laps and waste'**
  String get qtyLap;

  /// No description provided for @qtyConcrete.
  ///
  /// In en, this message translates to:
  /// **'Concrete'**
  String get qtyConcrete;

  /// No description provided for @qtyVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get qtyVolume;

  /// No description provided for @qtyCementTotal.
  ///
  /// In en, this message translates to:
  /// **'Cement'**
  String get qtyCementTotal;

  /// No description provided for @qtyBags.
  ///
  /// In en, this message translates to:
  /// **'{n} bags of 50 kg'**
  String qtyBags(int n);

  /// No description provided for @qtySandTotal.
  ///
  /// In en, this message translates to:
  /// **'Sand'**
  String get qtySandTotal;

  /// No description provided for @qtyGravelTotal.
  ///
  /// In en, this message translates to:
  /// **'Gravel'**
  String get qtyGravelTotal;

  /// No description provided for @qtyWaterTotal.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get qtyWaterTotal;

  /// No description provided for @qtyFormwork.
  ///
  /// In en, this message translates to:
  /// **'Formwork area'**
  String get qtyFormwork;

  /// No description provided for @qtyRebarLength.
  ///
  /// In en, this message translates to:
  /// **'Total length'**
  String get qtyRebarLength;

  /// No description provided for @qtyRebarMass.
  ///
  /// In en, this message translates to:
  /// **'Mass'**
  String get qtyRebarMass;

  /// No description provided for @qtyStockBars.
  ///
  /// In en, this message translates to:
  /// **'12 m bars to order'**
  String get qtyStockBars;

  /// No description provided for @qtyNothing.
  ///
  /// In en, this message translates to:
  /// **'Fill in the elements or the reinforcement.'**
  String get qtyNothing;

  /// No description provided for @noteQuantitiesMix.
  ///
  /// In en, this message translates to:
  /// **'Default mix is a common site dosage (350 kg/m³). Adjust it to your mix design.'**
  String get noteQuantitiesMix;

  /// No description provided for @frameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frames, continuous beams and trusses: model, analyse, read diagrams.'**
  String get frameSubtitle;

  /// No description provided for @frameNewModel.
  ///
  /// In en, this message translates to:
  /// **'New model'**
  String get frameNewModel;

  /// No description provided for @frameLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load models'**
  String get frameLoadError;

  /// No description provided for @frameEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No models yet'**
  String get frameEmptyTitle;

  /// No description provided for @frameEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Start from a continuous beam, a frame or a truss, or draw your own.'**
  String get frameEmptyMessage;

  /// No description provided for @frameCounts.
  ///
  /// In en, this message translates to:
  /// **'{nodes} nodes, {members} members'**
  String frameCounts(int nodes, int members);

  /// No description provided for @frameTemplateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the template dimensions.'**
  String get frameTemplateInvalid;

  /// No description provided for @frameTemplateBeam.
  ///
  /// In en, this message translates to:
  /// **'Continuous beam'**
  String get frameTemplateBeam;

  /// No description provided for @frameTemplateFrame.
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get frameTemplateFrame;

  /// No description provided for @frameTemplateTruss.
  ///
  /// In en, this message translates to:
  /// **'Truss'**
  String get frameTemplateTruss;

  /// No description provided for @frameTemplateBlank.
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get frameTemplateBlank;

  /// No description provided for @frameModelName.
  ///
  /// In en, this message translates to:
  /// **'Model name'**
  String get frameModelName;

  /// No description provided for @frameSpans.
  ///
  /// In en, this message translates to:
  /// **'Spans'**
  String get frameSpans;

  /// No description provided for @frameSpansHelp.
  ///
  /// In en, this message translates to:
  /// **'Separate spans with commas, e.g. 5, 6, 5'**
  String get frameSpansHelp;

  /// No description provided for @frameBays.
  ///
  /// In en, this message translates to:
  /// **'Bays'**
  String get frameBays;

  /// No description provided for @frameBayWidth.
  ///
  /// In en, this message translates to:
  /// **'Bay width'**
  String get frameBayWidth;

  /// No description provided for @frameStoreys.
  ///
  /// In en, this message translates to:
  /// **'Storeys'**
  String get frameStoreys;

  /// No description provided for @frameStoreyHeight.
  ///
  /// In en, this message translates to:
  /// **'Storey height'**
  String get frameStoreyHeight;

  /// No description provided for @frameTrussType.
  ///
  /// In en, this message translates to:
  /// **'Truss type'**
  String get frameTrussType;

  /// No description provided for @frameSpan.
  ///
  /// In en, this message translates to:
  /// **'Span'**
  String get frameSpan;

  /// No description provided for @frameTrussHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get frameTrussHeight;

  /// No description provided for @framePanels.
  ///
  /// In en, this message translates to:
  /// **'Panels'**
  String get framePanels;

  /// No description provided for @frameWindPerFloor.
  ///
  /// In en, this message translates to:
  /// **'Wind force per floor (left side)'**
  String get frameWindPerFloor;

  /// No description provided for @frameTemplateNote.
  ///
  /// In en, this message translates to:
  /// **'Characteristic loads, downwards. Self-weight is added to G. Sections and loads can be changed afterwards.'**
  String get frameTemplateNote;

  /// No description provided for @frameCreate.
  ///
  /// In en, this message translates to:
  /// **'Create model'**
  String get frameCreate;

  /// No description provided for @frameUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get frameUndo;

  /// No description provided for @frameRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get frameRedo;

  /// No description provided for @frameFit.
  ///
  /// In en, this message translates to:
  /// **'Fit to screen'**
  String get frameFit;

  /// No description provided for @frameLoadCases.
  ///
  /// In en, this message translates to:
  /// **'Load cases'**
  String get frameLoadCases;

  /// No description provided for @frameSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get frameSections;

  /// No description provided for @frameModeModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get frameModeModel;

  /// No description provided for @frameModeResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get frameModeResults;

  /// No description provided for @frameEnvelope.
  ///
  /// In en, this message translates to:
  /// **'ULS envelope'**
  String get frameEnvelope;

  /// No description provided for @frameViewDeformed.
  ///
  /// In en, this message translates to:
  /// **'Deformed'**
  String get frameViewDeformed;

  /// No description provided for @frameViewReactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get frameViewReactions;

  /// No description provided for @frameResultSource.
  ///
  /// In en, this message translates to:
  /// **'Case or combination'**
  String get frameResultSource;

  /// No description provided for @frameAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis not possible'**
  String get frameAnalysisFailed;

  /// No description provided for @frameErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add nodes and members first.'**
  String get frameErrEmpty;

  /// No description provided for @frameErrZeroLength.
  ///
  /// In en, this message translates to:
  /// **'A member has zero length.'**
  String get frameErrZeroLength;

  /// No description provided for @frameErrUnstable.
  ///
  /// In en, this message translates to:
  /// **'The structure is unstable: add supports or remove hinges so it cannot move freely.'**
  String get frameErrUnstable;

  /// No description provided for @frameErrInvalid.
  ///
  /// In en, this message translates to:
  /// **'The model contains an invalid member or section.'**
  String get frameErrInvalid;

  /// No description provided for @frameRename.
  ///
  /// In en, this message translates to:
  /// **'Rename model'**
  String get frameRename;

  /// No description provided for @frameToolSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get frameToolSelect;

  /// No description provided for @frameToolNode.
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get frameToolNode;

  /// No description provided for @frameToolMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get frameToolMember;

  /// No description provided for @frameToolSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get frameToolSupport;

  /// No description provided for @frameToolLoad.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get frameToolLoad;

  /// No description provided for @frameHintSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap a node or member to edit it. Pinch to zoom, drag to pan.'**
  String get frameHintSelect;

  /// No description provided for @frameHintNode.
  ///
  /// In en, this message translates to:
  /// **'Tap to place nodes (grid {grid} m).'**
  String frameHintNode(String grid);

  /// No description provided for @frameHintMember.
  ///
  /// In en, this message translates to:
  /// **'Tap a start point, then an end point. Members chain.'**
  String get frameHintMember;

  /// No description provided for @frameHintSupport.
  ///
  /// In en, this message translates to:
  /// **'Tap a node to cycle: free, pinned, fixed, roller.'**
  String get frameHintSupport;

  /// No description provided for @frameHintLoad.
  ///
  /// In en, this message translates to:
  /// **'Tap a member or node to set its load in the active case.'**
  String get frameHintLoad;

  /// No description provided for @frameActiveCase.
  ///
  /// In en, this message translates to:
  /// **'Active load case'**
  String get frameActiveCase;

  /// No description provided for @frameNodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Node {n}'**
  String frameNodeTitle(int n);

  /// No description provided for @frameApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get frameApply;

  /// No description provided for @frameSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get frameSupport;

  /// No description provided for @frameSupportFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get frameSupportFree;

  /// No description provided for @frameSupportPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get frameSupportPinned;

  /// No description provided for @frameSupportFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get frameSupportFixed;

  /// No description provided for @frameSupportRollerX.
  ///
  /// In en, this message translates to:
  /// **'Roller (slides in x)'**
  String get frameSupportRollerX;

  /// No description provided for @frameSupportRollerY.
  ///
  /// In en, this message translates to:
  /// **'Roller (slides in y)'**
  String get frameSupportRollerY;

  /// No description provided for @frameNodalLoad.
  ///
  /// In en, this message translates to:
  /// **'Nodal load, case {name}'**
  String frameNodalLoad(String name);

  /// No description provided for @frameApplyLoad.
  ///
  /// In en, this message translates to:
  /// **'Apply load'**
  String get frameApplyLoad;

  /// No description provided for @frameMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Member {n}'**
  String frameMemberTitle(int n);

  /// No description provided for @frameMemberNodes.
  ///
  /// In en, this message translates to:
  /// **'Nodes {a} → {b}'**
  String frameMemberNodes(int a, int b);

  /// No description provided for @frameSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get frameSection;

  /// No description provided for @frameMemberKind.
  ///
  /// In en, this message translates to:
  /// **'Member type'**
  String get frameMemberKind;

  /// No description provided for @frameKindBeam.
  ///
  /// In en, this message translates to:
  /// **'Beam'**
  String get frameKindBeam;

  /// No description provided for @frameKindTruss.
  ///
  /// In en, this message translates to:
  /// **'Truss bar'**
  String get frameKindTruss;

  /// No description provided for @frameHingeStart.
  ///
  /// In en, this message translates to:
  /// **'Hinge at start'**
  String get frameHingeStart;

  /// No description provided for @frameHingeEnd.
  ///
  /// In en, this message translates to:
  /// **'Hinge at end'**
  String get frameHingeEnd;

  /// No description provided for @frameMemberLoad.
  ///
  /// In en, this message translates to:
  /// **'Uniform load, case {name}'**
  String frameMemberLoad(String name);

  /// No description provided for @frameLoadDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get frameLoadDirection;

  /// No description provided for @frameLoadGravity.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get frameLoadGravity;

  /// No description provided for @frameLoadNormal.
  ///
  /// In en, this message translates to:
  /// **'Perpendicular'**
  String get frameLoadNormal;

  /// No description provided for @frameMaxSagging.
  ///
  /// In en, this message translates to:
  /// **'Maximum sagging moment'**
  String get frameMaxSagging;

  /// No description provided for @frameMaxHogging.
  ///
  /// In en, this message translates to:
  /// **'Maximum hogging moment'**
  String get frameMaxHogging;

  /// No description provided for @frameMaxShear.
  ///
  /// In en, this message translates to:
  /// **'Maximum shear'**
  String get frameMaxShear;

  /// No description provided for @frameAxialRange.
  ///
  /// In en, this message translates to:
  /// **'Axial force'**
  String get frameAxialRange;

  /// No description provided for @frameMaxDeflection.
  ///
  /// In en, this message translates to:
  /// **'Maximum deflection'**
  String get frameMaxDeflection;

  /// No description provided for @loadTypePermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get loadTypePermanent;

  /// No description provided for @loadTypeImposed.
  ///
  /// In en, this message translates to:
  /// **'Imposed'**
  String get loadTypeImposed;

  /// No description provided for @loadTypeSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get loadTypeSnow;

  /// No description provided for @loadTypeWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get loadTypeWind;

  /// No description provided for @frameSelfWeight.
  ///
  /// In en, this message translates to:
  /// **'Include self-weight'**
  String get frameSelfWeight;

  /// No description provided for @frameAddCase.
  ///
  /// In en, this message translates to:
  /// **'Add load case'**
  String get frameAddCase;

  /// No description provided for @frameCombinationsNote.
  ///
  /// In en, this message translates to:
  /// **'ULS and SLS combinations are generated from the case types with the selected default code (EN 1990 or BAEL).'**
  String get frameCombinationsNote;

  /// No description provided for @frameAddSection.
  ///
  /// In en, this message translates to:
  /// **'Add section'**
  String get frameAddSection;

  /// No description provided for @frameSectionType.
  ///
  /// In en, this message translates to:
  /// **'Section type'**
  String get frameSectionType;

  /// No description provided for @frameConcreteRect.
  ///
  /// In en, this message translates to:
  /// **'Concrete rectangle'**
  String get frameConcreteRect;

  /// No description provided for @frameProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get frameProfile;

  /// No description provided for @frameSectionNote.
  ///
  /// In en, this message translates to:
  /// **'New members use the selected section.'**
  String get frameSectionNote;

  /// No description provided for @memberDesignButton.
  ///
  /// In en, this message translates to:
  /// **'Design this member'**
  String get memberDesignButton;

  /// No description provided for @memberDesignSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Designed from the ULS envelope of the frame analysis.'**
  String get memberDesignSubtitle;

  /// No description provided for @memberEnvelopeForces.
  ///
  /// In en, this message translates to:
  /// **'ULS envelope forces'**
  String get memberEnvelopeForces;

  /// No description provided for @memberCompression.
  ///
  /// In en, this message translates to:
  /// **'Maximum compression'**
  String get memberCompression;

  /// No description provided for @memberTension.
  ///
  /// In en, this message translates to:
  /// **'Maximum tension'**
  String get memberTension;

  /// No description provided for @memberDesignAs.
  ///
  /// In en, this message translates to:
  /// **'Design as'**
  String get memberDesignAs;

  /// No description provided for @memberBucklingFactor.
  ///
  /// In en, this message translates to:
  /// **'Buckling length factor l0/L'**
  String get memberBucklingFactor;

  /// No description provided for @memberBucklingFactorHelp.
  ///
  /// In en, this message translates to:
  /// **'1.0 for a braced storey column is a safe default; use 0.7 to 0.85 if the ends are restrained by stiff beams.'**
  String get memberBucklingFactorHelp;

  /// No description provided for @memberNoEnvelope.
  ///
  /// In en, this message translates to:
  /// **'No ULS combination: add a load case first.'**
  String get memberNoEnvelope;

  /// No description provided for @memberUnsupportedSection.
  ///
  /// In en, this message translates to:
  /// **'This section cannot be designed here yet'**
  String get memberUnsupportedSection;

  /// No description provided for @memberUnsupportedSectionMsg.
  ///
  /// In en, this message translates to:
  /// **'Concrete rectangles and rolled IPE, HEA and HEB profiles can be designed here.'**
  String get memberUnsupportedSectionMsg;

  /// No description provided for @memberBeamNote.
  ///
  /// In en, this message translates to:
  /// **'Uses the extreme envelope moments of the whole member; curtailment of bars along the span is not optimised.'**
  String get memberBeamNote;

  /// No description provided for @steelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'EN 1993-1-1 · rolled I and H sections'**
  String get steelSubtitle;

  /// No description provided for @steelLength.
  ///
  /// In en, this message translates to:
  /// **'Member length'**
  String get steelLength;

  /// No description provided for @steelLengthHelp.
  ///
  /// In en, this message translates to:
  /// **'Between lateral restraints'**
  String get steelLengthHelp;

  /// No description provided for @steelAxialForce.
  ///
  /// In en, this message translates to:
  /// **'Axial force NEd'**
  String get steelAxialForce;

  /// No description provided for @steelAxialHelp.
  ///
  /// In en, this message translates to:
  /// **'Compression +, tension −'**
  String get steelAxialHelp;

  /// No description provided for @steelMoment.
  ///
  /// In en, this message translates to:
  /// **'Major-axis moment My,Ed'**
  String get steelMoment;

  /// No description provided for @steelShear.
  ///
  /// In en, this message translates to:
  /// **'Shear force VEd'**
  String get steelShear;

  /// No description provided for @steelGrade.
  ///
  /// In en, this message translates to:
  /// **'Steel grade'**
  String get steelGrade;

  /// No description provided for @steelProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get steelProfileTitle;

  /// No description provided for @steelSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get steelSeries;

  /// No description provided for @steelProfile.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get steelProfile;

  /// No description provided for @steelBasisNote.
  ///
  /// In en, this message translates to:
  /// **'γM0 = γM1 = 1.00 (recommended values). Properties computed from the nominal dimensions, including root fillets.'**
  String get steelBasisNote;

  /// No description provided for @steelForcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Design forces (ULS)'**
  String get steelForcesTitle;

  /// No description provided for @steelMomentShape.
  ///
  /// In en, this message translates to:
  /// **'Moment diagram'**
  String get steelMomentShape;

  /// No description provided for @steelShapeUdl.
  ///
  /// In en, this message translates to:
  /// **'UDL'**
  String get steelShapeUdl;

  /// No description provided for @steelShapePoint.
  ///
  /// In en, this message translates to:
  /// **'Point'**
  String get steelShapePoint;

  /// No description provided for @steelShapeUniform.
  ///
  /// In en, this message translates to:
  /// **'Uniform'**
  String get steelShapeUniform;

  /// No description provided for @steelShapeLinear.
  ///
  /// In en, this message translates to:
  /// **'Linear'**
  String get steelShapeLinear;

  /// No description provided for @steelPsiHelp.
  ///
  /// In en, this message translates to:
  /// **'End moment ratio, −1 ≤ ψ ≤ 1'**
  String get steelPsiHelp;

  /// No description provided for @steelBucklingTitle.
  ///
  /// In en, this message translates to:
  /// **'Buckling lengths'**
  String get steelBucklingTitle;

  /// No description provided for @steelBucklingNote.
  ///
  /// In en, this message translates to:
  /// **'Lcr = k × L about the major axis (y), the minor axis (z) and for lateral-torsional buckling. kLT = 1 for a beam restrained only at its ends; a small value for a continuously restrained flange.'**
  String get steelBucklingNote;

  /// No description provided for @steelLightest.
  ///
  /// In en, this message translates to:
  /// **'{name} is enough'**
  String steelLightest(String name);

  /// No description provided for @steelLightestMsg.
  ///
  /// In en, this message translates to:
  /// **'Lightest section of this series passing every check: {a} kg/m instead of {b} kg/m.'**
  String steelLightestMsg(String a, String b);

  /// No description provided for @steelUseProfile.
  ///
  /// In en, this message translates to:
  /// **'Use {name}'**
  String steelUseProfile(String name);

  /// No description provided for @steelResistances.
  ///
  /// In en, this message translates to:
  /// **'Cross-section resistance'**
  String get steelResistances;

  /// No description provided for @steelClass.
  ///
  /// In en, this message translates to:
  /// **'Section class'**
  String get steelClass;

  /// No description provided for @steelAxialResistance.
  ///
  /// In en, this message translates to:
  /// **'Axial resistance'**
  String get steelAxialResistance;

  /// No description provided for @steelMomentResistance.
  ///
  /// In en, this message translates to:
  /// **'Bending resistance'**
  String get steelMomentResistance;

  /// No description provided for @steelShearResistance.
  ///
  /// In en, this message translates to:
  /// **'Shear resistance'**
  String get steelShearResistance;

  /// No description provided for @steelReducedMoment.
  ///
  /// In en, this message translates to:
  /// **'Moment resistance with N and V'**
  String get steelReducedMoment;

  /// No description provided for @steelStability.
  ///
  /// In en, this message translates to:
  /// **'Member stability'**
  String get steelStability;

  /// No description provided for @steelFlexuralY.
  ///
  /// In en, this message translates to:
  /// **'Flexural buckling (y)'**
  String get steelFlexuralY;

  /// No description provided for @steelFlexuralZ.
  ///
  /// In en, this message translates to:
  /// **'Flexural buckling (z)'**
  String get steelFlexuralZ;

  /// No description provided for @steelCriticalMoment.
  ///
  /// In en, this message translates to:
  /// **'Elastic critical moment'**
  String get steelCriticalMoment;

  /// No description provided for @steelLtb.
  ///
  /// In en, this message translates to:
  /// **'Lateral-torsional buckling'**
  String get steelLtb;

  /// No description provided for @steelLtbResistance.
  ///
  /// In en, this message translates to:
  /// **'Buckling moment resistance'**
  String get steelLtbResistance;

  /// No description provided for @steelInteractionFactors.
  ///
  /// In en, this message translates to:
  /// **'Interaction factors (Annex B)'**
  String get steelInteractionFactors;

  /// No description provided for @steelProperties.
  ///
  /// In en, this message translates to:
  /// **'Section properties'**
  String get steelProperties;

  /// No description provided for @steelArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get steelArea;

  /// No description provided for @steelInertia.
  ///
  /// In en, this message translates to:
  /// **'Second moments'**
  String get steelInertia;

  /// No description provided for @steelPlasticModulus.
  ///
  /// In en, this message translates to:
  /// **'Plastic modulus'**
  String get steelPlasticModulus;

  /// No description provided for @steelMass.
  ///
  /// In en, this message translates to:
  /// **'Mass'**
  String get steelMass;

  /// No description provided for @steelNoteScope.
  ///
  /// In en, this message translates to:
  /// **'Major-axis bending only. Loads assumed at the shear centre with free warping at the supports. Class 4 webs use the effective area in compression; local load introduction and web buckling are not checked.'**
  String get steelNoteScope;

  /// No description provided for @checkSteelTension.
  ///
  /// In en, this message translates to:
  /// **'Tension'**
  String get checkSteelTension;

  /// No description provided for @checkSteelCompression.
  ///
  /// In en, this message translates to:
  /// **'Compression (section)'**
  String get checkSteelCompression;

  /// No description provided for @checkSteelBending.
  ///
  /// In en, this message translates to:
  /// **'Bending (section)'**
  String get checkSteelBending;

  /// No description provided for @checkSteelShear.
  ///
  /// In en, this message translates to:
  /// **'Shear (section)'**
  String get checkSteelShear;

  /// No description provided for @checkSteelCombined.
  ///
  /// In en, this message translates to:
  /// **'Bending with N and V'**
  String get checkSteelCombined;

  /// No description provided for @checkFlexuralBucklingY.
  ///
  /// In en, this message translates to:
  /// **'Flexural buckling y-y'**
  String get checkFlexuralBucklingY;

  /// No description provided for @checkFlexuralBucklingZ.
  ///
  /// In en, this message translates to:
  /// **'Flexural buckling z-z'**
  String get checkFlexuralBucklingZ;

  /// No description provided for @checkLtb.
  ///
  /// In en, this message translates to:
  /// **'Lateral-torsional buckling'**
  String get checkLtb;

  /// No description provided for @checkInteractionY.
  ///
  /// In en, this message translates to:
  /// **'Buckling interaction (y)'**
  String get checkInteractionY;

  /// No description provided for @checkInteractionZ.
  ///
  /// In en, this message translates to:
  /// **'Buckling interaction (z)'**
  String get checkInteractionZ;

  /// No description provided for @memberSteelNote.
  ///
  /// In en, this message translates to:
  /// **'Envelope extremes are combined in one check (largest N with largest M), which is conservative. Length L is the member length between its two nodes.'**
  String get memberSteelNote;

  /// No description provided for @timberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'EN 1995-1-1 · solid and glulam rectangular members'**
  String get timberSubtitle;

  /// No description provided for @timberWidth.
  ///
  /// In en, this message translates to:
  /// **'Width b'**
  String get timberWidth;

  /// No description provided for @timberDepth.
  ///
  /// In en, this message translates to:
  /// **'Depth h'**
  String get timberDepth;

  /// No description provided for @timberMaterialTitle.
  ///
  /// In en, this message translates to:
  /// **'Material and environment'**
  String get timberMaterialTitle;

  /// No description provided for @timberStrengthClass.
  ///
  /// In en, this message translates to:
  /// **'Strength class'**
  String get timberStrengthClass;

  /// No description provided for @timberDuration.
  ///
  /// In en, this message translates to:
  /// **'Load duration'**
  String get timberDuration;

  /// No description provided for @timberDurPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get timberDurPermanent;

  /// No description provided for @timberDurLong.
  ///
  /// In en, this message translates to:
  /// **'Long term'**
  String get timberDurLong;

  /// No description provided for @timberDurMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium term'**
  String get timberDurMedium;

  /// No description provided for @timberDurShort.
  ///
  /// In en, this message translates to:
  /// **'Short term'**
  String get timberDurShort;

  /// No description provided for @timberDurInstant.
  ///
  /// In en, this message translates to:
  /// **'Instantaneous'**
  String get timberDurInstant;

  /// No description provided for @timberServiceClass.
  ///
  /// In en, this message translates to:
  /// **'Service class'**
  String get timberServiceClass;

  /// No description provided for @timberServiceNote.
  ///
  /// In en, this message translates to:
  /// **'1: heated interior · 2: covered, unheated · 3: exposed to weather. Load duration is that of the shortest action in the combination (imposed floor loads: medium term; snow: short term; wind: instantaneous).'**
  String get timberServiceNote;

  /// No description provided for @timberBucklingNote.
  ///
  /// In en, this message translates to:
  /// **'Bending about the depth h. Lcr = k × L for buckling about y (in the plane of bending) and z, and lef = kLT × L for lateral-torsional buckling (≈ 0.9 for a uniform load on a simply supported beam, + 2h when the load acts on the compression edge).'**
  String get timberBucklingNote;

  /// No description provided for @timberSlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Deflection (simply supported span)'**
  String get timberSlsTitle;

  /// No description provided for @timberGk.
  ///
  /// In en, this message translates to:
  /// **'Permanent gk'**
  String get timberGk;

  /// No description provided for @timberQk.
  ///
  /// In en, this message translates to:
  /// **'Variable qk'**
  String get timberQk;

  /// No description provided for @timberSlsNote.
  ///
  /// In en, this message translates to:
  /// **'Characteristic uniform loads. Limits: L/300 instantaneous under qk, L/250 final with creep (kdef). Leave 0 to skip.'**
  String get timberSlsNote;

  /// No description provided for @timberStrengths.
  ///
  /// In en, this message translates to:
  /// **'Stresses and design strengths'**
  String get timberStrengths;

  /// No description provided for @timberFactors.
  ///
  /// In en, this message translates to:
  /// **'Modification factors'**
  String get timberFactors;

  /// No description provided for @timberAxialStress.
  ///
  /// In en, this message translates to:
  /// **'Axial stress'**
  String get timberAxialStress;

  /// No description provided for @timberNoteScope.
  ///
  /// In en, this message translates to:
  /// **'Rectangular sections, bending about the major axis only. kcr = 0.67 for shear. Bearing perpendicular to the grain, notches and connections are not checked.'**
  String get timberNoteScope;

  /// No description provided for @checkCombinedStress.
  ///
  /// In en, this message translates to:
  /// **'Bending with axial force'**
  String get checkCombinedStress;

  /// No description provided for @checkDeflectionInstant.
  ///
  /// In en, this message translates to:
  /// **'Instantaneous deflection'**
  String get checkDeflectionInstant;

  /// No description provided for @checkDeflectionFinal.
  ///
  /// In en, this message translates to:
  /// **'Final deflection'**
  String get checkDeflectionFinal;

  /// No description provided for @masonrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'EN 1996-1-1 · single-leaf wall under vertical load'**
  String get masonrySubtitle;

  /// No description provided for @masonryUnit.
  ///
  /// In en, this message translates to:
  /// **'Masonry unit'**
  String get masonryUnit;

  /// No description provided for @masonryClay.
  ///
  /// In en, this message translates to:
  /// **'Clay'**
  String get masonryClay;

  /// No description provided for @masonryConcrete.
  ///
  /// In en, this message translates to:
  /// **'Concrete block'**
  String get masonryConcrete;

  /// No description provided for @masonryCalciumSilicate.
  ///
  /// In en, this message translates to:
  /// **'Calcium silicate'**
  String get masonryCalciumSilicate;

  /// No description provided for @masonryAac.
  ///
  /// In en, this message translates to:
  /// **'Autoclaved aerated concrete'**
  String get masonryAac;

  /// No description provided for @masonryGroup.
  ///
  /// In en, this message translates to:
  /// **'group {n}'**
  String masonryGroup(int n);

  /// No description provided for @masonryFb.
  ///
  /// In en, this message translates to:
  /// **'Unit strength fb'**
  String get masonryFb;

  /// No description provided for @masonryFm.
  ///
  /// In en, this message translates to:
  /// **'Mortar strength fm'**
  String get masonryFm;

  /// No description provided for @masonryGammaHelp.
  ///
  /// In en, this message translates to:
  /// **'Partial factor for masonry, 1.5 to 3.0 depending on execution control (National Annex)'**
  String get masonryGammaHelp;

  /// No description provided for @masonryWallTitle.
  ///
  /// In en, this message translates to:
  /// **'Wall and loading'**
  String get masonryWallTitle;

  /// No description provided for @masonryThickness.
  ///
  /// In en, this message translates to:
  /// **'Thickness t'**
  String get masonryThickness;

  /// No description provided for @masonryHeight.
  ///
  /// In en, this message translates to:
  /// **'Clear height'**
  String get masonryHeight;

  /// No description provided for @masonryRestraint.
  ///
  /// In en, this message translates to:
  /// **'End restraint'**
  String get masonryRestraint;

  /// No description provided for @masonryRhoFloors.
  ///
  /// In en, this message translates to:
  /// **'Floors · ρ2 0.75'**
  String get masonryRhoFloors;

  /// No description provided for @masonryRhoOther.
  ///
  /// In en, this message translates to:
  /// **'Other · ρ2 1.0'**
  String get masonryRhoOther;

  /// No description provided for @masonryLoad.
  ///
  /// In en, this message translates to:
  /// **'Design load NEd'**
  String get masonryLoad;

  /// No description provided for @masonryETop.
  ///
  /// In en, this message translates to:
  /// **'Eccentricity, top'**
  String get masonryETop;

  /// No description provided for @masonryEBottom.
  ///
  /// In en, this message translates to:
  /// **'Eccentricity, bottom'**
  String get masonryEBottom;

  /// No description provided for @masonryEccNote.
  ///
  /// In en, this message translates to:
  /// **'ρ2 = 0.75 when both ends bear on concrete floors. Eccentricity of the load from the floor bearings (M/N), measured from the wall centreline. The initial imperfection hef/450 and the minimum 0.05 t are added automatically.'**
  String get masonryEccNote;

  /// No description provided for @masonryStrength.
  ///
  /// In en, this message translates to:
  /// **'Masonry strength'**
  String get masonryStrength;

  /// No description provided for @masonryFk.
  ///
  /// In en, this message translates to:
  /// **'Characteristic strength'**
  String get masonryFk;

  /// No description provided for @masonryFd.
  ///
  /// In en, this message translates to:
  /// **'Design strength'**
  String get masonryFd;

  /// No description provided for @masonryCapacityTitle.
  ///
  /// In en, this message translates to:
  /// **'Vertical resistance'**
  String get masonryCapacityTitle;

  /// No description provided for @masonryEffHeight.
  ///
  /// In en, this message translates to:
  /// **'Effective height and slenderness'**
  String get masonryEffHeight;

  /// No description provided for @masonryEInit.
  ///
  /// In en, this message translates to:
  /// **'Initial eccentricity'**
  String get masonryEInit;

  /// No description provided for @masonryEnds.
  ///
  /// In en, this message translates to:
  /// **'Top and bottom'**
  String get masonryEnds;

  /// No description provided for @masonryMid.
  ///
  /// In en, this message translates to:
  /// **'Mid-height'**
  String get masonryMid;

  /// No description provided for @masonryCreep.
  ///
  /// In en, this message translates to:
  /// **'Creep eccentricity'**
  String get masonryCreep;

  /// No description provided for @masonryNRd.
  ///
  /// In en, this message translates to:
  /// **'Design resistance per metre'**
  String get masonryNRd;

  /// No description provided for @masonryNoteScope.
  ///
  /// In en, this message translates to:
  /// **'General purpose mortar, unreinforced single-leaf wall. Lateral load (wind), concentrated loads and cavity walls are not covered. Mid-height eccentricity from the end values over the middle fifth.'**
  String get masonryNoteScope;

  /// No description provided for @checkWallEnd.
  ///
  /// In en, this message translates to:
  /// **'Resistance at wall ends'**
  String get checkWallEnd;

  /// No description provided for @checkWallMid.
  ///
  /// In en, this message translates to:
  /// **'Resistance at mid-height'**
  String get checkWallMid;

  /// No description provided for @windSubtitle.
  ///
  /// In en, this message translates to:
  /// **'EN 1991-1-4 wind · EN 1991-1-3 snow'**
  String get windSubtitle;

  /// No description provided for @windTitle.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get windTitle;

  /// No description provided for @windVb.
  ///
  /// In en, this message translates to:
  /// **'Basic wind velocity vb'**
  String get windVb;

  /// No description provided for @windVbHelp.
  ///
  /// In en, this message translates to:
  /// **'vb = cdir · cseason · vb,0 from the National Annex map (France: 22 to 28 m/s by region)'**
  String get windVbHelp;

  /// No description provided for @windTerrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain category'**
  String get windTerrain;

  /// No description provided for @windTerrain0.
  ///
  /// In en, this message translates to:
  /// **'0 · Sea, coastal area'**
  String get windTerrain0;

  /// No description provided for @windTerrainI.
  ///
  /// In en, this message translates to:
  /// **'I · Lakes, flat open land'**
  String get windTerrainI;

  /// No description provided for @windTerrainII.
  ///
  /// In en, this message translates to:
  /// **'II · Low vegetation, isolated obstacles'**
  String get windTerrainII;

  /// No description provided for @windTerrainIII.
  ///
  /// In en, this message translates to:
  /// **'III · Villages, suburbs, forests'**
  String get windTerrainIII;

  /// No description provided for @windTerrainIV.
  ///
  /// In en, this message translates to:
  /// **'IV · Urban, ≥ 15 % built over'**
  String get windTerrainIV;

  /// No description provided for @windHeight.
  ///
  /// In en, this message translates to:
  /// **'Building height h'**
  String get windHeight;

  /// No description provided for @windWidth.
  ///
  /// In en, this message translates to:
  /// **'Width b (across the wind)'**
  String get windWidth;

  /// No description provided for @windDepth.
  ///
  /// In en, this message translates to:
  /// **'Depth d (along the wind)'**
  String get windDepth;

  /// No description provided for @windGeometryNote.
  ///
  /// In en, this message translates to:
  /// **'Rectangular building with a flat roof, reference height ze = h (h ≤ b). Flat terrain (co = 1).'**
  String get windGeometryNote;

  /// No description provided for @snowTitle.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get snowTitle;

  /// No description provided for @snowSk.
  ///
  /// In en, this message translates to:
  /// **'Ground snow load sk'**
  String get snowSk;

  /// No description provided for @snowSkHelp.
  ///
  /// In en, this message translates to:
  /// **'Characteristic value at the site altitude from the National Annex (France: 0.45 to 1.40 kN/m² at sea level by region)'**
  String get snowSkHelp;

  /// No description provided for @snowRoof.
  ///
  /// In en, this message translates to:
  /// **'Roof'**
  String get snowRoof;

  /// No description provided for @snowRoofFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get snowRoofFlat;

  /// No description provided for @snowRoofMono.
  ///
  /// In en, this message translates to:
  /// **'Monopitch'**
  String get snowRoofMono;

  /// No description provided for @snowRoofDuo.
  ///
  /// In en, this message translates to:
  /// **'Duopitch'**
  String get snowRoofDuo;

  /// No description provided for @snowPitch.
  ///
  /// In en, this message translates to:
  /// **'Roof pitch α'**
  String get snowPitch;

  /// No description provided for @snowPitch1.
  ///
  /// In en, this message translates to:
  /// **'Pitch α1'**
  String get snowPitch1;

  /// No description provided for @snowPitch2.
  ///
  /// In en, this message translates to:
  /// **'Pitch α2'**
  String get snowPitch2;

  /// No description provided for @snowCeHelp.
  ///
  /// In en, this message translates to:
  /// **'Exposure: 0.8 windswept, 1.0 normal, 1.2 sheltered'**
  String get snowCeHelp;

  /// No description provided for @windPeakTitle.
  ///
  /// In en, this message translates to:
  /// **'Peak velocity pressure'**
  String get windPeakTitle;

  /// No description provided for @windMeanVelocity.
  ///
  /// In en, this message translates to:
  /// **'Roughness and mean velocity'**
  String get windMeanVelocity;

  /// No description provided for @windTurbulence.
  ///
  /// In en, this message translates to:
  /// **'Turbulence intensity'**
  String get windTurbulence;

  /// No description provided for @windExposure.
  ///
  /// In en, this message translates to:
  /// **'Exposure factor'**
  String get windExposure;

  /// No description provided for @windPeakPressure.
  ///
  /// In en, this message translates to:
  /// **'Peak pressure'**
  String get windPeakPressure;

  /// No description provided for @windWallsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vertical walls (e = {e} m)'**
  String windWallsTitle(String e);

  /// No description provided for @windRoofTitle.
  ///
  /// In en, this message translates to:
  /// **'Flat roof'**
  String get windRoofTitle;

  /// No description provided for @windZone.
  ///
  /// In en, this message translates to:
  /// **'Zone {zone}'**
  String windZone(String zone);

  /// No description provided for @windZoneExtent.
  ///
  /// In en, this message translates to:
  /// **'Zone {zone} · {extent} m'**
  String windZoneExtent(String zone, String extent);

  /// No description provided for @windNetWall.
  ///
  /// In en, this message translates to:
  /// **'Net windward + leeward (D − E)'**
  String get windNetWall;

  /// No description provided for @snowResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Roof snow load'**
  String get snowResultTitle;

  /// No description provided for @snowShape.
  ///
  /// In en, this message translates to:
  /// **'Shape coefficient'**
  String get snowShape;

  /// No description provided for @snowCase.
  ///
  /// In en, this message translates to:
  /// **'Arrangement ({name})'**
  String snowCase(String name);

  /// No description provided for @windNoteScope.
  ///
  /// In en, this message translates to:
  /// **'External pressures we = qp · cpe,10 (loaded areas ≥ 10 m²); positive towards the surface. Add internal pressure cpi = +0.2 or −0.3 when no face is dominant. Roof zones F/G lie along the windward edge over e/10, H over e/2. cs·cd = 1.'**
  String get windNoteScope;

  /// No description provided for @snowNoteScope.
  ///
  /// In en, this message translates to:
  /// **'Persistent design situation, Ct = 1. Drifting at abrupt changes of height, snow guards and exceptional snow are not covered. For duopitch roofs: (i) undrifted, (ii) and (iii) drifted with half load on one slope.'**
  String get snowNoteScope;

  /// No description provided for @windPitchedNote.
  ///
  /// In en, this message translates to:
  /// **'Wind pressure coefficients for pitched roofs (EN 1991-1-4 7.2.4, 7.2.5) are not computed yet; wall zones and qp still apply.'**
  String get windPitchedNote;

  /// No description provided for @seismicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'EN 1998-1 · lateral force method (4.3.3.2)'**
  String get seismicSubtitle;

  /// No description provided for @seismicHazard.
  ///
  /// In en, this message translates to:
  /// **'Seismic action'**
  String get seismicHazard;

  /// No description provided for @seismicZone.
  ///
  /// In en, this message translates to:
  /// **'Zone (France)'**
  String get seismicZone;

  /// No description provided for @seismicZoneCustom.
  ///
  /// In en, this message translates to:
  /// **'Other — enter agR'**
  String get seismicZoneCustom;

  /// No description provided for @seismicZoneN.
  ///
  /// In en, this message translates to:
  /// **'Zone {n} · agR = {ag} m/s²'**
  String seismicZoneN(int n, String ag);

  /// No description provided for @seismicAgR.
  ///
  /// In en, this message translates to:
  /// **'Reference ground acceleration agR'**
  String get seismicAgR;

  /// No description provided for @seismicImportance.
  ///
  /// In en, this message translates to:
  /// **'Importance class'**
  String get seismicImportance;

  /// No description provided for @seismicGround.
  ///
  /// In en, this message translates to:
  /// **'Ground type'**
  String get seismicGround;

  /// No description provided for @seismicSpectrumType.
  ///
  /// In en, this message translates to:
  /// **'Spectrum'**
  String get seismicSpectrumType;

  /// No description provided for @seismicHazardNote.
  ///
  /// In en, this message translates to:
  /// **'Recommended spectrum parameters of EN 1998-1 (Tables 3.2, 3.3) and γI = 0.8 / 1.0 / 1.2 / 1.4. Type 2 for moderate seismicity (mainland France), type 1 for high seismicity (French Antilles). Check the National Annex values for your project.'**
  String get seismicHazardNote;

  /// No description provided for @seismicBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get seismicBuilding;

  /// No description provided for @seismicSystem.
  ///
  /// In en, this message translates to:
  /// **'Structural system (period)'**
  String get seismicSystem;

  /// No description provided for @seismicSysConcrete.
  ///
  /// In en, this message translates to:
  /// **'RC moment frames (Ct = 0.075)'**
  String get seismicSysConcrete;

  /// No description provided for @seismicSysSteel.
  ///
  /// In en, this message translates to:
  /// **'Steel moment frames (Ct = 0.085)'**
  String get seismicSysSteel;

  /// No description provided for @seismicSysOther.
  ///
  /// In en, this message translates to:
  /// **'Walls and other (Ct = 0.050)'**
  String get seismicSysOther;

  /// No description provided for @seismicStoreys.
  ///
  /// In en, this message translates to:
  /// **'Storeys'**
  String get seismicStoreys;

  /// No description provided for @seismicStoreyHeight.
  ///
  /// In en, this message translates to:
  /// **'Storey height'**
  String get seismicStoreyHeight;

  /// No description provided for @seismicFloorMass.
  ///
  /// In en, this message translates to:
  /// **'Mass per floor'**
  String get seismicFloorMass;

  /// No description provided for @seismicRoofMass.
  ///
  /// In en, this message translates to:
  /// **'Roof mass'**
  String get seismicRoofMass;

  /// No description provided for @seismicRoofHelp.
  ///
  /// In en, this message translates to:
  /// **'Roof mass empty = same as floors'**
  String get seismicRoofHelp;

  /// No description provided for @seismicQ.
  ///
  /// In en, this message translates to:
  /// **'Behaviour factor q'**
  String get seismicQ;

  /// No description provided for @seismicQHelp.
  ///
  /// In en, this message translates to:
  /// **'q = 1.5 for low dissipation (DCL)'**
  String get seismicQHelp;

  /// No description provided for @seismicPeriodOverride.
  ///
  /// In en, this message translates to:
  /// **'Period T1'**
  String get seismicPeriodOverride;

  /// No description provided for @seismicPeriodHelp.
  ///
  /// In en, this message translates to:
  /// **'T1 empty = Ct · H^3/4'**
  String get seismicPeriodHelp;

  /// No description provided for @seismicBaseShear.
  ///
  /// In en, this message translates to:
  /// **'Base shear Fb = {fb} kN'**
  String seismicBaseShear(String fb);

  /// No description provided for @seismicMassRatio.
  ///
  /// In en, this message translates to:
  /// **'{pct} % of the seismic weight'**
  String seismicMassRatio(String pct);

  /// No description provided for @seismicPeriodOut.
  ///
  /// In en, this message translates to:
  /// **'T1 exceeds min(4 TC, 2 s): the lateral force method does not apply; use modal response spectrum analysis.'**
  String get seismicPeriodOut;

  /// No description provided for @seismicSpectrumTitle.
  ///
  /// In en, this message translates to:
  /// **'Design spectrum'**
  String get seismicSpectrumTitle;

  /// No description provided for @seismicDesignAg.
  ///
  /// In en, this message translates to:
  /// **'Design ground acceleration'**
  String get seismicDesignAg;

  /// No description provided for @seismicSpectrumParams.
  ///
  /// In en, this message translates to:
  /// **'Spectrum parameters'**
  String get seismicSpectrumParams;

  /// No description provided for @seismicPeriod.
  ///
  /// In en, this message translates to:
  /// **'Fundamental period'**
  String get seismicPeriod;

  /// No description provided for @seismicSd.
  ///
  /// In en, this message translates to:
  /// **'Spectral acceleration'**
  String get seismicSd;

  /// No description provided for @seismicLambda.
  ///
  /// In en, this message translates to:
  /// **'Correction factor'**
  String get seismicLambda;

  /// No description provided for @seismicTotalMass.
  ///
  /// In en, this message translates to:
  /// **'Total seismic mass'**
  String get seismicTotalMass;

  /// No description provided for @seismicOverturning.
  ///
  /// In en, this message translates to:
  /// **'Overturning moment at the base'**
  String get seismicOverturning;

  /// No description provided for @seismicStoreyForces.
  ///
  /// In en, this message translates to:
  /// **'Storey forces and shears'**
  String get seismicStoreyForces;

  /// No description provided for @seismicLevel.
  ///
  /// In en, this message translates to:
  /// **'Level +{z} m'**
  String seismicLevel(String z);

  /// No description provided for @seismicNoteScope.
  ///
  /// In en, this message translates to:
  /// **'Regular building in elevation, one horizontal direction. Floor forces proportional to height × mass (4.11). Accidental torsion, the vertical component, second-order effects and PS92 are not covered yet. Seismic mass = G + ψE,i Q.'**
  String get seismicNoteScope;

  /// No description provided for @slopeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bishop\'s simplified method · automatic critical circle search'**
  String get slopeSubtitle;

  /// No description provided for @slopeGeometry.
  ///
  /// In en, this message translates to:
  /// **'Slope geometry'**
  String get slopeGeometry;

  /// No description provided for @slopeHeight.
  ///
  /// In en, this message translates to:
  /// **'Height H'**
  String get slopeHeight;

  /// No description provided for @slopeAngle.
  ///
  /// In en, this message translates to:
  /// **'Face angle β'**
  String get slopeAngle;

  /// No description provided for @slopeSurcharge.
  ///
  /// In en, this message translates to:
  /// **'Crest surcharge q'**
  String get slopeSurcharge;

  /// No description provided for @slopeMaxDepth.
  ///
  /// In en, this message translates to:
  /// **'Max. depth below toe'**
  String get slopeMaxDepth;

  /// No description provided for @slopeGeometryNote.
  ///
  /// In en, this message translates to:
  /// **'Simple slope from a horizontal crest to a horizontal toe, β ≤ 75°. Max. depth limits deep circles (empty = H).'**
  String get slopeGeometryNote;

  /// No description provided for @slopeSoil.
  ///
  /// In en, this message translates to:
  /// **'Soil (effective parameters)'**
  String get slopeSoil;

  /// No description provided for @slopeGamma.
  ///
  /// In en, this message translates to:
  /// **'Unit weight γ'**
  String get slopeGamma;

  /// No description provided for @slopeCohesion.
  ///
  /// In en, this message translates to:
  /// **'Cohesion c\''**
  String get slopeCohesion;

  /// No description provided for @slopePhi.
  ///
  /// In en, this message translates to:
  /// **'Friction angle φ\''**
  String get slopePhi;

  /// No description provided for @slopeSoilNote.
  ///
  /// In en, this message translates to:
  /// **'Homogeneous soil. Pore pressure ratio ru = u / (γ h): 0 dry, about 0.3 to 0.5 with a high water table. For undrained clay enter c = cu and φ = 0.'**
  String get slopeSoilNote;

  /// No description provided for @slopeCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical slip circle'**
  String get slopeCritical;

  /// No description provided for @slopeFactor.
  ///
  /// In en, this message translates to:
  /// **'Factor of safety'**
  String get slopeFactor;

  /// No description provided for @slopeFactorEc7.
  ///
  /// In en, this message translates to:
  /// **'With EC7 DA3 parameters'**
  String get slopeFactorEc7;

  /// No description provided for @slopeCentre.
  ///
  /// In en, this message translates to:
  /// **'Centre'**
  String get slopeCentre;

  /// No description provided for @slopeRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get slopeRadius;

  /// No description provided for @slopeCircles.
  ///
  /// In en, this message translates to:
  /// **'Circles analysed'**
  String get slopeCircles;

  /// No description provided for @slopeNoteScope.
  ///
  /// In en, this message translates to:
  /// **'Circular slip surfaces only, origin at the crest edge (x right, y up). Required F ≥ 1.5 (traditional) and Fd ≥ 1.0 with tan φ\' and c\' divided by 1.25 and the surcharge × 1.3 (EN 1997-1 DA3). Layered soils, water tables and non-circular surfaces are not covered.'**
  String get slopeNoteScope;

  /// No description provided for @checkSlopeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global factor of safety'**
  String get checkSlopeGlobal;

  /// No description provided for @checkSlopeEc7.
  ///
  /// In en, this message translates to:
  /// **'Overall stability (EC7)'**
  String get checkSlopeEc7;

  /// No description provided for @pileCapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Strut-and-tie (Blévot) · 2, 3 or 4 piles'**
  String get pileCapSubtitle;

  /// No description provided for @pileCapPiles.
  ///
  /// In en, this message translates to:
  /// **'Number of piles'**
  String get pileCapPiles;

  /// No description provided for @pileCapGeometry.
  ///
  /// In en, this message translates to:
  /// **'Load and geometry'**
  String get pileCapGeometry;

  /// No description provided for @pileCapLoad.
  ///
  /// In en, this message translates to:
  /// **'Column load NEd (ULS)'**
  String get pileCapLoad;

  /// No description provided for @pileCapSpacing.
  ///
  /// In en, this message translates to:
  /// **'Pile spacing'**
  String get pileCapSpacing;

  /// No description provided for @pileCapDiameter.
  ///
  /// In en, this message translates to:
  /// **'Pile diameter'**
  String get pileCapDiameter;

  /// No description provided for @pileCapColumn.
  ///
  /// In en, this message translates to:
  /// **'Column side'**
  String get pileCapColumn;

  /// No description provided for @pileCapDepth.
  ///
  /// In en, this message translates to:
  /// **'Cap depth h'**
  String get pileCapDepth;

  /// No description provided for @pileCapEdge.
  ///
  /// In en, this message translates to:
  /// **'Edge beyond piles'**
  String get pileCapEdge;

  /// No description provided for @pileCapGeometryNote.
  ///
  /// In en, this message translates to:
  /// **'Centred square column, piles equally spaced (≥ 2 diameters): in line, triangle or square. Cover measured to the tie bars over the pile heads. Cap self-weight × 1.35 is added.'**
  String get pileCapGeometryNote;

  /// No description provided for @pileCapDepthRange.
  ///
  /// In en, this message translates to:
  /// **'Use a depth between {min} and {max} mm'**
  String pileCapDepthRange(String min, String max);

  /// No description provided for @pileCapDepthMsg.
  ///
  /// In en, this message translates to:
  /// **'The strut angle should stay between 45° and 55° for the strut-and-tie model to be valid.'**
  String get pileCapDepthMsg;

  /// No description provided for @pileCapUseDepth.
  ///
  /// In en, this message translates to:
  /// **'Use the middle of the range'**
  String get pileCapUseDepth;

  /// No description provided for @pileCapModel.
  ///
  /// In en, this message translates to:
  /// **'Strut-and-tie model'**
  String get pileCapModel;

  /// No description provided for @pileCapPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan dimensions'**
  String get pileCapPlan;

  /// No description provided for @pileCapSelfWeight.
  ///
  /// In en, this message translates to:
  /// **'Cap self-weight'**
  String get pileCapSelfWeight;

  /// No description provided for @pileCapReaction.
  ///
  /// In en, this message translates to:
  /// **'Pile reaction (ULS)'**
  String get pileCapReaction;

  /// No description provided for @pileCapAngle.
  ///
  /// In en, this message translates to:
  /// **'Strut angle'**
  String get pileCapAngle;

  /// No description provided for @pileCapTie.
  ///
  /// In en, this message translates to:
  /// **'Force per tie ({n, plural, =1{1 tie} other{{n} ties}})'**
  String pileCapTie(int n);

  /// No description provided for @pileCapTieSteel.
  ///
  /// In en, this message translates to:
  /// **'Steel per tie'**
  String get pileCapTieSteel;

  /// No description provided for @pileCapTieBars.
  ///
  /// In en, this message translates to:
  /// **'Bars per tie (over the piles)'**
  String get pileCapTieBars;

  /// No description provided for @pileCapNodeColumn.
  ///
  /// In en, this message translates to:
  /// **'Node under the column'**
  String get pileCapNodeColumn;

  /// No description provided for @pileCapNodePile.
  ///
  /// In en, this message translates to:
  /// **'Node over each pile'**
  String get pileCapNodePile;

  /// No description provided for @pileCapNoteScope.
  ///
  /// In en, this message translates to:
  /// **'Rigid cap, centred axial load only. Ties run between pile heads and are anchored beyond the pile axes with hooks. Add a nominal mesh (bottom and top) and side bars. Pile capacity and group effects are not checked here. The column node uses the basic limit k1 ν′fcd (EC2 6.5.4(4)a), which is conservative: a confined node may justify a higher limit (6.5.4(6)).'**
  String get pileCapNoteScope;

  /// No description provided for @checkStrutAngle.
  ///
  /// In en, this message translates to:
  /// **'Strut angle'**
  String get checkStrutAngle;

  /// No description provided for @checkTieSteel.
  ///
  /// In en, this message translates to:
  /// **'Tie reinforcement'**
  String get checkTieSteel;

  /// No description provided for @checkNodeColumn.
  ///
  /// In en, this message translates to:
  /// **'Node under the column'**
  String get checkNodeColumn;

  /// No description provided for @checkNodePile.
  ///
  /// In en, this message translates to:
  /// **'Node over the piles'**
  String get checkNodePile;

  /// No description provided for @septicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Volume and layout of a two-compartment tank'**
  String get septicSubtitle;

  /// No description provided for @septicUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get septicUse;

  /// No description provided for @septicUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get septicUsers;

  /// No description provided for @septicRooms.
  ///
  /// In en, this message translates to:
  /// **'Main rooms (house)'**
  String get septicRooms;

  /// No description provided for @septicFlow.
  ///
  /// In en, this message translates to:
  /// **'Wastewater per user'**
  String get septicFlow;

  /// No description provided for @septicRetention.
  ///
  /// In en, this message translates to:
  /// **'Retention time'**
  String get septicRetention;

  /// No description provided for @septicSludge.
  ///
  /// In en, this message translates to:
  /// **'Sludge per user'**
  String get septicSludge;

  /// No description provided for @septicYears.
  ///
  /// In en, this message translates to:
  /// **'Emptying interval'**
  String get septicYears;

  /// No description provided for @septicUseNote.
  ///
  /// In en, this message translates to:
  /// **'Typical values: 100–150 L/d per user with mains water, 40–60 L/d without; 1 day retention; 40 L of sludge per user per year. For a house, enter the number of main rooms to apply the DTU 64.1 minimum (3 m³ up to 5 rooms, + 1 m³ per extra room).'**
  String get septicUseNote;

  /// No description provided for @septicShape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get septicShape;

  /// No description provided for @septicDepth.
  ///
  /// In en, this message translates to:
  /// **'Liquid depth'**
  String get septicDepth;

  /// No description provided for @septicFreeboard.
  ///
  /// In en, this message translates to:
  /// **'Freeboard'**
  String get septicFreeboard;

  /// No description provided for @septicRatio.
  ///
  /// In en, this message translates to:
  /// **'Length / width'**
  String get septicRatio;

  /// No description provided for @septicVolume.
  ///
  /// In en, this message translates to:
  /// **'Liquid volume {v} m³'**
  String septicVolume(String v);

  /// No description provided for @septicDims.
  ///
  /// In en, this message translates to:
  /// **'Inside dimensions {l} × {b} m, total depth {h} m'**
  String septicDims(String l, String b, String h);

  /// No description provided for @septicVolumes.
  ///
  /// In en, this message translates to:
  /// **'Volumes'**
  String get septicVolumes;

  /// No description provided for @septicSettling.
  ///
  /// In en, this message translates to:
  /// **'Settling (flow × retention)'**
  String get septicSettling;

  /// No description provided for @septicSludgeVolume.
  ///
  /// In en, this message translates to:
  /// **'Sludge storage'**
  String get septicSludgeVolume;

  /// No description provided for @septicDtuMin.
  ///
  /// In en, this message translates to:
  /// **'DTU 64.1 minimum'**
  String get septicDtuMin;

  /// No description provided for @septicProvided.
  ///
  /// In en, this message translates to:
  /// **'Volume provided'**
  String get septicProvided;

  /// No description provided for @septicLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get septicLayout;

  /// No description provided for @septicInside.
  ///
  /// In en, this message translates to:
  /// **'Inside dimensions'**
  String get septicInside;

  /// No description provided for @septicCompartments.
  ///
  /// In en, this message translates to:
  /// **'Compartments'**
  String get septicCompartments;

  /// No description provided for @septicNoteScope.
  ///
  /// In en, this message translates to:
  /// **'Sizing guidance only: check local regulations. The soakaway or treatment field, ventilation and the structural design of the walls and slab are not covered.'**
  String get septicNoteScope;
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
