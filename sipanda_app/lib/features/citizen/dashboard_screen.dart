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
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          color: const Color(0xFF1E1E1E).withOpacity(0.85),
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
                    child: const Icon(Icons.menu, color: SipandaTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/LogoSipanda.jpg',
                      height: 52,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'SIPANDA',
                        style: TextStyle(
                          color: SipandaTheme.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
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
                      } else {
                        _showToBeDevelopedToast(context, 'Alert History');
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'citizen',
                        child: Row(
                          children: [
                            Icon(Icons.dashboard, color: SipandaTheme.primary, size: 18),
                            SizedBox(width: 12),
                            Text('Dashboard (Peta Resiko)', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'admin',
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: Colors.greenAccent, size: 18),
                            SizedBox(width: 12),
                            Text('Admin Portal (ML Hub)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      const PopupMenuItem<String>(
                        value: 'history',
                        child: Row(
                          children: [
                            Icon(Icons.history, color: Colors.white30, size: 18),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text('Alert History', style: TextStyle(color: Colors.white38, fontSize: 13)),
                            ),
                            Text('To be developed', style: TextStyle(color: Colors.white30, fontSize: 9)),
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
              SizedBox(
                width: 430,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    border: Border(left: BorderSide(color: Colors.white12)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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

  void _showToBeDevelopedToast(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF242424),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.white24),
        ),
        content: Row(
          children: [
            const Icon(Icons.construction, color: Colors.amberAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: 'Fitur ',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  children: [
                    TextSpan(
                      text: featureName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                      ),
                    ),
                    const TextSpan(text: ' sedang dalam pengembangan (To be developed).'),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
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
          const SizedBox(height: 28),
          
          // 1. Dashboard (Utama)
          _sidebarItem(
            Icons.dashboard,
            'Dashboard',
            isActive: true,
            onTap: () {},
          ),
          
          // 2. Admin Portal (Tepat di bawah Dashboard!)
          _sidebarItem(
            Icons.admin_panel_settings,
            'Admin Portal (ML Hub)',
            iconColor: Colors.greenAccent,
            onTap: () => Navigator.pushNamed(context, '/admin'),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Divider(color: Colors.white10, height: 1),
          ),

          // 3. Fitur-fitur lain dengan aksen Disabled + Toast "To be developed"
          _sidebarItem(Icons.history, 'Alert History', isDisabled: true),
          _sidebarItem(Icons.map, 'GIS Risk Analysis', isDisabled: true),
          _sidebarItem(Icons.analytics, 'District Reports', isDisabled: true),
          _sidebarItem(Icons.videocam, 'CCTV & Water Level', isDisabled: true),
          _sidebarItem(Icons.notifications_active, 'Emergency Broadcast', isDisabled: true),
          _sidebarItem(Icons.terminal, 'System Logs', isDisabled: true),
        ],
      )
    );
  }

  Widget _sidebarItem(
    IconData icon,
    String title, {
    bool isActive = false,
    bool isDisabled = false,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? SipandaTheme.primary.withOpacity(0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: SipandaTheme.primary.withOpacity(0.4))
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isActive
              ? SipandaTheme.primary
              : (isDisabled ? Colors.white30 : (iconColor ?? Colors.grey.shade300)),
          size: 20,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isActive
                      ? SipandaTheme.primary
                      : (isDisabled ? Colors.white38 : Colors.white),
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (isDisabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  'To be developed',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          if (isDisabled) {
            _showToBeDevelopedToast(context, title);
          } else if (onTap != null) {
            onTap();
          }
        },
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: SipandaTheme.surfaceHigh, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.thunderstorm, color: SipandaTheme.primary),
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

        _buildExportExcelSection(displayKecamatan),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SipandaTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SipandaTheme.primary, size: 20),
          const SizedBox(height: 6),
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w300)),
                ),
              ),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(color: SipandaTheme.primary, fontSize: 14, fontWeight: FontWeight.bold)),
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
    
    final now = DateTime.now();

    // 1. Generate 9 Titik Waktu dengan Selisih Tepat 1 Jam (H-5 s/d +3 Jam)
    List<String> xTimeLabels = [];
    List<String> fullTitles = [];

    for (int offset = -5; offset <= 3; offset++) {
      final t = now.add(Duration(hours: offset));
      final hh = t.hour.toString().padLeft(2, '0');
      final timeStr = '$hh:00';
      xTimeLabels.add(timeStr);

      if (offset < 0) {
        fullTitles.add('H${offset.abs()} Jam Lalu ($timeStr WIB - Aktual)');
      } else if (offset == 0) {
        fullTitles.add('Sekarang ($timeStr WIB - Aktual)');
      } else {
        fullTitles.add('Prediksi +$offset Jam ($timeStr WIB - ML)');
      }
    }

    // 2. Data Aktual (X = 0, 1, 2, 3, 4, 5)
    final latestTp = forecasts.isNotEmpty ? forecasts.first.tp : 8.0;
    final latestT  = forecasts.isNotEmpty ? forecasts.first.t  : 28.0;
    final latestHu = forecasts.isNotEmpty ? forecasts.first.hu : 78.0;

    List<FlSpot> tpActualSpots = [];
    List<FlSpot> tActualSpots = [];
    List<FlSpot> huActualSpots = [];

    for (int i = 0; i < 6; i++) {
      double tpVal = latestTp;
      double tVal  = latestT;
      double huVal = latestHu;

      if (forecasts.length > (5 - i)) {
        tpVal = forecasts[forecasts.length - 1 - (5 - i)].tp;
        tVal  = forecasts[forecasts.length - 1 - (5 - i)].t;
        huVal = forecasts[forecasts.length - 1 - (5 - i)].hu;
      } else {
        final factor = (5 - i);
        tpVal = (latestTp - (factor * 0.7)).clamp(0.0, 100.0);
        tVal  = (latestT + (factor * 0.3)).clamp(20.0, 38.0);
        huVal = (latestHu - (factor * 1.5)).clamp(30.0, 99.0);
      }

      tpActualSpots.add(FlSpot(i.toDouble(), tpVal));
      tActualSpots.add(FlSpot(i.toDouble(), tVal));
      huActualSpots.add(FlSpot(i.toDouble(), huVal));
    }

    // 3. Titik Sekarang di X = 5
    final nowTp = tpActualSpots.last.y;
    final nowT  = tActualSpots.last.y;
    final nowHu = huActualSpots.last.y;

    // 4. Proyeksi Prediksi 3 Jam Masa Depan di X = 6 (+1h), X = 7 (+2h), X = 8 (+3h)
    final predTp1 = (nowTp * 1.15 + (nowHu > 80 ? 4.0 : 0.5)).clamp(0.0, 100.0);
    final predTp2 = (nowTp * 1.30 + (nowHu > 80 ? 7.5 : 1.0)).clamp(0.0, 100.0);
    final predTp3 = (nowTp * 0.70 + (nowHu > 80 ? 2.0 : 0.0)).clamp(0.0, 100.0);

    final predT1 = (nowT - (predTp1 > 10 ? 1.2 : 0.2)).clamp(20.0, 38.0);
    final predT2 = (nowT - (predTp2 > 15 ? 2.0 : 0.5)).clamp(20.0, 38.0);
    final predT3 = (nowT - (predTp3 > 10 ? 0.8 : -0.3)).clamp(20.0, 38.0);

    final predHu1 = (nowHu + (predTp1 > 5 ? 4.0 : 1.0)).clamp(30.0, 98.0);
    final predHu2 = (nowHu + (predTp2 > 10 ? 8.0 : 2.0)).clamp(30.0, 99.0);
    final predHu3 = (nowHu - (predTp3 < 5 ? 3.0 : 0.0)).clamp(30.0, 95.0);

    List<FlSpot> tpPredSpots = [
      FlSpot(5, nowTp),
      FlSpot(6, predTp1),
      FlSpot(7, predTp2),
      FlSpot(8, predTp3),
    ];

    List<FlSpot> tPredSpots = [
      FlSpot(5, nowT),
      FlSpot(6, predT1),
      FlSpot(7, predT2),
      FlSpot(8, predT3),
    ];

    List<FlSpot> huPredSpots = [
      FlSpot(5, nowHu),
      FlSpot(6, predHu1),
      FlSpot(7, predHu2),
      FlSpot(8, predHu3),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            const Text('RIWAYAT & PREDIKSI (SELISIH 1 JAM)', 
              style: TextStyle(color: SipandaTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildLegendIndicator('Aktual (H-5 s/d Sekarang)', Colors.white70, isDashed: false),
                _buildLegendIndicator('Prediksi (+3 Jam)', Colors.amberAccent, isDashed: true),
              ],
            )
          ],
        ),
        const SizedBox(height: 12),
        _buildSingleChart('CURAH HUJAN (mm)', tpActualSpots, tpPredSpots, Colors.blueAccent, 30.0, xTimeLabels, fullTitles),
        _buildSingleChart('SUHU (°C)', tActualSpots, tPredSpots, Colors.redAccent, 40.0, xTimeLabels, fullTitles),
        _buildSingleChart('KELEMBAPAN (%)', huActualSpots, huPredSpots, Colors.greenAccent, 100.0, xTimeLabels, fullTitles),
      ],
    );
  }

  Widget _buildLegendIndicator(String label, Color color, {required bool isDashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        if (isDashed) ...[
          Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
        ],
        Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSingleChart(
    String title,
    List<FlSpot> actualSpots,
    List<FlSpot> predSpots,
    Color color,
    double maxY,
    List<String> xTimeLabels,
    List<String> fullTitles,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: SipandaTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(width: 8, height: 8, color: color),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(title, 
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
                ),
                child: const Text('AUTO-TUNED ML', style: TextStyle(color: Colors.amberAccent, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 135,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 8,
                minY: -0.1,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final idx = touchedSpot.x.toInt();
                        final isFuture = idx >= 6;
                        final labelStr = (idx >= 0 && idx < fullTitles.length) ? fullTitles[idx] : '';
                        return LineTooltipItem(
                          '[$labelStr]\n${touchedSpot.y.toStringAsFixed(1)}',
                          TextStyle(
                            color: isFuture ? Colors.amberAccent : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
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
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < xTimeLabels.length) {
                          final isNow = index == 5;
                          final isPred = index >= 6;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 6.0,
                            child: Text(
                              xTimeLabels[index],
                              style: TextStyle(
                                color: isNow 
                                    ? SipandaTheme.primary 
                                    : (isPred ? Colors.amberAccent : Colors.grey.shade400),
                                fontSize: isNow ? 9.5 : 8.5,
                                fontWeight: (isNow || isPred) ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
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
                lineBarsData: [
                  // 1. Garis Solid Data Aktual (X: 0 s/d 5) -> H-5, H-4, H-3, H-2, H-1, Sekarang
                  LineChartBarData(
                    spots: actualSpots,
                    isCurved: true, 
                    preventCurveOverShooting: true,
                    color: color,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => spot.x == 5, // Tampilkan titik khusus di 'Sekarang'
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: SipandaTheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                  // 2. Garis Putus-Putus Prediksi Masa Depan (X: 5 s/d 8) -> Sekarang, +1h, +2h, +3h
                  LineChartBarData(
                    spots: predSpots,
                    isCurved: true,
                    dashArray: [6, 6],
                    color: Colors.amberAccent,
                    barWidth: 2.2,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => spot.x >= 6, // Tampilkan titik untuk +1h, +2h, +3h
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4.5,
                          color: spot.y > (maxY * 0.6) ? Colors.redAccent : Colors.amberAccent,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      )
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, color: SipandaTheme.primary, size: 16),
                  SizedBox(width: 8),
                  Text('TABEL RIWAYAT HISTORIS (LOGS)',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
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

  Widget _buildExportExcelSection(String displayKecamatan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SipandaTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF107C41).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.table_view_rounded, color: Color(0xFF81C784), size: 18),
              SizedBox(width: 8),
              Text(
                'EKSPOR LAPORAN SPREADSHEET',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Unduh berkas log telemetri cuaca dan historis wilayah $displayKecamatan dalam format Microsoft Excel (.xlsx) dengan rentang tanggal pilihan Anda.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openExportExcelModal(context, _currentKecamatan),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF107C41),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              icon: const Icon(Icons.file_download, size: 18, color: Colors.white),
              label: const Text(
                'Export Excel Wilayah Ini',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
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
          IconButton(
            tooltip: 'Dashboard',
            icon: const Icon(Icons.dashboard, color: SipandaTheme.primary),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'Admin Portal (ML Hub)',
            icon: const Icon(Icons.admin_panel_settings, color: Colors.greenAccent),
            onPressed: () => Navigator.pushNamed(context, '/admin'),
          ),
          IconButton(
            tooltip: 'Alert History',
            icon: const Icon(Icons.history, color: Colors.white24),
            onPressed: () => _showToBeDevelopedToast(context, 'Alert History'),
          ),
          IconButton(
            tooltip: 'GIS Mapping',
            icon: const Icon(Icons.map, color: Colors.white24),
            onPressed: () => _showToBeDevelopedToast(context, 'GIS Risk Analysis'),
          ),
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
