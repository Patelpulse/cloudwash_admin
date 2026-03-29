#!/bin/bash

# Exit on error
set -e

if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:$PWD/flutter/bin"
flutter doctor -v

# Create a dummy .env if it doesn't exist (to satisfy dotenv.load())
if [ ! -f .env ]; then
  echo "Creating dummy .env file"
  echo "API_URL=https://cloudwashapi.onrender.com/api" > .env
fi

# Fetch dependencies
flutter pub get

# Build Flutter Web
flutter build web --release --dart-define=API_URL="${API_URL:-https://cloudwashapi.onrender.com/api}"

# Copy build files to the root (Vercel expects them in the directory its told, but we can also just point Vercel to build/web)
# For now, we'll just keep them in build/web and point Vercel there.
