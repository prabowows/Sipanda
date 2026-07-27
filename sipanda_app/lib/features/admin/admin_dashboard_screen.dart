import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sipanda_app/core/theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Stepper state (0 = Upload, 1 = Training, 2 = Deploy)
  int _activeStep = 0;
  
  // Model config state
  String _selectedAlgorithm = 'LSTM';
  double _forecastHorizon = 24;
  double _trainSplit = 80;
  
  // File upload state
  String? _uploadedFileName;
  bool _isUploading = false;
  
  // Training simulation state
  bool _isTraining = false;
  double _trainingProgress = 0.0;
  
  // Sidebar visibility
  bool _isSidebarVisible = true;
  
  // Mock dataset
  final List<Map<String, dynamic>> _dataset = [
    {'time': '2023-11-20 00:00', 'temp': 24.5, 'hum': 88.2, 'rain': 0.0},
    {'time': '2023-11-20 01:00', 'temp': 24.2, 'hum': 89.1, 'rain': 0.0},
    {'time': '2023-11-20 02:00', 'temp': 24.0, 'hum': 90.5, 'rain': 0.2},
    {'time': '2023-11-20 03:00', 'temp': 23.8, 'hum': 91.0, 'rain': 0.5},
    {'time': '2023-11-20 04:00', 'temp': 23.5, 'hum': 92.4, 'rain': 1.2},
    {'time': '2023-11-20 05:00', 'temp': 23.2, 'hum': 93.0, 'rain': 1.0},
    {'time': '2023-11-20 06:00', 'temp': 23.9, 'hum': 91.8, 'rain': 0.4},
    {'time': '2023-11-20 07:00', 'temp': 25.1, 'hum': 86.5, 'rain': 0.0},
    {'time': '2023-11-20 08:00', 'temp': 26.8, 'hum': 80.2, 'rain': 0.0},
    {'time': '2023-11-20 09:00', 'temp': 28.4, 'hum': 75.6, 'rain': 0.0},
  ];

  void _simulateUpload() async {
    setState(() {
      _isUploading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isUploading = false;
      _uploadedFileName = 'semarang_weather_sensor_data_2023.csv';
      _activeStep = 1; // Advance step to training configuration
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dataset berhasil diunggah dan divalidasi!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _simulateTraining() async {
    if (_uploadedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon unggah dataset terlebih dahulu.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    setState(() {
      _isTraining = true;
      _trainingProgress = 0.0;
      _activeStep = 1;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _trainingProgress = i * 10.0;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isTraining = false;
        _activeStep = 2; // Advance step to Deploy
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Model $_selectedAlgorithm berhasil dilatih!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SipandaTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWeb = constraints.maxWidth >= 960;
          return Column(
            children: [
              _buildTopBar(isWeb),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isWeb && _isSidebarVisible) _buildSidebar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWeb ? 32 : 16,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildStepper(),
                            const SizedBox(height: 24),
                            if (isWeb)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      children: [
                                        _buildUploadCard(),
                                        const SizedBox(height: 24),
                                        _buildValidationSummary(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 8,
                                    child: _buildDatasetPreview(),
                                  ),
                                ],
                              )
                            else ...[
                              _buildUploadCard(),
                              const SizedBox(height: 16),
                              _buildValidationSummary(),
                              const SizedBox(height: 16),
                              _buildDatasetPreview(),
                            ],
                            const SizedBox(height: 32),
                            if (isWeb)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildAlgorithmSelection()),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildTrainingParameters()),
                                ],
                              )
                            else ...[
                              _buildAlgorithmSelection(),
                              const SizedBox(height: 16),
                              _buildTrainingParameters(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 960 ? _buildMobileBottomNav() : null,
    );
  }

  Widget _buildTopBar(bool isWeb) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: SipandaTheme.surface,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isWeb)
                IconButton(
                  icon: const Icon(Icons.menu, color: SipandaTheme.primary),
                  onPressed: () {
                    setState(() {
                      _isSidebarVisible = !_isSidebarVisible;
                    });
                  },
                ),
              const SizedBox(width: 8),
              Text(
                'Aetheris AI',
                style: GoogleFonts.inter(
                  color: SipandaTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              if (isWeb) ...[
                const SizedBox(width: 48),
                _buildTopNavLink('Dashboard', false),
                _buildTopNavLink('Models', true),
                _buildTopNavLink('Datasets', false),
                _buildTopNavLink('Infrastructure', false),
              ]
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: SipandaTheme.textSecondary),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: SipandaTheme.textSecondary),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuB9QS6puMFqCiUJFNzNOPSyvgkISE20vu9FAP2XDeok9bt_yyNKGIFIenYXr1T8YVrOXoQDZ-0tZ4PDu97Dl-1krix8KG82r_gp_4dCwFe9TJQUK5gVkx-D_HgX3JQBn_vJMGooCEdahEbc0KEUiavnJDc5MJ5qX4VfbwHMsuFH9d94OkN0nS5Gw9tpPm0b8FKl3TwwExKLgGc3BneyTGOD3vhicgf5bj26Yp9jEE3zGFdOuFIkvvyFohF-lBNSwKFv1tCmg5Krvg',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => CircleAvatar(
                    radius: 16,
                    backgroundColor: SipandaTheme.primary.withOpacity(0.5),
                    child: const Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavLink(String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: isActive ? SipandaTheme.primary : SipandaTheme.textSecondary,
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: SipandaTheme.surface,
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SipandaTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hub, color: SipandaTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project Hera',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Vortex-12 Model Suite',
                      style: GoogleFonts.inter(
                        color: SipandaTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sidebarItem(Icons.analytics_outlined, 'Overview', false),
          _sidebarItem(Icons.model_training, 'Training', true),
          _sidebarItem(Icons.rule, 'Validation', false),
          _sidebarItem(Icons.rocket_launch_outlined, 'Deployment', false),
          _sidebarItem(Icons.history, 'Archive', false),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: SipandaTheme.primary,
              foregroundColor: SipandaTheme.background,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('New Experiment', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          _sidebarItem(Icons.description_outlined, 'Documentation', false),
          _sidebarItem(Icons.help_outline, 'Support', false),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? SipandaTheme.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, color: isActive ? SipandaTheme.primary : SipandaTheme.textSecondary, size: 20),
        title: Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? SipandaTheme.primary : SipandaTheme.textSecondary,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Training Forecasting Model',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Latih model machine learning untuk prediksi suhu, kelembaban, dan curah hujan hingga 48 jam ke depan.',
                style: GoogleFonts.inter(
                  color: SipandaTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: SipandaTheme.primary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {},
          icon: const Icon(Icons.inventory_2_outlined, color: SipandaTheme.primary, size: 18),
          label: Text(
            'Model Registry',
            style: GoogleFonts.inter(
              color: SipandaTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _stepItem(1, 'Upload Dataset', _activeStep >= 0),
        _stepLine(_activeStep >= 1),
        _stepItem(2, 'Training', _activeStep >= 1),
        _stepLine(_activeStep >= 2),
        _stepItem(3, 'Deploy', _activeStep >= 2),
      ],
    );
  }

  Widget _stepItem(int number, String label, bool isActive) {
    final activeColor = SipandaTheme.primary;
    final inactiveColor = Colors.white24;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? activeColor : inactiveColor,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? activeColor : SipandaTheme.textSecondary,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 2,
        color: isActive ? SipandaTheme.primary : Colors.white12,
      ),
    );
  }

  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: _isUploading ? null : _simulateUpload,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: SipandaTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: DashedBorderPainter(color: _uploadedFileName != null ? SipandaTheme.primary : Colors.white24),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isUploading
                        ? const CircularProgressIndicator(color: SipandaTheme.primary)
                        : Icon(
                            _uploadedFileName != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                            size: 48,
                            color: _uploadedFileName != null ? Colors.greenAccent : SipandaTheme.textSecondary,
                          ),
                    const SizedBox(height: 12),
                    Text(
                      _isUploading
                          ? 'Mengunggah & Memvalidasi Data...'
                          : (_uploadedFileName ?? 'Drop file here or browse'),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!_isUploading && _uploadedFileName == null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SipandaTheme.primary,
                          foregroundColor: SipandaTheme.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _simulateUpload,
                        child: const Text('Upload Dataset', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValidationSummary() {
    return Container(
      decoration: BoxDecoration(
        color: SipandaTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VALIDATION SUMMARY',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF005236),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'VALID',
                  style: TextStyle(
                    color: Color(0xFF4EDEa3),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow('Records', '87,600'),
          const Divider(color: Colors.white10),
          _summaryRow('Missing Values', '12', isError: true),
          const Divider(color: Colors.white10),
          _summaryRow('Frequency', 'Hourly'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: SipandaTheme.textSecondary)),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: isError ? Colors.redAccent : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatasetPreview() {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: SipandaTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'DATASET PREVIEW',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.02)),
                  columns: const [
                    DataColumn(label: Text('Timestamp')),
                    DataColumn(label: Text('Temperature (°C)')),
                    DataColumn(label: Text('Humidity (%)')),
                    DataColumn(label: Text('Rainfall (mm)')),
                  ],
                  rows: _dataset.map((row) {
                    return DataRow(
                      cells: [
                        DataCell(Text(row['time'], style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                        DataCell(Text(row['temp'].toString(), style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                        DataCell(Text(row['hum'].toString(), style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                        DataCell(Text(row['rain'].toString(), style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlgorithmSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Algorithm Selection',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _algorithmCard('LSTM', 'Long Short-Term Memory', 'Best Accuracy', Icons.psychology),
        _algorithmCard('GRU', 'Gated Recurrent Unit', 'Fast Training', Icons.bolt),
        _algorithmCard('XGBoost', 'Extreme Gradient Boosting', 'Tabular Data', Icons.account_tree),
        _algorithmCard('Random Forest', 'Ensemble Learning', 'Stable', Icons.forest),
        _algorithmCard('Prophet', 'Additive Modeling', 'Seasonality', Icons.timeline),
      ],
    );
  }

  Widget _algorithmCard(String code, String name, String tag, IconData icon) {
    final isSelected = _selectedAlgorithm == code;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAlgorithm = code;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? SipandaTheme.primary.withOpacity(0.05) : SipandaTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? SipandaTheme.primary : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? SipandaTheme.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isSelected ? SipandaTheme.primary : SipandaTheme.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    name,
                    style: const TextStyle(color: SipandaTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? SipandaTheme.primary.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: isSelected ? SipandaTheme.primary : SipandaTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingParameters() {
    return Container(
      decoration: BoxDecoration(
        color: SipandaTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Training Parameters',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Forecast Horizon
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Forecast Horizon', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${_forecastHorizon.toInt()}h',
                    style: const TextStyle(color: SipandaTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _forecastHorizon,
                min: 1,
                max: 48,
                activeColor: SipandaTheme.primary,
                onChanged: (val) => setState(() => _forecastHorizon = val),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1h', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('24h', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('48h', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Train / Test Split
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Train / Test Split', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${_trainSplit.toInt()} / ${(100 - _trainSplit).toInt()}',
                    style: const TextStyle(color: SipandaTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Expanded(
                        flex: _trainSplit.toInt(),
                        child: Container(color: SipandaTheme.primary),
                      ),
                      Expanded(
                        flex: (100 - _trainSplit).toInt(),
                        child: Container(color: SipandaTheme.primary.withOpacity(0.2)),
                      ),
                    ],
                  ),
                ),
              ),
              Slider(
                value: _trainSplit,
                min: 50,
                max: 95,
                activeColor: SipandaTheme.primary,
                onChanged: (val) => setState(() => _trainSplit = val),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('50%', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('80%', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('95%', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(8),
              border: const Border(left: BorderSide(color: SipandaTheme.primary, width: 4)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info, color: SipandaTheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Konfigurasi saat ini dioptimalkan untuk data time-series frekuensi per jam dengan memori 12 jam ke belakang.',
                    style: TextStyle(fontSize: 12, color: SipandaTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          if (_isTraining) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Training progress...', style: TextStyle(fontSize: 12, color: SipandaTheme.textSecondary)),
                    Text('${_trainingProgress.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _trainingProgress / 100.0,
                  backgroundColor: Colors.white10,
                  color: SipandaTheme.primary,
                ),
              ],
            ),
          ] else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: SipandaTheme.primary,
                foregroundColor: SipandaTheme.background,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _simulateTraining,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Model Training', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: SipandaTheme.surface,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _mobileNavItem(Icons.model_training, 'Training', true),
          _mobileNavItem(Icons.analytics_outlined, 'Stats', false),
          _mobileNavItem(Icons.inventory_2_outlined, 'Registry', false),
          _mobileNavItem(Icons.settings_outlined, 'Config', false),
        ],
      ),
    );
  }

  Widget _mobileNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? SipandaTheme.primary : SipandaTheme.textSecondary, size: 20),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isActive ? SipandaTheme.primary : SipandaTheme.textSecondary,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double dashWidth = 8;
    const double dashSpace = 4;
    final path = Path();
    
    // Top
    for (double x = 0; x < size.width; x += dashWidth + dashSpace) {
      path.moveTo(x, 0);
      path.lineTo((x + dashWidth).clamp(0, size.width), 0);
    }
    // Right
    for (double y = 0; y < size.height; y += dashWidth + dashSpace) {
      path.moveTo(size.width, y);
      path.lineTo(size.width, (y + dashWidth).clamp(0, size.height));
    }
    // Bottom
    for (double x = size.width; x > 0; x -= dashWidth + dashSpace) {
      path.moveTo(x, size.height);
      path.lineTo((x - dashWidth).clamp(0, size.width), size.height);
    }
    // Left
    for (double y = size.height; y > 0; y -= dashWidth + dashSpace) {
      path.moveTo(0, y);
      path.lineTo(0, (y - dashWidth).clamp(0, size.height));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}

