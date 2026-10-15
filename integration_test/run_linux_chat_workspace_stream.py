"""Isolated GTK production HTTP/SSE fixture; no live Agent or inference."""
import copy
import sys

from run_linux_shell_compact_return import run
from run_linux_persona_conflict import no_preferences


def expected_journeys():
    return [dict(width=width, destination=destination, dismissal=dismissal, text_scale=2,
                 progressive_chunks=2, completed_under_overlay=True,
                 canonical_reply=True, chat_retained=True, draft_retained=True,
                 exact_owner_retained=True, exact_location_retained=True,
                 sends=1, history_reads=2, unexpected_requests=0, endpoint_saves=0)
            for width in (390.0, 1280.0)
            for destination in ('settings', 'profiles')
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
    invalid = [{}, receipt | {'native_pid': True}, receipt | {'native_pid': 0},
               receipt | {'journeys': []}]
    for index, row in enumerate(receipt['journeys']):
        for key, value in row.items():
            for wrong in (None, not value if type(value) is bool else
                          value + 1 if type(value) in (int, float) else 'other'):
                changed = copy.deepcopy(receipt)
                changed['journeys'][index][key] = wrong
                invalid.append(changed)
    for value in invalid:
        try:
            validate(value)
        except (AssertionError, KeyError):
            continue
        raise AssertionError('Missing or invalid streaming proof accepted')
    print('Streaming native receipt self-check passed')


if __name__ == '__main__':
    if sys.argv[1:] == ['--self-check']:
        self_check()
    else:
        assert not sys.argv[1:], 'No target or credential arguments accepted'
        run(card='overlay-native-profile-sse-408',
            target='integration_test/linux_chat_workspace_stream_test.dart',
            receipt_name='chat-workspace-stream.json', validate_receipt=validate,
            artifact_name='chat-workspace-stream-receipt.json',
            inspect_preferences=no_preferences)
