FROM cirrusci/flutter:stable

WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . ./

RUN flutter build web --release

EXPOSE 8080
CMD ["bash", "-lc", "flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080"]
