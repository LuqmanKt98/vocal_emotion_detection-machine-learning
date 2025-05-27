import pyaudio
import wave
import os
import time
import numpy as np
import librosa
import torch
import sys
import json
from transformers import pipeline, AutoFeatureExtractor, AutoModelForAudioClassification

def record_audio(filename="recording.wav", duration=5, sample_rate=16000):
    """
    Record audio from the microphone for a specified duration.
    
    Args:
        filename: Name of the output audio file
        duration: Duration of recording in seconds
        sample_rate: Sample rate of the recording
    """
    # Audio recording parameters
    chunk = 1024
    audio_format = pyaudio.paInt16
    channels = 1
    
    print(f"Recording for {duration} seconds...")
    
    # Initialize PyAudio
    p = pyaudio.PyAudio()
    
    # Open stream
    stream = p.open(format=audio_format,
                    channels=channels,
                    rate=sample_rate,
                    input=True,
                    frames_per_buffer=chunk)
    
    frames = []
    
    # Record audio in chunks
    for i in range(0, int(sample_rate / chunk * duration)):
        data = stream.read(chunk)
        frames.append(data)
    
    print("Recording finished!")
    
    # Stop and close the stream
    stream.stop_stream()
    stream.close()
    p.terminate()
    
    # Save the recorded audio as a WAV file
    wf = wave.open(filename, 'wb')
    wf.setnchannels(channels)
    wf.setsampwidth(p.get_sample_size(audio_format))
    wf.setframerate(sample_rate)
    wf.writeframes(b''.join(frames))
    wf.close()
    
    print(f"Audio saved as {filename}")
    return filename

def detect_emotion(audio_file):
    """
    Detect emotion from an audio file using Hugging Face Transformers.
    
    Args:
        audio_file: Path to the audio file
    
    Returns:
        The detected emotion label
    """
    print("Loading emotion recognition model...")
    
    # Load audio file
    speech_array, sampling_rate = librosa.load(audio_file, sr=16000)
    
    # Use a public emotion recognition model
    model_name = "superb/wav2vec2-base-superb-er"
    
    # Initialize the audio classification pipeline with explicit PyTorch backend
    classifier = pipeline(
        "audio-classification", 
        model=model_name,
        framework="pt"  # Explicitly use PyTorch
    )
    
    print("Analyzing your emotion...")
    
    # Get emotion predictions
    preds = classifier(speech_array)
    
    # Get the top 3 emotions with their confidence scores
    top_emotions = preds[:3]
    
    # Format the emotion results
    result = {}
    for emotion in top_emotions:
        result[emotion["label"]] = f"{emotion['score']*100:.1f}%"
    
    return result

def main():
    # Check if file path is provided as argument
    if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
        # First argument is the file path
        file_path = sys.argv[1]
        print(f"Processing file: {file_path}")
        emotions = detect_emotion(file_path)
    else:
        # No file provided or file doesn't exist, record audio
        duration = 5  # Default duration
        if len(sys.argv) > 1:
            try:
                duration = int(sys.argv[1])
            except ValueError:
                pass
        
        print("Emotion Detection from Speech")
        print("=============================")
        
        # Record audio from the microphone
        audio_file = record_audio(duration=duration)
        
        # Detect emotion from the recorded audio
        emotions = detect_emotion(audio_file)
    
    print("\nResults:")
    print("========")
    print("Detected emotions:")
    for emotion, confidence in emotions.items():
        print(f"- {emotion}: {confidence}")
    
    # Print as JSON for easier parsing by Node.js
    print("\nJSON Output:")
    print(json.dumps(emotions))

if __name__ == "__main__":
    main() 