"""Isolated GTK footer journey using the existing source/process/teardown harness."""

import copy
import math
import sys

from run_linux_shell_compact_return import run


EXPECTED = dict(phase='profile-footer', scales=[1.0, 2.0],
                input='WidgetTester.sendKeyEvent in native Flutter engine',
                resize_seam='IntegrationTestWidgetsFlutterBinding.setSurfaceSize + TestFlutterView.physicalSize',
                owner_replacement=True, obsolete_notification_ignored=True,
                compact_sidebar_absent=True, returned_width=64.0,
                reads=0, sends=0, mutations=0)
FOCUS_PHASES = ('expanded', 'collapsed', 'adaptive-return', 'space',
                'compact-recovery', 'enter', 'wide-recovery')


def recovery_rows():
    return [dict(scale=s, return_width=w, return_focused=True, route='/hermes', profile='b',
                 session='synthetic-session-b', profiles_route_reads=0,
                 reconnected=True, retired_notifications=3, draft='')
            for s in (1.0, 2.0) for w in (390.0, 1280.0)]


def exact(actual, expected):
    assert type(actual) is type(expected)
    if isinstance(expected, dict):
        assert actual.keys() == expected.keys()
        for key, value in expected.items():
            exact(actual[key], value)
    elif isinstance(expected, list):
        assert len(actual) == len(expected)
        for a, e in zip(actual, expected):
            exact(a, e)
    else:
        assert actual == expected


def validate(receipt):
    assert receipt.keys() == EXPECTED.keys() | {'native_pid', 'phases', 'focus', 'recovery'}
    exact({k: receipt[k] for k in EXPECTED}, EXPECTED)
    assert type(receipt['native_pid']) is int and receipt['native_pid'] > 0
    phases = [dict(scale=scale, key=key, navigations=1, profile='b',
                   session='synthetic-session-b', reads=0, sends=0, mutations=0)
              for scale in (1.0, 2.0) for key in ('space', 'enter')]
    exact(receipt['phases'], phases)
    exact(receipt['recovery'], recovery_rows())
    assert type(receipt['focus']) is list and len(receipt['focus']) == 14
    for row, (scale, phase) in zip(receipt['focus'],
            ((s, p) for s in (1.0, 2.0) for p in FOCUS_PHASES)):
        label = ('Manage profiles — Profile: Profile A' if phase in ('expanded', 'collapsed')
                 else 'Manage profiles — Profile: Profile B [redacted-path] token=[redacted]')
        assert row.keys() == {'scale', 'phase', 'rect', 'outline_pixels', 'inverse_traversal', 'label'}
        exact({k: row[k] for k in ('scale', 'phase', 'inverse_traversal', 'label')},
              dict(scale=scale, phase=phase, inverse_traversal=True, label=label))
        assert type(row['outline_pixels']) is int and row['outline_pixels'] >= 24
        rect = row['rect']
        assert type(rect) is list and len(rect) == 4
        assert all(type(v) is float and math.isfinite(v) for v in rect)
        left, top, right, bottom = rect
        assert 0 <= left < right <= 1280 and 0 <= top < bottom <= 720
        assert right - left >= 48 and bottom - top >= 48


def self_check():
    # Validator unit data only; never used as a native execution receipt.
    receipt: dict = dict(EXPECTED, native_pid=1, recovery=recovery_rows(),
        phases=[dict(scale=s, key=k, navigations=1, profile='b', session='synthetic-session-b',
                     reads=0, sends=0, mutations=0) for s in (1.0, 2.0) for k in ('space', 'enter')],
        focus=[dict(scale=s, phase=p, rect=[0.0, 0.0, 48.0, 48.0], outline_pixels=24,
                    inverse_traversal=True,
                    label='Manage profiles — Profile: Profile A' if p in ('expanded', 'collapsed')
                    else 'Manage profiles — Profile: Profile B [redacted-path] token=[redacted]')
               for s in (1.0, 2.0) for p in FOCUS_PHASES])
    validate(receipt)
    invalid = [{}, receipt | {'native_pid': 0}, receipt | {'native_pid': True},
               receipt | {'scales': [True, 2.0]}, receipt | {'phases': []}, receipt | {'focus': []}]
    for key in receipt:
        missing = copy.deepcopy(receipt)
        del missing[key]
        invalid.extend([missing, receipt | {key: None}])
    for collection in ('phases', 'focus', 'recovery'):
        for i, row in enumerate(receipt[collection]):
            for key in row:
                broken = copy.deepcopy(receipt)
                del broken[collection][i][key]
                invalid.append(broken)
                broken = copy.deepcopy(receipt)
                broken[collection][i][key] = None
                invalid.append(broken)
            wrong_values = (('route', '/profiles'), ('profile', 'a'), ('session', 'obsolete-session'),
                            ('profiles_route_reads', 1), ('reconnected', False),
                            ('return_focused', False),
                            ('retired_notifications', 2), ('draft', 'replayed')) if collection == 'recovery' else (
                (('reads', 1), ('navigations', 2), ('profile', 'a')) if collection == 'phases' else (
                    ('outline_pixels', 0), ('outline_pixels', 23), ('inverse_traversal', False), ('rect', [0.0, 0.0, 47.0, 48.0]),
                    ('rect', [0.0, 0.0, float('nan'), 48.0]), ('label', 'unredacted')))
            for key, wrong in wrong_values:
                broken = copy.deepcopy(receipt)
                broken[collection][i][key] = wrong
                invalid.append(broken)
    for broken in invalid:
        try:
            validate(broken)
        except (AssertionError, KeyError, TypeError):
            continue
        raise AssertionError('Incomplete or malformed footer proof accepted')
    print('profile-footer runner self-check passed')


if __name__ == '__main__':
    if sys.argv[1:] == ['--self-check']:
        self_check()
    else:
        assert not sys.argv[1:], 'Runner accepts no credentials or target arguments'
        run(card='t_66ec0dbc', target='integration_test/linux_profile_footer_native_test.dart',
            receipt_name='profile-footer.json', validate_receipt=validate,
            artifact_name='profile-footer.json')
