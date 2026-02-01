# Smart Parking - Admin System Documentation

## Role Hierarchy

The Smart Parking system now supports a comprehensive role-based access control system with four distinct user roles:

### 1. **Super Admin** (super_admin)
- **Highest level access** - Full system control
- **Email**: superadmin@smartparking.com
- **Password**: super123456

**Permissions:**
- All Admin permissions
- Create and delete Admin users
- Create and delete Parking Operator users
- Cannot be deleted by anyone
- Access to admin management page

### 2. **Admin** (admin)
- **Administrative access** for system management
- **Email**: admin@smartparking.com
- **Password**: admin123456

**Permissions:**
- View dashboard and analytics
- Manage regular users (view, delete)
- Manage all parking spots (create, update, delete)
- View revenue reports
- Access to user management page
- Access to parking management page

### 3. **Parking Operator** (parking_operator)
- **Operational role** for parking facility management
- **Email**: operator@smartparking.com
- **Password**: operator123456

**Permissions:**
- Generate QR codes for parking access
- Manage their assigned parking facilities
- View booking information
- Scan QR codes for entry/exit validation
- Limited dashboard access

### 4. **User** (user)
- **Regular customer** role
- Created through normal registration

**Permissions:**
- Search and browse parking spots
- Make bookings
- Manage their own vehicles
- View their booking history
- Update personal profile

---

## Login Methods

### Email/Password Login
1. Open the Smart Parking app
2. Click **"Login with Email instead"**
3. Enter email and password
4. Click **"Login with Email"**

### Quick Admin Login (Legacy)
1. Click **"Admin Login"** button
2. Username: `admin`
3. Password: `1234`
4. Note: This is a hardcoded shortcut and doesn't authenticate with backend

---

## Admin Dashboard Features

### Quick Actions Menu
The dashboard provides quick access to key management features:

#### 1. **Manage Users**
- View all registered users with pagination
- Filter users by role
- Search users by name or email
- Delete regular users
- View user details (email, role, status)

#### 2. **Manage Parkings**
- View all parking facilities
- Create new parking spots
- Update parking information
- Delete parking facilities
- Manage pricing and availability

#### 3. **Manage Admins** (Super Admin Only)
- View all admin and operator accounts
- Create new admin users
- Create new parking operators
- Delete admin/operator accounts (except super admin)
- Assign appropriate roles

#### 4. **View Reports**
- Revenue analytics
- Booking statistics
- Top performing parking spots
- Revenue by period (daily/weekly/monthly)

### Dashboard Statistics
- **Total Users**: Count of registered users
- **Total Parkings**: Number of parking facilities
- **Total Bookings**: All-time booking count
- **Active Bookings**: Currently active reservations

### Revenue Analytics
- **Total Revenue**: Sum of all completed transactions
- **Average per Booking**: Mean revenue per booking
- **Revenue by Parking**: Breakdown by facility
- **Revenue by Period**: Time-based analysis

---

## API Endpoints

### Admin Routes

#### User Management
```
GET    /api/admin/users              - Get all users (paginated)
DELETE /api/admin/users/:id          - Delete a user
```

#### Parking Management
```
POST   /api/admin/parkings           - Create new parking
PUT    /api/admin/parkings/:id       - Update parking
DELETE /api/admin/parkings/:id       - Delete parking
```

#### Admin Management (Super Admin Only)
```
GET    /api/admin/admins             - Get all admin users
POST   /api/admin/admins             - Create admin/operator
DELETE /api/admin/admins/:id         - Delete admin/operator
```

#### Analytics
```
GET    /api/admin/dashboard          - Dashboard statistics
GET    /api/admin/revenue            - Revenue analytics
```

---

## Security Features

### Role-Based Access Control
- Middleware checks user role on every request
- Super Admin required for admin management
- Admin/Super Admin required for user/parking management
- Parking Operator has limited access to own facilities

### Protected Operations
- Super Admins cannot be deleted
- Users cannot delete themselves
- Only Super Admin can manage admin accounts
- Admin users cannot delete other admins

### Authentication
- JWT token-based authentication
- Secure password hashing with bcrypt
- Token stored securely (Secure Storage on mobile, SharedPreferences on web)

---

## Workflow Examples

### Creating a New Admin User
1. Login as Super Admin (superadmin@smartparking.com)
2. Navigate to Dashboard
3. Click **"Manage Admins"**
4. Click **"Add Admin"** button
5. Fill in details:
   - First Name
   - Last Name
   - Email
   - Phone
   - Password
   - Role (Admin or Parking Operator)
6. Click **"Create"**

### Creating a New Parking Spot
1. Login as Admin or Super Admin
2. Navigate to Dashboard
3. Click **"Manage Parkings"**
4. Click **"Add Parking"** button
5. Fill in parking details:
   - Name
   - Address
   - Coordinates
   - Total spots
   - Pricing (hourly, daily, monthly)
   - Features
   - Operating hours
6. Submit the form

### Deleting a User
1. Login as Admin or Super Admin
2. Navigate to Dashboard
3. Click **"Manage Users"**
4. Search or filter to find the user
5. Click delete icon (trash can)
6. Confirm deletion

### Parking Operator - Generate QR Code
1. Login as Parking Operator
2. Navigate to parking facility
3. Select booking/parking slot
4. Click **"Generate QR Code"**
5. QR code is displayed for entry/exit scanning

---

## Frontend Pages

### New Admin Pages
- `admin_dashboard_page.dart` - Main dashboard with statistics
- `manage_users_page.dart` - User management interface
- `manage_admins_page.dart` - Admin account management (Super Admin only)

### Updated Services
- `admin_service.dart` - Extended with new API methods
- `auth_service.dart` - Added email/password login
- `auth_provider.dart` - Added loginWithEmail method

---

## Database Schema Updates

### User Model
```javascript
role: {
  type: String,
  enum: ['user', 'parking_operator', 'admin', 'super_admin'],
  default: 'user'
}
```

---

## Testing Credentials

| Role | Email | Password | Access Level |
|------|-------|----------|--------------|
| Super Admin | superadmin@smartparking.com | super123456 | Full system access |
| Admin | admin@smartparking.com | admin123456 | Manage users & parkings |
| Parking Operator | operator@smartparking.com | operator123456 | Manage parkings & QR |
| Demo Owner | parking.owner@demo.com | demo123456 | Parking owner |

---

## Troubleshooting

### Cannot Access Admin Dashboard
1. Ensure backend server is running (`npm start`)
2. Check that you're using correct email/password
3. Verify user role in database
4. Clear app cache and try again

### "Access Denied" Error
- Your account doesn't have admin privileges
- Contact Super Admin to upgrade your role
- Verify you're logged in with correct account

### Backend Connection Issues
- Check backend is running on port 5000
- Verify MongoDB is connected
- Check CORS settings in backend
- Ensure correct baseUrl in frontend services

---

## Best Practices

1. **Never share Super Admin credentials**
2. **Create specific admin accounts for each administrator**
3. **Use Parking Operator role for facility managers**
4. **Regularly audit user accounts**
5. **Monitor admin activity logs**
6. **Keep passwords secure and complex**
7. **Delete inactive admin accounts**

---

## Future Enhancements

- Activity logs and audit trails
- Email notifications for admin actions
- Bulk user operations
- Advanced analytics dashboard
- Export reports to PDF/Excel
- Two-factor authentication for admins
- Role permissions customization

---

**Version**: 1.0  
**Last Updated**: January 28, 2026  
**Contact**: Smart Parking Development Team
