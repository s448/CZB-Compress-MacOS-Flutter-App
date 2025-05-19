import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mangabookmaker/controller/api_compress_controller.dart';

class CBZCompressionView extends StatelessWidget {
  final CBZCompressionController controller = Get.put(
    CBZCompressionController(),
  );
  final TextEditingController _batchSizeController = TextEditingController();
  final TextEditingController _stopPointController = TextEditingController();

  // ✅ Scroll Controller
  final ScrollController _scrollController = ScrollController();

  CBZCompressionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CBZ Compressor App'),
        backgroundColor: Colors.blueAccent,
      ),
      backgroundColor: Colors.blueAccent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  controller.endpoint.value = value;
                },
                decoration: const InputDecoration(
                  filled: true,
                  hintText: "API endpoint for testing on my local server",
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(80)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _batchSizeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        filled: true,
                        hintText: "Batch Size ( default 50 )",
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(80)),
                        ),
                      ),
                      onChanged: (value) {
                        controller.batchSize.value = int.tryParse(value) ?? 5;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _stopPointController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        filled: true,
                        hintText: "Stop Point ( default 50 )",
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(80)),
                        ),
                      ),
                      onChanged: (value) {
                        controller.stopPoint.value = int.tryParse(value) ?? 5;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  controller.startWatchingDirectory();
                },
                child: const Text('Start Watching Directory'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  controller.stopWatchingDirectory();
                },
                child: const Text('Stop Watching Directory'),
              ),
              const SizedBox(height: 20),
              Obx(
                () => Text(
                  controller.isWatching.value
                      ? "🟢 Watching..."
                      : "🔴 Stopped.",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 40, child: Text("Process Logs")),

              // ✅ ListView with Scroll Controller
              Obx(() {
                // Auto-scroll to the end
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  height: 300,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: controller.logMessages.length,
                    itemBuilder: (context, index) {
                      return Text(controller.logMessages[index]);
                    },
                  ),
                );
              }),
              const SizedBox(height: 20),
              Obx(() {
                return controller.isStopPointReached()
                    ? ElevatedButton(
                      onPressed: () {
                        controller.proceedProcessing();
                      },
                      child: const Text('Stop Point reached, Continue ?'),
                    )
                    : const SizedBox.shrink();
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
