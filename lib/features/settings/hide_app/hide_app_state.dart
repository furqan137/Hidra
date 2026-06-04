class HideAppState {
  /// Whether app is hidden (Android launcher hidden / iOS stealth mode)
  final bool isHidden;

  /// Secret dial code shown in settings (UX only)
  final String dialCode;

  /// Used for validation / UI feedback
  final bool isDialCodeValid;

  /// iOS only: user unlocked vault via fake dialer
  final bool isStealthUnlocked;

  const HideAppState({
    this.isHidden = false,
    this.dialCode = '*#*#13710#*#*',
    this.isDialCodeValid = true,
    this.isStealthUnlocked = false,
  });

  HideAppState copyWith({
    bool? isHidden,
    String? dialCode,
    bool? isDialCodeValid,
    bool? isStealthUnlocked,
  }) {
    return HideAppState(
      isHidden: isHidden ?? this.isHidden,
      dialCode: dialCode ?? this.dialCode,
      isDialCodeValid: isDialCodeValid ?? this.isDialCodeValid,
      isStealthUnlocked: isStealthUnlocked ?? this.isStealthUnlocked,
    );
  }
}