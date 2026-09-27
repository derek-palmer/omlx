"""The throughput-bench skip banner must explain the server's reason.

`upload_skipped` is shared by external endpoints, the Settings opt-out, and
ANE-aligned prompts. A single external-hardware sentence mislabels the
other two.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
I18N_DIR = ROOT / "omlx/admin/i18n"

# reason emitted by benchmark.py -> i18n key the banner must use
REASON_COPY = {
    "external_endpoint": "bench.upload_skipped.reason_external",
    "upload_disabled": "bench.upload_skipped.reason_disabled",
    "ane_aligned_prompt": "bench.upload_skipped.reason_ane_aligned",
}
FALLBACK_KEY = "bench.upload_skipped.reason_unknown"


def test_banner_selects_copy_from_the_event_reason():
    html = (ROOT / "omlx/admin/templates/dashboard/_bench.html").read_text()
    script = (ROOT / "omlx/admin/static/js/dashboard.js").read_text()

    assert "benchUploadSkippedMessage()" in html
    # The template used to hardcode the external-endpoint sentence.
    assert "bench.upload_skipped.reason_external" not in html

    for reason, key in REASON_COPY.items():
        assert reason in script
        assert key in script
    assert FALLBACK_KEY in script


def test_skip_reason_copy_exists_in_every_locale():
    required = set(REASON_COPY.values()) | {FALLBACK_KEY}
    for locale_path in sorted(I18N_DIR.glob("*.json")):
        locale = json.loads(locale_path.read_text(encoding="utf-8"))
        missing = {key for key in required if not locale.get(key)}
        assert not missing, f"{locale_path.name}: missing {sorted(missing)}"
