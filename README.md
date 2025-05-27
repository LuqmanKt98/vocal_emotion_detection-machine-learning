# Vocal Emotion Detection App

This application detects emotions from voice recordings using a Flutter frontend and a Node.js backend that runs a Python machine learning model.

## System Architecture

1. **Flutter Frontend**: Mobile app that allows users to record their voice and displays detected emotions
2. **Node.js Backend**: Server that handles API requests and communicates with the Python script
3. **Python Script**: Uses the Hugging Face Transformers library to detect emotions from audio

## Setup Instructions

### Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Node.js (version 14 or higher)
- Python (version 3.8 or higher)
- npm (comes with Node.js)

### Backend Setup

1. Install Node.js dependencies:
   ```bash
   cd backend
   npm install
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Start the backend server:
   ```bash
   npm run dev
   ```

### Frontend Setup

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Update the backend URL:
   - Open `lib/main.dart`
   - Change the `backendUrl` variable to your server's IP address

3. Run the Flutter app:
   ```bash
   flutter run
   ```

## Usage

1. Launch the app
2. Tap the microphone button to start recording
3. Speak for a few seconds
4. Tap the stop button to end recording
5. The app will process your voice and display the detected emotions with confidence scores

## Features

- Real-time audio recording with visualization
- Audio processing on the server
- Display of top detected emotions with confidence levels
- User-friendly interface

## Troubleshooting

- If the app cannot connect to the server, check that:
  - The backend server is running
  - The backendUrl in the Flutter app is correct
  - Your device is on the same network as the server

- If emotion detection is not working:
  - Ensure all Python dependencies are installed correctly
  - Check the server logs for any errors
