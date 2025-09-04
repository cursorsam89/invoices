#!/bin/bash

# Business Record Management - Deployment Script
# This script builds and prepares the app for deployment

echo "🚀 Business Record Management - Deployment Script"
echo "=================================================="

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    echo "   Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check Flutter version
echo "📱 Flutter version:"
flutter --version

# Enable web support
echo "🌐 Enabling web support..."
flutter config --enable-web

echo "cleaning the build"
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web
echo "🔨 Building for web..."
flutter build web --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "📁 Build output location: build/web/"
    echo ""
    echo "🚀 Deployment Options:"
    echo "1. GitHub Pages: Push to GitHub and enable Pages in settings"
    echo "2. Netlify: Drag and drop build/web/ folder to Netlify"
    echo "3. Vercel: Use 'vercel build/web/' command"
    echo "4. Firebase: Use 'firebase deploy' (after setup)"
    echo ""
    echo "📋 Next steps:"
    echo "- Configure environment variables (SUPABASE_URL, SUPABASE_ANON_KEY)"
    echo "- Set up your Supabase project"
    echo "- Test the application thoroughly"
    echo ""
    echo "📖 For detailed instructions, see DEPLOYMENT_GUIDE.md"
else
    echo "❌ Build failed. Please check the error messages above."
    exit 1
fi
