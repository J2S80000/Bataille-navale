const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { MongoClient } = require('mongodb');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

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
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error);
    process.exit(1);
  }
}

// Routes

// GET all game statistics
app.get('/api/game_statistics', async (req, res) => {
  try {
    const playerId = req.query.playerId;
    const query = playerId ? { playerId } : {};
    const stats = await db.collection('game_statistics').find(query).toArray();
    res.json(stats);
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

// GET all games
app.get('/api/games', async (req, res) => {
  try {
    const playerId = req.query.playerId;
    const query = playerId ? { playerId } : {};
    const games = await db.collection('games').find(query).toArray();
    res.json(games);
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
