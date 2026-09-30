# Build stage
FROM golang:alpine AS builder

# Enable automatic Go toolchain fetching and CA certificates
ENV GOTOOLCHAIN=auto
RUN apk add --no-cache ca-certificates git

WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build statically-linked binaries for Linux
# Build packages, not single files, so every file of a command is included.
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/dairy-api ./cmd/api
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/dairy-migrate ./cmd/migrate
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/dairy-cli ./cmd/tusk

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