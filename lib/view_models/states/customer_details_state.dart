class CustomerDetailsState {
  final bool isEditing;

  const CustomerDetailsState({
    this.isEditing = false,
  });

  CustomerDetailsState copyWith({
    bool? isEditing,
  }) {
    return CustomerDetailsState(
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerDetailsState && other.isEditing == isEditing;
  }

  @override
  int get hashCode => isEditing.hashCode;
}
