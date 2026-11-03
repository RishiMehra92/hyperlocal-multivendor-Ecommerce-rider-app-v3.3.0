import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/dashboard/bloc/ratings/ratings_state.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import '../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../utils/widgets/custom_scaffold.dart';
import '../../../utils/widgets/loading_widget.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../config/colors.dart';
import '../../../config/helper.dart';
import '../bloc/ratings/ratings_bloc.dart';
import '../bloc/ratings/ratings_event.dart';
import '../model/ratings_model.dart';

class RatingsPage extends StatefulWidget {
  const RatingsPage({super.key});

  @override
  State<RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends State<RatingsPage> {
  final Map<int, bool> _expandedReviews = {};
  @override
  void initState() {
    super.initState();
    context.read<RatingsBloc>().add(FetchRatings());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBar(title: context.tr('feedback')),
      body: BlocBuilder<RatingsBloc, RatingsState>(
        builder: (context, state) {
          if (state.fetchStatus == ApiStatus.loading) {
            return const Center(child: LoadingWidget());
          } else if (state.fetchStatus == ApiStatus.failed) {
            return EmptyStateWidget.noData(
              onRetry: () {
                context.read<RatingsBloc>().add(FetchRatings());
              },
            );
          } else if (state.fetchStatus == ApiStatus.success &&
              state.feedback != null &&
              state.overallRatings != null) {
            return _buildRatingsContent(context, state);
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_border,
                    size: (isTablet() ? 48 : 64).r,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: context.tr('noReviewsYet'),
                    fontSize: sz(18, seprateTabletSize: 14),
                    color: Colors.grey[600],
                  ),
                  SizedBox(height: 8.h),
                  CustomText(
                    text: context.tr('beFirstToLeaveReview'),
                    fontSize: sz(14, seprateTabletSize: 10),
                    color: Colors.grey[500],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildRatingsContent(BuildContext context, RatingsState state) {
    final feedback = state.feedback!;
    final overallRatings = state.overallRatings!;

    if (feedback.data.feedbackItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: (isTablet() ? 48 : 64).r,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            CustomText(
              text: context.tr('noReviewsYet'),
              fontSize: sz(18, seprateTabletSize: 14),
              color: Colors.grey[600],
            ),
            SizedBox(height: 8.h),
            CustomText(
              text: context.tr('beFirstToLeaveReview'),
              fontSize: sz(14, seprateTabletSize: 10),
              color: Colors.grey[500],
            ),
          ],
        ),
      );
    }

    // Calculate ratings statistics from feedback data if ratings API returns empty data
    final calculatedRatings = _calculateRatingsFromFeedback(
      feedback.data.feedbackItems,
    );
    final ratingsData =
        overallRatings.data.totalReviews > 0
            ? overallRatings.data
            : calculatedRatings;

    return RefreshIndicator(
      onRefresh: () async {
        final completer = Completer<void>();
        context.read<RatingsBloc>().add(RefreshRatings(completer: completer));
        await completer.future;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!state.isFetchingMore &&
              !state.hasReachedMax &&
              isBottom(scrollInfo.metrics)) {
            context.read<RatingsBloc>().add(LoadMoreRatings());
          }
          return false;
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: (isTablet() ? 24 : 18).w),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: Overall Rating + Rating Breakdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Overall Rating Section (Left)
                  _buildOverallRatingSection(ratingsData),
                  SizedBox(height: 16.h),
                  // Rating Breakdown Section (Right)
                  _buildRatingBreakdownSection(ratingsData.ratingsBreakdown),
                ],
              ),
              SizedBox(height: 24.h),

              // User Reviews Section
              _buildUserReviewsSection(feedback.data.feedbackItems),

              // Pagination Loading Indicator
              if (state.isFetchingMore)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: const Center(child: LoadingWidget()),
                ),

              // End of List placeholder padding
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  // Calculate ratings statistics from feedback data when ratings API is empty
  RatingsData _calculateRatingsFromFeedback(
    List<DeliveryFeedback> feedbackList,
  ) {
    if (feedbackList.isEmpty) {
      return RatingsData(
        totalReviews: 0,
        averageRating: 0.0,
        ratingsBreakdown: RatingsBreakdown(
          oneStar: 0,
          twoStar: 0,
          threeStar: 0,
          fourStar: 0,
          fiveStar: 0,
        ),
      );
    }

    final totalReviews = feedbackList.length;
    final totalRating = feedbackList.fold<int>(
      0,
      (sum, feedback) => sum + feedback.rating,
    );
    final averageRating = totalRating / totalReviews;

    // Count ratings by star
    int oneStar = 0, twoStar = 0, threeStar = 0, fourStar = 0, fiveStar = 0;
    for (final feedback in feedbackList) {
      switch (feedback.rating) {
        case 1:
          oneStar++;
          break;
        case 2:
          twoStar++;
          break;
        case 3:
          threeStar++;
          break;
        case 4:
          fourStar++;
          break;
        case 5:
          fiveStar++;
          break;
      }
    }

    return RatingsData(
      totalReviews: totalReviews,
      averageRating: averageRating,
      ratingsBreakdown: RatingsBreakdown(
        oneStar: oneStar,
        twoStar: twoStar,
        threeStar: threeStar,
        fourStar: fourStar,
        fiveStar: fiveStar,
      ),
    );
  }

