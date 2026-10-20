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
  String get modColumnSub => 'Compression, élancement';

  @override
  String get modSlab => 'Dalle';

  @override
  String get modSlabSub => 'Dalle portant dans un sens';

  @override
  String get modFooting => 'Semelle';

  @override
  String get modFootingSub => 'Isolée, filante';

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
  String get calcBetaTitle => 'Bêta : résultats non vérifiés';

  @override
  String get calcBetaMessage =>
      'Ce module est en cours de réécriture et de vérification sur des exemples de référence. N\'utilisez pas ces résultats pour l\'exécution.';

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
  String get calcLoad => 'Charge';

  @override
  String get calcHeight => 'Hauteur';

  @override
  String get beamSubtitle => 'Poutre sur appuis simples sous charge répartie.';

  @override
  String get beamGeometryLoad => 'Géométrie et charge';

  @override
  String get beamTotalLoad => 'Charge de calcul totale';

  @override
  String get beamWidth => 'Largeur b';

  @override
  String get beamDepth => 'Hauteur h';

  @override
  String get beamAdequate => 'Section suffisante';

  @override
  String get beamAdequateMsg =>
      'Ferraillage de flexion trouvé pour le moment de calcul.';

  @override
  String get beamInadequate => 'Section insuffisante';

  @override
  String get beamInadequateMsg => 'Augmentez la section ou la classe de béton.';

  @override
  String get beamBending => 'Ferraillage de flexion';

  @override
  String get beamSteelRequired => 'Section d\'acier requise';

  @override
  String get beamSuggestedBars => 'Barres proposées';

  @override
  String get beamLeverArm => 'Bras de levier';

  @override
  String get beamMomentRatio => 'Moment réduit';

  @override
  String get columnSubtitle => 'Poteau circulaire en compression centrée.';

  @override
  String get columnLoadGeometry => 'Charge et géométrie';

  @override
  String get columnAxialLoad => 'Effort normal';

  @override
  String get columnSlender => 'Poteau élancé';

  @override
  String get columnSlenderMsg =>
      'Les effets du second ordre doivent être vérifiés.';

  @override
  String get columnShort => 'Poteau court';

  @override
  String get columnShortMsg =>
      'Les effets du second ordre peuvent être négligés.';

  @override
  String get columnSection => 'Section';

  @override
  String get columnDiameter => 'Diamètre recommandé';

  @override
  String get columnRequiredArea => 'Section requise';

  @override
  String get columnHeightRatio => 'Hauteur / diamètre';

  @override
  String get slabSubtitle => 'Dalle portant dans un sens, sur appuis simples.';

  @override
  String get slabSpanLoad => 'Portée et charge';

  @override
  String get slabOneWay => 'Dalle portant dans un sens';

  @override
  String get slabThickness => 'Épaisseur recommandée';

  @override
  String get slabDesignMoment => 'Moment de calcul';

  @override
  String get slabSteelRequired => 'Acier requis';

  @override
  String get footingSubtitle => 'Semelle isolée sous poteau.';

  @override
  String get footingDesignBasis => 'Bases de calcul';

  @override
  String get footingCode => 'Règlement';

  @override
  String get codeEurocode => 'Eurocode';

  @override
  String get codeBael => 'BAEL 99';

  @override
  String get footingType => 'Type de semelle';

  @override
  String get footingIsolated => 'Isolée';

  @override
  String get footingCombined => 'Combinée';

  @override
  String get footingColumnActions => 'Efforts du poteau';

  @override
  String get footingAxialLoad => 'Effort normal';

  @override
  String get footingMoment => 'Moment';

  @override
  String get footingSoil => 'Sol';

  @override
  String get footingBearing => 'Capacité portante';

  @override
  String get footingUnitWeight => 'Poids volumique';

  @override
  String footingPresizing(String area) {
    return 'Prédimensionnement : environ $area m² de semelle';
  }

  @override
  String footingPresizingReason(String sf) {
    return 'D\'après la capacité portante du sol avec un coefficient de sécurité de $sf.';
  }

  @override
  String get footingAdequate => 'Dimensionnement satisfaisant';

  @override
  String get footingReview => 'Dimensionnement à revoir';

  @override
  String get footingDimensions => 'Dimensions';

  @override
  String get footingLxB => 'Longueur × largeur';

  @override
  String get footingPlanArea => 'Surface en plan';

  @override
  String get footingRequiredArea => 'Surface requise';

  @override
  String get footingThickness => 'Épaisseur';

  @override
  String get footingReinforcement => 'Ferraillage';

  @override
  String get footingSteelArea => 'Section d\'acier';

  @override
  String get footingBarSize => 'Diamètre des barres';

  @override
  String get footingSpacing => 'Espacement';

  @override
  String get wallSubtitle =>
      'Mur cantilever : renversement et prédimensionnement.';

  @override
  String get wallWallSoil => 'Mur et sol';

  @override
  String get wallRetainedHeight => 'Hauteur retenue';

  @override
  String get wallSoilUnitWeight => 'Poids volumique du sol';

  @override
  String get wallFrictionAngle => 'Angle de frottement φ';

  @override
  String get wallStable => 'Stable au renversement';

  @override
  String get wallOverturningRisk => 'Risque de renversement';

  @override
  String get wallStability => 'Stabilité';

  @override
  String get wallFosOverturning => 'Coefficient de sécurité au renversement';

  @override
  String get wallActiveThrust => 'Poussée active des terres';

  @override
  String get wallPresizing => 'Prédimensionnement (mur cantilever)';

  @override
  String get wallBaseWidth => 'Largeur de semelle';

  @override
  String get wallStemThickness => 'Épaisseur du voile';

  @override
  String get wallBaseThickness => 'Épaisseur de semelle';

  @override
  String get wallToeHeel => 'Patin / talon';

  @override
  String get wallAlternatives => 'Autres types de murs';

  @override
  String wallBaseApprox(String width) {
    return 'Base ≈ $width m';
  }

  @override
  String get wallGabion => 'Mur en gabions';

  @override
  String get wallGabionDesc =>
      'Cages grillagées remplies de pierres. Souple et drainant.';

  @override
  String get wallGabionPros =>
      'Excellent drainage, mise en œuvre simple, tolère les tassements.';

  @override
  String get wallGabionCons =>
      'Demande une grande emprise ; le grillage peut se corroder avec le temps.';

  @override
  String get wallStone => 'Maçonnerie de pierres';

  @override
  String get wallStoneDesc => 'Mur poids traditionnel en pierre naturelle.';

  @override
  String get wallStonePros => 'Très durable, esthétique, matériaux locaux.';

  @override
  String get wallStoneCons =>
      'Main-d\'œuvre importante, maçons qualifiés nécessaires.';

  @override
  String get wallBlocks => 'Blocs creux armés';

  @override
  String get wallBlocksDesc =>
      'Blocs de ciment avec armatures verticales et remplissage en béton.';

  @override
  String get wallBlocksPros =>
      'Plus rapide que la maçonnerie traditionnelle, qualité régulière.';

  @override
  String get wallBlocksCons =>
      'Hauteur limitée (en général moins de 3 m), pose des armatures précise.';

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
}
