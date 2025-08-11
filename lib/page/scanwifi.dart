import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'dart:math';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  List<WiFiAccessPoint> wifiList = [];
  bool isScanning = false;

  int currentPage = 0;
  static const int itemsPerPage = 8;

  // เก็บ AP ที่เคยเจอ (key: SSID, value: set ของ BSSID ที่เคยเจอ)
  final Map<String, Set<String>> _knownAccessPoints = {};

  int get totalPages => (wifiList.length / itemsPerPage).ceil();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.locationWhenInUse,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();
  }

  Future<void> scanWifi() async {
    setState(() {
      isScanning = true;
      currentPage = 0;
    });

    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan != CanStartScan.yes) {
      setState(() => isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถสแกน Wi-Fi ได้: $canScan')),
      );
      return;
    }

    await WiFiScan.instance.startScan();
    await Future.delayed(const Duration(seconds: 5));
    final results = await WiFiScan.instance.getScannedResults();

    // ตรวจจับ Rogue/Evil Twin
    _detectRogueEvilTwin(results);

    setState(() {
      wifiList = results;
      isScanning = false;
    });
  }

  void _detectRogueEvilTwin(List<WiFiAccessPoint> scannedAPs) {
    for (final ap in scannedAPs) {
      final knownBSSIDs = _knownAccessPoints[ap.ssid] ?? <String>{};

      // ถ้าเจอ SSID เดิมแต่ BSSID ใหม่ (แปลว่าอาจเป็น Rogue หรือ Evil Twin)
      if (knownBSSIDs.isNotEmpty && !knownBSSIDs.contains(ap.bssid)) {
        _showRogueAlert(ap);
      }

      // เพิ่ม BSSID นี้ในฐานข้อมูล
      knownBSSIDs.add(ap.bssid);
      _knownAccessPoints[ap.ssid] = knownBSSIDs;
    }
  }

  void _showRogueAlert(WiFiAccessPoint ap) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
          content: Text(
            'พบ Wi-Fi ที่น่าสงสัย: SSID "${ap.ssid}" กับ BSSID ใหม่ ${ap.bssid}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          action: SnackBarAction(
            label: 'ดูรายละเอียด',
            textColor: Colors.white,
            onPressed: () => _showWifiDetailsDialog(context, ap),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final paginatedList = wifiList
        .skip(currentPage * itemsPerPage)
        .take(itemsPerPage)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Wi-Fi Scanner')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: isScanning ? null : scanWifi,
              child: Text(isScanning ? 'กำลังสแกน...' : 'สแกน Wi-Fi'),
            ),
          ),
          Expanded(
            child: paginatedList.isEmpty
                ? const Center(child: Text('ยังไม่มีผลลัพธ์'))
                : ListView.builder(
                    itemCount: paginatedList.length,
                    itemBuilder: (context, index) {
                      final ap = paginatedList[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showWifiDetailsDialog(context, ap),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.wifi,
                                          color: Colors.green,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          ap.ssid.isNotEmpty
                                              ? ap.ssid
                                              : "<ไม่ทราบชื่อ>",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (_isSecure(ap.capabilities))
                                          const Icon(
                                            Icons.lock,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            _getSecurityColor(ap.capabilities),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getSecurityLabel(ap.capabilities),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'BSSID: ${ap.bssid}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _infoChip('${ap.level} dBm',
                                        _getSignalColor(ap.level)),
                                    _infoChip(
                                        '≈${_estimateDistance(ap.level)} m',
                                        Colors.blue),
                                    _infoChip('${ap.frequency} MHz',
                                        Colors.green),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (index) {
                  final isActive = index == currentPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isActive ? Colors.blue : Colors.grey[300],
                        foregroundColor:
                            isActive ? Colors.white : Colors.black,
                        minimumSize: const Size(40, 36),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        setState(() {
                          currentPage = index;
                        });
                      },
                      child: Text('${index + 1}'),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getSecurityColor(String capabilities) {
    if (capabilities.contains("WPA3")) return Colors.purple;
    if (capabilities.contains("WPA2")) return Colors.blue;
    if (capabilities.contains("WPA")) return Colors.orange;
    return Colors.grey;
  }

  String _getSecurityLabel(String capabilities) {
    if (capabilities.contains("WPA3")) return "WPA3";
    if (capabilities.contains("WPA2")) return "WPA2";
    if (capabilities.contains("WPA")) return "WPA";
    return "Open";
  }

  bool _isSecure(String capabilities) {
    return capabilities.contains("WPA") || capabilities.contains("WEP");
  }

  String _estimateDistance(int rssi) {
    double distance = pow(10.0, (-69 - rssi) / 20).toDouble();
    return distance.toStringAsFixed(1);
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -70) return Colors.amber;
    if (rssi >= -85) return Colors.red;
    return Colors.grey;
  }

  void _showWifiDetailsDialog(BuildContext context, WiFiAccessPoint ap) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          title: Row(
            children: [
              const Icon(Icons.wifi, color: Colors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ap.ssid.isNotEmpty ? ap.ssid : "<ไม่ทราบชื่อ>",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (_isSecure(ap.capabilities))
                const Icon(Icons.lock, size: 18, color: Colors.grey),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 24),
              _infoTile(Icons.router, 'BSSID', ap.bssid),
              _infoTile(Icons.network_cell, 'ความแรงสัญญาณ',
                  '${ap.level} dBm'),
              _infoTile(Icons.waves, 'ความถี่', '${ap.frequency} MHz'),
              _infoTile(Icons.shield, 'ความปลอดภัย',
                  _getSecurityLabel(ap.capabilities)),
              _infoTile(Icons.pin_drop, 'ระยะทางโดยประมาณ',
                  '≈${_estimateDistance(ap.level)} m'),
              const SizedBox(height: 12),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('ปิด'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(label),
      subtitle:
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      contentPadding: EdgeInsets.zero,
    );
  }
}
