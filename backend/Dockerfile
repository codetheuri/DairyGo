# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build statically-linked binaries for Linux
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/dairy-api ./cmd/api/main.go
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/dairy-migrate ./cmd/migrate/main.go
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/dairy-cli ./cmd/tusk/main.go

# Runtime stage
FROM alpine:latest  

# Install CA certificates and tzdata for secure HTTPS and local time handling
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# Copy the binaries and database migrations from builder stage
COPY --from=builder /app/dairy-api .
COPY --from=builder /app/dairy-migrate .
COPY --from=builder /app/dairy-cli .
COPY --from=builder /app/database/migrations ./database/migrations

# Expose server port
EXPOSE 8081

# Run the API application binary
CMD ["./dairy-api"]