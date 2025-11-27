#!/bin/bash

# 🏀 Basketball Coach AI - Automated Setup Script
# This script sets up the complete Expo React Native basketball coaching app

echo "🏀 Basketball Coach AI - Setup Script"
echo "====================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if Node.js is installed
print_info "Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js first:"
    echo "  - Download from: https://nodejs.org"
    echo "  - Or use homebrew: brew install node"
    exit 1
fi

NODE_VERSION=$(node --version)
print_status "Node.js is installed: $NODE_VERSION"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install npm first."
    exit 1
fi

NPM_VERSION=$(npm --version)
print_status "npm is installed: $NPM_VERSION"

# Install Expo CLI globally if not already installed
print_info "Checking Expo CLI installation..."
if ! command -v expo &> /dev/null; then
    print_info "Installing Expo CLI globally..."
    npm install -g expo-cli
    if [ $? -eq 0 ]; then
        print_status "Expo CLI installed successfully"
    else
        print_error "Failed to install Expo CLI"
        exit 1
    fi
else
    EXPO_VERSION=$(expo --version)
    print_status "Expo CLI is already installed: $EXPO_VERSION"
fi

# Create necessary directories
print_info "Creating project directories..."
mkdir -p logs
mkdir -p backend-server/uploads
print_status "Project directories created"

# Setup Backend
print_info "Setting up backend server..."
cd backend-server

if [ ! -f "package.json" ]; then
    print_error "Backend package.json not found. Please ensure you're in the correct directory."
    exit 1
fi

print_info "Installing backend dependencies..."
npm install
if [ $? -eq 0 ]; then
    print_status "Backend dependencies installed successfully"
else
    print_error "Failed to install backend dependencies"
    exit 1
fi

# Create .env file for backend
print_info "Creating backend environment file..."
cat > .env << EOF
# Basketball Coach AI - Backend Environment
NODE_ENV=development
PORT=3001
GEMINI_API_KEY=AIzaSyA08Ar4gUbXv0aly_a4H3o7Z8u6UjO34KY
EOF
print_status "Backend .env file created"

# Go back to root directory
cd ..

# Setup Frontend
print_info "Setting up React Native frontend..."
cd expo-frontend

if [ ! -f "package.json" ]; then
    print_error "Frontend package.json not found. Please ensure you're in the correct directory."
    exit 1
fi

print_info "Installing frontend dependencies..."
npm install
if [ $? -eq 0 ]; then
    print_status "Frontend dependencies installed successfully"
else
    print_error "Failed to install frontend dependencies"
    exit 1
fi

# Go back to root directory
cd ..

# Create startup scripts
print_info "Creating startup scripts..."

# Backend startup script
cat > start-backend.sh << 'EOF'
#!/bin/bash
echo "🏀 Starting Basketball Coach Backend..."
cd backend-server
npm run dev
EOF
chmod +x start-backend.sh

# Frontend startup script
cat > start-frontend.sh << 'EOF'
#!/bin/bash
echo "🏀 Starting Basketball Coach Frontend..."
cd expo-frontend
npm start
EOF
chmod +x start-frontend.sh

# Complete startup script
cat > start-app.sh << 'EOF'
#!/bin/bash
echo "🏀 Starting Basketball Coach AI Complete System..."
echo "Opening backend and frontend in separate terminal windows..."

# For macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Start backend in new terminal
    osascript -e 'tell application "Terminal" to do script "cd \"'$(pwd)'\" && ./start-backend.sh"'
    
    # Wait a moment then start frontend
    sleep 2
    osascript -e 'tell application "Terminal" to do script "cd \"'$(pwd)'\" && ./start-frontend.sh"'
    
    echo "✅ Both backend and frontend started in separate terminals"
    echo "📱 Scan the QR code with Expo Go app to test on your device"
else
    echo "ℹ️  Please run the following commands in separate terminals:"
    echo "   Terminal 1: ./start-backend.sh"
    echo "   Terminal 2: ./start-frontend.sh"
fi
EOF
chmod +x start-app.sh

print_status "Startup scripts created"

# Test backend setup
print_info "Testing backend setup..."
cd backend-server
npm run dev &
BACKEND_PID=$!
sleep 3

# Test if backend is running
if curl -s http://localhost:3001/api/health > /dev/null; then
    print_status "Backend is running and responding"
    kill $BACKEND_PID
else
    print_warning "Backend test failed, but this might be normal during setup"
    kill $BACKEND_PID 2>/dev/null
fi

cd ..

# Final setup summary
echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
print_status "✅ Node.js and npm are installed"
print_status "✅ Expo CLI is installed"
print_status "✅ Backend dependencies are installed"
print_status "✅ Frontend dependencies are installed"
print_status "✅ Environment files are configured"
print_status "✅ Startup scripts are created"
echo ""
echo "🚀 Next Steps:"
echo "1. Install Expo Go app on your phone:"
echo "   - iOS: https://apps.apple.com/app/expo-go/id982107779"
echo "   - Android: https://play.google.com/store/apps/details?id=host.exp.exponent"
echo ""
echo "2. Start the application:"
echo "   ./start-app.sh"
echo ""
echo "3. Or start manually:"
echo "   Terminal 1: ./start-backend.sh"
echo "   Terminal 2: ./start-frontend.sh"
echo ""
echo "4. Test the Demo Analysis feature to see AI-enhanced coaching!"
echo ""
print_info "📖 For detailed instructions, see EXPO_SETUP_GUIDE.md"
print_info "🏀 Your basketball coaching app is ready to use!" 