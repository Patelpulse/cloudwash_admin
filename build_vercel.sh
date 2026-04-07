#!/bin/bash

# Exit on error
set -e

if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PWD/flutter/bin:$PATH"
flutter doctor -v

# Create a dummy .env if it doesn't exist (to satisfy dotenv.load())
if [ ! -f .env ]; then
  echo "Creating dummy .env file"
  echo "API_URL=https://admin.cloudwash.in/api" > .env
fi

# Fetch dependencies
flutter pub get

# Build Flutter Web
flutter build web --release --dart-define=API_URL="${API_URL:-https://admin.cloudwash.in/api}"

# Some Vercel deployments may ignore SPA rewrites. Generate per-route index files
# so direct deep links (for example /login) keep working.
SPA_ROUTES=(
  "login"
  "users"
  "bookings"
  "analytics"
  "categories"
  "categories/add"
  "banners"
  "banners/add"
  "sub-categories"
  "sub-categories/add"
  "notifications"
  "notifications/add"
  "services"
  "services/add"
  "cities"
  "cities/add"
  "addons"
  "addons/add"
  "testimonials"
  "testimonials/add"
  "profile"
  "web-landing"
  "web-landing/hero"
  "web-landing/logo"
  "web-landing/about"
  "web-landing/stats"
  "web-landing/testimonials"
  "web-landing/why-choose-us"
  "web-landing/footer"
)

for route in "${SPA_ROUTES[@]}"; do
  mkdir -p "build/web/${route}"
  cp "build/web/index.html" "build/web/${route}/index.html"
done

# Copy build files to the root (Vercel expects them in the directory its told, but we can also just point Vercel to build/web)
# For now, we'll just keep them in build/web and point Vercel there.
