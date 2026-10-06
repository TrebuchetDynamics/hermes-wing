"""Bounded X11 input for the isolated native integration test display only."""
import ctypes as c
import os
import sys
import time
from pathlib import Path
import re

if os.environ.get('WING_ISOLATED_NATIVE_INPUT') != '1':
    raise SystemExit('Use the isolated native-input launcher.')
owned = Path(os.environ.get('WING_LINUX_TEST_ROOT', ''))
temp = Path(os.environ.get('TMPDIR', '/tmp')).resolve()
if (not owned.is_absolute() or owned.resolve() != owned or
        owned.parent != temp or not re.fullmatch(r'wing-linux-native\.[a-zA-Z0-9]+', owned.name) or
        not (owned / '.wing-linux-test-owner').is_file() or
        os.environ.get('XDG_CONFIG_HOME') != str(owned / 'config')):
    raise SystemExit('Owned native-input state unavailable.')
mode = sys.argv[1]
if mode not in ('type', 'pick', 'compose', 'compose_cancel', 'lifecycle', 'save', 'save_cancel'):
    raise SystemExit('Unknown native test action.')
x = c.CDLL('libX11.so.6')
t = c.CDLL('libXtst.so.6')
x.XOpenDisplay.argtypes = [c.c_char_p]
x.XOpenDisplay.restype = c.c_void_p
x.XDefaultRootWindow.argtypes = [c.c_void_p]
x.XDefaultRootWindow.restype = c.c_ulong
x.XQueryTree.argtypes = [c.c_void_p, c.c_ulong, c.POINTER(c.c_ulong), c.POINTER(c.c_ulong), c.POINTER(c.POINTER(c.c_ulong)), c.POINTER(c.c_uint)]
x.XFetchName.argtypes = [c.c_void_p, c.c_ulong, c.POINTER(c.c_char_p)]
x.XFree.argtypes = [c.c_void_p]
x.XKeysymToKeycode.argtypes = [c.c_void_p, c.c_ulong]
x.XKeysymToKeycode.restype = c.c_ubyte
x.XSetInputFocus.argtypes = [c.c_void_p, c.c_ulong, c.c_int, c.c_ulong]
x.XFlush.argtypes = [c.c_void_p]
x.XCloseDisplay.argtypes = [c.c_void_p]
x.XIconifyWindow.argtypes = [c.c_void_p, c.c_ulong, c.c_int]
x.XMapRaised.argtypes = [c.c_void_p, c.c_ulong]
t.XTestFakeKeyEvent.argtypes = [c.c_void_p, c.c_uint, c.c_int, c.c_ulong]
d = x.XOpenDisplay(None)
if not d:
    raise SystemExit('Owned X11 display unavailable.')

def windows(parent, depth=0):
    root, parent_return, count = c.c_ulong(), c.c_ulong(), c.c_uint()
    children = c.POINTER(c.c_ulong)()
    if not x.XQueryTree(d, parent, c.byref(root), c.byref(parent_return), c.byref(children), c.byref(count)):
        return []
    result = [children[i] for i in range(count.value)]
    if children:
        x.XFree(children)
    if depth < 2:
        for child in list(result):
            result.extend(windows(child, depth+1))
    return result

def title(window):
    name = c.c_char_p()
    x.XFetchName(d, window, c.byref(name))
    value = name.value.decode(errors='replace') if name.value else ''
    if name:
        x.XFree(name)
    return value

def key(symbol, down):
    code = x.XKeysymToKeycode(d, symbol)
    if not code:
        raise RuntimeError('Test key is not present in the X11 keymap.')
    t.XTestFakeKeyEvent(d, code, int(down), 0)
    x.XFlush(d)
    # Let the embedder process each physical transition before the next one.
    time.sleep(0.03)

def stroke(symbol):
    key(symbol, True)
    key(symbol, False)

try:
    deadline = time.monotonic()+10
    while True:
        expected_titles = (('Save File',) if mode in ('save', 'save_cancel') else
                           ('Open File', 'Open file', 'Open') if mode == 'pick' else
                           ('Hermes Wing',))
        targets = [w for w in windows(x.XDefaultRootWindow(d)) if title(w) in expected_titles]
        if targets:
            break
        if time.monotonic() > deadline:
            raise RuntimeError('Expected native test window did not appear.')
        time.sleep(0.05)
    x.XSetInputFocus(d, targets[-1], 2, 0)
    x.XFlush(d)
    time.sleep(0.1)
    if mode == 'save_cancel':
        stroke(0xff1b)
        print('Native save dialog cancelled with Escape.')
        sys.exit(0)
    if mode == 'lifecycle':
        x.XIconifyWindow(d, targets[-1], 0)
        x.XFlush(d)
        time.sleep(0.7)
        x.XMapRaised(d, targets[-1])
        x.XFlush(d)
        time.sleep(0.7)
        x.XSetInputFocus(d, targets[-1], 2, 0)
        x.XFlush(d)
        time.sleep(0.3)
        print('Native window minimize and restore requested.')
        sys.exit(0)
    if mode in ('compose', 'compose_cancel'):
        # GTK's real Unicode input method: compose an emoji, then cancel a
        # second composition. No clipboard or Flutter text-input injection.
        for codepoint, terminator in [('1f600', 0xff0d)] if mode == 'compose' else [('00e9', 0xff1b)]:
            key(0xffe3, True)
            key(0xffe1, True)
            stroke(ord('u'))
            key(0xffe1, False)
            key(0xffe3, False)
            for char in codepoint:
                stroke(ord(char))
                time.sleep(0.04)
            stroke(terminator)
            time.sleep(0.2)
        print('Native GTK composition commit and cancellation delivered.')
        sys.exit(0)
    text = 'native keyboard input'
    if mode in ('pick', 'save'):
        if mode == 'pick':
            text = os.environ['WING_NATIVE_PICK_FILE']
            if Path(text) != owned / 'sample.txt' or not os.path.isfile(text):
                raise RuntimeError('Only the owned picker fixture may be selected.')
        else:
            name = os.environ.get('WING_NATIVE_SAVE_FILENAME')
            if name not in ('hermes-transcript.txt', 'hermes-transcript.md'):
                raise RuntimeError('Only the fixed synthetic export may be selected.')
            text = str(owned / name)
        key(0xffe3, True)  # Control_L
        stroke(ord('l'))
        key(0xffe3, False)
        time.sleep(0.15)
        # Save dialogs select the basename but may leave the suggested extension
        # outside that selection. Replace the complete entry, not only the stem.
        key(0xffe3, True)
        stroke(ord('a'))
        key(0xffe3, False)
    for char in text:
        shifted = char.isupper() or char == '_'
        if shifted:
            key(0xffe1, True)  # Shift_L
        stroke(ord('-' if char == '_' else char.lower()))
        if shifted:
            key(0xffe1, False)
        time.sleep(0.003)
    if mode in ('pick', 'save'):
        stroke(0xff0d)  # Return
        # GTK resolves an explicitly entered path before accepting selection.
        time.sleep(0.6)
        stroke(0xff0d)
        if mode == 'save':
            print('save_dialog_still_open=' + str(any(title(w) == 'Save File' for w in windows(x.XDefaultRootWindow(d)))))
    print('Native input delivered on the isolated display.')
finally:
    x.XCloseDisplay(d)
