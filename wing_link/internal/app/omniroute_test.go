package app

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestOmniRouteDependencyClosureIsPinned(t *testing.T) {
	var lock struct {
		Packages map[string]struct{ Version, Resolved, Integrity string }
	}
	if err := json.Unmarshal(omniRouteLock, &lock); err != nil {
		t.Fatal(err)
	}
	if lock.Packages["node_modules/omniroute"].Version != omniRouteVersion {
		t.Fatal("runtime version differs from lock")
	}
	if len(lock.Packages) < 2 {
		t.Fatal("missing dependency closure")
	}
	for name, p := range lock.Packages {
		if name == "" {
			continue
		}
		if !strings.HasPrefix(p.Resolved, "https://registry.npmjs.org/") || !strings.HasPrefix(p.Integrity, "sha512-") {
			t.Fatalf("unverified dependency: %s", name)
		}
		for dependency, version := range map[string]string{"adm-zip": "0.6.0", "dompurify": "3.4.13", "sharp": "0.35.3"} {
			if strings.HasSuffix(name, "/"+dependency) && p.Version != version {
				t.Fatalf("unreviewed security override: %s@%s", name, p.Version)
			}
		}
	}
}

func TestOmniRouteStagingAndFailedProbe(t *testing.T) {
	for _, fail := range []bool{false, true} {
		t.Run(map[bool]string{false: "ready", true: "probe failure"}[fail], func(t *testing.T) {
			root := filepath.Join(t.TempDir(), "runtime")
			calls := 0
			run := func(_ context.Context, spec CommandSpec, onLine func(string)) ProcessResult {
				calls++
				if onLine != nil {
					t.Fatal("installer output forwarded")
				}
				if spec.Timeout <= 0 {
					t.Fatal("unbounded process")
				}
				if calls == 1 {
					args := strings.Join(spec.Args, " ")
					for _, flag := range []string{"ci", "--ignore-scripts", "--omit=dev", "--no-audit", "--registry=https://registry.npmjs.org"} {
						if !strings.Contains(args, flag) {
							t.Fatalf("missing %s", flag)
						}
					}
					if _, err := os.Stat(filepath.Join(root, omniRouteVersion)); !errors.Is(err, os.ErrNotExist) {
						t.Fatal("runtime activated before readiness")
					}
				}
				if fail && calls == 3 {
					return ProcessResult{Err: errors.New("private npm output must not escape")}
				}
				return ProcessResult{}
			}
			err := installOmniRouteAt(context.Background(), root, "node", "npm-cli.js", run)
			if fail {
				if err == nil || strings.Contains(err.Error(), "private") {
					t.Fatalf("unsafe error: %v", err)
				}
				if _, err := os.Stat(filepath.Join(root, omniRouteVersion)); !errors.Is(err, os.ErrNotExist) {
					t.Fatal("failed runtime activated")
				}
			} else if err != nil {
				t.Fatal(err)
			}
			leftovers, _ := filepath.Glob(filepath.Join(root, ".install-*"))
			if len(leftovers) > 0 {
				t.Fatal("staging directory leaked")
			}
			if calls != 3 {
				t.Fatalf("calls=%d", calls)
			}
			if !fail {
				calls = 1 // adoption must run only the two probes, never npm again.
				if err := installOmniRouteAt(context.Background(), root, "node", "npm-cli.js", run); err != nil {
					t.Fatal(err)
				}
				if calls != 3 {
					t.Fatal("adoption reran installation")
				}
			}
		})
	}
}

func TestOmniRouteRejectsUnsafeAndUnreviewedDestination(t *testing.T) {
	root := filepath.Join(t.TempDir(), "runtime")
	outside := t.TempDir()
	if err := os.Symlink(outside, root); err != nil {
		t.Fatal(err)
	}
	run := func(context.Context, CommandSpec, func(string)) ProcessResult {
		t.Fatal("unexpected process")
		return ProcessResult{}
	}
	if installOmniRouteAt(context.Background(), root, "node", "npm", run) == nil {
		t.Fatal("symlink accepted")
	}
	root = filepath.Join(t.TempDir(), "runtime")
	if err := os.MkdirAll(filepath.Join(root, omniRouteVersion), 0700); err != nil {
		t.Fatal(err)
	}
	if installOmniRouteAt(context.Background(), root, "node", "npm", run) == nil {
		t.Fatal("unreviewed runtime adopted")
	}
}

func TestOmniRouteSetupFlagIsLocalAndBounded(t *testing.T) {
	options, err := parseBootstrapOptions([]string{"--with-omniroute", "--json"})
	if err != nil || !options.WithOmniRoute || !options.JSON {
		t.Fatalf("options=%+v err=%v", options, err)
	}
	if _, err := parseBootstrapOptions([]string{"--with-omniroute", "--with-omniroute"}); err == nil {
		t.Fatal("duplicate option accepted")
	}
	var request BootstrapRequest
	if err := json.Unmarshal([]byte(`{}`), &request); err != nil {
		t.Fatal(err)
	}
	encoded, _ := json.Marshal(request)
	if string(encoded) != "{}" {
		t.Fatal("local installation leaked into remote bootstrap request")
	}
}

// Explicit integration check: downloads the locked runtime, without starting a server.
func TestOmniRouteRealInstall(t *testing.T) {
	if os.Getenv("WING_TEST_OMNIROUTE_INSTALL") != "1" {
		t.Skip("set WING_TEST_OMNIROUTE_INSTALL=1 for the network installation check")
	}
	node, err := omniRouteNode()
	if err != nil {
		t.Fatal(err)
	}
	npm, err := exec.LookPath("npm")
	if err != nil {
		t.Fatal(err)
	}
	npm, err = filepath.EvalSymlinks(npm)
	if err != nil {
		t.Fatal(err)
	}
	root := filepath.Join(t.TempDir(), "runtime")
	if err := installOmniRouteAt(context.Background(), root, node, npm, runProcess); err != nil {
		t.Fatal(err)
	}
	// Exercise the consumers of the patched 0.x dependencies without downloading
	// a model or calling an inference provider.
	const script = `
const assert = require('node:assert/strict');
const {createRequire} = require('node:module');
const {join} = require('node:path');
const {pathToFileURL} = require('node:url');
const root = process.argv[1];
const req = createRequire(join(root, 'package.json'));
const omni = createRequire(join(root, 'node_modules/omniroute/package.json'));
(async () => {
  const AdmZip = req('adm-zip');
  const zip = new AdmZip();
  zip.addFile('fixture.txt', Buffer.from('bounded fixture'));
  assert.equal(new AdmZip(zip.toBuffer()).readAsText('fixture.txt'), 'bounded fixture');
  const sharp = omni('sharp');
  const png = await sharp({create:{width:2,height:2,channels:3,background:{r:80,g:100,b:120}}}).png().toBuffer();
  const {RawImage} = await import(pathToFileURL(join(root, 'node_modules/@huggingface/transformers/src/utils/image.js')));
  const image = await RawImage.read(new Blob([png], {type:'image/png'}));
  const resized = await image.resize(4, 4);
  assert.equal(resized.width, 4);
  assert.equal(resized.height, 4);
  assert.equal(resized.data.length, 48);
  assert.equal(omni('dompurify').version, '3.4.13');
})().catch(error => { console.error(error); process.exitCode = 1; });
`
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	if output, err := exec.CommandContext(ctx, node, "-e", script, filepath.Join(root, omniRouteVersion)).CombinedOutput(); err != nil {
		t.Fatalf("patched dependency compatibility: %v\n%s", err, output)
	}
}
