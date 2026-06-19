FROM python:3.10-slim  # Use the official Python 3.10 slim base image to keep the image size small

WORKDIR /app  # Set /app as the working directory inside the container for all subsequent commands

COPY requirements.txt .  # Copy only the dependency list first to leverage Docker layer caching

RUN pip install --upgrade pip && \  # Upgrade pip to the latest version
    pip install --no-cache-dir -r requirements.txt  # Install all Python dependencies without storing the pip cache

COPY . .  # Copy all remaining project files into the container working directory

RUN ls -la /app  # List container files at build time for build-step debugging and verification

ENV PYTHONPATH=/app  # Add /app to Python's module search path so "app.main" resolves correctly

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]  # Start the uvicorn ASGI server, binding to all network interfaces on port 8000
