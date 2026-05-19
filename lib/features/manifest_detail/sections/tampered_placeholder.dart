import 'dart:convert';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/entities/validation_status.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Number of unfeedback taps required before the failure-detail dialog opens.
const _tapsForDebugDialog = 10;

/// Solid-red placeholder rendered in place of the credential body when a
/// manifest's validation result is [ValidationStatus.invalid].
///
/// A bare [GestureDetector] swallows taps without any ripple or splash so
/// the surface stays visually static. After [_tapsForDebugDialog] taps the
/// widget reveals an [AlertDialog] listing every [ValidationStatusEntry] in
/// [failures] plus a Copy button that pretty-prints the entries to the
/// clipboard. The tap counter resets when the dialog dismisses.
class TamperedPlaceholder extends StatefulWidget {

  const TamperedPlaceholder({
    required this.result,
    required this.failures,
    super.key,
    this.validationState,
  });

  final ValidationResult result;
  final List<ValidationStatusEntry> failures;

  /// Optional `validation_state` string from the raw manifest, included in
  /// the failure dialog payload for context.
  final String? validationState;

  @override
  State<TamperedPlaceholder> createState() => _TamperedPlaceholderState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ValidationResult>('result', result))
      ..add(
        IterableProperty<ValidationStatusEntry>('failures', failures),
      )
      ..add(StringProperty('validationState', validationState));
  }
}

class _TamperedPlaceholderState extends State<TamperedPlaceholder> {
  int _tapCount = 0;

  Future<void> _onTap() async {
    _tapCount += 1;
    if (_tapCount < _tapsForDebugDialog) {
      return;
    }
    await _showDebugDialog();
    if (!mounted) {
      return;
    }
    setState(() => _tapCount = 0);
  }

  Future<void> _showDebugDialog() async {
    await showDialog<void>(
      context: context,
      builder: (final dialogContext) {
        final theme = C2paViewerTheme.of(dialogContext);
        return AlertDialog(
          title: const Text('Validation problem details'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.validationState != null) ...[
                    SelectableText(
                      'validation_state: ${widget.validationState}',
                      style: theme.bodySmallStyle.copyWith(
                        color: theme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.failures.isEmpty)
                    SelectableText(
                      'No error-coded validation entries were reported.',
                      style: theme.bodyStyle.copyWith(
                        color: theme.textPrimaryColor,
                      ),
                    )
                  else
                    for (final failure in widget.failures)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              failure.code,
                              style: theme.titleSmallStyle.copyWith(
                                color: theme.textPrimaryColor,
                              ),
                            ),
                            if (failure.url != null) ...[
                              const SizedBox(height: 2),
                              SelectableText(
                                failure.url!,
                                style: theme.bodySmallStyle.copyWith(
                                  color: theme.textSecondaryColor,
                                ),
                              ),
                            ],
                            if (failure.explanation != null) ...[
                              const SizedBox(height: 4),
                              SelectableText(
                                failure.explanation!,
                                style: theme.bodySmallStyle.copyWith(
                                  color: theme.textPrimaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: _copyFailuresJson,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyFailuresJson() async {
    final payload = <String, dynamic>{
      if (widget.validationState != null)
        'validation_state': widget.validationState,
      'failures': widget.failures
          .map(
            (final f) => <String, dynamic>{
              'code': f.code,
              if (f.url != null) 'url': f.url,
              if (f.explanation != null) 'explanation': f.explanation,
            },
          )
          .toList(),
    };
    final encoded = const JsonEncoder.withIndent('  ').convert(payload);
    await Clipboard.setData(ClipboardData(text: encoded));
  }

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.invalidColor,
            borderRadius: theme.sectionRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.dangerous, color: Colors.white, size: 36),
              SizedBox(height: 12),
              Text(
                "This file may have been tampered with. Its Content "
                "Credentials can't be verified or viewed.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
