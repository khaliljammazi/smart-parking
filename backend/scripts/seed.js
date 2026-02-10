const mongoose = require('mongoose');
const Parking = require('../src/models/Parking');
const User = require('../src/models/User');
require('dotenv').config();

// Create parking data matching the actual Parking model schema
const createSampleParkings = (ownerId) => [
  // HAMMAMET PARKINGS
  {
    name: 'Parking Marina Yasmine',
    description: 'Grand parking sécurisé à Yasmine Hammamet, proche de la marina',
    address: {
      street: 'Port de Plaisance Yasmine',
      city: 'Hammamet',
      postalCode: '8050',
      country: 'Tunisia'
    },
    coordinates: {
      latitude: 36.3800,
      longitude: 10.6350
    },
    totalSpots: 80,
    availableSpots: 40,
    pricing: {
      hourly: 3.5,
      daily: 30,
      monthly: 220
    },
    features: ['covered', 'security', 'cctv', 'lighting', '24_7'],
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
    name: 'Parking Médina Hammamet',
    description: 'Parking à proximité de la médina historique',
    address: {
      street: 'Avenue Habib Bourguiba',
      city: 'Hammamet',
      postalCode: '8050',
      country: 'Tunisia'
    },
    coordinates: {
      latitude: 36.4000,
      longitude: 10.6167
    },
    totalSpots: 40,
    availableSpots: 35,
    pricing: {
      hourly: 2.0,
      daily: 18,
      monthly: 140
    },
    features: ['security', 'cctv', 'disabled_access'],
    owner: ownerId,
    isActive: true,
    operatingHours: {
      monday: { open: '07:00', close: '22:00' },
      tuesday: { open: '07:00', close: '22:00' },
      wednesday: { open: '07:00', close: '22:00' },
      thursday: { open: '07:00', close: '22:00' },
      friday: { open: '07:00', close: '22:00' },
      saturday: { open: '07:00', close: '23:00' },
      sunday: { open: '07:00', close: '23:00' }
    },
    images: ['https://via.placeholder.com/300x200']
  },
  {
    name: 'Parking Plage Hammamet',
    description: 'Parking près de la plage publique',
    address: {
      street: 'Avenue de la Corniche',
      city: 'Hammamet',
      postalCode: '8050',
      country: 'Tunisia'
    },
    coordinates: {
      latitude: 36.4050,
      longitude: 10.6200
    },
    totalSpots: 60,
    availableSpots: 20,
    pricing: {
      hourly: 4.0,
      daily: 35,
      monthly: 250
    },
    features: ['security', 'lighting', 'car_wash'],
    owner: ownerId,
    isActive: true,
    operatingHours: {
      monday: { open: '06:00', close: '20:00' },
      tuesday: { open: '06:00', close: '20:00' },
      wednesday: { open: '06:00', close: '20:00' },
      thursday: { open: '06:00', close: '20:00' },
      friday: { open: '06:00', close: '22:00' },
      saturday: { open: '06:00', close: '22:00' },
      sunday: { open: '06:00', close: '22:00' }
    },
    images: ['https://via.placeholder.com/300x200']
  },
  {
    name: 'Parking Central Hammamet',
    description: 'Parking au coeur du centre-ville',
    address: {
      street: 'Rue Ali Belhouane',
      city: 'Hammamet',
      postalCode: '8050',
      country: 'Tunisia'
    },
    coordinates: {
      latitude: 36.3995,
      longitude: 10.6150
    },
    totalSpots: 50,
    availableSpots: 25,
    pricing: {
      hourly: 2.5,
      daily: 22,
      monthly: 170
    },
    features: ['covered', 'security', 'payment_terminal'],
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

  // NABEUL PARKINGS
  {
    name: 'Parking Marché Nabeul',
    description: 'Parking à proximité du célèbre marché de Nabeul',
    address: {
      street: 'Avenue Farhat Hached',
      city: 'Nabeul',
      postalCode: '8000',
      country: 'Tunisia'
    },
    coordinates: {
      latitude: 36.4561,
      longitude: 10.7376
    },
    totalSpots: 45,
    availableSpots: 28,
    pricing: {
      hourly: 2.0,
      daily: 16,
      monthly: 130
    },
    features: ['security', 'cctv'],
    owner: ownerId,
    isActive: true,
    operatingHours: {
      monday: { open: '07:00', close: '19:00' },
      tuesday: { open: '07:00', close: '19:00' },
      wednesday: { open: '07:00', close: '19:00' },
      thursday: { open: '07:00', close: '19:00' },
      friday: { open: '07:00', close: '20:00' },
      saturday: { open: '07:00', close: '20:00' },
      sunday: { open: '07:00', close: '19:00' }
    },
    images: ['https://via.placeholder.com/300x200']
  },

  // TUNIS PARKINGS
  // TUNIS PARKINGS
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
      latitude: 36.8065,
      longitude: 10.1815
    },
    totalSpots: 70,
    availableSpots: 45,
    pricing: {
      hourly: 3.0,
      daily: 25,
      monthly: 200
    },
    features: ['covered', 'security', 'ev_charging', 'disabled_access', '24_7'],
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
      latitude: 36.8095,
      longitude: 10.1725
    },
    totalSpots: 35,
    availableSpots: 15,
    pricing: {
      hourly: 3.5,
      daily: 28,
      monthly: 210
    },
    features: ['covered', 'security', 'disabled_access', 'valet'],
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
      latitude: 36.8200,
      longitude: 10.1650
    },
    totalSpots: 55,
    availableSpots: 32,
    pricing: {
      hourly: 2.5,
      daily: 20,
      monthly: 160
    },
    features: ['security', 'cctv', 'lighting'],
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

  // SOUSSE PARKINGS
  {
    name: 'Parking Port Sousse',
    description: 'Parking sécurisé près du port de Sousse',
    address: {
      street: 'Avenue Hédi Chaker',
      city: 'Sousse',
      postalCode: '4000',
      country: 'Tunisia'
    },
    coordinates: {
      latitude: 35.8256,
      longitude: 10.6411
    },
    totalSpots: 65,
    availableSpots: 35,
    pricing: {
      hourly: 2.5,
      daily: 22,
      monthly: 170
    },
    features: ['covered', 'security', 'cctv', 'payment_terminal'],
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

  // SFAX PARKINGS
  {
    name: 'Parking Centre Ville Sfax',
    description: 'Grand parking au centre de Sfax',
    address: {
      street: 'Avenue Habib Bourguiba',
      city: 'Sfax',
      postalCode: '3000',
      country: 'Tunisia'
    },
    coordinates: {
      latitude: 34.7406,
      longitude: 10.7603
    },
    totalSpots: 60,
    availableSpots: 30,
    pricing: {
      hourly: 2.5,
      daily: 20,
      monthly: 155
    },
    features: ['security', 'cctv', 'disabled_access'],
    owner: ownerId,
    isActive: true,
    operatingHours: {
      monday: { open: '07:00', close: '21:00' },
      tuesday: { open: '07:00', close: '21:00' },
      wednesday: { open: '07:00', close: '21:00' },
      thursday: { open: '07:00', close: '21:00' },
      friday: { open: '07:00', close: '21:00' },
      saturday: { open: '07:00', close: '21:00' },
      sunday: { open: '08:00', close: '20:00' }
    },
    images: ['https://via.placeholder.com/300x200']
  },

  // MONASTIR PARKINGS
  {
    name: 'Parking Aéroport Monastir',
    description: 'Parking à l\'aéroport international de Monastir',
    address: {
      street: 'Route de l\'Aéroport',
      city: 'Monastir',
      postalCode: '5000',
      country: 'Tunisia'
    },
    coordinates: {
      latitude: 35.7777,
      longitude: 10.8264
    },
    totalSpots: 120,
    availableSpots: 75,
    pricing: {
      hourly: 3.5,
      daily: 30,
      monthly: 250
    },
    features: ['covered', 'security', 'cctv', '24_7', 'disabled_access', 'payment_terminal'],
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
