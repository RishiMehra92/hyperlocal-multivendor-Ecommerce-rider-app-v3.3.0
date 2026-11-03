import 'package:hyper_local/config/helper.dart';

class ReferAndEarnModel {
  bool? success;
  String? message;
  ReferAndEarnData? data;

  ReferAndEarnModel({this.success, this.message, this.data});

  ReferAndEarnModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data =
        json['data'] != null ? ReferAndEarnData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class ReferAndEarnData {
  String? referralCode;
  String? friendsCode;
  int? totalReferrals;
  int? totalEarned;
  int? rewarded; // New field
  int? pending; // New field (from your JSON)
  int? pendingEarnings; // Keeping your original field if used elsewhere
  Program? program;

  ReferAndEarnData({
    this.referralCode,
    this.friendsCode,
    this.totalReferrals,
    this.totalEarned,
    this.rewarded,
    this.pending,
    this.pendingEarnings,
    this.program,
  });

  ReferAndEarnData.fromJson(Map<String, dynamic> json) {
    referralCode = parseString(json['referral_code']?.toString());
    friendsCode = parseString(json['friends_code']?.toString());
    totalReferrals = parseInt(json['total_referrals']?.toString());
    totalEarned = parseInt(json['total_earned']?.toString());
    rewarded = parseInt(json['rewarded']?.toString()); // Map new field
    pending = parseInt(json['pending']?.toString()); // Map new field
    pendingEarnings = parseInt(json['pending_earnings']?.toString());
    program =
        json['program'] != null ? Program.fromJson(json['program']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['referral_code'] = referralCode;
    data['friends_code'] = friendsCode;
    data['total_referrals'] = totalReferrals;
    data['total_earned'] = totalEarned;
    data['rewarded'] = rewarded;
    data['pending'] = pending;
    data['pending_earnings'] = pendingEarnings;
    if (program != null) {
      data['program'] = program!.toJson();
    }
    return data;
  }
}

class Program {
  bool? status;
  int? bonusReferral; // New field (int based on your JSON)
  int? bonusReferee; // New field (int based on your JSON)
  String? referrerBonusMethod;
  String? referrerBonusValue;
  String? referrerBonusMaxCap;
  String? refereeBonusMethod;
  String? refereeBonusValue;
  String? refereeBonusMaxCap;
  String? minimumOrderAmount;
  String? maxTimesBonus;

  Program({
    this.status,
    this.bonusReferral,
    this.bonusReferee,
    this.referrerBonusMethod,
    this.referrerBonusValue,
    this.referrerBonusMaxCap,
    this.refereeBonusMethod,
    this.refereeBonusValue,
    this.refereeBonusMaxCap,
    this.minimumOrderAmount,
    this.maxTimesBonus,
  });

  Program.fromJson(Map<String, dynamic> json) {
    status = parseBool(json['status']);
    bonusReferral = parseInt(
      json['bonus_referral']?.toString(),
    ); // Map new field
    bonusReferee = parseInt(json['bonus_referee']?.toString()); // Map new field
    referrerBonusMethod = parseString(json['referrer_bonus_method']);
    referrerBonusValue = parseString(json['referrer_bonus_value']);
    referrerBonusMaxCap = parseString(json['referrer_bonus_max_cap']);
    refereeBonusMethod = parseString(json['referee_bonus_method']);
    refereeBonusValue = parseString(json['referee_bonus_value']);
    refereeBonusMaxCap = parseString(json['referee_bonus_max_cap']);
    minimumOrderAmount = parseString(json['minimum_order_amount']);
    maxTimesBonus = parseString(json['max_times_bonus']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['bonus_referral'] = bonusReferral;
    data['bonus_referee'] = bonusReferee;
    data['referrer_bonus_method'] = referrerBonusMethod;
    data['referrer_bonus_value'] = referrerBonusValue;
    data['referrer_bonus_max_cap'] = referrerBonusMaxCap;
    data['referee_bonus_method'] = refereeBonusMethod;
    data['referee_bonus_value'] = refereeBonusValue;
    data['referee_bonus_max_cap'] = refereeBonusMaxCap;
    data['minimum_order_amount'] = minimumOrderAmount;
    data['max_times_bonus'] = maxTimesBonus;
    return data;
  }
}
