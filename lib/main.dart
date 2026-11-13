import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const IoTApp());

class IoTApp extends StatelessWidget {
  const IoTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Monitoring',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
      ),
      home: const DashboardPage(),
    );
  }
}

/// Model data sensor (dummy)
class Reading {
  final DateTime time;
  final double temp;
  final double hum;
  Reading(this.time, this.temp, this.hum);
}

String fmtHm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
String fmtHms(DateTime t) => '${fmtHm(t)}:${t.second.toString().padLeft(2, '0')}';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Data dummy konfigurasi MQTT (nanti dipakai di tugas berikutnya)
  static const String broker = 'broker.hivemq.com';
  static const String topic = 'kampus/iot/kelas1/sensor';

  final _rand = Random();
  late List<Reading> readings;
  bool connected = true;
  bool expanded = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    readings = [
      Reading(now.subtract(const Duration(minutes: 15)), 28.0, 72),
      Reading(now.subtract(const Duration(minutes: 10)), 29.0, 73),
      Reading(now.subtract(const Duration(minutes: 5)), 28.5, 74),
      Reading(now, 30.5, 75),
    ];
    // Simulasi data masuk setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _simulate());
  }

  void _simulate() {
    if (!connected) return;
    final last = readings.last;
    final t = (last.temp + (_rand.nextDouble() * 3 - 1.5)).clamp(24.0, 38.0);
    final h = (last.hum + (_rand.nextDouble() * 4 - 2)).clamp(40.0, 95.0);
    setState(() {
      readings.add(Reading(DateTime.now(), double.parse(t.toStringAsFixed(1)),
          h.roundToDouble()));
      if (readings.length > 8) readings.removeAt(0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = readings.last;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _sensorCard(
                      icon: Icons.thermostat,
                      label: 'Temperature',
                      value: connected ? '${last.temp.toStringAsFixed(1)}°C' : '--',
                      source: 'Sensor DHT11',
                      bg: const Color(0xFFE3F2FD),
                      fg: const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sensorCard(
                      icon: Icons.water_drop_outlined,
                      label: 'Humidity',
                      value: connected ? '${last.hum.toStringAsFixed(0)}%' : '--',
                      source: 'Sensor DHT11',
                      bg: const Color(0xFFE8F5E9),
                      fg: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _mqttCard(last),
              const SizedBox(height: 12),
              _historyCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Header + status koneksi ----------
  Widget _header() {
    return _box(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IoT Monitoring',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text('Dashboard Monitoring Sensor',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          // Tap chip untuk simulasi Connected / Disconnected
          GestureDetector(
            onTap: () => setState(() => connected = !connected),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: connected ? const Color(0xFFDFF5E3) : const Color(0xFFFDE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                connected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: connected ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Kartu sensor ----------
  Widget _sensorCard({
    required IconData icon,
    required String label,
    required String value,
    required String source,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 12, color: fg)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: fg)),
          ),
          const SizedBox(height: 4),
          Text(source, style: TextStyle(fontSize: 10, color: fg)),
        ],
      ),
    );
  }

  // ---------- Info koneksi MQTT ----------
  Widget _mqttCard(Reading last) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MQTT Connection',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          _infoRow('Broker', broker),
          _infoRow('Topic', topic),
          _infoRow('Last Update', fmtHms(last.time)),
        ],
      ),
    );
  }

  Widget _infoRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Flexible(
              child: Text(v,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  // ---------- Grafik + tabel riwayat ----------
  Widget _historyCard() {
    final shown = expanded ? readings : readings.sublist(max(0, readings.length - 4));
    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monitoring History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Temperature (°C)',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEDED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Dummy Data', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Contoh data simulasi untuk desain dashboard.'),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => expanded = !expanded),
              child: Text(expanded ? 'Collapse chart' : 'Expand chart',
                  style: const TextStyle(fontSize: 12)),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: expanded ? 260 : 160,
            width: double.infinity,
            child: CustomPaint(painter: LineChartPainter(shown.map((e) => e.temp).toList())),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: SizedBox()),
              Expanded(
                child: Text('Temperature',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
          const Divider(),
          for (final r in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(fmtHm(r.time),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Text('${r.temp}°C')),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _box({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: child,
      );
}

/// Grafik garis sederhana (tanpa package tambahan)
class LineChartPainter extends CustomPainter {
  final List<double> data;
  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    const pad = 16.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    final axis = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(pad, pad), Offset(pad, size.height - pad), axis);
    canvas.drawLine(Offset(pad, size.height - pad),
        Offset(size.width - pad, size.height - pad), axis);

    final minV = data.reduce(min) - 1;
    final maxV = data.reduce(max) + 1;
    final points = <Offset>[
      for (var i = 0; i < data.length; i++)
        Offset(
          pad + w * i / (data.length - 1),
          pad + h * (1 - (data[i] - minV) / (maxV - minV)),
        ),
    ];

    final line = Paint()
      ..color = const Color(0xFF1E88FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);

    final dot = Paint()..color = const Color(0xFF1E88FF);
    for (final p in points) {
      canvas.drawCircle(p, 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter old) => old.data != data;
}
