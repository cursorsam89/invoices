# Business Record Management - Flutter Web App

A comprehensive business record management application built with Flutter Web and Supabase backend. Manage customers, invoices, and payment transactions with real-time updates.

## Features

- **Authentication**: Secure sign-up and sign-in with Supabase Auth
- **Dashboard**: Real-time overview of amount received and amount due
- **Customer Management**: Add, edit, and delete customers with automatic invoice generation
- **Invoice Tracking**: View and manage invoices with payment status
- **Payment Processing**: Add payments and track transaction history
- **Real-time Updates**: Live data synchronization using Supabase subscriptions
- **Search & Filter**: Find customers and filter by overdue status
- **Responsive Design**: Modern UI optimized for web browsers

## Technology Stack

- **Frontend**: Flutter Web
- **Backend**: Supabase (Authentication, Database, Real-time subscriptions)
- **Database**: PostgreSQL (via Supabase)
- **State Management**: Flutter's built-in StatefulWidget
- **UI**: Material Design 3

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Customers Table
```sql
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  amount DECIMAL(10,2),
  description TEXT,
  repeat INTEGER DEFAULT 1,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Invoices Table
```sql
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  due_date DATE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending',
  paid_amount DECIMAL(10,2) DEFAULT 0,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Transactions Table
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID REFERENCES invoices(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  payment_date DATE NOT NULL,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Supabase account

### 2. Supabase Setup

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Go to Settings > API to get your project URL and anon key
3. Create the database tables using the schema above
4. Set up Row Level Security (RLS) policies:

```sql
-- Enable RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Customers policies
CREATE POLICY "Users can view their own customers" ON customers
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own customers" ON customers
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own customers" ON customers
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own customers" ON customers
  FOR DELETE USING (auth.uid() = user_id);

-- Invoices policies
CREATE POLICY "Users can view invoices for their customers" ON invoices
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM customers 
      WHERE customers.id = invoices.customer_id 
      AND customers.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert invoices for their customers" ON invoices
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM customers 
      WHERE customers.id = invoices.customer_id 
      AND customers.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update invoices for their customers" ON invoices
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM customers 
      WHERE customers.id = invoices.customer_id 
      AND customers.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete invoices for their customers" ON invoices
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM customers 
      WHERE customers.id = invoices.customer_id 
      AND customers.user_id = auth.uid()
    )
  );

-- Transactions policies
CREATE POLICY "Users can view transactions for their invoices" ON transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM invoices 
      JOIN customers ON customers.id = invoices.customer_id
      WHERE invoices.id = transactions.invoice_id 
      AND customers.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert transactions for their invoices" ON transactions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM invoices 
      JOIN customers ON customers.id = invoices.customer_id
      WHERE invoices.id = transactions.invoice_id 
      AND customers.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update transactions for their invoices" ON transactions
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM invoices 
      JOIN customers ON customers.id = invoices.customer_id
      WHERE invoices.id = transactions.invoice_id 
      AND customers.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete transactions for their invoices" ON transactions
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM invoices 
      JOIN customers ON customers.id = invoices.customer_id
      WHERE invoices.id = transactions.invoice_id 
      AND customers.user_id = auth.uid()
    )
  );
```

### 3. Flutter Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Create a `.env` file in the root directory:
   ```
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. Run the application:
   ```bash
   flutter run -d chrome
   ```

## Usage

### Authentication
- First-time users will be redirected to sign up
- Existing users can sign in with their email and password
- Authentication is handled securely through Supabase Auth

### Adding Customers
1. Click the "+" button on the home screen
2. Fill in customer details:
   - Name (required)
   - Amount (optional)
   - Description (optional)
   - Repeat (number of months)
   - Start date
3. The system will automatically generate invoices based on the repeat value

### Managing Invoices
- View all invoices for a customer by clicking on their card
- Add payments using the "Add Payment" button
- View transaction history and cancel transactions if needed
- Invoices automatically update their status based on payments

### Dashboard Features
- **Amount Received**: Shows total payments received in the current month
- **Amount Due**: Shows total pending amount from previous months
- **Search**: Find customers by name (case-insensitive)
- **Filter**: View all customers or only those with overdue invoices

## Business Rules

1. **Invoice Generation**: When a customer is created with an amount, invoices are automatically generated based on the repeat value
2. **Payment Tracking**: Each payment creates a transaction record
3. **Status Updates**: Invoice status automatically updates based on payment amounts
4. **Transaction Cancellation**: Cancelled transactions revert the invoice paid amount
5. **Monthly Reset**: Amount received resets to ₹0 at the start of each month
6. **Overdue Calculation**: Overdue invoices are calculated based on due date vs current date

## File Structure

```
lib/
├── main.dart                 # App entry point and configuration
├── models/                   # Data models
│   ├── user.dart
│   ├── customer.dart
│   ├── invoice.dart
│   └── transaction.dart
├── services/                 # Business logic and API calls
│   └── supabase_service.dart
├── screens/                  # UI screens
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   └── customer_details_screen.dart
├── widgets/                  # Reusable UI components
│   ├── customer_card.dart
│   ├── add_customer_modal.dart
│   └── transaction_modal.dart
└── utils/                    # Utility functions
    └── date_formatter.dart
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
