# Demo App# Demo App



Node.js application for MongoDB connectivity testing.Simple Node.js app for testing MongoDB connectivity in Kubernetes.



## Endpoints## API Endpoints



- `GET /healthz` - Health check (pings MongoDB)### GET /healthz

- `POST /orders` - Create order: `{"orderId": "ORDER-123"}`Health check - pings MongoDB.

- `GET /orders/count` - Get total order count

Returns 200 if healthy, 503 if not.

## Local Development

### POST /orders

```bashCreate an order.

npm install

npm start```json

```{"orderId": "ORDER-12345"}

```

## Docker

Returns `{inserted: true, id: "..."}`.

```bash

docker build -t demo-app .### GET /orders/count

docker run -p 3000:3000 -e MONGO_URI=mongodb://... demo-appGet total order count.

```

Returns `{count: 42}`.

## Environment Variables

### GET /orders

- `PORT` - Server port (default: 3000)List all orders (max 100).

- `MONGO_URI` - MongoDB connection string

- `MONGO_DB` - Database name## Configuration

- `MONGO_COLLECTION` - Collection name

Environment variables (injected by Kubernetes):

- `PORT` - Server port (default: 3000)
- `MONGO_URI` - MongoDB connection string
- `MONGO_DB` - Database name (default: app)
- `MONGO_COLLECTION` - Collection name (default: orders)

## Local Development

```bash
npm install

export MONGO_URI="mongodb://appuser:password@localhost:27017/app"
npm start
```

## Docker

```bash
docker build -t demo-app:latest .

docker run -p 3000:3000 \
  -e MONGO_URI="mongodb://appuser:password@mongodb:27017/app" \
  demo-app:latest
```

## Testing

```bash
# Health
curl http://localhost:3000/healthz

# Create order
curl -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -d '{"orderId":"ORDER-001"}'

# Count
curl http://localhost:3000/orders/count
```

## Logs

Structured JSON logging:
```json
{"timestamp":"2025-12-11T10:30:00.000Z","method":"POST","path":"/orders","status":201,"latency_ms":45,"user_agent":"curl/7.79.1"}
```
