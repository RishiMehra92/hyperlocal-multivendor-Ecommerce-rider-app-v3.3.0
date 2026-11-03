import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/helper.dart';
import '../../repo/profile_repo.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepo _profileRepo;

  ProfileBloc(this._profileRepo) : super(const ProfileState()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<DeleteProfileEvent>(_onDeleteProfile);
    on<ResetUpdateStatus>(_onResetUpdateStatus);
  }

  void _onResetUpdateStatus(
    ResetUpdateStatus event,
    Emitter<ProfileState> emit,
  ) {
    emit(
      state.copyWith(
        updateStatus: ApiStatus.initial,
        fetchStatus: ApiStatus.initial,
      ),
    );
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.profile == null) {
      emit(
        state.copyWith(
          fetchStatus: ApiStatus.loading,
          clearMessage: true,
          profile: null,
        ),
      );
    } else {
      emit(state.copyWith(clearMessage: true));
    }
    try {
      final profile = await _profileRepo.getProfile();
      log("Total balance here ${profile.user?.walletBalance}");
      log("Total Blocked  here ${profile.user?.blockedBalance}");
      log("Available balance here ${profile.user?.availableBalance}");
      emit(state.copyWith(fetchStatus: ApiStatus.success, profile: profile));
    } catch (e) {
      if (e.toString().contains('toDouble') ||
          e.toString().contains('NoSuchMethodError')) {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failed,
            message: 'Data format error: Please contact support',
          ),
        );
      } else {
        emit(
          state.copyWith(fetchStatus: ApiStatus.failed, message: e.toString()),
        );
      }
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(state.copyWith(updateStatus: ApiStatus.loading, clearMessage: true));

      final profile = await _profileRepo.updateProfile(
        fullName: event.fullName,
        address: event.address,
        driverLicenseNumber: event.driverLicenseNumber,
        vehicleType: event.vehicleType,
        mobile: event.mobile,
        email: event.email,
        country: event.country,
        driverLicenseFiles: event.driverLicenseFiles,
        vehicleRegistrationFiles: event.vehicleRegistrationFiles,
        profileImageFile: event.profileImageFile,
      );

      emit(
        state.copyWith(
          updateStatus: ApiStatus.success,
          profile: profile,
          message: 'Profile updated successfully',
        ),
      );
      add(const LoadProfile());
    } catch (e) {
      if (e.toString().contains('toDouble') ||
          e.toString().contains('NoSuchMethodError')) {
        emit(
          state.copyWith(
            updateStatus: ApiStatus.failed,
            message: 'Data format error: Please contact support',
          ),
        );
      } else {
        emit(
          state.copyWith(updateStatus: ApiStatus.failed, message: e.toString()),
        );
      }
    }
  }

  Future<void> _onDeleteProfile(
    DeleteProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(
        state.copyWith(deleteApiStatus: ApiStatus.loading, clearMessage: true),
      );

      final data = await _profileRepo.deleteProfileFunc();
      if (data.success == true) {
        emit(
          state.copyWith(
            deleteApiStatus: ApiStatus.success,
            deleteResponse: data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            deleteApiStatus: ApiStatus.failed,
            message: "Failed to delete",
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          deleteApiStatus: ApiStatus.failed,
          message: "Something went wrong",
        ),
      );
    }
  }
}
