#!/bin/sh
# Runs every suite: the editor suites through `xo test run`, then each in-game suite in a fresh arena
# through `xo game eval`. Usage: sh tools/run_tests.sh [xo instance name]
XO="/Applications/Xogot.app/Contents/MacOS/xo"
APP=${1:-}
x() { if [ -n "$APP" ]; then "$XO" "$@" --app "$APP"; else "$XO" "$@"; fi; }
cd "$(dirname "$0")/.." || exit 1
fails=0
echo "== editor suites (tests/editor)"
x test run --root res://tests/editor | python3 -c "
import json,sys; d=json.load(sys.stdin); s=d['summary']; print('   passed %d / %d' % (s['passed'], s['total']))
sys.exit(0 if d['status']=='passed' else 1)" || fails=$((fails+1))
for t in test_camera test_facing test_weapons test_bandit_bounds test_cover test_crates test_wheel test_scenes_runtime; do
  echo "== $t (tests/game, live arena)"
  x project stop >/dev/null 2>&1
  sleep 1
  x project run --scene res://scenes/arena.tscn >/dev/null
  sleep 3
  out=$(x game eval --file "tests/game/$t.gd" --timeout 240)
  printf '%s' "$out" | python3 -c "
import json,sys
d=json.load(sys.stdin)
lines=[l for l in d.get('output',[]) if l.startswith('PASS') or l.startswith('FAIL') or l.startswith('INFO')]
print('\n'.join('   '+l for l in lines))
errs=[e for e in d.get('errors',[]) if 'xogot' not in e and 'UNUSED' not in e and 'SHADOWED' not in e and 'INTEGER' not in e]
if errs: print('   ERRORS:', errs[:3])
sys.exit(1 if any(l.startswith('FAIL') for l in lines) or not lines or errs else 0)" || fails=$((fails+1))
done
x project stop >/dev/null 2>&1
echo "== test_menu (tools/check_menu.py)"
python3 tools/check_menu.py $APP | sed "s/^/   /" || fails=$((fails+1))
echo "== suites with failures: $fails"
exit $fails
