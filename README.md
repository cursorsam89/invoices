# Business Record Management - Flutter Web App

A comprehensive business record management application built with Flutter Web and Supabase backend. Manage customers, invoices, and payment transactions with real-time updates and a beautiful, modern UI.

## ✨ New Features & Enhancements

### 🎨 Modern UI Design
- **Beautiful Authentication Screen**: Animated gradient background with modern form design
- **Enhanced Dashboard**: Card-based layout with welcome section and improved stats display
- **Modern Customer Cards**: Gradient avatars and better information organization
- **Responsive Design**: Mobile-first approach with adaptive layouts
- **Smooth Animations**: Fade and slide transitions throughout the app
- **Professional Color Scheme**: Modern indigo gradient (#6366F1 to #8B5CF6)

### 🚀 Deployment Ready
- **GitHub Pages**: Automatic deployment with GitHub Actions
- **Netlify/Vercel**: Easy deployment to popular platforms
- **PWA Support**: Progressive Web App features for better user experience
- **SEO Optimized**: Proper meta tags and semantic structure

## Features

- **Authentication**: Secure sign-up and sign-in with Supabase Auth
- **Dashboard**: Real-time overview of amount received and amount due
- **Customer Management**: Add, edit, and delete customers with automatic invoice generation
- **Invoice Tracking**: View and manage invoices with payment status
- **Payment Processing**: Add payments and track transaction history
- **Real-time Updates**: Live data synchronization using Supabase subscriptions
- **Search & Filter**: Find customers and filter by overdue status
- **Responsive Design**: Modern UI optimized for web browsers
- **Beautiful Loading States**: Custom loading screens and spinners
- **Enhanced UX**: Improved user experience with better visual feedback

## Technology Stack

- **Frontend**: Flutter Web
- **Backend**: Supabase (Authentication, Database, Real-time subscriptions)
- **Database**: PostgreSQL (via Supabase)
- **State Management**: Flutter's built-in StatefulWidget
- **UI**: Material Design 3 with custom enhancements
- **Deployment**: GitHub Actions, Netlify, Vercel

## 🚀 Quick Deploy

### GitHub Pages (Recommended)
1. Push your code to GitHub
2. Enable GitHub Pages in repository settings
3. Configure environment variables in GitHub Secrets
4. Your app will be automatically deployed!

### Other Platforms
- **Netlify**: Drag & drop deployment
- **Vercel**: CLI deployment
- **Firebase Hosting**: Google's hosting platform

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions.

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
- Flutter SDK (3.19.0 or higher)
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
CREATE POLICY "Users can view their own invoices" ON invoices
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM customers 
      WHERE customers.id = invoices.customer_id 
      AND customers.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own invoices" ON invoices
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM customers 
      WHERE customers.id = invoices.customer_id 
      AND customers.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own invoices" ON invoices
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM customers 
      WHERE customers.id = invoices.customer_id 
      AND customers.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their own invoices" ON invoices
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM customers 
      WHERE customers.id = invoices.customer_id 
      AND customers.user_id = auth.uid()
    )
  );

-- Transactions policies
CREATE POLICY "Users can view their own transactions" ON transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM invoices 
      JOIN customers ON customers.id = invoices.customer_id 
      WHERE invoices.id = transactions.invoice_id 
      AND customers.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own transactions" ON transactions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM invoices 
      JOIN customers ON customers.id = invoices.customer_id 
      WHERE invoices.id = transactions.invoice_id 
      AND customers.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own transactions" ON transactions
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM invoices 
      JOIN customers ON customers.id = invoices.customer_id 
      WHERE invoices.id = transactions.invoice_id 
      AND customers.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their own transactions" ON transactions
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM invoices 
      JOIN customers ON customers.id = invoices.customer_id 
      WHERE invoices.id = transactions.invoice_id 
      AND customers.user_id = auth.uid()
    )
  );
```

### 3. Environment Setup

1. Clone the repository:
```bash
git clone <your-repo-url>
cd business-record-management
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create a `.env` file in the root directory:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. Run the application:
```bash
flutter run -d chrome
```

## 🎨 UI Design System

### Color Palette
- **Primary**: #6366F1 (Indigo)
- **Secondary**: #8B5CF6 (Purple)
- **Accent**: #EC4899 (Pink)
- **Success**: #10B981 (Green)
- **Error**: #EF4444 (Red)
- **Background**: #F8FAFC (Light Gray)

### Typography
- **Headlines**: Bold, high contrast
- **Body**: Clean, readable fonts
- **Labels**: Medium weight for clarity

### Components
- **Cards**: Rounded corners (16px), subtle shadows
- **Buttons**: Gradient backgrounds, rounded corners (12px)
- **Inputs**: Filled style with focus states
- **Icons**: Consistent sizing and colors

## 📱 Responsive Design

The application is designed to work seamlessly across all devices:
- **Desktop**: Full-featured dashboard with side-by-side layouts
- **Tablet**: Adaptive layouts with touch-friendly controls
- **Mobile**: Mobile-first design with optimized navigation

## 🔒 Security Features

- **Row Level Security**: Database-level security policies
- **Authentication**: Secure Supabase Auth integration
- **Input Validation**: Client and server-side validation
- **Environment Variables**: Secure credential management

## 🚀 Performance Optimizations

- **Lazy Loading**: Efficient data loading
- **Real-time Updates**: Optimized subscriptions
- **Bundle Optimization**: Minimized web bundle size
- **Caching**: Smart caching strategies

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For support and questions:
- Create an issue in the GitHub repository
- Check the [deployment guide](DEPLOYMENT_GUIDE.md)
- Review the [setup guide](SETUP_GUIDE.md)

## 🎉 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the powerful backend platform
- Material Design for the design system inspiration

---

**Ready to deploy?** Check out the [Deployment Guide](DEPLOYMENT_GUIDE.md) for step-by-step instructions!
