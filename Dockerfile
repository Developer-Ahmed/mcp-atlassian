# Stage 1: Use uv-enabled image to install deps
FROM ghcr.io/astral-sh/uv:python3.10-alpine AS uv

WORKDIR /app
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# Copy project definition files
COPY pyproject.toml README.md ./

# Generate lock file
RUN uv lock

# Install dependencies without dev or project
RUN uv sync --frozen --no-install-project --no-dev --no-editable

# Copy the rest of the project
COPY . .

# Install the project itself
RUN uv sync --frozen --no-dev --no-editable

# Clean up unnecessary files in the virtual environment
RUN find /app/.venv -name '__pycache__' -type d -exec rm -rf {} + && \
    find /app/.venv -name '*.pyc' -delete && \
    find /app/.venv -name '*.pyo' -delete && \
    echo "Cleaned up .venv"

# Stage 2: Final minimal image
FROM python:3.10-alpine

# Create a non-root user
RUN adduser -D -h /home/app -s /bin/sh app
USER app
WORKDIR /app

# Copy project and venv from build stage
COPY --from=uv --chown=app:app /app /app
COPY --from=uv --chown=app:app /app/.venv /app/.venv

# Set PATH to use virtual environment
ENV PATH="/app/.venv/bin:$PATH"

# Expose default port
EXPOSE $PORT

# Entrypoint
ENTRYPOINT ["sh", "-c", "mcp-atlassian --transport streamable-http --port $PORT"]


