from fastapi import FastAPI


app = FastAPI()


@app.get("/")
async def root():    
    return {"message": "Hello DEVOPS World V.2.0"}