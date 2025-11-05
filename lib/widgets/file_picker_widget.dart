import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wifi_file_transfer/models/file_model.dart';
import 'package:wifi_file_transfer/utils/constants.dart';

class FilePickerWidget extends StatefulWidget {
  final List<FileModel> selectedFiles;
  final Function(List<FileModel>) onFilesSelected;
  final bool multiSelect;
  final int? maxFileSize;
  final List<String>? allowedExtensions;

  const FilePickerWidget({
    Key? key,
    required this.selectedFiles,
    required this.onFilesSelected,
    this.multiSelect = true,
    this.maxFileSize,
    this.allowedExtensions,
  }) : super(key: key);

  @override
  State<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  bool _isPicking = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSize = widget.selectedFiles.fold<int>(
      0,
      (sum, file) => sum + file.size,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.folder_open,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Files',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (widget.selectedFiles.isNotEmpty)
                  TextButton(
                    onPressed: _clearAllFiles,
                    child: const Text('Clear All'),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // File picker button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPicking ? null : _pickFiles,
                icon: _isPicking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isPicking ? 'Loading...' : 'Add Files'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Selected files list
            if (widget.selectedFiles.isNotEmpty) ...[
              // Summary
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.selectedFiles.length} files • ${_formatSize(totalSize)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Files list
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.selectedFiles.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final file = widget.selectedFiles[index];
                    return _buildFileItem(file, index);
                  },
                ),
              ),
            ] else ...[
              // Empty state
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_off,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No files selected',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "Add Files" to browse',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(FileModel file, int index) {
    final theme = Theme.of(context);
    final fileIcon = _getFileIcon(file.type, file.extension);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // File icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                fileIcon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  file.formattedSize,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            onPressed: () => _removeFile(index),
            icon: const Icon(Icons.close, size: 20),
            visualDensity: VisualDensity.compact,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  String _getFileIcon(FileType type, String? extension) {
    // Check for specific file type icons
    if (extension != null && AppConstants.fileTypeIcons.containsKey(extension)) {
      return AppConstants.fileTypeIcons[extension]!;
    }

    // Fallback to generic file type icons
    switch (type) {
      case FileType.image:
        return '🖼️';
      case FileType.video:
        return '🎬';
      case FileType.audio:
        return '🎵';
      case FileType.document:
        return '📄';
      default:
        return '📎';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  Future<void> _pickFiles() async {
    setState(() {
      _isPicking = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: widget.allowedExtensions != null
            ? FileType.custom
            : FileType.any,
        allowMultiple: widget.multiSelect,
        allowedExtensions: widget.allowedExtensions,
      );

      if (result != null) {
        final selectedFiles = <FileModel>[];
        int totalSize = widget.selectedFiles.fold<int>(
          0,
          (sum, file) => sum + file.size,
        );

        for (final file in result.files) {
          if (file.path != null) {
            final fileModel = FileModel.fromPath(
              file.path!,
              DateTime.now().millisecondsSinceEpoch.toString(),
            );

            // Check file size limit
            if (widget.maxFileSize != null && fileModel.size > widget.maxFileSize!) {
              _showErrorSnackBar(
                'File "${fileModel.name}" exceeds the size limit of ${_formatSize(widget.maxFileSize!)}',
              );
              continue;
            }

            selectedFiles.add(fileModel);
            totalSize += fileModel.size;
          }
        }

        if (selectedFiles.isNotEmpty) {
          final updatedFiles = [...widget.selectedFiles, ...selectedFiles];
          widget.onFilesSelected(updatedFiles);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick files: $e');
    } finally {
      setState(() {
        _isPicking = false;
      });
    }
  }

  void _removeFile(int index) {
    final updatedFiles = List<FileModel>.from(widget.selectedFiles);
    updatedFiles.removeAt(index);
    widget.onFilesSelected(updatedFiles);
  }

  void _clearAllFiles() {
    widget.onFilesSelected([]);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class QuickFilePicker extends StatelessWidget {
  final Function(FileModel) onFileSelected;
  final List<String> quickTypes;

  const QuickFilePicker({
    Key? key,
    required this.onFileSelected,
    this.quickTypes = const ['images', 'documents', 'videos', 'audio'],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Select',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (quickTypes.contains('images'))
                _buildQuickOption(
                  context,
                  label: 'Images',
                  icon: Icons.image,
                  extensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
                ),
              if (quickTypes.contains('documents'))
                _buildQuickOption(
                  context,
                  label: 'Documents',
                  icon: Icons.description,
                  extensions: ['pdf', 'doc', 'docx', 'txt', 'rtf'],
                ),
              if (quickTypes.contains('videos'))
                _buildQuickOption(
                  context,
                  label: 'Videos',
                  icon: Icons.videocam,
                  extensions: ['mp4', 'avi', 'mov', 'mkv', 'wmv'],
                ),
              if (quickTypes.contains('audio'))
                _buildQuickOption(
                  context,
                  label: 'Audio',
                  icon: Icons.audiotrack,
                  extensions: ['mp3', 'wav', 'flac', 'aac', 'ogg'],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required List<String> extensions,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _pickFilesByType(extensions),
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFilesByType(List<String> extensions) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: extensions,
      );

      if (result != null) {
        for (final file in result.files) {
          if (file.path != null) {
            final fileModel = FileModel.fromPath(
              file.path!,
              DateTime.now().millisecondsSinceEpoch.toString(),
            );
            onFileSelected(fileModel);
          }
        }
      }
    } catch (e) {
      // Handle error
    }
  }
}