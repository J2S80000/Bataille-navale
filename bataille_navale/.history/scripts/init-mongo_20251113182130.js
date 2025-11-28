db = db.getSiblingDB('bataille_navale');

db.createCollection('game_statistics');
db.createCollection('games');
db.createCollection('players');

// Index pour optimiser les requêtes
db.game_statistics.createIndex({ "playerId": 1 });
db.game_statistics.createIndex({ "recordedAt": -1 });
db.games.createIndex({ "playerId": 1 });
db.games.createIndex({ "timestamp": -1 });
db.players.createIndex({ "playerId": 1 }, { unique: true });

print("✓ Collections and indexes created successfully");
