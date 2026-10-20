import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/entities.dart';

class ReportService {
  static Future<void> generateProjectSummary(
    Project project, {
    List<FootingCalculation>? footings,
    List<BeamCalculation>? beams,
    List<PunchListItem>? punchList,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(project.name),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildProjectInfo(project),
          pw.SizedBox(height: 20),
          if (footings != null && footings.isNotEmpty) ...[
            _buildSectionTitle('Footing Calculations'),
            _buildFootingsTable(footings),
            pw.SizedBox(height: 20),
          ],
          if (beams != null && beams.isNotEmpty) ...[
            _buildSectionTitle('Beam Calculations'),
            _buildBeamsTable(beams),
            pw.SizedBox(height: 20),
          ],
          if (punchList != null && punchList.isNotEmpty) ...[
            _buildSectionTitle('Field Punch List'),
            _buildPunchListTable(punchList),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Sibot_${project.name}_Summary.pdf',
    );
  }

  static pw.Widget _buildHeader(String projectName) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'SIBOT ENGINEERING REPORT',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.Text(
            projectName,
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
      ),
    );
  }

  static pw.Widget _buildProjectInfo(Project project) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Project Overview',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Text(
              'Location: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(project.location),
          ],
        ),
        pw.Row(
          children: [
            pw.Text(
              'Engineer: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(project.engineer),
          ],
        ),
        pw.Row(
          children: [
            pw.Text(
              'Date: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(DateTime.now().toString().split(' ')[0]),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(project.description),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
    );
  }

  static pw.Widget _buildFootingsTable(List<FootingCalculation> footings) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      data: <List<String>>[
        <String>[
          'Calculation Name',
          'Load (kN)',
          'Required Area (m²)',
          'Status',
        ],
        ...footings.map(
          (f) => [
            f.name,
            f.columnLoad.toString(),
            f.requiredArea?.toStringAsFixed(2) ?? 'N/A',
            f.isValid ? 'SAFE' : 'REVIEW',
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildBeamsTable(List<BeamCalculation> beams) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      data: <List<String>>[
        <String>['Calculation Name', 'Span (m)', 'Moment (kN.m)', 'Status'],
        ...beams.map(
          (b) => [
            b.name,
            b.span.toString(),
            ((b.load * b.span * b.span) / 8).toStringAsFixed(1),
            b.isValid ? 'SAFE' : 'REVIEW',
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPunchListTable(List<PunchListItem> items) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      data: <List<String>>[
        <String>['Description', 'Priority', 'Status', 'Assigned To'],
        ...items.map(
          (i) => [
            i.description,
            i.priority.toUpperCase(),
            i.status.toUpperCase(),
            i.assignedTo,
          ],
        ),
      ],
    );
  }
}
