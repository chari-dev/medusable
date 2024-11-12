# `medusable`

> Portable e-commerce backend powered by Medusa.js

## ✨ Features

- 🚀 Ready-to-use Medusa.js backend
- 🐳 Production-ready Docker setup
- 📧 Email notifications with React Email
- 📦 Demo data included (products, categories, etc.)
- 🛠 Easy deployment & configuration

## 🚀 Getting Started

### Prerequisites

- Node.js 20.x
- PNPM 9.11.0+
- Docker & Docker Compose (for containerized setup)

### Using Docker (Recommended)

```bash
# Start services and setup database
pnpm docker:setup

# Start the application
docker compose up -d
```

### Local Development

```bash
# Install deps, setup database and create admin user
pnpm project:setup

# Start development server
pnpm dev
```

### Default Admin User

After setup, you can login to the admin dashboard with these credentials:
- Email: medusable@ouestlabs.com
- Password: medusable

## 🛠 Configuration

### Environment Variables

Required environment variables in `.env`:

```bash
AUTH_CORS=*
STORE_CORS=*
ADMIN_CORS=*
DISABLE_ADMIN=false
JWT_SECRET=your-secret
COOKIE_SECRET=your-secret
REDIS_URL=redis://redis:6379
BACKEND_URL=http://localhost:9000
DATABASE_URL=postgres://postgres:postgres@postgres:5432/medusable
```

### Docker Volumes

The application uses the following persistent volumes:
- `postgres_data`: PostgreSQL data
- `redis_data`: Redis data
- `uploads`: User uploads
- `static`: Static files

## 📧 Email Templates

Built with React Email for consistent styling and easy customization.

```bash
# Preview email templates
pnpm dev:email
```

Visit `http://localhost:9090` to preview templates.

## 🛠 Development Tools

### Database Operations

```bash
# Setup database
pnpm db:setup

# Seed demo data
pnpm db:seed

# Run migrations
pnpm db:migrate
```

### Other Tools

```bash
# Format code
pnpm format

# Clean build files
pnpm clean
```

## 📚 Documentation

- [Custom Modules](src/modules/README.md)
- [API Routes](src/api/README.md)
- [Admin UI](src/admin/README.md)
- [Medusa Documentation](https://docs.medusajs.com/)

## 📝 [MIT License](LICENSE)