const express = require('express');
const { MongoClient } = require('mongodb');
const morgan = require('morgan');

// Config from environment (K8s will inject these)
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017';
const MONGO_DB = process.env.MONGO_DB || 'app';
const MONGO_COLLECTION = process.env.MONGO_COLLECTION || 'orders';

const app = express();
app.use(express.json());

// Request logging - structured JSON for easy parsing
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    const log = {
      timestamp: new Date().toISOString(),
      method: req.method,
      path: req.path,
      status: res.statusCode,
      latency_ms: duration,
      user_agent: req.get('user-agent') || 'unknown'
    };
    console.log(JSON.stringify(log));
  });
  
  next();
});

// MongoDB connection
let mongoClient = null;
let db = null;
let collection = null;

async function initializeMongo() {
  try {
    // Mask password in logs
    const safeUri = MONGO_URI.replace(/\/\/[^:]+:[^@]+@/, '//***:***@');
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'info',
      message: 'Connecting to MongoDB',
      uri: safeUri
    }));

    mongoClient = new MongoClient(MONGO_URI, {
      maxPoolSize: 10,
      minPoolSize: 2,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });

    await mongoClient.connect();
    db = mongoClient.db(MONGO_DB);
    collection = db.collection(MONGO_COLLECTION);

    await db.admin().ping();

    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'info',
      message: 'Connected to MongoDB successfully',
      database: MONGO_DB,
      collection: MONGO_COLLECTION
    }));

    return true;
  } catch (error) {
    console.error(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'error',
      message: 'MongoDB connection failed',
      error: error.message
    }));
    return false;
  }
}

// Health check endpoint
app.get('/healthz', async (req, res) => {
  if (!mongoClient) {
    return res.status(503).json({ 
      status: 'unhealthy', 
      error: 'MongoDB client not initialized' 
    });
  }

  try {
    await db.admin().ping();
    res.status(200).json({ status: 'healthy' });
  } catch (error) {
    console.error(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'error',
      message: 'Health check failed',
      error: error.message
    }));
    res.status(503).json({ 
      status: 'unhealthy', 
      error: error.message 
    });
  }
});

// Create order
app.post('/orders', async (req, res) => {
  try {
    const { orderId } = req.body;

    if (!orderId || typeof orderId !== 'string') {
      return res.status(400).json({ 
        error: 'orderId is required and must be a string' 
      });
    }

    const order = {
      orderId: orderId,
      ts: new Date().toISOString(),
      createdAt: new Date()
    };

    const result = await collection.insertOne(order);

    res.status(201).json({
      inserted: true,
      id: result.insertedId.toString()
    });

  } catch (error) {
    console.error(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'error',
      message: 'Failed to insert order',
      error: error.message
    }));
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
});

// Get order count
app.get('/orders/count', async (req, res) => {
  try {
    const count = await collection.countDocuments();
    res.status(200).json({ count });
  } catch (error) {
    console.error(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'error',
      message: 'Failed to count orders',
      error: error.message
    }));
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
});

// List orders
app.get('/orders', async (req, res) => {
  try {
    const orders = await collection.find({}).limit(100).toArray();
    res.status(200).json({ orders, count: orders.length });
  } catch (error) {
    console.error(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'error',
      message: 'Failed to fetch orders',
      error: error.message
    }));
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
});

// Graceful shutdown handler
async function gracefulShutdown(signal) {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level: 'info',
    message: `Received ${signal}, starting graceful shutdown`
  }));

  // Close MongoDB connection
  if (mongoClient) {
    await mongoClient.close();
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'info',
      message: 'MongoDB connection closed'
    }));
  }

  process.exit(0);
}

// Register shutdown handlers
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Start the server
async function startServer() {
  // Initialize MongoDB connection
  const connected = await initializeMongo();
  
  if (!connected) {
    console.error(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'error',
      message: 'Failed to initialize MongoDB, exiting'
    }));
    process.exit(1);
  }

  // Start Express server
  app.listen(PORT, () => {
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'info',
      message: 'Server started successfully',
      port: PORT,
      mongodb_db: MONGO_DB,
      mongodb_collection: MONGO_COLLECTION
    }));
  });
}

// Start the application
startServer().catch(error => {
  console.error(JSON.stringify({
    timestamp: new Date().toISOString(),
    level: 'error',
    message: 'Failed to start server',
    error: error.message
  }));
  process.exit(1);
});
