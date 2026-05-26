import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart' as dio_instance;
import '../utils/constants.dart';
import 'localStorage/my-local-controller.dart';

class ApiService {
  // Helper methods for setting headers (assuming these are defined elsewhere)
  static void setAcceptHeader(dio_instance.Dio dio) {
    dio.options.headers['Accept'] = 'application/json';
  }

  static void setContentHeader(dio_instance.Dio dio) {
    dio.options.headers['Content-Type'] = 'application/json';
  }

  static Future<void> setCustomHeader(
    dio_instance.Dio dio,
    String key,
    String value,
  ) async {
    dio.options.headers[key] = value;
  }

  static void showSnackBar(String title, String message) {
    // Implement your snackbar logic here
    log('$title: $message');
  }

  // POST Method (unchanged)
  static Future<void> postMethod({
    required String apiUrl,
    required dynamic postData,
    required Function(bool success, dynamic data) executionMethod,
    bool authHeader = false,
    dynamic queryParameters,
  }) async {
    dio_instance.Response response;
    dio_instance.Dio dio = dio_instance.Dio();

    dio.options.connectTimeout = const Duration(milliseconds: 10000);
    dio.options.receiveTimeout = const Duration(milliseconds: 6000);

    setAcceptHeader(dio);
    setContentHeader(dio);
    if (authHeader) {
      setCustomHeader(
        dio,
        'Authorization',
        'Bearer ${await LocalStorage.getData(key: AppKeys.authToken)}',
      );
    }

    try {
      var connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult != ConnectivityResult.none) {
        log('Internet Connected');
        try {
          log('postData--->> $postData');

          response = await dio.post(
            apiUrl,
            data: postData,
            queryParameters: queryParameters,
          );
          log('StatusCode------>> ${response.statusCode}');
          log('Post Response $apiUrl------>> $response');

          if (response.statusCode == 200 || response.statusCode == 201) {
            executionMethod(true, response.data);
            return;
          }
          executionMethod(false, {'success': false});
        } on dio_instance.DioException catch (e) {
          log(e.response.toString());
          int statusCode = e.response?.statusCode ?? 500;
          if (statusCode >= 500) {
            executionMethod(false, {'message': 'Server Error'});
            return;
          }
          if (dio_instance.DioExceptionType.receiveTimeout == e.type ||
              dio_instance.DioExceptionType.connectionTimeout == e.type) {
            showSnackBar('Error', 'Internet Not Connected');
            executionMethod(false, {'message': null});
            return;
          } else if (dio_instance.DioExceptionType.unknown == e.type) {
            if (e.message!.contains('SocketException')) {
              showSnackBar('Error', 'Connection failed');
              executionMethod(false, {'success': false});
              return;
            }
          }
          log('Dio Error From Post $apiUrl -->> ${e.message}');
          var data = json.decode(e.response.toString());
          executionMethod(false, data);
        }
      } else {
        showSnackBar('Error', 'Internet Not Connected');
        log('Internet Not Connected');
        executionMethod(false, {'message': 'Internet Not Connected'});
      }
    } on SocketException catch (_) {
      showSnackBar('Error', 'Internet Not Connected');
      log('Internet Not Connected');
      executionMethod(false, {'message': 'Internet Not Connected'});
    }
  }

  // GET Method (unchanged)
  static Future<void> getMethod({
    required String apiUrl,
    required Function(bool success, dynamic data) executionMethod,
    bool authHeader = false,
    dynamic queryParameters,
  }) async {
    dio_instance.Response response;
    dio_instance.Dio dio = dio_instance.Dio();

    dio.options.connectTimeout = const Duration(milliseconds: 10000);
    dio.options.receiveTimeout = const Duration(milliseconds: 6000);

    setAcceptHeader(dio);
    setContentHeader(dio);
    if (authHeader) {
      setCustomHeader(
        dio,
        'Authorization',
        'Bearer ${await LocalStorage.getData(key: AppKeys.authToken)}',
      );
    }

    try {
      var connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult != ConnectivityResult.none) {
        log('Internet Connected');
        try {
          log('GET Request to $apiUrl with queryParameters: $queryParameters');

          response = await dio.get(apiUrl, queryParameters: queryParameters);
          log('StatusCode------>> ${response.statusCode}');
          log('GET Response $apiUrl------>> $response');

          if (response.statusCode == 200 || response.statusCode == 201) {
            executionMethod(true, response.data);
            return;
          }
          executionMethod(false, {'success': false});
        } on dio_instance.DioException catch (e) {
          log(e.response.toString());
          int statusCode = e.response?.statusCode ?? 500;
          if (statusCode >= 500) {
            executionMethod(false, {'message': 'Server Error'});
            return;
          }
          if (dio_instance.DioExceptionType.receiveTimeout == e.type ||
              dio_instance.DioExceptionType.connectionTimeout == e.type) {
            showSnackBar('Error', 'Internet Not Connected');
            executionMethod(false, {'message': null});
            return;
          } else if (dio_instance.DioExceptionType.unknown == e.type) {
            if (e.message!.contains('SocketException')) {
              showSnackBar('Error', 'Connection failed');
              executionMethod(false, {'success': false});
              return;
            }
          }
          log('Dio Error From GET $apiUrl -->> ${e.message}');
          var data = json.decode(e.response.toString());
          executionMethod(false, data);
        }
      } else {
        showSnackBar('Error', 'Internet Not Connected');
        log('Internet Not Connected');
        executionMethod(false, {'message': 'Internet Not Connected'});
      }
    } on SocketException catch (_) {
      showSnackBar('Error', 'Internet Not Connected');
      log('Internet Not Connected');
      executionMethod(false, {'message': 'Internet Not Connected'});
    }
  }

  // New Multipart POST Method
  static Future<void> postMultipartMethod({
    required String apiUrl,
    required Map<String, dynamic> formData,
    File? file,
    String fileKey = 'file',
    required Function(bool success, dynamic data) executionMethod,
    bool authHeader = false,
    dynamic queryParameters,
  }) async {
    dio_instance.Response response;
    dio_instance.Dio dio = dio_instance.Dio();

    dio.options.connectTimeout = const Duration(milliseconds: 10000);
    dio.options.receiveTimeout = const Duration(milliseconds: 6000);

    setAcceptHeader(dio);
    // Note: Content-Type will be set automatically to multipart/form-data by Dio
    if (authHeader) {
      setCustomHeader(
        dio,
        'Authorization',
        'Bearer ${await LocalStorage.getData(key: AppKeys.authToken)}',
      );
    }

    try {
      var connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult != ConnectivityResult.none) {
        log('Internet Connected');
        try {
          // Prepare form data
          dio_instance.FormData dioFormData = dio_instance.FormData.fromMap(
            formData,
          );

          // Add file if provided
          if (file != null) {
            dioFormData.files.add(
              MapEntry(
                fileKey,
                await dio_instance.MultipartFile.fromFile(
                  file.path,
                  filename: file.path.split('/').last,
                ),
              ),
            );
          }

          log('Multipart postData--->> $formData');
          if (file != null) {
            log('Uploading file: ${file.path} with key: $fileKey');
          }

          response = await dio.post(
            apiUrl,
            data: dioFormData,
            queryParameters: queryParameters,
          );
          log('StatusCode------>> ${response.statusCode}');
          log('Multipart Post Response $apiUrl------>> $response');

          if (response.statusCode == 200 || response.statusCode == 201) {
            executionMethod(true, response.data);
            return;
          }
          executionMethod(false, {'success': false});
        } on dio_instance.DioException catch (e) {
          log(e.response.toString());
          int statusCode = e.response?.statusCode ?? 500;
          if (statusCode >= 500) {
            executionMethod(false, {'message': 'Server Error'});
            return;
          }
          if (dio_instance.DioExceptionType.receiveTimeout == e.type ||
              dio_instance.DioExceptionType.connectionTimeout == e.type) {
            showSnackBar('Error', 'Internet Not Connected');
            executionMethod(false, {'message': null});
            return;
          } else if (dio_instance.DioExceptionType.unknown == e.type) {
            if (e.message!.contains('SocketException')) {
              showSnackBar('Error', 'Connection failed');
              executionMethod(false, {'success': false});
              return;
            }
          }
          log('Dio Error From Multipart Post $apiUrl -->> ${e.message}');
          var data = json.decode(e.response.toString());
          executionMethod(false, data);
        }
      } else {
        showSnackBar('Error', 'Internet Not Connected');
        log('Internet Not Connected');
        executionMethod(false, {'message': 'Internet Not Connected'});
      }
    } on SocketException catch (_) {
      showSnackBar('Error', 'Internet Not Connected');
      log('Internet Not Connected');
      executionMethod(false, {'message': 'Internet Not Connected'});
    }
  }

  static Future<void> postMultipartMultipleFilesMethod({
    required String apiUrl,
    required Map<String, String> formData,
    required List<File> files,
    String fileKey = 'images',
    required Function(bool success, dynamic data) executionMethod,
    bool authHeader = false,
    dynamic queryParameters,
  }) async {
    dio_instance.Response response;
    dio_instance.Dio dio = dio_instance.Dio();

    dio.options.connectTimeout = const Duration(milliseconds: 10000);
    dio.options.receiveTimeout = const Duration(milliseconds: 6000);

    setAcceptHeader(dio);

    if (authHeader) {
      setCustomHeader(
        dio,
        'Authorization',
        'Bearer ${await LocalStorage.getData(key: AppKeys.authToken)}',
      );
    }

    try {
      var connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult != ConnectivityResult.none) {
        log('Internet Connected');

        try {
          final dioFormData = dio_instance.FormData();

          // Add form fields
          formData.forEach((key, value) {
            dioFormData.fields.add(MapEntry(key, value));
          });

          // Add multiple image files
          for (var file in files) {
            final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
            dioFormData.files.add(
              MapEntry(
                '$fileKey[]', // important: must be 'images[]'
                await dio_instance.MultipartFile.fromFile(
                  file.path,
                  filename: fileName,
                  contentType: MediaType('image', 'jpeg'),
                ),
              ),
            );
          }

          log('Multipart postData--->> $formData');
          log('Uploading ${files.length} files...');

          response = await dio.post(
            apiUrl,
            data: dioFormData,
            queryParameters: queryParameters,
          );

          log('StatusCode------>> ${response.statusCode}');
          log('Multipart Post Response $apiUrl------>> $response');
          log('Multipart Response Data: ${response.data}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            executionMethod(true, response.data);
            return;
          }

          executionMethod(false, {'success': false});
        } on dio_instance.DioException catch (e) {
          log('Dio Error From Multipart Post $apiUrl -->> ${e.message}');
          int statusCode = e.response?.statusCode ?? 500;

          if (statusCode >= 500) {
            executionMethod(false, {'message': 'Server Error'});
            return;
          }

          if (dio_instance.DioExceptionType.receiveTimeout == e.type ||
              dio_instance.DioExceptionType.connectionTimeout == e.type) {
            showSnackBar('Error', 'Internet Not Connected');
            executionMethod(false, {'message': null});
            return;
          } else if (dio_instance.DioExceptionType.unknown == e.type) {
            if (e.message!.contains('SocketException')) {
              showSnackBar('Error', 'Connection failed');
              executionMethod(false, {'success': false});
              return;
            }
          }

          var data = json.decode(e.response!.data());
          executionMethod(false, data);
        }
      } else {
        showSnackBar('Error', 'Internet Not Connected');
        log('Internet Not Connected');
        executionMethod(false, {'message': 'Internet Not Connected'});
      }
    } on SocketException catch (_) {
      showSnackBar('Error', 'Internet Not Connected');
      log('Internet Not Connected');
      executionMethod(false, {'message': 'Internet Not Connected'});
    }
  }
}
