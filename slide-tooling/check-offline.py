#!/usr/bin/env python3
"""Check whether a rendered Quarto reveal.js deck works with no network.

    check-offline.py deck.html [deck2.html ...]

Exit 0 when every deck is self-contained, 1 otherwise.

Two things make a naive grep unreliable, and this handles both.

Quarto inlines CSS as a PERCENT-ENCODED data: URI, so `cdn.jsdelivr` appears as
`cdn%2Ejsdelivr` and a plain search misses it. Every data URI is decoded first.

Bundled libraries carry CDN hostnames as inert strings that never generate a
request. plotly.js is the case in point: it contains `unpkg.com/maki@2.1.0/...`
and a `topojsonURL` of `cdn.plot.ly/un/`, neither of which is fetched unless you
use a map trace. So a bare hostname is a WARNING to confirm in a browser, and
only a genuinely fetchable reference FAILS the check.

What actually breaks a deck, in order of how often it bites:
  - `<script type="module">import "https://cdn.plot.ly/..."`, which is how
    plotly.py 6.x loads itself. The URL sits inside JS, so embed-resources
    cannot rewrite it. Fix with `pio.renderers.default = "notebook"`.
  - a runtime `script.src = ...` or `link.href = ...`, which is how Quarto's
    KaTeX object-form and its MathJax loader work. Fix by using the bare string
    `html-math-method: katex` plus `self-contained-math: true`.
  - a literal `src=`/`href=` or CSS `url()` pointing at http(s).
  - `fetch()` or `XMLHttpRequest` against an absolute URL.

Even a clean result is not proof for a deck with interactive figures. Load it in
a browser, step through every slide so each widget instantiates, and read the
network log. Map traces (choropleth, scattergeo, mapbox) fetch topojson at
display time and cannot be made offline by embedding.
"""
import pathlib
import re
import sys
import urllib.parse

HOSTS = [
    "cdn.jsdelivr", "unpkg.com", "cdnjs", "ajax.googleapis", "fonts.googleapis",
    "fonts.gstatic", "mathjax.org", "plot.ly", "plotly.com", "d3js.org",
    "code.jquery", "maxcdn", "bootstrapcdn", "raw.githubusercontent",
    "polyfill.io", "esm.sh", "skypack.dev",
]

# Hostnames that ship as inert strings inside common bundles. A hit here is a
# warning, not a failure, unless a hard pattern also matches.
LIKELY_INERT = {"unpkg.com", "plot.ly", "plotly.com"}

# plotly.js embeds attribution links and map-icon paths for its map traces. They
# are present in every plotly bundle and fetched by none of it unless you use a
# map trace, so they are excused when the bundle is detected. Verified in a
# browser: a deck with three plotly figures made exactly one request, for itself.
# `cdn.plot.ly` in a MODULE IMPORT is never excused, because that is the real
# plotly.py 6.x failure and it does fetch.
PLOTLY_BUNDLE_HOSTS = [
    "unpkg.com", "plotly.com", "plot.ly", "mapbox.com", "maplibre.org",
    "openstreetmap.org", "carto.com", "stamen.com", "creativecommons.org",
    "opencagedata.com", "nasa.gov", "usgs.gov", "esri.com", "arcgisonline.com",
    "wikimedia.org", "openmaptiles.org",
]

HARD = [
    ("module import",
     re.compile(r'<script[^>]*type\s*=\s*["\']module["\'][^>]*>(?:(?!</script>).)*?'
                r'import\s*\(?\s*["\']https?://[^"\']+', re.S | re.I)),
    ("runtime script.src", re.compile(r'\.src\s*=\s*["\']https?://[^"\']+', re.I)),
    ("runtime link.href", re.compile(r'\.href\s*=\s*["\']https?://[^"\']+', re.I)),
    # Only tags whose URL is fetched at display time. A plain <a href="https://...">
    # navigates when clicked and costs the deck nothing on stage, and a deck that
    # cites with DOI links could otherwise never pass this check.
    ("element src/href", re.compile(
        r'<(?:script|link|img|iframe|source|video|audio|embed)\b[^>]*?'
        r'(?:src|href)\s*=\s*["\']https?://[^"\']+', re.I)),
    ("css url()", re.compile(r'url\(\s*["\']?https?://', re.I)),
    ("fetch/XHR", re.compile(r'(?:fetch|\.open)\s*\(\s*["\'](?:GET|POST)?["\']?\s*,?\s*'
                             r'["\']https?://[^"\']+', re.I)),
    ("plotly topojson", re.compile(r'topojsonURL\s*[:=]\s*["\']https?://[^"\']+', re.I)),
    # reveal's math plugin builds a script tag from a URL held in its config, so
    # the URL never sits next to a .src assignment. This is how the default
    # MathJax setup breaks offline, and a bare-hostname scan cannot tell it apart
    # from an inert string, so match the config key itself.
    ("reveal math config", re.compile(r'mathjax\s*:\s*["\']https?://[^"\']+', re.I)),
]

