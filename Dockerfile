# ---------- Builder stage ----------
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies (for some pip packages)
RUN apt-get update && apt-get install -y --no-install-recommends gcc

# Install dependencies in a virtual environment
COPY requirements.txt .
RUN python -m venv /venv && \
    /venv/bin/pip install --no-cache-dir -r requirements.txt

# ---------- Final stage ----------
FROM python:3.11-slim

# Security best practices
RUN useradd -m appuser
WORKDIR /app

# Copy virtualenv from builder
COPY --from=builder /venv /venv

# Copy app code
COPY . .

USER appuser

# Expose Flask port
EXPOSE 5000

ENV PATH="/venv/bin:$PATH"

CMD ["python", "app.py"]
