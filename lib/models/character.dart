import 'package:flutter/material.dart';

/// Aves emblemáticas de las cuatro regiones del Ecuador.
enum Character {
  condor,
  piquero,
  tucan,
  colibri,
  guacamayo,
  fragata,
  gallitoRoca,
  curiquingue;

  String get displayName => switch (this) {
        Character.condor => 'Cóndor Andino',
        Character.piquero => 'Piquero Patas Azules',
        Character.tucan => 'Tucán Andino',
        Character.colibri => 'Estrellita Esmeraldeña',
        Character.guacamayo => 'Guacamayo Escarlata',
        Character.fragata => 'Fragata de Galápagos',
        Character.gallitoRoca => 'Gallito de la Peña',
        Character.curiquingue => 'Curiquingue',
      };

  String get region => switch (this) {
        Character.condor => 'Sierra · Andes',
        Character.piquero => 'Costa · Galápagos',
        Character.tucan => 'Sierra · Bosque nublado',
        Character.colibri => 'Costa · Chocó',
        Character.guacamayo => 'Amazonía',
        Character.fragata => 'Región Insular',
        Character.gallitoRoca => 'Andes · Amazonía',
        Character.curiquingue => 'Sierra · Páramo',
      };

  String get description => switch (this) {
        Character.condor => 'Guardián de las cumbres y símbolo de libertad.',
        Character.piquero =>
          'Habitante icónico de las islas con patas azul turquesa.',
        Character.tucan =>
          'Explorador de los bosques húmedos de las estribaciones.',
        Character.colibri =>
          'Pequeña joya endémica del bosque seco de Esmeraldas.',
        Character.guacamayo =>
          'Un destello rojo que recorre la selva amazónica.',
        Character.fragata =>
          'Maestra del viento sobre el archipiélago de Galápagos.',
        Character.gallitoRoca =>
          'Ave de brillante plumaje que vive junto a cascadas.',
        Character.curiquingue =>
          'Caminante curioso de los páramos ecuatorianos.',
      };

  int get price => switch (this) {
        Character.condor => 0,
        Character.piquero => 60,
        Character.tucan => 90,
        Character.colibri => 120,
        Character.guacamayo => 150,
        Character.fragata => 180,
        Character.gallitoRoca => 220,
        Character.curiquingue => 260,
      };

  /// Nivel que debe completarse antes de poder comprar el personaje.
  int get requiredLevel => switch (this) {
        Character.condor => 0,
        Character.piquero => 1,
        Character.tucan => 2,
        Character.colibri => 3,
        Character.guacamayo => 4,
        Character.fragata => 5,
        Character.gallitoRoca => 6,
        Character.curiquingue => 7,
      };

  Color get primaryColor => switch (this) {
        Character.condor => const Color(0xff25343b),
        Character.piquero => const Color(0xfff6f0df),
        Character.tucan => const Color(0xff1c2928),
        Character.colibri => const Color(0xff0f8b72),
        Character.guacamayo => const Color(0xffd94732),
        Character.fragata => const Color(0xff263238),
        Character.gallitoRoca => const Color(0xffef5b35),
        Character.curiquingue => const Color(0xff76543a),
      };

  Color get accentColor => switch (this) {
        Character.condor => const Color(0xfff3efe2),
        Character.piquero => const Color(0xff26a9e0),
        Character.tucan => const Color(0xffffc845),
        Character.colibri => const Color(0xff78d6b1),
        Character.guacamayo => const Color(0xffffc845),
        Character.fragata => const Color(0xffd1493f),
        Character.gallitoRoca => const Color(0xff242d35),
        Character.curiquingue => const Color(0xffffc845),
      };
}
