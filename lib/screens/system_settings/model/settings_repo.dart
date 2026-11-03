import 'package:hyper_local/utils/services/json_parser.dart';

const String modelName = 'settings_model';

class SettingsResponse {
  bool? success;
  String? message;
  SettingsModel? data;

  SettingsResponse({this.success, this.message, this.data});

  factory SettingsResponse.fromJson(Map<String, dynamic> json) {
    return SettingsResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data:
          json['data'] != null
              ? SettingsModel.fromJson(json['data'] as Map<String, dynamic>)
              : null,
    );
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

class SettingsModel {
  List<SettingItem>? data;

  SettingsModel({this.data});

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    // The API sometimes returns 'data' as List and sometimes as Map (especially for currency/system settings)
    if (json['data'] is List) {
      return SettingsModel(
        data: JsonParser.list<SettingItem>(
          json['data'],
          (v) => SettingItem.fromJson(v as Map<String, dynamic>),
        ),
      );
    } else if (json['data'] is Map<String, dynamic>) {
      // Handle case where 'data' is a direct Map (currency/system settings)
      final systemData = json['data'] as Map<String, dynamic>;
      final item = SettingItem(
        variable: 'system',
        value: Value.fromJson(systemData),
      );
      return SettingsModel(data: [item]);
    } else if (json['variable'] != null) {
      return SettingsModel(data: [SettingItem.fromJson(json)]);
    }

    return SettingsModel(data: []);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  // Helper methods (kept your original logic)
  SettingItem? get deliveryBoySettings {
    return data?.cast<SettingItem?>().firstWhere(
      (item) => item?.variable == 'delivery_boy',
      orElse: () => null,
    );
  }

  SettingItem? get systemSettings {
    return data?.cast<SettingItem?>().firstWhere(
      (item) => item?.variable == 'system',
      orElse: () => null,
    );
  }

  String? get currencySymbol => systemSettings?.value?.currencySymbol;
  String? get currency => systemSettings?.value?.currency;
  String? get termsCondition => deliveryBoySettings?.value?.termsCondition;
  String? get privacyPolicy => deliveryBoySettings?.value?.privacyPolicy;
  bool? get referStatus =>
      deliveryBoySettings?.value?.deliveryBoyReferEarnStatus;
  bool? get cashCollectionLimitStatus =>
      deliveryBoySettings?.value?.cashCollectionLimitStatus;
  String? get cashCollectionLimitAmount =>
      deliveryBoySettings?.value?.cashCollectionLimitAmount;

  bool get isCustomSmsEnabled {
    final authItem = data?.cast<SettingItem?>().firstWhere(
      (item) => item?.variable == 'authentication',
      orElse: () => null,
    );
    return authItem?.value?.customSms ?? false;
  }

  String? get customSmsUrl {
    final authItem = data?.cast<SettingItem?>().firstWhere(
      (item) => item?.variable == 'authentication',
      orElse: () => null,
    );
    return authItem?.value?.customSmsUrl;
  }

  String? get customSmsMethod {
    final authItem = data?.cast<SettingItem?>().firstWhere(
      (item) => item?.variable == 'authentication',
      orElse: () => null,
    );
    return authItem?.value?.customSmsMethod;
  }

  String? get smsGateway {
    final authItem = data?.cast<SettingItem?>().firstWhere(
      (item) => item?.variable == 'authentication',
      orElse: () => null,
    );
    return authItem?.value?.smsGateway;
  }

  SettingItem? get appSettings {
    return data?.cast<SettingItem?>().firstWhere(
      (item) => item?.variable == 'app',
      orElse: () => null,
    );
  }

  String? get customerAppstoreLink => appSettings?.value?.customerAppstoreLink;
  String? get customerPlaystoreLink =>
      appSettings?.value?.customerPlaystoreLink;
  String? get customerAppScheme => appSettings?.value?.customerAppScheme;
  String? get sellerAppstoreLink => appSettings?.value?.sellerAppstoreLink;
  String? get sellerPlaystoreLink => appSettings?.value?.sellerPlaystoreLink;
  String? get sellerAppScheme => appSettings?.value?.sellerAppScheme;
  String? get riderAppstoreLink => appSettings?.value?.riderAppstoreLink;
  String? get riderPlaystoreLink => appSettings?.value?.riderPlaystoreLink;
}

class SettingItem {
  String? variable;
  Value? value;

  SettingItem({this.variable, this.value});

