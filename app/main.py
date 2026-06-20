import os  # Import the os module to read environment variables set at container build time
from fastapi import FastAPI  # Import the FastAPI class from the fastapi library

app = FastAPI()  # Create the FastAPI application instance

# These are injected as Docker build args and baked into the image as environment variables
GIT_SHA    = os.getenv("GIT_SHA", "unknown")     # Full git commit SHA of the build — set by CI/CD pipeline
BUILD_TIME = os.getenv("BUILD_TIME", "unknown")  # UTC timestamp of when the Docker image was built
IMAGE_TAG  = os.getenv("IMAGE_TAG", "unknown")   # Image tag used (short SHA) — matches the ACR tag


@app.get("/")  # Register a GET route at the root URL path "/"
async def root():  # Define an asynchronous handler function for the root route
    return {"message": "Hello DEVOPS World V.2.0"}  # Return a JSON response with a greeting message


@app.get("/version")  # Register a GET route at /version for deployment verification
async def version():  # Returns build metadata so you can confirm exactly which commit is running
    return {
        "version":    "2.0",        # Application version — bump this manually when releasing a new version
        "git_sha":    GIT_SHA,      # Full commit SHA — compare with GitHub to verify the deployed commit
        "build_time": BUILD_TIME,   # When the Docker image was built (UTC ISO-8601)
        "image_tag":  IMAGE_TAG,    # Short SHA used as the ACR image tag for this build
    }


@app.get("/health")  # Register a GET route at /health for liveness/readiness probes
async def health():  # Lightweight endpoint — returns 200 OK so Kubernetes knows the pod is alive
    return {"status": "ok"}  # Minimal response; Kubernetes only needs a 2xx status code
