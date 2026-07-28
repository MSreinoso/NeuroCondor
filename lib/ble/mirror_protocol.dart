enum MirrorHandState { stopped, open, closed }

extension MirrorHandStateData on MirrorHandState {
  String get command => switch (this) {
        MirrorHandState.stopped => 'M,2',
        MirrorHandState.open => 'M,0',
        MirrorHandState.closed => 'M,1',
      };

  String get label => switch (this) {
        MirrorHandState.stopped => 'Actuadores detenidos',
        MirrorHandState.open => 'Mano abierta · inflando',
        MirrorHandState.closed => 'Mano cerrada · desinflando',
      };
}
