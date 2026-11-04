import 'package:flutter/foundation.dart';

/// Why the API stopped the business: its MPOS workspace is unpaid, suspended or leaving.
class WorkspaceBlock {
  const WorkspaceBlock({required this.code, required this.message});

  /// payment_required, workspace_suspended, workspace_exit or workspace_deleted.
  final String code;
  final String message;

  bool get isPaymentRequired => code == 'payment_required';

  String get title => switch (code) {
    'payment_required' => 'Subscription payment pending',
    'workspace_suspended' => 'Business suspended',
    'workspace_exit' => 'Business is leaving MPOS',
    _ => 'Business closed',
  };
}

/// Set by the API client from 402/403/410 answers with a block code; cleared by the next
/// successful business call (e.g. after the admin marks the workspace paid). The app shows a
/// full-screen notice while it is set.
class WorkspaceBlockNotifier extends ValueNotifier<WorkspaceBlock?> {
  WorkspaceBlockNotifier._() : super(null);

  static final instance = WorkspaceBlockNotifier._();

  static const codes = {'payment_required', 'workspace_suspended', 'workspace_exit', 'workspace_deleted'};

  /// Looks at an API answer: a block sets the notice, a success on a business call clears it.
  void inspect(int statusCode, Map<String, dynamic> body, String path) {
    final code = body['code'];
    if ((statusCode == 402 || statusCode == 403 || statusCode == 410) && code is String && codes.contains(code)) {
      value = WorkspaceBlock(code: code, message: (body['message'] as String?) ?? '');
    } else if (statusCode >= 200 && statusCode < 300 && value != null && !path.startsWith('/auth')) {
      value = null;
    }
  }

  void clear() => value = null;
}
