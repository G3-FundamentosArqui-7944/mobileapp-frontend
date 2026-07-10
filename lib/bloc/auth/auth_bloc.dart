import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/api/api_client.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_controller.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  final LocaleController _localeController;

  /// Recibe los `ApiClient` activos (microservicios y monolito) para enganchar
  /// el callback de sesión expirada en todos: cualquier 401 cuyo refresh falle
  /// debe terminar en logout, sin importar qué backend lo devolvió.
  AuthBloc({
    required AuthRepository repository,
    required List<ApiClient> apiClients,
    required LocaleController localeController,
  })  : _repo = repository,
        _localeController = localeController,
        super(const AuthInitial()) {
    on<AuthInitialized>(_onInitialized);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthSessionExpired>(_onSessionExpired);

    for (final client in apiClients) {
      client.onSessionExpired = () => add(const AuthSessionExpired());
    }
  }

  Future<void> _onInitialized(AuthInitialized event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final restored = await _repo.restoreSession();
    if (restored == null) {
      emit(const AuthUnauthenticated());
    } else {
      emit(AuthAuthenticated(restored));
    }
  }

  Future<void> _onSignIn(AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.signIn(SignInRequest(email: event.email, password: event.password));
      emit(AuthAuthenticated(user));
    } on ApiException catch (e) {
      emit(AuthFailure(_friendly(e)));
    }
  }

  Future<void> _onSignUp(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final request = SignUpRequest(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
      );
      final user = event.asCoach
          ? await _repo.signUpCoach(request)
          : await _repo.signUpAthlete(request);
      emit(AuthSignUpSuccess(user));
      // Auto-login para entrar directo al dashboard.
      add(AuthSignInRequested(email: event.email, password: event.password));
    } on ApiException catch (e) {
      emit(AuthFailure(_friendly(e)));
    }
  }

  Future<void> _onSignOut(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await _repo.signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onSessionExpired(AuthSessionExpired event, Emitter<AuthState> emit) async {
    await _repo.signOut();
    emit(AuthUnauthenticated(message: _l10n.auth_sessionExpired));
  }

  AppLocalizations get _l10n => lookupAppLocalizations(_localeController.locale);

  String _friendly(ApiException e) {
    switch (e.statusCode) {
      case 400:
        return _l10n.auth_invalidData;
      case 401:
        return _l10n.auth_invalidCredentials;
      case 404:
        return _l10n.auth_accountNotFound;
      case 409:
        return _l10n.auth_emailAlreadyRegistered;
      default:
        return e.message;
    }
  }
}
