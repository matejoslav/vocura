# Vocura

[![Tests](https://github.com/matejoslav/vocura/actions/workflows/tests.yml/badge.svg)](https://github.com/matejoslav/vocura/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS 14+](https://img.shields.io/badge/Platform-macOS%2014%2B-lightgrey.svg)](#requirements)

A lightweight macOS menu bar app for voice-to-text transcription using a customizable hotkey.

Built with SwiftUI. Press a hotkey anywhere, speak, and the transcribed text is inserted at your cursor.

> **Note:** This is an exploratory project to learn more about macOS development and Swift.

## Features

- **Global Hotkey**: Press a customizable keyboard shortcut (default: ⇧⌘Space) to start/stop recording
- **Speech-to-Text**: Uses [Deepgram](https://deepgram.com/) API for transcription
- **Auto-Insert**: Automatically inserts transcribed text at your cursor position
- **Menu Bar App**: Stays in the menu bar, never clutters your dock
- **Secure**: API keys stored securely in macOS Keychain

## Supported Speech-to-Text Technologies

Vocura is designed to support multiple speech-to-text (STT) backends. The table below tracks what is currently available and what is planned.

| Provider | Status | Notes |
| --- | --- | --- |
| [Deepgram](https://deepgram.com/) | ✅ Supported | Cloud API, uses the `nova-2` model with smart formatting |

> More providers are planned. The goal is to let you choose between different cloud services and on-device transcription. Contributions and suggestions are welcome.

## Requirements

- macOS 14.0 (Sonoma) or later
- [Deepgram API key](https://console.deepgram.com/signup) (free tier available)
- Accessibility permissions (required for text insertion)

## Installation

### Building from Source

1. Clone the repository:

   ```bash
   git clone https://github.com/matejoslav/vocura.git
   cd vocura
   ```

2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) (one-time):

   ```bash
   brew install xcodegen
   ```

3. Generate the Xcode project:

   ```bash
   xcodegen
   ```

4. Open `Vocura.xcodeproj` in Xcode and hit Run, or build from the command line:

   ```bash
   xcodebuild -project Vocura.xcodeproj -scheme Vocura -configuration Release build -derivedDataPath build clean build
   ```

   The built app will be under `build/Build/Products/Release/Vocura.app`.

### Running Tests

```bash
xcodebuild -project Vocura.xcodeproj -scheme Vocura test
```

Tests also run automatically on every push and pull request via GitHub Actions.

## Setup

1. Launch Vocura
2. Grant Accessibility permissions when prompted (required for text insertion)
3. Click the Vocura icon in the menu bar and select **Settings**
4. Enter your Deepgram API key
5. (Optional) Customize the hotkey

## Usage

1. Place your cursor where you want text to appear
2. Press the hotkey (default: ⇧⌘Space) to start recording
3. Speak clearly
4. Press the hotkey again to stop recording
5. The transcribed text will be automatically inserted at your cursor position

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)
