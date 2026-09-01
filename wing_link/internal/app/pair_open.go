package app

import (
	"html/template"
	"net/http"
	"net/url"
	"time"
)

const androidWingPackage = "com.trebuchetdynamics.hermes.wing"

func androidIntentURI(pairing *url.URL) string {
	return "intent://connect?" + pairing.RawQuery + "#Intent;scheme=wing;package=" + androidWingPackage + ";end"
}

func directWingURI(pairing *url.URL) string {
	return "wing://connect?" + pairing.RawQuery
}

var pairOpenTemplate = template.Must(template.New("pair-open").Parse(`<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="color-scheme" content="light dark">
<meta name="referrer" content="no-referrer">
<meta name="description" content="Open a secure, single-use Hermes Wing pairing request.">
<title>Open Hermes Wing</title>
<style>
:root {
  color-scheme: light dark;
  --accent: #229ed9;
  --accent-strong: #167fbd;
  --accent-end: #3b82f6;
  --page: #edf7fc;
  --surface: #ffffff;
  --text: #102a3a;
  --muted: #506b7a;
  --line: #cfe7f3;
  --soft: #e7f5fb;
  --focus: #0b5fff;
  --shadow: 0 1.5rem 4rem rgba(25, 100, 145, 0.2);
}
* { box-sizing: border-box; }
html, body { min-height: 100%; }
body {
  margin: 0;
  min-height: 100vh;
  min-height: 100dvh;
  display: grid;
  place-items: center;
  padding: max(1rem, env(safe-area-inset-top)) max(1rem, env(safe-area-inset-right)) max(1rem, env(safe-area-inset-bottom)) max(1rem, env(safe-area-inset-left));
  background: radial-gradient(circle at 15% 0%, rgba(34, 158, 217, 0.2), transparent 38%), linear-gradient(150deg, var(--page), #f7fbfe 65%);
  color: var(--text);
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  -webkit-font-smoothing: antialiased;
}
.card {
  width: min(100%, 29rem);
  padding: clamp(1.5rem, 6vw, 2.5rem);
  border: 1px solid rgba(34, 158, 217, 0.18);
  border-radius: 1.5rem;
  background: var(--surface);
  box-shadow: var(--shadow);
}
.brand {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1.75rem;
  color: var(--muted);
  font-size: 0.82rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}
.brand-mark {
  display: grid;
  width: 2.5rem;
  height: 2.5rem;
  place-items: center;
  border-radius: 0.8rem;
  background: linear-gradient(135deg, var(--accent), var(--accent-end));
  color: #ffffff;
  font-size: 1.15rem;
  box-shadow: 0 0.5rem 1.25rem rgba(34, 158, 217, 0.28);
}
h1 {
  margin: 0;
  max-width: 14ch;
  font-size: clamp(2rem, 9vw, 3rem);
  line-height: 1.02;
  letter-spacing: -0.045em;
  text-wrap: balance;
}
.intro {
  margin: 1rem 0 1.5rem;
  max-width: 36ch;
  color: var(--muted);
  font-size: 1.02rem;
  line-height: 1.6;
  text-wrap: pretty;
}
.trust {
  display: flex;
  gap: 0.75rem;
  align-items: flex-start;
  margin: 0 0 1.5rem;
  padding: 0.9rem 1rem;
  border: 1px solid var(--line);
  border-radius: 0.9rem;
  background: var(--soft);
  color: var(--text);
  font-size: 0.9rem;
  line-height: 1.45;
}
.trust-dot {
  flex: 0 0 auto;
  width: 0.65rem;
  height: 0.65rem;
  margin-top: 0.28rem;
  border-radius: 50%;
  background: var(--accent);
  box-shadow: 0 0 0 0.28rem rgba(34, 158, 217, 0.15);
}
.primary {
  min-height: 48px;
  width: 100%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.85rem 1.25rem;
  border-radius: 0.85rem;
  background: linear-gradient(135deg, var(--accent), var(--accent-end));
  box-shadow: 0 0.75rem 1.5rem rgba(34, 126, 205, 0.25);
  color: #ffffff;
  font-weight: 750;
  text-align: center;
  text-decoration: none;
  transition: transform 160ms ease, box-shadow 160ms ease, filter 160ms ease;
}
.primary:hover { filter: brightness(0.96); box-shadow: 0 0.9rem 1.8rem rgba(34, 126, 205, 0.3); }
.primary:active { transform: translateY(1px) scale(0.99); }
a:focus-visible { outline: 3px solid var(--focus); outline-offset: 4px; }
.fallback {
  margin: 1rem 0 0;
  color: var(--muted);
  font-size: 0.87rem;
  line-height: 1.5;
  text-align: center;
}
.fallback a { color: var(--accent-strong); font-weight: 650; text-underline-offset: 0.2em; }
@media (prefers-color-scheme: dark) {
  :root {
    --page: #071a26;
    --surface: #0d2635;
    --text: #edf8fd;
    --muted: #abc2cf;
    --line: #21485b;
    --soft: #123446;
    --accent: #36abe2;
    --accent-strong: #72c8ef;
    --focus: #89d5ff;
    --shadow: 0 1.5rem 4rem rgba(0, 9, 15, 0.45);
  }
  body { background: radial-gradient(circle at 15% 0%, rgba(34, 158, 217, 0.22), transparent 42%), var(--page); }
  .card { border-color: rgba(88, 183, 227, 0.18); }
}
@media (max-height: 32rem) and (orientation: landscape) {
  body { place-items: start center; }
  .card { padding: 1.25rem 1.5rem; }
  .brand { margin-bottom: 0.85rem; }
  h1 { font-size: 2rem; }
  .intro { margin: 0.65rem 0 0.85rem; }
  .trust { margin-bottom: 0.85rem; padding-block: 0.65rem; }
}
@media (prefers-reduced-motion: reduce) { .primary { transition: none; } }
</style>
</head>
<body>
<main class="card">
  <div class="brand" aria-label="Hermes Wing"><span class="brand-mark" aria-hidden="true">W</span><span>Hermes Wing</span></div>
  <h1>Connect to Hermes</h1>
  <p class="intro">Review this pairing request in Hermes Wing on this Android device.</p>
  <p class="trust"><span class="trust-dot" aria-hidden="true"></span><span><strong>Single-use pairing request</strong><br>This link expires in 5 minutes and does not contain your account credentials.</span></p>
  <a class="primary" href="wing://connect?code={{.Code}}{{if .Broker}}&broker={{.Broker}}{{end}}{{if .Control}}&control={{.Control}}{{end}}{{if .Fingerprint}}&host_fingerprint={{.Fingerprint}}{{end}}{{if .Origin}}&origin={{.Origin}}{{end}}{{if .Protocol}}&protocol_generation={{.Protocol}}{{end}}">Open Hermes Wing</a>
  <p class="fallback">Using Chrome and need another option? <a href="intent://connect?code={{.Code}}{{if .Broker}}&broker={{.Broker}}{{end}}{{if .Control}}&control={{.Control}}{{end}}{{if .Fingerprint}}&host_fingerprint={{.Fingerprint}}{{end}}{{if .Origin}}&origin={{.Origin}}{{end}}{{if .Protocol}}&protocol_generation={{.Protocol}}{{end}}#Intent;scheme=wing;package={{.Package}};end">Open with the Android intent</a>.</p>
</main>
</body>
</html>`))

