#!/usr/bin/env python3
"""
Makes the "Nearest Safe Zone" screen find the location + route much faster.

  python tools/fix_location_speed.py            (run in the project root)

1) Uses the phone's last known position instantly, starts live GPS right away
   (no more waiting up to 20 s for a perfect GPS lock) and also asks for a
   quick medium-accuracy fix in parallel.
2) Requests the walking route and the driving route at the same time.
Prints what it changed; changes nothing if the code is already patched.
"""
import re, sys, glob, os

CANDIDATES = glob.glob('lib/**/safe_routing_map_screen.dart', recursive=True)
if not CANDIDATES:
    print('safe_routing_map_screen.dart not found - run from the project root.'); sys.exit(1)
path = CANDIDATES[0]
src = open(path, encoding='utf8', newline='').read()
crlf = '\r\n' in src
s = src.replace('\r\n', '\n')

if 'getLastKnownPosition' in s:
    print('GPS part: already patched')
else:
    pat = re.compile(
        r"      final pos = await Geolocator\.getCurrentPosition\(\)\s*\.timeout\(const Duration\(seconds: 20\)\);\s*"
        r"_onPosition\(pos\);\s*await _positionSub\?\.cancel\(\);\s*"
        r"_positionSub = Geolocator\.getPositionStream\(\s*locationSettings: const LocationSettings\(\s*"
        r"accuracy: LocationAccuracy\.high,\s*distanceFilter: 25,\s*\),\s*\)\.listen\(_onPosition, onError: \(Object _\) \{\}\);\n")
    new = """      // 1) Instant: the phone's last known position (no waiting for GPS).
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) _onPosition(last);
      } catch (_) {}
      // 2) Live updates start right away - the first fix refreshes the screen.
      await _positionSub?.cancel();
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 25,
        ),
      ).listen(_onPosition, onError: (Object _) {});
      // 3) Quick medium-accuracy fix in parallel (much faster than waiting
      //    for a perfect GPS lock).
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      ).then(_onPosition).catchError((Object _) {});
"""
    s2, n = pat.subn(lambda m: new, s, count=1)
    if n: s = s2; print('GPS part: patched')
    else: print('GPS part: block not found (file was changed by someone) - send me the _startLocation() method')

if 'final walkF' in s:
    print('Route part: already patched')
else:
    pat2 = re.compile(
        r"    var routes = await _getJson\(\s*'https://routing\.openstreetmap\.de/routed-foot/route/v1/foot/\$coords\?\$q'\);\s*"
        r"var walking = true;\s*routes \?\?= await _getJson\(\s*'https://router\.project-osrm\.org/route/v1/driving/\$coords\?\$q'\);\s*"
        r"if \(routes == null\) walking = false;\n")
    new2 = """    // Both are requested at the same time, so a slow walking server no
    // longer delays the route.
    final walkF = _getJson(
        'https://routing.openstreetmap.de/routed-foot/route/v1/foot/$coords?$q');
    final driveF = _getJson(
        'https://router.project-osrm.org/route/v1/driving/$coords?$q');
    var walking = true;
    var routes = await walkF.timeout(const Duration(seconds: 3),
        onTimeout: () => null);
    if (routes == null) {
      routes = await driveF;
      walking = false;
    }
"""
    s2, n = pat2.subn(lambda m: new2, s, count=1)
    if n: s = s2; print('Route part: patched')
    else: print('Route part: block not found (file was changed by someone)')

if s.replace('\n', '\r\n' if crlf else '\n') != src:
    out = s.replace('\n', '\r\n') if crlf else s
    open(path, 'w', encoding='utf8', newline='').write(out)
    print('Saved', path)
