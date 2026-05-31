import '../../test_support/regression_expect.dart';
import 'setup_screen_presentation.dart';

void main() {
  summarizesMissingHandoffHostWithoutUrl();
  summarizesHostAndPortForActiveGatewayConfirmation();
  bracketsBareIpv6HostInActiveGatewayConfirmationSummary();
}

void summarizesMissingHandoffHostWithoutUrl() {
  const presentation = SetupScreenPresentation();

  final result = presentation.handoffHostSummary(
    scheme: 'https',
    address: '   ',
    port: '8765',
  );

  regressionExpect(
    result == 'the new gateway',
    'missing handoff host should use a safe generic label',
  );
}

void summarizesHostAndPortForActiveGatewayConfirmation() {
  const presentation = SetupScreenPresentation();

  final result = presentation.handoffHostSummary(
    scheme: ' https ',
    address: ' gateway.example ',
    port: ' 8765 ',
  );

  regressionExpect(
    result == 'https://gateway.example:8765',
    'handoff host summary should trim scheme, host, and port',
  );
}

void bracketsBareIpv6HostInActiveGatewayConfirmationSummary() {
  const presentation = SetupScreenPresentation();

  final result = presentation.handoffHostSummary(
    scheme: 'http',
    address: '2001:db8::1',
    port: '8765',
  );

  regressionExpect(
    result == 'http://[2001:db8::1]:8765',
    'bare IPv6 handoff host should be bracketed before adding a port',
  );
}
