// MongoDB initialization script
// This script creates the application user with proper permissions

db = db.getSiblingDB('admin');

// Create application user
db.createUser({
  user: 'appuser',
  pwd: 'apppass123',
  roles: [
    {
      role: 'readWrite',
      db: 'app'
    }
  ]
});

print('✅ Application user "appuser" created successfully');

// Switch to app database
db = db.getSiblingDB('app');

// Create a collection to initialize the database
db.createCollection('orders');

print('✅ Database "app" and collection "orders" created successfully');
