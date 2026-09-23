# PodRepeat

PodRepeat is a podcast player I built for language practice. It lets me tap one sentence in a transcript and replay that exact part of the episode until I understand it.

This is not my largest project, but it is the most personal one. I was tired of podcast apps pushing me towards another episode when I still had not understood the current one. I also did not want another subscription just to search a transcript or translate a sentence. PodRepeat therefore keeps the library small, uses ordinary RSS feeds, and does as much work as possible on the phone.

| Library | Sentences saved for review | Transcript and translation |
| --- | --- | --- |
| <img src="docs/screenshots/library.png" alt="PodRepeat podcast library" width="260"> | <img src="docs/screenshots/review.png" alt="PodRepeat repeated-sentence review list" width="260"> | <img src="docs/screenshots/transcript.png" alt="PodRepeat timestamped bilingual transcript" width="260"> |

[Download the Android APK](https://github.com/BitForLI/language-learning-podcast-app/releases/latest/download/podrepeat-android.apk)

## The learning loop

1. Add a podcast from RSS or Apple Podcasts search.
2. Open an episode and generate or import its transcript.
3. Tap any sentence to move to its timestamp.
4. Repeat a sentence, a paragraph, or the whole episode without creating separate audio clips.
5. Return to frequently repeated sentences from the review list.

A sentence enters the review list only after its timed loop finishes. The app records how often it was repeated and links it back to the original episode, so the list reflects actual practice rather than bookmarks I may never open again.

## Decisions I made on purpose

**No endless recommendation feed.** For language learning, I would rather understand a few favourite podcasts than collect hundreds of unplayed episodes. The library is limited to ten feeds to keep that focus.

**The transcript follows the original audio.** Sentence and paragraph loops use timestamps on the episode timeline. Moving between lines does not require pre-cut audio files.

**Local before cloud.** Subscriptions, listening history, transcripts, translations, and review data stay in the app's private storage during normal use. On supported Android devices, NVIDIA Parakeet creates English transcripts on device; Google ML Kit handles downloaded translation models on Android and iOS.

**A familiar interface, not a generated dashboard.** The visual direction borrows the soft, layered feel of Apple Podcasts because this is still a listening app. The learning controls are added around that experience instead of turning every function into a card on a home screen.

## What is implemented

- RSS subscriptions and Apple Podcasts search
- sentence, paragraph, and episode repetition
- timestamped VTT, SRT, and JSON transcript import
- on-device English transcription with Parakeet and Silero voice-activity detection
- offline translation after the required ML Kit model is downloaded
- playback position and speed restoration
- local review history and TXT transcript export

The Flutter app reads podcast services directly and does not need an API base URL. An older FastAPI implementation remains in [`backend/`](backend/) as a tested reference, but it is not part of the current runtime.

## A few implementation details

- [`playback_controller.dart`](lib/features/player/application/playback_controller.dart) owns timed repetition on the original episode.
- [`mobile_on_device_transcriber.dart`](lib/features/player/data/mobile_on_device_transcriber.dart) runs sherpa-onnx work outside the UI isolate and publishes transcript chunks as they finish.
- [`local_podcast_repository.dart`](lib/features/library/data/local_podcast_repository.dart) stores the library and listening state locally.
- [`review_sentence.dart`](lib/features/progress/domain/review_sentence.dart) defines the review item created after a completed sentence loop.

The tests cover playback ranges, transcript/audio binding, local storage, and review behaviour. They do not claim a particular speech-recognition accuracy: results depend on the recording and device.

## Run and verify

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

The reference backend has its own tests:

```bash
cd backend
python -m pytest tests -q
```

## Current limits

- Models and episode audio must be downloaded before local transcription.
- Imported transcript formats can be read, but synchronized navigation requires transcript timing that matches the retained recording.
- The app does not yet provide a complete data export for moving between installations.
- APKs before v1.0.7 used temporary debug certificates and cannot be upgraded in place to a persistently signed release.

Release builds use a private signing key supplied through GitHub Actions secrets. The Dart package name `listen`, Android application ID `com.listenapp.listen`, and storage filename are retained for compatibility with existing installations.
