import 'dart:math' as math;

import '../beam.dart';
import '../column.dart';
import '../core.dart';
import '../steel_member.dart';
import '../steel_profiles.dart';
import '../timber.dart';
import 'analysis3d.dart';
import 'design3d.dart';
import 'edit3d.dart';
import 'model3d.dart';

/// Material of a design group.
enum DesignMaterial { concrete, steel, timber }

/// How reinforced concrete members are designed.
enum ConcreteRole { auto, beam, column }

/// Members designed with the same settings.
class DesignGroup {
  final String id;
  final String name;
  final List<int> members;
  final DesignMaterial material;

  // Reinforced concrete.
  final DesignCode code;
  final double fck;
  final double fyk;
  final double cover;
  final ConcreteRole role;

  /// Buckling length factor of columns (l0 = k·L).
  final double l0Factor;

  // Steel and timber stability: buckling length factors about y, z and
  // the lateral-torsional one.
  final String grade;
  final double ky;
  final double kz;
  final double kLT;

  // Timber.
  final String timberClass;
  final LoadDuration duration;
  final int serviceClass;

  /// Deflection limit as a span ratio (L / limit), SLS characteristic.
  final double deflectionLimit;

  const DesignGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.material,
    this.code = DesignCode.ec2,
    this.fck = 25,
    this.fyk = 500,
    this.cover = 30,
    this.role = ConcreteRole.auto,
    this.l0Factor = 1,
    this.grade = 'S275',
    this.ky = 1,
    this.kz = 1,
    this.kLT = 1,
    this.timberClass = 'C24',
    this.duration = LoadDuration.mediumTerm,
    this.serviceClass = 1,
    this.deflectionLimit = 250,
  });

  DesignGroup copyWith({
    String? name,
    List<int>? members,
    DesignMaterial? material,
    DesignCode? code,
    double? fck,
    double? fyk,
    double? cover,
    ConcreteRole? role,
    double? l0Factor,
    String? grade,
    double? ky,
    double? kz,
    double? kLT,
    String? timberClass,
    LoadDuration? duration,
    int? serviceClass,
    double? deflectionLimit,
  }) => DesignGroup(
    id: id,
    name: name ?? this.name,
    members: members ?? this.members,
    material: material ?? this.material,
    code: code ?? this.code,
    fck: fck ?? this.fck,
    fyk: fyk ?? this.fyk,
    cover: cover ?? this.cover,
    role: role ?? this.role,
    l0Factor: l0Factor ?? this.l0Factor,
    grade: grade ?? this.grade,
    ky: ky ?? this.ky,
    kz: kz ?? this.kz,
    kLT: kLT ?? this.kLT,
    timberClass: timberClass ?? this.timberClass,
    duration: duration ?? this.duration,
    serviceClass: serviceClass ?? this.serviceClass,
    deflectionLimit: deflectionLimit ?? this.deflectionLimit,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'members': members,
    'material': material.name,
    'code': code.name,
    'fck': fck,
    'fyk': fyk,
    'cover': cover,
    'role': role.name,
    'l0': l0Factor,
    'grade': grade,
    'ky': ky,
    'kz': kz,
    'kLT': kLT,
    'timber': timberClass,
    'duration': duration.name,
    'service': serviceClass,
    'defl': deflectionLimit,
  };

  factory DesignGroup.fromJson(Map<String, dynamic> j) {
    double d(String k, double v) => (j[k] as num?)?.toDouble() ?? v;
    return DesignGroup(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      members: (j['members'] as List? ?? const []).cast<int>(),
      material: DesignMaterial.values.byName(j['material'] as String),
      code: DesignCode.values.byName(j['code'] as String? ?? 'ec2'),
      fck: d('fck', 25),
      fyk: d('fyk', 500),
      cover: d('cover', 30),
      role: ConcreteRole.values.byName(j['role'] as String? ?? 'auto'),
      l0Factor: d('l0', 1),
      grade: j['grade'] as String? ?? 'S275',
      ky: d('ky', 1),
      kz: d('kz', 1),
      kLT: d('kLT', 1),
      timberClass: j['timber'] as String? ?? 'C24',
      duration: LoadDuration.values.byName(
        j['duration'] as String? ?? 'mediumTerm',
      ),
      serviceClass: j['service'] as int? ?? 1,
      deflectionLimit: d('defl', 250),
    );
  }
}

