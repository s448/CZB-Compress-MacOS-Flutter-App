import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class APIService {
  final String _baseUrl;

  APIService(this._baseUrl);

  compressImages(
    List<Map<String, dynamic>> imageFiles,
    String folderName,
  ) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      log("📡 Sending request to $_baseUrl");
      request.fields['folderName'] = folderName;

      for (var image in imageFiles) {
        final extension = image['name'].split('.').last.toLowerCase();
        final contentType = extension == 'png' ? 'png' : 'jpeg';

        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            image['bytes'] as List<int>,
            filename: image['name'],
            contentType: MediaType('image', contentType),
          ),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        log(" Compression Successful");
        var responseData = await response.stream.bytesToString();
        log(" Response Body: $responseData");
        return responseData;
      } else {
        log(" Compression Failed: ${response.statusCode}");
        final responseData = await response.stream.bytesToString();
        log(" Response Body: $responseData");
        return null;
      }
    } catch (e) {
      log("API call failed: $e");
      return null;
    }
  }
}

final Map<String, MediaType> supportedTypes = {
  'jpg': MediaType('image', 'jpeg'),
  'jpeg': MediaType('image', 'jpeg'),
  'png': MediaType('image', 'png'),
  'gif': MediaType('image', 'gif'),
  'bmp': MediaType('image', 'bmp'),
  'webp': MediaType('image', 'webp'),
  'tiff': MediaType('image', 'tiff'),
  'tif': MediaType('image', 'tiff'),
};
