FROM ghcr.io/cirruslabs/flutter:3.44.0 AS builder
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get
COPY . .
RUN flutter build web --release --base-href /

FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
