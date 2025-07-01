import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/model/report.dart';
import '../../core/services/report_service.dart';

class ModerationPage extends StatelessWidget {
  const ModerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Moderation Tools'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SvgPicture.asset(
              'assets/icons/iibsashologo.svg',
              height: 32,
              width: 32,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Report>>(
        stream: ReportService().getReports(resolved: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No reports'));
          }
          final reports = snapshot.data!;
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('${report.type == 'listing' ? 'Listing' : 'User'}: ${report.reportedId}'),
                  subtitle: Text('Reason: ${report.reason}\nDetails: ${report.details}\nBy: ${report.reporterId}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await ReportService().resolveReport(report.id);
                    },
                    child: Text('Mark Resolved'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
