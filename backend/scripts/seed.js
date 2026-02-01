const mongoose = require('mongoose');
const Parking = require('../src/models/Parking');
const User = require('../src/models/User');
require('dotenv').config();

// Create parking data matching the actual Parking model schema
const createSampleParkings = (ownerId) => [
  {
    name: 'Parking Central Tunis',
    description: 'Parking spacieux au centre-ville de Tunis',
    address: {
      street: 'Avenue Habib Bourguiba',
      city: 'Tunis',
      postalCode: '1000',
      country: 'Tunisia'
    },
    coordinates: {
      longitude: 10.1815,
      latitude: 36.8065
    },
    totalSpots: 50,
    availableSpots: 25,
    pricing: {
      hourly: 2.5,
      daily: 20,
      monthly: 150
    },
    features: ['covered', 'security', 'ev_charging'],
    owner: ownerId,
    isActive: true,
    operatingHours: {
      monday: { open: '00:00', close: '23:59' },
      tuesday: { open: '00:00', close: '23:59' },
      wednesday: { open: '00:00', close: '23:59' },
      thursday: { open: '00:00', close: '23:59' },
      friday: { open: '00:00', close: '23:59' },
      saturday: { open: '00:00', close: '23:59' },
      sunday: { open: '00:00', close: '23:59' }
    },
    images: ['https://via.placeholder.com/300x200']
  },
  {
    name: 'Parking Lafayette',
    description: 'Parking moderne près de la Médina',
    address: {
      street: 'Rue Charles de Gaulle',
      city: 'Tunis',
      postalCode: '1002',
      country: 'Tunisia'
    },
    coordinates: {
      longitude: 10.1725,
      latitude: 36.8095
    },
    totalSpots: 30,
    availableSpots: 10,
    pricing: {
      hourly: 3.0,
      daily: 25,
      monthly: 180
    },
    features: ['covered', 'security', 'disabled_access'],
    owner: ownerId,
    isActive: true,
    operatingHours: {
      monday: { open: '07:00', close: '22:00' },
      tuesday: { open: '07:00', close: '22:00' },
      wednesday: { open: '07:00', close: '22:00' },
      thursday: { open: '07:00', close: '22:00' },
      friday: { open: '07:00', close: '22:00' },
      saturday: { open: '08:00', close: '20:00' },
      sunday: { open: '08:00', close: '20:00' }
    },
    images: ['https://via.placeholder.com/300x200']
  },
  {
    name: 'Parking Belvedere',
    description: 'Parking près du Parc du Belvédère',
    address: {
      street: 'Avenue de la Liberté',
      city: 'Tunis',
      postalCode: '1002',
      country: 'Tunisia'
    },
    coordinates: {
      longitude: 10.1650,
      latitude: 36.8200
    },
    totalSpots: 40,
    availableSpots: 30,
    pricing: {
      hourly: 2.0,
      daily: 15,
      monthly: 120
    },
    features: ['security', 'cctv'],
    owner: ownerId,
    isActive: true,
    operatingHours: {
      monday: { open: '00:00', close: '23:59' },
      tuesday: { open: '00:00', close: '23:59' },
      wednesday: { open: '00:00', close: '23:59' },
      thursday: { open: '00:00', close: '23:59' },
      friday: { open: '00:00', close: '23:59' },
      saturday: { open: '00:00', close: '23:59' },
      sunday: { open: '00:00', close: '23:59' }
    },
    images: ['https://via.placeholder.com/300x200']
  }
];

async function seedDatabase() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find or create a demo owner user
    let owner = await User.findOne({ email: 'parking.owner@demo.com' });
    if (!owner) {
      owner = await User.create({
        firstName: 'Parking',
        lastName: 'Owner',
        email: 'parking.owner@demo.com',
        password: 'demo123456',
        phone: '+21612345678',
        role: 'parking_owner'
      });
      console.log('Created demo owner user');
    } else {
      console.log('Using existing demo owner user');
    }

    // Find or create a super admin user
    let superAdmin = await User.findOne({ email: 'superadmin@smartparking.com' });
    if (!superAdmin) {
      superAdmin = await User.create({
        firstName: 'Super',
        lastName: 'Admin',
        email: 'superadmin@smartparking.com',
        password: 'super123456',
        phone: '+1234567890',
        role: 'super_admin',
        isVerified: true
      });
      console.log('Created super admin user');
      console.log('Super Admin credentials:');
      console.log('Email: superadmin@smartparking.com');
      console.log('Password: super123456');
    } else {
      console.log('Using existing super admin user');
    }

    // Find or create an admin user
    let admin = await User.findOne({ email: 'admin@smartparking.com' });
    if (!admin) {
      admin = await User.create({
        firstName: 'Admin',
        lastName: 'User',
        email: 'admin@smartparking.com',
        password: 'admin123456',
        phone: '+1234567891',
        role: 'admin',
        isVerified: true
      });
      console.log('Created admin user');
      console.log('Admin credentials:');
      console.log('Email: admin@smartparking.com');
      console.log('Password: admin123456');
    } else {
      console.log('Using existing admin user');
    }

    // Find or create a parking operator user
    let operator = await User.findOne({ email: 'operator@smartparking.com' });
    if (!operator) {
      operator = await User.create({
        firstName: 'Parking',
        lastName: 'Operator',
        email: 'operator@smartparking.com',
        password: 'operator123456',
        phone: '+1234567892',
        role: 'parking_operator',
        isVerified: true
      });
      console.log('Created parking operator user');
      console.log('Parking Operator credentials:');
      console.log('Email: operator@smartparking.com');
      console.log('Password: operator123456');
    } else {
      console.log('Using existing parking operator user');
    }

    // Clear existing parking data
    await Parking.deleteMany({});
    console.log('Cleared existing parking data');

    // Create sample parkings with owner
    const sampleParkings = createSampleParkings(owner._id);

    // Insert sample data
    const inserted = await Parking.insertMany(sampleParkings);
    console.log(`Inserted ${inserted.length} parking spots`);

    // Display inserted IDs
    console.log('\nParking IDs:');
    inserted.forEach(parking => {
      console.log(`${parking.name}: ${parking._id}`);
    });

    process.exit(0);
  } catch (error) {
    console.error('Error seeding database:', error);
    process.exit(1);
  }
}

seedDatabase();
