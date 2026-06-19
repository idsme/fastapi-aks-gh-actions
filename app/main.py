from fastapi import FastAPI  # Import the FastAPI class from the fastapi library

app = FastAPI()  # Create the FastAPI application instance


@app.get("/")  # Register a GET route at the root URL path "/"
async def root():  # Define an asynchronous handler function for the root route
    return {"message": "Hello DEVOPS World V.2.0"}  # Return a JSON response with a greeting message
