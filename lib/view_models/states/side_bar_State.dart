// ignore_for_file: file_names

class SidebarState {
  final String activeItem;
  final String hoverItem;

  SidebarState({required this.activeItem, required this.hoverItem});

  SidebarState copyWith({String? activeItem, String? hoverItem}) {
    return SidebarState(
      activeItem: activeItem ?? this.activeItem,
      hoverItem: hoverItem ?? this.hoverItem,
    );
  }
}
