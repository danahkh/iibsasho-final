import 'package:flutter/material.dart';
import '../../core/model/report.dart';
import '../../core/services/report_service.dart';

class ReportDialog extends StatefulWidget {
  final String reportedId;
  final String type; // 'listing' or 'user'
  final String reporterId;
  const ReportDialog({super.key, required this.reportedId, required this.type, required this.reporterId});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  String reason = '';
  String details = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.type == 'listing' ? 'Listing' : 'User'}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: reason.isNotEmpty ? reason : null,
              items: [
                DropdownMenuItem(value: 'Fraud', child: Text('Fraud')),
                DropdownMenuItem(value: 'Spam', child: Text('Spam')),
                DropdownMenuItem(value: 'Inappropriate', child: Text('Inappropriate')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => reason = v ?? ''),
              validator: (v) => v == null || v.isEmpty ? 'Select a reason' : null,
              decoration: InputDecoration(labelText: 'Reason'),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Details (optional)'),
              onChanged: (v) => details = v,
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => isLoading = true);
                  final report = Report(
                    id: '',
                    reportedId: widget.reportedId,
                    type: widget.type,
                    reason: reason,
                    details: details,
                    reporterId: widget.reporterId,
                    createdAt: DateTime.now(),
                    resolved: false,
                  );
                  await ReportService().submitReport(report);
                  setState(() => isLoading = false);
                  Navigator.of(context).pop(true);
                },
          child: Text(isLoading ? 'Reporting...' : 'Report'),
        ),
      ],
    );
  }
}

// Example usage: Add to listing/user UI
// To show report dialog:
// showDialog(
//   context: context,
//   builder: (context) => ReportDialog(
//     reportedId: listing.id, // or user.id
//     type: 'listing', // or 'user'
//     reporterId: 'currentUserId',
//   ),
// );
