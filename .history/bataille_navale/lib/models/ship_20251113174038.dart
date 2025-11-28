import 'package:equatable/equatable.dart';

enum ShipType {
  carrier,    // 5 cases
  battleship, // 4 cases
  cruiser,    // 3 cases
  submarine,  // 3 cases
  destroyer,  // 2 cases
}

extension ShipTypeExtension on ShipType {
  int get size {
    switch (this) {
      case ShipType.carrier:
        return 5;
      case ShipType.battleship:
        return 4;
      case ShipType.cruiser:
      case ShipType.submarine:
        return 3;
      case ShipType.destroyer:
        return 2;
    }
  }

  String get displayName {
    switch (this) {
      case ShipType.carrier:
        return 'Porte-avions';
      case ShipType.battleship:
        return 'Croiseur';
      case ShipType.cruiser:
        return 'Destroyer';
      case ShipType.submarine:
        return 'Sous-marin';
      case ShipType.destroyer:
        return 'Torpilleur';
    }
  }
}

class Ship extends Equatable {
  final String id;
  final ShipType type;
  final List<(int, int)> cells; // positions (row, col)
  final bool isVertical;
  final int hits; // Nombre de coups reçus

  const Ship({
    required this.id,
    required this.type,
    required this.cells,
    required this.isVertical,
    this.hits = 0,
  });

  bool get isSunk => hits == type.size;

  Ship copyWith({int? hits}) {
    return Ship(
      id: id,
      type: type,
      cells: cells,
      isVertical: isVertical,
      hits: hits ?? this.hits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'cells': cells.map((cell) => {'row': cell.$1, 'col': cell.$2}).toList(),
      'isVertical': isVertical,
      'hits': hits,
    };
  }

  factory Ship.fromJson(Map<String, dynamic> json) {
    return Ship(
      id: json['id'] as String,
      type: ShipType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      cells: (json['cells'] as List)
          .map((c) => (c['row'] as int, c['col'] as int))
          .toList(),
      isVertical: json['isVertical'] as bool,
      hits: json['hits'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, type, cells, isVertical, hits];
}
