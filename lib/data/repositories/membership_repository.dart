import '../api/api_client.dart';
import '../models/membership_models.dart';

class MembershipRepository {
  final ApiClient _api;

  MembershipRepository({required ApiClient api}) : _api = api;

  // Plans
  Future<List<MembershipPlan>> listPlans({bool onlyActive = true}) async {
    final list = await _api.get('/membership-plans', query: {'onlyActive': onlyActive})
        as List<dynamic>;
    return list.map((e) => MembershipPlan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MembershipPlan> getPlanByCode(String code) async {
    final json = await _api.get('/membership-plans/$code') as Map<String, dynamic>;
    return MembershipPlan.fromJson(json);
  }

  // Subscriptions
  Future<Subscription> subscribe(CreateSubscriptionRequest req) async {
    final json = await _api.post('/subscriptions', body: req.toJson()) as Map<String, dynamic>;
    return Subscription.fromJson(json);
  }

  Future<Subscription> cancel(int subscriptionId) async {
    final json = await _api.delete('/subscriptions/$subscriptionId') as Map<String, dynamic>;
    return Subscription.fromJson(json);
  }

  Future<List<Subscription>> subscriptionsByUser(int userId) async {
    final list = await _api.get('/subscriptions/user/$userId') as List<dynamic>;
    return list.map((e) => Subscription.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MembershipValidation> membershipStatus(int userId) async {
    final json = await _api.get('/subscriptions/user/$userId/membership-status')
        as Map<String, dynamic>;
    return MembershipValidation.fromJson(json);
  }

  // Payments / invoices
  Future<List<Payment>> paymentsByUser(int userId) async {
    final list = await _api.get('/payments/user/$userId') as List<dynamic>;
    return list.map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Invoice>> invoicesByUser(int userId) async {
    final list = await _api.get('/payments/user/$userId/invoices') as List<dynamic>;
    return list.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
  }
}
