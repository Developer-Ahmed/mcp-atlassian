# Stage 1: Use a base Python image with uv installed
FROM python:3.10-alpine AS build

# Install build dependencies
RUN apk add --no-cache curl build-base git

# Install uv manually (since you're not using Astral's BuildKit image anymore)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Create app dir
WORKDIR /app

# Copy project files
COPY pyproject.toml README.md ./
RUN /root/.cargo/bin/uv lock

# Install dependencies (no dev, frozen env)
COPY uv.lock ./
RUN /root/.cargo/bin/uv sync --frozen --no-install-project --no-dev --no-editable

# Now copy the source code and install the project
COPY . /app
RUN /root/.cargo/bin/uv sync --frozen --no-dev --no-editable

# Clean unnecessary files
RUN find /app/.venv -name '__pycache__' -type d -exec rm -rf {} + && \
    find /app/.venv -name '*.pyc' -delete && \
    find /app/.venv -name '*.pyo' -delete && \
    echo "Cleaned up .venv"

# Stage 2: Minimal runtime image
FROM python:3.10-alpine

# Create a non-root user
RUN adduser -D -h /home/app -s /bin/sh app
USER app
WORKDIR /app

# Copy the virtual environment
COPY --from=build --chown=app:app /app/.venv /app/.venv
COPY --from=build --chown=app:app /app /app

# Add venv to PATH
ENV PATH="/app/.venv/bin:$PATH"

# Expose the default port (9000 or set your own)
EXPOSE 9000

# Use the HTTP or SSE transport as needed
ENTRYPOINT ["mcp-atlassian"]

