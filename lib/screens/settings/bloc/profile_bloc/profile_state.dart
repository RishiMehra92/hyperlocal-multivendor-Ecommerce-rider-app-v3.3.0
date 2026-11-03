import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import '../../model/profile_model.dart';
import '../../repo/deleteApiStatus.dart';

class ProfileState extends Equatable {
  final ProfileModel? profile;
  final ApiStatus fetchStatus;
  final ApiStatus updateStatus;
  final ApiStatus deleteApiStatus;
  final ApiStatus documentUploadStatus;
  final DeleteAccountResponse? deleteResponse;
  final String message;
  final String documentType;

  const ProfileState({
    this.profile,
    this.fetchStatus = ApiStatus.initial,
    this.updateStatus = ApiStatus.initial,
    this.deleteApiStatus = ApiStatus.initial,
    this.documentUploadStatus = ApiStatus.initial,
    this.deleteResponse,
    this.message = '',
    this.documentType = '',
  });

  ProfileState copyWith({
    ProfileModel? profile,
    ApiStatus? fetchStatus,
    ApiStatus? updateStatus,
    ApiStatus? deleteApiStatus,
    ApiStatus? documentUploadStatus,
    DeleteAccountResponse? deleteResponse,
    String? message,
    String? documentType,
    bool clearMessage = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      fetchStatus: fetchStatus ?? this.fetchStatus,
      updateStatus: updateStatus ?? this.updateStatus,
      deleteApiStatus: deleteApiStatus ?? this.deleteApiStatus,
      documentUploadStatus: documentUploadStatus ?? this.documentUploadStatus,
      deleteResponse: deleteResponse ?? this.deleteResponse,
      message: clearMessage ? '' : (message ?? this.message),
      documentType: documentType ?? this.documentType,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    fetchStatus,
    updateStatus,
    deleteApiStatus,
    documentUploadStatus,
    deleteResponse,
    message,
    documentType,
  ];
}
