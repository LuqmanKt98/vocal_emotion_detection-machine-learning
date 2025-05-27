import os
import shutil
import uvicorn
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import tempfile
import json

# Import the emotion detection functionality directly
# Try to use the full emotion_detector first, fall back to simple if that fails
try:
    from emotion_detector import record_audio, detect_emotion
    print("Using full emotion detector")
except ImportError:
    # Fall back to simple implementation
    from simple_emotion_detector import record_audio, detect_emotion
    print("Using simplified emotion detector")

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
)

# Create uploads directory if it doesn't exist
os.makedirs("uploads", exist_ok=True)

class EmotionDetectionRequest(BaseModel):
    duration: int = 5
    isWebMode: bool = False

@app.get("/api/health")
async def health_check():
    return {"status": "OK", "message": "Server is running"}

@app.post("/api/detect-emotion")
async def detect_emotion_endpoint(request: EmotionDetectionRequest):
    try:
        print(f"Recording audio for {request.duration} seconds")
        
        # Record audio directly using our function
        audio_file = record_audio(duration=request.duration)
        
        print(f"Audio recorded successfully, now detecting emotion")
        
        # Detect emotion
        emotions = detect_emotion(audio_file)
        
        print(f"Detected emotions: {emotions}")
        
        return {"emotions": emotions}
    except Exception as e:
        print(f"Error: {str(e)}")
        return {"error": str(e)}

@app.post("/api/detect-emotion-from-file")
async def detect_emotion_from_file(audio: UploadFile = File(...)):
    try:
        # Save the uploaded file
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".wav")
        try:
            shutil.copyfileobj(audio.file, temp_file)
            temp_file_path = temp_file.name
        finally:
            temp_file.close()
            audio.file.close()
        
        print(f"Audio file uploaded to {temp_file_path}, now detecting emotion")
        
        # Detect emotion
        emotions = detect_emotion(temp_file_path)
        
        # Delete the temporary file
        os.unlink(temp_file_path)
        
        return {"emotions": emotions}
    except Exception as e:
        print(f"Error: {str(e)}")
        return {"error": str(e)}

if __name__ == "__main__":
    print("Starting FastAPI server at http://0.0.0.0:3001")
    uvicorn.run(app, host="0.0.0.0", port=3001) 