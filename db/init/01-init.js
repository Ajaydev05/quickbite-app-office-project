// MongoDB initialization script for QuickBite
// Runs automatically on first container start

db = db.getSiblingDB('quickbite');

// Create application user with readWrite access
db.createUser({
  user: 'quickbite_user',
  pwd: process.env.MONGO_APP_PASSWORD || 'quickbite_password',
  roles: [{ role: 'readWrite', db: 'quickbite' }]
});

// Create initial collections with schema validation hints
db.createCollection('users');
db.createCollection('restaurants');
db.createCollection('menuItems');
db.createCollection('orders');
db.createCollection('carts');
db.createCollection('reviews');

// Indexes for performance
db.users.createIndex({ email: 1 }, { unique: true });
db.restaurants.createIndex({ owner: 1 });
db.restaurants.createIndex({ location: '2dsphere' }, { sparse: true });
db.menuItems.createIndex({ restaurant: 1 });
db.orders.createIndex({ customer: 1, createdAt: -1 });
db.orders.createIndex({ restaurant: 1, status: 1 });
db.carts.createIndex({ user: 1 }, { unique: true });
db.reviews.createIndex({ restaurant: 1, createdAt: -1 });

print('✅ QuickBite database initialized successfully');
