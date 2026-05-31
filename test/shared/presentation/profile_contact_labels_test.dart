import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/shared/presentation/profile_contact_labels.dart';

void main() {
  const profile = NavivoxProfileContact(
    serverId: 'srv1',
    profileId: 'mineru',
    displayName: 'Mineru Builder',
    serverLabel: 'Local',
    health: NavivoxProfileHealth.warning,
    latestPreview: 'Ready',
    workspaceRootCount: 4,
    workspaceRootsWarning: 2,
    workspaceRootsError: 1,
  );

  test('uses safe profile and server fallbacks for blank contacts', () {
    const blankContact = NavivoxProfileContact(
      serverId: 'srv1',
      profileId: 'mineru',
      displayName: ' ',
      serverLabel: ' ',
      health: NavivoxProfileHealth.online,
      latestPreview: 'Ready',
    );

    expect(
      profileContactDisplayLabel(blankContact, fallback: 'mineru'),
      'mineru',
    );
    expect(
      profileContactServerLabel(blankContact, fallback: 'default'),
      'default',
    );
    expect(profileContactDisplayLabel(null, fallback: 'default'), 'default');
    expect(profileContactServerLabel(null, fallback: 'default'), 'default');
  });

  test(
    'uses display, profile, server, then caller fallback for identity labels',
    () {
      expect(
        profileContactIdentityLabel(profile, fallback: 'profile'),
        'Mineru Builder',
      );
      expect(
        profileContactIdentityLabel(
          const NavivoxProfileContact(
            serverId: 'srv1',
            profileId: 'mineru',
            displayName: ' ',
            serverLabel: 'Local',
            health: NavivoxProfileHealth.online,
            latestPreview: 'Ready',
          ),
          fallback: 'profile',
        ),
        'mineru',
      );
      expect(
        profileContactIdentityLabel(
          const NavivoxProfileContact(
            serverId: 'srv1',
            profileId: ' ',
            displayName: ' ',
            serverLabel: 'Local',
            health: NavivoxProfileHealth.online,
            latestPreview: 'Ready',
          ),
          fallback: 'profile',
        ),
        'srv1',
      );
      expect(
        profileContactIdentityLabel(
          const NavivoxProfileContact(
            serverId: ' ',
            profileId: ' ',
            displayName: ' ',
            serverLabel: 'Local',
            health: NavivoxProfileHealth.online,
            latestPreview: 'Ready',
          ),
          fallback: 'profile',
        ),
        'profile',
      );
    },
  );

  test('formats project status segments and full status bar labels', () {
    expect(profileContactProjectStatusSegments(profile), [
      '4 projects',
      '1 error',
      '2 warnings',
    ]);
    expect(
      profileContactProjectStatusLabel(profile),
      '4 projects • 1 error • 2 warnings',
    );
    expect(
      profileContactStatusBarLabel(profile),
      'Local • warning • 4 projects • 1 error • 2 warnings',
    );
  });

  test(
    'reports project attention when no counts exist but roots are unhealthy',
    () {
      const profile = NavivoxProfileContact(
        serverId: 'srv1',
        profileId: 'mineru',
        displayName: 'Mineru Builder',
        serverLabel: 'Local',
        health: NavivoxProfileHealth.online,
        latestPreview: 'Ready',
        workspaceRootsOk: false,
      );

      expect(profileContactProjectStatusSegments(profile), [
        'project attention needed',
      ]);
      expect(
        profileContactStatusBarLabel(profile),
        'Local • online • project attention needed',
      );
    },
  );
}
