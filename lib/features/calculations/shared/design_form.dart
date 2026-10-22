import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// Why a calculation could not run, tied to an input field.
class FormProblem {
  final String field;

  /// Null when the field is simply missing.
  final InputProblem? problem;

  const FormProblem(this.field, [this.problem]);
}

/// Where a calculation's inputs came from: a member or a support of a
/// 3D model, with a stamp of the model at that moment.
class ModelLink {
  final String modelId;
  final String modelName;

  /// Member (0-based) or node (0-based) the forces come from.
  final int? member;
  final int? node;

  /// [modelStamp] of the model when the forces were taken.
  final int stamp;

  const ModelLink({
    required this.modelId,
    required this.modelName,
    required this.stamp,
    this.member,
    this.node,
  });

  Map<String, Object?> toMetadata() => {
    'link_model': modelId,
    'link_name': modelName,
    'link_member': member,
    'link_node': node,
    'link_stamp': stamp,
  };
}

/// Stable 32-bit FNV-1a hash of a model's JSON source key.
int modelStamp(String sourceKey) {
  var h = 0x811c9dc5;
  for (final c in sourceKey.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// State shared by all design modules: numeric inputs by key, choice
/// options by key, the design code, and the last result.
class DesignFormState<R> {
  final Map<String, double?> values;
  final Map<String, String> options;
  final DesignCode code;
  final R? result;
  final FormProblem? problem;

  /// Identifier of the last saved calculation (changes on every run).
  final String? runId;

  /// Model the inputs were taken from (null = typed in).
  final ModelLink? link;

  const DesignFormState({
    required this.values,
    required this.options,
    required this.code,
    this.result,
    this.problem,
    this.runId,
    this.link,
  });

  double? operator [](String key) => values[key];

  DesignFormState<R> copyWith({
    Map<String, double?>? values,
    Map<String, String>? options,
    DesignCode? code,
    R? result,
    bool clearResult = false,
    FormProblem? problem,
    String? runId,
    ModelLink? link,
    bool clearLink = false,
  }) {
    return DesignFormState(
      values: values ?? this.values,
      options: options ?? this.options,
      code: code ?? this.code,
      result: clearResult ? null : (result ?? this.result),
      // Any edit clears the previous problem.
      problem: problem,
      runId: runId ?? this.runId,
      link: clearLink ? null : (link ?? this.link),
    );
  }
}

/// Default code from the settings; Eurocode when settings are unavailable.
DesignCode defaultDesignCode() {
  try {
    return SettingsService.getDefaultCode() == 'bael99'
        ? DesignCode.bael
        : DesignCode.ec2;
  } catch (_) {
    return DesignCode.ec2;
  }
}

/// Base notifier for a design module of one project.
abstract class DesignFormNotifier<R> extends Notifier<DesignFormState<R>> {
  DesignFormNotifier(this.projectId);
  final String projectId;

  /// Initial numeric values (null = empty field).
  Map<String, double?> get initialValues;

  /// Initial choice options.
  Map<String, String> get initialOptions => const {};

  /// Keys that must be filled before calculating, in display order.
  List<String> get requiredKeys;

  /// Runs the engine. May throw [InputError].
  R compute(DesignFormState<R> s);

  /// Runs [compute], possibly off the UI thread (heavy modules run it in
  /// an isolate). May throw [InputError].
  Future<R> computeAsync(DesignFormState<R> s) async => compute(s);

  /// Saves the result; returns the saved calculation id. Tools that keep
  /// no record (section properties, quantities) use this default.
  Future<String> saveResult(DesignFormState<R> s, R r) async =>
      DateTime.now().microsecondsSinceEpoch.toString();

  @override
  DesignFormState<R> build() => DesignFormState(
    values: {...initialValues},
    options: {...initialOptions},
    code: defaultDesignCode(),
  );

  void set(String key, double? value) {
    state = state.copyWith(values: {...state.values, key: value});
  }

  void setOption(String key, String value) {
    state = state.copyWith(options: {...state.options, key: value});
  }

  void setCode(DesignCode code) {
    // Results are code-specific: clear them when the code changes.
    state = state.copyWith(code: code, clearResult: true);
  }

  /// Starts from [values] and [options] taken from a model (the other
  /// fields keep their initial values) and remembers the [link].
  void applyLink(
    ModelLink link, {
    Map<String, double?> values = const {},
    Map<String, String> options = const {},
    DesignCode? code,
  }) {
    state = DesignFormState(
      values: {...initialValues, ...values},
      options: {...initialOptions, ...options},
      code: code ?? state.code,
      link: link,
    );
  }

  /// Forgets where the inputs came from.
  void unlink() => state = state.copyWith(clearLink: true);

  /// Replaces several values at once (e.g. a pre-sizing suggestion).
  void setAll(Map<String, double?> values) {
    state = state.copyWith(values: {...state.values, ...values});
  }

  Future<void> calculate() async {
    for (final key in requiredKeys) {
      if (state.values[key] == null) {
        state = state.copyWith(problem: FormProblem(key));
        return;
      }
    }
    final R result;
    try {
      result = await computeAsync(state);
    } on InputError catch (e) {
      state = state.copyWith(problem: FormProblem(e.field, e.problem));
      return;
    }
    String? id;
    try {
      id = await saveResult(state, result);
    } catch (e, st) {
      LoggerService.e('Saving calculation failed: $e', e, st);
    }
    state = state.copyWith(
      result: result,
      runId: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
    );
  }

  /// Saves an entity in the calculations box.
  Future<void> save(String id, Object entity) =>
      HiveService.getBox(HiveService.calculationsBox).put(id, entity);
}

/// Values that are safe to store in Hive metadata (flat primitives).
Map<String, dynamic> flatMetadata(
  DesignFormState<Object?> s,
  Map<String, Object?> results,
) => {
  'code': s.code.name,
  for (final e in s.values.entries)
    if (e.value != null) 'in_${e.key}': e.value,
  for (final e in s.options.entries) 'opt_${e.key}': e.value,
  for (final e in results.entries)
    if (e.value != null) e.key: e.value,
  if (s.link != null)
    for (final e in s.link!.toMetadata().entries)
      if (e.value != null) e.key: e.value,
};
