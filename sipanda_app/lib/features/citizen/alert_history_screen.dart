import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sipanda_app/core/theme.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SipandaTheme.surface,
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
      bottomNavigationBar: MediaQuery.of(context).size.width < 800 
          ? _buildBottomNav() 
          : null,
    );
  }

  // --- MOBILE LAYOUT ---
  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        // Main Content
        ListView(
          padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 120),
          children: [
            const Text('Alert History', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
            const SizedBox(height: 8),
            const Text('Reviewing critical Siaga status logs across Semarang districts.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            // Search Input
            Container(
              decoration: BoxDecoration(
                color: SipandaTheme.surfaceHigh,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: const Border(bottom: BorderSide(color: SipandaTheme.primary, width: 2))
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search by district...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16)
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Alert Cards
            _buildMobileAlertCard('Tembalang', 'ID: 9823-XA', 'Jan 14, 2024 • 03:45 AM', '245', '4h 12m'),
            _buildMobileAlertCard('Ngaliyan', 'ID: 8711-BC', 'Jan 12, 2024 • 11:20 PM', '212', '2h 45m'),
            _buildMobileAlertCard('Banyumanik', 'ID: 7654-JK', 'Jan 08, 2024 • 06:15 AM', '268', '8h 04m'),
            Opacity(opacity: 0.6, child: _buildMobileAlertCard('Tugu', 'ID: 6543-LM', 'Jan 02, 2024 • 09:00 PM', '230', '3h 30m')),

            const SizedBox(height: 32),

            // Stats
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 160,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: SipandaTheme.surfaceHigh.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('MONTHLY CRITICAL', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 2)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text('24', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w300)),
                            const SizedBox(width: 8),
                            const Text('+12%', style: TextStyle(color: SipandaTheme.statusAman, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  )
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 160,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: SipandaTheme.surfaceHigh.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12)
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.timer, color: SipandaTheme.primary),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('AVG DUR', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text('4.5', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                                const Text('h', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ),
              ],
            )
          ],
        ),

        // App Bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: _buildTopBar(false)
        ),
      ],
    );
  }

  Widget _buildMobileAlertCard(String district, String id, String time, String peak, String dur) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SipandaTheme.surfaceHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFFB71C1C), width: 4))
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF93000A).withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                child: const Text('CRITICAL', style: TextStyle(color: SipandaTheme.statusSiaga, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              const SizedBox(width: 8),
              Text(id, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(district, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PEAK LEVEL', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(peak, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: SipandaTheme.primary)),
                      const Text(' cm', style: TextStyle(fontSize: 12, color: SipandaTheme.primary)),
                    ],
                  )
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DURATION', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                  Text(dur, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: Colors.white)),
                ],
              ),
              const Icon(Icons.chevron_right, color: Colors.grey)
            ],
          )
        ],
      ),
    );
  }

  // --- WEB LAYOUT ---
  Widget _buildWebLayout(BuildContext context) {
    return Row(
      children: [
        _buildSidebar(),
        Expanded(
          child: Column(
            children: [
               _buildWebTopBar(),
               Expanded(
                 child: SingleChildScrollView(
                   padding: const EdgeInsets.all(40),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       _buildWebHeader(),
                       const SizedBox(height: 40),
                       _buildMetricsBento(),
                       const SizedBox(height: 40),
                       _buildDataTable(),
                       const SizedBox(height: 40),
                       _buildVisualContext()
                     ],
                   )
                 ),
               )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildWebHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HISTORICAL ANALYTICS', style: TextStyle(fontSize: 10, color: SipandaTheme.primary, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Alert History', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w300)),
          ],
        ),
        Row(
          children: [
            _filterDropdown('All Districts'),
            const SizedBox(width: 16),
            _filterBox(Icons.calendar_today, 'Oct 01 - Oct 31, 2023'),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: SipandaTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(8)
              ),
              child: const Row(
                children: [
                  Icon(Icons.tune, color: SipandaTheme.primary, size: 18),
                  SizedBox(width: 8),
                  Text('FILTER', style: TextStyle(color: SipandaTheme.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _filterDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: SipandaTheme.surfaceHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: Colors.grey))
      ),
      child: Row(
        children: [
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.white, letterSpacing: 1)),
          const SizedBox(width: 32),
          const Icon(Icons.expand_more, color: Colors.grey, size: 18)
        ],
      )
    );
  }

  Widget _filterBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: SipandaTheme.surfaceHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: Colors.grey))
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1)),
        ],
      )
    );
  }

  Widget _buildMetricsBento() {
    return Row(
      children: [
        Expanded(child: _bentoCard(Icons.warning, 'Month', '128', 'TOTAL SIAGA EVENTS', '+12% DECREASE', Icons.trending_down, SipandaTheme.statusAman)),
        const SizedBox(width: 24),
        Expanded(child: _bentoCard(Icons.timer, '', '4.2m', 'AVG. RESPONSE TIME', 'WITHIN TARGET RANGE', Icons.check_circle, SipandaTheme.statusAman)),
        const SizedBox(width: 24),
        Expanded(
          child: Container(
            height: 160, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: SipandaTheme.surfaceHigh.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: SipandaTheme.statusAman),
                const Spacer(),
                const Text('SEMARANG BARAT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300)),
                const Text('MOST ACTIVE DISTRICT', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 16),
                Container(
                  height: 4, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)),
                  child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.7, child: Container(decoration: BoxDecoration(color: SipandaTheme.statusAman, borderRadius: BorderRadius.circular(2)))),
                )
              ],
            ),
          )
        ),
      ],
    );
  }

  Widget _bentoCard(IconData icon, String tag, String val, String subtitle, String status, IconData statusIcon, Color statusColor) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SipandaTheme.surfaceHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: icon == Icons.warning ? Colors.redAccent : SipandaTheme.primary),
              if (tag.isNotEmpty)
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: SipandaTheme.surfaceHigh, borderRadius: BorderRadius.circular(4)), child: Text(tag.toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.grey, letterSpacing: 1)))
            ],
          ),
          const Spacer(),
          Text(val, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 12),
              const SizedBox(width: 4),
              Text(status, style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: SipandaTheme.surfaceHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12)
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Historical Siaga Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Text('SHOWING 1-12 OF 842', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(width: 16),
                    Icon(Icons.chevron_left, color: Colors.grey[600]),
                    Icon(Icons.chevron_right, color: Colors.grey[600]),
                  ],
                )
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              dividerThickness: 0.1,
              headingTextStyle: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.bold),
              columns: const [
                DataColumn(label: Text('DISTRICT')),
                DataColumn(label: Text('INCIDENT ID')),
                DataColumn(label: Text('DATE & TIME')),
                DataColumn(label: Text('PEAK LEVEL')),
                DataColumn(label: Text('DURATION')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: [
                _dataRow('Semarang Barat', '3.2045S, 114.59E', '#SIP-2023-942', '24 Oct 2023', '23:14:02', '482 cm', '04h 12m', 'Siaga III', SipandaTheme.statusSiaga),
                _dataRow('Tugu', '3.2001S, 114.58E', '#SIP-2023-938', '22 Oct 2023', '09:45:11', '512 cm', '11h 05m', 'Critical', Colors.red),
                _dataRow('Ngaliyan', '3.219S, 114.61E', '#SIP-2023-931', '18 Oct 2023', '14:22:56', '395 cm', '02h 45m', 'Warning', SipandaTheme.statusWaspada),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: TextButton.icon(
                onPressed: (){}, 
                icon: const Text('LOAD FULL ARCHIVES', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 2)), 
                label: const Icon(Icons.keyboard_double_arrow_down, color: Colors.grey, size: 16)
              )
            ),
          )
        ],
      )
    );
  }

  DataRow _dataRow(String dist, String coord, String id, String date, String time, String peak, String dur, String status, Color statusColor) {
    return DataRow(
      cells: [
        DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(dist, style: const TextStyle(fontWeight: FontWeight.bold)), Text(coord, style: const TextStyle(fontSize: 10, color: Colors.grey))])),
        DataCell(Text(id, style: const TextStyle(fontSize: 12, color: SipandaTheme.primary))),
        DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(date, style: const TextStyle(fontSize: 13)), Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey))])),
        DataCell(Row(children: [Text(peak, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), const SizedBox(width: 8), const Icon(Icons.show_chart, color: SipandaTheme.statusSiaga, size: 14)])),
        DataCell(Text(dur, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)))),
        DataCell(Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: SipandaTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.visibility, color: SipandaTheme.primary, size: 16))),
      ]
    );
  }

  Widget _buildVisualContext() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1519999482648-25049ddd37b1?q=80&w=2126'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken)),
              borderRadius: BorderRadius.circular(16)
            ),
            padding: const EdgeInsets.all(24),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SPATIAL CONTEXT', style: TextStyle(color: SipandaTheme.primary, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                Text('Region Activity Density', style: TextStyle(fontSize: 18)),
              ],
            ),
          )
        ),
        const SizedBox(width: 24),
        Expanded(
           child: Container(
             height: 250,
             padding: const EdgeInsets.all(32),
             decoration: BoxDecoration(color: SipandaTheme.surfaceHigh.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Row(
                   children: [
                     Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: SipandaTheme.statusAman.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.auto_graph, color: SipandaTheme.statusAman)),
                     const SizedBox(width: 16),
                     const Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('RESPONSE EFFICIENCY', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                         Text('Operational Health: Optimal', style: TextStyle(fontSize: 16)),
                       ],
                     )
                   ],
                 ),
                 const SizedBox(height: 16),
                 const Text('Historical data suggests a correlation between nighttime precipitation and accelerated rise in Semarang Barat. Early warning systems are currently configured for a 15% lower threshold during 22:00-04:00 hours.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5)
                 ),
                 const SizedBox(height: 16),
                 Row(
                   children: [
                     ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: SipandaTheme.surfaceHigh), child: const Text('VIEW DETAILS', style: TextStyle(fontSize: 10, color: Colors.white))),
                     const SizedBox(width: 12),
                     ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: SipandaTheme.primary.withOpacity(0.2)), child: const Text('RECALIBRATE SENSORS', style: TextStyle(fontSize: 10, color: SipandaTheme.primary))),
                   ],
                 )
               ],
             ),
           )
        )
      ],
    );
  }

  // --- COMMON WIDGETS ---
  // Reused from Dashboard screen
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
                children: [
                  const Icon(Icons.menu, color: SipandaTheme.primary),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/LogoSipanda.jpg',
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text('SIPANDA', style: TextStyle(color: SipandaTheme.primary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('SENTINEL ADMIN', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(width: 8),
                  CircleAvatar(radius: 12, backgroundColor: SipandaTheme.primary.withOpacity(0.5), child: const Icon(Icons.person, size: 16, color: Colors.white))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebTopBar() {
    return Container(
      height: 64, 
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12))
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/LogoSipanda.jpg',
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text('SIPANDA', style: TextStyle(color: SipandaTheme.primary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -1)),
            ),
          ),
          Row(
            children: [
               const Text('System Status: Active', style: TextStyle(fontSize: 10, color: SipandaTheme.statusAman, letterSpacing: 1)),
               const SizedBox(width: 24),
               const Icon(Icons.notifications, color: Colors.grey, size: 20),
               const SizedBox(width: 16),
               const Icon(Icons.settings, color: Colors.grey, size: 20),
               const SizedBox(width: 16),
               CircleAvatar(radius: 14, backgroundColor: SipandaTheme.primary.withOpacity(0.5), child: const Icon(Icons.person, size: 18, color: Colors.white))
            ],
          )
        ],
      )
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 288, 
      decoration: const BoxDecoration(
        color: SipandaTheme.background, 
        border: Border(right: BorderSide(color: Colors.white12))
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: SipandaTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.security, color: SipandaTheme.primary)),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SENTINEL LENS', style: TextStyle(color: SipandaTheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('STRATEGIC INTELLIGENCE', style: TextStyle(fontSize: 8, color: Colors.grey, letterSpacing: 1))
                  ],
                )
              ],
            )
          ),
          const SizedBox(height: 48),
          _sidebarItem(Icons.dashboard, 'Dashboard', onTap: () => Navigator.pop(context)),
          _sidebarItem(Icons.history, 'Alert History', isActive: true, onTap: () {}),
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
      decoration: BoxDecoration(color: isActive ? SipandaTheme.primary.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      child: ListTile(leading: Icon(icon, color: isActive ? SipandaTheme.primary : Colors.grey), title: Text(title, style: TextStyle(color: isActive ? SipandaTheme.primary : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)), onTap: onTap),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          height: 80, color: const Color(0xFF1E1E1E).withOpacity(0.9), padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(Icons.explore, 'Map', false, onTap: () => Navigator.pop(context)),
              _navItem(Icons.history, 'History', true, onTap: () {}),
              _navItem(Icons.insert_chart, 'Metrics', false),
              _navItem(Icons.admin_panel_settings, 'Admin', false),
            ],
          )
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? SipandaTheme.primary : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isActive ? SipandaTheme.primary : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}
