# ai

`ai` is a minimal, offline-first iOS chat application for iPhone and iPad. The app provides a focused ChatGPT-style interface backed by a local quantized model through a Swift Package wrapper around `llama.cpp`.

The default path is local inference. Network-backed model providers can be added behind the existing responder abstraction without replacing the on-device architecture.

## Architecture

The codebase is organized around a small SwiftUI/MVVM structure:

- `ai/Views`: SwiftUI screens and reusable UI components.
- `ai/ViewModels`: presentation state and chat orchestration.
- `ai/Models`: value types for chat state, runtime state, local model settings, diagnostics, presets, and history policy.
- `ai/Services`: local model lifecycle, chat responders, memory policy, settings persistence, and chat history persistence.
- `Packages/LlamaBackend`: local Swift Package exposing `LlamaBackendKit`, a thin Swift API over the `llama.cpp` XCFramework binary target.

Important runtime components:

- `LocalAIManager`: owns local model load/unload, generation, diagnostics, settings, memory handling, and cancellation.
- `LlamaLocalEngine`: wraps the native backend, applies the model chat template, streams tokens, and truncates prompt history by token budget.
- `ChatViewModel`: owns UI state, chat persistence, runtime state, recent chats, sharing, archiving, renaming, and bounded history pruning.
- `ChatHistoryPolicy`: keeps restored and persisted chat history bounded for memory and storage safety.
- `LocalModelMemoryPolicy`: blocks model loading when memory, model size, or thermal state make local inference unsafe.

## Requirements

- Xcode with iOS SDK support.
- iOS 17 or newer for the local backend package.
- A physical iPhone or iPad is recommended for local model testing.
- The quantized GGUF model file must be installed locally before building/running with offline inference.

The expected model resource is:

```text
ai/Models/google_gemma-3-1b-it-Q4_K_M.gguf
```

Model weights are intentionally ignored by Git because they are large binary artifacts. Keep the filename above unless `LocalModelResource.swift` is updated to match a different model.

## Local Model Notes

This project is tuned around constrained-memory devices. The Settings screen exposes three model profiles:

- `Efficient`: lower context/output/thread pressure for older or warm devices.
- `Balanced`: recommended default profile.
- `Expanded`: larger context/output settings when memory allows.

Manual settings become `Custom` and are saved on device. Changing settings unloads the current model; the next generation reloads the model with the new options.

## Build

Open `ai.xcodeproj`, select the `ai` scheme, and build for a physical iOS device.

Command-line build used during development:

```sh
xcodebuild -quiet \
  -project ai.xcodeproj \
  -scheme ai \
  -destination generic/platform=iOS \
  -derivedDataPath /tmp/ai-derived \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Tested

The current implementation was build-tested with:

- Xcode command-line build using the `ai` scheme.
- Generic iOS device destination.
- iPhoneOS SDK 26.2.
- Local `LlamaBackend` Swift Package resolution.
- Bundled resource validation confirming only `google_gemma-3-1b-it-Q4_K_M.gguf` is present among model/cache-sensitive files.

Runtime behavior should still be validated on the target physical device, especially after changing model settings, because local inference performance and memory pressure depend on device RAM, thermal state, and the exact model file.

## Repository Hygiene

The repository excludes generated build output, user-specific Xcode state, editor state, secrets, and large local model artifacts. Keep model downloads and conversion caches outside Git.