  factory SettingItem.fromJson(Map<String, dynamic> json) {
    return SettingItem(
      variable: JsonParser.string(json['variable']),
      value:
          json['value'] != null
              ? Value.fromJson(json['value'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['variable'] = variable;
    if (value != null) {
      data['value'] = value!.toJson();
    }
    return data;
  }
}

class Value {
  String? appName;
  String? sellerSupportNumber;
  String? sellerSupportEmail;
  String? systemTimezone;
  String? copyrightDetails;
  String? logo;
  String? favicon;
  bool? enableThirdPartyStoreSync;
  bool? shopify;
  bool? woocommerce;
  bool? etsy;
  int? minimumCartAmount;
  int? maximumItemsAllowedInCart;
  String? lowStockLimit;
  String? maximumDistanceToNearestStore;
  bool? enableWallet;
  int? welcomeWalletBalanceAmount;
  bool? sellerAppMaintenanceMode;
  String? sellerAppMaintenanceMessage;
  bool? webMaintenanceMode;
  String? webMaintenanceMessage;
  bool? demoMode;
  String? adminDemoModeMessage;
  String? sellerDemoModeMessage;
  String? customerDemoModeMessage;
  String? customerLocationDemoModeMessage;
  String? deliveryBoyDemoModeMessage;
  bool? referEarnStatus;
  String? referEarnMethodUser;
  String? referEarnBonusUser;
  String? referEarnMaximumBonusAmountUser;
  String? referEarnMethodReferral;
  String? referEarnBonusReferral;
  String? referEarnMaximumBonusAmountReferral;
  String? referEarnMinimumOrderAmount;
  String? referEarnNumberOfTimesBonus;
  String? currency;
  String? currencySymbol;
  bool? customSms;
  String? customSmsUrl;
  String? customSmsMethod;
  String? smsGateway;

  // Web / Delivery Boy settings
  String? returnRefundPolicy;
  String? privacyPolicy;
  String? termsCondition;
  bool? deliveryBoyReferEarnStatus;
  String? deliveryBoyReferEarnBonusReferral;
  String? deliveryBoyReferEarnBonusReferee;
  bool? cashCollectionLimitStatus;
  String? cashCollectionLimitAmount;

  ////
  String? customerAppstoreLink;
  String? customerPlaystoreLink;
  String? customerAppScheme;
  String? sellerAppstoreLink;
  String? sellerPlaystoreLink;
  String? sellerAppScheme;
  String? riderAppstoreLink;
  String? riderPlaystoreLink;

  Value({
    this.appName,
    this.sellerSupportNumber,
    this.sellerSupportEmail,
    this.systemTimezone,
    this.copyrightDetails,
    this.logo,
    this.favicon,
    this.enableThirdPartyStoreSync,
    this.shopify,
    this.woocommerce,
    this.etsy,
    this.minimumCartAmount,
    this.maximumItemsAllowedInCart,
    this.lowStockLimit,
    this.maximumDistanceToNearestStore,
    this.enableWallet,
    this.welcomeWalletBalanceAmount,
    this.sellerAppMaintenanceMode,
    this.sellerAppMaintenanceMessage,
    this.webMaintenanceMode,
    this.webMaintenanceMessage,
    this.demoMode,
    this.adminDemoModeMessage,
    this.sellerDemoModeMessage,
    this.customerDemoModeMessage,
    this.customerLocationDemoModeMessage,
    this.deliveryBoyDemoModeMessage,
    this.referEarnStatus,
    this.referEarnMethodUser,
    this.referEarnBonusUser,
    this.referEarnMaximumBonusAmountUser,
    this.referEarnMethodReferral,
    this.referEarnBonusReferral,
    this.referEarnMaximumBonusAmountReferral,
    this.referEarnMinimumOrderAmount,
    this.referEarnNumberOfTimesBonus,
    this.currency,
    this.currencySymbol,
    this.customSms,
    this.customSmsUrl,
    this.customSmsMethod,
    this.smsGateway,
    this.returnRefundPolicy,
    this.privacyPolicy,
    this.termsCondition,
    this.deliveryBoyReferEarnStatus,
    this.deliveryBoyReferEarnBonusReferral,
    this.deliveryBoyReferEarnBonusReferee,
    this.cashCollectionLimitStatus,
    this.cashCollectionLimitAmount,

    this.customerAppstoreLink,
    this.customerPlaystoreLink,
    this.customerAppScheme,
    this.sellerAppstoreLink,
    this.sellerPlaystoreLink,
    this.sellerAppScheme,
    this.riderAppstoreLink,
    this.riderPlaystoreLink,
  });

  factory Value.fromJson(Map<String, dynamic> json) {
    return Value(
      appName: JsonParser.string(json['appName']),
      sellerSupportNumber: JsonParser.string(json['sellerSupportNumber']),
      sellerSupportEmail: JsonParser.string(json['sellerSupportEmail']),
      systemTimezone: JsonParser.string(json['systemTimezone']),
      copyrightDetails: JsonParser.string(json['copyrightDetails']),
      logo: JsonParser.string(json['logo']),
      favicon: JsonParser.string(json['favicon']),
      enableThirdPartyStoreSync: JsonParser.boolValue(
        json['enableThirdPartyStoreSync'],
      ),
      shopify: JsonParser.boolValue(json['Shopify']),
      woocommerce: JsonParser.boolValue(json['Woocommerce']),
      etsy: JsonParser.boolValue(json['etsy']),
      minimumCartAmount: JsonParser.intValue(json['minimumCartAmount']),
      maximumItemsAllowedInCart: JsonParser.intValue(
        json['maximumItemsAllowedInCart'],
      ),
      lowStockLimit: JsonParser.string(json['lowStockLimit']),
      maximumDistanceToNearestStore: JsonParser.string(
        json['maximumDistanceToNearestStore'],
      ),
      enableWallet: JsonParser.boolValue(json['enableWallet']),
      welcomeWalletBalanceAmount: JsonParser.intValue(
        json['welcomeWalletBalanceAmount'],
      ),
      sellerAppMaintenanceMode: JsonParser.boolValue(
        json['sellerAppMaintenanceMode'],
      ),
      sellerAppMaintenanceMessage: JsonParser.string(
        json['sellerAppMaintenanceMessage'],
      ),
      webMaintenanceMode: JsonParser.boolValue(json['webMaintenanceMode']),
      webMaintenanceMessage: JsonParser.string(json['webMaintenanceMessage']),
      demoMode: JsonParser.boolValue(json['demoMode']),
      adminDemoModeMessage: JsonParser.string(json['adminDemoModeMessage']),
      sellerDemoModeMessage: JsonParser.string(json['sellerDemoModeMessage']),
      customerDemoModeMessage: JsonParser.string(
        json['customerDemoModeMessage'],
      ),
      customerLocationDemoModeMessage: JsonParser.string(
        json['customerLocationDemoModeMessage'],
      ),
      deliveryBoyDemoModeMessage: JsonParser.string(
        json['deliveryBoyDemoModeMessage'],
      ),
      referEarnStatus: JsonParser.boolValue(json['referEarnStatus']),
      referEarnMethodUser: JsonParser.string(json['referEarnMethodUser']),
      referEarnBonusUser: JsonParser.string(json['referEarnBonusUser']),
      referEarnMaximumBonusAmountUser: JsonParser.string(
        json['referEarnMaximumBonusAmountUser'],
      ),
      referEarnMethodReferral: JsonParser.string(
        json['referEarnMethodReferral'],
      ),
      referEarnBonusReferral: JsonParser.string(json['referEarnBonusReferral']),
      referEarnMaximumBonusAmountReferral: JsonParser.string(
        json['referEarnMaximumBonusAmountReferral'],
      ),
      referEarnMinimumOrderAmount: JsonParser.string(
        json['referEarnMinimumOrderAmount'],
      ),
      referEarnNumberOfTimesBonus: JsonParser.string(
        json['referEarnNumberOfTimesBonus'],
      ),
      currency: JsonParser.string(json['currency']),
      currencySymbol: JsonParser.string(json['currencySymbol']),
      customSms: JsonParser.boolValue(json['customSms']),
      customSmsUrl: JsonParser.string(json['customSmsUrl']),
      customSmsMethod: JsonParser.string(json['customSmsMethod']),
      smsGateway: JsonParser.string(json['smsGateway']),
      returnRefundPolicy: JsonParser.string(json['returnRefundPolicy']),
      deliveryBoyReferEarnStatus: JsonParser.boolValue(
        json["deliveryBoyReferEarnStatus"],
      ),
      deliveryBoyReferEarnBonusReferral: JsonParser.string(
        json["deliveryBoyReferEarnBonusReferral"],
      ),
      deliveryBoyReferEarnBonusReferee: JsonParser.string(
        json["deliveryBoyReferEarnBonusReferee"],
      ),
      cashCollectionLimitStatus: JsonParser.boolValue(
        json["cashCollectionLimitStatus"],
      ),
      cashCollectionLimitAmount: JsonParser.string(
        json["cashCollectionLimitAmount"],
      ),
      privacyPolicy: JsonParser.string(json['privacyPolicy']),
      termsCondition: JsonParser.string(json['termsCondition']),

      customerAppstoreLink: JsonParser.string(json['customerAppstoreLink']),
      customerPlaystoreLink: JsonParser.string(json['customerPlaystoreLink']),
      customerAppScheme: JsonParser.string(json['customerAppScheme']),
      sellerAppstoreLink: JsonParser.string(json['sellerAppstoreLink']),
      sellerPlaystoreLink: JsonParser.string(json['sellerPlaystoreLink']),
      sellerAppScheme: JsonParser.string(json['sellerAppScheme']),
      riderAppstoreLink: JsonParser.string(json['riderAppstoreLink']),
      riderPlaystoreLink: JsonParser.string(json['riderPlaystoreLink']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['appName'] = appName;
    data['sellerSupportNumber'] = sellerSupportNumber;
    data['sellerSupportEmail'] = sellerSupportEmail;
    data['systemTimezone'] = systemTimezone;
    data['copyrightDetails'] = copyrightDetails;
    data['logo'] = logo;
    data['favicon'] = favicon;
    data['enableThirdPartyStoreSync'] = enableThirdPartyStoreSync;
    data['Shopify'] = shopify;
    data['Woocommerce'] = woocommerce;
    data['etsy'] = etsy;
    data['minimumCartAmount'] = minimumCartAmount;
    data['maximumItemsAllowedInCart'] = maximumItemsAllowedInCart;
    data['lowStockLimit'] = lowStockLimit;
    data['maximumDistanceToNearestStore'] = maximumDistanceToNearestStore;
    data['enableWallet'] = enableWallet;
    data['welcomeWalletBalanceAmount'] = welcomeWalletBalanceAmount;
    data['sellerAppMaintenanceMode'] = sellerAppMaintenanceMode;
    data['sellerAppMaintenanceMessage'] = sellerAppMaintenanceMessage;
    data['webMaintenanceMode'] = webMaintenanceMode;
    data['webMaintenanceMessage'] = webMaintenanceMessage;
    data['demoMode'] = demoMode;
    data['adminDemoModeMessage'] = adminDemoModeMessage;
    data['sellerDemoModeMessage'] = sellerDemoModeMessage;
    data['customerDemoModeMessage'] = customerDemoModeMessage;
    data['customerLocationDemoModeMessage'] = customerLocationDemoModeMessage;
    data['deliveryBoyDemoModeMessage'] = deliveryBoyDemoModeMessage;
    data['referEarnStatus'] = referEarnStatus;
    data['referEarnMethodUser'] = referEarnMethodUser;
    data['referEarnBonusUser'] = referEarnBonusUser;
    data['referEarnMaximumBonusAmountUser'] = referEarnMaximumBonusAmountUser;
    data['referEarnMethodReferral'] = referEarnMethodReferral;
    data['referEarnBonusReferral'] = referEarnBonusReferral;
    data['referEarnMaximumBonusAmountReferral'] =
        referEarnMaximumBonusAmountReferral;
    data['referEarnMinimumOrderAmount'] = referEarnMinimumOrderAmount;
    data['referEarnNumberOfTimesBonus'] = referEarnNumberOfTimesBonus;
    data['currency'] = currency;
    data['currencySymbol'] = currencySymbol;
    data['customSms'] = customSms;
    data['customSmsUrl'] = customSmsUrl;
    data['customSmsMethod'] = customSmsMethod;
    data['smsGateway'] = smsGateway;
    data['returnRefundPolicy'] = returnRefundPolicy;
    data['deliveryBoyReferEarnStatus'] = deliveryBoyReferEarnStatus;
    data['deliveryBoyReferEarnBonusReferral'] =
        deliveryBoyReferEarnBonusReferral;
    data['deliveryBoyReferEarnBonusReferee'] = deliveryBoyReferEarnBonusReferee;
    data['cashCollectionLimitStatus'] = cashCollectionLimitStatus;
    data['cashCollectionLimitAmount'] = cashCollectionLimitAmount;
    data['privacyPolicy'] = privacyPolicy;
    data['termsCondition'] = termsCondition;

    data['customerAppstoreLink'] = customerAppstoreLink;
    data['customerPlaystoreLink'] = customerPlaystoreLink;
    data['customerAppScheme'] = customerAppScheme;
    data['sellerAppstoreLink'] = sellerAppstoreLink;
    data['sellerPlaystoreLink'] = sellerPlaystoreLink;
    data['sellerAppScheme'] = sellerAppScheme;
    data['riderAppstoreLink'] = riderAppstoreLink;
    data['riderPlaystoreLink'] = riderPlaystoreLink;
    return data;
  }
}
