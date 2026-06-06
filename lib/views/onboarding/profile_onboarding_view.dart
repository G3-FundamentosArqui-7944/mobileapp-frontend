import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/matchmaking_models.dart';
import '../../data/repositories/profiles_repository.dart';
import '../home/home_view.dart';
import '../matchmaking/coach_search_view.dart';

/// Pantalla post-signup que crea el perfil de matchmaking (atleta o coach).
/// Sin ella, el usuario queda registrado en IAM pero invisible para search/
/// recommendations, así que es bloqueante en el flujo de alta.
class ProfileOnboardingView extends StatefulWidget {
  final AuthenticatedUser user;
  const ProfileOnboardingView({super.key, required this.user});

  @override
  State<ProfileOnboardingView> createState() => _ProfileOnboardingViewState();
}

class _ProfileOnboardingViewState extends State<ProfileOnboardingView> {
  static const _kTrainingLevels = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'ELITE'];
  static const _kGoals = [
    'WEIGHT_LOSS',
    'MUSCLE_GAIN',
    'STRENGTH',
    'ENDURANCE',
    'MOBILITY',
    'GENERAL_FITNESS',
    'COMPETITION_PREP',
  ];
  static const _kSpecialties = [
    'STRENGTH_TRAINING',
    'BODYBUILDING',
    'POWERLIFTING',
    'CALISTHENICS',
    'CROSSFIT',
    'YOGA',
    'MOBILITY',
    'NUTRITION_COACHING',
    'CARDIO',
    'HIIT',
  ];

  // Athlete state
  String _trainingLevel = 'BEGINNER';
  final Set<String> _goals = {};
  final _preferencesCtrl = TextEditingController();

  // Coach state
  final _bioCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController(text: '1');
  final _rateCtrl = TextEditingController(text: '50');
  String _currency = 'PEN';
  final Set<String> _specialties = {};

  bool _saving = false;
  // Mientras chequeamos si el perfil ya existe (rescata el caso donde el primer
  // POST sí completó en el backend pero el Flutter timeoutó esperando la respuesta).
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final asCoach = widget.user.isCoach && !widget.user.isAthlete;
    final repo = context.read<ProfilesRepository>();
    try {
      final existing = asCoach
          ? await repo.getCoachByUserId(widget.user.id)
          : await repo.getAthleteByUserId(widget.user.id);
      if (!mounted) return;
      if (existing != null) {
        _goHome(message: 'Tu perfil ya estaba guardado');
        return;
      }
    } on ApiException {
      // No bloqueamos al usuario por un fallo de lectura; lo dejamos llenar el form.
    }
    if (mounted) setState(() => _checking = false);
  }

  void _goHome({String? message}) {
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeView(user: widget.user)),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _preferencesCtrl.dispose();
    _bioCtrl.dispose();
    _yearsCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final asCoach = widget.user.isCoach && !widget.user.isAthlete;
    if (asCoach) {
      if (_specialties.isEmpty) {
        _snack('Selecciona al menos una especialidad');
        return;
      }
      final years = int.tryParse(_yearsCtrl.text);
      final rate = num.tryParse(_rateCtrl.text);
      if (years == null || years < 0) return _snack('Años de experiencia inválidos');
      if (rate == null || rate < 0) return _snack('Tarifa inválida');
    } else {
      if (_goals.isEmpty) return _snack('Selecciona al menos una meta');
    }

    setState(() => _saving = true);
    try {
      final repo = context.read<ProfilesRepository>();
      if (asCoach) {
        await repo.createCoachProfile(CreateCoachProfileRequest(
          userId: widget.user.id,
          biography: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
          yearsOfExperience: int.parse(_yearsCtrl.text),
          hourlyRate: num.parse(_rateCtrl.text),
          currency: _currency,
          specialties: _specialties.toList(),
        ));
      } else {
        await repo.createAthleteProfile(CreateAthleteProfileRequest(
          userId: widget.user.id,
          trainingLevel: _trainingLevel,
          goals: _goals.toList(),
          preferences: _preferencesCtrl.text.trim().isEmpty ? null : _preferencesCtrl.text.trim(),
        ));
      }
      if (!mounted) return;
      _goHome();
    } on ApiException catch (e) {
      // 409 = el backend ya tenía el perfil (típicamente cuando un POST previo
      // sí persistió pero el cliente timeouteó esperando la respuesta).
      if (e.statusCode == 409 && mounted) {
        _goHome(message: 'Tu perfil ya estaba guardado');
        return;
      }
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asCoach = widget.user.isCoach && !widget.user.isAthlete;
    if (_checking) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu perfil'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text(
              asCoach ? 'Cuéntanos cómo entrenas' : '¿Cuál es tu meta?',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              asCoach
                  ? 'Esto ayuda a los atletas a encontrarte cuando filtran por especialidad y precio.'
                  : 'Esto define las recomendaciones de coach y rutinas que te sugiramos.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            asCoach ? _coachForm() : _athleteForm(),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _athleteForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Nivel de entrenamiento'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _kTrainingLevels.map((level) {
            return ChoiceChip(
              label: Text(_trainingLevelLabel(level)),
              selected: _trainingLevel == level,
              onSelected: (_) => setState(() => _trainingLevel = level),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const _Label('Metas (elige una o más)'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kGoals.map((g) {
            final selected = _goals.contains(g);
            return FilterChip(
              label: Text(_goalLabel(g)),
              selected: selected,
              onSelected: (v) => setState(() {
                if (v) {
                  _goals.add(g);
                } else {
                  _goals.remove(g);
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const _Label('Preferencias (opcional)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _preferencesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Por ejemplo: prefiero entrenar mañanas, gym sin máquinas...',
          ),
        ),
      ],
    );
  }

  Widget _coachForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Especialidades'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kSpecialties.map((s) {
            final selected = _specialties.contains(s);
            return FilterChip(
              label: Text(specialtyLabel(s)),
              selected: selected,
              onSelected: (v) => setState(() {
                if (v) {
                  _specialties.add(s);
                } else {
                  _specialties.remove(s);
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _yearsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Años de experiencia'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Tarifa por hora'),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 88,
              child: DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Moneda'),
                items: const [
                  DropdownMenuItem(value: 'PEN', child: Text('PEN')),
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                ],
                onChanged: (v) => setState(() => _currency = v ?? 'PEN'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _Label('Biografía (opcional)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bioCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Cuenta tu enfoque, certificaciones, atletas con los que has trabajado...',
          ),
        ),
      ],
    );
  }

  String _trainingLevelLabel(String l) {
    switch (l) {
      case 'BEGINNER':
        return 'Principiante';
      case 'INTERMEDIATE':
        return 'Intermedio';
      case 'ADVANCED':
        return 'Avanzado';
      case 'ELITE':
        return 'Élite';
      default:
        return l;
    }
  }

  String _goalLabel(String g) {
    switch (g) {
      case 'WEIGHT_LOSS':
        return 'Bajar de peso';
      case 'MUSCLE_GAIN':
        return 'Ganar músculo';
      case 'STRENGTH':
        return 'Fuerza';
      case 'ENDURANCE':
        return 'Resistencia';
      case 'MOBILITY':
        return 'Movilidad';
      case 'GENERAL_FITNESS':
        return 'Estado general';
      case 'COMPETITION_PREP':
        return 'Competencia';
      default:
        return g;
    }
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );
}
