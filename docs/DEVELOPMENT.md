# Development Guide

This guide is for contributors working on `falken`.

## Backend Overview

`falken` uses local GGUF model files through `llama.cpp`, not LiteRT. The Swift package in `Packages/LlamaBackend` exposes `LlamaBackendKit`, which is used by `LocalAIManager` through the local responder path.

The required default model is:

```text
falken/Models/google_gemma-3-1b-it-Q4_K_M.gguf
```

Model files are ignored by Git. Do not commit model weights, caches, conversion output, lock files, or metadata.

## Before You Push

Run both warning-clean builds:

```sh
xcodebuild -quiet -project falken.xcodeproj -scheme falken -destination generic/platform=iOS build
xcodebuild -quiet -project falken.xcodeproj -scheme falken -destination platform=iOS\ Simulator,name=iPhone\ 17 build
```

The expected successful output is no output. Treat any compiler warning, build-system warning, or model validation warning as a regression.

## Main Architecture Rules

- Keep local model lifecycle in `LocalAIManager` and its extensions.
- Keep model filenames and resource expectations centralized in `LocalModelRegistry`.
- Keep bundle validation behavior aligned with `LocalModelResourceValidator` and the Xcode model validation build phase.
- Keep chat history bounded through `ChatHistoryPolicy`.
- Keep diagnostics local-only and avoid chat text or user identifiers.
- Keep `ChatResponding` as the responder boundary for local and remote providers.

## SwiftUI and Concurrency Rules

- Do not publish `@Published` state from SwiftUI view update callbacks.
- Prefer native SwiftUI controls before adding UIKit bridges.
- Keep persisted Codable value models and non-UI stores usable outside main-actor contexts.
- Validate warning behavior with simulator builds because Swift concurrency diagnostics can differ from generic-device builds.

## Chat Persistence Behavior

On cold launch, the previously active persisted conversation is moved into Recent Chats and the visible chat starts empty. This is intentional so users see the welcome screen after relaunch and can resume old chats from the sidebar or drawer.

Normal in-app navigation still archives the active chat when users start a new chat, load another chat, rename a chat, or archive explicitly.

## Local Model Behavior

The model loads lazily when local inference is needed. It unloads on:

- memory warnings
- app backgrounding
- app termination
- serious or critical thermal pressure
- repeated generation timeouts
- model profile changes
- settings changes

Settings changes are persisted immediately but take effect on the next model load.

## Device Validation

Simulator builds are not enough for memory-sensitive changes. Test model loading, generation, cancellation, settings changes, and diagnostics on the physical device class you care about, especially older devices such as iPhone 11 Pro.
