class CBZCompressionModel {
  final String fileName;
  final String downloadUrl;

  CBZCompressionModel({required this.fileName, required this.downloadUrl});

  factory CBZCompressionModel.fromJson(Map<String, dynamic> json) {
    return CBZCompressionModel(
      fileName: json['fileName'],
      downloadUrl: json['downloadUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'fileName': fileName, 'downloadUrl': downloadUrl};
  }
}
