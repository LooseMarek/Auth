FROM swift:6.2-jammy AS build
WORKDIR /app
COPY . .
RUN swift build -c release

FROM ubuntu:jammy-slim
RUN apt-get update && apt-get install -y libssl-dev libsqlite3-dev && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/.build/release/Run .
EXPOSE 8080
CMD ["./Run", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
