import '../api/api_client.dart';
import '../models/matchmaking_models.dart';

class ConnectionRequestsRepository {
  final ApiClient _api;

  ConnectionRequestsRepository({required ApiClient api}) : _api = api;

  Future<ConnectionRequest> request(CreateConnectionRequest req) async {
    final json = await _api.post('/connection-requests', body: req.toJson())
        as Map<String, dynamic>;
    return ConnectionRequest.fromJson(json);
  }

  Future<ConnectionRequest> respond(int requestId, RespondConnectionRequest req) async {
    final json = await _api.put('/connection-requests/$requestId', body: req.toJson())
        as Map<String, dynamic>;
    return ConnectionRequest.fromJson(json);
  }

  Future<List<ConnectionRequest>> byAthlete(int athleteId) async {
    final list = await _api.get('/connection-requests/athlete/$athleteId') as List<dynamic>;
    return list.map((e) => ConnectionRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ConnectionRequest>> byCoach(int coachId) async {
    final list = await _api.get('/connection-requests/coach/$coachId') as List<dynamic>;
    return list.map((e) => ConnectionRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ConnectionRequest>> coachClients(int coachId) async {
    final list = await _api.get('/connection-requests/coach/$coachId/clients') as List<dynamic>;
    return list.map((e) => ConnectionRequest.fromJson(e as Map<String, dynamic>)).toList();
  }
}
