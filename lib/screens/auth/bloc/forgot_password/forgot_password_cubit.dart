import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/auth/repo/auth_repo.dart';
import 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository _authRepository;

  ForgotPasswordCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const ForgotPasswordState());

  Future<void> forgotPassword({required String email}) async {
    emit(state.copyWith(status: ApiStatus.loading));
    try {
      final response = await _authRepository.forgotPassword(email: email);
      if (response['success'] == true) {
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
            errorMessage: response['message'],
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: ApiStatus.failed, errorMessage: e.toString()),
      );
    }
  }
}
