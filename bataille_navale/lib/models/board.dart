import 'package:equatable/equatable.dart';
import 'cell.dart';
import 'ship.dart';

class Board extends Equatable {
  static const int size = 10;
  
  final List<List<Cell>> grid;
  final List<Ship> ships;
  final bool isVisible; // Affiche les navires (true = mon plateau, false = plateau adversaire)

  const Board({
    required this.grid,
    required this.ships,
    this.isVisible = false,
  });

  /// Crée un plateau vide
  factory Board.empty({bool isVisible = false}) {
    final grid = List.generate(
      size,
      (row) => List.generate(
        size,
        (col) => Cell(row: row, col: col, state: CellState.empty),
      ),
    );
    return Board(grid: grid, ships: [], isVisible: isVisible);
  }

  Cell getCell(int row, int col) {
    if (row < 0 || row >= size || col < 0 || col >= size) {
      throw ArgumentError('Position invalide: ($row, $col)');
    }
    return grid[row][col];
  }

  Board updateCell(int row, int col, CellState state) {
    final newGrid = grid.map((r) => [...r]).toList();
    newGrid[row][col] = Cell(row: row, col: col, state: state);
    return Board(grid: newGrid, ships: ships, isVisible: isVisible);
  }

  /// Crée une copie du plateau avec les navires cachés (pour l'adversaire)
  Board withHiddenShips() {
    final newGrid = grid.map((row) {
      return row.map((cell) {
        // Garder les hit/miss/sunk visibles, mais masquer les ships
        if (cell.state == CellState.ship) {
          return Cell(row: cell.row, col: cell.col, state: CellState.empty);
        }
        return cell;
      }).toList();
    }).toList();
    return Board(grid: newGrid, ships: ships, isVisible: false);
  }

  /// Met à jour un navire (pour compter les hits)
  Board updateShip(Ship updatedShip) {
    final updatedShips = ships.map((ship) {
      if (ship.id == updatedShip.id) {
        return updatedShip;
      }
      return ship;
    }).toList();
    return Board(grid: grid, ships: updatedShips, isVisible: isVisible);
  }

  /// Retourne vrai si la cellule a un navire
  bool hasShip(int row, int col) {
    return ships.any((ship) => ship.cells.contains((row, col)));
  }

  /// Obtient le navire à une position donnée
  Ship? getShipAt(int row, int col) {
    return ships.firstWhere(
      (ship) => ship.cells.contains((row, col)),
      orElse: () => throw StateError('Aucun navire à ($row, $col)'),
    );
  }

  /// Crée une copie du plateau avec un navire ajouté
  Board addShip(Ship ship) {
    return Board(
      grid: grid,
      ships: [...ships, ship],
      isVisible: isVisible,
    );
  }

  /// Compte les navires coulés
  int get sunkShips => ships.where((ship) => ship.isSunk).length;

  /// Retorna vrai si tous les navires sont coulés
  bool get allShipsSunk => ships.isNotEmpty && sunkShips == ships.length;

  Map<String, dynamic> toJson() {
    return {
      'grid': grid.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
      'ships': ships.map((ship) => ship.toJson()).toList(),
      'isVisible': isVisible,
    };
  }

  factory Board.fromJson(Map<String, dynamic> json) {
    final gridData = json['grid'] as List;
    final grid = gridData
        .map((row) => (row as List)
            .map((cell) => Cell.fromJson(cell as Map<String, dynamic>))
            .toList())
        .toList();

    final ships = (json['ships'] as List)
        .map((ship) => Ship.fromJson(ship as Map<String, dynamic>))
        .toList();

    return Board(
      grid: grid,
      ships: ships,
      isVisible: json['isVisible'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [grid, ships, isVisible];
}
