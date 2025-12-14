# Sound Resources

This directory contains audio files for screenshot capture feedback.

## Adding Custom Capture Sound

To add a custom capture sound effect:

1. Create or obtain an audio file in AIFF or WAV format
2. Name it `capture.aiff` or `capture.wav`
3. Place it in this directory
4. The sound should be short (< 1 second) and not too loud
5. Recommended sample rate: 44.1 kHz
6. Recommended bit depth: 16-bit

## Default Behavior

If no custom sound file is provided, the app will:
1. First attempt to use the macOS system camera shutter sound
2. Fall back to the system "Pop" sound if the camera sound is unavailable

## Example Sound Effects

You can find free sound effects from:
- macOS system sounds: `/System/Library/Sounds/`
- Create your own using GarageBand or other audio software
- Free sound libraries (ensure proper licensing)

## File Size

Keep audio files small (< 100 KB) to minimize app bundle size.
