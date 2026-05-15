// Modelos del bounded context Membership (planes, suscripciones, pagos).

class MembershipPlan {
  final int id;
  final String code;
  final String name;
  final String? description;
  final num priceAmount;
  final String currency;
  final String billingPeriod;
  final bool active;
  final String? stripePriceId;

  const MembershipPlan({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.priceAmount,
    required this.currency,
    required this.billingPeriod,
    required this.active,
    this.stripePriceId,
  });

  factory MembershipPlan.fromJson(Map<String, dynamic> json) => MembershipPlan(
        id: (json['id'] as num).toInt(),
        code: json['code'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        priceAmount: json['priceAmount'] as num,
        currency: json['currency'] as String,
        billingPeriod: json['billingPeriod'] as String,
        active: json['active'] as bool? ?? true,
        stripePriceId: json['stripePriceId'] as String?,
      );
}

class Subscription {
  final int id;
  final int userId;
  final String planCode;
  final String status;
  final DateTime startDate;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelledAt;
  final String? stripeSubscriptionId;

  const Subscription({
    required this.id,
    required this.userId,
    required this.planCode,
    required this.status,
    required this.startDate,
    this.currentPeriodEnd,
    this.cancelledAt,
    this.stripeSubscriptionId,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        planCode: json['planCode'] as String,
        status: json['status'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        currentPeriodEnd: json['currentPeriodEnd'] == null
            ? null
            : DateTime.tryParse(json['currentPeriodEnd'] as String),
        cancelledAt: json['cancelledAt'] == null ? null : DateTime.tryParse(json['cancelledAt'] as String),
        stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
      );
}

class MembershipValidation {
  final int userId;
  final bool active;
  final String? planCode;
  final DateTime? currentPeriodEnd;

  const MembershipValidation({
    required this.userId,
    required this.active,
    this.planCode,
    this.currentPeriodEnd,
  });

  factory MembershipValidation.fromJson(Map<String, dynamic> json) => MembershipValidation(
        userId: (json['userId'] as num).toInt(),
        active: json['active'] as bool? ?? false,
        planCode: json['planCode'] as String?,
        currentPeriodEnd: json['currentPeriodEnd'] == null
            ? null
            : DateTime.tryParse(json['currentPeriodEnd'] as String),
      );
}

class Payment {
  final int id;
  final int userId;
  final int? subscriptionId;
  final num amount;
  final String currency;
  final String status;
  final String? stripePaymentIntentId;
  final String? description;
  final DateTime? processedAt;
  final String? failureReason;

  const Payment({
    required this.id,
    required this.userId,
    this.subscriptionId,
    required this.amount,
    required this.currency,
    required this.status,
    this.stripePaymentIntentId,
    this.description,
    this.processedAt,
    this.failureReason,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        subscriptionId: (json['subscriptionId'] as num?)?.toInt(),
        amount: json['amount'] as num,
        currency: json['currency'] as String,
        status: json['status'] as String,
        stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
        description: json['description'] as String?,
        processedAt: json['processedAt'] == null ? null : DateTime.tryParse(json['processedAt'] as String),
        failureReason: json['failureReason'] as String?,
      );
}

class Invoice {
  final int id;
  final int userId;
  final int? subscriptionId;
  final num amount;
  final String currency;
  final String status;
  final String? stripeInvoiceId;
  final String? hostedInvoiceUrl;
  final DateTime? issuedAt;
  final DateTime? paidAt;

  const Invoice({
    required this.id,
    required this.userId,
    this.subscriptionId,
    required this.amount,
    required this.currency,
    required this.status,
    this.stripeInvoiceId,
    this.hostedInvoiceUrl,
    this.issuedAt,
    this.paidAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        subscriptionId: (json['subscriptionId'] as num?)?.toInt(),
        amount: json['amount'] as num,
        currency: json['currency'] as String,
        status: json['status'] as String,
        stripeInvoiceId: json['stripeInvoiceId'] as String?,
        hostedInvoiceUrl: json['hostedInvoiceUrl'] as String?,
        issuedAt: json['issuedAt'] == null ? null : DateTime.tryParse(json['issuedAt'] as String),
        paidAt: json['paidAt'] == null ? null : DateTime.tryParse(json['paidAt'] as String),
      );
}

class CreateSubscriptionRequest {
  final int userId;
  final String planCode;

  const CreateSubscriptionRequest({required this.userId, required this.planCode});

  Map<String, dynamic> toJson() => {'userId': userId, 'planCode': planCode};
}
