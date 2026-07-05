import '../states/customer_details_state.dart';
import 'package:riverpod/legacy.dart';

class CustomerDetailsNotifier extends StateNotifier<CustomerDetailsState> {
  CustomerDetailsNotifier() : super(const CustomerDetailsState());

  // Toggle edit mode
  void toggleEditMode() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  // Set edit mode explicitly
  void setEditMode(bool isEditing) {
    state = state.copyWith(isEditing: isEditing);
  }
}

// Provider
final customerDetailsProvider = StateNotifierProvider.autoDispose<
  CustomerDetailsNotifier,
  CustomerDetailsState
>((ref) => CustomerDetailsNotifier());
