# Setup Guide - Business Record Management App

This guide will walk you through setting up the Business Record Management Flutter Web app with Supabase backend.

## Prerequisites

1. **Flutter SDK** (latest stable version)
   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **Supabase Account**
   - Sign up at: https://supabase.com
   - Create a new project

3. **Code Editor** (VS Code recommended)
   - Install Flutter extension for better development experience

## Step 1: Supabase Project Setup

### 1.1 Create Supabase Project
1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - Name: `business-record-management`
   - Database Password: (choose a strong password)
   - Region: (choose closest to you)
5. Click "Create new project"
6. Wait for the project to be created (usually 1-2 minutes)

### 1.2 Get Project Credentials
1. In your Supabase dashboard, go to **Settings** > **API**
2. Copy the following values:
   - **Project URL** (looks like: `https://your-project-id.supabase.co`)
   - **Anon public key** (starts with `eyJ...`)

### 1.3 Set Up Database Schema
1. In your Supabase dashboard, go to **SQL Editor**
2. Copy the entire content from `database_setup.sql` file
3. Paste it into the SQL editor
4. Click "Run" to execute the script
5. Verify that all tables are created in **Table Editor**

## Step 2: Flutter Project Setup

### 2.1 Clone/Download Project
If you have the project files:
1. Extract them to a folder
2. Open the folder in your code editor

### 2.2 Install Dependencies
1. Open terminal in the project root directory
2. Run:
   ```bash
   flutter pub get
   ```

### 2.3 Configure Environment Variables
1. Create a `.env` file in the project root directory
2. Add your Supabase credentials:
   ```
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```
3. Replace the values with your actual Supabase project URL and anon key

### 2.4 Test the Setup
1. Run the application:
   ```bash
   flutter run -d chrome
   ```
2. The app should open in your browser
3. You should see the authentication screen

## Step 3: First Time Setup

### 3.1 Create Your Account
1. On the authentication screen, click "Don't have an account? Sign Up"
2. Enter your email and password
3. Click "Sign Up"
4. Check your email for verification link
5. Click the verification link
6. Return to the app and sign in

### 3.2 Add Your First Customer
1. After signing in, you'll see the home screen
2. Click the "+" button (floating action button)
3. Fill in customer details:
   - **Name**: Enter customer name (required)
   - **Amount**: Enter monthly amount (optional)
   - **Description**: Add any notes (optional)
   - **Repeat**: Number of months (default: 1)
   - **Start Date**: Choose start date
4. Click "Save Customer"
5. If you entered an amount, invoices will be automatically generated

## Step 4: Using the Application

### 4.1 Dashboard Overview
- **Amount Received**: Shows payments received this month
- **Amount Due**: Shows total pending amounts
- **Search**: Find customers by name
- **Filter**: View all customers or only overdue ones

### 4.2 Customer Management
- **View Customers**: Click on any customer card to see details
- **Add Customers**: Use the "+" button
- **Edit Customers**: Click edit icon (not implemented in this version)
- **Delete Customers**: Click delete icon (removes customer and all related data)

### 4.3 Invoice Management
- **View Invoices**: Click on a customer to see their invoices
- **Add Payments**: Click "Add Payment" on any invoice
- **Track Status**: Invoices show as Pending, Paid, or Overdue
- **Transaction History**: View and cancel payments if needed

### 4.4 Payment Processing
- **Add Payment**: Enter amount and payment date
- **View History**: See all transactions for an invoice
- **Cancel Payment**: Cancel transactions to revert invoice amounts

## Troubleshooting

### Common Issues

1. **"Flutter command not found"**
   - Install Flutter SDK and add to PATH
   - Run `flutter doctor` to verify installation

2. **"Supabase connection failed"**
   - Check your `.env` file has correct credentials
   - Verify Supabase project is active
   - Check internet connection

3. **"Database tables not found"**
   - Run the `database_setup.sql` script in Supabase SQL Editor
   - Check that RLS policies are created

4. **"Authentication not working"**
   - Verify email verification is completed
   - Check Supabase Auth settings
   - Ensure RLS policies are properly configured

5. **"Real-time updates not working"**
   - Check Supabase project is on a paid plan (free tier has limitations)
   - Verify database triggers are set up correctly

### Getting Help

1. **Check Supabase Logs**: Go to Supabase dashboard > Logs
2. **Flutter Debug**: Use browser developer tools for web debugging
3. **Database Issues**: Check Supabase SQL Editor for errors

## Security Notes

- Never commit your `.env` file to version control
- Keep your Supabase keys secure
- Regularly update dependencies
- Monitor Supabase usage and costs

## Next Steps

After setup, consider:
1. Customizing the UI theme
2. Adding more features (reports, exports, etc.)
3. Setting up automated backups
4. Configuring email notifications
5. Adding user roles and permissions

## Support

For issues specific to this application:
1. Check the README.md file
2. Review the code comments
3. Check Supabase documentation: https://supabase.com/docs
4. Check Flutter documentation: https://flutter.dev/docs