import numpy as np
import wave
import struct

# Create a simple test audio file (sine wave)
def create_test_audio(filename="test-audio.wav", duration=5, sample_rate=16000):
    amplitude = 32767
    frequency = 440  # A4 note
    
    num_samples = duration * sample_rate
    
    # Generate sine wave
    time_points = np.linspace(0, duration, num_samples)
    waveform = amplitude * np.sin(2 * np.pi * frequency * time_points)
    
    # Convert to 16-bit PCM
    waveform = waveform.astype(np.int16)
    
    # Write to WAV file
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16 bits per sample
        wav_file.setframerate(sample_rate)
        
        for sample in waveform:
            packed_value = struct.pack('<h', sample)
            wav_file.writeframes(packed_value)
    
    print(f"Created test audio file: {filename}")

if __name__ == "__main__":
    create_test_audio() 