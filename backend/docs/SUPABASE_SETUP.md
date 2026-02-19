# 🗄️ Supabase Setup

## Tables

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE,
  phone_number VARCHAR(20) UNIQUE,
  password_hash VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE password_reset_tokens (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  otp TEXT,
  otp_expiry TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);