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
  String get dashDesignModulesSubtitle =>
      'Analyse, béton, fondations et outils';

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
  String get modFootingSub => 'Isolée, filante, combinée';

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
      'Semelle isolée, filante ou combinée : dimensions, armatures, poinçonnement.';

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
      'Valeurs de calcul ELU. Le moment sens h fléchit la section suivant h ; le moment sens b suivant b.';

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

  @override
  String get columnDiameter => 'Diamètre D';

  @override
  String get columnMomentH => 'Moment, sens h';

  @override
  String get columnMomentB => 'Moment, sens b';

  @override
  String get columnMomentX => 'Moment Mx';

  @override
  String get columnMomentY => 'Moment My';

  @override
  String get columnShape => 'Section';

  @override
  String get columnRectangular => 'Rectangulaire';

  @override
  String get columnCircular => 'Circulaire';

  @override
  String get columnUlsNoteCircle =>
      'Valeurs de calcul ELU. Les deux moments sont composés vectoriellement.';

  @override
  String get columnBarsPerFace => 'Barres par face';

  @override
  String get noteBiaxial =>
      'Moments dans les deux sens : vérification en flexion déviée EN 1992-1-1 5.8.9(4).';

  @override
  String get noteImperfectionOneDirection =>
      'Imperfection et excentricité minimale appliquées dans un seul sens à la fois (EN 1992-1-1 5.8.9(2)) ; le cas le plus défavorable est retenu.';

  @override
  String get checkConcreteStress => 'Contrainte du béton (ELS)';

  @override
  String get checkSteelStress => 'Contrainte de l\'acier (ELS)';

  @override
  String get checkCrackWidth => 'Ouverture des fissures';

  @override
  String get diagramShear => 'Effort tranchant V';

  @override
  String get diagramMoment => 'Moment fléchissant M';

  @override
  String get slsTitle => 'État limite de service';

  @override
  String get slsCracking => 'Fissuration';

  @override
  String get slsCrackingSlight => 'Peu préjudiciable';

  @override
  String get slsCrackingHarmful => 'Préjudiciable';

  @override
  String get slsCrackingVeryHarmful => 'Très préjudiciable';

  @override
  String get slsPsi2 => 'Coefficient quasi permanent ψ2';

  @override
  String get slsCrackLimit => 'Ouverture limite wmax';

  @override
  String get slsCharMoment => 'Moment caractéristique';

  @override
  String get slsConcreteStress => 'Contrainte du béton';

  @override
  String get slsSteelStress => 'Contrainte de l\'acier';

  @override
  String get slsQpMoment => 'Moment quasi permanent';

  @override
  String get slsCrackSpacing => 'Espacement maximal des fissures';

  @override
  String get punchingTitle => 'Poinçonnement (facultatif)';

  @override
  String get punchingType => 'Type de charge';

  @override
  String get punchingColumn => 'Poteau intérieur';

  @override
  String get punchingPointLoad => 'Charge ponctuelle';

  @override
  String get punchingOptionalNote =>
      'Laissez la charge vide pour ne pas vérifier le poinçonnement. Charge ELU sur une surface c1 × c2.';

  @override
  String get punchingLoad => 'Charge de poinçonnement VEd';

  @override
  String get punchingC1 => 'Surface chargée c1';

  @override
  String get punchingC2 => 'Surface chargée c2';

  @override
  String get punchingPerimeter => 'Contour de contrôle';

  @override
  String get punchingDemand => 'Sollicitation de poinçonnement';

  @override
  String get punchingResistance => 'Résistance sans armatures';

  @override
  String get punchingReinforcement =>
      'Armatures de poinçonnement par contour (sr = 0,75d)';

  @override
  String get footingTypeLabel => 'Type de semelle';

  @override
  String get footingIsolatedType => 'Isolée';

  @override
  String get footingStripType => 'Filante';

  @override
  String get footingCombinedType => 'Combinée';

  @override
  String get footingWallActions => 'Efforts du mur (par mètre)';

  @override
  String get footingWallThickness => 'Épaisseur du mur';

  @override
  String get footingCol1A => 'Poteau 1, a (le long de la semelle)';

  @override
  String get footingCol1B => 'Poteau 1, b';

  @override
  String get footingCol2A => 'Poteau 2, a (le long de la semelle)';

  @override
  String get footingCol2B => 'Poteau 2, b';

  @override
  String get footingSpacingInput => 'Entraxe des poteaux';

  @override
  String get footingG1 => 'Poteau 1, G';

  @override
  String get footingQ1 => 'Poteau 1, Q';

  @override
  String get footingG2 => 'Poteau 2, G';

  @override
  String get footingQ2 => 'Poteau 2, Q';

  @override
  String get footingWidth => 'Largeur';

  @override
  String get footingTransverseBars => 'Armatures transversales';

  @override
  String get footingOverhang => 'Débord au-delà du poteau 1';

  @override
  String get footingLongBottom => 'Longitudinales, nappe inférieure';

  @override
  String get footingLongTop => 'Longitudinales, nappe supérieure';

  @override
  String footingTransverseUnder(int n) {
    return 'Transversales sous le poteau $n';
  }

  @override
  String get noteCombinedFooting =>
      'Longueur choisie pour centrer la résultante de service ; calcul en poutre sur réaction linéaire du sol. Épaisseur augmentée jusqu\'à ne plus avoir besoin de cadres.';

  @override
  String get noteSoilEc7 =>
      'Portance selon l\'EN 1997-1 Annexe D, approche de calcul 2 (γR,v = 1,4), charge verticale.';

  @override
  String get soilBearingMode => 'Vérification de portance';

  @override
  String get soilModeAllowable => 'Contrainte admissible';

  @override
  String get soilModeParameters => 'Paramètres du sol (EC7)';

  @override
  String get soilDrainage => 'Comportement du sol';

  @override
  String get soilDrained => 'Drainé (c′, φ′)';

  @override
  String get soilUndrained => 'Non drainé (cu)';

  @override
  String get soilCohesion => 'Cohésion c′';

  @override
  String get soilPhi => 'Angle de frottement φ′';

  @override
  String get soilCu => 'Cohésion non drainée cu';

  @override
  String get soilModulus => 'Module d\'Young E';

  @override
  String get soilPoisson => 'Coefficient de Poisson ν';

  @override
  String get wallBase => 'Semelle du mur';

  @override
  String get wallUlsPressure => 'Contrainte ELU, patin / talon';

  @override
  String get wallToeMoment => 'Patin, nappe inférieure';

  @override
  String get wallHeelMoment => 'Talon, nappe supérieure';

  @override
  String get wallEqu => 'Renversement EQU';

  @override
  String get wallDa2Sliding => 'Glissement DA2';

  @override
  String get noteWallEc7 =>
      'EC7 : renversement à l\'EQU (γG,dst 1,1, γG,stb 0,9, γφ′ 1,25), glissement en DA2 (1,35 / 1,5, γR,h 1,1). Les coefficients globaux sont donnés à titre indicatif.';

  @override
  String get bearingSubtitle =>
      'Portance EC7 et tassement d\'une fondation superficielle.';

  @override
  String get bearingWidth => 'Largeur B';

  @override
  String get bearingLength => 'Longueur L';

  @override
  String get bearingLoadNote =>
      'Charges caractéristiques, poids de la semelle et des terres compris.';

  @override
  String get bearingResistance => 'Portance';

  @override
  String get bearingFactors => 'Facteurs de portance';

  @override
  String get bearingUltimate => 'Contrainte ultime';

  @override
  String get bearingDesignResistance => 'Résistance de calcul';

  @override
  String get bearingDesignPressure => 'Contrainte de calcul (1,35G + 1,5Q)';

  @override
  String get bearingSettlement => 'Tassement';

  @override
  String get bearingServicePressure => 'Contrainte de service';

  @override
  String get noteSettlementEstimate =>
      'Le tassement est une estimation élastique pour une semelle rigide (cercle équivalent) ; utilisez des essais œdométriques pour les argiles.';

  @override
  String get sectionsSubtitle => 'Aire, inertie et modules de section.';

  @override
  String get sectionShape => 'Forme';

  @override
  String get sectionRect => 'Rectangle';

  @override
  String get sectionCircle => 'Cercle';

  @override
  String get sectionHollow => 'Creux';

  @override
  String get sectionI => 'I';

  @override
  String get sectionT => 'T';

  @override
  String get sectionWidth => 'Largeur b';

  @override
  String get sectionHeight => 'Hauteur h';

  @override
  String get sectionThickness => 'Épaisseur de paroi t';

  @override
  String get sectionFlange => 'Épaisseur de semelle tf';

  @override
  String get sectionWeb => 'Épaisseur d\'âme tw';

  @override
  String get sectionResults => 'Caractéristiques';

  @override
  String get sectionArea => 'Aire';

  @override
  String get sectionCentroid => 'Centre de gravité depuis le haut';

  @override
  String get sectionInertiaY => 'Inertie, axe fort';

  @override
  String get sectionInertiaZ => 'Inertie, axe faible';

  @override
  String get sectionWelTop => 'Module élastique, fibre supérieure';

  @override
  String get sectionWelBottom => 'Module élastique, fibre inférieure';

  @override
  String get sectionWpl => 'Module plastique';

  @override
  String get sectionRadii => 'Rayons de giration';

  @override
  String get noteSectionNoFillets =>
      'Les congés de raccordement ne sont pas pris en compte ; les valeurs des catalogues de profilés sont un peu plus élevées.';

  @override
  String get quantitiesSubtitle =>
      'Matériaux du béton, coffrage et poids d\'acier.';

  @override
  String get qtyElements => 'Éléments';

  @override
  String get qtyLength => 'Longueur';

  @override
  String get qtyWidth => 'Largeur';

  @override
  String get qtyHeight => 'Hauteur / épaisseur';

  @override
  String get qtyCount => 'Nombre';

  @override
  String get qtyFormworkType => 'Faces coffrées';

  @override
  String get qtyColumnWall => 'Poteau / voile';

  @override
  String get qtyMix => 'Dosage par m³';

  @override
  String get qtyCement => 'Ciment';

  @override
  String get qtySand => 'Sable';

  @override
  String get qtyGravel => 'Gravier';

  @override
  String get qtyWater => 'Eau';

  @override
  String get qtyWaste => 'Pertes';

  @override
  String get qtyRebar => 'Armatures';

  @override
  String get qtyBarDiameter => 'Diamètre des barres';

  @override
  String get qtyBarCount => 'Nombre de barres';

  @override
  String get qtyBarLength => 'Longueur des barres';

  @override
  String get qtyLap => 'Recouvrements et chutes';

  @override
  String get qtyConcrete => 'Béton';

  @override
  String get qtyVolume => 'Volume';

  @override
  String get qtyCementTotal => 'Ciment';

  @override
  String qtyBags(int n) {
    return '$n sacs de 50 kg';
  }

  @override
  String get qtySandTotal => 'Sable';

  @override
  String get qtyGravelTotal => 'Gravier';

  @override
  String get qtyWaterTotal => 'Eau';

  @override
  String get qtyFormwork => 'Surface de coffrage';

  @override
  String get qtyRebarLength => 'Longueur totale';

  @override
  String get qtyRebarMass => 'Masse';

  @override
  String get qtyStockBars => 'Barres de 12 m à commander';

  @override
  String get qtyNothing => 'Renseignez les éléments ou les armatures.';

  @override
  String get noteQuantitiesMix =>
      'Le dosage par défaut est un dosage courant de chantier (350 kg/m³). Adaptez-le à votre formulation.';

  @override
  String get frameSubtitle =>
      'Portiques, poutres continues et treillis : modéliser, calculer, lire les diagrammes.';

  @override
  String get frameNewModel => 'Nouveau modèle';

  @override
  String get frameLoadError => 'Impossible de charger les modèles';

  @override
  String get frameEmptyTitle => 'Aucun modèle';

  @override
  String get frameEmptyMessage =>
      'Partez d\'une poutre continue, d\'un portique ou d\'un treillis, ou dessinez le vôtre.';

  @override
  String frameCounts(int nodes, int members) {
    return '$nodes nœuds, $members barres';
  }

  @override
  String get frameTemplateInvalid => 'Vérifiez les dimensions du modèle type.';

  @override
  String get frameTemplateBeam => 'Poutre continue';

  @override
  String get frameTemplateFrame => 'Portique';

  @override
  String get frameTemplateTruss => 'Treillis';

  @override
  String get frameTemplateBlank => 'Vide';

  @override
  String get frameModelName => 'Nom du modèle';

  @override
  String get frameSpans => 'Portées';

  @override
  String get frameSpansHelp =>
      'Séparez les portées par des virgules, ex. 5; 6; 5';

  @override
  String get frameBays => 'Travées';

  @override
  String get frameBayWidth => 'Largeur de travée';

  @override
  String get frameStoreys => 'Niveaux';

  @override
  String get frameStoreyHeight => 'Hauteur d\'étage';

  @override
  String get frameTrussType => 'Type de treillis';

  @override
  String get frameSpan => 'Portée';

  @override
  String get frameTrussHeight => 'Hauteur';

  @override
  String get framePanels => 'Panneaux';

  @override
  String get frameWindPerFloor => 'Effort de vent par niveau (côté gauche)';

  @override
  String get frameTemplateNote =>
      'Charges caractéristiques, vers le bas. Le poids propre est ajouté à G. Sections et charges sont modifiables ensuite.';

  @override
  String get frameCreate => 'Créer le modèle';

  @override
  String get frameUndo => 'Annuler';

  @override
  String get frameRedo => 'Rétablir';

  @override
  String get frameFit => 'Ajuster à l\'écran';

  @override
  String get frameLoadCases => 'Cas de charge';

  @override
  String get frameSections => 'Sections';

  @override
  String get frameModeModel => 'Modèle';

  @override
  String get frameModeResults => 'Résultats';

  @override
  String get frameEnvelope => 'Enveloppe ELU';

  @override
  String get frameViewDeformed => 'Déformée';

  @override
  String get frameViewReactions => 'Réactions';

  @override
  String get frameResultSource => 'Cas ou combinaison';

  @override
  String get frameAnalysisFailed => 'Calcul impossible';

  @override
  String get frameErrEmpty => 'Ajoutez d\'abord des nœuds et des barres.';

  @override
  String get frameErrZeroLength => 'Une barre a une longueur nulle.';

  @override
  String get frameErrUnstable =>
      'La structure est instable : ajoutez des appuis ou supprimez des rotules pour qu\'elle ne puisse plus bouger librement.';

  @override
  String get frameErrInvalid =>
      'Le modèle contient une barre ou une section invalide.';

  @override
  String get frameRename => 'Renommer le modèle';

  @override
  String get frameToolSelect => 'Sélection';

  @override
  String get frameToolNode => 'Nœud';

  @override
  String get frameToolMember => 'Barre';

  @override
  String get frameToolSupport => 'Appui';

  @override
  String get frameToolLoad => 'Charge';

  @override
  String get frameHintSelect =>
      'Touchez un nœud ou une barre pour le modifier. Pincez pour zoomer, glissez pour déplacer.';

  @override
  String frameHintNode(String grid) {
    return 'Touchez pour placer des nœuds (grille $grid m).';
  }

  @override
  String get frameHintMember =>
      'Touchez un point de départ puis un point d\'arrivée. Les barres s\'enchaînent.';

  @override
  String get frameHintSupport =>
      'Touchez un nœud pour alterner : libre, articulé, encastré, appui simple.';

  @override
  String get frameHintLoad =>
      'Touchez une barre ou un nœud pour définir sa charge dans le cas actif.';

  @override
  String get frameActiveCase => 'Cas de charge actif';

  @override
  String frameNodeTitle(int n) {
    return 'Nœud $n';
  }

  @override
  String get frameApply => 'Appliquer';

  @override
  String get frameSupport => 'Appui';

  @override
  String get frameSupportFree => 'Libre';

  @override
  String get frameSupportPinned => 'Articulé';

  @override
  String get frameSupportFixed => 'Encastré';

  @override
  String get frameSupportRollerX => 'Appui simple (glisse en x)';

  @override
  String get frameSupportRollerY => 'Appui simple (glisse en y)';

  @override
  String frameNodalLoad(String name) {
    return 'Charge nodale, cas $name';
  }

  @override
  String get frameApplyLoad => 'Appliquer la charge';

  @override
  String frameMemberTitle(int n) {
    return 'Barre $n';
  }

  @override
  String frameMemberNodes(int a, int b) {
    return 'Nœuds $a → $b';
  }

  @override
  String get frameSection => 'Section';

  @override
  String get frameMemberKind => 'Type de barre';

  @override
  String get frameKindBeam => 'Poutre';

  @override
  String get frameKindTruss => 'Barre de treillis';

  @override
  String get frameHingeStart => 'Rotule à l\'origine';

  @override
  String get frameHingeEnd => 'Rotule à l\'extrémité';

  @override
  String frameMemberLoad(String name) {
    return 'Charge répartie, cas $name';
  }

  @override
  String get frameLoadDirection => 'Direction';

  @override
  String get frameLoadGravity => 'Verticale';

  @override
  String get frameLoadNormal => 'Perpendiculaire';

  @override
  String get frameMaxSagging => 'Moment positif maximal';

  @override
  String get frameMaxHogging => 'Moment négatif maximal';

  @override
  String get frameMaxShear => 'Effort tranchant maximal';

  @override
  String get frameAxialRange => 'Effort normal';

  @override
  String get frameMaxDeflection => 'Flèche maximale';

  @override
  String get loadTypePermanent => 'Permanente';

  @override
  String get loadTypeImposed => 'Exploitation';

  @override
  String get loadTypeSnow => 'Neige';

  @override
  String get loadTypeWind => 'Vent';

  @override
  String get frameSelfWeight => 'Inclure le poids propre';

  @override
  String get frameAddCase => 'Ajouter un cas de charge';

  @override
  String get frameCombinationsNote =>
      'Les combinaisons ELU et ELS sont générées à partir des types de cas, selon le règlement par défaut (EN 1990 ou BAEL).';

  @override
  String get frameAddSection => 'Ajouter une section';

  @override
  String get frameSectionType => 'Type de section';

  @override
  String get frameConcreteRect => 'Rectangle en béton';

  @override
  String get frameProfile => 'Profilé';

  @override
  String get frameSectionNote =>
      'Les nouvelles barres utilisent la section sélectionnée.';

  @override
  String get memberDesignButton => 'Dimensionner cette barre';

  @override
  String get memberDesignSubtitle =>
      'Dimensionnement à partir de l\'enveloppe ELU de l\'analyse du portique.';

  @override
  String get memberEnvelopeForces => 'Efforts de l\'enveloppe ELU';

  @override
  String get memberCompression => 'Compression maximale';

  @override
  String get memberTension => 'Traction maximale';

  @override
  String get memberDesignAs => 'Dimensionner comme';

  @override
  String get memberBucklingFactor =>
      'Coefficient de longueur de flambement l0/L';

  @override
  String get memberBucklingFactorHelp =>
      '1,0 pour un poteau d\'étage contreventé est une valeur sûre ; 0,7 à 0,85 si les extrémités sont tenues par des poutres raides.';

  @override
  String get memberNoEnvelope =>
      'Aucune combinaison ELU : ajoutez d\'abord un cas de charge.';

  @override
  String get memberUnsupportedSection =>
      'Cette section ne peut pas encore être dimensionnée ici';

  @override
  String get memberUnsupportedSectionMsg =>
      'Les rectangles en béton et les profilés laminés IPE, HEA et HEB peuvent être dimensionnés ici.';

  @override
  String get memberBeamNote =>
      'Utilise les moments extrêmes de l\'enveloppe sur toute la barre ; l\'arrêt des barres le long de la portée n\'est pas optimisé.';

  @override
  String get steelSubtitle => 'EN 1993-1-1 · profilés laminés I et H';

  @override
  String get steelLength => 'Longueur de la barre';

  @override
  String get steelLengthHelp => 'Entre maintiens latéraux';

  @override
  String get steelAxialForce => 'Effort normal NEd';

  @override
  String get steelAxialHelp => 'Compression +, traction −';

  @override
  String get steelMoment => 'Moment fort My,Ed';

  @override
  String get steelShear => 'Effort tranchant VEd';

  @override
  String get steelGrade => 'Nuance d\'acier';

  @override
  String get steelProfileTitle => 'Profilé';

  @override
  String get steelSeries => 'Série';

  @override
  String get steelProfile => 'Section';

  @override
  String get steelBasisNote =>
      'γM0 = γM1 = 1,00 (valeurs recommandées). Caractéristiques calculées à partir des dimensions nominales, congés compris.';

  @override
  String get steelForcesTitle => 'Efforts de calcul (ELU)';

  @override
  String get steelMomentShape => 'Diagramme de moment';

  @override
  String get steelShapeUdl => 'Répartie';

  @override
  String get steelShapePoint => 'Ponct.';

  @override
  String get steelShapeUniform => 'Const.';

  @override
  String get steelShapeLinear => 'Linéaire';

  @override
  String get steelPsiHelp => 'Rapport des moments d\'extrémité, −1 ≤ ψ ≤ 1';

  @override
  String get steelBucklingTitle => 'Longueurs de flambement';

  @override
  String get steelBucklingNote =>
      'Lcr = k × L selon l\'axe fort (y), l\'axe faible (z) et pour le déversement. kLT = 1 pour une poutre maintenue seulement aux appuis ; une petite valeur pour une semelle maintenue en continu.';

  @override
  String steelLightest(String name) {
    return '$name suffit';
  }

  @override
  String steelLightestMsg(String a, String b) {
    return 'Profilé le plus léger de la série qui satisfait toutes les vérifications : $a kg/m au lieu de $b kg/m.';
  }

  @override
  String steelUseProfile(String name) {
    return 'Utiliser $name';
  }

  @override
  String get steelResistances => 'Résistance de la section';

  @override
  String get steelClass => 'Classe de section';

  @override
  String get steelAxialResistance => 'Résistance axiale';

  @override
  String get steelMomentResistance => 'Résistance en flexion';

  @override
  String get steelShearResistance => 'Résistance au cisaillement';

  @override
  String get steelReducedMoment => 'Moment résistant avec N et V';

  @override
  String get steelStability => 'Stabilité de la barre';

  @override
  String get steelFlexuralY => 'Flambement (y)';

  @override
  String get steelFlexuralZ => 'Flambement (z)';

  @override
  String get steelCriticalMoment => 'Moment critique élastique';

  @override
  String get steelLtb => 'Déversement';

  @override
  String get steelLtbResistance => 'Moment résistant au déversement';

  @override
  String get steelInteractionFactors => 'Facteurs d\'interaction (annexe B)';

  @override
  String get steelProperties => 'Caractéristiques';

  @override
  String get steelArea => 'Aire';

  @override
  String get steelInertia => 'Moments d\'inertie';

  @override
  String get steelPlasticModulus => 'Module plastique';

  @override
  String get steelMass => 'Masse';

  @override
  String get steelNoteScope =>
      'Flexion selon l\'axe fort uniquement. Charges appliquées au centre de cisaillement, gauchissement libre aux appuis. Les âmes de classe 4 utilisent l\'aire efficace en compression ; l\'introduction des charges locales et le voilement de l\'âme ne sont pas vérifiés.';

  @override
  String get checkSteelTension => 'Traction';

  @override
  String get checkSteelCompression => 'Compression (section)';

  @override
  String get checkSteelBending => 'Flexion (section)';

  @override
  String get checkSteelShear => 'Cisaillement (section)';

  @override
  String get checkSteelCombined => 'Flexion avec N et V';

  @override
  String get checkFlexuralBucklingY => 'Flambement y-y';

  @override
  String get checkFlexuralBucklingZ => 'Flambement z-z';

  @override
  String get checkLtb => 'Déversement';

  @override
  String get checkInteractionY => 'Interaction flambement (y)';

  @override
  String get checkInteractionZ => 'Interaction flambement (z)';

  @override
  String get memberSteelNote =>
      'Les extrêmes de l\'enveloppe sont combinés en une seule vérification (N max avec M max), ce qui est conservatif. La longueur L est celle de la barre entre ses deux nœuds.';

  @override
  String get timberSubtitle =>
      'EN 1995-1-1 · bois massif et lamellé-collé, sections rectangulaires';

  @override
  String get timberWidth => 'Largeur b';

  @override
  String get timberDepth => 'Hauteur h';

  @override
  String get timberMaterialTitle => 'Matériau et environnement';

  @override
  String get timberStrengthClass => 'Classe de résistance';

  @override
  String get timberDuration => 'Durée de charge';

  @override
  String get timberDurPermanent => 'Permanente';

  @override
  String get timberDurLong => 'Long terme';

  @override
  String get timberDurMedium => 'Moyen terme';

  @override
  String get timberDurShort => 'Court terme';

  @override
  String get timberDurInstant => 'Instantanée';

  @override
  String get timberServiceClass => 'Classe de service';

  @override
  String get timberServiceNote =>
      '1 : intérieur chauffé · 2 : abrité, non chauffé · 3 : exposé aux intempéries. La durée de charge est celle de l\'action la plus courte de la combinaison (charges d\'exploitation : moyen terme ; neige : court terme ; vent : instantanée).';

  @override
  String get timberBucklingNote =>
      'Flexion selon la hauteur h. Lcr = k × L pour le flambement selon y (dans le plan de flexion) et z, et lef = kLT × L pour le déversement (≈ 0,9 pour une charge répartie sur poutre isostatique, + 2h si la charge est appliquée sur la fibre comprimée).';

  @override
  String get timberSlsTitle => 'Flèche (travée isostatique)';

  @override
  String get timberGk => 'Permanente gk';

  @override
  String get timberQk => 'Variable qk';

  @override
  String get timberSlsNote =>
      'Charges réparties caractéristiques. Limites : L/300 instantanée sous qk, L/250 finale avec fluage (kdef). Laisser 0 pour ignorer.';

  @override
  String get timberStrengths => 'Contraintes et résistances de calcul';

  @override
  String get timberFactors => 'Coefficients de modification';

  @override
  String get timberAxialStress => 'Contrainte axiale';

  @override
  String get timberNoteScope =>
      'Sections rectangulaires, flexion selon l\'axe fort uniquement. kcr = 0,67 pour le cisaillement. La compression transversale, les entailles et les assemblages ne sont pas vérifiés.';

  @override
  String get checkCombinedStress => 'Flexion et effort normal';

  @override
  String get checkDeflectionInstant => 'Flèche instantanée';

  @override
  String get checkDeflectionFinal => 'Flèche finale';

  @override
  String get masonrySubtitle =>
      'EN 1996-1-1 · mur simple sous charge verticale';

  @override
  String get masonryUnit => 'Élément de maçonnerie';

  @override
  String get masonryClay => 'Terre cuite';

  @override
  String get masonryConcrete => 'Bloc béton';

  @override
  String get masonryCalciumSilicate => 'Silico-calcaire';

  @override
  String get masonryAac => 'Béton cellulaire autoclavé';

  @override
  String masonryGroup(int n) {
    return 'groupe $n';
  }

  @override
  String get masonryFb => 'Résistance des éléments fb';

  @override
  String get masonryFm => 'Résistance du mortier fm';

  @override
  String get masonryGammaHelp =>
      'Coefficient partiel de la maçonnerie, 1,5 à 3,0 selon le contrôle d\'exécution (Annexe nationale)';

  @override
  String get masonryWallTitle => 'Mur et chargement';

  @override
  String get masonryThickness => 'Épaisseur t';

  @override
  String get masonryHeight => 'Hauteur libre';

  @override
  String get masonryRestraint => 'Maintien aux extrémités';

  @override
  String get masonryRhoFloors => 'Planchers · ρ2 0,75';

  @override
  String get masonryRhoOther => 'Autre · ρ2 1,0';

  @override
  String get masonryLoad => 'Charge de calcul NEd';

  @override
  String get masonryETop => 'Excentricité en tête';

  @override
  String get masonryEBottom => 'Excentricité en pied';

  @override
  String get masonryEccNote =>
      'ρ2 = 0,75 quand les deux extrémités s\'appuient sur des planchers béton. Excentricité de la charge due aux appuis de plancher (M/N), mesurée depuis l\'axe du mur. L\'imperfection initiale hef/450 et le minimum 0,05 t sont ajoutés automatiquement.';

  @override
  String get masonryStrength => 'Résistance de la maçonnerie';

  @override
  String get masonryFk => 'Résistance caractéristique';

  @override
  String get masonryFd => 'Résistance de calcul';

  @override
  String get masonryCapacityTitle => 'Résistance verticale';

  @override
  String get masonryEffHeight => 'Hauteur efficace et élancement';

  @override
  String get masonryEInit => 'Excentricité initiale';

  @override
  String get masonryEnds => 'Tête et pied';

  @override
  String get masonryMid => 'Mi-hauteur';

  @override
  String get masonryCreep => 'Excentricité de fluage';

  @override
  String get masonryNRd => 'Résistance de calcul par mètre';

  @override
  String get masonryNoteScope =>
      'Mortier d\'usage courant, mur simple non armé. Les charges latérales (vent), les charges concentrées et les murs doubles ne sont pas traités. Excentricité à mi-hauteur déduite des valeurs d\'extrémité sur le cinquième central.';

  @override
  String get checkWallEnd => 'Résistance aux extrémités';

  @override
  String get checkWallMid => 'Résistance à mi-hauteur';

  @override
  String get windSubtitle => 'EN 1991-1-4 vent · EN 1991-1-3 neige';

  @override
  String get windTitle => 'Vent';

  @override
  String get windVb => 'Vitesse de référence vb';

  @override
  String get windVbHelp =>
      'vb = cdir · cseason · vb,0 selon la carte de l\'Annexe nationale (France : 22 à 28 m/s selon la région)';

  @override
  String get windTerrain => 'Catégorie de terrain';

  @override
  String get windTerrain0 => '0 · Mer, zone côtière';

  @override
  String get windTerrainI => 'I · Lacs, rase campagne';

  @override
  String get windTerrainII => 'II · Végétation basse, obstacles isolés';

  @override
  String get windTerrainIII => 'III · Villages, banlieues, forêts';

  @override
  String get windTerrainIV => 'IV · Urbain, ≥ 15 % bâti';

  @override
  String get windHeight => 'Hauteur du bâtiment h';

  @override
  String get windWidth => 'Largeur b (face au vent)';

  @override
  String get windDepth => 'Profondeur d (dans le sens du vent)';

  @override
  String get windGeometryNote =>
      'Bâtiment rectangulaire à toiture-terrasse, hauteur de référence ze = h (h ≤ b). Terrain plat (co = 1).';

  @override
  String get snowTitle => 'Neige';

  @override
  String get snowSk => 'Charge de neige au sol sk';

  @override
  String get snowSkHelp =>
      'Valeur caractéristique à l\'altitude du site selon l\'Annexe nationale (France : 0,45 à 1,40 kN/m² au niveau de la mer selon la région)';

  @override
  String get snowRoof => 'Toiture';

  @override
  String get snowRoofFlat => 'Plate';

  @override
  String get snowRoofMono => '1 pan';

  @override
  String get snowRoofDuo => '2 pans';

  @override
  String get snowPitch => 'Pente α';

  @override
  String get snowPitch1 => 'Pente α1';

  @override
  String get snowPitch2 => 'Pente α2';

  @override
  String get snowCeHelp =>
      'Exposition : 0,8 site balayé, 1,0 normal, 1,2 site abrité';

  @override
  String get windPeakTitle => 'Pression dynamique de pointe';

  @override
  String get windMeanVelocity => 'Rugosité et vitesse moyenne';

  @override
  String get windTurbulence => 'Intensité de turbulence';

  @override
  String get windExposure => 'Coefficient d\'exposition';

  @override
  String get windPeakPressure => 'Pression de pointe';

  @override
  String windWallsTitle(String e) {
    return 'Parois verticales (e = $e m)';
  }

  @override
  String get windRoofTitle => 'Toiture-terrasse';

  @override
  String windZone(String zone) {
    return 'Zone $zone';
  }

  @override
  String windZoneExtent(String zone, String extent) {
    return 'Zone $zone · $extent m';
  }

  @override
  String get windNetWall => 'Net au vent + sous le vent (D − E)';

  @override
  String get snowResultTitle => 'Charge de neige sur la toiture';

  @override
  String get snowShape => 'Coefficient de forme';

  @override
  String snowCase(String name) {
    return 'Disposition ($name)';
  }

  @override
  String get windNoteScope =>
      'Pressions extérieures we = qp · cpe,10 (surfaces chargées ≥ 10 m²) ; positives vers la paroi. Ajouter la pression intérieure cpi = +0,2 ou −0,3 en l\'absence de face dominante. Zones de toiture F/G le long du bord au vent sur e/10, H sur e/2. cs·cd = 1.';

  @override
  String get snowNoteScope =>
      'Situation de projet durable, Ct = 1. Les accumulations aux changements de hauteur, les arrêts de neige et la neige exceptionnelle ne sont pas traités. Toitures à 2 pans : (i) sans accumulation, (ii) et (iii) avec demi-charge sur un versant.';

  @override
  String get windPitchedNote =>
      'Les coefficients de pression du vent pour les toitures à versants (EN 1991-1-4 7.2.4, 7.2.5) ne sont pas encore calculés ; les zones de parois et qp restent valables.';

  @override
  String get seismicSubtitle =>
      'EN 1998-1 · méthode des forces latérales (4.3.3.2)';

  @override
  String get seismicHazard => 'Action sismique';

  @override
  String get seismicZone => 'Zone (France)';

  @override
  String get seismicZoneCustom => 'Autre — saisir agR';

  @override
  String seismicZoneN(int n, String ag) {
    return 'Zone $n · agR = $ag m/s²';
  }

  @override
  String get seismicAgR => 'Accélération de référence agR';

  @override
  String get seismicImportance => 'Catégorie d\'importance';

  @override
  String get seismicGround => 'Classe de sol';

  @override
  String get seismicSpectrumType => 'Spectre';

  @override
  String get seismicHazardNote =>
      'Paramètres de spectre recommandés de l\'EN 1998-1 (tableaux 3.2, 3.3) et γI = 0,8 / 1,0 / 1,2 / 1,4. Type 2 pour la sismicité modérée (métropole), type 1 pour la forte sismicité (Antilles). Vérifier les valeurs de l\'Annexe nationale pour votre projet.';

  @override
  String get seismicBuilding => 'Bâtiment';

  @override
  String get seismicSystem => 'Système structural (période)';

  @override
  String get seismicSysConcrete => 'Portiques béton (Ct = 0,075)';

  @override
  String get seismicSysSteel => 'Portiques acier (Ct = 0,085)';

  @override
  String get seismicSysOther => 'Voiles et autres (Ct = 0,050)';

  @override
  String get seismicStoreys => 'Niveaux';

  @override
  String get seismicStoreyHeight => 'Hauteur d\'étage';

  @override
  String get seismicFloorMass => 'Masse par plancher';

  @override
  String get seismicRoofMass => 'Masse de la toiture';

  @override
  String get seismicRoofHelp => 'Masse de toiture vide = comme les planchers';

  @override
  String get seismicQ => 'Coefficient de comportement q';

  @override
  String get seismicQHelp => 'q = 1,5 en faible dissipation (DCL)';

  @override
  String get seismicPeriodOverride => 'Période T1';

  @override
  String get seismicPeriodHelp => 'T1 vide = Ct · H^3/4';

  @override
  String seismicBaseShear(String fb) {
    return 'Effort tranchant à la base Fb = $fb kN';
  }

  @override
  String seismicMassRatio(String pct) {
    return '$pct % du poids sismique';
  }

  @override
  String get seismicPeriodOut =>
      'T1 dépasse min(4 TC, 2 s) : la méthode des forces latérales ne s\'applique pas ; utiliser l\'analyse modale spectrale.';

  @override
  String get seismicSpectrumTitle => 'Spectre de calcul';

  @override
  String get seismicDesignAg => 'Accélération de calcul';

  @override
  String get seismicSpectrumParams => 'Paramètres du spectre';

  @override
  String get seismicPeriod => 'Période fondamentale';

  @override
  String get seismicSd => 'Accélération spectrale';

  @override
  String get seismicLambda => 'Coefficient de correction';

  @override
  String get seismicTotalMass => 'Masse sismique totale';

  @override
  String get seismicOverturning => 'Moment de renversement à la base';

  @override
  String get seismicStoreyForces => 'Forces et efforts tranchants d\'étage';

  @override
  String seismicLevel(String z) {
    return 'Niveau +$z m';
  }

  @override
  String get seismicNoteScope =>
      'Bâtiment régulier en élévation, une direction horizontale. Forces d\'étage proportionnelles à hauteur × masse (4.11). La torsion accidentelle, la composante verticale, les effets du second ordre et le PS92 ne sont pas encore traités. Masse sismique = G + ψE,i Q.';

  @override
  String get slopeSubtitle =>
      'Méthode de Bishop simplifiée · recherche automatique du cercle critique';

  @override
  String get slopeGeometry => 'Géométrie du talus';

  @override
  String get slopeHeight => 'Hauteur H';

  @override
  String get slopeAngle => 'Pente β';

  @override
  String get slopeSurcharge => 'Surcharge en crête q';

  @override
  String get slopeMaxDepth => 'Profondeur max. sous le pied';

  @override
  String get slopeGeometryNote =>
      'Talus simple entre une crête et un pied horizontaux, β ≤ 75°. La profondeur max. limite les cercles profonds (vide = H).';

  @override
  String get slopeSoil => 'Sol (paramètres effectifs)';

  @override
  String get slopeGamma => 'Poids volumique γ';

  @override
  String get slopeCohesion => 'Cohésion c\'';

  @override
  String get slopePhi => 'Angle de frottement φ\'';

  @override
  String get slopeSoilNote =>
      'Sol homogène. Coefficient de pression interstitielle ru = u / (γ h) : 0 sec, environ 0,3 à 0,5 avec une nappe haute. Pour une argile non drainée, saisir c = cu et φ = 0.';

  @override
  String get slopeCritical => 'Cercle de glissement critique';

  @override
  String get slopeFactor => 'Coefficient de sécurité';

  @override
  String get slopeFactorEc7 => 'Avec les paramètres EC7 AC3';

  @override
  String get slopeCentre => 'Centre';

  @override
  String get slopeRadius => 'Rayon';

  @override
  String get slopeCircles => 'Cercles analysés';

  @override
  String get slopeNoteScope =>
      'Surfaces de rupture circulaires uniquement, origine au bord de la crête (x vers la droite, y vers le haut). F ≥ 1,5 requis (approche traditionnelle) et Fd ≥ 1,0 avec tan φ\' et c\' divisés par 1,25 et la surcharge × 1,3 (EN 1997-1 AC3). Les sols stratifiés, les nappes et les surfaces non circulaires ne sont pas traités.';

  @override
  String get checkSlopeGlobal => 'Coefficient de sécurité global';

  @override
  String get checkSlopeEc7 => 'Stabilité générale (EC7)';

  @override
  String get pileCapSubtitle => 'Bielles et tirants (Blévot) · 2, 3 ou 4 pieux';

  @override
  String get pileCapPiles => 'Nombre de pieux';

  @override
  String get pileCapGeometry => 'Charge et géométrie';

  @override
  String get pileCapLoad => 'Charge du poteau NEd (ELU)';

  @override
  String get pileCapSpacing => 'Entraxe des pieux';

  @override
  String get pileCapDiameter => 'Diamètre des pieux';

  @override
  String get pileCapColumn => 'Côté du poteau';

  @override
  String get pileCapDepth => 'Hauteur de la semelle h';

  @override
  String get pileCapEdge => 'Débord au-delà des pieux';

  @override
  String get pileCapGeometryNote =>
      'Poteau carré centré, pieux à entraxes égaux (≥ 2 diamètres) : en ligne, en triangle ou en carré. Enrobage mesuré aux tirants au-dessus des têtes de pieux. Le poids propre de la semelle × 1,35 est ajouté.';

  @override
  String pileCapDepthRange(String min, String max) {
    return 'Prendre une hauteur entre $min et $max mm';
  }

  @override
  String get pileCapDepthMsg =>
      'L\'angle des bielles doit rester entre 45° et 55° pour que le modèle bielles-tirants soit valable.';

  @override
  String get pileCapUseDepth => 'Prendre le milieu de la plage';

  @override
  String get pileCapModel => 'Modèle bielles et tirants';

  @override
  String get pileCapPlan => 'Dimensions en plan';

  @override
  String get pileCapSelfWeight => 'Poids propre de la semelle';

  @override
  String get pileCapReaction => 'Réaction d\'un pieu (ELU)';

  @override
  String get pileCapAngle => 'Angle des bielles';

  @override
  String pileCapTie(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tirants',
      one: '1 tirant',
    );
    return 'Effort par tirant ($_temp0)';
  }

  @override
  String get pileCapTieSteel => 'Acier par tirant';

  @override
  String get pileCapTieBars => 'Barres par tirant (au-dessus des pieux)';

  @override
  String get pileCapNodeColumn => 'Nœud sous le poteau';

  @override
  String get pileCapNodePile => 'Nœud au-dessus de chaque pieu';

  @override
  String get pileCapNoteScope =>
      'Semelle rigide, charge axiale centrée uniquement. Les tirants relient les têtes de pieux et sont ancrés au-delà des axes des pieux par des crochets. Prévoir un treillis (inférieur et supérieur) et des armatures de peau. La capacité des pieux et les effets de groupe ne sont pas vérifiés ici. Le nœud sous le poteau utilise la limite de base k1 ν′fcd (EC2 6.5.4(4)a), ce qui est conservatif : un nœud confiné peut justifier une limite plus élevée (6.5.4(6)).';

  @override
  String get checkStrutAngle => 'Angle des bielles';

  @override
  String get checkTieSteel => 'Armatures des tirants';

  @override
  String get checkNodeColumn => 'Nœud sous le poteau';

  @override
  String get checkNodePile => 'Nœud sur les pieux';

  @override
  String get septicSubtitle =>
      'Volume et dimensions d\'une fosse à deux compartiments';

  @override
  String get septicUse => 'Utilisation';

  @override
  String get septicUsers => 'Usagers';

  @override
  String get septicRooms => 'Pièces principales (maison)';

  @override
  String get septicFlow => 'Eaux usées par usager';

  @override
  String get septicRetention => 'Temps de séjour';

  @override
  String get septicSludge => 'Boues par usager';

  @override
  String get septicYears => 'Intervalle de vidange';

  @override
  String get septicUseNote =>
      'Valeurs usuelles : 100–150 L/j par usager avec eau courante, 40–60 L/j sans ; séjour de 1 jour ; 40 L de boues par usager et par an. Pour une maison, saisir le nombre de pièces principales pour appliquer le minimum du DTU 64.1 (3 m³ jusqu\'à 5 pièces, + 1 m³ par pièce supplémentaire).';

  @override
  String get septicShape => 'Forme';

  @override
  String get septicDepth => 'Hauteur d\'eau';

  @override
  String get septicFreeboard => 'Revanche';

  @override
  String get septicRatio => 'Longueur / largeur';

  @override
  String septicVolume(String v) {
    return 'Volume utile $v m³';
  }

  @override
  String septicDims(String l, String b, String h) {
    return 'Dimensions intérieures $l × $b m, profondeur totale $h m';
  }

  @override
  String get septicVolumes => 'Volumes';

  @override
  String get septicSettling => 'Décantation (débit × séjour)';

  @override
  String get septicSludgeVolume => 'Stockage des boues';

  @override
  String get septicDtuMin => 'Minimum DTU 64.1';

  @override
  String get septicProvided => 'Volume obtenu';

  @override
  String get septicLayout => 'Dimensions';

  @override
  String get septicInside => 'Dimensions intérieures';

  @override
  String get septicCompartments => 'Compartiments';

  @override
  String get septicNoteScope =>
      'Aide au dimensionnement uniquement : vérifier la réglementation locale. L\'épandage ou le traitement, la ventilation et le calcul structurel des parois et de la dalle ne sont pas traités.';

  @override
  String get f3dSubtitle =>
      'Ossatures spatiales : statique, modal, spectre de réponse et flambement';

  @override
  String get f3dNewBuilding => 'Nouveau bâtiment';

  @override
  String get f3dEditBuilding => 'Modifier le bâtiment';

  @override
  String get f3dEmptyTitle => 'Aucun modèle 3D';

  @override
  String get f3dEmptyMessage =>
      'Générez une ossature de bâtiment à partir de sa trame, de ses niveaux, de ses sections et des charges de plancher, puis explorez-la en 3D.';

  @override
  String f3dGridSummary(int x, int y, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n niveaux',
      one: '1 niveau',
    );
    return '$x × $y travées · $_temp0';
  }

  @override
  String f3dDefaultName(int x, int y, int n) {
    return 'Bâtiment $x×$y R+$n';
  }

  @override
  String get f3dWizardInvalid =>
      'Vérifiez les valeurs : nombres entiers de travées (1–20) et de niveaux (1–40), portées, hauteurs et sections positives.';

  @override
  String get f3dGrid => 'Trame';

  @override
  String get f3dBaysX => 'Travées en X';

  @override
  String get f3dSpanX => 'Portée X';

  @override
  String get f3dBaysY => 'Travées en Y';

  @override
  String get f3dSpanY => 'Portée Y';

  @override
  String get f3dStoreys => 'Niveaux';

  @override
  String get f3dGroundHeight => 'Rez-de-chaussée';

  @override
  String get f3dStoreyHeight => 'Étage courant';

  @override
  String get f3dSections => 'Sections';

  @override
  String get f3dMaterial => 'Matériau';

  @override
  String get f3dColumns => 'Poteaux';

  @override
  String get f3dBeams => 'Poutres';

  @override
  String get f3dLoads => 'Charges de plancher';

  @override
  String get f3dFloorG => 'Permanente g';

  @override
  String get f3dFloorQ => 'Exploitation q';

  @override
  String get f3dFacade => 'Façade sur poutres de rive';

  @override
  String get f3dLoadsNote =>
      'Appliquées à tous les niveaux, toiture comprise, transmises aux poutres par des lignes à 45° (charges uniformes équivalentes en moment). Le poids propre des barres est ajouté à G.';

  @override
  String get f3dSave => 'Enregistrer et analyser';

  @override
  String get f3dTabModel => 'Modèle';

  @override
  String get f3dTabStatic => 'Statique';

  @override
  String get f3dTabModes => 'Modes';

  @override
  String get f3dTabSeismic => 'Séisme';

  @override
  String get f3dTabBuckling => 'Flambement';

  @override
  String get f3dFootprint => 'Dimensions L × l × H';

  @override
  String get f3dNodesMembers => 'Nœuds / barres';

  @override
  String get f3dSeismicMass => 'Masse sismique';

  @override
  String get f3dModelNote =>
      'Pieds de poteaux encastrés, nœuds rigides ; les dalles agissent comme diaphragmes rigides si l\'option est choisie et ne sont pas modélisées autrement (les poutres portent les charges de plancher). Glisser pour tourner, pincer pour zoomer, deux doigts pour déplacer, double tap pour réinitialiser la vue.';

  @override
  String get f3dCombination => 'Combinaison';

  @override
  String get f3dColourBy => 'Afficher';

  @override
  String get f3dDeformed => 'Forme';

  @override
  String get f3dPDelta => 'Second ordre (P-Δ)';

  @override
  String get f3dPDeltaHelp =>
      'Itère avec la rigidité géométrique des efforts normaux.';

  @override
  String get f3dMaxVertical => 'Déplacement vertical max.';

  @override
  String get f3dMaxLateral => 'Déplacement horizontal max.';

  @override
  String get f3dMaxBeamMoment => 'Moment max. des poutres';

  @override
  String get f3dMaxColumnLoad => 'Compression max. des poteaux';

  @override
  String get f3dTotalReaction => 'Réaction verticale totale';

  @override
  String get f3dNoModes =>
      'Aucune masse vibrante : ajoutez des charges ou le poids propre.';

  @override
  String get f3dModesHelp =>
      'Masse issue de G + 0,3 Q. Touchez un mode pour l\'animer.';

  @override
  String f3dCumulativeMass(String x, String y) {
    return 'Masse cumulée : X $x · Y $y';
  }

  @override
  String get f3dCumulativeHelp =>
      'L\'EN 1998-1 4.3.3.3.1 demande au moins 90 % de la masse dans chaque direction.';

  @override
  String get f3dDirection => 'Direction';

  @override
  String get f3dRunSpectrum => 'Lancer le spectre de réponse';

  @override
  String f3dSpectrumMass(String pct) {
    return 'Modes retenus : $pct % de la masse dans cette direction (90 % requis).';
  }

  @override
  String get f3dModalContributions => 'Contributions modales';

  @override
  String f3dModeN(int n) {
    return 'Mode $n';
  }

  @override
  String get f3dSpectrumNote =>
      'Spectre de calcul de l\'EN 1998-1 (paramètres recommandés), amortissement 5 %, combinaison CQC de 12 modes. Les résultats sont des enveloppes (valeurs absolues).';

  @override
  String get f3dNoBuckling =>
      'Aucune barre n\'est comprimée : pas de coefficient de flambement.';

  @override
  String f3dAlphaCr(String a) {
    return 'αcr = $a';
  }

  @override
  String get f3dAlphaFirstOrder =>
      'αcr ≥ 10 : une analyse au premier ordre suffit (EN 1993-1-1 5.2.1).';

  @override
  String get f3dAlphaSecondOrder =>
      '3 ≤ αcr < 10 : tenir compte des effets du second ordre (activer P-Δ dans l\'onglet Statique).';

  @override
  String get f3dAlphaTooLow =>
      'αcr < 3 : l\'ossature est trop souple ; la rigidifier.';

  @override
  String f3dBucklingNote(String combo) {
    return 'Coefficient critique élastique de la combinaison $combo : les charges multipliées par αcr feraient flamber l\'ossature. La déformée de flambement est affichée.';
  }

  @override
  String get f3dBothDirections => 'X + Y';

  @override
  String get f3dAccidentalTorsion => 'Torsion accidentelle';

  @override
  String get f3dAccidentalTorsionHelp =>
      'Excentricité de ±5 % des forces d\'étage (EN 1998-1 4.3.2), ajoutée à la réponse modale.';

  @override
  String f3dBaseShearDir(String dir, String fb) {
    return 'Effort tranchant à la base $dir : $fb kN';
  }

  @override
  String f3dTorsionApplied(String m) {
    return 'Torsion accidentelle : Σ Mai = $m kN·m.';
  }

  @override
  String get f3dCombinedNote =>
      'Efforts affichés : le plus grand de EX + 0,3 EY et 0,3 EX + EY (EN 1998-1 4.3.3.5.1).';

  @override
  String get f3dRigidFloors => 'Planchers rigides (diaphragmes)';

  @override
  String get f3dRigidFloorsHelp =>
      'Les dalles solidarisent chaque niveau dans son plan : nécessaire pour la torsion accidentelle et des modes sismiques réalistes.';

  @override
  String get f3dPs92Zone => 'Zone sismique';

  @override
  String get f3dPs92Class => 'Classe d\'ouvrage';

  @override
  String get f3dPs92Site => 'Site';

  @override
  String f3dPs92Note(String an) {
    return 'PS92 (NF P 06-013) : aN = $an m/s², spectre normalisé R(T) du site, amortissement 5 % (ρ = 1), sans effet topographique (τ = 1). Accélération de calcul aN·R(T)/q.';
  }

  @override
  String get checkSteelBendingZ => 'Flexion d\'axe faible';

  @override
  String get f3dDesignStatic =>
      'Efforts de calcul : enveloppe des combinaisons ELU.';

  @override
  String get f3dDesignSeismic =>
      'Efforts de calcul : situation sismique G + 0,3 Q ± E (enveloppe).';

  @override
  String get f3dMinorMoment => 'Moment d\'axe faible';

  @override
  String get f3dBeamExtraForces => 'Flexion déviée ou effort normal';

  @override
  String get f3dBeamExtraForcesMsg =>
      'Cette poutre reprend aussi un moment d\'axe faible ou un effort normal notable, ignorés par le calcul en poutre. La calculer comme un poteau pour les prendre en compte.';

  @override
  String get f3dTapToDesign =>
      'Touchez une barre dans la vue pour la dimensionner.';

  @override
  String get f3dTabEdit => 'Modifier';

  @override
  String get f3dEditGenerated => 'Bâtiment généré';

  @override
  String get f3dEditGeneratedMsg =>
      'La première modification en fait un modèle personnalisé. Changer ensuite les paramètres du bâtiment le régénère et efface les modifications.';

  @override
  String get f3dRegenerate => 'Régénérer depuis les paramètres';

  @override
  String get f3dRegenerateConfirm =>
      'Effacer toutes les modifications et régénérer le bâtiment depuis ses paramètres ?';

  @override
  String get f3dConfirm => 'Confirmer';

  @override
  String get f3dUndo => 'Annuler';

  @override
  String get f3dConnect => 'Ajouter des barres';

  @override
  String get f3dAddNode => 'Ajouter un nœud';

  @override
  String get f3dConnectHelp =>
      'Touchez un nœud puis le suivant : chaque paire est reliée par une barre de la section active. Touchez à nouveau l\'outil pour arrêter.';

  @override
  String get f3dSelectHelp => 'Touchez un nœud ou une barre pour le modifier.';

  @override
  String get f3dLoadCase => 'Cas de charge';

  @override
  String get f3dAddCase => 'Ajouter un cas de charge';

  @override
  String get f3dCaseName => 'Nom';

  @override
  String get f3dCaseType => 'Type';

  @override
  String get f3dTypePermanent => 'Permanente (G)';

  @override
  String get f3dTypeImposed => 'Exploitation (Q)';

  @override
  String get f3dTypeSnow => 'Neige (S)';

  @override
  String get f3dTypeWind => 'Vent (W)';

  @override
  String get f3dActiveSection => 'Section des nouvelles barres';

  @override
  String get f3dAddSection => 'Ajouter une section';

  @override
  String get f3dSection => 'Section';

  @override
  String f3dNodeN(int n) {
    return 'Nœud $n';
  }

  @override
  String get f3dMove => 'Déplacer';

  @override
  String get f3dSupport => 'Appui';

  @override
  String get f3dSupportFree => 'Libre';

  @override
  String get f3dSupportPinned => 'Rotule';

  @override
  String get f3dSupportFixed => 'Encastré';

  @override
  String f3dNodalLoad(String name) {
    return 'Charge nodale ($name)';
  }

  @override
  String f3dMemberLoad(String name) {
    return 'Charge répartie ($name)';
  }

  @override
  String get f3dMemberLoadHelp =>
      'Axes globaux, kN/m le long de la barre ; la pesanteur est qz < 0.';

  @override
  String get f3dApplyLoad => 'Appliquer la charge';

  @override
  String get f3dApply => 'Appliquer';

  @override
  String get f3dRoll => 'Angle de rotation';

  @override
  String get f3dDeleteNode => 'Supprimer le nœud et ses barres';

  @override
  String get f3dDeleteMember => 'Supprimer la barre';

  @override
  String get modPlate => 'Dalles et radiers (EF)';

  @override
  String get modPlateSub => 'Plaques, aciers Wood–Armer';

  @override
  String get plateSubtitle =>
      'Éléments finis (plaque de Kirchhoff) · cartographies · ferraillage Wood–Armer';

  @override
  String get plateType => 'Élément';

  @override
  String get plateSlab => 'Dalle';

  @override
  String get plateRaft => 'Radier';

  @override
  String get plateGeometry => 'Géométrie et appuis';

  @override
  String get plateThickness => 'Épaisseur';

  @override
  String get plateSimple => 'Simple';

  @override
  String get plateColumns => 'Poteaux (x,y)';

  @override
  String get plateColumnsHelp =>
      'Appuis ponctuels sous une dalle ou poteaux d\'un radier, en mètres depuis l\'angle x = 0, y = 0, séparés par des espaces. Bords : appui le long de chaque côté.';

  @override
  String get plateSupports => 'Appuis';

  @override
  String get plateLoads => 'Charges';

  @override
  String get plateG => 'Permanente g (hors poids propre)';

  @override
  String get plateQ => 'Exploitation q';

  @override
  String get platePointLoads => 'Charges ponctuelles (x,y,P)';

  @override
  String get plateSubgrade => 'Module de réaction k';

  @override
  String get plateLoadsHelp =>
      'Le poids propre est ajouté (25 kN/m³). ELU : 1,35 G + 1,5 Q pour les moments et les aciers ; ELS : G + Q pour les flèches. Les charges ponctuelles sont des charges permanentes caractéristiques, en kN.';

  @override
  String get plateRaftHelp =>
      'Ressorts de Winkler : pression du sol = k · w. k usuel : 10 000–30 000 kN/m³ pour des sols moyens, selon le rapport géotechnique. Charges ponctuelles : descentes des poteaux (G), en kN.';

  @override
  String get plateMesh => 'Éléments sur le grand côté';

  @override
  String get plateSummary => 'Résultats';

  @override
  String get plateMaxDeflection => 'Flèche max. (élastique, non fissurée)';

  @override
  String get plateSpanRatio => 'Rapport à la portée';

  @override
  String get plateSoilPressure => 'Pression max. sur le sol';

  @override
  String get plateMomentsX => 'Moments x (ELU)';

  @override
  String get plateMomentsY => 'Moments y (ELU)';

  @override
  String get plateTwist => 'Moment de torsion';

  @override
  String plateColumnN(int n) {
    return 'Poteau $n';
  }

  @override
  String get plateReinforcement => 'Ferraillage (Wood–Armer)';

  @override
  String get plateBottomX => 'Inférieur x';

  @override
  String get plateBottomY => 'Inférieur y';

  @override
  String get plateTopX => 'Supérieur x';

  @override
  String get plateTopY => 'Supérieur y';

  @override
  String get plateMinimum => 'Minimum par nappe';

  @override
  String get plateShow => 'Afficher';

  @override
  String get plateFieldW => 'Flèche';

  @override
  String plateProbe(String x, String y, String value) {
    return 'x = $x m, y = $y m : $value';
  }

  @override
  String get plateNoteScope =>
      'Plaque rectangulaire, élastique linéaire, non fissurée (les flèches à long terme et fissurées sont plus grandes). Les poteaux sont des appuis ponctuels : vérifier le poinçonnement séparément et prendre les aciers sur poteaux sur les valeurs de pic (lissées sur la largeur du poteau en pratique). Barres x en nappe extérieure.';
}