  Widget _buildOverallRatingSection(RatingsData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title: Overall Rating
        CustomText(
          text: context.tr('overallRating'),
          fontSize: sz(18, seprateTabletSize: 14),
          fontWeight: FontWeight.w600,
          color: Theme.of(
            context,
          ).colorScheme.oppColorChange.withValues(alpha: 0.7),
        ),

        // Large Numerical Rating
        CustomText(
          text: data.averageRating.toStringAsFixed(1),
          fontSize: sz(36, seprateTabletSize: 28),
          fontWeight: FontWeight.bold,
          color: Theme.of(
            context,
          ).colorScheme.oppColorChange.withValues(alpha: 0.7),
        ),

        // Star Rating Display
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(5, (index) {
              if (index < data.averageRating.floor()) {
                return Icon(
                  Icons.star,
                  color: Colors.yellow,
                  size: sz(28, seprateTabletSize: 22).sp,
                );
              } else if (index == data.averageRating.floor() &&
                  data.averageRating % 1 > 0) {
                return Icon(
                  Icons.star_half,
                  color: Colors.yellow,
                  size: sz(28, seprateTabletSize: 22).sp,
                );
              } else {
                return Icon(
                  Icons.star_border,
                  color: Colors.grey[400],
                  size: sz(28, seprateTabletSize: 22).sp,
                );
              }
            }),
          ],
        ),
        SizedBox(height: 20.h),

        // Review Count
        CustomText(
          text: context.tr('basedOnReviews', positionalArgs: [data.totalReviews]),
          fontSize: sz(14, seprateTabletSize: 10),
          color: Theme.of(
            context,
          ).colorScheme.oppColorChange.withValues(alpha: 0.7),
        ),
      ],
    );
  }

  Widget _buildRatingBreakdownSection(RatingsBreakdown breakdown) {
    final totalReviews =
        breakdown.oneStar +
        breakdown.twoStar +
        breakdown.threeStar +
        breakdown.fourStar +
        breakdown.fiveStar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRatingBar(
          context.tr('star5'),
          breakdown.fiveStar,
          totalReviews,
          AppColors.primaryColor,
        ),
        SizedBox(height: 8.h),
        _buildRatingBar(
          context.tr('star4'),
          breakdown.fourStar,
          totalReviews,
          AppColors.primaryColor,
        ),
        SizedBox(height: 8.h),
        _buildRatingBar(
          context.tr('star3'),
          breakdown.threeStar,
          totalReviews,
          AppColors.primaryColor,
        ),
        SizedBox(height: 8.h),
        _buildRatingBar(
          context.tr('star2'),
          breakdown.twoStar,
          totalReviews,
          AppColors.primaryColor,
        ),
        SizedBox(height: 8.h),
        _buildRatingBar(
          context.tr('star1'),
          breakdown.oneStar,
          totalReviews,
          AppColors.primaryColor,
        ),
      ],
    );
  }

  Widget _buildRatingBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;

    return Row(
      children: [
        SizedBox(
          // width: 30.w,
          child: CustomText(
            text: label,
            fontSize: sz(14, seprateTabletSize: 10),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Theme.of(context).colorScheme.ratingColorChange,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: (isTablet() ? 6 : 8).h,

            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        SizedBox(width: 12.w),
        SizedBox(
          width: (isTablet() ? 44 : 50).w,
          child: CustomText(
            text: count.toString(),
            fontSize: sz(14, seprateTabletSize: 10),
            fontWeight: FontWeight.w500,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildUserReviewsSection(List<DeliveryFeedback> feedbackList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),

        // Actual Reviews from API
        ...feedbackList.map(
          (feedback) => Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: _buildReviewCard(feedback),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(DeliveryFeedback feedback) {
    final isExpanded = _expandedReviews[feedback.id] ?? false;
    final description = feedback.description;
    final shouldShowSeeMore = description.length > 100;
    final displayText =
        isExpanded
            ? description
            : (description.length > 100
                ? '${description.substring(0, 100)}...'
                : description);

    return CustomCard(
      padding: EdgeInsets.all((isTablet() ? 10 : 12).w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: (isTablet() ? 18 : 22).r,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.oppColorChange.withValues(alpha: 0.2),
                child:
                    feedback.user.profileImage.isNotEmpty
                        ? CustomAvatar(
                          imageUrl: feedback.user.profileImage,
                          radius: (isTablet() ? 36 : 40).r,
                        )
                        : CustomText(
                          text: feedback.user.name,
                          fontSize: sz(12, seprateTabletSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: feedback.user.name,
                      fontSize: sz(14, seprateTabletSize: 10),
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < feedback.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.primaryColor,
                            size: sz(14, seprateTabletSize: 11).sp,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        CustomText(
                          text: '${feedback.rating}.0',
                          fontSize: sz(13, seprateTabletSize: 10),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: CustomText(
                  text: _formatDate(feedback.createdAt),
                  fontSize: sz(12, seprateTabletSize: 9),
                  color: Colors.grey[500],
                  maxLines: 2,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (feedback.title.isNotEmpty) ...[
            CustomText(
              text: feedback.title,
              fontSize: sz(15, seprateTabletSize: 12),
              fontWeight: FontWeight.w700,
            ),
            SizedBox(height: 8.h),
          ],
          CustomText(
            text: displayText,
            fontSize: sz(14, seprateTabletSize: 10),
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.9),
          ),
          if (shouldShowSeeMore)
            GestureDetector(
              onTap:
                  () => setState(
                    () => _expandedReviews[feedback.id] = !isExpanded,
                  ),
              child: Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: CustomText(
                  text:
                      isExpanded
                          ? context.tr('seeLess')
                          : context.tr('seeMore'),
                  fontSize: sz(14, seprateTabletSize: 10),
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
