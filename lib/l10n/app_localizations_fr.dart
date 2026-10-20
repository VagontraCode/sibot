// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Sibot Ingénierie';

  @override
  String get brandName => 'Sibot';

  @override
  String get brandTagline => 'Ingénierie';

  @override
  String get navHome => 'Accueil';

  @override
  String get navProjects => 'Projets';

  @override
  String get navField => 'Chantier';

  @override
  String get navReports => 'Rapports';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonSeeAll => 'Tout voir';

  @override
  String get commonSwitch => 'Changer';

  @override
  String get commonProject => 'Projet';

  @override
  String get commonProjectEyebrow => 'Projet';

  @override
  String get commonMore => 'Plus';

  @override
  String get commonSaving => 'Enregistrement…';

  @override
  String get commonUntitled => 'Sans titre';

  @override
  String get commonPlanned => 'Prévu';

  @override
  String commonPhase(int n) {
    return 'Phase $n';
  }

  @override
  String get commonBeta => 'Bêta';

  @override
  String get commonOk => 'OK';

  @override
  String get commonReview => 'À revoir';

  @override
  String get timeJustNow => 'à l\'instant';

  @override
  String timeMinutesAgo(int n) {
    return 'il y a $n min';
  }

  @override
  String timeHoursAgo(int n) {
    return 'il y a $n h';
  }

  @override
  String timeDaysAgo(int n) {
    return 'il y a $n j';
  }

  @override
  String timeUpdated(String when) {
    return 'Mis à jour $when';
  }

  @override
  String get statusActive => 'En cours';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get statusArchived => 'Archivé';

  @override
  String get statusAll => 'Tous';

  @override
  String get dashGreetingMorning => 'Bonjour';

  @override
  String get dashGreetingAfternoon => 'Bon après-midi';

  @override
  String get dashGreetingEvening => 'Bonsoir';

  @override
  String get dashHeroTitle =>
      'Modélisez, calculez et dimensionnez,\ndirectement sur le chantier.';

  @override
  String get dashNewProject => 'Nouveau projet';

  @override
  String get dashOpenProjects => 'Ouvrir les projets';

  @override
  String get dashStatProjects => 'Projets';

  @override
  String get dashStatCalculations => 'Calculs';

  @override
  String get dashStatModules => 'Modules de calcul';

  @override
  String get dashStatRoadmap => 'Au programme';

  @override
  String get dashRecentProjects => 'Projets récents';

  @override
  String get dashDesignModules => 'Modules de calcul';

  @override
  String get dashDesignModulesSubtitle => 'Béton armé, Eurocode 2 et BAEL';

  @override
  String get dashRoadmap => 'Feuille de route';

  @override
  String get dashRoadmapSubtitle => 'Analyse, acier, bois, maçonnerie et plus';

  @override
  String dashOpenModuleIn(String module) {
    return 'Ouvrir $module dans…';
  }

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsSubtitle => 'Langue, apparence et paramètres de calcul.';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Système';

  @override
  String get settingsTheme => 'Apparence';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsDefaultCode => 'Règlement par défaut';

  @override
  String get settingsDefaultCodeHelp =>
      'Utilisé à l\'ouverture d\'un module de calcul.';

  @override
  String get projectsSubtitle =>
      'Calculs, photos et rapports, regroupés par projet.';

  @override
  String get projectsLoadError => 'Impossible de charger les projets';

  @override
  String get projectsEmptyTitle => 'Aucun projet';

  @override
  String get projectsEmptyMessage =>
      'Créez un projet pour regrouper ses calculs et ses données de chantier.';

  @override
  String get projectsSearchHint => 'Rechercher par nom, lieu ou ingénieur';

  @override
  String get projectsNoMatch => 'Aucun projet correspondant';

  @override
  String get projectUntitled => 'Projet sans titre';

  @override
  String get projectFormNew => 'Nouveau projet';

  @override
  String get projectFormEdit => 'Modifier le projet';

  @override
  String get projectFormName => 'Nom du projet';

  @override
  String get projectFormNameError => 'Donnez un nom au projet';

  @override
  String get projectFormLocation => 'Lieu';

  @override
  String get projectFormEngineer => 'Ingénieur';

  @override
  String get projectFormDescription => 'Description';

  @override
  String get projectFormStatus => 'Statut';

  @override
  String get projectFormSave => 'Enregistrer';

  @override
  String get projectFormCreate => 'Créer le projet';

  @override
  String get projectPickerTitle => 'Choisir un projet';

  @override
  String get projectLoadError => 'Impossible de charger le projet';

  @override
  String get projectNotFound => 'Projet introuvable';

  @override
  String get projectNotFoundMessage => 'Il a peut-être été supprimé.';

  @override
  String get projectExportPdf => 'Exporter en PDF';

  @override
  String get projectEdit => 'Modifier le projet';

  @override
  String get projectDelete => 'Supprimer le projet';

  @override
  String get projectDeleteTitle => 'Supprimer le projet ?';

  @override
  String projectDeleteMessage(String name) {
    return '« $name » sera retiré de cet appareil. Ses calculs et données de chantier restent enregistrés mais ne seront plus affichés.';
  }

  @override
  String get projectDesignModules => 'Modules de calcul';

  @override
  String get projectField => 'Chantier';

  @override
  String get projectCalculations => 'Calculs';

  @override
  String get projectCalcLoadError => 'Impossible de charger les calculs';

  @override
  String get projectCalcEmptyTitle => 'Aucun calcul';

  @override
  String get projectCalcEmptyMessage =>
      'Les résultats calculés dans un module sont enregistrés ici.';

  @override
  String countPhotos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n photos',
      one: '1 photo',
      zero: 'aucune photo',
    );
    return '$_temp0';
  }

  @override
  String countReports(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n rapports',
      one: '1 rapport',
      zero: 'aucun rapport',
    );
    return '$_temp0';
  }

  @override
  String countOpen(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ouverts',
      one: '1 ouvert',
      zero: 'aucun ouvert',
    );
    return '$_temp0';
  }

  @override
  String get catAnalysis => 'Analyse de structure';

  @override
  String get catConcrete => 'Béton armé';

  @override
  String get catSteel => 'Acier';

  @override
  String get catTimber => 'Bois';

  @override
  String get catMasonry => 'Maçonnerie';

  @override
  String get catGeotech => 'Géotechnique';

  @override
  String get catLoads => 'Charges';

  @override
  String get catTools => 'Outils';

  @override
  String get modFrame2d => 'Portiques 2D';

  @override
  String get modFrame2dSub => 'Portiques, treillis, poutres continues';

  @override
  String get modFrame3d => 'Structures 3D';

  @override
  String get modFrame3dSub => 'Ossatures spatiales, analyse modale';

  @override
  String get modBeam => 'Poutre';

  @override
  String get modBeamSub => 'Flexion, effort tranchant';

  @override
  String get modColumn => 'Poteau';

  @override
  String get modColumnSub => 'N–M, élancement';

  @override
  String get modSlab => 'Dalle';

  @override
  String get modSlabSub => 'Un sens, deux sens';

  @override
  String get modFooting => 'Semelle';

  @override
  String get modFootingSub => 'Semelle isolée, poinçonnement';

  @override
  String get modRetainingWall => 'Mur de soutènement';

  @override
  String get modRetainingWallSub => 'Stabilité, prédimensionnement';

  @override
  String get modSteelMember => 'Élément acier';

  @override
  String get modSteelMemberSub => 'Vérifications EC3, flambement';

  @override
  String get modTimberMember => 'Élément bois';

  @override
  String get modTimberMemberSub => 'Vérifications EC5';

  @override
  String get modMasonryWall => 'Mur en maçonnerie';

  @override
  String get modMasonryWallSub => 'Résistance verticale EC6';

  @override
  String get modBearing => 'Portance et tassement';

  @override
  String get modBearingSub => 'Vérifications du sol EC7';

  @override
  String get modSlope => 'Stabilité des talus';

  @override
  String get modSlopeSub => 'Coefficient de sécurité';

  @override
  String get modWindSnow => 'Vent et neige';

  @override
  String get modWindSnowSub => 'Actions EC1';

  @override
  String get modSeismic => 'Séisme';

  @override
  String get modSeismicSub => 'Spectres EC8 / PS92';

  @override
  String get modSections => 'Caractéristiques de section';

  @override
  String get modSectionsSub => 'A, I, W, i';

  @override
  String get modQuantities => 'Métrés';

  @override
  String get modQuantitiesSub => 'Béton, acier';

  @override
  String get modPileCap => 'Semelle sur pieux';

  @override
  String get modPileCapSub => 'Groupe de pieux, chevêtre';

  @override
  String get modSeptic => 'Fosse septique';

  @override
  String get modSepticSub => 'Dimensionnement du volume';

  @override
  String modPlannedFor(String module, int phase) {
    return '$module est prévu en phase $phase de la feuille de route.';
  }

  @override
  String get calcCalculate => 'Calculer';

  @override
  String get calcCalculating => 'Calcul en cours…';

  @override
  String get calcCheckInputs => 'Vérifiez les données';

  @override
  String get calcBetaTitle => 'Bêta : vérification indépendante en cours';

  @override
  String get calcBetaMessage =>
      'Les calculs suivent les articles cités et passent des tests de calcul manuel, mais n\'ont pas encore été comparés à des exemples publiés ou à RSA. Vérifiez les résultats avant de les utiliser pour l\'exécution.';

  @override
  String get calcResults => 'Résultats';

  @override
  String get calcResultsPlaceholder =>
      'Renseignez les paramètres puis touchez Calculer.';

  @override
  String get calcMaterials => 'Matériaux';

  @override
  String get calcConcreteFck => 'Béton fck';

  @override
  String get calcSteelFyk => 'Acier fyk';

  @override
  String get calcSpan => 'Portée';

  @override
  String get beamSubtitle =>
      'Section rectangulaire : flexion, effort tranchant et flèche.';

  @override
  String get beamGeometryLoad => 'Géométrie et charge';

  @override
  String get beamWidth => 'Largeur b';

  @override
  String get beamDepth => 'Hauteur h';

  @override
  String get beamBending => 'Ferraillage de flexion';

  @override
  String get beamSteelRequired => 'Section d\'acier requise';

  @override
  String get beamMomentRatio => 'Moment réduit';

  @override
  String get columnSubtitle =>
      'Poteau rectangulaire : effort normal, flexion et élancement.';

  @override
  String get columnLoadGeometry => 'Charge et géométrie';

  @override
  String get columnAxialLoad => 'Effort normal';

  @override
  String get slabSubtitle =>
      'Dalle portant dans un ou deux sens, isostatique ou continue.';

  @override
  String get slabSpanLoad => 'Portée et charge';

  @override
  String get footingSubtitle =>
      'Semelle isolée sous poteau : dimensions, armatures et poinçonnement.';

  @override
  String get footingDesignBasis => 'Bases de calcul';

  @override
  String get footingCode => 'Règlement';

  @override
  String get codeEurocode => 'Eurocode';

  @override
  String get codeBael => 'BAEL 99';

  @override
  String get footingColumnActions => 'Efforts du poteau';

  @override
  String get footingSoil => 'Sol';

  @override
  String get footingUnitWeight => 'Poids volumique';

  @override
  String get footingDimensions => 'Dimensions';

  @override
  String get footingLxB => 'Longueur × largeur';

  @override
  String get footingThickness => 'Épaisseur';

  @override
  String get footingReinforcement => 'Ferraillage';

  @override
  String get wallSubtitle =>
      'Mur cantilever : stabilité et ferraillage du voile.';

  @override
  String get wallWallSoil => 'Mur et sol';

  @override
  String get wallRetainedHeight => 'Hauteur retenue';

  @override
  String get wallSoilUnitWeight => 'Poids volumique du sol';

  @override
  String get wallFrictionAngle => 'Angle de frottement φ';

  @override
  String get wallStability => 'Stabilité';

  @override
  String get wallFosOverturning => 'Coefficient de sécurité au renversement';

  @override
  String get wallActiveThrust => 'Poussée active des terres';

  @override
  String get wallBaseThickness => 'Épaisseur de semelle';

  @override
  String get fieldSubtitle => 'Photos, journaux et réserves du chantier.';

  @override
  String get fieldEmptyMessage =>
      'Les données de chantier sont rangées par projet. Créez-en un d\'abord.';

  @override
  String get fieldTools => 'Outils';

  @override
  String get fieldPhotosCaption => 'photos';

  @override
  String get fieldReportsCaption => 'rapports';

  @override
  String get fieldOpenItemsCaption => 'réserves ouvertes';

  @override
  String get photoLog => 'Journal photo';

  @override
  String get photoAdd => 'Ajouter une photo';

  @override
  String get photoLoadError => 'Impossible de charger les photos';

  @override
  String get photoEmptyTitle => 'Aucune photo';

  @override
  String get photoEmptyMessage =>
      'Documentez l\'avancement, les défauts et le ferraillage avant coulage.';

  @override
  String get photoCamera => 'Appareil photo';

  @override
  String get photoGallery => 'Galerie';

  @override
  String get photoDescription => 'Description';

  @override
  String get photoLocation => 'Emplacement sur le chantier';

  @override
  String get photoLocationHint => 'ex. file B-3, niveau 2';

  @override
  String get photoSave => 'Enregistrer la photo';

  @override
  String get reportDaily => 'Journaux de chantier';

  @override
  String get reportNew => 'Nouveau journal';

  @override
  String get reportLoadError => 'Impossible de charger les journaux';

  @override
  String get reportEmptyTitle => 'Aucun journal';

  @override
  String get reportEmptyMessage =>
      'Notez chaque jour la météo, l\'effectif, l\'avancement et la sécurité.';

  @override
  String get reportNoSummary => 'Pas de résumé';

  @override
  String reportWorkers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ouvriers',
      one: '1 ouvrier',
      zero: 'aucun ouvrier',
    );
    return '$_temp0';
  }

  @override
  String get reportWeather => 'Météo';

  @override
  String get reportWorkersOnSite => 'Ouvriers sur site';

  @override
  String get reportWorkersField => 'Ouvriers';

  @override
  String get reportProgress => 'Avancement';

  @override
  String get reportSafety => 'Sécurité';

  @override
  String get reportSafetyNotes => 'Remarques sécurité';

  @override
  String get reportDailyTitle => 'Journal de chantier';

  @override
  String get reportSave => 'Enregistrer le journal';

  @override
  String get punchList => 'Réserves';

  @override
  String get punchAdd => 'Ajouter une réserve';

  @override
  String get punchLoadError => 'Impossible de charger les réserves';

  @override
  String get punchEmptyTitle => 'Aucune réserve';

  @override
  String get punchEmptyMessage => 'Suivez les défauts jusqu\'à leur levée.';

  @override
  String punchOpenTab(int n) {
    return 'Ouvertes · $n';
  }

  @override
  String punchClosedTab(int n) {
    return 'Levées · $n';
  }

  @override
  String get punchNothingClosed => 'Aucune réserve levée';

  @override
  String get punchAllClear => 'Tout est levé';

  @override
  String get punchSwipeHint =>
      'Balayez vers la droite pour lever une réserve, vers la gauche pour la supprimer.';

  @override
  String punchAssignedTo(String name) {
    return 'Attribuée à $name';
  }

  @override
  String get punchNew => 'Nouvelle réserve';

  @override
  String get punchWhat => 'Que faut-il reprendre ?';

  @override
  String get punchAssignedLabel => 'Attribuée à';

  @override
  String get punchPriority => 'Priorité';

  @override
  String get priorityHigh => 'Haute';

  @override
  String get priorityMedium => 'Moyenne';

  @override
  String get priorityLow => 'Basse';

  @override
  String get reportsSubtitle => 'Notes de calcul PDF et documents de chantier.';

  @override
  String get reportsEmptyMessage => 'Les rapports sont générés par projet.';

  @override
  String get reportsGenerate => 'Générer';

  @override
  String get reportsSummary => 'Synthèse du projet';

  @override
  String get reportsSummaryDesc =>
      'Calculs de semelles et de poutres, et liste des réserves, dans un seul PDF.';

  @override
  String get reportsCalcNotes => 'Notes de calcul';

  @override
  String get reportsCalcNotesDesc =>
      'Formules, articles du règlement et diagrammes pour chaque module.';

  @override
  String get reportsFieldAudit => 'Rapport de chantier';

  @override
  String get reportsFieldAuditDesc => 'Journaux, photos et réserves.';

  @override
  String get librarySubtitle =>
      'Règlements, caractéristiques des matériaux et outils rapides.';

  @override
  String get libraryConverter => 'Convertisseur d\'unités';

  @override
  String get libraryLength => 'Longueur';

  @override
  String get libraryForce => 'Force';

  @override
  String get libraryPressure => 'Pression';

  @override
  String get libraryValue => 'Valeur';

  @override
  String get librarySwap => 'Inverser';

  @override
  String get libraryMaterials => 'Matériaux';

  @override
  String get libraryConcrete => 'Béton';

  @override
  String get librarySteel => 'Acier de construction';

  @override
  String get libraryRebar => 'Armatures';

  @override
  String libraryTable(String code, String table) {
    return '$code, tableau $table';
  }

  @override
  String get libraryRebarSource => 'Section πd²/4, masse à 7850 kg/m³';

  @override
  String get libraryColClass => 'Classe';

  @override
  String get libraryColGrade => 'Nuance';

  @override
  String get libraryColArea => 'Section mm²';

  @override
  String get libraryColMass => 'Masse kg/m';

  @override
  String get libraryCodes => 'Règlements';

  @override
  String get libraryCodesSubtitle =>
      'Règlements que la suite prendra en charge';

  @override
  String get codeEc0 => 'Bases de calcul, combinaisons';

  @override
  String get codeEc1 => 'Actions : charges, vent, neige';

  @override
  String get codeEc2 => 'Structures en béton';

  @override
  String get codeEc3 => 'Structures en acier';

  @override
  String get codeEc5 => 'Structures en bois';

  @override
  String get codeEc6 => 'Structures en maçonnerie';

  @override
  String get codeEc7 => 'Calcul géotechnique';

  @override
  String get codeEc8 => 'Résistance aux séismes';

  @override
  String get codeBaelDesc => 'Béton armé (FR)';

  @override
  String get codePs92Desc => 'Règles parasismiques (FR)';

  @override
  String get calcCover => 'Enrobage';

  @override
  String get loadPermanent => 'Charge permanente g';

  @override
  String get loadVariable => 'Charge d\'exploitation q';

  @override
  String get loadPermanentArea => 'Charge permanente g';

  @override
  String get loadVariableArea => 'Charge d\'exploitation q';

  @override
  String get loadPermanentPoint => 'Charge permanente G';

  @override
  String get loadVariablePoint => 'Charge d\'exploitation Q';

  @override
  String get loadSelfWeightNote =>
      'Charges caractéristiques. Le poids propre est ajouté automatiquement ; combinaison ELU 1,35G + 1,5Q.';

  @override
  String get beamSupport => 'Appuis';

  @override
  String get beamSimplySupported => 'Isostatique';

  @override
  String get beamCantilever => 'Console';

  @override
  String get resultDesignForces => 'Sollicitations de calcul';

  @override
  String get resultUlsLoad => 'Charge ELU';

  @override
  String get resultMoment => 'Moment de calcul';

  @override
  String get resultShear => 'Effort tranchant de calcul';

  @override
  String get resultEffectiveDepth => 'Hauteur utile';

  @override
  String get resultBottomBars => 'Armatures inférieures';

  @override
  String get resultTopBars => 'Armatures supérieures';

  @override
  String get resultLinks => 'Cadres';

  @override
  String get checksTitle => 'Vérifications';

  @override
  String get checkBendingSteel => 'Armatures de flexion';

  @override
  String get checkMinSteel => 'Armatures minimales';

  @override
  String get checkMaxSteel => 'Armatures maximales';

  @override
  String get checkBarSpacing => 'Espacement libre des barres';

  @override
  String get checkShearConcrete => 'Effort tranchant (béton)';

  @override
  String get checkShearLinks => 'Armatures d\'effort tranchant';

  @override
  String get checkLinkSpacing => 'Espacement des cadres';

  @override
  String get checkDeflection => 'Flèche';

  @override
  String get checkSlenderness => 'Élancement';

  @override
  String get checkAxialBending => 'Flexion composée';

  @override
  String get checkBearing => 'Contrainte sur le sol';

  @override
  String get checkPunching => 'Poinçonnement';

  @override
  String get checkOverturning => 'Renversement';

  @override
  String get checkSliding => 'Glissement';

  @override
  String get checkEccentricity => 'Excentricité';

  @override
  String get verdictOk => 'Toutes les vérifications sont satisfaites';

  @override
  String verdictFail(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n vérifications non satisfaites',
      one: '1 vérification non satisfaite',
    );
    return '$_temp0';
  }

  @override
  String verdictUtilisation(String pct) {
    return 'Taux de travail maximal $pct %';
  }

  @override
  String problemMissing(String field) {
    return 'Renseignez $field.';
  }

  @override
  String problemNotPositive(String field) {
    return '$field doit être supérieur à 0.';
  }

  @override
  String problemOutOfRange(String field) {
    return '$field est hors du domaine couvert par la méthode.';
  }

  @override
  String problemGeometry(String field) {
    return '$field n\'est pas cohérent avec les autres dimensions.';
  }

  @override
  String get noteCompressionSteel =>
      'Le moment dépasse la limite d\'une section simplement armée : des aciers comprimés sont nécessaires.';

  @override
  String get noteBarsDoNotFit =>
      'Aucune disposition de barres standard ne tient sur un lit. Augmentez la section.';

  @override
  String get noteLinksNotFound =>
      'Des cadres jusqu\'à Ø12 ne suffisent pas. Augmentez la section.';

  @override
  String get noteDeflectionNotCovered =>
      'La dispense de vérification de flèche du BAEL ne couvre pas les consoles : calculez la flèche.';

  @override
  String get columnWidthB => 'Largeur b';

  @override
  String get columnDepthH => 'Hauteur h (sens de flexion)';

  @override
  String get columnBucklingLength => 'Longueur de flambement lf';

  @override
  String get columnMoment => 'Moment du premier ordre';

  @override
  String get columnCreep => 'Coefficient de fluage effectif φef';

  @override
  String get columnUlsNote =>
      'Valeurs de calcul ELU. La flexion agit autour de l\'axe parallèle à b.';

  @override
  String get columnSlendernessTitle => 'Élancement et moments';

  @override
  String get columnImperfection => 'Excentricité d\'imperfection';

  @override
  String get columnSecondOrder => 'Excentricité du second ordre';

  @override
  String get columnLongitudinalBars => 'Armatures longitudinales';

  @override
  String get columnAxialResistance => 'Effort normal résistant';

  @override
  String get columnMomentResistance => 'Moment résistant sous NEd';

  @override
  String get columnInteraction => 'Diagramme d\'interaction N–M';

  @override
  String get noteSecondOrder =>
      'λ > λlim : moment du second ordre ajouté par la méthode de la courbure nominale (EN 1992-1-1 5.8.8).';

  @override
  String get noteBaelCentred =>
      'Compression centrée : méthode α du BAEL B.8.4.';

  @override
  String get noteSlendernessOutOfScope =>
      'Élancement hors du domaine de la méthode : un calcul de flambement est nécessaire.';

  @override
  String get noteSectionTooSmall =>
      'Le pourcentage d\'acier maximal ne suffit pas. Augmentez la section.';

  @override
  String get slabType => 'Type de dalle';

  @override
  String get slabOneWayShort => 'Un sens';

  @override
  String get slabTwoWayShort => 'Deux sens';

  @override
  String get slabContinuous => 'Continue';

  @override
  String get slabShortSpan => 'Petite portée lx';

  @override
  String get slabLongSpan => 'Grande portée ly';

  @override
  String get slabThicknessInput => 'Épaisseur h';

  @override
  String get slabCoefficients => 'Coefficients du panneau';

  @override
  String get slabMomentXSpan => 'Moment en travée, x';

  @override
  String get slabMomentSupport => 'Moment sur appui';

  @override
  String get slabMomentYSpan => 'Moment en travée, y';

  @override
  String get slabBarsXSpan => 'Nappe inférieure, sens x';

  @override
  String get slabBarsSupport => 'Chapeaux sur appuis';

  @override
  String get slabBarsYSpan => 'Nappe inférieure, sens y';

  @override
  String get slabDistribution => 'Armatures de répartition';

  @override
  String get noteTreatedAsOneWay =>
      'lx/ly < 0,4 : le panneau est calculé comme portant dans un sens.';

  @override
  String get noteBaelPanel =>
      'Moments des dalles sur quatre appuis par les coefficients de l\'Annexe E3 du BAEL 91 (ν = 0 à l\'ELU).';

  @override
  String get noteContinuityCoefficients =>
      'Continuité par coefficients simplifiés : 0,75 M0 en travée, 0,5 M0 sur appuis (BAEL A.8.2.32).';

  @override
  String get footingColumnA => 'Poteau a (sens du moment)';

  @override
  String get footingColumnB => 'Poteau b';

  @override
  String get footingMomentG => 'Moment dû à G';

  @override
  String get footingMomentQ => 'Moment dû à Q';

  @override
  String get footingAllowable => 'Contrainte admissible du sol';

  @override
  String get footingDepthInput => 'Profondeur d\'assise';

  @override
  String get footingCharacteristicNote =>
      'Charges caractéristiques (service) du poteau. Dimensions à l\'ELS, armatures à l\'ELU.';

  @override
  String get footingSelfWeight => 'Poids de la semelle et des terres';

  @override
  String get footingPressure => 'Contrainte sur le sol';

  @override
  String get footingBarsAlongA => 'Barres parallèles à A';

  @override
  String get footingBarsAlongB => 'Barres parallèles à B';

  @override
  String get noteSizeLimit =>
      'La semelle dépasserait 10 m : vérifiez le sol ou les charges.';

  @override
  String get noteFootingBael =>
      'Semelle rigide calculée par la méthode des bielles ; contrainte au 3/4 de la largeur.';

  @override
  String get noteFootingEc2 =>
      'Flexion à 0,15a à l\'intérieur du nu du poteau (EN 1992-1-1 9.8.2.2) ; contrainte sur la surface effective (EN 1997-1 Annexe D).';

  @override
  String get wallGeometry => 'Géométrie';

  @override
  String get wallPresizeButton => 'Prédimensionner d\'après la hauteur';

  @override
  String get wallToeLength => 'Longueur du patin';

  @override
  String get wallHeelLength => 'Longueur du talon';

  @override
  String get wallStemTop => 'Épaisseur du voile, en tête';

  @override
  String get wallStemBottom => 'Épaisseur du voile, en pied';

  @override
  String get wallSurcharge => 'Surcharge q';

  @override
  String get wallToe => 'patin';

  @override
  String get wallHeel => 'talon';

  @override
  String get wallKa => 'Coefficient de poussée';

  @override
  String get wallFosSliding => 'Coefficient de sécurité au glissement';

  @override
  String get wallStem => 'Voile';

  @override
  String get wallStemBars => 'Armatures verticales, côté terres';

  @override
  String get noteWallMethod =>
      'Stabilité avec la poussée de Rankine et des coefficients de sécurité globaux de 1,5. Le calcul aux coefficients partiels de l\'EC7 viendra avec le module de géotechnique.';

  @override
  String get noteWallShearKey =>
      'Le glissement n\'est pas vérifié : ajoutez une bêche ou allongez le talon.';
}
