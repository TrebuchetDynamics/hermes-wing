import 'dart:io';

const _expectedColumns = <String>[
  'ID',
  'Capability',
  'Classification',
  'Source identity',
  'Artifact or receipt identity',
  'Platform',
  'Evidence date UTC',
  'Limitations',
];

const _classifications = <String>{
  'battle-tested',
  'qualified',
  'deterministically tested',
  'build/device-smoke tested',
  'prototype/partial',
  'unverified',
  'unverified physical/acoustic',
  'planned only',
};

const _receiptBearingClassifications = <String>{
  'battle-tested',
  'qualified',
  'deterministically tested',
  'build/device-smoke tested',
};

void main(List<String> arguments) {
  try {
    final options = _Options.parse(arguments);
    final rows = _parseMatrix(File(options.matrixPath));
    final failures = _validate(rows, options);
    if (failures.isNotEmpty) {
      for (final failure in failures) {
        stderr.writeln('evidence_matrix=FAIL $failure');
      }
      exitCode = 2;
      return;
    }
    stdout.writeln(
      'evidence_matrix=PASS rows=${rows.length} '
      'max_age_days=${options.maxAgeDays}',
    );
  } on FormatException catch (error) {
    stderr.writeln('evidence_matrix=FAIL ${error.message}');
    exitCode = 2;
  } on FileSystemException catch (error) {
    stderr.writeln('evidence_matrix=FAIL ${error.message}');
    exitCode = 2;
  }
}

final class _Options {
  const _Options({
    required this.matrixPath,
    required this.now,
    required this.maxAgeDays,
  });

  final String matrixPath;
  final DateTime now;
  final int maxAgeDays;

  static _Options parse(List<String> arguments) {
    var matrixPath = 'docs/quality/evidence-matrix.md';
    var now = DateTime.now().toUtc();
    var maxAgeDays = 90;
    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (index + 1 >= arguments.length) {
        throw FormatException('missing value for $argument');
      }
      final value = arguments[++index];
      switch (argument) {
        case '--matrix':
          matrixPath = value;
        case '--now':
          now = DateTime.parse(value).toUtc();
        case '--max-age-days':
          maxAgeDays = int.parse(value);
        default:
          throw FormatException('unknown argument: $argument');
      }
    }
    if (maxAgeDays < 0) {
      throw const FormatException('--max-age-days must be non-negative');
    }
    return _Options(matrixPath: matrixPath, now: now, maxAgeDays: maxAgeDays);
  }
}

final class _EvidenceRow {
  const _EvidenceRow(this.cells);

  final List<String> cells;

  String get id => cells[0];
  String get capability => cells[1];
  String get classification => cells[2].toLowerCase();
  String get sourceIdentity => cells[3];
  String get artifactIdentity => cells[4];
  String get platform => cells[5];
  String get evidenceDate => cells[6];
  String get limitations => cells[7];
}

List<_EvidenceRow> _parseMatrix(File file) {
  if (!file.existsSync()) {
    throw FormatException('matrix does not exist: ${file.path}');
  }
  final tableLines = file
      .readAsLinesSync()
      .where((line) => line.trimLeft().startsWith('|'))
      .toList(growable: false);
  if (tableLines.length < 3) {
    throw const FormatException('matrix table is missing or empty');
  }
  final header = _splitRow(tableLines.first);
  if (!_sameCells(header, _expectedColumns)) {
    throw FormatException(
      'matrix header must be: ${_expectedColumns.join(' | ')}',
    );
  }
  if (!_isSeparator(_splitRow(tableLines[1]))) {
    throw const FormatException('matrix separator row is invalid');
  }
  return tableLines
      .skip(2)
      .map(_splitRow)
      .where((cells) => cells.isNotEmpty)
      .map((cells) {
        if (cells.length != _expectedColumns.length) {
          throw FormatException(
            'matrix row has ${cells.length} cells; expected '
            '${_expectedColumns.length}: ${cells.join(' | ')}',
          );
        }
        return _EvidenceRow(cells);
      })
      .toList(growable: false);
}

List<String> _splitRow(String line) {
  final trimmed = line.trim();
  if (!trimmed.startsWith('|') || !trimmed.endsWith('|')) return const [];
  return trimmed
      .substring(1, trimmed.length - 1)
      .split('|')
      .map((cell) => cell.trim().replaceAll('`', ''))
      .toList(growable: false);
}

bool _sameCells(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _isSeparator(List<String> cells) {
  return cells.length == _expectedColumns.length &&
      cells.every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell));
}

List<String> _validate(List<_EvidenceRow> rows, _Options options) {
  final failures = <String>[];
  final ids = <String>{};
  for (final row in rows) {
    if (row.cells.any((cell) => cell.isEmpty)) {
      failures.add('${row.id.isEmpty ? '<missing-id>' : row.id}: empty field');
      continue;
    }
    if (!ids.add(row.id)) failures.add('${row.id}: duplicate ID');
    if (!_classifications.contains(row.classification)) {
      failures.add('${row.id}: unsupported classification ${row.cells[2]}');
    }
    if (row.sourceIdentity.toLowerCase() == 'none') {
      failures.add('${row.id}: source identity is required');
    }
    if (row.limitations.toLowerCase() == 'none') {
      failures.add('${row.id}: limitations must state an actual boundary');
    }

    DateTime date;
    try {
      final value = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(row.evidenceDate)
          ? '${row.evidenceDate}T00:00:00Z'
          : row.evidenceDate;
      date = DateTime.parse(value).toUtc();
    } on FormatException {
      failures.add('${row.id}: invalid evidence date ${row.evidenceDate}');
      continue;
    }
    if (date.isAfter(options.now)) {
      failures.add('${row.id}: evidence date is in the future');
    }

    if (_receiptBearingClassifications.contains(row.classification)) {
      if (row.artifactIdentity.toLowerCase() == 'none') {
        failures.add('${row.id}: receipt identity is required');
      }
      final age = options.now.difference(date).inDays;
      if (age > options.maxAgeDays) {
        failures.add(
          '${row.id}: stale receipt ($age days; max ${options.maxAgeDays})',
        );
      }
    }
  }
  if (rows.isEmpty) {
    failures.add('matrix must contain at least one evidence row');
  }
  return failures;
}
