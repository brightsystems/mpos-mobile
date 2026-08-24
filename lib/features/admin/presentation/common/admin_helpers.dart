import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';

AuthSessionEntity? sessionOf(BuildContext context) {
  final state = context.read<AuthBloc>().state;
  return state is AuthAuthenticated ? state.session : null;
}

/// Runs a repository action inside a progress dialog and surfaces a success or
/// error snackbar. Returns the data on success, or null on failure.
Future<T?> runAdminAction<T>(
  BuildContext context,
  Future<Result<T>> Function() action, {
  String? successMessage,
}) async {
  final result = await AppDialog.showProgress(() => action());

  if (result.isSuccess) {
    if (successMessage != null) {
      AppSnackBar.show(successMessage);
    }
    return result.data;
  }

  AppSnackBar.showError(result.error?.toString() ?? 'Something went wrong.');
  return null;
}
