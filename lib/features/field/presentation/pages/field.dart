import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../features/shared/providers/app_providers.dart';
import '../../../../core/models/entities.dart';
import '../../../../core/services/core_services.dart';

// ============ PHOTO LOG PAGE ============

class PhotoLogPage extends ConsumerStatefulWidget {
  final String projectId;
  const PhotoLogPage({super.key, required this.projectId});

  @override
  ConsumerState<PhotoLogPage> createState() => _PhotoLogPageState();
}

class _PhotoLogPageState extends ConsumerState<PhotoLogPage> {
  @override
  Widget build(BuildContext context) {
    final photoLogsAsync = ref.watch(photoLogsProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Log'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: () => _showAddPhotoDialog(context),
          ),
        ],
      ),
      body: photoLogsAsync.when(
        data: (photos) {
          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No photos yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPhotoDialog(context),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Add Photo'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return _buildPhotoCard(context, photo);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, PhotoLog photo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: photo.imagePath.startsWith('assets')
                ? Image.asset(photo.imagePath, fit: BoxFit.cover)
                : Image.file(
                    File(photo.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.image_not_supported),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.description,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Location: ${photo.location}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  photo.timestamp.toString().split('.')[0],
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPhotoDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    XFile? pickedFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Photo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      setState(() => pickedFile = image);
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: pickedFile != null
                        ? Image.file(File(pickedFile!.path), fit: BoxFit.cover)
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_camera,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                const Text('Tap to capture photo'),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (pickedFile == null) return;

                // Save image locally
                final appDir = await getApplicationDocumentsDirectory();
                final fileName = p.basename(pickedFile!.path);
                final savedPath = p.join(appDir.path, fileName);
                await File(pickedFile!.path).copy(savedPath);

                final photo = PhotoLog(
                  id: IdService.generatePhotoId(),
                  projectId: widget.projectId,
                  imagePath: savedPath,
                  description: descriptionController.text,
                  timestamp: DateTime.now(),
                  location: locationController.text,
                  tags: [],
                );

                ref
                    .read(photoLogsProvider(widget.projectId).notifier)
                    .addPhotoLog(photo);
                
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ DAILY REPORT PAGE ============

class DailyReportPage extends ConsumerWidget {
  final String projectId;
  const DailyReportPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(dailyReportsProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reports'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showNewReportDialog(context, ref),
          ),
        ],
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text('No reports yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                child: ListTile(
                  title: Text(report.date.toString().split(' ')[0]),
                  subtitle: Text(report.progressSummary),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showNewReportDialog(BuildContext context, WidgetRef ref) {
    final weatherController = TextEditingController();
    final progressController = TextEditingController();
    final safetyController = TextEditingController();
    int workers = 10;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Daily Report'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weatherController,
                  decoration: InputDecoration(
                    labelText: 'Weather',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Workers: '),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: workers.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            workers = int.tryParse(value) ?? 10;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: progressController,
                  decoration: InputDecoration(
                    labelText: 'Progress Summary',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: safetyController,
                  decoration: InputDecoration(
                    labelText: 'Safety Notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final report = DailyReport(
                  id: IdService.generateReportId(),
                  projectId: projectId,
                  date: DateTime.now(),
                  weather: weatherController.text,
                  workersCount: workers,
                  progressSummary: progressController.text,
                  issues: [],
                  safetyNotes: safetyController.text,
                );

                ref
                    .read(dailyReportsProvider(projectId).notifier)
                    .addReport(report);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ PUNCH LIST PAGE ============

class PunchListPage extends ConsumerWidget {
  final String projectId;
  const PunchListPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final punchListAsync = ref.watch(punchListProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Punch List'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddItemDialog(context, ref),
          ),
        ],
      ),
      body: punchListAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.checklist_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text('No items yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildPunchListCard(context, item, ref);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildPunchListCard(
    BuildContext context,
    PunchListItem item,
    WidgetRef ref,
  ) {
    final priorityColor =
        {
          'high': Colors.red,
          'medium': Colors.orange,
          'low': Colors.green,
        }[item.priority] ??
        Colors.blue;

    return Dismissible(
      key: Key(item.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right: Mark as Completed
          final updatedItem = item.copyWith(
            status: 'closed',
            completedAt: DateTime.now(),
          );
          ref.read(punchListProvider(projectId).notifier).updateItem(updatedItem);
          return false; // Don't remove from list, just update
        } else {
          // Swipe Left: Delete
          return true; // Remove from list
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          ref.read(punchListProvider(projectId).notifier).deleteItem(item.id);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Checkbox(
            value: item.status == 'closed',
            onChanged: (value) {
              final updatedItem = item.copyWith(
                status: value == true ? 'closed' : 'open',
                completedAt: value == true ? DateTime.now() : null,
              );
              ref
                  .read(punchListProvider(projectId).notifier)
                  .updateItem(updatedItem);
            },
          ),
          title: Text(
            item.description,
            style: TextStyle(
              decoration: item.status == 'closed'
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          subtitle: Text('Assigned to: ${item.assignedTo}'),
          trailing: Chip(
            label: Text(item.priority),
            backgroundColor: priorityColor.withValues(alpha: 0.2),
            labelStyle: TextStyle(color: priorityColor),
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final descriptionController = TextEditingController();
    final assignedController = TextEditingController();
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  items: const [
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                  ],
                  onChanged: (value) {
                    setState(() => priority = value ?? 'medium');
                  },
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: assignedController,
                  decoration: InputDecoration(
                    labelText: 'Assigned To',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final item = PunchListItem(
                  id: IdService.generateId(),
                  projectId: projectId,
                  description: descriptionController.text,
                  priority: priority,
                  status: 'open',
                  createdAt: DateTime.now(),
                  assignedTo: assignedController.text,
                );

                ref.read(punchListProvider(projectId).notifier).addItem(item);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
