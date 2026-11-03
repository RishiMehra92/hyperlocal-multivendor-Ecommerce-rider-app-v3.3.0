import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/error_message_code.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/screens/auth/model/phone_auth_response_model.dart';

class PhoneAuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Dio _dio = Dio();

  int? _resendToken;

  /// Send OTP to the provided phone number
  Future<Map<String, dynamic>> sendOTP({
    required String phoneNumber,
    bool isCustomSms = false,
  }) async {
    final customSmsFlag = isCustomSms || Global.isCustomSmsEnabled;
    if (customSmsFlag) {
      try {
        if (kDebugMode) {
          debugPrint('📤 Sending Custom OTP to: $phoneNumber');
          debugPrint('URL: ${ApiRoutes.customSendOtpApi}');
        }

        final response = await _dio.post(
          ApiRoutes.customSendOtpApi,
          data: {'mobile': phoneNumber},
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        if (kDebugMode) {
          debugPrint('✅ Custom OTP Sent successfully');
          debugPrint('Response: ${response.data}');
        }

        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP sent successfully',
          'verificationId':
              phoneNumber, // Using phone number as verificationId for custom SMS
          'autoVerified': false,
        };
      } on DioException catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Custom OTP Send failed: ${e.message}');
          debugPrint('Response: ${e.response?.data}');
        }
        String errorMessage = 'Failed to send OTP';
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }
        throw Exception(errorMessage);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error sending custom OTP: $e');
        }
        throw Exception('Error sending custom OTP: $e');
      }
    }

    final completer = Completer<Map<String, dynamic>>();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (kDebugMode) {
            debugPrint('✅ Phone verification completed automatically');
          }
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'message': 'Phone verified automatically',
              'verificationId': null,
              'credential': credential,
              'autoVerified': true,
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) {
            debugPrint('❌ Phone verification failed: ${e.message}');
          }
          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'The phone number is invalid';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later';
          } else {
            errorMessage = e.message ?? 'Verification failed';
          }
          if (!completer.isCompleted) {
            completer.completeError(errorMessage);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (kDebugMode) {
            debugPrint(
              '✅ OTP sent successfully. Verification ID: $verificationId',
            );
          }
          _resendToken = resendToken;
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'message': 'OTP sent successfully',
              'verificationId': verificationId,
              'resendToken': resendToken,
              'autoVerified': false,
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (kDebugMode) {
            debugPrint('⏱️ Code auto retrieval timeout');
          }
          // Don't complete here, just log
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );

      return await completer.future;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending OTP: $e');
      }
      throw Exception('Error sending OTP: $e');
    }
  }

  /// Verify OTP and get Firebase ID Token
  Future<Map<String, dynamic>> verifyOTP({
    required String verificationId,
    required String otp,
    bool isCustomSms = false,
  }) async {
    final customSmsFlag = isCustomSms || Global.isCustomSmsEnabled;
    if (customSmsFlag) {
      try {
        if (kDebugMode) {
          debugPrint('📤 Verifying Custom OTP');
          debugPrint('URL: ${ApiRoutes.customVerifyOtpApi}');
        }

        final Map<String, dynamic> requestBody = {
          'mobile':
              verificationId, // verificationId is phone number for custom SMS
          'otp': otp,
        };

        final response = await _dio.post(
          ApiRoutes.customVerifyOtpApi,
          data: requestBody,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        if (kDebugMode) {
          debugPrint('✅ Custom OTP Verified successfully');
          debugPrint('Response: ${response.data}');
        }

        if (response.data['success'] == true) {
          final authModel = PhoneAuthResponseModel.fromJson(
            response.data is Map<String, dynamic>
                ? response.data as Map<String, dynamic>
                : {},
          );
          final accessToken = authModel.accessToken ?? '';

          if (kDebugMode) {
            debugPrint(
              '🔑 Extracted Access Token for Custom SMS: $accessToken',
            );
          }

          return {
            'success': true,
            'message': response.data['message'] ?? 'OTP verified successfully',
            'accessToken': accessToken,
          };
        } else {
          throw Exception(
            response.data['message'] ?? 'OTP verification failed',
          );
        }
      } on DioException catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Custom OTP Verification failed: ${e.message}');
          debugPrint('Response: ${e.response?.data}');
        }
        String errorMessage = 'Invalid OTP';
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }
        throw Exception(errorMessage);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error verifying custom OTP: $e');
        }
        throw Exception('Error verifying custom OTP: $e');
      }
    }

    try {
      // Create credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Sign in with credential
      UserCredential userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      // Get ID Token
      String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception('Failed to get ID token');
      }

      if (kDebugMode) {
        debugPrint('✅ OTP verified successfully');
        debugPrint('ID Token: $idToken');
      }

      return {
        'success': true,
        'message': 'OTP verified successfully',
        'idToken': idToken,
      };
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ OTP verification failed: ${e.message}');
      }
      String errorMessage = 'Invalid OTP';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid OTP code';
      } else if (e.code == 'session-expired') {
        errorMessage = 'OTP expired. Please request a new one';
      } else {
        errorMessage = e.message ?? 'OTP verification failed';
      }
      throw Exception(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error verifying OTP: $e');
      }
      throw Exception('Error verifying OTP: $e');
    }
  }

  Future<PhoneAuthResponseModel> sendIdTokenToBackend({
    required String idToken,
  }) async {
    try {
      const String apiUrl = ApiRoutes.phoneCallbackApi;

      if (kDebugMode) {
        debugPrint('📤 Sending ID Token to backend');
        debugPrint('URL: $apiUrl');
        debugPrint('ID Token: $idToken');
      }

      final response = await _dio.post(
        apiUrl,
        data: {'idToken': idToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        ),
      );

      if (kDebugMode) {
        debugPrint('✅ Backend API Response:');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Data: ${response.data}');
      }

      // Handle only 200 as success — everything else is error
      if (response.statusCode != 200) {
        final msg =
            (response.data is Map && response.data['message'] != null)
                ? response.data['message']
                : 'Backend returned status ${response.statusCode}';
        throw Exception(msg);
      }

      final rawData = response.data;
      if (rawData is! Map<String, dynamic>) {
        throw Exception('Invalid response format (not a map)');
      }

      final model = PhoneAuthResponseModel.fromJson(rawData);

      // Backend returned 200 but with success: false (e.g. "User not found")
      // Throw a typed exception so the BLoC can handle navigation
      if (!model.success) {
        throw UserNotFoundException(
          model.message.isNotEmpty ? model.message : 'User not found',
        );
      }

      return model;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ DioException: ${e.message}');
        debugPrint('Response: ${e.response?.data}');
      }

      String errorMessage = 'Failed to authenticate';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      } else if (e.error is SocketException) {
        errorMessage = ErrorMessageKeysAndCode.noInternetCode;
      }
      throw Exception(errorMessage);
    } on UserNotFoundException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Unexpected error: $e');
      }
      if (e is UserNotFoundException) rethrow;
      throw Exception('Error sending token to backend: $e');
    }
  }

  /// Resend OTP
  Future<Map<String, dynamic>> resendOTP({
    required String phoneNumber,
    bool isCustomSms = false,
  }) async {
    return await sendOTP(phoneNumber: phoneNumber, isCustomSms: isCustomSms);
  }

  /// Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

/// Thrown when the backend confirms the phone is valid but no account exists yet.
/// The BLoC catches this to redirect the user to the registration page.
class UserNotFoundException implements Exception {
  final String message;
  const UserNotFoundException(this.message);

  @override
  String toString() => message;
}
