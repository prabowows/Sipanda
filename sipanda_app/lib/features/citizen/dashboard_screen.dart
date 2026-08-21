import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:sipanda_app/core/theme.dart';
import 'package:sipanda_app/features/citizen/widgets/map_risk_layer.dart';
import 'package:sipanda_app/core/services/bmkg_service.dart';
import 'package:sipanda_app/core/database_service.dart';
import 'package:sipanda_app/models/district_data.dart';
import 'package:sipanda_app/core/utils/excel_export_service.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  final GlobalKey<RiskGisMapState> _mapKey = GlobalKey<RiskGisMapState>();
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  
  String _currentKecamatan = 'semarang tengah'; // Default selected district
  bool _isLoadingBmkg = true;
  bool _isSidebarVisible = true;

  @override
  void initState() {
    super.initState();
    _refreshBmkgData(isInitial: true);
  }

  Future<void> _loadHistoryForKecamatan(String name) async {
    if (name.isEmpty) return;
    final docId = name.toLowerCase().trim().replaceAll(' ', '_');
    try {
      final historyList = await _dbService.getDistrictHistory(docId);
      if (historyList.isNotEmpty) {
        BmkgService.updateHistoryFromFirestore(name, historyList);
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint("Error loading history for $docId: $e");
    }
  }

  Future<void> _preloadAllHistory() async {
    for (var key in BmkgService.kecamatanCodes.keys) {
      _loadHistoryForKecamatan(key);
    }
  }

  Future<void> _refreshBmkgData({bool isInitial = false}) async {
    if (!isInitial) {
      setState(() {
        _isLoadingBmkg = true;
      });
    }

    try {
      await BmkgService.fetchAllParallel();
    } catch (_) {}

    await _preloadAllHistory();

    if (mounted) {
      _mapKey.currentState?.refreshPolygons();
      setState(() {
        _isLoadingBmkg = false;
      });
      
      if (!isInitial) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data Telemetri & BMKG berhasil disegarkan.', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: SipandaTheme.primary,
            duration: Duration(seconds: 2),
          )
        );
      }
    }
  }

  void _onSearchSubmitted(String value) {
    if (value.isNotEmpty) {
      _mapKey.currentState?.searchAndMoveToKecamatan(value);
      final cleanVal = value.toLowerCase().trim();
      if (BmkgService.kecamatanCodes.containsKey(cleanVal)) {
        setState(() {
          _currentKecamatan = cleanVal;
        });
        _loadHistoryForKecamatan(cleanVal);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DistrictData>>(
      stream: _dbService.streamDistricts(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          BmkgService.updateFromFirestore(snapshot.data!);
          _isLoadingBmkg = false;
          _mapKey.currentState?.refreshPolygons();
          
          // Preload history for active district and background districts
          if (_currentKecamatan.isNotEmpty) {
            _loadHistoryForKecamatan(_currentKecamatan);
          }
        }

        return Scaffold(
          backgroundColor: SipandaTheme.background,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWeb = constraints.maxWidth >= 800;
              if (isWeb) {
                return _buildWebLayout(context);
              } else {
                return _buildMobileLayout(context);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildTopBar(bool isWeb) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          color: const Color(0xFF1E1E1E).withOpacity(0.8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSidebarVisible = !_isSidebarVisible;
                      });
                    },
                    child: const Icon(Icons.menu, color: SipandaTheme.primary),
                  ),
                  const SizedBox(width: 16),
                  const Text('SIPANDA', 
                    style: TextStyle(
                      color: SipandaTheme.primary,
                      fontSize: 20, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0
                    )
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: SipandaTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: const Text('LIVE TELEMETRY', style: TextStyle(color: SipandaTheme.primary, fontSize: 10, fontWeight: FontWeight.bold))
                  )
                ],
              ),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: SipandaTheme.statusAman, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        const Text('SYS ONLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  PopupMenuButton<String>(
                    offset: const Offset(0, 48),
                    color: SipandaTheme.surfaceHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white12)),
                    onSelected: (value) {
                      if (value == 'citizen') {
                        Navigator.pushReplacementNamed(context, '/');
                      } else if (value == 'admin') {
                        Navigator.pushNamed(context, '/admin');
                      } else if (value == 'history') {
                        Navigator.pushNamed(context, '/history');
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'citizen',
                        child: Row(
                          children: [
                            Icon(Icons.dashboard, color: SipandaTheme.primary, size: 18),
                            SizedBox(width: 12),
                            Text('Citizen Dashboard', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'history',
                        child: Row(
                          children: [
                            Icon(Icons.history, color: Colors.amberAccent, size: 18),
                            SizedBox(width: 12),
                            Text('Alert History', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      const PopupMenuItem<String>(
                        value: 'admin',
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: Colors.redAccent, size: 18),
                            SizedBox(width: 12),
                            Text('Admin Portal', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: SipandaTheme.surfaceHigh,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: SipandaTheme.primary.withOpacity(0.5),
                            child: const Icon(Icons.person, size: 16, color: Colors.white),
                          )
                        ],
                      )
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(true),
        Expanded(
          child: Row(
            children: [
              if (_isSidebarVisible) _buildSidebar(),
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    RiskGisMap(
                      key: _mapKey,
                      onKecamatanTapped: (kecName) {
                        final cleanVal = kecName.toLowerCase().trim();
                        setState(() {
                          _currentKecamatan = cleanVal;
                        });
                        _loadHistoryForKecamatan(cleanVal);
                      },
                    ),
                    Positioned(
                      top: 24, left: 24,
                      child: _buildSearchBar(),
                    ),
                    Positioned(
                      top: 24, right: 24,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: SipandaTheme.surfaceHigh,
                        onPressed: _isLoadingBmkg ? null : _refreshBmkgData,
                        child: _isLoadingBmkg 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: SipandaTheme.primary))
                          : const Icon(Icons.refresh, color: SipandaTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  color: const Color(0xFF1E1E1E),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildDashboardContent(),
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RiskGisMap(
            key: _mapKey,
            onKecamatanTapped: (kecName) {
              final cleanVal = kecName.toLowerCase().trim();
              setState(() {
                _currentKecamatan = cleanVal;
              });
              _loadHistoryForKecamatan(cleanVal);
            },
          ),
        ),
        
        Positioned(
          top: 80,
          left: 16,
          right: 72,
          child: _buildSearchBar(),
        ),
        
        Positioned(
          top: 80,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: SipandaTheme.surfaceHigh,
            onPressed: _isLoadingBmkg ? null : _refreshBmkgData,
            child: _isLoadingBmkg 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: SipandaTheme.primary))
              : const Icon(Icons.refresh, color: SipandaTheme.primary),
          ),
        ),

        Positioned(
          top: 140,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: SipandaTheme.statusAman.withOpacity(0.4), 
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: SipandaTheme.statusAman.withOpacity(0.5))
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: SipandaTheme.statusAman, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('AMAN', style: TextStyle(color: SipandaTheme.statusAman, fontWeight: FontWeight.bold, letterSpacing: 2))
                ],
              )
            )
          ),
        ),
        
        DraggableScrollableSheet(
          initialChildSize: 0.15,
          minChildSize: 0.15,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 32.0, sigmaY: 32.0),
                child: Container(
                  color: const Color(0xFF1E1E1E).withOpacity(0.85),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    children: [
                      Center(child: Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 24),
                      _buildDashboardContent(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        Positioned(
          top: 0, left: 0, right: 0,
          child: _buildTopBar(false)
        ),

        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _buildBottomNav()
        )
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 288,
      decoration: const BoxDecoration(
        color: SipandaTheme.background,
        border: Border(right: BorderSide(color: Colors.white12)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: SipandaTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.security, color: SipandaTheme.primary)
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SEMARANG COMMAND', style: TextStyle(color: SipandaTheme.primary, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                         Container(width: 8, height: 8, decoration: const BoxDecoration(color: SipandaTheme.statusAman, shape: BoxShape.circle)),
                         const SizedBox(width: 6),
                         const Text('Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
                      ],
                    )
                  ],
                )
              ],
            )
          ),
          const SizedBox(height: 32),
          _sidebarItem(Icons.dashboard, 'Dashboard', isActive: true, onTap: () {}),
          _sidebarItem(Icons.history, 'Alert History', onTap: () => Navigator.pushNamed(context, '/history')),
          _sidebarItem(Icons.admin_panel_settings, 'Admin Portal', onTap: () => Navigator.pushNamed(context, '/admin')),
          _sidebarItem(Icons.map, 'GIS Mapping'),
          _sidebarItem(Icons.analytics, 'District Reports'),
          _sidebarItem(Icons.terminal, 'System Logs'),
        ],
      )
    );
  }

  Widget _sidebarItem(IconData icon, String title, {bool isActive = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? SipandaTheme.primary.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8)
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? SipandaTheme.primary : Colors.grey),
        title: Text(title, style: TextStyle(color: isActive ? SipandaTheme.primary : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_isLoadingBmkg) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 100),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: SipandaTheme.primary),
            const SizedBox(height: 24),
            Text('MENYINKRONKAN DATA TELEMETRI...', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold))
          ],
        ),
      );
    }

    if (_currentKecamatan.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 100),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('PILIH WILAYAH PADA PETA', style: TextStyle(color: Colors.grey.shade400, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Klik salah satu marker lokasi untuk melihat data spesifik.', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center,)
          ],
        ),
      );
    }

    final activeForecasts = BmkgService.getForecast(_currentKecamatan);
    final historyForecasts = BmkgService.getHistoryForecast(_currentKecamatan);
    final currentForecast = (activeForecasts != null && activeForecasts.isNotEmpty) ? activeForecasts.first : null;
    
    final displayKecamatan = _currentKecamatan.toUpperCase();
    final currentTemp = currentForecast?.t.toStringAsFixed(1) ?? '--';
    final currentHu = currentForecast?.hu.toStringAsFixed(0) ?? '--';

    String hujanLbl = currentForecast?.rainLabel ?? 'N/A';
    Color hujanColor = currentForecast?.rainColor ?? Colors.grey;
    String suhuLbl  = currentForecast?.tempLabel ?? 'N/A';
    Color suhuColor  = currentForecast?.tempColor ?? Colors.grey;
    String huLbl    = currentForecast?.huLabel ?? 'N/A';
    Color huColor    = currentForecast?.huColor ?? Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayKecamatan, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Data Real-Time Terverifikasi', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openExportExcelModal(context, _currentKecamatan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF107C41),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.table_view_rounded, size: 16, color: Colors.white),
                  label: const Text('Export Excel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: SipandaTheme.surfaceHigh, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.thunderstorm, color: SipandaTheme.primary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chipInfo('Hujan', hujanLbl, hujanColor),
            _chipInfo('Suhu', suhuLbl, suhuColor),
            _chipInfo('Kelembapan', huLbl, huColor),
          ],
        ),
        const SizedBox(height: 24),
        
        Row(
          children: [
            Expanded(child: _metricCard(Icons.thermostat, 'Suhu', currentTemp, '°C')),
            const SizedBox(width: 16),
            Expanded(child: _metricCard(Icons.water_drop, 'Kelembapan', currentHu, '%')),
          ],
        ),
        const SizedBox(height: 24),

        _buildTrendChart(historyForecasts),

        const SizedBox(height: 24),

        _buildHistoricalDataTable(historyForecasts),

        const SizedBox(height: 24),

        _buildRecentTransmissions(currentForecast, displayKecamatan),
      ],
    );
  }

  Widget _chipInfo(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _metricCard(IconData icon, String title, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SipandaTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SipandaTheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300)),
              Text(unit, style: const TextStyle(color: SipandaTheme.primary, fontSize: 16)),
            ],
          )
        ],
      )
    );
  }

  Widget _buildTrendChart(List<WeatherData>? forecasts) {
    if (_isLoadingBmkg || forecasts == null || forecasts.isEmpty) {
       return Container(
         height: 250, width: double.infinity,
         decoration: BoxDecoration(color: SipandaTheme.surfaceHigh, borderRadius: BorderRadius.circular(12)),
         child: const Center(child: CircularProgressIndicator(color: SipandaTheme.primary))
       );
    }
    
    List<FlSpot> tpSpots = [];
    List<FlSpot> tSpots = [];
    List<FlSpot> huSpots = [];
    List<String> times = [];
    
    for (int i = 0; i < forecasts.length; i++) {
       final f = forecasts[i];
       tpSpots.add(FlSpot(i.toDouble(), f.tp));
       tSpots.add(FlSpot(i.toDouble(), f.t));
       huSpots.add(FlSpot(i.toDouble(), f.hu));
       
       try {
          final dt = DateTime.parse(f.datetime).toLocal();
          final hh = dt.hour.toString().padLeft(2, '0');
          final mm = dt.minute.toString().padLeft(2, '0');
          times.add('$hh:$mm');
       } catch (e) {
          times.add('T+$i');
       }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('RIWAYAT & TREN TIME-SERIES', style: TextStyle(color: SipandaTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: SipandaTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              child: Text('${forecasts.length} TITIK WAKTU', style: const TextStyle(color: SipandaTheme.primary, fontSize: 9, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 12),
        _buildSingleChart('CURAH HUJAN (mm)', tpSpots, Colors.blueAccent, times, 20.0),
        _buildSingleChart('SUHU (°C)', tSpots, Colors.redAccent, times, 40.0),
        _buildSingleChart('KELEMBAPAN (%)', huSpots, Colors.greenAccent, times, 100.0),
      ],
    );
  }

  Widget _buildHistoricalDataTable(List<WeatherData>? forecasts) {
    if (forecasts == null || forecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: SipandaTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: SipandaTheme.primary, size: 16),
                  SizedBox(width: 8),
                  Text('TABEL RIWAYAT HISTORIS (LOGS)',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _openExportExcelModal(context, _currentKecamatan),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF107C41).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF107C41)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_download, color: Color(0xFF81C784), size: 12),
                          SizedBox(width: 4),
                          Text('Unduh Excel', style: TextStyle(color: Color(0xFF81C784), fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: SipandaTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text('${forecasts.length} ENTRI LOG', style: const TextStyle(color: SipandaTheme.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              dividerThickness: 0.1,
              headingTextStyle: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.bold),
              columns: const [
                DataColumn(label: Text('WAKTU PENARIKAN')),
                DataColumn(label: Text('HUJAN (mm)')),
                DataColumn(label: Text('SUHU (°C)')),
                DataColumn(label: Text('KELEMBAPAN (%)')),
                DataColumn(label: Text('KONDISI CUACA')),
              ],
              rows: forecasts.map((f) {
                String timeFormatted;
                try {
                  final dt = DateTime.parse(f.datetime).toLocal();
                  final hh = dt.hour.toString().padLeft(2, '0');
                  final mm = dt.minute.toString().padLeft(2, '0');
                  final ss = dt.second.toString().padLeft(2, '0');
                  timeFormatted = '$hh:$mm:$ss WIB';
                } catch (_) {
                  timeFormatted = f.datetime;
                }

                Color rainColor = Colors.greenAccent;
                if (f.tp > 10) rainColor = Colors.redAccent;
                else if (f.tp >= 5) rainColor = Colors.orangeAccent;

                return DataRow(
                  cells: [
                    DataCell(Text(timeFormatted, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500))),
                    DataCell(Text('${f.tp.toStringAsFixed(1)} mm', style: TextStyle(fontSize: 11, color: rainColor, fontWeight: FontWeight.bold))),
                    DataCell(Text('${f.t.toStringAsFixed(1)} °C', style: const TextStyle(fontSize: 11, color: Colors.white))),
                    DataCell(Text('${f.hu.toStringAsFixed(0)} %', style: const TextStyle(fontSize: 11, color: Colors.blueAccent))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                      child: Text(f.weatherDesc, style: const TextStyle(fontSize: 10, color: Colors.white)),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleChart(String title, List<FlSpot> spots, Color color, List<String> times, double maxY) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SipandaTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.white12, strokeWidth: 1, dashArray: [4, 4]);
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < times.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8.0,
                            child: Text(times[index], style: const TextStyle(color: Colors.grey, fontSize: 10))
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxY / 4 > 0 ? maxY / 4 : 5,
                      getTitlesWidget: (value, meta) {
                        if (value < 0) return const SizedBox.shrink();
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(bottom: BorderSide(color: Colors.white24, width: 2)),
                ),
                minY: -0.1,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true, 
                    preventCurveOverShooting: true,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _buildRecentTransmissions(WeatherData? currentForecast, String displayKecamatan) {
    if (currentForecast == null) return const SizedBox();

    final weatherDesc = currentForecast.weatherDesc;
    final isRain = weatherDesc.toLowerCase().contains('hujan') || currentForecast.tp > 0;
    
    String textDesc;
    if (isRain) {
       textDesc = '$weatherDesc diprediksi untuk wilayah $displayKecamatan.';
    } else {
       textDesc = 'Kondisi cuaca terpantau $weatherDesc untuk wilayah $displayKecamatan.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TRANSMISI DATA TERKINI', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _transmissionItem(_getWeatherIcon(weatherDesc), 'Telemetry Update', textDesc, 'Just now')
      ],
    );
  }

  IconData _getWeatherIcon(String weatherDesc) {
    final desc = weatherDesc.toLowerCase();
    if (desc.contains('cerah berawan')) return Icons.wb_cloudy_outlined;
    if (desc.contains('cerah')) return Icons.wb_sunny;
    if (desc.contains('hujan petir')) return Icons.thunderstorm;
    if (desc.contains('hujan lebat')) return Icons.water_drop;
    if (desc.contains('hujan')) return Icons.grain;
    if (desc.contains('kabut')) return Icons.foggy;
    return Icons.cloud;
  }

  Widget _transmissionItem(IconData icon, String title, String desc, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SipandaTheme.surfaceHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: SipandaTheme.surface, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.grey)
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            )
          ),
          Text(time, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))
        ],
      )
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          width: 350,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: _searchController,
            onSubmitted: _onSearchSubmitted,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Cari kecamatan (contoh: Genuk, Tembalang)...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: SipandaTheme.primary, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward, color: SipandaTheme.primary, size: 18),
                onPressed: () => _onSearchSubmitted(_searchController.text),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: SipandaTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const Icon(Icons.dashboard, color: SipandaTheme.primary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.history, color: Colors.grey), onPressed: () => Navigator.pushNamed(context, '/history')),
          IconButton(icon: const Icon(Icons.admin_panel_settings, color: Colors.grey), onPressed: () => Navigator.pushNamed(context, '/admin')),
        ],
      ),
    );
  }

  Future<void> _openExportExcelModal(BuildContext context, String rawKecamatan) async {
    if (rawKecamatan.isEmpty) return;
    final displayKecamatan = rawKecamatan.toUpperCase();
    final docId = rawKecamatan.toLowerCase().trim().replaceAll(' ', '_');

    DateTimeRange selectedRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );

    bool isExporting = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final startFormatted = DateFormat('dd MMM yyyy').format(selectedRange.start);
            final endFormatted = DateFormat('dd MMM yyyy').format(selectedRange.end);
            final daysCount = selectedRange.duration.inDays + 1;

            return Dialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white24),
              ),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF107C41).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF107C41)),
                          ),
                          child: const Icon(Icons.table_view_rounded, color: Color(0xFF107C41), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Export Laporan Excel (.xlsx)',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text('Kecamatan $displayKecamatan',
                                  style: const TextStyle(fontSize: 12, color: SipandaTheme.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 16),

                    const Text('PILIH RENTANG TANGGAL',
                        style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // Preset buttons
                    Row(
                      children: [
                        _presetChip(
                          label: 'Hari Ini',
                          isSelected: selectedRange.duration.inDays == 0 &&
                              selectedRange.end.day == DateTime.now().day,
                          onTap: () {
                            setDialogState(() {
                              final now = DateTime.now();
                              selectedRange = DateTimeRange(start: now, end: now);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _presetChip(
                          label: '7 Hari',
                          isSelected: selectedRange.duration.inDays == 7,
                          onTap: () {
                            setDialogState(() {
                              final now = DateTime.now();
                              selectedRange = DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _presetChip(
                          label: '30 Hari',
                          isSelected: selectedRange.duration.inDays == 30,
                          onTap: () {
                            setDialogState(() {
                              final now = DateTime.now();
                              selectedRange = DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Interactive Date Range Card
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: selectedRange,
                          firstDate: DateTime(2024, 1, 1),
                          lastDate: DateTime.now().add(const Duration(days: 7)),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: SipandaTheme.primary,
                                  onPrimary: Colors.black,
                                  surface: Color(0xFF222222),
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: const Color(0xFF1E1E1E),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedRange = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: SipandaTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: SipandaTheme.primary.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.date_range, color: SipandaTheme.primary, size: 20),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$startFormatted - $endFormatted',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Text('Durasi: $daysCount Hari (Klik untuk ubah)',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                  ],
                                ),
                              ],
                            ),
                            const Icon(Icons.edit_calendar_outlined, color: SipandaTheme.primary, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey, size: 14),
                              SizedBox(width: 6),
                              Text('Informasi Laporan Spreadsheet',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('• Berisi log curah hujan, suhu, kelembapan, kondisi cuaca, dan tingkat risiko banjir.',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                          Text('• Dilengkapi ringkasan statistik dan akumulasi curah hujan otomatis.',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isExporting ? null : () => Navigator.of(ctx).pop(),
                          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: isExporting
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isExporting = true;
                                  });

                                  try {
                                    // 1. Fetch History from DB for this range with a 3s timeout
                                    List<DistrictHistoryData> historyLogs = [];
                                    try {
                                      historyLogs = await _dbService
                                          .getDistrictHistoryByDateRange(
                                            docId,
                                            startDate: selectedRange.start,
                                            endDate: selectedRange.end,
                                          )
                                          .timeout(const Duration(seconds: 3), onTimeout: () => []);
                                    } catch (err) {
                                      debugPrint("History range fetch fallback: $err");
                                    }

                                    // 2. Get forecast logs
                                    final forecastLogs = BmkgService.getHistoryForecast(rawKecamatan);

                                    // 3. Export to Excel
                                    final filePath = await ExcelExportService.exportDistrictWeatherToExcel(
                                      districtName: rawKecamatan,
                                      startDate: selectedRange.start,
                                      endDate: selectedRange.end,
                                      historyLogs: historyLogs,
                                      forecastLogs: forecastLogs,
                                    );

                                    if (mounted) {
                                      Navigator.of(ctx).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle, color: Colors.white),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Laporan Excel Kecamatan $displayKecamatan berhasil diunduh (${filePath ?? "SiPanda_Cuaca.xlsx"})!',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: const Color(0xFF107C41),
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  } catch (e, stack) {
                                    debugPrint("Error exporting excel: $e\n$stack");
                                    setDialogState(() {
                                      isExporting = false;
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Gagal mengekspor Excel: $e'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF107C41),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: isExporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.file_download, size: 18),
                          label: Text(
                            isExporting ? 'Memproses...' : 'Unduh Excel (.xlsx)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _presetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF107C41).withOpacity(0.25) : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF107C41) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF81C784) : Colors.white70,
          ),
        ),
      ),
    );
  }
}
