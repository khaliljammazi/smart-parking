# Smart Parking Backend API

A Node.js backend API for the Smart Parking application with OAuth 2.0 authentication, QR code integration, and automated validation.

## Features

- **User Management**: Registration, authentication, and profile management
- **OAuth 2.0**: Google and Facebook login integration
- **Vehicle Management**: Add, update, and manage user vehicles
- **Parking Management**: CRUD operations for parking spots
- **Booking System**: Reserve parking spots with time slots
- **QR Code Integration**: Secure check-in/check-out with QR codes
- **Automated Validation**: Streamlined entry/exit process
- **Real-time Updates**: Location tracking and availability updates

## Tech Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT + Passport.js (OAuth 2.0)
- **Validation**: Express Validator
- **Security**: Helmet, CORS, Rate Limiting
- **QR Codes**: qrcode library
- **Payments**: Stripe integration ready

## Getting Started

### Prerequisites

- Node.js (>= 16.0.0)
- MongoDB
- npm or yarn

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd smart-parking/backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Setup**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Start MongoDB**
   Make sure MongoDB is running on your system

5. **Run the server**
   ```bash
   # Development mode
   npm run dev

   # Production mode
   npm start
   ```

The server will start on `http://localhost:5000`

## Environment Variables

Create a `.env` file in the root directory:

```env
# Environment
NODE_ENV=development
PORT=5000

# Database
MONGODB_URI=mongodb://localhost:27017/smart_parking

# JWT
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRE=7d

# OAuth 2.0
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret

# Client URL
CLIENT_URL=http://localhost:3000

# QR Code Settings
QR_CODE_SIZE=256
QR_VALIDITY_MINUTES=15
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user
- `GET /api/auth/google` - Google OAuth
- `GET /api/auth/facebook` - Facebook OAuth

### User Management
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile
- `POST /api/users/vehicles` - Add vehicle
- `GET /api/users/vehicles` - Get user vehicles
- `PUT /api/users/vehicles/:id` - Update vehicle
- `DELETE /api/users/vehicles/:id` - Delete vehicle

### Parking Management
- `GET /api/parking` - Get parking spots (with filters)
- `GET /api/parking/:id` - Get parking details
- `POST /api/parking` - Create parking spot
- `PUT /api/parking/:id` - Update parking spot
- `DELETE /api/parking/:id` - Delete parking spot
- `GET /api/parking/nearby/search` - Find nearby parking

### Bookings
- `POST /api/bookings` - Create booking
- `GET /api/bookings` - Get user bookings
- `GET /api/bookings/:id` - Get booking details
- `PUT /api/bookings/:id/cancel` - Cancel booking
- `PUT /api/bookings/:id/rate` - Rate completed booking

### QR Code Integration
- `GET /api/qr/generate/:bookingId` - Generate QR code
- `POST /api/qr/scan` - Scan and validate QR code
- `GET /api/qr/validate/:qrCode` - Validate QR code

## API Response Format

All API responses follow this format:

```json
{
  "success": true|false,
  "message": "Response message",
  "data": { ... },
  "errors": [ ... ]
}
```

## Authentication

The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

## QR Code Flow

1. **Booking Creation**: User books a parking spot
2. **QR Generation**: System generates unique QR code for the booking
3. **Check-in**: User scans QR at parking entrance
4. **Validation**: System validates QR and opens barrier
5. **Check-out**: User scans QR at exit
6. **Payment**: System calculates final amount and processes payment

## Payment Integration

The system is designed for pay-at-exit model:
- Booking reserves the spot
- Payment occurs when user exits
- Supports card, cash, and wallet payments
- Integrated with Stripe for card payments

## Development

### Running Tests
```bash
npm test
```

### Code Linting
```bash
npm run lint
```

### Database Seeding
```bash
npm run seed
```

## Deployment

### Environment Variables for Production
- Set `NODE_ENV=production`
- Use production MongoDB URI
- Configure production OAuth credentials
- Set up Stripe production keys

### Docker Support
```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support, email support@smartparking.com or create an issue in the repository.