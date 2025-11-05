import 'package:flutter/material.dart';
import 'package:wifi_file_transfer/models/transfer_model.dart';
import 'package:wifi_file_transfer/utils/constants.dart';

class CustomProgressBar extends StatelessWidget {
  final double progress;
  final String? label;
  final Color? backgroundColor;
  final Color? progressColor;
  final double height;
  final BorderRadius? borderRadius;
  final bool showPercentage;

  const CustomProgressBar({
    Key? key,
    required this.progress,
    this.label,
    this.backgroundColor,
    this.progressColor,
    this.height = 8.0,
    this.borderRadius,
    this.showPercentage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surfaceVariant;
    final progColor = progressColor ?? theme.colorScheme.primary;
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showPercentage)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: AppConstants.mediumAnimation,
                width: progress.clamp(0.0, 1.0) * double.infinity,
                decoration: BoxDecoration(
                  color: progColor,
                  borderRadius: radius,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TransferProgressBar extends StatelessWidget {
  final TransferSession transfer;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final bool showActions;

  const TransferProgressBar({
    Key? key,
    required this.transfer,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = transfer.status == TransferStatus.completed;
    final isFailed = transfer.status == TransferStatus.failed;
    final isPaused = transfer.status == TransferStatus.paused;
    final isInProgress = transfer.status == TransferStatus.inProgress;

    Color progressColor;
    IconData statusIcon;
    String statusText;

    switch (transfer.status) {
      case TransferStatus.completed:
        progressColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case TransferStatus.failed:
        progressColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Failed';
        break;
      case TransferStatus.paused:
        progressColor = Colors.orange;
        statusIcon = Icons.pause_circle;
        statusText = 'Paused';
        break;
      case TransferStatus.cancelled:
        progressColor = Colors.grey;
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        break;
      case TransferStatus.inProgress:
        progressColor = theme.colorScheme.primary;
        statusIcon = Icons.sync;
        statusText = 'Transferring';
        break;
      default:
        progressColor = theme.colorScheme.primary;
        statusIcon = Icons.pending;
        statusText = 'Preparing';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 4,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with device and status
            Row(
              children: [
                Icon(
                  transfer.type == TransferType.send
                      ? Icons.upload
                      : Icons.download,
                  color: progressColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transfer.targetDevice.deviceName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      statusIcon,
                      color: progressColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            CustomProgressBar(
              progress: transfer.progress,
              label: '${transfer.files.length} files • ${transfer.formattedTotalSize}',
              progressColor: progressColor,
              height: 6,
            ),

            const SizedBox(height: 8),

            // Transfer details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${transfer.formattedTransferredSize} / ${transfer.formattedTotalSize}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isInProgress && transfer.transferSpeed != '0 MB/s')
                  Text(
                    transfer.transferSpeed,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),

            // Action buttons
            if (showActions && !isCompleted && !isFailed) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isInProgress) ...[
                    TextButton.icon(
                      onPressed: onPause,
                      icon: const Icon(Icons.pause, size: 16),
                      label: const Text('Pause'),
                    ),
                  ],
                  if (isPaused) ...[
                    TextButton.icon(
                      onPressed: onResume,
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Resume'),
                    ),
                  ],
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],

            // Error message
            if (isFailed && transfer.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transfer.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CircularProgressWithPercentage extends StatelessWidget {
  final double progress;
  final double size;
  final Color? color;
  final double strokeWidth;
  final Widget? child;

  const CircularProgressWithPercentage({
    Key? key,
    required this.progress,
    this.size = 60.0,
    this.color,
    this.strokeWidth = 6.0,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = color ?? theme.colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.surfaceVariant,
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          // Center content
          if (child != null)
            Center(child: child!)
          else
            Center(
              child: Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: progressColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}