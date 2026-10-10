import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/responder_controller.dart';
import '../widgets/c4_ui.dart';

/// Opens the map-based zone broadcast screen (FR11).
/// (Name kept so every existing caller keeps working.)
Future<void> showBroadcastDialog(
  BuildContext context, {
  String zone = '',
  String title = 'IMMEDIATE EVACUATION ORDER',
  String message =
      'Water level critical. Flash flood imminent. Evacuate to the nearest relief camp immediately.',
  LatLng? center,
  double radiusKm = 2,
}) {
  return pushPage(
    context,
    BroadcastScreen(
      zone: zone,
      title: title,
      message: message,
      center: center,
      radiusKm: radiusKm,
    ),
    frame: false,
  );
}

const List<String> _districts = [
  'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle',
  'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara', 'Kandy', 'Kegalle',
  'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara', 'Monaragala',
  'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura',
  'Trincomalee', 'Vavuniya',
];

class _Poly {
  final List<LatLng> outer;
  final List<List<LatLng>> holes;
  const _Poly(this.outer, this.holes);
}

class _Hit {
  final String name;
  final String label;
  final LatLng point;
  final LatLngBounds? bounds;
  final List<_Poly> polys;
  final String? district;
  final String? city;
  const _Hit({
    required this.name,
    required this.label,
    required this.point,
    this.bounds,
    this.polys = const [],
    this.district,
    this.city,
  });
}

class BroadcastScreen extends StatefulWidget {
  final String zone;
  final String title;
  final String message;
  final LatLng? center;
  final double radiusKm;

  const BroadcastScreen({
    super.key,
    this.zone = '',
    required this.title,
    required this.message,
    this.center,
    this.radiusKm = 2,
  });

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final MapController _map = MapController();
  final TextEditingController _search = TextEditingController();
  late final TextEditingController _zone =
      TextEditingController(text: widget.zone);
  late final TextEditingController _title =
      TextEditingController(text: widget.title);
  late final TextEditingController _msg =
      TextEditingController(text: widget.message);
  final TextEditingController _city = TextEditingController(text: 'All');

  late LatLng _point = widget.center ?? const LatLng(6.9271, 79.8612);
  late double _radius = widget.radiusKm;
  String _district = 'All';
  String _severity = 'Critical';

  List<_Poly> _polys = [];
  LatLngBounds? _bounds;
  String? _areaName;

  List<_Hit> _results = [];
  bool _searching = false;
  String? _searchError;
  bool _sending = false;

  @override
  void dispose() {
    _map.dispose();
    _search.dispose();
    _zone.dispose();
    _title.dispose();
    _msg.dispose();
    _city.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Search (OpenStreetMap Nominatim) - district / city / town
  // ---------------------------------------------------------------------------
  List<_Poly> _parseGeo(dynamic g) {
    try {
      if (g is! Map) return [];
      final type = g['type'];
      final c = g['coordinates'];
      List<LatLng> ring(dynamic r) => (r as List)
          .map((p) => LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()))
          .toList();
      _Poly poly(dynamic p) => _Poly(
            ring(p[0]),
            [for (var i = 1; i < (p as List).length; i++) ring(p[i])],
          );
      if (type == 'Polygon') return [poly(c)];
      if (type == 'MultiPolygon') return [for (final p in c as List) poly(p)];
    } catch (_) {}
    return [];
  }

  String? _matchDistrict(String raw) {
    final r = raw.toLowerCase().replaceAll('district', '').trim();
    if (r.isEmpty) return null;
    for (final d in _districts) {
      if (d.toLowerCase() == r || r.contains(d.toLowerCase())) return d;
    }
    return null;
  }

