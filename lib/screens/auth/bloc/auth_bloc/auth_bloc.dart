import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/auth/repo/auth_repo.dart';
import '../../model/mobile_email_check_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<LoginRequest>(_onLoginRequest);
    on<RegisterRequest>(_onRegisterRequest);
    on<EmailOrMobileNumber>(_onMobileAndEmailCheck);
  }

  Future<void> _onLoginRequest(
    LoginRequest event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: ApiStatus.loading, clearMessage: true));
    try {
      final response = await AuthRepository().login(
        email: event.email,
        password: event.password,
      );
      if (response['success'] == true) {
        final token = response['data']['access_token'].toString();

        await Global.setUserToken(token);

        emit(
          state.copyWith(
            status: ApiStatus.success,
            message: response['message'],
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: response['message'],
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: ApiStatus.failed, message: e.toString()));
    }
  }

  Future<void> _onMobileAndEmailCheck(
    EmailOrMobileNumber event,
    Emitter<AuthState> emit,
  ) async {
    final isMobile = event.type == 'mobile';
    try {
      // 1. Emit loading status for the corresponding field
      emit(
        state.copyWith(
          mobileANdEmailStatus:
              isMobile
                  ? MobileANdEmailStatus.loading
                  : state.mobileANdEmailStatus,
          emailStatus:
              !isMobile ? MobileANdEmailStatus.loading : state.emailStatus,
          status: ApiStatus.initial,
        ),
      );
      // 2. Call the shared repository API verification logic
      MobileAndEmailCheck response = await AuthRepository().checkMobileAndEmail(
        type: event.type,
        value: event.value,
        isVerifyUser: false,
      );
      // 3. Emit response status
      if (response.data != null) {
        if (response.data!.exists == true) {
          emit(
            state.copyWith(
              mobileANdEmailStatus:
                  isMobile
                      ? MobileANdEmailStatus.isuse
                      : state.mobileANdEmailStatus,
              emailStatus:
                  !isMobile ? MobileANdEmailStatus.isuse : state.emailStatus,
            ),
          );
        } else {
          emit(
            state.copyWith(
              mobileANdEmailStatus:
                  isMobile
                      ? MobileANdEmailStatus.isnew
                      : state.mobileANdEmailStatus,
              emailStatus:
                  !isMobile ? MobileANdEmailStatus.isnew : state.emailStatus,
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            mobileANdEmailStatus:
                isMobile
                    ? MobileANdEmailStatus.isuse
                    : state.mobileANdEmailStatus,
            emailStatus:
                !isMobile ? MobileANdEmailStatus.isuse : state.emailStatus,
          ),
        );
      }
    } catch (stack) {
      emit(
        state.copyWith(
          mobileANdEmailStatus:
              isMobile
                  ? MobileANdEmailStatus.isuse
                  : state.mobileANdEmailStatus,
          emailStatus:
              !isMobile ? MobileANdEmailStatus.isuse : state.emailStatus,
        ),
      );
    }
  }

  Future<void> _onRegisterRequest(
    RegisterRequest event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: ApiStatus.loading, clearMessage: true));
    try {
      // Map<String, dynamic> response = {};
      final response = await AuthRepository().register(
        name: event.name,
        email: event.email,
        mobile: event.mobile,
        password: event.password,
        confirmPassword: event.confirmPassword,
        address: event.address,
        driverLicenseNumber: event.driverLicenseNumber,
        vehicleType: event.vehicleType,
        deliveryZoneId: event.deliveryZoneId,
        driverLicenseFiles: event.driverLicenseFiles ?? [], // List<File>
        vehicleRegistrationFiles:
            event.vehicleRegistrationFiles ?? [], // List<File>
        country: event.country,
        countryCode: event.countryCode,
        iso2: event.iso2,
        friends_code: event.referCode,
      );

      if (response['success'] == true) {
        final token = response['access_token'].toString();

        await Global.setUserToken(token);

        emit(
          state.copyWith(
            status: ApiStatus.success,
            message: response['message'],
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: response['message'],
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: ApiStatus.failed, message: e.toString()));
    }
  }
}
