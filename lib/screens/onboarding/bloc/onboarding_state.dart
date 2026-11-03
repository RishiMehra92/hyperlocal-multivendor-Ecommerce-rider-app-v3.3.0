import 'package:equatable/equatable.dart';
import '../model/onboarding_model.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingLoaded extends OnboardingState {
  final bool isEnabled;
  final List<OnboardingScreenItem> screens;
  final bool isFallback;

  const OnboardingLoaded({
    required this.isEnabled,
    required this.screens,
    this.isFallback = false,
  });

  @override
  List<Object?> get props => [isEnabled, screens, isFallback];
}

class OnboardingDisabled extends OnboardingState {
  const OnboardingDisabled();
}

class OnboardingError extends OnboardingState {
  final String message;
  final List<OnboardingScreenItem> fallbackScreens;

  const OnboardingError({
    required this.message,
    required this.fallbackScreens,
  });

  @override
  List<Object?> get props => [message, fallbackScreens];
}
