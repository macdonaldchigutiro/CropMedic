import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'brand.dart';
import 'theme.dart';

class WeatherScreen extends StatefulWidget {
  final String lang;
  const WeatherScreen({super.key, required this.lang});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  ProvinceWeatherLocation _location = provinceLocations.first;
  WeatherSnapshot? _weather;
  String? _error;
  bool _loading = false;

  String _ui(String en, String sn, String nd, String toi) {
    switch (widget.lang) {
      case 'sn': return sn;
      case 'nd': return nd;
      case 'toi': return toi;
      default: return en;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${_location.lat}',
        'longitude': '${_location.lon}',
        'current': 'temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m',
        'daily': 'temperature_2m_max,temperature_2m_min,precipitation_probability_max',
        'forecast_days': '3',
        'timezone': 'Africa/Harare',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) throw Exception('Weather service returned ${response.statusCode}.');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>;
      final maxT = (daily['temperature_2m_max'] as List).cast<num>();
      final minT = (daily['temperature_2m_min'] as List).cast<num>();
      final rain = (daily['precipitation_probability_max'] as List).cast<num>();
      setState(() {
        _weather = WeatherSnapshot(
          temp: (current['temperature_2m'] as num).toDouble(),
          humidity: (current['relative_humidity_2m'] as num).toDouble(),
          precipitation: (current['precipitation'] as num).toDouble(),
          wind: (current['wind_speed_10m'] as num).toDouble(),
          maxTemps: maxT.map((e) => e.toDouble()).toList(),
          minTemps: minT.map((e) => e.toDouble()).toList(),
          rainChance: rain.map((e) => e.toDouble()).toList(),
        );
      });
    } catch (_) {
      setState(() => _error = _ui(
            'Live weather is unavailable right now. You can still use the seasonal guidance below.',
            'Mamiriro ekunze aripo haasi kuwanikwa izvozvi. Shandisa mazano emwaka ari pasi.',
            'Isimo sezulu esiphilayo asitholakali khathesi. Sebenzisa iseluleko sesikhathi somnyaka esingezansi.',
            'Mvula yamazuba ano tayijaniki lino. Belensya malayilile aamwaka ali ansi.',
          ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Expanded(child: CropMedicBrand(compact: true, showTagline: false)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _ui('Weather & crop risk', 'Mamiriro ekunze nenjodzi yezvirimwa', 'Isimo sezulu lengozi yezilimo', 'Mvula anjodzi yamilimo'),
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Palette.primaryDark,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ui(
                      'Weather that explains what it could mean for your crop — not just numbers.',
                      'Mamiriro ekunze anotsanangura zvazvinoreva pachirimwa chako, kwete manhamba chete.',
                      'Isimo sezulu esichaza ukuthi singathini esilimweni sakho, hatshi amanani kuphela.',
                      'Mvula iitondezya nzyoyamba kumilimo yako, kutali manamba alikke.',
                    ),
                    style: const TextStyle(color: Palette.textDim, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<ProvinceWeatherLocation>(
                    value: _location,
                    decoration: InputDecoration(
                      labelText: _ui('Province / nearest centre', 'Dunhu / nzvimbo iri pedyo', 'Isabelo / indawo eseduze', 'Cisi / busena bwafwi'),
                      filled: true,
                      fillColor: Palette.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    items: provinceLocations
                        .map((p) => DropdownMenuItem(value: p, child: Text('${p.province} · ${p.centre}')))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _location = value);
                      _load();
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(34),
                      child: Center(child: CircularProgressIndicator(color: Palette.primary)),
                    )
                  else if (_weather != null)
                    _weatherCard(_weather!)
                  else if (_error != null)
                    AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.cloud_off_rounded, color: Palette.alert),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_error!, style: const TextStyle(height: 1.4))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _ui('Farmer alerts', 'Yambiro kumurimi', 'Izixwayiso zomlimi', 'Lulayo lwamulimi'),
                    style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, fontWeight: FontWeight.w800, color: Palette.primaryDark),
                  ),
                  const SizedBox(height: 10),
                  ..._riskCards(),
                  const SizedBox(height: 8),
                  AppCard(
                    color: const Color(0xFFF2F6EE),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _ui('General seasonal guidance', 'Mazano emwaka', 'Iseluleko sesikhathi somnyaka', 'Malayilile aamwaka'),
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Palette.primaryDark),
                        ),
                        const SizedBox(height: 10),
                        _bullet('After several wet days, inspect lower leaves for fungal spots and blight.'),
                        _bullet('Avoid spraying when rain is imminent or wind is strong.'),
                        _bullet('During very hot periods, watch young crops for wilting and moisture stress.'),
                        _bullet('Weather risk is an early warning, not a disease diagnosis.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _weatherCard(WeatherSnapshot w) {
    final dayCount = w.maxTemps.length < 3 ? w.maxTemps.length : 3;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, color: Palette.gold, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_location.centre, style: const TextStyle(fontSize: 13, color: Palette.textDim)),
                    Text('${w.temp.round()}°C', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Palette.primaryDark)),
                  ],
                ),
              ),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
            ],
          ),
          const Divider(color: Palette.border),
          Row(
            children: [
              Expanded(child: _metric(Icons.water_drop_outlined, '${w.humidity.round()}%', 'Humidity')),
              Expanded(child: _metric(Icons.grain_rounded, '${w.precipitation.toStringAsFixed(1)} mm', 'Rain now')),
              Expanded(child: _metric(Icons.air_rounded, '${w.wind.round()} km/h', 'Wind')),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Next 3 days', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(dayCount, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == dayCount - 1 ? 0 : 7),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: Palette.primarySoft, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      Text(i == 0 ? 'Today' : 'Day ${i + 1}', style: const TextStyle(fontSize: 11, color: Palette.textDim)),
                      const SizedBox(height: 3),
                      Text('${w.maxTemps[i].round()}° / ${w.minTemps[i].round()}°', style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${w.rainChance[i].round()}% rain', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  List<Widget> _riskCards() {
    final w = _weather;
    if (w == null) {
      return [
        _risk(Icons.eco_rounded, 'Scout after rain', 'Wet leaves for long periods can increase fungal disease risk.', Palette.primary),
        _risk(Icons.air_rounded, 'Watch spraying conditions', 'Strong wind can cause spray drift and poor coverage.', Palette.gold),
      ];
    }
    final result = <Widget>[];
    if (w.humidity >= 80 || w.rainChance.first >= 60) {
      result.add(_risk(Icons.coronavirus_outlined, 'Higher fungal-disease risk', 'High humidity or rain is expected. Inspect leaves closely for spots and blight.', Palette.alert));
    } else {
      result.add(_risk(Icons.shield_outlined, 'Lower fungal pressure right now', 'Conditions are less favourable for many leaf fungi, but keep scouting.', Palette.primary));
    }
    if (w.wind >= 20) {
      result.add(_risk(Icons.air_rounded, 'Avoid spraying in strong wind', 'Wind is high enough to increase drift and reduce coverage.', Palette.gold));
    }
    if (w.temp >= 32) {
      result.add(_risk(Icons.thermostat_rounded, 'Heat-stress watch', 'Hot conditions can stress young or poorly watered crops.', Palette.alert));
    }
    if (w.rainChance.first >= 60) {
      result.add(_risk(Icons.umbrella_rounded, 'Rain likely', 'Delay non-urgent spraying if rainfall could wash product off soon after application.', Palette.primary));
    }
    return result;
  }

  Widget _risk(IconData icon, String title, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(text, style: const TextStyle(height: 1.35, color: Palette.textDim)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Palette.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Palette.textDim)),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: CircleAvatar(radius: 3, backgroundColor: Palette.primary),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}

class ProvinceWeatherLocation {
  final String province;
  final String centre;
  final double lat;
  final double lon;
  const ProvinceWeatherLocation(this.province, this.centre, this.lat, this.lon);
}

const provinceLocations = <ProvinceWeatherLocation>[
  ProvinceWeatherLocation('Harare', 'Harare', -17.8292, 31.0522),
  ProvinceWeatherLocation('Bulawayo', 'Bulawayo', -20.1500, 28.5833),
  ProvinceWeatherLocation('Manicaland', 'Mutare', -18.9707, 32.6709),
  ProvinceWeatherLocation('Mashonaland Central', 'Bindura', -17.3019, 31.3306),
  ProvinceWeatherLocation('Mashonaland East', 'Marondera', -18.1853, 31.5519),
  ProvinceWeatherLocation('Mashonaland West', 'Chinhoyi', -17.3667, 30.2000),
  ProvinceWeatherLocation('Masvingo', 'Masvingo', -20.0637, 30.8277),
  ProvinceWeatherLocation('Matabeleland North', 'Lupane', -18.9315, 27.8060),
  ProvinceWeatherLocation('Matabeleland South', 'Gwanda', -20.9362, 29.0069),
  ProvinceWeatherLocation('Midlands', 'Gweru', -19.4500, 29.8167),
];

class WeatherSnapshot {
  final double temp;
  final double humidity;
  final double precipitation;
  final double wind;
  final List<double> maxTemps;
  final List<double> minTemps;
  final List<double> rainChance;

  const WeatherSnapshot({
    required this.temp,
    required this.humidity,
    required this.precipitation,
    required this.wind,
    required this.maxTemps,
    required this.minTemps,
    required this.rainChance,
  });
}
