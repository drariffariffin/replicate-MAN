"""
STT Melayu — Guna faster-whisper untuk transkrip audio ke teks Bahasa Melayu.
Usage: python whisper_melayu.py <wav_file>
"""
import sys
import os

def transcribe(audio_path):
    from faster_whisper import WhisperModel
    
    model_size = "small"
    print(f"Loading model '{model_size}'...", file=sys.stderr)
    
    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    
    print("Transcribing...", file=sys.stderr)
    segments, info = model.transcribe(audio_path, language="ms", beam_size=5)
    
    text = " ".join([seg.text for seg in segments])
    print(text)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python whisper_melayu.py <audio.wav>")
        sys.exit(1)
    
    audio_file = sys.argv[1]
    if not os.path.exists(audio_file):
        print(f"File not found: {audio_file}")
        sys.exit(1)
    
    transcribe(audio_file)