/// The material a member's section suggests: steel for library
/// profiles, concrete for rectangles, null otherwise.
DesignMaterial? sectionMaterial(Section3D s) {
  if (s.profile != null && steelProfiles.containsKey(s.profile)) {
    return DesignMaterial.steel;
  }
  if (s.b != null && s.h != null) {
    // Timber rectangles are much lighter than concrete ones.
    return s.unitWeight < 12 ? DesignMaterial.timber : DesignMaterial.concrete;
  }
  return null;
}

/// One group per material and member kind (columns, beams, braces) for
/// the members of [m] that are in no group yet. [name] labels them.
List<DesignGroup> autoGroups(
  Model3D m,
  String Function(DesignMaterial, MemberKind) name, {
  List<DesignGroup> existing = const [],
}) {
  final taken = {for (final g in existing) ...g.members};
  final byKey = <(DesignMaterial, MemberKind), List<int>>{};
  for (var e = 0; e < m.elements.length; e++) {
    if (taken.contains(e)) continue;
    final mat = sectionMaterial(m.sections[m.elements[e].section]);
    if (mat == null) continue;
    byKey.putIfAbsent((mat, m.kindOf(e)), () => []).add(e);
  }
  var n = existing.length;
  return [
    ...existing,
    for (final entry in byKey.entries)
      DesignGroup(
        id: 'g${++n}',
        name: name(entry.key.$1, entry.key.$2),
        members: entry.value,
        material: entry.key.$1,
        role: switch (entry.key.$2) {
          MemberKind.column => ConcreteRole.column,
          _ => ConcreteRole.beam,
        },
      ),
  ];
}

/// Design of one member of a group.
class MemberDesign3D {
  final int member;
  final String group;
  final DesignMaterial material;

  /// Reinforced concrete: designed as a column (else as a beam).
  final bool asColumn;
  final MemberEnvelope3D forces;
  final List<Check> checks;

  /// Reinforcement or section in a few words (e.g. "3 Ø16 / 2 Ø12").
  final String summary;

  /// Why the member could not be designed (input problem), if so.
  final InputError? error;

  const MemberDesign3D({
    required this.member,
    required this.group,
    required this.material,
    required this.forces,
    this.asColumn = false,
    this.checks = const [],
    this.summary = '',
    this.error,
  });

  /// Largest demand / capacity ratio (∞ when it could not be designed).
  double get ratio => error != null
      ? double.infinity
      : checks.fold<double>(0, (r, c) => math.max(r, c.ratio));

  Check? get governing => checks.isEmpty
      ? null
      : checks.reduce((a, b) => a.ratio >= b.ratio ? a : b);

  bool get ok => error == null && checks.every((c) => c.ok);
}

/// Largest deflection of a member relative to the chord between its
/// ends over [results], m.
double relativeDeflection(Frame3DResult r, int member) {
  final st = r.members[member].stations;
  final a = st.first.disp, b = st.last.disp;
  final l = st.last.x;
  var d = 0.0;
  for (final s in st) {
    final t = l == 0 ? 0.0 : s.x / l;
    var q = 0.0;
    for (var k = 0; k < 3; k++) {
      final v = s.disp[k] - (a[k] + (b[k] - a[k]) * t);
      q += v * v;
    }
    d = math.max(d, math.sqrt(q));
  }
  return d;
}

/// Designs the members of every group from the ULS results [uls] and
/// checks their deflections under the SLS results [sls].
List<MemberDesign3D> designGroups(
  Model3D m,
  List<DesignGroup> groups,
  List<Frame3DResult> uls,
  List<Frame3DResult> sls,
) {
  final out = <MemberDesign3D>[];
  final done = <int>{};
  for (final g in groups) {
    for (final e in g.members) {
      if (e < 0 || e >= m.elements.length || !done.add(e)) continue;
      out.add(designMember3D(m, g, e, uls, sls));
    }
  }
  return out;
}

