import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/global.dart';

import '../model/mobile_email_check_model.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final fcmToken = await Global.getFCMToken();

      Map<String, dynamic> body = {
        'email': email,
        'password': password,
        "fcm_token": fcmToken,
        "device_type": Platform.isAndroid ? 'android' : 'ios',
      };

      var response = await ApiBaseHelper.loginPost(
        url: ApiRoutes.loginApi,
        body: body,
      );
      return response;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String mobile,
    required String country,
    required String countryCode,
    required String iso2,
    required String password,
    required String confirmPassword,
    required String address,
    required String driverLicenseNumber,
    required String vehicleType,
    required int deliveryZoneId,
    required List<File> driverLicenseFiles,
    required List<File> vehicleRegistrationFiles,
    required String friends_code,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🚀 === REGISTRATION DATA START ===');
        debugPrint('Name: $name');
        debugPrint('Email: $email');
        debugPrint('Mobile: $mobile');
        debugPrint('Country: $country ($iso2)');
        debugPrint('Address: $address');
        debugPrint('Driver License Number: $driverLicenseNumber');
        debugPrint('Vehicle Type: $vehicleType');
        debugPrint('Delivery Zone ID: $deliveryZoneId');
        debugPrint('Password: ${password.isNotEmpty ? '***SET***' : 'EMPTY'}');
        debugPrint(
          'Confirm Password: ${confirmPassword.isNotEmpty ? '***SET***' : 'EMPTY'}',
        );
        debugPrint(
          'Refer Code: ${friends_code.isNotEmpty ? '***$friends_code***' : 'EMPTY'}',
        );
        debugPrint('Driver License Files count: ${driverLicenseFiles.length}');
        for (var i = 0; i < driverLicenseFiles.length; i++) {
          debugPrint('  File $i path: ${driverLicenseFiles[i].path}');
        }
        debugPrint(
          'Vehicle Registration Files count: ${vehicleRegistrationFiles.length}',
        );
        for (var i = 0; i < vehicleRegistrationFiles.length; i++) {
          debugPrint('  File $i path: ${vehicleRegistrationFiles[i].path}');
        }
        debugPrint('=== REGISTRATION DATA END ===');
      }

      // Validate files exist before uploading
      for (final file in driverLicenseFiles) {
        if (!await file.exists()) {
          throw Exception(
            'Driver license file does not exist at path: ${file.path}',
          );
        }
      }
      for (final file in vehicleRegistrationFiles) {
        if (!await file.exists()) {
          throw Exception(
            'Vehicle registration file does not exist at path: ${file.path}',
          );
        }
      }

      final fcmToken = await Global.getFCMToken();

      var data = FormData.fromMap({
        'email': email,
        'mobile': mobile,
        'password': password,
        'full_name': name,
        'address': address,
        'driver_license_number': driverLicenseNumber,
        'vehicle_type': vehicleType,
        'delivery_zone_id': deliveryZoneId.toString(),
        'country': country,
        'country_code': countryCode,
        'iso_2': iso2,
        'password_confirmation': confirmPassword,
        "fcm_token": fcmToken,
        "device_type": Platform.isAndroid ? 'android' : 'ios',
        "friends_code": friends_code,
      });

      // Add driver license files
      for (final file in driverLicenseFiles) {
        final fileName = file.path.split('/').last;
        data.files.add(
          MapEntry(
            'driver_license[]',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ),
        );
      }

      // Add vehicle registration files
      for (final file in vehicleRegistrationFiles) {
        final fileName = file.path.split('/').last;
        data.files.add(
          MapEntry(
            'vehicle_registration[]',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ),
        );
      }

      if (kDebugMode) {
        debugPrint('📤 FormData prepared successfully');
        debugPrint(
          'Total fields in FormData: ${data.fields.length + data.files.length}',
        );
        debugPrint(
          'Fields: ${data.fields.map((e) => '${e.key}: ${e.value}').join(' | ')}',
        );
        debugPrint(
          'Files: ${data.files.map((e) => '${e.key}: ${e.value.filename}').join(' | ')}',
        );
      }

      final response = await ApiBaseHelper.formPost(
        url: ApiRoutes.registerApi,
        useAuthToken: false, // Usually registration doesn't need auth token
        body: data,
      );

      if (kDebugMode) {
        debugPrint('✅ Registration API Response:');
        debugPrint(response.toString());
      }

      return response;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ REGISTRATION FAILED: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Re-throw or handle as needed
      throw Exception('Error occurred during registration: $e');
    }
  }

  Future<MobileAndEmailCheck> checkMobileAndEmail({
    required String type,
    required String value,
    required bool isVerifyUser,
  }) async {
    try {
      Map<String, dynamic> body = {
        'type': type,
        'value': value,
        'verify_flag': isVerifyUser,
      };

      var response = await ApiBaseHelper.post(
        url: ApiRoutes.verifyEmailOrMobileApi,
        body: body,
      );
      return MobileAndEmailCheck.fromJson(response);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      Map<String, dynamic> body = {'email': email};

      var response = await ApiBaseHelper.post(
        url: ApiRoutes.forgetPasswordApi,
        body: body,
      );
      return response;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
