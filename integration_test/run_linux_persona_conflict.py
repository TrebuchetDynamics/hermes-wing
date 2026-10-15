"""Isolated GTK Persona recovery using deterministic transport, never a live Agent."""
import copy
import sys

from run_linux_shell_compact_return import run


def validate(receipt):
    assert type(receipt['native_pid']) is int and receipt['native_pid'] > 0
    expected = [dict(width=width, modal=modal, text_scale=2,
                     ordinary_failure_retains_draft=True,
                     conflict_loads_authoritative_text=True,
                     revisions=['r1', 'r1', 'r2', 'r3'], writes=4,
                     stale_completion_rejected=True, automatic_replays=0)
                for width in (390.0, 1280.0) for modal in (False, True)]
    assert receipt['journeys'] == expected
    for row, reference in zip(receipt['journeys'], expected):
        assert all(type(row[key]) is type(value) for key, value in reference.items())


def no_preferences(root, _digest):
    assert not list((root / 'data').rglob('shared_preferences.json'))
    return {'personal_storage': 'NOT_ACCESSED', 'preferences': 'MOCKED'}


def self_check():
    receipt = dict(native_pid=1, journeys=[dict(
        width=width, modal=modal, text_scale=2,
        ordinary_failure_retains_draft=True, conflict_loads_authoritative_text=True,
        revisions=['r1', 'r1', 'r2', 'r3'], writes=4,
        stale_completion_rejected=True, automatic_replays=0)
        for width in (390.0, 1280.0) for modal in (False, True)])
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
        raise AssertionError('Missing or invalid Persona proof accepted')
    print('Persona native receipt self-check passed')


if __name__ == '__main__':
    if sys.argv[1:] == ['--self-check']:
        self_check()
    else:
        assert not sys.argv[1:], 'No target or credential arguments accepted'
        run(card='verify-persona-native',
            target='integration_test/linux_persona_conflict_test.dart',
            receipt_name='persona-conflict.json', validate_receipt=validate,
            artifact_name='persona-conflict-receipt.json', inspect_preferences=no_preferences)