MemberDesign3D designMember3D(
  Model3D m,
  DesignGroup g,
  int e,
  List<Frame3DResult> uls,
  List<Frame3DResult> sls,
) {
  final f = MemberEnvelope3D.of(m, e, uls);
  final s = m.sections[m.elements[e].section];
  var defl = 0.0;
  for (final r in sls) {
    defl = math.max(defl, relativeDeflection(r, e));
  }
  final deflection = Check(
    kind: CheckKind.deflection,
    demand: defl * 1000,
    capacity: f.length * 1000 / g.deflectionLimit,
    clause: 'L/${g.deflectionLimit.round()} (SLS)',
    unit: 'mm',
  );
  MemberDesign3D fail(InputError err, {bool asColumn = false}) =>
      MemberDesign3D(
        member: e,
        group: g.id,
        material: g.material,
        forces: f,
        asColumn: asColumn,
        error: err,
      );

  switch (g.material) {
    case DesignMaterial.concrete:
      if (s.b == null || s.h == null) {
        return fail(const InputError(InputProblem.outOfRange, 'section'));
      }
      final column = switch (g.role) {
        ConcreteRole.column => true,
        ConcreteRole.beam => false,
        ConcreteRole.auto => m.kindOf(e) == MemberKind.column,
      };
      try {
        if (column && f.nCompression > 0) {
          final r = designColumn(
            ColumnInput(
              code: g.code,
              b: s.b!,
              h: s.h!,
              l0: f.length * g.l0Factor,
              nEd: f.nCompression,
              m0Ed: f.myMax,
              m0EdB: f.mzMax,
              cover: g.cover,
              fck: g.fck,
              fyk: g.fyk,
            ),
          );
          return MemberDesign3D(
            member: e,
            group: g.id,
            material: g.material,
            forces: f,
            asColumn: true,
            checks: [...r.checks, deflection],
            summary:
                '${r.bars?.toString() ?? '—'} · Ø${r.linkDiameter} @ ${r.linkSpacing}',
          );
        }
        final r = designBeamSection(
          BeamSectionInput(
            code: g.code,
            b: s.b!,
            h: s.h!,
            mSagging: f.mySagging,
            mHogging: f.myHogging,
            vEd: f.vzMax,
            cover: g.cover,
            fck: g.fck,
            fyk: g.fyk,
          ),
        );
        return MemberDesign3D(
          member: e,
          group: g.id,
          material: g.material,
          forces: f,
          checks: [...r.checks, deflection],
          summary:
              '${r.bottomBars?.toString() ?? '—'} / ${r.topBars?.toString() ?? '—'}'
              ' · ${r.shear.links?.toString() ?? '—'}',
        );
      } on InputError catch (err) {
        return fail(err, asColumn: column);
      }
    case DesignMaterial.steel:
      final p = s.profile == null ? null : steelProfiles[s.profile];
      if (p == null || !steelDesignable(p)) {
        return fail(const InputError(InputProblem.outOfRange, 'section'));
      }
      try {
        final r = designSteelMember(
          SteelMemberInput(
            section: p,
            grade: g.grade,
            length: f.length,
            nEd: f.nCompression > 0 ? f.nCompression : -f.nTension,
            myEd: f.myMax,
            mzEd: f.mzMax,
            vEd: f.vzMax,
            ky: g.ky,
            kz: g.kz,
            kLT: g.kLT,
          ),
        );
        return MemberDesign3D(
          member: e,
          group: g.id,
          material: g.material,
          forces: f,
          checks: [...r.checks, deflection],
          summary: '${p.name} ${g.grade} · cl. ${r.sectionClass}',
        );
      } on InputError catch (err) {
        return fail(err);
      }
    case DesignMaterial.timber:
      final t = timberClasses[g.timberClass];
      if (s.b == null || s.h == null || t == null) {
        return fail(const InputError(InputProblem.outOfRange, 'section'));
      }
      try {
        final r = designTimberMember(
          TimberMemberInput(
            timber: t,
            b: math.min(s.b!, s.h!),
            h: math.max(s.b!, s.h!),
            length: f.length,
            nEd: f.nCompression > 0 ? f.nCompression : -f.nTension,
            myEd: f.myMax,
            vEd: f.vzMax,
            ky: g.ky,
            kz: g.kz,
            kLT: g.kLT,
            duration: g.duration,
            serviceClass: g.serviceClass,
          ),
        );
        return MemberDesign3D(
          member: e,
          group: g.id,
          material: g.material,
          forces: f,
          checks: [...r.checks, deflection],
          summary: '${t.name} · kmod ${r.kmod.toStringAsFixed(2)}',
        );
      } on InputError catch (err) {
        return fail(err);
      }
  }
}

/// Timber rectangle b × h (mm) of strength class [t]: E0,mean and a mean
/// density of 1.2 ρk for the self-weight.
Section3D timberSection(TimberClass t, double b, double h) {
  final r = Section3D.rectangle(
    b,
    h,
    e: t.e0mean,
    nu: 0.4,
    unitWeight: 1.2 * t.rhoK * 9.81 / 1000,
  );
  return Section3D(
    name: '${t.name} ${r.name}',
    area: r.area,
    iy: r.iy,
    iz: r.iz,
    j: r.j,
    youngModulus: r.youngModulus,
    // Timber shear modulus is about E / 16.
    shearModulus: t.e0mean / 16,
    unitWeight: r.unitWeight,
    b: b,
    h: h,
  );
}
