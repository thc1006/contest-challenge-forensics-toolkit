FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install yq
RUN curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Install Python dependencies
RUN pip install --no-cache-dir PyYAML

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Create output directories
RUN mkdir -p outputs data/gharchive data/github data/urlscan data/ct data/dns data/wayback

# Set environment
ENV PYTHONUNBUFFERED=1

# Default command
CMD ["bash"]
