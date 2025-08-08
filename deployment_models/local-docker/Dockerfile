FROM python:3.11-slim

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Set environment variables for Python and uv
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

WORKDIR /app

COPY pyproject.toml uv.lock* ./

# Install dependencies (production only, no dev dependencies)
RUN uv sync --frozen --no-dev

COPY ./src ./src

EXPOSE 8501

CMD ["uv", "run", "streamlit", "run", "src/Authentication.py"]