  Future<List<_Hit>> _geocode(String q) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'jsonv2',
        'limit': '6',
        'countrycodes': 'lk',
        'addressdetails': '1',
        'polygon_geojson': '1',
        'polygon_threshold': '0.003',
      });
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'dev.lasha.flood_disaster');
      req.headers.set(HttpHeaders.acceptLanguageHeader, 'en');
      final res = await req.close().timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as List<dynamic>;
      final out = <_Hit>[];
      for (final e in data) {
        final lat = double.tryParse(e['lat'].toString());
        final lon = double.tryParse(e['lon'].toString());
        if (lat == null || lon == null) continue;
        final label = (e['display_name'] ?? '').toString();
        var name = (e['name'] ?? '').toString().trim();
        if (name.isEmpty) name = label.split(',').first.trim();

        LatLngBounds? bounds;
        final bb = e['boundingbox'];
        if (bb is List && bb.length == 4) {
          final s = double.tryParse(bb[0].toString());
          final n = double.tryParse(bb[1].toString());
          final w = double.tryParse(bb[2].toString());
          final ea = double.tryParse(bb[3].toString());
          if (s != null && n != null && w != null && ea != null) {
            bounds = LatLngBounds(LatLng(s, w), LatLng(n, ea));
          }
        }

        final addr = (e['address'] is Map) ? e['address'] as Map : const {};
        String? district = _matchDistrict(
            (addr['state_district'] ?? addr['county'] ?? '').toString());
        district ??= _matchDistrict(name);
        final cityRaw = (addr['city'] ??
                addr['town'] ??
                addr['suburb'] ??
                addr['village'] ??
                addr['municipality'] ??
                '')
            .toString()
            .trim();
        // A hit that IS a district has no separate city.
        final isDistrictHit = _matchDistrict(name) != null &&
            name.toLowerCase().contains('district');
        out.add(_Hit(
          name: name,
          label: label,
          point: LatLng(lat, lon),
          bounds: bounds,
          polys: _parseGeo(e['geojson']),
          district: district,
          city: (cityRaw.isEmpty || isDistrictHit) ? null : cityRaw,
        ));
      }
      return out;
    } finally {
      client.close();
    }
  }

  Future<void> _runSearch() async {
    final q = _search.text.trim();
    if (q.isEmpty || _searching) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _searchError = null;
      _results = [];
    });
    try {
      final hits = await _geocode(q);
      if (!mounted) return;
      setState(() {
        _results = hits;
        if (hits.isEmpty) _searchError = 'No place found for "$q"';
      });
      if (hits.length == 1) _pick(hits.first);
    } catch (e) {
      if (!mounted) return;
      setState(() => _searchError = 'Search failed. Check the internet.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _pick(_Hit h) {
    setState(() {
      _point = h.point;
      _polys = h.polys;
      _bounds = h.bounds;
      _areaName = h.name;
      _results = [];
      _searchError = null;
      _zone.text = h.name;
      if (h.district != null) _district = h.district!;
      _city.text = (h.city == null || h.city!.isEmpty) ? 'All' : h.city!;
      _search.text = h.name;
    });
    try {
      if (h.bounds != null) {
        _map.fitCamera(CameraFit.bounds(
          bounds: h.bounds!,
          padding: const EdgeInsets.all(36),
        ));
      } else {
        _map.move(h.point, 13);
      }
    } catch (_) {}
  }

  void _clearArea() {
    setState(() {
      _polys = [];
      _bounds = null;
      _areaName = null;
    });
  }

  double get _effectiveRadiusKm {
    final b = _bounds;
    if (_polys.isNotEmpty && b != null) {
      return ResponderController.kmBetween(_point, b.northEast);
    }
    return _radius;
  }

  // ---------------------------------------------------------------------------
  Future<void> _send() async {
    if (_zone.text.trim().isEmpty || _title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zone name and title are required.')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _sending = true);
    try {
      final b = _bounds;
      await ResponderController().broadcastZoneAlert(
        zone: _zone.text.trim(),
        title: _title.text.trim(),
        message: _msg.text.trim(),
        district: _district,
        city: _city.text,
        severity: _severity,
        center: _point,
        radiusKm: _effectiveRadiusKm,
        areaName: _areaName,
        bbox: b == null
            ? null
            : [
                b.south,
                b.west,
                b.north,
                b.east,
              ],
      );
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Zone alert sent. Citizens in the target area see it now.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _sending = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Broadcast failed: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  // ---------------------------------------------------------------------------
  InputDecoration _deco(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: C4.muted, fontSize: 12),
        prefixIcon: icon == null ? null : Icon(icon, size: 18, color: C4.muted),
        filled: true,
        fillColor: C4.card,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C4.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C4.border),
        ),
      );

  Widget _mapStack() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _point,
            initialZoom: 12.5,
            onTap: (tapPos, p) => setState(() {
              _point = p;
              _polys = [];
              _bounds = null;
              _areaName = null;
              _results = [];
            }),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.flood_disaster',
            ),
            if (_polys.isNotEmpty)
              PolygonLayer(
                polygons: [
                  for (final p in _polys)
                    Polygon(
                      points: p.outer,
                      holePointsList: p.holes.isEmpty ? null : p.holes,
                      color: Colors.redAccent.withValues(alpha: 0.25),
                      borderColor: Colors.redAccent,
                      borderStrokeWidth: 3,
                    ),
                ],
              )
            else
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _point,
                    radius: _radius * 1000,
                    useRadiusInMeter: true,
                    color: Colors.redAccent.withValues(alpha: 0.25),
                    borderColor: Colors.redAccent,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _point,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on,
                      color: Colors.redAccent, size: 38),
                ),
              ],
            ),
          ],
        ),
        // search + results
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: C4.surface,
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _runSearch(),
                  style: const TextStyle(color: C4.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search district, city or town',
                    hintStyle: const TextStyle(color: C4.muted, fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.search, color: C4.muted, size: 20),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward,
                                color: C4.accent),
                            onPressed: _runSearch,
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_searchError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Material(
                    color: C4.surface,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(_searchError!,
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 12)),
                    ),
                  ),
                ),
              if (_results.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Material(
                    color: C4.surface,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 230),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: C4.border),
                        itemBuilder: (_, i) {
                          final h = _results[i];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              h.polys.isNotEmpty
                                  ? Icons.crop_square_rounded
                                  : Icons.place_outlined,
                              color: C4.accent,
                            ),
                            title: Text(h.name,
                                style: const TextStyle(
                                    color: C4.text,
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(h.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: C4.muted, fontSize: 11)),
                            onTap: () => _pick(h),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_areaName != null)
          Positioned(
            left: 10,
            bottom: 10,
            child: Material(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.crop_free, color: Colors.white, size: 15),
                    const SizedBox(width: 6),
                    Text(_areaName!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                      onPressed: _clearArea,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _form(double pad) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, 14, pad, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _polys.isNotEmpty
                      ? 'The selected area boundary will receive this warning.'
                      : 'Search an area, or tap the map and set a radius.',
                  style: const TextStyle(color: C4.muted, fontSize: 12),
                ),
                if (_polys.isEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.radar, size: 16, color: C4.muted),
                      const SizedBox(width: 6),
                      Text('Radius ${_radius.toStringAsFixed(1)} km',
                          style: const TextStyle(color: C4.text, fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _radius,
                          min: 0.5,
                          max: 15,
                          divisions: 29,
                          activeColor: Colors.redAccent,
                          onChanged: (v) => setState(() => _radius = v),
                        ),
                      ),
                    ],
                  ),
                ] else
                  const SizedBox(height: 12),
                TextField(
                  controller: _zone,
                  style: const TextStyle(color: C4.text, fontSize: 14),
                  decoration: _deco('Target zone name', icon: Icons.place_outlined),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _district,
                        isExpanded: true,
                        dropdownColor: C4.card,
                        style: const TextStyle(color: C4.text, fontSize: 14),
                        decoration: _deco('District'),
                        items: ['All', ..._districts]
                            .map((d) =>
                                DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _district = v ?? _district),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _city,
                        style: const TextStyle(color: C4.text, fontSize: 14),
                        decoration: _deco('City (or All)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('SEVERITY',
                    style: TextStyle(
                        color: C4.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final s in const ['Watch', 'Warning', 'Critical'])
                      ChoiceChip(
                        showCheckmark: false,
                        label: Text(s),
                        selected: _severity == s,
                        selectedColor: (s == 'Critical'
                                ? const Color(0xFFEF4444)
                                : s == 'Warning'
                                    ? const Color(0xFFF59E0B)
                                    : C4.blue)
                            .withValues(alpha: 0.3),
                        backgroundColor: C4.card,
                        labelStyle: TextStyle(
                            color: _severity == s ? C4.text : C4.muted,
                            fontWeight: FontWeight.w700),
                        onSelected: (_) => setState(() => _severity = s),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _title,
                  style: const TextStyle(color: C4.text, fontSize: 14),
                  decoration: _deco('Alert title', icon: Icons.title),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _msg,
                  maxLines: 3,
                  style: const TextStyle(color: C4.text, fontSize: 14),
                  decoration: _deco('Instruction for citizens'),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(pad, 10, pad, 10),
          decoration: const BoxDecoration(
            color: C4.surface,
            border: Border(top: BorderSide(color: C4.border)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626)),
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cell_tower),
                label: Text(_sending ? 'SENDING...' : 'TRANSMIT ALERT'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C4.bg,
      appBar: AppBar(
        backgroundColor: C4.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Broadcast zone alert',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: LayoutBuilder(
        builder: (context, cons) {
          final wide = cons.maxWidth >= 860;
          final pad = Responsive.pad(cons.maxWidth);
          if (wide) {
            return Row(
              children: [
                Expanded(child: _mapStack()),
                const VerticalDivider(width: 1, color: C4.border),
                SizedBox(width: 440, child: _form(pad)),
              ],
            );
          }
          final double mapH = (cons.maxHeight * 0.4)
              .clamp(150.0, math.max(150.0, cons.maxHeight - 260))
              .toDouble();
          return Column(
            children: [
              SizedBox(height: mapH, child: _mapStack()),
              Expanded(child: _form(pad)),
            ],
          );
        },
      ),
    );
  }
}

