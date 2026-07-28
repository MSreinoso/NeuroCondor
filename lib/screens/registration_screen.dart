import 'package:flutter/material.dart';

import '../data/local_progress_repository.dart';
import '../models/character.dart';
import '../widgets/character_portrait.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.repository});
  final LocalProgressRepository repository;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool saving = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    await widget.repository.register(controller.text);
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: -110,
              right: -90,
              child: Container(
                width: 290,
                height: 290,
                decoration: const BoxDecoration(
                  color: Color(0xffffd166),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -130,
              left: -100,
              child: Container(
                width: 310,
                height: 310,
                decoration: const BoxDecoration(
                  color: Color(0xffd4ece8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            const CharacterPortrait(
                              character: Character.condor,
                              size: 112,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Neuro Cóndor',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Recorre el Ecuador, entrena tus movimientos y forma una bandada única.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            Form(
                              key: formKey,
                              child: TextFormField(
                                controller: controller,
                                autofocus: true,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre del participante',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().length < 2
                                        ? 'Ingresa al menos 2 caracteres'
                                        : null,
                                onFieldSubmitted: (_) => submit(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: saving ? null : submit,
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: Text(
                                  saving ? 'Guardando…' : 'Comenzar viaje',
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield_outlined, size: 17),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Tus datos se guardan solo en este dispositivo.',
                                    style: TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
