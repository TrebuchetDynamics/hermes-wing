import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/router/app_routes.dart';
import 'package:navivox/shared/widgets/app_shell_presentation.dart';

void main() {
  const presentation = AppShellPresentation();

  test(
    'centralizes App shell destination order, routes, labels, and icons',
    () {
      final destinations = presentation.destinations;

      expect(destinations.map((destination) => destination.path), [
        AppRoutes.chats,
        AppRoutes.servers,
        AppRoutes.agents,
        AppRoutes.memory,
        AppRoutes.config,
        AppRoutes.settings,
      ]);
      expect(destinations.map((destination) => destination.label), [
        'Chats',
        'Servers',
        'Agents',
        'Memory',
        'Config',
        'Settings',
      ]);
      expect(destinations.first.icon, Icons.chat_bubble_outlined);
      expect(destinations.last.icon, Icons.keyboard_voice_outlined);
      expect(presentation.mobileNavigationDestinations.map((d) => d.label), [
        'Chats',
        'Agents',
        'Memory',
        'Settings',
      ]);
      expect(presentation.mobileOverflowDestinations.map((d) => d.label), [
        'Servers',
        'Config',
      ]);
    },
  );

  test('selects destination by location with Chats as safe fallback', () {
    expect(
      presentation.stateForLocation(AppRoutes.memory).selectedDestination.label,
      'Memory',
    );
    expect(
      presentation
          .stateForLocation('/config/providers')
          .selectedDestination
          .label,
      'Config',
    );
    expect(
      presentation.stateForLocation('/unknown').selectedDestination.label,
      'Chats',
    );
  });

  test('hides mobile navigation only on Profile contact chat threads', () {
    expect(
      presentation.stateForLocation('/chats/local/mineru').showNavigationMenu,
      isFalse,
    );
    expect(
      presentation.stateForLocation(AppRoutes.chats).showNavigationMenu,
      isTrue,
    );
    expect(
      presentation.stateForLocation('/chats/local').showNavigationMenu,
      isTrue,
    );
    expect(
      presentation.stateForLocation(AppRoutes.servers).showNavigationMenu,
      isTrue,
    );
  });

  test('centralizes bottom nav overflow copy', () {
    expect(presentation.navigationMenuTooltip, 'Open navigation menu');
    expect(presentation.mobileOverflowLabel, 'More');
    expect(presentation.mobileOverflowTooltip, 'Open more destinations');
  });

  test('maps overflow routes to the More tab on mobile', () {
    expect(
      presentation.stateForLocation(AppRoutes.config).selectedMobileIndex,
      4,
    );
    expect(
      presentation.stateForLocation(AppRoutes.servers).selectedMobileIndex,
      4,
    );
    expect(
      presentation.stateForLocation(AppRoutes.memory).selectedMobileIndex,
      2,
    );
  });
}
