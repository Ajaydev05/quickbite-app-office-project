const mongoose = require('mongoose');

const connectDB = async () => {
  const uri = process.env.MONGODB_URI || 'mongodb://quickbite_user:quickbite_password@localhost:27017/quickbite';
  const conn = await mongoose.connect(uri);
  console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  mongoose.connection.on('disconnected', () => console.warn('⚠️  MongoDB disconnected'));
  mongoose.connection.on('error', err => console.error('❌ MongoDB error:', err));
};

module.exports = connectDB;
