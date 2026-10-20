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
  /// **'Axial, slenderness'**
  String get modColumnSub;

  /// No description provided for @modSlab.
  ///
  /// In en, this message translates to:
  /// **'Slab'**
  String get modSlab;

  /// No description provided for @modSlabSub.
  ///
  /// In en, this message translates to:
  /// **'One-way slab'**
  String get modSlabSub;

  /// No description provided for @modFooting.
  ///
  /// In en, this message translates to:
  /// **'Footing'**
  String get modFooting;

  /// No description provided for @modFootingSub.
  ///
  /// In en, this message translates to:
  /// **'Isolated, combined'**
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
  /// **'Beta: results not yet verified'**
  String get calcBetaTitle;

  /// No description provided for @calcBetaMessage.
  ///
  /// In en, this message translates to:
  /// **'This module is being rewritten and checked against worked examples. Do not use these results for construction.'**
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

  /// No description provided for @calcLoad.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get calcLoad;

  /// No description provided for @calcHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get calcHeight;

  /// No description provided for @beamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simply supported beam under a uniform load.'**
  String get beamSubtitle;

  /// No description provided for @beamGeometryLoad.
  ///
  /// In en, this message translates to:
  /// **'Geometry & load'**
  String get beamGeometryLoad;

  /// No description provided for @beamTotalLoad.
  ///
  /// In en, this message translates to:
  /// **'Total design load'**
  String get beamTotalLoad;

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

  /// No description provided for @beamAdequate.
  ///
  /// In en, this message translates to:
  /// **'Section adequate'**
  String get beamAdequate;

  /// No description provided for @beamAdequateMsg.
  ///
  /// In en, this message translates to:
  /// **'Bending reinforcement found for the design moment.'**
  String get beamAdequateMsg;

  /// No description provided for @beamInadequate.
  ///
  /// In en, this message translates to:
  /// **'Section inadequate'**
  String get beamInadequate;

  /// No description provided for @beamInadequateMsg.
  ///
  /// In en, this message translates to:
  /// **'Increase the section or the concrete class.'**
  String get beamInadequateMsg;

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

  /// No description provided for @beamSuggestedBars.
  ///
  /// In en, this message translates to:
  /// **'Suggested bars'**
  String get beamSuggestedBars;

  /// No description provided for @beamLeverArm.
  ///
  /// In en, this message translates to:
  /// **'Lever arm'**
  String get beamLeverArm;

  /// No description provided for @beamMomentRatio.
  ///
  /// In en, this message translates to:
  /// **'Moment ratio'**
  String get beamMomentRatio;

  /// No description provided for @columnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Circular column under axial load.'**
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

  /// No description provided for @columnSlender.
  ///
  /// In en, this message translates to:
  /// **'Slender column'**
  String get columnSlender;

  /// No description provided for @columnSlenderMsg.
  ///
  /// In en, this message translates to:
  /// **'Second-order effects must be checked.'**
  String get columnSlenderMsg;

  /// No description provided for @columnShort.
  ///
  /// In en, this message translates to:
  /// **'Short column'**
  String get columnShort;

  /// No description provided for @columnShortMsg.
  ///
  /// In en, this message translates to:
  /// **'Second-order effects can be neglected.'**
  String get columnShortMsg;

  /// No description provided for @columnSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get columnSection;

  /// No description provided for @columnDiameter.
  ///
  /// In en, this message translates to:
  /// **'Recommended diameter'**
  String get columnDiameter;

  /// No description provided for @columnRequiredArea.
  ///
  /// In en, this message translates to:
  /// **'Required area'**
  String get columnRequiredArea;

  /// No description provided for @columnHeightRatio.
  ///
  /// In en, this message translates to:
  /// **'Height / diameter'**
  String get columnHeightRatio;

  /// No description provided for @slabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-way slab, simply supported.'**
  String get slabSubtitle;

  /// No description provided for @slabSpanLoad.
  ///
  /// In en, this message translates to:
  /// **'Span & load'**
  String get slabSpanLoad;

  /// No description provided for @slabOneWay.
  ///
  /// In en, this message translates to:
  /// **'One-way slab'**
  String get slabOneWay;

  /// No description provided for @slabThickness.
  ///
  /// In en, this message translates to:
  /// **'Recommended thickness'**
  String get slabThickness;

  /// No description provided for @slabDesignMoment.
  ///
  /// In en, this message translates to:
  /// **'Design moment'**
  String get slabDesignMoment;

  /// No description provided for @slabSteelRequired.
  ///
  /// In en, this message translates to:
  /// **'Steel required'**
  String get slabSteelRequired;

  /// No description provided for @footingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pad footing under a column.'**
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

  /// No description provided for @footingType.
  ///
  /// In en, this message translates to:
  /// **'Footing type'**
  String get footingType;

  /// No description provided for @footingIsolated.
  ///
  /// In en, this message translates to:
  /// **'Isolated'**
  String get footingIsolated;

  /// No description provided for @footingCombined.
  ///
  /// In en, this message translates to:
  /// **'Combined'**
  String get footingCombined;

  /// No description provided for @footingColumnActions.
  ///
  /// In en, this message translates to:
  /// **'Column actions'**
  String get footingColumnActions;

  /// No description provided for @footingAxialLoad.
  ///
  /// In en, this message translates to:
  /// **'Axial load'**
  String get footingAxialLoad;

  /// No description provided for @footingMoment.
  ///
  /// In en, this message translates to:
  /// **'Moment'**
  String get footingMoment;

  /// No description provided for @footingSoil.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get footingSoil;

  /// No description provided for @footingBearing.
  ///
  /// In en, this message translates to:
  /// **'Bearing capacity'**
  String get footingBearing;

  /// No description provided for @footingUnitWeight.
  ///
  /// In en, this message translates to:
  /// **'Unit weight'**
  String get footingUnitWeight;

  /// No description provided for @footingPresizing.
  ///
  /// In en, this message translates to:
  /// **'Pre-sizing: about {area} m² of footing'**
  String footingPresizing(String area);

  /// No description provided for @footingPresizingReason.
  ///
  /// In en, this message translates to:
  /// **'Based on the soil bearing capacity with a safety factor of {sf}.'**
  String footingPresizingReason(String sf);

  /// No description provided for @footingAdequate.
  ///
  /// In en, this message translates to:
  /// **'Design adequate'**
  String get footingAdequate;

  /// No description provided for @footingReview.
  ///
  /// In en, this message translates to:
  /// **'Design needs review'**
  String get footingReview;

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

  /// No description provided for @footingPlanArea.
  ///
  /// In en, this message translates to:
  /// **'Plan area'**
  String get footingPlanArea;

  /// No description provided for @footingRequiredArea.
  ///
  /// In en, this message translates to:
  /// **'Required area'**
  String get footingRequiredArea;

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

  /// No description provided for @footingSteelArea.
  ///
  /// In en, this message translates to:
  /// **'Steel area'**
  String get footingSteelArea;

  /// No description provided for @footingBarSize.
  ///
  /// In en, this message translates to:
  /// **'Bar size'**
  String get footingBarSize;

  /// No description provided for @footingSpacing.
  ///
  /// In en, this message translates to:
  /// **'Spacing'**
  String get footingSpacing;

  /// No description provided for @wallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cantilever wall: overturning check and pre-sizing.'**
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

  /// No description provided for @wallStable.
  ///
  /// In en, this message translates to:
  /// **'Stable against overturning'**
  String get wallStable;

  /// No description provided for @wallOverturningRisk.
  ///
  /// In en, this message translates to:
  /// **'Overturning risk'**
  String get wallOverturningRisk;

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

  /// No description provided for @wallPresizing.
  ///
  /// In en, this message translates to:
  /// **'Pre-sizing (cantilever wall)'**
  String get wallPresizing;

  /// No description provided for @wallBaseWidth.
  ///
  /// In en, this message translates to:
  /// **'Base width'**
  String get wallBaseWidth;

  /// No description provided for @wallStemThickness.
  ///
  /// In en, this message translates to:
  /// **'Stem thickness'**
  String get wallStemThickness;

  /// No description provided for @wallBaseThickness.
  ///
  /// In en, this message translates to:
  /// **'Base thickness'**
  String get wallBaseThickness;

  /// No description provided for @wallToeHeel.
  ///
  /// In en, this message translates to:
  /// **'Toe / heel'**
  String get wallToeHeel;

  /// No description provided for @wallAlternatives.
  ///
  /// In en, this message translates to:
  /// **'Alternative wall types'**
  String get wallAlternatives;

  /// No description provided for @wallBaseApprox.
  ///
  /// In en, this message translates to:
  /// **'Base ≈ {width} m'**
  String wallBaseApprox(String width);

  /// No description provided for @wallGabion.
  ///
  /// In en, this message translates to:
  /// **'Gabion wall'**
  String get wallGabion;

  /// No description provided for @wallGabionDesc.
  ///
  /// In en, this message translates to:
  /// **'Stone-filled wire baskets. Flexible and permeable.'**
  String get wallGabionDesc;

  /// No description provided for @wallGabionPros.
  ///
  /// In en, this message translates to:
  /// **'Excellent drainage, easy to build, tolerates settlement.'**
  String get wallGabionPros;

  /// No description provided for @wallGabionCons.
  ///
  /// In en, this message translates to:
  /// **'Requires a large excavation; the wire mesh can corrode over time.'**
  String get wallGabionCons;

  /// No description provided for @wallStone.
  ///
  /// In en, this message translates to:
  /// **'Stone masonry'**
  String get wallStone;

  /// No description provided for @wallStoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Traditional gravity wall using natural stone.'**
  String get wallStoneDesc;

  /// No description provided for @wallStonePros.
  ///
  /// In en, this message translates to:
  /// **'Highly durable, attractive, uses local materials.'**
  String get wallStonePros;

  /// No description provided for @wallStoneCons.
  ///
  /// In en, this message translates to:
  /// **'Labour-intensive, requires skilled masons.'**
  String get wallStoneCons;

  /// No description provided for @wallBlocks.
  ///
  /// In en, this message translates to:
  /// **'Reinforced hollow blocks'**
  String get wallBlocks;

  /// No description provided for @wallBlocksDesc.
  ///
  /// In en, this message translates to:
  /// **'Cement blocks with vertical rebar and concrete infill.'**
  String get wallBlocksDesc;

  /// No description provided for @wallBlocksPros.
  ///
  /// In en, this message translates to:
  /// **'Faster than traditional masonry, consistent quality.'**
  String get wallBlocksPros;

  /// No description provided for @wallBlocksCons.
  ///
  /// In en, this message translates to:
  /// **'Height limited (usually under 3 m), requires precise rebar placement.'**
  String get wallBlocksCons;

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
