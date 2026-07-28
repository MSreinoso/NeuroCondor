enum DigitalPinState { unknown, inactive, active }

enum GlovePhase {
  idleClosed,
  opening,
  holdOpen,
  readyOpen,
  closing,
  holdClosed,
}

sealed class DeviceEvent {
  const DeviceEvent();
}

class DigitalPinEvent extends DeviceEvent {
  const DigitalPinEvent(this.state);
  final DigitalPinState state;
}

class GlovePhaseEvent extends DeviceEvent {
  const GlovePhaseEvent(this.phase, this.secondsRemaining);
  final GlovePhase phase;
  final int secondsRemaining;
}

class DeviceFaultEvent extends DeviceEvent {
  const DeviceFaultEvent(this.code);
  final String code;
}

DeviceEvent? parseDeviceMessage(String raw) {
  final fields = raw.trim().split(',');
  if (fields.length < 2) return null;
  if (fields[0] == 'P') {
    return DigitalPinEvent(
      fields[1] == '1'
          ? DigitalPinState.active
          : fields[1] == '0'
              ? DigitalPinState.inactive
              : DigitalPinState.unknown,
    );
  }
  if (fields[0] == 'G') {
    final phase = switch (fields[1]) {
      'OPENING' => GlovePhase.opening,
      'OPEN' => GlovePhase.holdOpen,
      'OPEN_READY' => GlovePhase.readyOpen,
      'CLOSING' => GlovePhase.closing,
      'CLOSED_WAIT' => GlovePhase.holdClosed,
      _ => GlovePhase.idleClosed,
    };
    return GlovePhaseEvent(
      phase,
      fields.length > 2 ? int.tryParse(fields[2]) ?? 0 : 0,
    );
  }
  if (fields[0] == 'E') return DeviceFaultEvent(fields.sublist(1).join(','));
  return null;
}
