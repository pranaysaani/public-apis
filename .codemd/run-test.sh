#!/usr/bin/env bash
root="$(pwd)"
target="${1:-all}"
status=0
mkdir -p "$root/codemd-reports" "$root/.codemd/test-results"
if [ "$target" = "finalize" ]; then
  if [ ! -f "$root/.codemd/test-results/0.exit" ]; then echo "CODEMD_TIMEOUT 0"; echo "CODEMD_RESULT 0 124"; status=1; else code="$(cat "$root/.codemd/test-results/0.exit")"; [ "$code" -eq 0 ] || status=1; fi
  if [ ! -f "$root/.codemd/test-results/1.exit" ]; then echo "CODEMD_TIMEOUT 1"; echo "CODEMD_RESULT 1 124"; status=1; else code="$(cat "$root/.codemd/test-results/1.exit")"; [ "$code" -eq 0 ] || status=1; fi
  exit "$status"
fi
if [ "$target" = "all" ] || [ "$target" = "0" ]; then { echo '### CodeMD: changed-line coverage'; echo; echo 'Lines this change touched that the tests ran. The raw reports are in the **codemd-coverage-reports** zip under Artifacts, kept 90 days.'; echo; echo '| File | Changed lines run | Not run |'; echo '|---|---|---|'; } >> "${GITHUB_STEP_SUMMARY:-/dev/null}"; fi
if [ "$target" = "all" ] || [ "$target" = "0" ]; then
( cd scripts && eval 'python -m pytest -q tests/test_validate_links.py' ); code=$?
echo "$code" > "$root/.codemd/test-results/0.exit"
echo "CODEMD_RESULT 0 $code"; [ "$code" -eq 0 ] || status=1
fi
if [ "$target" = "all" ] || [ "$target" = "1" ]; then
( cd scripts && eval 'python -m coverage run -m pytest -q tests/test_validate_links.py' ); code=$?
echo "$code" > "$root/.codemd/test-results/1.exit"
echo "CODEMD_RESULT 1 $code"; [ "$code" -eq 0 ] || status=1
( cd scripts && eval 'python -m coverage json -q -o .codemd-coverage.json' ) >/dev/null 2>&1
( cd scripts && [ -f .codemd-coverage.json ] && cp .codemd-coverage.json "$root/codemd-reports/"1-coverage.py-codemd-coverage.json ) || true
( cd scripts && eval 'python -m coverage xml -q -o .codemd-cobertura.xml' >/dev/null 2>&1 && [ -s .codemd-cobertura.xml ] && cp .codemd-cobertura.xml "$root/codemd-reports/1-cobertura.xml" ) || true
( cd scripts && python3 "$root/.codemd/coverage_summary.py" coverage.py .codemd-coverage.json scripts/validate/links.py 58 58 1 58 ) || true
( cd scripts && python3 "$root/.codemd/coverage_summary.py" coverage.py .codemd-coverage.json scripts/validate/links.py 58 58 1.f0 58 ) || true
fi
exit "$status"
