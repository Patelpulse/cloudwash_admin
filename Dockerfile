# Stage 1: Build the Flutter Web App
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy package files and install dependencies to optimize caching
COPY pubspec.* ./
RUN flutter pub get

# Copy all the project files
COPY . .

# Build the application for web in release mode
RUN flutter build web --release

# Stage 2: Serve the app using Nginx
FROM nginx:alpine

# Copy the built web files from the previous stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration template
# The nginx alpine image will automatically run envsubst on this template and output to /etc/nginx/conf.d/default.conf
COPY default.conf.template /etc/nginx/templates/default.conf.template

# Expose dynamic PORT for Railway
ENV PORT=80
EXPOSE ${PORT}

# No CMD needed, Nginx base image handles starting the server
