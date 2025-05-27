import pyaudio
import wave
import os
import time
import numpy as np
import librosa
import torch
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
    
    print(f"DEBUG: Starting recording for {duration} seconds...")
    
    try:
        # Initialize PyAudio
        p = pyaudio.PyAudio()
        
        print("DEBUG: PyAudio initialized")
        
        # Open stream
        stream = p.open(format=audio_format,
                        channels=channels,
                        rate=sample_rate,
                        input=True,
                        frames_per_buffer=chunk)
        
        print("DEBUG: Audio stream opened")
        
        frames = []
        
        # Record audio in chunks
        total_chunks = int(sample_rate / chunk * duration)
        for i in range(0, total_chunks):
            if i % (total_chunks // 5) == 0:
                print(f"DEBUG: Recording progress {i}/{total_chunks} chunks...")
            data = stream.read(chunk)
            frames.append(data)
        
        print("DEBUG: Recording finished!")
        
        # Stop and close the stream
        stream.stop_stream()
        stream.close()
        p.terminate()
        
        print("DEBUG: Audio stream closed")
        
        # Save the recorded audio as a WAV file
        wf = wave.open(filename, 'wb')
        wf.setnchannels(channels)
        wf.setsampwidth(p.get_sample_size(audio_format))
        wf.setframerate(sample_rate)
        wf.writeframes(b''.join(frames))
        wf.close()
        
        print(f"DEBUG: Audio saved as {filename}")
        return filename
    except Exception as e:
        print(f"ERROR in recording: {str(e)}")
        raise

def detect_emotion(audio_file):
    """
    Detect emotion from an audio file using Hugging Face Transformers.
    
    Args:
        audio_file: Path to the audio file
    
    Returns:
        The detected emotion label
    """
    print("DEBUG: Loading emotion recognition model...")
    
    try:
        # Load audio file
        print(f"DEBUG: Loading audio file {audio_file}")
        speech_array, sampling_rate = librosa.load(audio_file, sr=16000)
        print(f"DEBUG: Audio loaded, shape: {speech_array.shape}, sampling rate: {sampling_rate}")
        
        # Use a public emotion recognition model
        model_name = "superb/wav2vec2-base-superb-er"
        print(f"DEBUG: Using model: {model_name}")
        
        # Initialize the audio classification pipeline with explicit PyTorch backend
        print("DEBUG: Initializing audio classification pipeline...")
        classifier = pipeline(
            "audio-classification", 
            model=model_name,
            framework="pt"  # Explicitly use PyTorch
        )
        
        print("DEBUG: Pipeline initialized, analyzing emotion...")
        
        # Get emotion predictions
        preds = classifier(speech_array)
        
        print("DEBUG: Predictions obtained")
        
        # Get the top 3 emotions with their confidence scores
        top_emotions = preds[:3]
        
        # Format the emotion results
        result = {}
        for emotion in top_emotions:
            result[emotion["label"]] = f"{emotion['score']*100:.1f}%"
        
        print(f"DEBUG: Emotion results: {result}")
        return result
    except Exception as e:
        print(f"ERROR in emotion detection: {str(e)}")
        raise

def main():
    print("Emotion Detection from Speech")
    print("=============================")
    
    import sys
    
    try:
        print(f"DEBUG: Command line arguments: {sys.argv}")
        
        # Check if an audio file path was provided as an argument
        if len(sys.argv) > 1 and os.path.isfile(sys.argv[1]):
            # Use the provided audio file
            audio_file = sys.argv[1]
            print(f"DEBUG: Using provided audio file: {audio_file}")
        else:
            # Record new audio if no valid file was provided
            # If a number is provided, use it as the duration
            duration = 5
            if len(sys.argv) > 1:
                try:
                    duration = int(sys.argv[1])
                    print(f"DEBUG: Using provided duration: {duration}")
                except ValueError:
                    print(f"DEBUG: Could not parse {sys.argv[1]} as duration, using default")
                    
            print(f"DEBUG: About to record audio for {duration} seconds")
            audio_file = record_audio(duration=duration)
        
        print(f"DEBUG: Audio file ready at {audio_file}, detecting emotion...")
        
        # Detect emotion from the audio
        emotions = detect_emotion(audio_file)
        
        print("\nResults:")
        print("========")
        print("Detected emotions:")
        for emotion, confidence in emotions.items():
            print(f"- {emotion}: {confidence}")
        
        # Print JSON format for easier parsing
        import json
        print(json.dumps(emotions))
        
        print("DEBUG: Processing complete!")
    except Exception as e:
        print(f"ERROR in main: {str(e)}")
        # Return a simple error result that can be parsed by the server
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    main() 