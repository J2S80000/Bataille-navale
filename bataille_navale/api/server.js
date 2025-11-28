const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { MongoClient } = require('mongodb');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware avec limites augmentées
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' })); // Augmente la limite de payload
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));

// MongoDB connection
const MONGO_URL = 'mongodb://admin:password@mongodb:27017/';
const DB_NAME = 'bataille_navale';
let mongoClient;
let db;

// Connect to MongoDB
async function connectMongo() {
  try {
    mongoClient = new MongoClient(MONGO_URL, {
      authSource: 'admin',
      serverSelectionTimeoutMS: 5000,
      connectTimeoutMS: 5000,
    });
    await mongoClient.connect();
    db = mongoClient.db(DB_NAME);
    console.log('✓ Connected to MongoDB');
    
    // Créer les indexes pour optimiser les queries
    await createIndexes();
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error);
    process.exit(1);
  }
}

// Crée les indexes pour optimiser les performances
async function createIndexes() {
  try {
    const gameStatsCollection = db.collection('game_statistics');
    const gamesCollection = db.collection('games');
    
    // Index sur playerId pour filtrer rapidement
    await gameStatsCollection.createIndex({ playerId: 1 });
    console.log('✓ Index created on game_statistics.playerId');
    
    // Index sur timestamp pour trier par date
    await gameStatsCollection.createIndex({ timestamp: -1 });
    console.log('✓ Index created on game_statistics.timestamp');
    
    // Index composé pour queries fréquentes
    await gameStatsCollection.createIndex({ playerId: 1, timestamp: -1 });
    console.log('✓ Composite index created on game_statistics');
    
    // TTL index optionnel: supprimer les docs après 90 jours
    await gameStatsCollection.createIndex({ timestamp: 1 }, { expireAfterSeconds: 7776000 });
    console.log('✓ TTL index created (90 days)');
    
    // Index pour games
    await gamesCollection.createIndex({ playerId: 1 });
    await gamesCollection.createIndex({ timestamp: -1 });
    console.log('✓ Indexes created on games collection');
  } catch (error) {
    console.error('⚠ Error creating indexes:', error);
    // Pas d'erreur fatale
  }
}

// Routes

// GET all game statistics with pagination
app.get('/api/game_statistics', async (req, res) => {
  try {
    const playerId = req.query.playerId;
    const limit = Math.min(parseInt(req.query.limit) || 5000, 5000); // Default 5000, max 5000
    const skip = parseInt(req.query.skip) || 0;
    
    const query = playerId ? { playerId } : {};
    const stats = await db.collection('game_statistics')
      .find(query)
      .sort({ timestamp: -1 })
      .limit(limit)
      .skip(skip)
      .toArray();
    
    const total = await db.collection('game_statistics').countDocuments(query);
    
    res.json({ 
      data: stats,
      total,
      limit,
      skip,
      hasMore: (skip + limit) < total
    });
  } catch (error) {
    console.error('Error fetching statistics:', error);
    res.status(500).json({ error: error.message });
  }
});

// POST new game statistics
app.post('/api/game_statistics', async (req, res) => {
  try {
    const stat = req.body;
    stat.timestamp = new Date();
    const result = await db.collection('game_statistics').insertOne(stat);
    res.status(201).json({ _id: result.insertedId, ...stat });
  } catch (error) {
    console.error('Error saving statistics:', error);
    res.status(500).json({ error: error.message });
  }
});

// POST batch game statistics (pour simuler rapidement plusieurs parties)
app.post('/api/game_statistics/batch', async (req, res) => {
  try {
    const stats = Array.isArray(req.body) ? req.body : [req.body];
    
    if (stats.length === 0) {
      return res.status(400).json({ error: 'Empty array' });
    }
    
    // Ajouter timestamp à chaque stat
    const docsWithTimestamp = stats.map(stat => ({
      ...stat,
      timestamp: new Date(),
    }));
    
    const result = await db.collection('game_statistics').insertMany(docsWithTimestamp, { ordered: false });
    
    res.status(201).json({ 
      insertedCount: result.insertedCount,
      insertedIds: result.insertedIds,
      message: `${result.insertedCount}/${stats.length} statistiques sauvegardées`
    });
  } catch (error) {
    console.error('Error saving batch statistics:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET all games with pagination
app.get('/api/games', async (req, res) => {
  try {
    const playerId = req.query.playerId;
    const limit = Math.min(parseInt(req.query.limit) || 1000, 5000); // Max 5000 par request
    const skip = parseInt(req.query.skip) || 0;
    
    const query = playerId ? { playerId } : {};
    const games = await db.collection('games')
      .find(query)
      .sort({ timestamp: -1 })
      .limit(limit)
      .skip(skip)
      .toArray();
    
    const total = await db.collection('games').countDocuments(query);
    
    res.json({ 
      data: games,
      total,
      limit,
      skip,
      hasMore: (skip + limit) < total
    });
  } catch (error) {
    console.error('Error fetching games:', error);
    res.status(500).json({ error: error.message });
  }
});

// POST new game
app.post('/api/games', async (req, res) => {
  try {
    const game = req.body;
    game.timestamp = new Date();
    const result = await db.collection('games').insertOne(game);
    res.status(201).json({ _id: result.insertedId, ...game });
  } catch (error) {
    console.error('Error saving game:', error);
    res.status(500).json({ error: error.message });
  }
});

// DELETE game statistics
app.delete('/api/game_statistics/:id', async (req, res) => {
  try {
    const { ObjectId } = require('mongodb');
    const result = await db.collection('game_statistics').deleteOne({
      _id: new ObjectId(req.params.id),
    });
    res.json({ deleted: result.deletedCount > 0 });
  } catch (error) {
    console.error('Error deleting statistics:', error);
    res.status(500).json({ error: error.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date() });
});

// Start server
connectMongo().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 API server running on http://localhost:${PORT}`);
  });
});
