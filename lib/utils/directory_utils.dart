import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart';
import 'package:mangabookmaker/controller/api_compress_controller.dart';
import 'package:mangabookmaker/data/api_data.dart';
import 'package:mangabookmaker/utils/google_drive_services.dart';

class DirectoryUtils {
  final Directory directory = Directory(
    join(
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '',
      'Desktop',
      'Books',
    ),
  );

  final GoogleDriveService _driveService = GoogleDriveService();
  StreamSubscription<FileSystemEvent>? _subscription;
  final CBZCompressionController controller;
  final List<String> _folderQueue = [];
  List<String> _batchQueue = [];
  bool _isPaused = false;
  Timer? _processTimer;

  DirectoryUtils(this.controller);

  void watchDirectory() {
    try {
      _subscription = directory.watch().listen((event) async {
        if (event.type == FileSystemEvent.create &&
            Directory(event.path).existsSync()) {
          // ✅ Add to the folder queue
          if (!_folderQueue.contains(event.path)) {
            _folderQueue.add(event.path);
            log("📂 Folder added to queue: ${event.path}");

            // ✅ Restart the timer for processing
            _processTimer?.cancel(); // Cancel if already running
            _processTimer = Timer(Duration(seconds: 3), () {
              log("⏳ Paste operation complete. Loading batch...");
              _loadBatch();
            });
          }
        }
      });
    } catch (e) {
      log('Error watching directory: $e');
    }
  }

  /// ✅ Load the first batch from _folderQueue to _batchQueue
  void _loadBatch() {
    // Clear old batch
    _batchQueue.clear();

    // Take the first "batchSize" elements from _folderQueue
    int loadSize = controller.batchSize.value;
    _batchQueue = _folderQueue.take(loadSize).toList();
    _folderQueue.removeRange(0, _batchQueue.length);

    log("🔄 Loaded ${_batchQueue.length} folders into batch.");
    _processBatch();
  }

  /// ✅ Process only the _batchQueue, one by one
  Future<void> _processBatch() async {
    log('🔄 Processing ${_batchQueue.length} folders from the batch queue.');

    while (_batchQueue.isNotEmpty && !_isPaused) {
      final folderPath = _batchQueue.removeAt(0);
      final images = await _loadImages(folderPath);
      final folderName = basename(folderPath);

      if (images.isNotEmpty) {
        final response = await APIService(
          controller.endpoint.value,
        ).compressImages(images, folderName);

        if (response != null) {
          controller.addLog("✅ Compression Successful: $response");
          log(" Compression Successful: $response");

          // ✅ Move to Trash after successful compression
          await _moveToTrash(folderPath);
          controller.addLog("Syncing to Google Drive");
          await _driveService.uploadFile(
            response.toString(),
            "17fRU-vUofuFMSLrhm_J6BJR3Wp4AnQWW",
          );
          controller.addLog("Book Saved to Drive");

          // ✅ Increment the stop point alarm
          controller.stopIndex.value++;
          log("🔔 Stop Point Alarm: ${controller.stopIndex.value}");

          // ✅ Check if stop point is reached
          if (controller.stopIndex.value >= controller.stopPoint.value) {
            controller.addLog("🛑 Stop point reached. Pausing...");
            _isPaused = true;
            break;
          }
        } else {
          controller.addLog("❌ Compression Failed");
          log(" Compression Failed");
        }
      } else {
        controller.addLog("⚠️ No images found in the folder.");
      }
    }
  }

  /// ✅ Function to continue processing after stop
  Future<void> proceedAfterStopPoint() async {
    if (_isPaused) {
      controller.addLog("🔄 Resuming after stop point...");
      controller.stopIndex.value = 0; // ✅ Reset the alarm
      _isPaused = false;
      await _processBatch();
    } else {
      log("⚠️ Not paused. No processing needed.");
    }
  }

  Future<List<Map<String, dynamic>>> _loadImages(String folderPath) async {
    final folder = Directory(folderPath);

    // Supported extensions
    final supportedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

    // Collecting image files
    final imageFiles = folder.listSync().where((file) {
      final extension = file.path.split('.').last.toLowerCase();
      return supportedExtensions.contains(extension);
    });

    // Reading the image bytes and adding them to a list
    List<Map<String, dynamic>> images = [];
    for (var image in imageFiles) {
      final bytes = await File(image.path).readAsBytes();
      images.add({'name': image.path.split('/').last, 'bytes': bytes});
    }

    return images;
  }

  /// 🗑️ Move to Recycle Bin (Windows only for now)
  Future<void> _moveToTrash(String folderPath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/C', 'rd', '/S', '/Q', folderPath]);
      } else if (Platform.isMacOS) {
        await Process.run('mv', [folderPath, '~/.Trash/']);
      }
      controller.addLog("🗑️ Folder moved to Trash: $folderPath");
    } catch (e) {
      log("❌ Failed to move to Trash: $e");
    }
  }

  /// Stop watching the directory
  void stopWatching() {
    if (_subscription != null) {
      _subscription?.cancel();
      _subscription = null;
      controller.addLog('🛑 Stopped watching: ${directory.path}');
    } else {
      log('⚠️ No active watcher to stop.');
    }
  }
}
