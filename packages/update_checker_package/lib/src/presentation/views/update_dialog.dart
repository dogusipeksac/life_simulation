import 'package:flutter/material.dart';
import '../../domain/models/update_info.dart';

class UpdateBottomSheetDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final bool isForce;
  final VoidCallback onUpdateClick;
  final VoidCallback onDismiss;

  const UpdateBottomSheetDialog({
    Key? key,
    required this.updateInfo,
    required this.isForce,
    required this.onUpdateClick,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return PopScope(
      canPop: !isForce,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: colorScheme.outline.withOpacity(0.14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              updateInfo.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              updateInfo.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.78),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onUpdateClick,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                updateInfo.confirmButtonText.isEmpty
                    ? 'Update'
                    : updateInfo.confirmButtonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!isForce && updateInfo.cancelButtonText != null && updateInfo.cancelButtonText!.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withOpacity(0.72),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  updateInfo.cancelButtonText ?? 'Later',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required UpdateInfo updateInfo,
    required bool isForce,
    required VoidCallback onUpdateClick,
    required VoidCallback onDismiss,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: !isForce,
      enableDrag: !isForce,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UpdateBottomSheetDialog(
        updateInfo: updateInfo,
        isForce: isForce,
        onUpdateClick: onUpdateClick,
        onDismiss: onDismiss,
      ),
    );
  }
}
