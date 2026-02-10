# Database Setup Guide

## Step 1: Install MongoDB

Make sure MongoDB is installed and running on your system.

**Windows:**
1. Download MongoDB from https://www.mongodb.com/try/download/community
2. Install and start MongoDB service

**Or use MongoDB Atlas (Cloud):**
1. Go to https://www.mongodb.com/cloud/atlas
2. Create a free cluster
3. Get your connection string

## Step 2: Configure Environment Variables

Create or edit `.env` file in the `backend` folder:

```env
# MongoDB Connection
MONGODB_URI=mongodb://localhost:27017/smart_parking
# Or for MongoDB Atlas:
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/smart_parking

# Server Configuration
PORT=5000
NODE_ENV=development

# JWT Secret
JWT_SECRET=your-secret-key-here-change-in-production

# Other optional configs
FRONTEND_URL=http://localhost:51919
```

## Step 3: Install Dependencies

```bash
cd backend
npm install
```

## Step 4: Seed the Database

This will populate your database with sample parking data for:
- **4 parkings in Hammamet** (Marina Yasmine, Médina, Plage, Central)
- **1 parking in Nabeul** (Marché)
- **3 parkings in Tunis** (Central, Lafayette, Belvédère)
- **1 parking in Sousse** (Port)
- **1 parking in Sfax** (Centre Ville)
- **1 parking in Monastir** (Aéroport)

**Total: 11 parking spots**

Run the seed script:

```bash
npm run seed
# or
node scripts/seed.js
```

You should see output like:
```
Connected to MongoDB
Created demo owner user
Cleared existing parking data
Inserted 11 parking spots

Parking IDs:
Parking Marina Yasmine: 65a1b2c3d4e5f6789012345a
Parking Médina Hammamet: 65a1b2c3d4e5f6789012345b
...
```

## Step 5: Start the Backend Server

```bash
npm start
# or for development with auto-reload:
npm run dev
```

Server will start on http://localhost:5000

## Step 6: Verify Data

Test the API endpoints:

**Get all parkings:**
```
GET http://localhost:5000/api/parking?limit=100
```

**Get parkings near Hammamet:**
```
GET http://localhost:5000/api/parking?latitude=36.4000&longitude=10.6167&radius=10000
```

**Get parkings near Tunis:**
```
GET http://localhost:5000/api/parking?latitude=36.8065&longitude=10.1815&radius=10000
```

## Troubleshooting

### Error: Cannot connect to MongoDB
- Make sure MongoDB is running
- Check your `MONGODB_URI` in `.env`
- For local MongoDB: `mongodb://localhost:27017/smart_parking`
- For Atlas: Use the connection string from your cluster

### Error: npm command not found
- Install Node.js from https://nodejs.org/

### Parking data not showing in app
1. Check backend is running: `npm start`
2. Check backend URL in Flutter app matches (port 5000)
3. Reload Flutter app: Hot restart (R) or hot reload (r)

## Default User Accounts

The seed script creates these test accounts:

**Super Admin:**
- Email: `superadmin@smartparking.com`
- Password: `super123456`

**Admin:**
- Email: `admin@smartparking.com`
- Password: `admin123456`

**Parking Operator:**
- Email: `operator@smartparking.com`
- Password: `operator123456`

**Parking Owner:**
- Email: `parking.owner@demo.com`
- Password: `demo123456`

## Database Schema

The Parking model includes:
- Basic info (name, description)
- Location (address, coordinates)
- Capacity (totalSpots, availableSpots)
- Pricing (hourly, daily, monthly)
- Features (covered, security, CCTV, etc.)
- Operating hours for each day
- Contact info & images

## Next Steps

1. Run `npm start` in backend folder
2. Run `flutter run -d chrome --web-port=51919` in Flutter folder
3. Your app should now show real parking data from the database!
4. Select **Hammamet** from the city selector to see Hammamet parkings