# plotly.py hardcodes include_mathjax="cdn" per figure, so a Python plotly deck
# carries an inlined MathJax 2 whose own body mentions these hosts. Inlined means
# nothing is fetched, and the reveal-math-config pattern above still catches the
# case where a MathJax URL is genuinely load-bearing.
MATHJAX_INERT = ["mathjax.org", "mathjax.rstudio.com"]


def haystack(raw: str) -> str:
    """Raw HTML plus every percent-decoded data URI payload."""
    chunks = []
    for m in re.finditer(r'data:[^,]*,([^"\')\s]+)', raw):
        try:
            chunks.append(urllib.parse.unquote(m.group(1)))
        except Exception:
            pass
    return raw + "\n".join(chunks)


def check(path: str) -> bool:
    p = pathlib.Path(path)
    print(f"--- {p.name} ---")
    if not p.exists():
        print("  ERROR: not found")
        return False
    raw = p.read_text(encoding="utf-8", errors="replace")
    hay = haystack(raw)

    print(f"  size               : {len(raw)/1048576:.2f} MB")

    has_plotly = "topojsonURL" in hay or "plotly.js" in hay or "Plotly.newPlot" in hay

    hard, excused, seen = [], [], set()
    for label, rx in HARD:
        for m in rx.finditer(hay):
            s = re.sub(r"\s+", " ", m.group(0))[:110]
            if s in seen:
                continue
            seen.add(s)
            # a module import of a CDN is the real plotly.py failure, never excused
            bundled = (has_plotly and label != "module import"
                       and any(h in s for h in PLOTLY_BUNDLE_HOSTS))
            (excused if bundled else hard).append((label, s))

    hosts = sorted({h for h in HOSTS if h in hay})
    excused_hosts = set(PLOTLY_BUNDLE_HOSTS) if has_plotly else set(LIKELY_INERT)
    # MathJax inlined by embed-resources leaves its own hostnames in the body.
    if "MathJax.Hub" in hay or "MathJax.Ajax" in hay:
        excused_hosts |= set(MATHJAX_INERT)
    inert = [h for h in hosts if h in excused_hosts]
    real = [h for h in hosts if h not in excused_hosts]

    if hard:
        print(f"  FETCHABLE REFS     : {len(hard)}")
        for label, s in hard[:8]:
            print(f"    [{label}] {s}")
    else:
        print("  fetchable refs     : none")

    if real:
        print(f"  external hosts     : {', '.join(real)}")
    if inert:
        print(f"  host strings, inert in a bundle: {', '.join(inert)}")

    print(f"  @font-face         : {hay.count('@font-face')}")
    if has_plotly:
        print(f"  plotly bundle      : present, {len(excused)} bundled refs excused "
              "(attribution and map icons)")
        print("                       map traces (choropleth/scattergeo/mapbox) DO fetch "
              "topojson and cannot be embedded")
        print("                       confirm in a browser: step through every slide, "
              "read the network log")

    unconv = len(re.findall(r'<span class="math[^"]*">', raw))
    mathml = raw.count("<math")
    note = "  (normal under html-math-method: katex)" if unconv and mathml == 0 else ""
    print(f"  math               : {mathml} mathml nodes, {unconv} client-rendered spans{note}")

    ok = not hard and not real
    print(f"  OFFLINE-SAFE       : {'YES' if ok else 'NO'}")
    if not ok:
        print("  likely fix         : math loader, use the bare string "
              "html-math-method: katex plus self-contained-math: true")
        print("                       python plotly, set pio.renderers.default = \"notebook\"")
    return ok


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    if not args:
        print(__doc__)
        return 2
    return 0 if all([check(a) for a in args]) else 1


if __name__ == "__main__":
    raise SystemExit(main())
