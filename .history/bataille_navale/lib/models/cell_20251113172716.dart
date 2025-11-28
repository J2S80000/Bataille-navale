import 'package:equatable/equatable.dart';

enum CellState {
  empty,      // Pas touché
  hit,        // Touché (navire)
  miss,       // Manqué
  ship,       // Navire (utilisateur seulement)
  sunk,       // Navire coulé
}

class Cell extends Equatable {
  final int row;
  final int col;
  final CellState state;

  const Cell({
    required this.row,
    required this.col,
    required this.state,
  });

  Cell copyWith({CellState? state}) {
    return Cell(
      row: row,
      col: col,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'state': state.toString().split('.').last,
    };
  }

  factory Cell.fromJson(Map<String, dynamic> json) {
    return Cell(
      row: json['row'] as int,
      col: json['col'] as int,
      state: CellState.values.firstWhere(
        (e) => e.toString().split('.').last == json['state'],
        orElse: () => CellState.empty,
      ),
    );
  }

  @override
  List<Object?> get props => [row, col, state];
}