type pairOpenTemplateData struct {
	Broker      string
	Code        string
	Control     string
	Fingerprint string
	Origin      string
	Package     string
	Protocol    string
}

func handlePairOpen(pairing *url.URL, expiresAt time.Time) http.HandlerFunc {
	return func(writer http.ResponseWriter, request *http.Request) {
		writer.Header().Set("Cache-Control", "no-store")
		writer.Header().Set("Pragma", "no-cache")
		writer.Header().Set("Referrer-Policy", "no-referrer")
		writer.Header().Set("Content-Security-Policy", "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'")
		writer.Header().Set("Content-Type", "text/html; charset=utf-8")
		writer.Header().Set("X-Content-Type-Options", "nosniff")
		if request.Method != http.MethodGet {
			writer.Header().Set("Allow", http.MethodGet)
			writer.WriteHeader(http.StatusMethodNotAllowed)
			return
		}
		if !time.Now().Before(expiresAt) {
			writer.WriteHeader(http.StatusGone)
			return
		}
		query := pairing.Query()
		_ = pairOpenTemplate.Execute(writer, pairOpenTemplateData{
			Broker:      query.Get("broker"),
			Code:        query.Get("code"),
			Control:     query.Get("control"),
			Fingerprint: query.Get("host_fingerprint"),
			Origin:      query.Get("origin"),
			Package:     androidWingPackage,
			Protocol:    query.Get("protocol_generation"),
		})
	}
}
