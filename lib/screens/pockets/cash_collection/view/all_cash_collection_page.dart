import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import 'package:hyper_local/utils/widgets/loading_widget.dart';
import 'package:hyper_local/utils/currency_formatter.dart';
import 'package:hyper_local/screens/pockets/cash_collection/bloc/cash_collection_bloc.dart';
import 'package:hyper_local/screens/pockets/cash_collection/bloc/cash_collection_event.dart';
import 'package:hyper_local/screens/pockets/cash_collection/bloc/cash_collection_state.dart';
import 'package:hyper_local/screens/pockets/cash_collection/model/cash_collection_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/widgets/toast_message.dart';

import '../../../../config/colors.dart';
import '../../../../config/helper.dart';

class AllCashCollectionPage extends StatefulWidget {
  const AllCashCollectionPage({super.key});

  @override
  State<AllCashCollectionPage> createState() => _AllCashCollectionPageState();
}

class _AllCashCollectionPageState extends State<AllCashCollectionPage>
    with WidgetsBindingObserver {
  CashCollectionResponse? _currentResponse;
  String? _selectedSubmissionStatus;
  String? _selectedDateRange;
  final ScrollController _scrollController = ScrollController();
  bool _wasCurrentRoute = false;
  bool _isSelectionMode = false;
  final Set<int> _selectedCollectionIds = {};

  final List<String> _submissionStatusOptions = [
    'pending',
    'partially_submitted',
    'submitted',
  ];

  final List<String> _dateRangeOptions = [
    'last_30_minutes',
    'last_1_hour',
    'last_5_hours',
    'last_1_day',
    'last_7_days',
    'last_30_days',
    'last_365_days',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
      if (isCurrent) {
        _refreshData();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (isCurrent && !_wasCurrentRoute) {
      _refreshData();
    }
    _wasCurrentRoute = isCurrent;
  }

  void _refreshData() {
    context.read<CashCollectionBloc>().add(
      FetchCashCollectionByDateRange(
        _selectedDateRange ?? 'last_365_days',
        submissionStatus: _selectedSubmissionStatus,
      ),
    );
  }

  void _onScroll() {
    if (isBottom(_scrollController)) {
      context.read<CashCollectionBloc>().add(LoadMoreCashCollection());
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(context),
    );
  }

  Widget _buildFilterBottomSheet(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    // Local state variables initialized from current page state
    String? localSubmissionStatus = _selectedSubmissionStatus;
    String? localDateRange = _selectedDateRange;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        final hasFilters =
            localSubmissionStatus != null || localDateRange != null;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                  width: 45.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

                // Title and Clear All Row
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text:
                            context.tr('filterCashCollections'),
                        fontSize: sz(18, seprateTabletSize: 14),
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      if (hasFilters)
                        GestureDetector(
                          onTap: () {
                            setLocalState(() {
                              localSubmissionStatus = null;
                              localDateRange = null;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: CustomText(
                              text: context.tr('clearAll'),
                              fontSize: sz(12, seprateTabletSize: 10),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.08),
                  height: 16.h,
                ),

                // Submission Status Section
                _buildFilterSection(
                  title: context.tr('submissionStatus'),
                  icon: Icons.fact_check_outlined,
                  options: _submissionStatusOptions,
                  selectedValue: localSubmissionStatus,
                  onChanged: (value) {
                    setLocalState(() {
                      localSubmissionStatus = value;
                    });
                  },
                  displayText: _getStatusDisplayText,
                  isDarkTheme: isDarkTheme,
                ),

                SizedBox(height: 24.h),

                // Date Range Section
                _buildFilterSection(
                  title: context.tr('dateRangeLast'),
                  icon: Icons.calendar_today_rounded,
                  options: _dateRangeOptions,
                  selectedValue: localDateRange,
                  onChanged: (value) {
                    setLocalState(() {
                      localDateRange = value;
                    });
                  },
                  displayText: _getDateRangeDisplayText,
                  isDarkTheme: isDarkTheme,
                ),

                SizedBox(height: 28.h),

                // Action Buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: context.tr('cancel'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          backgroundColor:
                              isDarkTheme
                                  ? const Color(0xFF28282D)
                                  : const Color(0xFFEBEBEB),
                          borderRadius: 12,
                          width: double.infinity,
                          textStyle: TextStyle(
                            fontSize: sz(14, seprateTabletSize: 11).sp,
                            fontWeight: FontWeight.w600,
                            color:
                                isDarkTheme
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.black.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: CustomButton(
                          text: context.tr('apply'),
                          onPressed: () {
                            setState(() {
                              _selectedSubmissionStatus = localSubmissionStatus;
                              _selectedDateRange = localDateRange;
                            });
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          backgroundColor: AppColors.primaryColor,
                          borderRadius: 12,
                          width: double.infinity,
                          textStyle: TextStyle(
                            fontSize: sz(14, seprateTabletSize: 11).sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required List<String> options,
    required String? selectedValue,
    required Function(String?) onChanged,
    required String Function(String) displayText,
    required bool isDarkTheme,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: sz(18, seprateTabletSize: 14).sp,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 8.w),
              CustomText(
                text: title,
                fontSize: sz(14, seprateTabletSize: 11),
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children:
                options.map((option) {
                  final isSelected = selectedValue == option;
                  return GestureDetector(
                    onTap: () => onChanged(isSelected ? null : option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                        horizontal: (isTablet() ? 12 : 14).w,
                        vertical: (isTablet() ? 8 : 10).h,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primaryColor
                                : (isDarkTheme
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primaryColor
                                  : Colors.transparent,
                          width: 1.r,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            text: displayText(option),
                            fontSize: sz(11, seprateTabletSize: 9),
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color:
                                isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                          ),
                          if (isSelected) ...[
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: sz(14, seprateTabletSize: 11).sp,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    // Fetch data with selected filters
    context.read<CashCollectionBloc>().add(
      FetchCashCollectionByDateRange(
        _selectedDateRange ?? '',
        submissionStatus: _selectedSubmissionStatus,
      ),
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return context.tr('pending');
      case 'partially_submitted':
        return context.tr('partiallySubmitted');
      case 'submitted':
        return context.tr('submitted');
      default:
        return context.tr('unknown');
    }
  }

  String _getDateRangeDisplayText(String dateRange) {
    switch (dateRange) {
      case 'last_30_minutes':
        return context.tr('last30Minutes');
      case 'last_1_hour':
        return context.tr('last1Hour');
      case 'last_5_hours':
        return context.tr('last5Hours');
      case 'last_1_day':
        return context.tr('last1Day');
      case 'last_7_days':
        return context.tr('last7Days');
      case 'last_30_days':
        return context.tr('last30Days');
      case 'last_365_days':
        return context.tr('last365Days');
      case 'all':
        return context.tr('all');
      default:
        return context.tr('all');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CashCollectionBloc, CashCollectionState>(
      builder: (context, state) {
        final totalCount = state.response?.data?.total;
        final countText = totalCount != null ? ' ($totalCount)' : '';

        return CustomScaffold(
          appBar: CustomAppBar(
            title:
                _isSelectionMode
                    ? '${_selectedCollectionIds.length} ${context.tr('selected')}'
                    : '${context.tr('cashCollection')}$countText',
            additionalActions: [
              if (_isSelectionMode)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedCollectionIds.clear();
                    });
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondaryColor,
                    size: sz(24, seprateTabletSize: 18).sp,
                  ),
                )
              else ...[
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedSubmissionStatus = 'pending';
                      _selectedCollectionIds.clear();
                      _refreshData();
                    });
                  },
                  icon: Icon(
                    Icons.playlist_add_check_rounded,
                    color: AppColors.textSecondaryColor,
                    size: sz(26, seprateTabletSize: 20).sp,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showFilterBottomSheet(context);
                  },
                  icon: Icon(
                    Icons.filter_list,
                    color: AppColors.textSecondaryColor,
                    size: sz(24, seprateTabletSize: 18).sp,
                  ),
                ),
              ],
            ],
          ),
          floatingActionButton:
              _isSelectionMode && _selectedCollectionIds.isNotEmpty
                  ? FloatingActionButton.extended(
                    onPressed:
                        state.settleStatus == ApiStatus.loading
                            ? null
                            : () {
                              context.read<CashCollectionBloc>().add(
                                SettleOnlineEvent(
                                  _selectedCollectionIds.toList(),
                                ),
                              );
                            },
                    backgroundColor: Colors.green,
                    icon:
                        state.settleStatus == ApiStatus.loading
                            ? SizedBox(
                              width: 18.w,
                              height: 18.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(
                              Icons.payment_rounded,
                              color: Colors.white,
                            ),
                    label: CustomText(
                      text:
                          state.settleStatus == ApiStatus.loading
                              ? context.tr('processing')
                              : '${context.tr('payNow')} (${_selectedCollectionIds.length})',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : null,
          body: RefreshIndicator(
            onRefresh: () async {
              final completer = Completer<void>();
              context.read<CashCollectionBloc>().add(
                FetchCashCollectionByDateRange(
                  _selectedDateRange ?? 'last_365_days',
                  submissionStatus: _selectedSubmissionStatus,
                  completer: completer,
                ),
              );
              await completer.future;
            },

            child: BlocConsumer<CashCollectionBloc, CashCollectionState>(
              listener: (context, state) {
                if (state.settleStatus == ApiStatus.success &&
                    state.checkoutUrl != null) {
                  final uri = Uri.parse(state.checkoutUrl!);
                  final bloc = context.read<CashCollectionBloc>();
                  launchUrl(uri, mode: LaunchMode.externalApplication).then((
                    _,
                  ) {
                    bloc.add(ResetSettleStatusEvent());
                  });
                  setState(() {
                    _isSelectionMode = false;
                    _selectedCollectionIds.clear();
                  });
                } else if (state.settleStatus == ApiStatus.failed &&
                    state.message.isNotEmpty) {
                  ToastManager.show(
                    context: context,
                    message: state.message,
                    type: ToastType.error,
                  );
                  context.read<CashCollectionBloc>().add(
                    ResetSettleStatusEvent(),
                  );
                }
              },
              builder: (context, state) {
                if ((state.fetchStatus == ApiStatus.loading ||
                        state.fetchStatus == ApiStatus.initial) &&
                    state.response == null) {
                  return const Center(child: LoadingWidget());
                } else if (state.fetchStatus == ApiStatus.failed) {
                  return ErrorStateWidget(
                    onRetry: () {
                      context.read<CashCollectionBloc>().add(
                        FetchCashCollectionByDateRange(
                          _selectedDateRange ?? 'last_365_days',
                          submissionStatus: _selectedSubmissionStatus,
                        ),
                      );
                    },
                  );
                  // return _buildErrorState(state.message);
                } else if (state.fetchStatus == ApiStatus.success &&
                    state.response != null) {
                  _currentResponse = state.response;
                  final response = _currentResponse;
                  if (response == null) return _buildEmptyState(isDarkTheme);

                  final cashCollections = response.data?.cashCollections ?? [];

                  // ADD THIS CHECK
                  if (cashCollections.isEmpty) {
                    return _buildEmptyState(isDarkTheme);
                  }

                  return _buildAllCashCollectionList(
                    response,
                    isDarkTheme,
                    state,
                  );
                }
                return _buildEmptyState(isDarkTheme);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllCashCollectionList(
    CashCollectionResponse response,
    bool isDarkTheme,
    CashCollectionState state,
  ) {
    final cashCollections = response.data?.cashCollections ?? [];

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: cashCollections.length + (state.isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == cashCollections.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: const Center(child: LoadingWidget()),
          );
        }
        final collection = cashCollections[index];
        final status = collection.submissionStatus ?? 'pending';
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: GestureDetector(
            onTap:
                _isSelectionMode && collection.id != null && status == 'pending'
                    ? () {
                      setState(() {
                        if (_selectedCollectionIds.contains(collection.id)) {
                          _selectedCollectionIds.remove(collection.id!);
                        } else {
                          _selectedCollectionIds.add(collection.id!);
                        }
                      });
                    }
                    : null,
            child: _buildCashCollectionCard(collection, isDarkTheme, state),
          ),
        );
      },
    );
  }

  Widget _buildCashCollectionCard(
    CashCollectionModel collection,
    bool isDarkTheme,
    CashCollectionState state,
  ) {
    final status = collection.submissionStatus ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusDisplayText(status);

    DateTime? orderDateTime;
    if (collection.orderDate != null) {
      try {
        orderDateTime = DateTime.parse(collection.orderDate!);
      } catch (e) {
        // Ignored
      }
    }
    final formattedOrderDate =
        orderDateTime != null
            ? DateFormat('dd-MMM-yy').format(orderDateTime)
            : (collection.orderDate ?? context.tr('na'));

    return CustomCard(
      borderRadius: 12.r,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Order ID & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                spacing: 5,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: sz(18, seprateTabletSize: 14).sp,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 8.w),
                      CustomText(
                        text:
                            '${context.tr('order')} #${collection.orderId}',
                        fontSize: sz(15, seprateTabletSize: 12),
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                  // Date Row
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: sz(13, seprateTabletSize: 10).sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      SizedBox(width: 6.w),
                      CustomText(
                        text:
                            '${context.tr('date')}: $formattedOrderDate',
                        fontSize: sz(12, seprateTabletSize: 9),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_isSelectionMode &&
                      status == 'pending' &&
                      collection.id != null) ...[
                    Checkbox(
                      value: _selectedCollectionIds.contains(collection.id),
                      activeColor: Colors.green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedCollectionIds.add(collection.id!);
                          } else {
                            _selectedCollectionIds.remove(collection.id!);
                          }
                        });
                      },
                    ),
                    SizedBox(height: 4.h),
                  ],
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sz(10, seprateTabletSize: 8).w,
                      vertical: sz(4, seprateTabletSize: 3).h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.15),
                        width: 1.r,
                      ),
                    ),
                    child: CustomText(
                      text: statusText,
                      fontSize: sz(11, seprateTabletSize: 8),
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  if (!_isSelectionMode &&
                      status == 'pending' &&
                      collection.id != null) ...[
                    SizedBox(height: 6.h),
                    GestureDetector(
                      onTap: () {
                        context.read<CashCollectionBloc>().add(
                          SettleOnlineEvent([collection.id!]),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: sz(10, seprateTabletSize: 8).w,
                          vertical: sz(4, seprateTabletSize: 3).h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.15),
                            width: 1.r,
                          ),
                        ),
                        child:
                            state.settleStatus == ApiStatus.loading &&
                                    state.settleCollectionIds != null &&
                                    state.settleCollectionIds!.contains(
                                      collection.id,
                                    )
                                ? SizedBox(
                                  width: sz(45, seprateTabletSize: 35).w,
                                  height: sz(14, seprateTabletSize: 11).h,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.green,
                                            ),
                                      ),
                                    ),
                                  ),
                                )
                                : CustomText(
                                  text: context.tr('payNow'),
                                  fontSize: sz(11, seprateTabletSize: 8),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          SizedBox(height: 12.h),
          Divider(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.08),
            height: 1.h,
            thickness: 1.h,
          ),
          SizedBox(height: 12.h),

          // Bottom Financial Info Grid (3 Columns)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: context.tr('collected'),
                      fontSize: sz(11, seprateTabletSize: 8),
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: CurrencyFormatter.formatAmount(
                        context,
                        collection.cashCollected ?? '0',
                      ),
                      fontSize: sz(14, seprateTabletSize: 11),
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
              Container(
                height: 28.h,
                width: 1.w,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.08),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: context.tr('submitted'),
                        fontSize: sz(11, seprateTabletSize: 8),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        text: CurrencyFormatter.formatAmount(
                          context,
                          collection.cashSubmitted ?? '0',
                        ),
                        fontSize: sz(14, seprateTabletSize: 11),
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 28.h,
                width: 1.w,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.08),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: context.tr('remaning'),
                        fontSize: sz(11, seprateTabletSize: 8),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        text: CurrencyFormatter.formatAmount(
                          context,
                          collection.remainingAmount ?? '0',
                        ),
                        fontSize: sz(14, seprateTabletSize: 11),
                        fontWeight: FontWeight.w700,
                        color:
                            status == 'submitted'
                                ? Colors.green
                                : AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkTheme) {
    return EmptyStateWidget(
      title: context.tr('noCashCollectionYet'),
      subtitle:
          context.tr('completeDeliveriesToSeeCashCollection'),
      icon: Icons.account_balance_wallet_outlined,
      showRetryButton: false,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'partially_submitted':
        return Colors.blue;
      case 'submitted':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
