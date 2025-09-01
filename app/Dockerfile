# ---- Build Stage ----
FROM node:23-alpine AS builder
WORKDIR /app

# Copy package files first (better cache)
COPY package*.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy the rest of the source code
COPY . .
RUN yarn build

# ---- Production Stage ----
FROM nginx:alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy build output from builder
COPY --from=builder /app/build /usr/share/nginx/html

# Copy custom nginx config for SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
