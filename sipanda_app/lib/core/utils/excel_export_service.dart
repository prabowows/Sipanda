import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../../models/district_data.dart';
import '../services/bmkg_service.dart';
import 'file_saver/file_saver.dart';

class ExcelExportService {
  static Future<String?> exportDistrictWeatherToExcel({
    required String districtName,
    required DateTime startDate,
    required DateTime endDate,
    required List<DistrictHistoryData> historyLogs,
    List<WeatherData>? forecastLogs,
  }) async {
    final excel = Excel.createExcel();
    const defaultSheet = 'Sheet1';
    const sheetName = 'Data Cuaca';
    
    excel.rename(defaultSheet, sheetName);
    final sheet = excel[sheetName];

    final dateFormatter = DateFormat('dd MMMM yyyy, HH:mm:ss');
    final shortDateFormatter = DateFormat('dd-MM-yyyy HH:mm');
    final dateRangeFormatter = DateFormat('dd/MM/yyyy');

    // Styling definitions
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 13,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#02569B'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final subHeaderStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#222222'),
      backgroundColorHex: ExcelColor.fromHexString('#EEEEEE'),
    );

    final tableHeaderStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#0078D4'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final dataRowStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final dataRowCenterStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final dataRowNumberStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    final summaryHeaderStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final summaryValueStyle = CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    // 1. Report Title & Header Information
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('I1'));
    var cellA1 = sheet.cell(CellIndex.indexByString('A1'));
    cellA1.value = TextCellValue('SIPANDA - SISTEM INTEGRASI PERINGATAN DINI ADAPTIF KOTA SEMARANG');
    cellA1.cellStyle = titleStyle;

    sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('I2'));
    var cellA2 = sheet.cell(CellIndex.indexByString('A2'));
    cellA2.value = TextCellValue('LAPORAN LOG TELEMETRI & HISTORIS CUACA WILAYAH');
    cellA2.cellStyle = titleStyle;

    // Metadata details
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Kecamatan:');
    sheet.cell(CellIndex.indexByString('A4')).cellStyle = subHeaderStyle;
    sheet.cell(CellIndex.indexByString('B4')).value = TextCellValue(districtName.toUpperCase());
    
    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Periode Tanggal:');
    sheet.cell(CellIndex.indexByString('A5')).cellStyle = subHeaderStyle;
    sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue('${dateRangeFormatter.format(startDate)} s/d ${dateRangeFormatter.format(endDate)}');

    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Waktu Ekspor:');
    sheet.cell(CellIndex.indexByString('A6')).cellStyle = subHeaderStyle;
    sheet.cell(CellIndex.indexByString('B6')).value = TextCellValue('${dateFormatter.format(DateTime.now())} WIB');

    sheet.cell(CellIndex.indexByString('A7')).value = TextCellValue('Sumber Data:');
    sheet.cell(CellIndex.indexByString('A7')).cellStyle = subHeaderStyle;
    sheet.cell(CellIndex.indexByString('B7')).value = TextCellValue('BMKG Open Data & SiPanda Telemetry Engine');

    // 2. Table Headers (Updated: Focused on weather parameters with explanation for each)
    final headers = [
      'No',
      'Waktu Log (WIB)',
      'Kecamatan',
      'Curah Hujan (mm)',
      'Kategori Hujan',
      'Suhu (°C)',
      'Kategori Suhu',
      'Kelembapan (%)',
      'Status Kelembapan',
    ];

    int rowIndex = 8;
    for (int col = 0; col < headers.length; col++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = tableHeaderStyle;
    }

    List<Map<String, dynamic>> combinedRows = [];

    for (var h in historyLogs) {
      combinedRows.add({
        'time': h.timestamp,
        'rainfall': h.rainfall,
        'temp': h.temp,
        'humidity': h.humidity,
      });
    }

    if (combinedRows.isEmpty && forecastLogs != null && forecastLogs.isNotEmpty) {
      final startNorm = DateTime(startDate.year, startDate.month, startDate.day);
      final endNorm = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      for (var f in forecastLogs) {
        DateTime dt;
        try {
          dt = DateTime.parse(f.datetime).toLocal();
        } catch (_) {
          dt = DateTime.now();
        }
        
        if (dt.isAfter(startNorm.subtract(const Duration(seconds: 1))) &&
            dt.isBefore(endNorm.add(const Duration(seconds: 1)))) {
          combinedRows.add({
            'time': dt,
            'rainfall': f.tp,
            'temp': f.t,
            'humidity': f.hu,
          });
        }
      }
    }

    double totalRain = 0;
    double maxRain = 0;
    double totalTemp = 0;
    double totalHu = 0;

    rowIndex++;

    for (int i = 0; i < combinedRows.length; i++) {
      final row = combinedRows[i];
      final time = row['time'] as DateTime;
      final rainfall = (row['rainfall'] as num).toDouble();
      final temp = (row['temp'] as num).toDouble();
      final humidity = (row['humidity'] as num).toDouble();

      totalRain += rainfall;
      if (rainfall > maxRain) maxRain = rainfall;
      totalTemp += temp;
      totalHu += humidity;

      String rainCategory = 'Cerah / Ringan';
      if (rainfall > 10) {
        rainCategory = 'Hujan Lebat';
      } else if (rainfall >= 5) {
        rainCategory = 'Hujan Sedang';
      }

      String tempCategory = 'Normal';
      if (temp > 35) {
        tempCategory = 'Sangat Panas';
      } else if (temp >= 30) {
        tempCategory = 'Panas';
      }

      String huCategory = 'Lembap';
      if (humidity < 40) {
        huCategory = 'Kering';
      } else if (humidity <= 60) {
        huCategory = 'Sedang';
      }

      final rowValues = [
        IntCellValue(i + 1),
        TextCellValue('${shortDateFormatter.format(time)} WIB'),
        TextCellValue(districtName.toUpperCase()),
        DoubleCellValue(rainfall),
        TextCellValue(rainCategory),
        DoubleCellValue(temp),
        TextCellValue(tempCategory),
        DoubleCellValue(humidity),
        TextCellValue(huCategory),
      ];

      for (int col = 0; col < rowValues.length; col++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
        cell.value = rowValues[col];

        if (col == 0 || col == 1 || col == 4 || col == 6 || col == 8) {
          cell.cellStyle = dataRowCenterStyle;
        } else if (col == 3 || col == 5 || col == 7) {
          cell.cellStyle = dataRowNumberStyle;
        } else {
          cell.cellStyle = dataRowStyle;
        }
      }

      rowIndex++;
    }

    // Empty state
    if (combinedRows.isEmpty) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: rowIndex),
      );
      var emptyCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      emptyCell.value = TextCellValue('Tidak ada rekaman data telemetri untuk rentang tanggal yang dipilih.');
      emptyCell.cellStyle = dataRowCenterStyle;
      rowIndex++;
    }

    // 3. Summary Section at bottom
    rowIndex += 2;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
    );
    var summaryTitle = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    summaryTitle.value = TextCellValue('RINGKASAN STATISTIK WILAYAH');
    summaryTitle.cellStyle = summaryHeaderStyle;
    rowIndex++;

    void addSummaryRow(String label, String value) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
      );
      var lblCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      lblCell.value = TextCellValue(label);
      lblCell.cellStyle = subHeaderStyle;

      var valCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
      valCell.value = TextCellValue(value);
      valCell.cellStyle = summaryValueStyle;
      rowIndex++;
    }

    final totalRows = combinedRows.length;
    final avgTemp = totalRows > 0 ? (totalTemp / totalRows).toStringAsFixed(1) : '-';
    final avgHu = totalRows > 0 ? (totalHu / totalRows).toStringAsFixed(0) : '-';
    final avgRain = totalRows > 0 ? (totalRain / totalRows).toStringAsFixed(2) : '-';

    addSummaryRow('Total Data / Frekuensi Log', '$totalRows rekaman');
    addSummaryRow('Rata-rata Suhu', '$avgTemp °C');
    addSummaryRow('Rata-rata Kelembapan', '$avgHu %');
    addSummaryRow('Total Akumulasi Curah Hujan', '${totalRain.toStringAsFixed(1)} mm');
    addSummaryRow('Rata-rata Curah Hujan', '$avgRain mm');
    addSummaryRow('Curah Hujan Maksimum', '${maxRain.toStringAsFixed(1)} mm');

    // Set column widths
    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 24);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 16);
    sheet.setColumnWidth(7, 16);
    sheet.setColumnWidth(8, 20);

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final sanitizedKecamatan = districtName.replaceAll(' ', '_').toLowerCase();
      final startStr = DateFormat('yyyyMMdd').format(startDate);
      final endStr = DateFormat('yyyyMMdd').format(endDate);
      final fileName = 'SiPanda_Cuaca_${sanitizedKecamatan}_${startStr}_${endStr}.xlsx';

      return await saveFile(
        bytes: fileBytes,
        fileName: fileName,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
    return null;
  }
}
