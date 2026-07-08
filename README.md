# Marginalia

A minimal, fast, book-focused PDF reader for macOS. It provides a personal
library with categories, ratings, reading status, highlights, and margin
notes. All data is stored locally on disk — there is no cloud sync or
account system.

## Features

- Import PDFs into a local library (cover image and metadata are extracted
  automatically from the PDF).
- Library view with categories, search (title, author, note content),
  reading status, and star ratings.
- Dedicated reader window per book, with page-by-page or reflowed text
  viewing.
- Highlights and margin notes stored as PDFKit annotations directly on the
  PDF.
- Bookmarks per page.
- Four themes: Light, Paper, Dark, and System. Paper and Dark themes also
  recolor the PDF content itself (via Core Image filters), not just the
  app chrome.
- Localization: English and Turkish, switchable from the app menu.
- Keyboard-driven workflow (import, search, page turning, highlighting,
  bookmarking, theme switching, etc.).

## Tech stack

- **Swift 6**, built with the Swift Package Manager (no Xcode project
  required — Xcode Command Line Tools are sufficient).
- **SwiftUI** for the UI.
- **PDFKit** for PDF rendering, annotations, and text extraction.
- **Observation framework** (`@Observable`) for state management, backed by
  a JSON file on disk instead of SwiftData/CoreData.
- **AppKit** and **Core Image** for cover rendering and PDF color filtering.
- Target platform: **macOS 15+**.

## Project structure

The application lives in the `Marginalia/` directory:

```
Marginalia/
├── Package.swift               Swift package manifest (single executable target)
├── run.sh                      Build, package into a .app bundle, and launch
└── Sources/Marginalia/
    ├── MarginaliaApp.swift     App entry point
    ├── RootView.swift          Top-level view composition
    ├── Library/                Library grid, sidebar, and scope filtering
    ├── BookDetail/              Book detail and rating views
    ├── Reader/                  PDF/reflow reader, PDFKit integration, notes panel
    ├── Models/                  Book, Bookmark, Highlight, Category, ReadingStatus,
    │                            and the LibraryStore/LibraryStorage persistence layer
    ├── Import/                  PDF import and metadata/cover extraction
    ├── Theme/                   Theme tokens and environment (Light/Paper/Dark/System)
    ├── Utilities/               Shared layout helpers (e.g. FlowLayout)
    ├── Localization/            L10n helper
    └── Resources/               Info.plist and en/tr .lproj localization files
```

Core state lives in `Models/LibraryStore.swift`: all mutations to the
library go through it, and changes are persisted to a JSON file with a
500 ms debounce.

## Setup and running

Requirements: macOS 15 or later, Swift 6 toolchain (Xcode Command Line
Tools are enough — a full Xcode installation is not required).

```bash
cd Marginalia
./run.sh             # debug build, package as .app, and launch
./run.sh release      # optimized release build (recommended for daily use)
./run.sh build        # build and package only, without launching
```

After the first run, `Marginalia.app` is produced inside the `Marginalia/`
directory. You can drag it into `/Applications` to install it like a
regular app.

You can also build directly with Swift Package Manager:

```bash
cd Marginalia
swift build            # or: swift build -c release
```

## Data storage

All library data is stored locally at:

```
~/Library/Application Support/Marginalia/
├── library.json      All metadata: books, notes, categories, ratings, progress
└── Books/            Imported PDF copies
```

To back up your library, copy this directory. Removing a PDF from `Books/`
removes the corresponding book from the library.

## Status

This is a personal tool with no automated test suite. Current version:
V1.0 (local-only: import, library, reader, highlights and notes,
categories, reading status, ratings, theming, search).
