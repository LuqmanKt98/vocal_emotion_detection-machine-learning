import os
import json
from emotion_detector import detect_emotion

def main():
    # Use our test audio file
    test_audio = "test-audio.wav"
    
    if not os.path.exists(test_audio):
        print(f"Error: Test audio file '{test_audio}' not found")
        return
    
    print(f"Testing emotion detection on {test_audio}")
    
    try:
        # Detect emotion
        emotions = detect_emotion(test_audio)
        
        print("\nResults:")
        print("========")
        print("Detected emotions:")
        for emotion, confidence in emotions.items():
            print(f"- {emotion}: {confidence}")
            
        print("\nJSON output:")
        print(json.dumps(emotions))
        
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    main() 