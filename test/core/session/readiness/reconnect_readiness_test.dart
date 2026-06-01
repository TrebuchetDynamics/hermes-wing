import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/capabilities/navivox_gateway_capabilities.dart';
import 'package:navivox/core/session/reconnect_readiness.dart';

import '../support/reconnect_capabilities_test_support.dart';

void main() {
  test('reports unknown before capabilities are loaded', () {
    final readiness = ReconnectReadiness.fromCapabilities(null);

    expect(readiness.kind, ReconnectReadinessKind.unknown);
    expect(readiness.message, 'Checking reconnect support…');
  });

  test('reports unsupported without durable reconnect capability', () {
    final readiness = ReconnectReadiness.fromCapabilities(
      reconnectCapabilityDocument({}),
    );

    expect(readiness.kind, ReconnectReadinessKind.unsupported);
    expect(
      readiness.message,
      'Reconnect cannot be saved for this gateway yet.',
    );
    expect(
      readiness.recoveryMessage,
      contains('Connected for this app session'),
    );
  });

  test('reports blocked with gateway-supplied reason', () {
    final readiness = ReconnectReadiness.fromCapabilities(
      reconnectCapabilityDocument({
        'supported': true,
        'blocked_reason': 'HTTPS or private-network transport required.',
      }),
    );

    expect(readiness.kind, ReconnectReadinessKind.blocked);
    expect(
      readiness.recoveryMessage,
      'HTTPS or private-network transport required.',
    );
  });

  test(
    'blocks supported durable reconnect when issue contract is incomplete',
    () {
      final readiness = ReconnectReadiness.fromCapabilities(
        reconnectCapabilityDocument({
          'supported': true,
          'auth_methods': ['device_key_challenge'],
          'platforms': ['android'],
        }),
      );

      expect(readiness.kind, ReconnectReadinessKind.blocked);
      expect(
        readiness.recoveryMessage,
        'Durable reconnect is advertised but missing issue endpoint and effective security.',
      );
    },
  );

  test('blocks supported durable reconnect when security gate is missing', () {
    final readiness = ReconnectReadiness.fromCapabilities(
      reconnectCapabilityDocument({
        'supported': true,
        'issue_endpoint': '/v1/navivox/device-credentials',
        'auth_methods': ['device_key_challenge'],
        'platforms': ['android'],
      }),
    );

    expect(readiness.kind, ReconnectReadinessKind.blocked);
    expect(
      readiness.recoveryMessage,
      'Durable reconnect is advertised but missing effective security.',
    );
  });

  test(
    'reports available but not saved when durable reconnect is eligible',
    () {
      final readiness = ReconnectReadiness.fromCapabilities(
        reconnectCapabilityDocument({
          'supported': true,
          'issue_endpoint': '/v1/navivox/device-credentials',
          'auth_methods': ['device_key_challenge'],
          'platforms': ['android'],
          'effective_security': 'loopback',
        }),
      );

      expect(readiness.kind, ReconnectReadinessKind.available);
      expect(
        readiness.message,
        'Reconnect support is available but not saved yet.',
      );
    },
  );
}
