import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/policy/hermes_surface_readiness.dart';
import 'package:wing/features/hermes_chat/diagnostics/hermes_diagnostics_export.dart';

const _contracts = {
  'jobs': ('GET', '/api/jobs', 'tasks:read', 'Jobs/schedules inventory'),
  'health_detailed': (
    'GET',
    '/health/detailed',
    'gateway:read',
    'Gateway health',
  ),
  'profile_soul': (
    'GET',
    '/api/profiles/{name}/soul',
    'profiles:read',
    'Persona/SOUL',
  ),
  'profile_soul_update': (
    'PUT',
    '/api/profiles/{name}/soul',
    'profiles:write',
    'Persona/SOUL',
  ),
};

HermesCapabilityDocument _catalog(String operation, String variant) =>
    HermesCapabilityDocument.fromJson({
      'schema_version': variant == 'schema' ? 2 : 1,
      'profile_context': {
        'type': variant == 'context' ? 'header' : 'query',
        'name': 'profile',
        'required': true,
        'default_profile_id': 'default',
      },
      'auth': {
        'type': 'bearer',
        'required': true,
        'granted_scopes': [
          for (final contract in _contracts.values)
            if (variant != 'missing grant' ||
                contract.$3 != _contracts[operation]!.$3)
              contract.$3,
          if (variant != 'extra missing') 'additional:read',
        ],
      },
      'endpoints': {
        for (final entry in _contracts.entries)
          entry.key: {
            'method': entry.key == operation && variant == 'method'
                ? 'POST'
                : entry.value.$1,
            'path': entry.key == operation && variant == 'path'
                ? '/api/other'
                : entry.value.$2,
            'profile_scoped': variant != 'unscoped',
            'required_scopes': [
              entry.value.$3,
              if (entry.key == operation) 'additional:read',
            ],
          },
      },
    });

HermesChannelState _state(HermesCapabilityDocument capabilities) =>
    HermesChannelState(
      status: HermesConnectionStatus.connected,
      selectedProfileId: 'default',
      capabilities: capabilities,
    );

HermesSurfaceReadiness _row(
  HermesCapabilityDocument capabilities,
  String name,
) => hermesSurfaceReadiness(
  capabilities,
).singleWhere((item) => item.title == _contracts[name]!.$4);

void main() {
  for (final context in [null, 'header']) {
    test(
      'unscoped persona without query context stays read-only: $context',
      () {
        final capabilities = HermesCapabilityDocument.fromJson({
          'schema_version': 1,
          if (context != null)
            'profile_context': {
              'type': context,
              'name': 'profile',
              'required': true,
              'default_profile_id': 'default',
            },
          'auth': {
            'type': 'bearer',
            'required': true,
            'granted_scopes': ['profiles:read', 'profiles:write'],
          },
          'endpoints': {
            for (final operation in ['profile_soul', 'profile_soul_update'])
              operation: {
                'method': _contracts[operation]!.$1,
                'path': _contracts[operation]!.$2,
                'profile_scoped': false,
                'required_scopes': [_contracts[operation]!.$3],
              },
          },
        });
        final state = _state(capabilities);
        expect(state.canReadProfileSoul, isTrue);
        expect(state.canEditProfileSoul, isFalse);
        expect(
          _row(capabilities, 'profile_soul_update').status,
          HermesSurfaceStatus.readOnly,
        );
        expect(
          hermesDiagnosticsExport(state),
          contains('Persona/SOUL: Read-only'),
        );
      },
    );
  }
  for (final operation in _contracts.keys) {
    for (final variant in [
      'schema',
      'method',
      'path',
      'context',
      'missing grant',
    ]) {
      test('$operation report matches operational denial for $variant', () {
        final capabilities = _catalog(operation, variant);
        final state = _state(capabilities);
        final allowed = switch (operation) {
          'jobs' => state.canReadJobs,
          'health_detailed' => state.canReadDetailedHealth,
          'profile_soul' => state.canReadProfileSoul,
          _ => state.canEditProfileSoul,
        };
        expect(allowed, isFalse);
        final expected =
            operation == 'profile_soul_update' &&
                (variant == 'method' ||
                    variant == 'path' ||
                    variant == 'missing grant')
            ? HermesSurfaceStatus.readOnly
            : HermesSurfaceStatus.deferred;
        final row = _row(capabilities, operation);
        expect(row.status, expected);
        expect(
          hermesDiagnosticsExport(state),
          contains('${row.title}: ${expected.label}'),
        );
      });
    }
    for (final variant in ['valid', 'unscoped']) {
      test('$operation preserves authorized $variant reporting', () {
        final capabilities = _catalog(operation, variant);
        final state = _state(capabilities);
        expect(state.canReadJobs, isTrue);
        expect(state.canReadDetailedHealth, isTrue);
        expect(state.canReadProfileSoul, isTrue);
        expect(state.canEditProfileSoul, isTrue);
        expect(
          _row(capabilities, operation).status,
          operation.startsWith('profile_soul')
              ? HermesSurfaceStatus.available
              : HermesSurfaceStatus.readOnly,
        );
        expect(
          hermesSurfaceReadiness(
            capabilities,
          ).singleWhere((row) => row.title == 'Jobs/schedules admin').status,
          HermesSurfaceStatus.deferred,
        );
      });
    }
  }
  test(
    'persona write report is read-only when extra write scope is denied',
    () {
      final capabilities = _catalog('profile_soul_update', 'extra missing');
      expect(_state(capabilities).canReadProfileSoul, isTrue);
      expect(_state(capabilities).canEditProfileSoul, isFalse);
      expect(
        _row(capabilities, 'profile_soul_update').status,
        HermesSurfaceStatus.readOnly,
      );
    },
  );
  test(
    'persona read report defers an additional ungranted scope denied by live gate',
    () {
      final capabilities = _catalog('profile_soul', 'extra missing');
      expect(_state(capabilities).canReadProfileSoul, isFalse);
      expect(_state(capabilities).canEditProfileSoul, isFalse);
      expect(
        _row(capabilities, 'profile_soul').status,
        HermesSurfaceStatus.deferred,
      );
    },
  );
  test(
    'health report defers an additional ungranted scope denied by live gate',
    () {
      final capabilities = _catalog('health_detailed', 'extra missing');
      expect(_state(capabilities).canReadDetailedHealth, isFalse);
      expect(
        _row(capabilities, 'health_detailed').status,
        HermesSurfaceStatus.deferred,
      );
    },
  );
  test(
    'jobs report defers an additional ungranted scope denied by live gate',
    () {
      final capabilities = _catalog('jobs', 'extra missing');
      expect(_state(capabilities).canReadJobs, isFalse);
      expect(_row(capabilities, 'jobs').status, HermesSurfaceStatus.deferred);
      expect(
        hermesDiagnosticsExport(_state(capabilities)),
        contains('Jobs/schedules inventory: Deferred'),
      );
    },
  );
}
