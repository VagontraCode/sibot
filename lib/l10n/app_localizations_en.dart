// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sibot Engineering';

  @override
  String get brandName => 'Sibot';

  @override
  String get brandTagline => 'Engineering';

  @override
  String get navHome => 'Home';

  @override
  String get navProjects => 'Projects';

  @override
  String get navField => 'Field';

  @override
  String get navReports => 'Reports';

  @override
  String get navLibrary => 'Library';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonSwitch => 'Switch';

  @override
  String get commonProject => 'Project';

  @override
  String get commonProjectEyebrow => 'Project';

  @override
  String get commonMore => 'More';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonUntitled => 'Untitled';

  @override
  String get commonPlanned => 'Planned';

  @override
  String commonPhase(int n) {
    return 'Phase $n';
  }

  @override
  String get commonBeta => 'Beta';

  @override
  String get commonOk => 'OK';

  @override
  String get commonReview => 'Review';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n d ago';
  }

  @override
  String timeUpdated(String when) {
    return 'Updated $when';
  }

  @override
  String get statusActive => 'Active';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusArchived => 'Archived';

  @override
  String get statusAll => 'All';

  @override
  String get dashGreetingMorning => 'Good morning';

  @override
  String get dashGreetingAfternoon => 'Good afternoon';

  @override
  String get dashGreetingEvening => 'Good evening';

  @override
  String get dashHeroTitle =>
      'Model, analyse and design,\nright from the site.';

  @override
  String get dashNewProject => 'New project';

  @override
  String get dashOpenProjects => 'Open projects';

  @override
  String get dashStatProjects => 'Projects';

  @override
  String get dashStatCalculations => 'Calculations';

  @override
  String get dashStatModules => 'Design modules';

  @override
  String get dashStatRoadmap => 'On the roadmap';

  @override
  String get dashRecentProjects => 'Recent projects';

  @override
  String get dashDesignModules => 'Design modules';

  @override
  String get dashDesignModulesSubtitle =>
      'Analysis, concrete, foundations and tools';

  @override
  String get dashRoadmap => 'Roadmap';

  @override
  String get dashRoadmapSubtitle => 'Analysis, steel, timber, masonry and more';

  @override
  String dashOpenModuleIn(String module) {
    return 'Open $module in…';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Language, appearance and design defaults.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsDefaultCode => 'Default design code';

  @override
  String get settingsDefaultCodeHelp => 'Used when you open a design module.';

  @override
  String get projectsSubtitle =>
      'Every calculation, photo and report, grouped by project.';

  @override
  String get projectsLoadError => 'Could not load projects';

  @override
  String get projectsEmptyTitle => 'No projects yet';

  @override
  String get projectsEmptyMessage =>
      'Create a project to keep its calculations and field data together.';

  @override
  String get projectsSearchHint => 'Search by name, location or engineer';

  @override
  String get projectsNoMatch => 'No matching projects';

  @override
  String get projectUntitled => 'Untitled project';

  @override
  String get projectFormNew => 'New project';

  @override
  String get projectFormEdit => 'Edit project';

  @override
  String get projectFormName => 'Project name';

  @override
  String get projectFormNameError => 'Give the project a name';

  @override
  String get projectFormLocation => 'Location';

  @override
  String get projectFormEngineer => 'Engineer';

  @override
  String get projectFormDescription => 'Description';

  @override
  String get projectFormStatus => 'Status';

  @override
  String get projectFormSave => 'Save changes';

  @override
  String get projectFormCreate => 'Create project';

  @override
  String get projectPickerTitle => 'Choose a project';

  @override
  String get projectLoadError => 'Could not load project';

  @override
  String get projectNotFound => 'Project not found';

  @override
  String get projectNotFoundMessage => 'It may have been deleted.';

  @override
  String get projectExportPdf => 'Export PDF';

  @override
  String get projectEdit => 'Edit project';

  @override
  String get projectDelete => 'Delete project';

  @override
  String get projectDeleteTitle => 'Delete project?';

  @override
  String projectDeleteMessage(String name) {
    return '\"$name\" will be removed from this device. Its saved calculations and field data stay in storage but will no longer be listed.';
  }

  @override
  String get projectDesignModules => 'Design modules';

  @override
  String get projectField => 'Field';

  @override
  String get projectCalculations => 'Calculations';

  @override
  String get projectCalcLoadError => 'Could not load calculations';

  @override
  String get projectCalcEmptyTitle => 'No calculations yet';

  @override
  String get projectCalcEmptyMessage =>
      'Results you calculate in a module are saved here.';

  @override
  String countPhotos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n photos',
      one: '1 photo',
      zero: 'no photos',
    );
    return '$_temp0';
  }

  @override
  String countReports(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n reports',
      one: '1 report',
      zero: 'no reports',
    );
    return '$_temp0';
  }

  @override
  String countOpen(int n) {
    return '$n open';
  }

  @override
  String get catAnalysis => 'Structural analysis';

  @override
  String get catConcrete => 'Reinforced concrete';

  @override
  String get catSteel => 'Steel';

  @override
  String get catTimber => 'Timber';

  @override
  String get catMasonry => 'Masonry';

  @override
  String get catGeotech => 'Geotechnics';

  @override
  String get catLoads => 'Loads';

  @override
  String get catTools => 'Tools';

  @override
  String get modFrame2d => '2D Frame Analysis';

  @override
  String get modFrame2dSub => 'Frames, trusses, continuous beams';

  @override
  String get modFrame3d => '3D Frame Analysis';

  @override
  String get modFrame3dSub => 'Space frames, modal analysis';

  @override
  String get modBeam => 'Beam';

  @override
  String get modBeamSub => 'Bending, shear';

  @override
  String get modColumn => 'Column';

  @override
  String get modColumnSub => 'N–M, slenderness';

  @override
  String get modSlab => 'Slab';

  @override
  String get modSlabSub => 'One-way, two-way';

  @override
  String get modFooting => 'Footing';

  @override
  String get modFootingSub => 'Isolated, strip, combined';

  @override
  String get modRetainingWall => 'Retaining Wall';

  @override
  String get modRetainingWallSub => 'Stability, pre-sizing';

  @override
  String get modSteelMember => 'Steel Member';

  @override
  String get modSteelMemberSub => 'EC3 checks, buckling';

  @override
  String get modTimberMember => 'Timber Member';

  @override
  String get modTimberMemberSub => 'EC5 checks';

  @override
  String get modMasonryWall => 'Masonry Wall';

  @override
  String get modMasonryWallSub => 'EC6 vertical capacity';

  @override
  String get modBearing => 'Bearing & Settlement';

  @override
  String get modBearingSub => 'EC7 soil checks';

  @override
  String get modSlope => 'Slope Stability';

  @override
  String get modSlopeSub => 'Factor of safety';

  @override
  String get modWindSnow => 'Wind & Snow';

  @override
  String get modWindSnowSub => 'EC1 actions';

  @override
  String get modSeismic => 'Seismic';

  @override
  String get modSeismicSub => 'EC8 / PS92 spectra';

  @override
  String get modSections => 'Section Properties';

  @override
  String get modSectionsSub => 'A, I, W, i';

  @override
  String get modQuantities => 'Quantities';

  @override
  String get modQuantitiesSub => 'Concrete, rebar take-off';

  @override
  String get modPileCap => 'Pile Cap';

  @override
  String get modPileCapSub => 'Pile group, cap design';

  @override
  String get modSeptic => 'Septic Tank';

  @override
  String get modSepticSub => 'Volume sizing';

  @override
  String modPlannedFor(String module, int phase) {
    return '$module is planned for Phase $phase of the roadmap.';
  }

  @override
  String get calcCalculate => 'Calculate';

  @override
  String get calcCalculating => 'Calculating…';

  @override
  String get calcCheckInputs => 'Check the inputs';

  @override
  String get calcBetaTitle => 'Beta: independent verification pending';

  @override
  String get calcBetaMessage =>
      'Calculations follow the cited clauses and pass hand-calculation tests, but have not yet been checked against published worked examples or RSA. Verify results before using them for construction.';

  @override
  String get calcResults => 'Results';

  @override
  String get calcResultsPlaceholder =>
      'Fill in the parameters and tap Calculate.';

  @override
  String get calcMaterials => 'Materials';

  @override
  String get calcConcreteFck => 'Concrete fck';

  @override
  String get calcSteelFyk => 'Steel fyk';

  @override
  String get calcSpan => 'Span';

  @override
  String get beamSubtitle =>
      'Rectangular section: bending, shear and deflection.';

  @override
  String get beamGeometryLoad => 'Geometry & load';

  @override
  String get beamWidth => 'Width b';

  @override
  String get beamDepth => 'Depth h';

  @override
  String get beamBending => 'Bending reinforcement';

  @override
  String get beamSteelRequired => 'Steel area required';

  @override
  String get beamMomentRatio => 'Moment ratio';

  @override
  String get columnSubtitle =>
      'Rectangular column: axial force, bending and slenderness.';

  @override
  String get columnLoadGeometry => 'Load & geometry';

  @override
  String get columnAxialLoad => 'Axial load';

  @override
  String get slabSubtitle => 'One-way or two-way slab, simple or continuous.';

  @override
  String get slabSpanLoad => 'Span & load';

  @override
  String get footingSubtitle =>
      'Isolated, strip or combined footing: sizing, steel, punching.';

  @override
  String get footingDesignBasis => 'Design basis';

  @override
  String get footingCode => 'Design code';

  @override
  String get codeEurocode => 'Eurocode';

  @override
  String get codeBael => 'BAEL 99';

  @override
  String get footingColumnActions => 'Column actions';

  @override
  String get footingSoil => 'Soil';

  @override
  String get footingUnitWeight => 'Unit weight';

  @override
  String get footingDimensions => 'Dimensions';

  @override
  String get footingLxB => 'Length × width';

  @override
  String get footingThickness => 'Thickness';

  @override
  String get footingReinforcement => 'Reinforcement';

  @override
  String get wallSubtitle =>
      'Cantilever wall: stability and stem reinforcement.';

  @override
  String get wallWallSoil => 'Wall & soil';

  @override
  String get wallRetainedHeight => 'Retained height';

  @override
  String get wallSoilUnitWeight => 'Soil unit weight';

  @override
  String get wallFrictionAngle => 'Friction angle φ';

  @override
  String get wallStability => 'Stability';

  @override
  String get wallFosOverturning => 'Factor of safety, overturning';

  @override
  String get wallActiveThrust => 'Active earth thrust';

  @override
  String get wallBaseThickness => 'Base thickness';

  @override
  String get fieldSubtitle =>
      'Photos, daily reports and punch lists from the site.';

  @override
  String get fieldEmptyMessage =>
      'Field data is filed under a project. Create one first.';

  @override
  String get fieldTools => 'Tools';

  @override
  String get fieldPhotosCaption => 'photos';

  @override
  String get fieldReportsCaption => 'reports';

  @override
  String get fieldOpenItemsCaption => 'open items';

  @override
  String get photoLog => 'Photo log';

  @override
  String get photoAdd => 'Add photo';

  @override
  String get photoLoadError => 'Could not load photos';

  @override
  String get photoEmptyTitle => 'No photos yet';

  @override
  String get photoEmptyMessage =>
      'Document progress, defects and rebar before pours.';

  @override
  String get photoCamera => 'Camera';

  @override
  String get photoGallery => 'Gallery';

  @override
  String get photoDescription => 'Description';

  @override
  String get photoLocation => 'Location on site';

  @override
  String get photoLocationHint => 'e.g. Grid B-3, level 2';

  @override
  String get photoSave => 'Save photo';

  @override
  String get reportDaily => 'Daily reports';

  @override
  String get reportNew => 'New report';

  @override
  String get reportLoadError => 'Could not load reports';

  @override
  String get reportEmptyTitle => 'No reports yet';

  @override
  String get reportEmptyMessage =>
      'Log weather, workforce, progress and safety each day.';

  @override
  String get reportNoSummary => 'No summary';

  @override
  String reportWorkers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workers',
      one: '1 worker',
    );
    return '$_temp0';
  }

  @override
  String get reportWeather => 'Weather';

  @override
  String get reportWorkersOnSite => 'Workers on site';

  @override
  String get reportWorkersField => 'Workers';

  @override
  String get reportProgress => 'Progress';

  @override
  String get reportSafety => 'Safety';

  @override
  String get reportSafetyNotes => 'Safety notes';

  @override
  String get reportDailyTitle => 'Daily report';

  @override
  String get reportSave => 'Save report';

  @override
  String get punchList => 'Punch list';

  @override
  String get punchAdd => 'Add item';

  @override
  String get punchLoadError => 'Could not load the punch list';

  @override
  String get punchEmptyTitle => 'Nothing to fix yet';

  @override
  String get punchEmptyMessage =>
      'Track defects and snags until they are closed out.';

  @override
  String punchOpenTab(int n) {
    return 'Open · $n';
  }

  @override
  String punchClosedTab(int n) {
    return 'Closed · $n';
  }

  @override
  String get punchNothingClosed => 'Nothing closed yet';

  @override
  String get punchAllClear => 'All clear';

  @override
  String get punchSwipeHint =>
      'Swipe right to close an item, left to delete it.';

  @override
  String punchAssignedTo(String name) {
    return 'Assigned to $name';
  }

  @override
  String get punchNew => 'New punch item';

  @override
  String get punchWhat => 'What needs fixing?';

  @override
  String get punchAssignedLabel => 'Assigned to';

  @override
  String get punchPriority => 'Priority';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String get reportsSubtitle => 'PDF calculation notes and site records.';

  @override
  String get reportsEmptyMessage => 'Reports are generated per project.';

  @override
  String get reportsGenerate => 'Generate';

  @override
  String get reportsSummary => 'Project summary';

  @override
  String get reportsSummaryDesc =>
      'Footing and beam calculations, and the punch list, in one PDF.';

  @override
  String get reportsCalcNotes => 'Calculation notes';

  @override
  String get reportsCalcNotesDesc =>
      'Formulas, code clauses and diagrams for each module.';

  @override
  String get reportsFieldAudit => 'Field audit';

  @override
  String get reportsFieldAuditDesc => 'Daily reports, photos and punch list.';

  @override
  String get librarySubtitle => 'Design codes, material data and quick tools.';

  @override
  String get libraryConverter => 'Unit converter';

  @override
  String get libraryLength => 'Length';

  @override
  String get libraryForce => 'Force';

  @override
  String get libraryPressure => 'Pressure';

  @override
  String get libraryValue => 'Value';

  @override
  String get librarySwap => 'Swap';

  @override
  String get libraryMaterials => 'Materials';

  @override
  String get libraryConcrete => 'Concrete';

  @override
  String get librarySteel => 'Structural steel';

  @override
  String get libraryRebar => 'Reinforcing bars';

  @override
  String libraryTable(String code, String table) {
    return '$code, Table $table';
  }

  @override
  String get libraryRebarSource => 'Area πd²/4, mass at 7850 kg/m³';

  @override
  String get libraryColClass => 'Class';

  @override
  String get libraryColGrade => 'Grade';

  @override
  String get libraryColArea => 'Area mm²';

  @override
  String get libraryColMass => 'Mass kg/m';

  @override
  String get libraryCodes => 'Design codes';

  @override
  String get libraryCodesSubtitle =>
      'Codes the suite is being built to support';

  @override
  String get codeEc0 => 'Basis of design, combinations';

  @override
  String get codeEc1 => 'Actions: loads, wind, snow';

  @override
  String get codeEc2 => 'Concrete structures';

  @override
  String get codeEc3 => 'Steel structures';

  @override
  String get codeEc5 => 'Timber structures';

  @override
  String get codeEc6 => 'Masonry structures';

  @override
  String get codeEc7 => 'Geotechnical design';

  @override
  String get codeEc8 => 'Earthquake resistance';

  @override
  String get codeBaelDesc => 'Reinforced concrete (FR)';

  @override
  String get codePs92Desc => 'Seismic rules (FR)';

  @override
  String get calcCover => 'Cover';

  @override
  String get loadPermanent => 'Permanent load g';

  @override
  String get loadVariable => 'Variable load q';

  @override
  String get loadPermanentArea => 'Permanent load g';

  @override
  String get loadVariableArea => 'Variable load q';

  @override
  String get loadPermanentPoint => 'Permanent load G';

  @override
  String get loadVariablePoint => 'Variable load Q';

  @override
  String get loadSelfWeightNote =>
      'Characteristic loads. Self-weight is added automatically; ULS combination 1.35G + 1.5Q.';

  @override
  String get beamSupport => 'Supports';

  @override
  String get beamSimplySupported => 'Simple span';

  @override
  String get beamCantilever => 'Cantilever';

  @override
  String get resultDesignForces => 'Design forces';

  @override
  String get resultUlsLoad => 'ULS load';

  @override
  String get resultMoment => 'Design moment';

  @override
  String get resultShear => 'Design shear';

  @override
  String get resultEffectiveDepth => 'Effective depth';

  @override
  String get resultBottomBars => 'Bottom bars';

  @override
  String get resultTopBars => 'Top bars';

  @override
  String get resultLinks => 'Links';

  @override
  String get checksTitle => 'Checks';

  @override
  String get checkBendingSteel => 'Bending reinforcement';

  @override
  String get checkMinSteel => 'Minimum reinforcement';

  @override
  String get checkMaxSteel => 'Maximum reinforcement';

  @override
  String get checkBarSpacing => 'Clear bar spacing';

  @override
  String get checkShearConcrete => 'Shear (concrete)';

  @override
  String get checkShearLinks => 'Shear reinforcement';

  @override
  String get checkLinkSpacing => 'Link spacing';

  @override
  String get checkDeflection => 'Deflection';

  @override
  String get checkSlenderness => 'Slenderness';

  @override
  String get checkAxialBending => 'Axial force and bending';

  @override
  String get checkBearing => 'Bearing pressure';

  @override
  String get checkPunching => 'Punching shear';

  @override
  String get checkOverturning => 'Overturning';

  @override
  String get checkSliding => 'Sliding';

  @override
  String get checkEccentricity => 'Eccentricity';

  @override
  String get verdictOk => 'All checks satisfied';

  @override
  String verdictFail(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n checks not satisfied',
      one: '1 check not satisfied',
    );
    return '$_temp0';
  }

  @override
  String verdictUtilisation(String pct) {
    return 'Highest utilisation $pct %';
  }

  @override
  String problemMissing(String field) {
    return 'Enter $field.';
  }

  @override
  String problemNotPositive(String field) {
    return '$field must be greater than 0.';
  }

  @override
  String problemOutOfRange(String field) {
    return '$field is outside the range this method covers.';
  }

  @override
  String problemGeometry(String field) {
    return '$field is not consistent with the other dimensions.';
  }

  @override
  String get noteCompressionSteel =>
      'The moment exceeds the limit for a singly reinforced section: compression steel is required.';

  @override
  String get noteBarsDoNotFit =>
      'No standard bar arrangement fits in one layer. Increase the section.';

  @override
  String get noteLinksNotFound =>
      'Links up to Ø12 cannot carry the shear. Increase the section.';

  @override
  String get noteDeflectionNotCovered =>
      'The BAEL deflection exemption does not cover cantilevers: calculate the deflection.';

  @override
  String get columnWidthB => 'Width b';

  @override
  String get columnDepthH => 'Depth h (bending direction)';

  @override
  String get columnBucklingLength => 'Buckling length l0';

  @override
  String get columnMoment => 'First-order moment';

  @override
  String get columnCreep => 'Effective creep ratio φef';

  @override
  String get columnUlsNote =>
      'ULS design values. The h-direction moment bends the section across h; the b-direction moment across b.';

  @override
  String get columnSlendernessTitle => 'Slenderness and moments';

  @override
  String get columnImperfection => 'Imperfection eccentricity';

  @override
  String get columnSecondOrder => 'Second-order eccentricity';

  @override
  String get columnLongitudinalBars => 'Longitudinal bars';

  @override
  String get columnAxialResistance => 'Axial resistance';

  @override
  String get columnMomentResistance => 'Moment resistance at NEd';

  @override
  String get columnInteraction => 'N–M interaction diagram';

  @override
  String get noteSecondOrder =>
      'λ > λlim: second-order moment added by the nominal curvature method (EN 1992-1-1 5.8.8).';

  @override
  String get noteBaelCentred => 'Centred compression: BAEL B.8.4 α method.';

  @override
  String get noteSlendernessOutOfScope =>
      'Slenderness beyond the method\'s range: a buckling analysis is required.';

  @override
  String get noteSectionTooSmall =>
      'The maximum steel ratio is not enough. Increase the section.';

  @override
  String get slabType => 'Slab type';

  @override
  String get slabOneWayShort => 'One-way';

  @override
  String get slabTwoWayShort => 'Two-way';

  @override
  String get slabContinuous => 'Continuous';

  @override
  String get slabShortSpan => 'Short span lx';

  @override
  String get slabLongSpan => 'Long span ly';

  @override
  String get slabThicknessInput => 'Thickness h';

  @override
  String get slabCoefficients => 'Panel coefficients';

  @override
  String get slabMomentXSpan => 'Span moment, x';

  @override
  String get slabMomentSupport => 'Support moment';

  @override
  String get slabMomentYSpan => 'Span moment, y';

  @override
  String get slabBarsXSpan => 'Bottom, x direction';

  @override
  String get slabBarsSupport => 'Top, over supports';

  @override
  String get slabBarsYSpan => 'Bottom, y direction';

  @override
  String get slabDistribution => 'Distribution bars';

  @override
  String get noteTreatedAsOneWay =>
      'lx/ly < 0.4: the panel is designed as one-way.';

  @override
  String get noteBaelPanel =>
      'Two-way moments from BAEL 91 Annexe E3 coefficients (ν = 0 at ULS).';

  @override
  String get noteContinuityCoefficients =>
      'Continuity by simplified coefficients: 0.75 M0 in span, 0.5 M0 over supports (BAEL A.8.2.32).';

  @override
  String get footingColumnA => 'Column a (moment direction)';

  @override
  String get footingColumnB => 'Column b';

  @override
  String get footingMomentG => 'Moment from G';

  @override
  String get footingMomentQ => 'Moment from Q';

  @override
  String get footingAllowable => 'Allowable bearing pressure';

  @override
  String get footingDepthInput => 'Founding depth';

  @override
  String get footingCharacteristicNote =>
      'Characteristic (service) column loads. Sizing at SLS, steel at ULS.';

  @override
  String get footingSelfWeight => 'Footing and backfill weight';

  @override
  String get footingPressure => 'Ground pressure';

  @override
  String get footingBarsAlongA => 'Bars parallel to A';

  @override
  String get footingBarsAlongB => 'Bars parallel to B';

  @override
  String get noteSizeLimit =>
      'The footing would exceed 10 m: check the soil or the loads.';

  @override
  String get noteFootingBael =>
      'Rigid footing designed by the strut-and-tie method (méthode des bielles); pressure at 3/4 width.';

  @override
  String get noteFootingEc2 =>
      'Bending at 0.15a inside the column face (EN 1992-1-1 9.8.2.2); pressure on the effective area (EN 1997-1 Annex D).';

  @override
  String get wallGeometry => 'Geometry';

  @override
  String get wallPresizeButton => 'Pre-size from height';

  @override
  String get wallToeLength => 'Toe length';

  @override
  String get wallHeelLength => 'Heel length';

  @override
  String get wallStemTop => 'Stem thickness, top';

  @override
  String get wallStemBottom => 'Stem thickness, base';

  @override
  String get wallSurcharge => 'Surcharge q';

  @override
  String get wallToe => 'toe';

  @override
  String get wallHeel => 'heel';

  @override
  String get wallKa => 'Active pressure coefficient';

  @override
  String get wallFosSliding => 'Factor of safety, sliding';

  @override
  String get wallStem => 'Stem';

  @override
  String get wallStemBars => 'Vertical bars, soil face';

  @override
  String get noteWallMethod =>
      'Stability with Rankine active pressure and global factors of safety of 1.5. EC7 partial-factor design comes with the geotechnics module.';

  @override
  String get noteWallShearKey =>
      'Sliding is not satisfied: add a shear key or lengthen the heel.';

  @override
  String get columnDiameter => 'Diameter D';

  @override
  String get columnMomentH => 'Moment, h direction';

  @override
  String get columnMomentB => 'Moment, b direction';

  @override
  String get columnMomentX => 'Moment Mx';

  @override
  String get columnMomentY => 'Moment My';

  @override
  String get columnShape => 'Section';

  @override
  String get columnRectangular => 'Rectangular';

  @override
  String get columnCircular => 'Circular';

  @override
  String get columnUlsNoteCircle =>
      'ULS design values. The two moments are combined vectorially.';

  @override
  String get columnBarsPerFace => 'Bars per face';

  @override
  String get noteBiaxial =>
      'Moments in both directions: biaxial check EN 1992-1-1 5.8.9(4).';

  @override
  String get noteImperfectionOneDirection =>
      'Imperfection and minimum eccentricity are applied in one direction at a time (EN 1992-1-1 5.8.9(2)); the worse case governs.';

  @override
  String get checkConcreteStress => 'Concrete stress (SLS)';

  @override
  String get checkSteelStress => 'Steel stress (SLS)';

  @override
  String get checkCrackWidth => 'Crack width';

  @override
  String get diagramShear => 'Shear force V';

  @override
  String get diagramMoment => 'Bending moment M';

  @override
  String get slsTitle => 'Serviceability';

  @override
  String get slsCracking => 'Cracking class';

  @override
  String get slsCrackingSlight => 'Not harmful';

  @override
  String get slsCrackingHarmful => 'Harmful';

  @override
  String get slsCrackingVeryHarmful => 'Very harmful';

  @override
  String get slsPsi2 => 'Quasi-permanent factor ψ2';

  @override
  String get slsCrackLimit => 'Crack width limit wmax';

  @override
  String get slsCharMoment => 'Characteristic moment';

  @override
  String get slsConcreteStress => 'Concrete stress';

  @override
  String get slsSteelStress => 'Steel stress';

  @override
  String get slsQpMoment => 'Quasi-permanent moment';

  @override
  String get slsCrackSpacing => 'Maximum crack spacing';

  @override
  String get punchingTitle => 'Punching (optional)';

  @override
  String get punchingType => 'Load type';

  @override
  String get punchingColumn => 'Interior column';

  @override
  String get punchingPointLoad => 'Point load';

  @override
  String get punchingOptionalNote =>
      'Leave the load empty to skip punching. ULS load on a c1 × c2 area.';

  @override
  String get punchingLoad => 'Punching load VEd';

  @override
  String get punchingC1 => 'Loaded area c1';

  @override
  String get punchingC2 => 'Loaded area c2';

  @override
  String get punchingPerimeter => 'Control perimeter';

  @override
  String get punchingDemand => 'Punching action';

  @override
  String get punchingResistance => 'Resistance without reinforcement';

  @override
  String get punchingReinforcement =>
      'Punching reinforcement per perimeter (sr = 0.75d)';

  @override
  String get footingTypeLabel => 'Footing type';

  @override
  String get footingIsolatedType => 'Isolated';

  @override
  String get footingStripType => 'Strip';

  @override
  String get footingCombinedType => 'Combined';

  @override
  String get footingWallActions => 'Wall actions (per metre)';

  @override
  String get footingWallThickness => 'Wall thickness';

  @override
  String get footingCol1A => 'Column 1, a (along footing)';

  @override
  String get footingCol1B => 'Column 1, b';

  @override
  String get footingCol2A => 'Column 2, a (along footing)';

  @override
  String get footingCol2B => 'Column 2, b';

  @override
  String get footingSpacingInput => 'Column spacing (centres)';

  @override
  String get footingG1 => 'Column 1, G';

  @override
  String get footingQ1 => 'Column 1, Q';

  @override
  String get footingG2 => 'Column 2, G';

  @override
  String get footingQ2 => 'Column 2, Q';

  @override
  String get footingWidth => 'Width';

  @override
  String get footingTransverseBars => 'Transverse bars';

  @override
  String get footingOverhang => 'Overhang beyond column 1';

  @override
  String get footingLongBottom => 'Longitudinal, bottom';

  @override
  String get footingLongTop => 'Longitudinal, top';

  @override
  String footingTransverseUnder(int n) {
    return 'Transverse under column $n';
  }

  @override
  String get noteCombinedFooting =>
      'Length set so the service resultant is at mid-length; designed as a beam on a linear soil reaction. Thickness increased until no shear links are needed.';

  @override
  String get noteSoilEc7 =>
      'Bearing resistance from EN 1997-1 Annex D, design approach 2 (γR,v = 1.4), vertical load.';

  @override
  String get soilBearingMode => 'Bearing check';

  @override
  String get soilModeAllowable => 'Allowable pressure';

  @override
  String get soilModeParameters => 'Soil parameters (EC7)';

  @override
  String get soilDrainage => 'Soil condition';

  @override
  String get soilDrained => 'Drained (c′, φ′)';

  @override
  String get soilUndrained => 'Undrained (cu)';

  @override
  String get soilCohesion => 'Cohesion c′';

  @override
  String get soilPhi => 'Friction angle φ′';

  @override
  String get soilCu => 'Undrained strength cu';

  @override
  String get soilModulus => 'Young\'s modulus E';

  @override
  String get soilPoisson => 'Poisson\'s ratio ν';

  @override
  String get wallBase => 'Base slab';

  @override
  String get wallUlsPressure => 'ULS base pressure, toe / heel';

  @override
  String get wallToeMoment => 'Toe, bottom bars';

  @override
  String get wallHeelMoment => 'Heel, top bars';

  @override
  String get wallEqu => 'EQU overturning';

  @override
  String get wallDa2Sliding => 'DA2 sliding';

  @override
  String get noteWallEc7 =>
      'EC7: overturning by EQU (γG,dst 1.1, γG,stb 0.9, γφ′ 1.25), sliding by DA2 (1.35 / 1.5, γR,h 1.1). Global factors are shown for information.';

  @override
  String get bearingSubtitle =>
      'EC7 bearing resistance and settlement of a shallow footing.';

  @override
  String get bearingWidth => 'Width B';

  @override
  String get bearingLength => 'Length L';

  @override
  String get bearingLoadNote =>
      'Characteristic loads including the footing and backfill weight.';

  @override
  String get bearingResistance => 'Bearing resistance';

  @override
  String get bearingFactors => 'Bearing factors';

  @override
  String get bearingUltimate => 'Ultimate bearing pressure';

  @override
  String get bearingDesignResistance => 'Design resistance';

  @override
  String get bearingDesignPressure => 'Design pressure (1.35G + 1.5Q)';

  @override
  String get bearingSettlement => 'Settlement';

  @override
  String get bearingServicePressure => 'Service pressure';

  @override
  String get noteSettlementEstimate =>
      'Settlement is an elastic estimate for a rigid footing (equivalent circle); use oedometer results for clays.';

  @override
  String get sectionsSubtitle => 'Area, inertia and section moduli.';

  @override
  String get sectionShape => 'Shape';

  @override
  String get sectionRect => 'Rectangle';

  @override
  String get sectionCircle => 'Circle';

  @override
  String get sectionHollow => 'Hollow';

  @override
  String get sectionI => 'I';

  @override
  String get sectionT => 'T';

  @override
  String get sectionWidth => 'Width b';

  @override
  String get sectionHeight => 'Height h';

  @override
  String get sectionThickness => 'Wall thickness t';

  @override
  String get sectionFlange => 'Flange thickness tf';

  @override
  String get sectionWeb => 'Web thickness tw';

  @override
  String get sectionResults => 'Properties';

  @override
  String get sectionArea => 'Area';

  @override
  String get sectionCentroid => 'Centroid from top';

  @override
  String get sectionInertiaY => 'Second moment, strong axis';

  @override
  String get sectionInertiaZ => 'Second moment, weak axis';

  @override
  String get sectionWelTop => 'Elastic modulus, top';

  @override
  String get sectionWelBottom => 'Elastic modulus, bottom';

  @override
  String get sectionWpl => 'Plastic modulus';

  @override
  String get sectionRadii => 'Radii of gyration';

  @override
  String get noteSectionNoFillets =>
      'Root fillets are not included; tabulated values for rolled sections are slightly higher.';

  @override
  String get quantitiesSubtitle =>
      'Concrete materials, formwork and rebar weights.';

  @override
  String get qtyElements => 'Elements';

  @override
  String get qtyLength => 'Length';

  @override
  String get qtyWidth => 'Width';

  @override
  String get qtyHeight => 'Height / thickness';

  @override
  String get qtyCount => 'Number';

  @override
  String get qtyFormworkType => 'Formwork faces';

  @override
  String get qtyColumnWall => 'Column / wall';

  @override
  String get qtyMix => 'Mix per m³';

  @override
  String get qtyCement => 'Cement';

  @override
  String get qtySand => 'Sand';

  @override
  String get qtyGravel => 'Gravel';

  @override
  String get qtyWater => 'Water';

  @override
  String get qtyWaste => 'Waste allowance';

  @override
  String get qtyRebar => 'Reinforcement';

  @override
  String get qtyBarDiameter => 'Bar diameter';

  @override
  String get qtyBarCount => 'Number of bars';

  @override
  String get qtyBarLength => 'Bar length';

  @override
  String get qtyLap => 'Laps and waste';

  @override
  String get qtyConcrete => 'Concrete';

  @override
  String get qtyVolume => 'Volume';

  @override
  String get qtyCementTotal => 'Cement';

  @override
  String qtyBags(int n) {
    return '$n bags of 50 kg';
  }

  @override
  String get qtySandTotal => 'Sand';

  @override
  String get qtyGravelTotal => 'Gravel';

  @override
  String get qtyWaterTotal => 'Water';

  @override
  String get qtyFormwork => 'Formwork area';

  @override
  String get qtyRebarLength => 'Total length';

  @override
  String get qtyRebarMass => 'Mass';

  @override
  String get qtyStockBars => '12 m bars to order';

  @override
  String get qtyNothing => 'Fill in the elements or the reinforcement.';

  @override
  String get noteQuantitiesMix =>
      'Default mix is a common site dosage (350 kg/m³). Adjust it to your mix design.';

  @override
  String get frameSubtitle =>
      'Frames, continuous beams and trusses: model, analyse, read diagrams.';

  @override
  String get frameNewModel => 'New model';

  @override
  String get frameLoadError => 'Could not load models';

  @override
  String get frameEmptyTitle => 'No models yet';

  @override
  String get frameEmptyMessage =>
      'Start from a continuous beam, a frame or a truss, or draw your own.';

  @override
  String frameCounts(int nodes, int members) {
    return '$nodes nodes, $members members';
  }

  @override
  String get frameTemplateInvalid => 'Check the template dimensions.';

  @override
  String get frameTemplateBeam => 'Continuous beam';

  @override
  String get frameTemplateFrame => 'Frame';

  @override
  String get frameTemplateTruss => 'Truss';

  @override
  String get frameTemplateBlank => 'Blank';

  @override
  String get frameModelName => 'Model name';

  @override
  String get frameSpans => 'Spans';

  @override
  String get frameSpansHelp => 'Separate spans with commas, e.g. 5, 6, 5';

  @override
  String get frameBays => 'Bays';

  @override
  String get frameBayWidth => 'Bay width';

  @override
  String get frameStoreys => 'Storeys';

  @override
  String get frameStoreyHeight => 'Storey height';

  @override
  String get frameTrussType => 'Truss type';

  @override
  String get frameSpan => 'Span';

  @override
  String get frameTrussHeight => 'Height';

  @override
  String get framePanels => 'Panels';

  @override
  String get frameWindPerFloor => 'Wind force per floor (left side)';

  @override
  String get frameTemplateNote =>
      'Characteristic loads, downwards. Self-weight is added to G. Sections and loads can be changed afterwards.';

  @override
  String get frameCreate => 'Create model';

  @override
  String get frameUndo => 'Undo';

  @override
  String get frameRedo => 'Redo';

  @override
  String get frameFit => 'Fit to screen';

  @override
  String get frameLoadCases => 'Load cases';

  @override
  String get frameSections => 'Sections';

  @override
  String get frameModeModel => 'Model';

  @override
  String get frameModeResults => 'Results';

  @override
  String get frameEnvelope => 'ULS envelope';

  @override
  String get frameViewDeformed => 'Deformed';

  @override
  String get frameViewReactions => 'Reactions';

  @override
  String get frameResultSource => 'Case or combination';

  @override
  String get frameAnalysisFailed => 'Analysis not possible';

  @override
  String get frameErrEmpty => 'Add nodes and members first.';

  @override
  String get frameErrZeroLength => 'A member has zero length.';

  @override
  String get frameErrUnstable =>
      'The structure is unstable: add supports or remove hinges so it cannot move freely.';

  @override
  String get frameErrInvalid =>
      'The model contains an invalid member or section.';

  @override
  String get frameRename => 'Rename model';

  @override
  String get frameToolSelect => 'Select';

  @override
  String get frameToolNode => 'Node';

  @override
  String get frameToolMember => 'Member';

  @override
  String get frameToolSupport => 'Support';

  @override
  String get frameToolLoad => 'Load';

  @override
  String get frameHintSelect =>
      'Tap a node or member to edit it. Pinch to zoom, drag to pan.';

  @override
  String frameHintNode(String grid) {
    return 'Tap to place nodes (grid $grid m).';
  }

  @override
  String get frameHintMember =>
      'Tap a start point, then an end point. Members chain.';

  @override
  String get frameHintSupport =>
      'Tap a node to cycle: free, pinned, fixed, roller.';

  @override
  String get frameHintLoad =>
      'Tap a member or node to set its load in the active case.';

  @override
  String get frameActiveCase => 'Active load case';

  @override
  String frameNodeTitle(int n) {
    return 'Node $n';
  }

  @override
  String get frameApply => 'Apply';

  @override
  String get frameSupport => 'Support';

  @override
  String get frameSupportFree => 'Free';

  @override
  String get frameSupportPinned => 'Pinned';

  @override
  String get frameSupportFixed => 'Fixed';

  @override
  String get frameSupportRollerX => 'Roller (slides in x)';

  @override
  String get frameSupportRollerY => 'Roller (slides in y)';

  @override
  String frameNodalLoad(String name) {
    return 'Nodal load, case $name';
  }

  @override
  String get frameApplyLoad => 'Apply load';

  @override
  String frameMemberTitle(int n) {
    return 'Member $n';
  }

  @override
  String frameMemberNodes(int a, int b) {
    return 'Nodes $a → $b';
  }

  @override
  String get frameSection => 'Section';

  @override
  String get frameMemberKind => 'Member type';

  @override
  String get frameKindBeam => 'Beam';

  @override
  String get frameKindTruss => 'Truss bar';

  @override
  String get frameHingeStart => 'Hinge at start';

  @override
  String get frameHingeEnd => 'Hinge at end';

  @override
  String frameMemberLoad(String name) {
    return 'Uniform load, case $name';
  }

  @override
  String get frameLoadDirection => 'Direction';

  @override
  String get frameLoadGravity => 'Vertical';

  @override
  String get frameLoadNormal => 'Perpendicular';

  @override
  String get frameMaxSagging => 'Maximum sagging moment';

  @override
  String get frameMaxHogging => 'Maximum hogging moment';

  @override
  String get frameMaxShear => 'Maximum shear';

  @override
  String get frameAxialRange => 'Axial force';

  @override
  String get frameMaxDeflection => 'Maximum deflection';

  @override
  String get loadTypePermanent => 'Permanent';

  @override
  String get loadTypeImposed => 'Imposed';

  @override
  String get loadTypeSnow => 'Snow';

  @override
  String get loadTypeWind => 'Wind';

  @override
  String get frameSelfWeight => 'Include self-weight';

  @override
  String get frameAddCase => 'Add load case';

  @override
  String get frameCombinationsNote =>
      'ULS and SLS combinations are generated from the case types with the selected default code (EN 1990 or BAEL).';

  @override
  String get frameAddSection => 'Add section';

  @override
  String get frameSectionType => 'Section type';

  @override
  String get frameConcreteRect => 'Concrete rectangle';

  @override
  String get frameProfile => 'Profile';

  @override
  String get frameSectionNote => 'New members use the selected section.';

  @override
  String get memberDesignButton => 'Design this member';

  @override
  String get memberDesignSubtitle =>
      'Designed from the ULS envelope of the frame analysis.';

  @override
  String get memberEnvelopeForces => 'ULS envelope forces';

  @override
  String get memberCompression => 'Maximum compression';

  @override
  String get memberTension => 'Maximum tension';

  @override
  String get memberDesignAs => 'Design as';

  @override
  String get memberBucklingFactor => 'Buckling length factor l0/L';

  @override
  String get memberBucklingFactorHelp =>
      '1.0 for a braced storey column is a safe default; use 0.7 to 0.85 if the ends are restrained by stiff beams.';

  @override
  String get memberNoEnvelope => 'No ULS combination: add a load case first.';

  @override
  String get memberUnsupportedSection =>
      'This section cannot be designed here yet';

  @override
  String get memberUnsupportedSectionMsg =>
      'Concrete rectangles and rolled IPE, HEA and HEB profiles can be designed here.';

  @override
  String get memberBeamNote =>
      'Uses the extreme envelope moments of the whole member; curtailment of bars along the span is not optimised.';

  @override
  String get steelSubtitle => 'EN 1993-1-1 · rolled I and H sections';

  @override
  String get steelLength => 'Member length';

  @override
  String get steelLengthHelp => 'Between lateral restraints';

  @override
  String get steelAxialForce => 'Axial force NEd';

  @override
  String get steelAxialHelp => 'Compression +, tension −';

  @override
  String get steelMoment => 'Major-axis moment My,Ed';

  @override
  String get steelShear => 'Shear force VEd';

  @override
  String get steelGrade => 'Steel grade';

  @override
  String get steelProfileTitle => 'Profile';

  @override
  String get steelSeries => 'Series';

  @override
  String get steelProfile => 'Section';

  @override
  String get steelBasisNote =>
      'γM0 = γM1 = 1.00 (recommended values). Properties computed from the nominal dimensions, including root fillets.';

  @override
  String get steelForcesTitle => 'Design forces (ULS)';

  @override
  String get steelMomentShape => 'Moment diagram';

  @override
  String get steelShapeUdl => 'UDL';

  @override
  String get steelShapePoint => 'Point';

  @override
  String get steelShapeUniform => 'Uniform';

  @override
  String get steelShapeLinear => 'Linear';

  @override
  String get steelPsiHelp => 'End moment ratio, −1 ≤ ψ ≤ 1';

  @override
  String get steelBucklingTitle => 'Buckling lengths';

  @override
  String get steelBucklingNote =>
      'Lcr = k × L about the major axis (y), the minor axis (z) and for lateral-torsional buckling. kLT = 1 for a beam restrained only at its ends; a small value for a continuously restrained flange.';

  @override
  String steelLightest(String name) {
    return '$name is enough';
  }

  @override
  String steelLightestMsg(String a, String b) {
    return 'Lightest section of this series passing every check: $a kg/m instead of $b kg/m.';
  }

  @override
  String steelUseProfile(String name) {
    return 'Use $name';
  }

  @override
  String get steelResistances => 'Cross-section resistance';

  @override
  String get steelClass => 'Section class';

  @override
  String get steelAxialResistance => 'Axial resistance';

  @override
  String get steelMomentResistance => 'Bending resistance';

  @override
  String get steelShearResistance => 'Shear resistance';

  @override
  String get steelReducedMoment => 'Moment resistance with N and V';

  @override
  String get steelStability => 'Member stability';

  @override
  String get steelFlexuralY => 'Flexural buckling (y)';

  @override
  String get steelFlexuralZ => 'Flexural buckling (z)';

  @override
  String get steelCriticalMoment => 'Elastic critical moment';

  @override
  String get steelLtb => 'Lateral-torsional buckling';

  @override
  String get steelLtbResistance => 'Buckling moment resistance';

  @override
  String get steelInteractionFactors => 'Interaction factors (Annex B)';

  @override
  String get steelProperties => 'Section properties';

  @override
  String get steelArea => 'Area';

  @override
  String get steelInertia => 'Second moments';

  @override
  String get steelPlasticModulus => 'Plastic modulus';

  @override
  String get steelMass => 'Mass';

  @override
  String get steelNoteScope =>
      'Major-axis bending only. Loads assumed at the shear centre with free warping at the supports. Class 4 webs use the effective area in compression; local load introduction and web buckling are not checked.';

  @override
  String get checkSteelTension => 'Tension';

  @override
  String get checkSteelCompression => 'Compression (section)';

  @override
  String get checkSteelBending => 'Bending (section)';

  @override
  String get checkSteelShear => 'Shear (section)';

  @override
  String get checkSteelCombined => 'Bending with N and V';

  @override
  String get checkFlexuralBucklingY => 'Flexural buckling y-y';

  @override
  String get checkFlexuralBucklingZ => 'Flexural buckling z-z';

  @override
  String get checkLtb => 'Lateral-torsional buckling';

  @override
  String get checkInteractionY => 'Buckling interaction (y)';

  @override
  String get checkInteractionZ => 'Buckling interaction (z)';

  @override
  String get memberSteelNote =>
      'Envelope extremes are combined in one check (largest N with largest M), which is conservative. Length L is the member length between its two nodes.';

  @override
  String get timberSubtitle =>
      'EN 1995-1-1 · solid and glulam rectangular members';

  @override
  String get timberWidth => 'Width b';

  @override
  String get timberDepth => 'Depth h';

  @override
  String get timberMaterialTitle => 'Material and environment';

  @override
  String get timberStrengthClass => 'Strength class';

  @override
  String get timberDuration => 'Load duration';

  @override
  String get timberDurPermanent => 'Permanent';

  @override
  String get timberDurLong => 'Long term';

  @override
  String get timberDurMedium => 'Medium term';

  @override
  String get timberDurShort => 'Short term';

  @override
  String get timberDurInstant => 'Instantaneous';

  @override
  String get timberServiceClass => 'Service class';

  @override
  String get timberServiceNote =>
      '1: heated interior · 2: covered, unheated · 3: exposed to weather. Load duration is that of the shortest action in the combination (imposed floor loads: medium term; snow: short term; wind: instantaneous).';

  @override
  String get timberBucklingNote =>
      'Bending about the depth h. Lcr = k × L for buckling about y (in the plane of bending) and z, and lef = kLT × L for lateral-torsional buckling (≈ 0.9 for a uniform load on a simply supported beam, + 2h when the load acts on the compression edge).';

  @override
  String get timberSlsTitle => 'Deflection (simply supported span)';

  @override
  String get timberGk => 'Permanent gk';

  @override
  String get timberQk => 'Variable qk';

  @override
  String get timberSlsNote =>
      'Characteristic uniform loads. Limits: L/300 instantaneous under qk, L/250 final with creep (kdef). Leave 0 to skip.';

  @override
  String get timberStrengths => 'Stresses and design strengths';

  @override
  String get timberFactors => 'Modification factors';

  @override
  String get timberAxialStress => 'Axial stress';

  @override
  String get timberNoteScope =>
      'Rectangular sections, bending about the major axis only. kcr = 0.67 for shear. Bearing perpendicular to the grain, notches and connections are not checked.';

  @override
  String get checkCombinedStress => 'Bending with axial force';

  @override
  String get checkDeflectionInstant => 'Instantaneous deflection';

  @override
  String get checkDeflectionFinal => 'Final deflection';

  @override
  String get masonrySubtitle =>
      'EN 1996-1-1 · single-leaf wall under vertical load';

  @override
  String get masonryUnit => 'Masonry unit';

  @override
  String get masonryClay => 'Clay';

  @override
  String get masonryConcrete => 'Concrete block';

  @override
  String get masonryCalciumSilicate => 'Calcium silicate';

  @override
  String get masonryAac => 'Autoclaved aerated concrete';

  @override
  String masonryGroup(int n) {
    return 'group $n';
  }

  @override
  String get masonryFb => 'Unit strength fb';

  @override
  String get masonryFm => 'Mortar strength fm';

  @override
  String get masonryGammaHelp =>
      'Partial factor for masonry, 1.5 to 3.0 depending on execution control (National Annex)';

  @override
  String get masonryWallTitle => 'Wall and loading';

  @override
  String get masonryThickness => 'Thickness t';

  @override
  String get masonryHeight => 'Clear height';

  @override
  String get masonryRestraint => 'End restraint';

  @override
  String get masonryRhoFloors => 'Floors · ρ2 0.75';

  @override
  String get masonryRhoOther => 'Other · ρ2 1.0';

  @override
  String get masonryLoad => 'Design load NEd';

  @override
  String get masonryETop => 'Eccentricity, top';

  @override
  String get masonryEBottom => 'Eccentricity, bottom';

  @override
  String get masonryEccNote =>
      'ρ2 = 0.75 when both ends bear on concrete floors. Eccentricity of the load from the floor bearings (M/N), measured from the wall centreline. The initial imperfection hef/450 and the minimum 0.05 t are added automatically.';

  @override
  String get masonryStrength => 'Masonry strength';

  @override
  String get masonryFk => 'Characteristic strength';

  @override
  String get masonryFd => 'Design strength';

  @override
  String get masonryCapacityTitle => 'Vertical resistance';

  @override
  String get masonryEffHeight => 'Effective height and slenderness';

  @override
  String get masonryEInit => 'Initial eccentricity';

  @override
  String get masonryEnds => 'Top and bottom';

  @override
  String get masonryMid => 'Mid-height';

  @override
  String get masonryCreep => 'Creep eccentricity';

  @override
  String get masonryNRd => 'Design resistance per metre';

  @override
  String get masonryNoteScope =>
      'General purpose mortar, unreinforced single-leaf wall. Lateral load (wind), concentrated loads and cavity walls are not covered. Mid-height eccentricity from the end values over the middle fifth.';

  @override
  String get checkWallEnd => 'Resistance at wall ends';

  @override
  String get checkWallMid => 'Resistance at mid-height';

  @override
  String get windSubtitle => 'EN 1991-1-4 wind · EN 1991-1-3 snow';

  @override
  String get windTitle => 'Wind';

  @override
  String get windVb => 'Basic wind velocity vb';

  @override
  String get windVbHelp =>
      'vb = cdir · cseason · vb,0 from the National Annex map (France: 22 to 28 m/s by region)';

  @override
  String get windTerrain => 'Terrain category';

  @override
  String get windTerrain0 => '0 · Sea, coastal area';

  @override
  String get windTerrainI => 'I · Lakes, flat open land';

  @override
  String get windTerrainII => 'II · Low vegetation, isolated obstacles';

  @override
  String get windTerrainIII => 'III · Villages, suburbs, forests';

  @override
  String get windTerrainIV => 'IV · Urban, ≥ 15 % built over';

  @override
  String get windHeight => 'Building height h';

  @override
  String get windWidth => 'Width b (across the wind)';

  @override
  String get windDepth => 'Depth d (along the wind)';

  @override
  String get windGeometryNote =>
      'Rectangular building with a flat roof, reference height ze = h (h ≤ b). Flat terrain (co = 1).';

  @override
  String get snowTitle => 'Snow';

  @override
  String get snowSk => 'Ground snow load sk';

  @override
  String get snowSkHelp =>
      'Characteristic value at the site altitude from the National Annex (France: 0.45 to 1.40 kN/m² at sea level by region)';

  @override
  String get snowRoof => 'Roof';

  @override
  String get snowRoofFlat => 'Flat';

  @override
  String get snowRoofMono => 'Monopitch';

  @override
  String get snowRoofDuo => 'Duopitch';

  @override
  String get snowPitch => 'Roof pitch α';

  @override
  String get snowPitch1 => 'Pitch α1';

  @override
  String get snowPitch2 => 'Pitch α2';

  @override
  String get snowCeHelp => 'Exposure: 0.8 windswept, 1.0 normal, 1.2 sheltered';

  @override
  String get windPeakTitle => 'Peak velocity pressure';

  @override
  String get windMeanVelocity => 'Roughness and mean velocity';

  @override
  String get windTurbulence => 'Turbulence intensity';

  @override
  String get windExposure => 'Exposure factor';

  @override
  String get windPeakPressure => 'Peak pressure';

  @override
  String windWallsTitle(String e) {
    return 'Vertical walls (e = $e m)';
  }

  @override
  String get windRoofTitle => 'Flat roof';

  @override
  String windZone(String zone) {
    return 'Zone $zone';
  }

  @override
  String windZoneExtent(String zone, String extent) {
    return 'Zone $zone · $extent m';
  }

  @override
  String get windNetWall => 'Net windward + leeward (D − E)';

  @override
  String get snowResultTitle => 'Roof snow load';

  @override
  String get snowShape => 'Shape coefficient';

  @override
  String snowCase(String name) {
    return 'Arrangement ($name)';
  }

  @override
  String get windNoteScope =>
      'External pressures we = qp · cpe,10 (loaded areas ≥ 10 m²); positive towards the surface. Add internal pressure cpi = +0.2 or −0.3 when no face is dominant. Roof zones F/G lie along the windward edge over e/10, H over e/2. cs·cd = 1.';

  @override
  String get snowNoteScope =>
      'Persistent design situation, Ct = 1. Drifting at abrupt changes of height, snow guards and exceptional snow are not covered. For duopitch roofs: (i) undrifted, (ii) and (iii) drifted with half load on one slope.';

  @override
  String get windPitchedNote =>
      'Wind pressure coefficients for pitched roofs (EN 1991-1-4 7.2.4, 7.2.5) are not computed yet; wall zones and qp still apply.';

  @override
  String get seismicSubtitle => 'EN 1998-1 · lateral force method (4.3.3.2)';

  @override
  String get seismicHazard => 'Seismic action';

  @override
  String get seismicZone => 'Zone (France)';

  @override
  String get seismicZoneCustom => 'Other — enter agR';

  @override
  String seismicZoneN(int n, String ag) {
    return 'Zone $n · agR = $ag m/s²';
  }

  @override
  String get seismicAgR => 'Reference ground acceleration agR';

  @override
  String get seismicImportance => 'Importance class';

  @override
  String get seismicGround => 'Ground type';

  @override
  String get seismicSpectrumType => 'Spectrum';

  @override
  String get seismicHazardNote =>
      'Recommended spectrum parameters of EN 1998-1 (Tables 3.2, 3.3) and γI = 0.8 / 1.0 / 1.2 / 1.4. Type 2 for moderate seismicity (mainland France), type 1 for high seismicity (French Antilles). Check the National Annex values for your project.';

  @override
  String get seismicBuilding => 'Building';

  @override
  String get seismicSystem => 'Structural system (period)';

  @override
  String get seismicSysConcrete => 'RC moment frames (Ct = 0.075)';

  @override
  String get seismicSysSteel => 'Steel moment frames (Ct = 0.085)';

  @override
  String get seismicSysOther => 'Walls and other (Ct = 0.050)';

  @override
  String get seismicStoreys => 'Storeys';

  @override
  String get seismicStoreyHeight => 'Storey height';

  @override
  String get seismicFloorMass => 'Mass per floor';

  @override
  String get seismicRoofMass => 'Roof mass';

  @override
  String get seismicRoofHelp => 'Roof mass empty = same as floors';

  @override
  String get seismicQ => 'Behaviour factor q';

  @override
  String get seismicQHelp => 'q = 1.5 for low dissipation (DCL)';

  @override
  String get seismicPeriodOverride => 'Period T1';

  @override
  String get seismicPeriodHelp => 'T1 empty = Ct · H^3/4';

  @override
  String seismicBaseShear(String fb) {
    return 'Base shear Fb = $fb kN';
  }

  @override
  String seismicMassRatio(String pct) {
    return '$pct % of the seismic weight';
  }

  @override
  String get seismicPeriodOut =>
      'T1 exceeds min(4 TC, 2 s): the lateral force method does not apply; use modal response spectrum analysis.';

  @override
  String get seismicSpectrumTitle => 'Design spectrum';

  @override
  String get seismicDesignAg => 'Design ground acceleration';

  @override
  String get seismicSpectrumParams => 'Spectrum parameters';

  @override
  String get seismicPeriod => 'Fundamental period';

  @override
  String get seismicSd => 'Spectral acceleration';

  @override
  String get seismicLambda => 'Correction factor';

  @override
  String get seismicTotalMass => 'Total seismic mass';

  @override
  String get seismicOverturning => 'Overturning moment at the base';

  @override
  String get seismicStoreyForces => 'Storey forces and shears';

  @override
  String seismicLevel(String z) {
    return 'Level +$z m';
  }

  @override
  String get seismicNoteScope =>
      'Regular building in elevation, one horizontal direction. Floor forces proportional to height × mass (4.11). Accidental torsion, the vertical component, second-order effects and PS92 are not covered yet. Seismic mass = G + ψE,i Q.';

  @override
  String get slopeSubtitle =>
      'Bishop\'s simplified method · automatic critical circle search';

  @override
  String get slopeGeometry => 'Slope geometry';

  @override
  String get slopeHeight => 'Height H';

  @override
  String get slopeAngle => 'Face angle β';

  @override
  String get slopeSurcharge => 'Crest surcharge q';

  @override
  String get slopeMaxDepth => 'Max. depth below toe';

  @override
  String get slopeGeometryNote =>
      'Simple slope from a horizontal crest to a horizontal toe, β ≤ 75°. Max. depth limits deep circles (empty = H).';

  @override
  String get slopeSoil => 'Soil (effective parameters)';

  @override
  String get slopeGamma => 'Unit weight γ';

  @override
  String get slopeCohesion => 'Cohesion c\'';

  @override
  String get slopePhi => 'Friction angle φ\'';

  @override
  String get slopeSoilNote =>
      'Homogeneous soil. Pore pressure ratio ru = u / (γ h): 0 dry, about 0.3 to 0.5 with a high water table. For undrained clay enter c = cu and φ = 0.';

  @override
  String get slopeCritical => 'Critical slip circle';

  @override
  String get slopeFactor => 'Factor of safety';

  @override
  String get slopeFactorEc7 => 'With EC7 DA3 parameters';

  @override
  String get slopeCentre => 'Centre';

  @override
  String get slopeRadius => 'Radius';

  @override
  String get slopeCircles => 'Circles analysed';

  @override
  String get slopeNoteScope =>
      'Circular slip surfaces only, origin at the crest edge (x right, y up). Required F ≥ 1.5 (traditional) and Fd ≥ 1.0 with tan φ\' and c\' divided by 1.25 and the surcharge × 1.3 (EN 1997-1 DA3). Layered soils, water tables and non-circular surfaces are not covered.';

  @override
  String get checkSlopeGlobal => 'Global factor of safety';

  @override
  String get checkSlopeEc7 => 'Overall stability (EC7)';

  @override
  String get pileCapSubtitle => 'Strut-and-tie (Blévot) · 2, 3 or 4 piles';

  @override
  String get pileCapPiles => 'Number of piles';

  @override
  String get pileCapGeometry => 'Load and geometry';

  @override
  String get pileCapLoad => 'Column load NEd (ULS)';

  @override
  String get pileCapSpacing => 'Pile spacing';

  @override
  String get pileCapDiameter => 'Pile diameter';

  @override
  String get pileCapColumn => 'Column side';

  @override
  String get pileCapDepth => 'Cap depth h';

  @override
  String get pileCapEdge => 'Edge beyond piles';

  @override
  String get pileCapGeometryNote =>
      'Centred square column, piles equally spaced (≥ 2 diameters): in line, triangle or square. Cover measured to the tie bars over the pile heads. Cap self-weight × 1.35 is added.';

  @override
  String pileCapDepthRange(String min, String max) {
    return 'Use a depth between $min and $max mm';
  }

  @override
  String get pileCapDepthMsg =>
      'The strut angle should stay between 45° and 55° for the strut-and-tie model to be valid.';

  @override
  String get pileCapUseDepth => 'Use the middle of the range';

  @override
  String get pileCapModel => 'Strut-and-tie model';

  @override
  String get pileCapPlan => 'Plan dimensions';

  @override
  String get pileCapSelfWeight => 'Cap self-weight';

  @override
  String get pileCapReaction => 'Pile reaction (ULS)';

  @override
  String get pileCapAngle => 'Strut angle';

  @override
  String pileCapTie(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ties',
      one: '1 tie',
    );
    return 'Force per tie ($_temp0)';
  }

  @override
  String get pileCapTieSteel => 'Steel per tie';

  @override
  String get pileCapTieBars => 'Bars per tie (over the piles)';

  @override
  String get pileCapNodeColumn => 'Node under the column';

  @override
  String get pileCapNodePile => 'Node over each pile';

  @override
  String get pileCapNoteScope =>
      'Rigid cap, centred axial load only. Ties run between pile heads and are anchored beyond the pile axes with hooks. Add a nominal mesh (bottom and top) and side bars. Pile capacity and group effects are not checked here. The column node uses the basic limit k1 ν′fcd (EC2 6.5.4(4)a), which is conservative: a confined node may justify a higher limit (6.5.4(6)).';

  @override
  String get checkStrutAngle => 'Strut angle';

  @override
  String get checkTieSteel => 'Tie reinforcement';

  @override
  String get checkNodeColumn => 'Node under the column';

  @override
  String get checkNodePile => 'Node over the piles';

  @override
  String get septicSubtitle => 'Volume and layout of a two-compartment tank';

  @override
  String get septicUse => 'Use';

  @override
  String get septicUsers => 'Users';

  @override
  String get septicRooms => 'Main rooms (house)';

  @override
  String get septicFlow => 'Wastewater per user';

  @override
  String get septicRetention => 'Retention time';

  @override
  String get septicSludge => 'Sludge per user';

  @override
  String get septicYears => 'Emptying interval';

  @override
  String get septicUseNote =>
      'Typical values: 100–150 L/d per user with mains water, 40–60 L/d without; 1 day retention; 40 L of sludge per user per year. For a house, enter the number of main rooms to apply the DTU 64.1 minimum (3 m³ up to 5 rooms, + 1 m³ per extra room).';

  @override
  String get septicShape => 'Shape';

  @override
  String get septicDepth => 'Liquid depth';

  @override
  String get septicFreeboard => 'Freeboard';

  @override
  String get septicRatio => 'Length / width';

  @override
  String septicVolume(String v) {
    return 'Liquid volume $v m³';
  }

  @override
  String septicDims(String l, String b, String h) {
    return 'Inside dimensions $l × $b m, total depth $h m';
  }

  @override
  String get septicVolumes => 'Volumes';

  @override
  String get septicSettling => 'Settling (flow × retention)';

  @override
  String get septicSludgeVolume => 'Sludge storage';

  @override
  String get septicDtuMin => 'DTU 64.1 minimum';

  @override
  String get septicProvided => 'Volume provided';

  @override
  String get septicLayout => 'Layout';

  @override
  String get septicInside => 'Inside dimensions';

  @override
  String get septicCompartments => 'Compartments';

  @override
  String get septicNoteScope =>
      'Sizing guidance only: check local regulations. The soakaway or treatment field, ventilation and the structural design of the walls and slab are not covered.';

  @override
  String get f3dSubtitle =>
      'Space frames: static, modal, response spectrum and buckling';

  @override
  String get f3dNewBuilding => 'New building';

  @override
  String get f3dEditBuilding => 'Edit building';

  @override
  String get f3dEmptyTitle => 'No 3D model yet';

  @override
  String get f3dEmptyMessage =>
      'Generate a building frame from its grid, storeys, sections and floor loads, then explore it in 3D.';

  @override
  String f3dGridSummary(int x, int y, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n storeys',
      one: '1 storey',
    );
    return '$x × $y bays · $_temp0';
  }

  @override
  String f3dDefaultName(int x, int y, int n) {
    return 'Building $x×$y R+$n';
  }

  @override
  String get f3dWizardInvalid =>
      'Check the values: whole numbers of bays (1–20) and storeys (1–40), positive spans, heights and sections.';

  @override
  String get f3dGrid => 'Grid';

  @override
  String get f3dBaysX => 'Bays in X';

  @override
  String get f3dSpanX => 'Span X';

  @override
  String get f3dBaysY => 'Bays in Y';

  @override
  String get f3dSpanY => 'Span Y';

  @override
  String get f3dStoreys => 'Storeys';

  @override
  String get f3dGroundHeight => 'Ground storey';

  @override
  String get f3dStoreyHeight => 'Typical storey';

  @override
  String get f3dSections => 'Sections';

  @override
  String get f3dMaterial => 'Material';

  @override
  String get f3dColumns => 'Columns';

  @override
  String get f3dBeams => 'Beams';

  @override
  String get f3dLoads => 'Floor loads';

  @override
  String get f3dFloorG => 'Permanent g';

  @override
  String get f3dFloorQ => 'Imposed q';

  @override
  String get f3dFacade => 'Facade on edge beams';

  @override
  String get f3dLoadsNote =>
      'Applied at every level including the roof, carried to the beams by 45° lines (moment-equivalent uniform loads). Member self-weight is added to G.';

  @override
  String get f3dSave => 'Save and analyse';

  @override
  String get f3dTabModel => 'Model';

  @override
  String get f3dTabStatic => 'Static';

  @override
  String get f3dTabModes => 'Modes';

  @override
  String get f3dTabSeismic => 'Seismic';

  @override
  String get f3dTabBuckling => 'Buckling';

  @override
  String get f3dFootprint => 'Size L × W × H';

  @override
  String get f3dNodesMembers => 'Nodes / members';

  @override
  String get f3dSeismicMass => 'Seismic mass';

  @override
  String get f3dModelNote =>
      'Fixed column bases, rigid joints; slabs act as rigid diaphragms when selected and are otherwise not modelled (beams carry the floor loads). Drag to orbit, pinch to zoom, two fingers to pan, double-tap to reset the view.';

  @override
  String get f3dCombination => 'Combination';

  @override
  String get f3dColourBy => 'Show';

  @override
  String get f3dDeformed => 'Shape';

  @override
  String get f3dPDelta => 'Second order (P-Δ)';

  @override
  String get f3dPDeltaHelp =>
      'Iterates with the geometric stiffness of the axial forces.';

  @override
  String get f3dMaxVertical => 'Max. vertical displacement';

  @override
  String get f3dMaxLateral => 'Max. horizontal displacement';

  @override
  String get f3dMaxBeamMoment => 'Max. beam moment';

  @override
  String get f3dMaxColumnLoad => 'Max. column compression';

  @override
  String get f3dTotalReaction => 'Total vertical reaction';

  @override
  String get f3dNoModes => 'No vibrating mass: add loads or self-weight.';

  @override
  String get f3dModesHelp => 'Mass from G + 0.3 Q. Tap a mode to animate it.';

  @override
  String f3dCumulativeMass(String x, String y) {
    return 'Cumulative mass: X $x · Y $y';
  }

  @override
  String get f3dCumulativeHelp =>
      'EN 1998-1 4.3.3.3.1 asks for at least 90 % of the mass in each direction.';

  @override
  String get f3dDirection => 'Direction';

  @override
  String get f3dRunSpectrum => 'Run response spectrum';

  @override
  String f3dSpectrumMass(String pct) {
    return 'Modes used: $pct % of the mass in this direction (90 % required).';
  }

  @override
  String get f3dModalContributions => 'Modal contributions';

  @override
  String f3dModeN(int n) {
    return 'Mode $n';
  }

  @override
  String get f3dSpectrumNote =>
      'Design spectrum of EN 1998-1 (recommended parameters), 5 % damping, CQC combination of 12 modes. Results are envelopes (absolute values).';

  @override
  String get f3dNoBuckling =>
      'No member is in compression: no buckling factor.';

  @override
  String f3dAlphaCr(String a) {
    return 'αcr = $a';
  }

  @override
  String get f3dAlphaFirstOrder =>
      'αcr ≥ 10: first-order analysis is sufficient (EN 1993-1-1 5.2.1).';

  @override
  String get f3dAlphaSecondOrder =>
      '3 ≤ αcr < 10: include second-order effects (use P-Δ in the Static tab).';

  @override
  String get f3dAlphaTooLow =>
      'αcr < 3: the frame is too flexible; stiffen it.';

  @override
  String f3dBucklingNote(String combo) {
    return 'Elastic critical load factor of the combination $combo: the loads multiplied by αcr would make the frame buckle. The buckled shape is shown.';
  }

  @override
  String get f3dBothDirections => 'X + Y';

  @override
  String get f3dAccidentalTorsion => 'Accidental torsion';

  @override
  String get f3dAccidentalTorsionHelp =>
      '±5 % eccentricity of the floor forces (EN 1998-1 4.3.2), added to the modal response.';

  @override
  String f3dBaseShearDir(String dir, String fb) {
    return 'Base shear $dir: $fb kN';
  }

  @override
  String f3dTorsionApplied(String m) {
    return 'Accidental torsion: Σ Mai = $m kN·m.';
  }

  @override
  String get f3dCombinedNote =>
      'Forces shown: the larger of EX + 0.3 EY and 0.3 EX + EY (EN 1998-1 4.3.3.5.1).';

  @override
  String get f3dRigidFloors => 'Rigid floors (diaphragms)';

  @override
  String get f3dRigidFloorsHelp =>
      'Slabs tie each floor in its plane: needed for accidental torsion and realistic seismic modes.';

  @override
  String get f3dPs92Zone => 'Seismic zone';

  @override
  String get f3dPs92Class => 'Building class';

  @override
  String get f3dPs92Site => 'Site';

  @override
  String f3dPs92Note(String an) {
    return 'PS92 (NF P 06-013): aN = $an m/s², normalised spectrum R(T) of the site, damping 5 % (ρ = 1), no topographic effect (τ = 1). Design acceleration aN·R(T)/q.';
  }

  @override
  String get checkSteelBendingZ => 'Minor-axis bending';

  @override
  String get f3dDesignStatic =>
      'Design forces: envelope of the ULS combinations.';

  @override
  String get f3dDesignSeismic =>
      'Design forces: seismic situation G + 0.3 Q ± E (envelope).';

  @override
  String get f3dMinorMoment => 'Minor-axis moment';

  @override
  String get f3dBeamExtraForces => 'Biaxial bending or axial force';

  @override
  String get f3dBeamExtraForcesMsg =>
      'This beam also carries a significant minor-axis moment or axial force, which the beam design ignores. Design it as a column to include them.';

  @override
  String get f3dTapToDesign => 'Tap a member in the view to design it.';
}
