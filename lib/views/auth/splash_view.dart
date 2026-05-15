import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../constants/app_colors.dart';
import '../home/home_view.dart';
import 'sign_in_view.dart';

/// Pantalla inicial: redirige según el estado actual del AuthBloc.
/// - Reacciona a transiciones de estado (BlocListener).
/// - Y revisa el estado actual al montarse, por si ya es terminal cuando llega aquí.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _navigate(context.read<AuthBloc>().state);
    });
  }

  void _navigate(AuthState state) {
    if (state is AuthAuthenticated) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeView(user: state.user)),
        (_) => false,
      );
    } else if (state is AuthUnauthenticated) {
      if (state.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInView()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (context, state) => _navigate(state),
      child: const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, size: 72, color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'BodyMatch',
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'AI fitness coaching',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
