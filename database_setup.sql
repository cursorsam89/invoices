-- Business Record Management Database Setup
-- Run this script in your Supabase SQL editor

-- Create tables
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS customers (
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

CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  due_date DATE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending',
  paid_amount DECIMAL(10,2) DEFAULT 0,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID REFERENCES invoices(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  payment_date DATE NOT NULL,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own customers" ON customers;
DROP POLICY IF EXISTS "Users can insert their own customers" ON customers;
DROP POLICY IF EXISTS "Users can update their own customers" ON customers;
DROP POLICY IF EXISTS "Users can delete their own customers" ON customers;

DROP POLICY IF EXISTS "Users can view invoices for their customers" ON invoices;
DROP POLICY IF EXISTS "Users can insert invoices for their customers" ON invoices;
DROP POLICY IF EXISTS "Users can update invoices for their customers" ON invoices;
DROP POLICY IF EXISTS "Users can delete invoices for their customers" ON invoices;

DROP POLICY IF EXISTS "Users can view transactions for their invoices" ON transactions;
DROP POLICY IF EXISTS "Users can insert transactions for their invoices" ON transactions;
DROP POLICY IF EXISTS "Users can update transactions for their invoices" ON transactions;
DROP POLICY IF EXISTS "Users can delete transactions for their invoices" ON transactions;

-- Create RLS policies for customers
CREATE POLICY "Users can view their own customers" ON customers
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own customers" ON customers
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own customers" ON customers
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own customers" ON customers
  FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for invoices
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

-- Create RLS policies for transactions
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_customers_user_id ON customers(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_transactions_invoice_id ON transactions(invoice_id);
CREATE INDEX IF NOT EXISTS idx_transactions_payment_date ON transactions(payment_date);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);