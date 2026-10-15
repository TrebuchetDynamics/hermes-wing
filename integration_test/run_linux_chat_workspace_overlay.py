"""Isolated GTK overlay routing; in-memory channel, no live Agent or inference."""
import copy
import sys

from run_linux_shell_compact_return import run
from run_linux_persona_conflict import no_preferences


def expected_journeys():
    return [dict(width=width, entry=entry, destination=destination, dismissal=dismissal,
                 text_scale=2, chat_retained=True, draft_retained=True,
                 transcript_retained=True, exact_location_retained=True,
                 shell_entry_keyboard=entry == 'shell',
                 close_keyboard_focus=True, composer_focus_restored=entry != 'shell',
                 mutations=0)
            for width in (390.0, 1280.0)
            for entry, destination in (('shell', 'settings'), ('shell', 'profiles'),
                                       ('slash', 'settings'), ('slash', 'profiles'),
                                       ('completion', 'settings'), ('manage', 'profiles'))
            for dismissal in ('close', 'escape', 'back')]


def validate(receipt):
    assert type(receipt['native_pid']) is int and receipt['native_pid'] > 0
    expected = expected_journeys()
    assert receipt['journeys'] == expected
    for row, reference in zip(receipt['journeys'], expected):
        assert all(type(row[key]) is type(value) for key, value in reference.items())


def self_check():
    receipt = dict(native_pid=1, journeys=expected_journeys())
    validate(receipt)
    invalid = [{}, receipt | {'native_pid': True}, receipt | {'journeys': []}]
    for index, row in enumerate(receipt['journeys']):
        for key in row:
            changed = copy.deepcopy(receipt)
            changed['journeys'][index][key] = None
            invalid.append(changed)
    for value in invalid:
        try:
            validate(value)
        except (AssertionError, KeyError):
            continue
        raise AssertionError('Missing or invalid overlay proof accepted')
    print('Overlay native receipt self-check passed')


if __name__ == '__main__':
    if sys.argv[1:] == ['--self-check']:
        self_check()
    else:
        assert not sys.argv[1:], 'No target or credential arguments accepted'
        run(card='overlay-native-408',
            target='integration_test/linux_chat_workspace_overlay_test.dart',
            receipt_name='chat-workspace-overlay.json', validate_receipt=validate,
            artifact_name='chat-workspace-overlay-receipt.json',
            inspect_preferences=no_preferences)
