import 'package:get/get.dart';
import 'package:mangabookmaker/utils/directory_utils.dart';

class CBZCompressionController extends GetxController {
  var batchSize = 5.obs; // Default batch size (user can change it)
  var stopPoint = 3.obs; // Default stop point, must be less than batch size
  var stopIndex = 0.obs;
  var endpoint = "".obs;
  var isWatching = false.obs;
  var logMessages = <String>[].obs;
  late DirectoryUtils directoryUtils;

  CBZCompressionController() {
    directoryUtils = DirectoryUtils(this);
  }

  startWatchingDirectory() {
    if (!isWatching.value) {
      addLog("👀 Starting directory watch...");
      directoryUtils.watchDirectory();
      isWatching.value = true;
    }
  }

  stopWatchingDirectory() {
    if (isWatching.value) {
      directoryUtils.stopWatching();
      isWatching.value = false;
    }
  }

  addLog(String message) {
    logMessages.add(message);
  }

  /// ✅ Proceed with processing after stop point is reached
  void proceedProcessing() {
    addLog("🔄 Proceeding where we stopped  ...");
    directoryUtils.proceedAfterStopPoint();
  }

  isStopPointReached() => stopPoint.value == stopIndex.value;
}
