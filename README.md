# ADRDE Professional Secure Chat Application

A cross-platform secure chat application built with Flutter on the client side and a Node.js backend for real-time communication, deployment tooling, and local-network support.

This repository contains the complete source for a professional-grade messaging platform with secure local storage, networking utilities, desktop support, and operational setup guides.

## Overview

The project is organized as a multi-platform application with:

- Flutter/Dart frontend for mobile and desktop environments
- Node.js backend and helper scripts for service orchestration
- LAN and secure deployment utilities for local or internal network use
- Testing and validation scripts for timestamp, authentication, avatar, and message flow behavior

The application is designed to support professional use cases where secure communication, operational readiness, and deployment flexibility are important.

## Key Features

- Cross-platform Flutter application support
  - Android
  - iOS
  - Web
  - Windows
  - Linux
  - macOS
- Secure data handling and storage
  - encrypted / secure storage components
  - local persistence for app state and message data
- Real-time communication support
  - socket-based communication layer
  - backend integration for messaging workflows
- Professional deployment tooling
  - local network setup scripts
  - firewall configuration scripts
  - certificate generation and HTTPS support
- Diagnostics and troubleshooting
  - setup guides
  - deployment checklists
  - issue-specific troubleshooting documentation

## Tech Stack

### Client
- Flutter
- Dart
- Material Design UI
- Provider / Riverpod state management
- Secure storage and local persistence libraries

### Backend / Services
- Node.js
- JavaScript
- Express-like server patterns and local service tooling

### Supporting Tools
- Docker-style local setup patterns (through scripts and docs)
- LAN environmental setup for internal testing/deployment
- Custom smoke tests and validation utilities

## Repository Structure

```text
.
├── android/                  # Android project files
├── ios/                      # iOS project files
├── web/                      # Web app files
├── windows/                  # Windows desktop project files
├── linux/                    # Linux desktop project files
├── macos/                    # macOS desktop project files
├── lib/                      # Flutter app source code
├── assets/                   # Images, icons, animations, sounds
├── backend/                  # Backend service code and dependencies
├── docs/                     # Documentation assets
├── test/                     # Test suite and validation files
├── .dart_tool/               # Dart tooling metadata
├── .vscode/                 # Editor settings
├── .idea/                    # IDE metadata
├── analysis_options.yaml     # Dart lint configuration
├── pubspec.yaml              # Flutter package configuration
├── package.json              # Node package configuration
├── server.js                 # Backend entry point / server config
├── README.md                # Project overview
├── DEVELOPMENT_GUIDE.md      # Development instructions
├── DEPLOYMENT_CHECKLIST.md   # Deployment tasks and checks
├── LAN_SETUP_GUIDE.md        # Local network setup guide
├── DEFAULT_GROUP_FEATURE.md  # Feature notes
├── DEFAULT_GROUP_TROUBLESHOOTING.md
├── READ_RECEIPT_TEST_PLAN.md # Testing plan
├── *.bat                     # Windows setup / LAN / firewall helpers
├── *.js                      # Node / test utilities
├── *.dart                    # Dart test/debug scripts
└── ...
```

## Getting Started

### Prerequisites

Before running the project, ensure the following are installed:

- Flutter SDK and Dart
- Node.js and npm
- A compatible IDE such as VS Code or Android Studio
- Any required OS-specific tooling for the platform you plan to run

### Install dependencies

```bash
flutter pub get
```

For the JavaScript-based backend or tooling:

```bash
npm install
```

### Run the app

Use the project’s Flutter entry point for app startup and follow the instructions in the project documentation.

For local/network setup, refer to the included operational scripts and project guides.

## Project Documentation

The repository includes several operational and development guides:

- DEVELOPMENT_GUIDE.md
- DEPLOYMENT_CHECKLIST.md
- LAN_SETUP_GUIDE.md
- DEFAULT_GROUP_FEATURE.md
- DEFAULT_GROUP_TROUBLESHOOTING.md
- READ_RECEIPT_TEST_PLAN.md

These documents provide setup and troubleshooting details for local, LAN, and deployment-oriented workflows.

## Notes

This project appears to be a full application workspace rather than a small demo. It includes both app code and operational tooling, which makes it suitable for a real-world product environment or a professional secure chat prototype.

## License

This repository does not currently declare a license in the root metadata, so licensing terms should be confirmed before redistribution or public reuse.

## Contributing

Contributions and enhancements are welcome. Before making large changes, it is recommended to review the project documentation and run the relevant tests or validation scripts.

## Contact / Maintainer

Repository owner: Anmoldube

Project repository: https://github.com/Anmoldube/Final_code
