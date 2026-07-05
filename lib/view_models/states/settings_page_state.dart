class SettingsPageState {
  final bool isProcessing;
  final String? error;

  const SettingsPageState({
    this.isProcessing = false,
    this.error,
  });

  SettingsPageState copyWith({
    bool? isProcessing,
    String? error,
  }) {
    return SettingsPageState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsPageState &&
        other.isProcessing == isProcessing &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(isProcessing, error);
}
