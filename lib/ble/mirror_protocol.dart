enum MirrorHandState { stopped, open, closed }

MirrorHandState? parseMirrorControl(String value) => switch (value.trim()) {
      '1' => MirrorHandState.open,
      '0' => MirrorHandState.closed,
      _ => null,
    };

extension MirrorHandStateData on MirrorHandState {
  String get label => switch (this) {
        MirrorHandState.stopped => 'Actuadores detenidos',
        MirrorHandState.open => 'Control 1 · mano abierta · cargando',
        MirrorHandState.closed => 'Control 0 · mano cerrada · salto',
      };
}
