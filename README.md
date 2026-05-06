# falken

`falken` is a minimal, offline-first iOS chat application for iPhone and iPad. The app provides a focused ChatGPT-style interface backed by a local quantized model through a Swift Package wrapper around `llama.cpp`.

The default path is local inference. Network-backed model providers can be added behind the existing responder abstraction without replacing the on-device architecture.

## Architecture

The codebase is organized around a small SwiftUI/MVVM structure:

- `falken/Views`: SwiftUI screens and reusable UI components.
- `falken/ViewModels`: presentation state and chat orchestration.
- `falken/Models`: value types for chat state, runtime state, local model settings, diagnostics, presets, and history policy.
- `falken/Services`: local model lifecycle, chat responders, memory policy, settings persistence, and chat history persistence.
- `Packages/LlamaBackend`: local Swift Package exposing `LlamaBackendKit`, a thin Swift API over the `llama.cpp` XCFramework binary target.

Important runtime components:

- `LocalAIManager`: owns local model load/unload, generation, diagnostics, settings, memory handling, and cancellation.
- `LlamaLocalEngine`: wraps the native backend, applies the model chat template, streams tokens, and truncates prompt history by token budget.
- `ChatViewModel`: owns UI state, chat persistence, runtime state, recent chats, sharing, archiving, renaming, and bounded history pruning.
- `ChatHistoryPolicy`: keeps restored and persisted chat history bounded for memory and storage safety.
- `LocalModelMemoryPolicy`: blocks model loading when memory, model size, or thermal state make local inference unsafe.
- `LocalModelProfile`: describes selectable local model profiles, from the bundled small/fast model to optional higher-quality GGUF profiles.
- `LocalModelResourceValidator`: validates bundled model resources and powers the Models screen installation status.

## Requirements

- Xcode with iOS SDK support.
- iOS 17 or newer for the local backend package.
- A physical iPhone or iPad is recommended for local model testing.
- The quantized GGUF model file must be installed locally before building/running with offline inference.

The expected model resource is:

```text
falken/Models/google_gemma-3-1b-it-Q4_K_M.gguf
```

Model weights are intentionally ignored by Git because they are large binary artifacts. Keep the filename above unless `LocalModelResource.swift` is updated to match a different model.

The Models screen also recognizes an optional higher-quality profile:

```text
falken/Models/google_gemma-3-4b-it-Q4_K_M.gguf
```

Only installed profiles can be selected. Larger profiles should be tested on target hardware before shipping because app size, RAM pressure, and thermal behavior change materially.

## Local Model Notes

This project is tuned around constrained-memory devices. The Settings screen exposes three model profiles:

- `Efficient`: lower context/output/thread pressure for older or warm devices.
- `Balanced`: recommended default profile.
- `Expanded`: larger context/output settings when memory allows.

Manual settings become `Custom` and are saved on device. Changing settings unloads the current model; the next generation reloads the model with the new options.

The app also includes:

- a first-run onboarding screen explaining the local model requirement,
- a Models screen for installed GGUF profile status and active profile selection,
- anonymized diagnostics copying for troubleshooting,
- an appearance preference for System, Dark, and restrained Light presentation.

## Build

Open `falken.xcodeproj`, select the `falken` scheme, and build for a physical iOS device.

Command-line build used during development:

```sh
xcodebuild -quiet \
  -project falken.xcodeproj \
  -scheme falken \
  -destination generic/platform=iOS \
  -derivedDataPath /tmp/falken-derived \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Tested

The current implementation was build-tested with:

- Xcode command-line build using the `falken` scheme.
- Generic iOS device destination.
- iPhoneOS SDK 26.2.
- Local `LlamaBackend` Swift Package resolution.
- Bundled resource validation confirming only `google_gemma-3-1b-it-Q4_K_M.gguf` is present among model/cache-sensitive files.

Runtime behavior should still be validated on the target physical device, especially after changing model settings, because local inference performance and memory pressure depend on device RAM, thermal state, and the exact model file.

## Repository Hygiene

The repository excludes generated build output, user-specific Xcode state, editor state, secrets, and large local model artifacts. Keep model downloads and conversion caches outside Git.
