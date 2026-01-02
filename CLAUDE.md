# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mousecape is a macOS cursor manager that uses private CoreGraphics APIs to customize system cursors. It consists of three main components:

1. **Mousecape.app** - The GUI application for managing cursor libraries ("capes")
2. **mousecloak** - Command-line tool for applying cursors and managing capes
3. **mousecloakHelper** - Background daemon that automatically re-applies cursors on login/user switch

## Building the Project

This is an Xcode project. Build commands:

```bash
# Open the project in Xcode
open Mousecape/Mousecape.xcodeproj

# Build from command line (requires full Xcode, not just Command Line Tools)
xcodebuild -project Mousecape/Mousecape.xcodeproj -scheme Mousecape -configuration Release
```

Note: The project uses Sparkle as a git submodule for auto-updates. Initialize with:
```bash
git submodule update --init --recursive
```

## Architecture

### Data Model

**MCCursorLibrary** ([src/models/MCCursorLibrary.h](Mousecape/Mousecape/src/models/MCCursorLibrary.h))
- Container for a collection of cursors (a "cape")
- Handles serialization to/from `.cape` files (which are plist dictionaries)
- Tracks dirty state and manages undo/redo
- Properties: name, author, identifier, version, fileURL

**MCCursor** ([src/models/MCCursor.h](Mousecape/Mousecape/src/models/MCCursor.h))
- Represents a single cursor with multiple scale representations
- Supports scales: 100%, 200%, 500%, 1000% (MCCursorScale enum)
- Properties: identifier, name, frameDuration, frameCount, size, hotSpot
- Each cursor can have multiple image representations at different scales
- Animated cursors stack frames vertically in a single image

**MCLibraryController** ([src/controllers/MCLibraryController.h](Mousecape/Mousecape/src/controllers/MCLibraryController.h))
- Manages the user's library of capes (stored in Application Support)
- Handles importing/exporting capes
- Applies capes by calling mousecloak functions
- Tracks which cape is currently applied

### GUI Structure

The app uses a Master-Detail pattern:

**Library Window** (MCLibraryWindowController/MCLibraryViewController)
- Shows all installed capes in the user's library
- Allows applying/restoring capes
- Double-clicking a cape opens it for editing

**Edit Window** (MCEditWindowController)
- Three-panel layout (NSSplitView):
  - **MCEditListController**: List of cursors in the cape
  - **MCEditDetailController**: Detail view for editing individual cursor properties (frames, size, hotspot)
  - **MCEditCapeController**: Cape metadata (name, author, version)

### CoreGraphics Integration

The core cursor manipulation happens through private CGS (CoreGraphics Services) APIs defined in [mousecloak/CGSInternal/CGSCursor.h](Mousecape/mousecloak/CGSInternal/CGSCursor.h).

**Key Functions:**
- `CGSRegisterCursorWithImages()` - Registers a custom cursor globally
- `CGSSetRegisteredCursor()` - Sets the active cursor
- `CoreCursorUnregisterAll()` - Resets to default system cursors
- `CGSCopyRegisteredCursorImages()` - Retrieves currently registered cursor data

**Implementation in [mousecloak/apply.m](Mousecape/mousecloak/apply.m):**
- `applyCursorForIdentifier()` - Registers a cursor with the system
- `applyCapeForIdentifier()` - Applies a single cursor from a cape dictionary
- `applyCape()` - Applies an entire cape
- `applyCapeAtPath()` - Loads and applies a cape file

**Backup/Restore ([mousecloak/backup.m](Mousecape/mousecloak/backup.m), [mousecloak/restore.m](Mousecape/mousecloak/restore.m)):**
- System cursors are backed up before custom capes are applied
- Backup stored in user preferences via MCPrefs
- Restore function retrieves backed-up cursors

### Helper Tool Installation

Uses ServiceManagement.framework to install a login item (mousecloakHelper) that runs `listener()` from [mousecloak/listen.m](Mousecape/mousecloak/listen.m). This re-applies the active cape when the cursor gets unregistered (e.g., user switch, login).

Implementation in [MCAppDelegate.m](Mousecape/Mousecape/MCAppDelegate.m):
- `SMLoginItemSetEnabled()` to install/uninstall
- `SMJobCopyDictionary()` to check installation status

## mousecloak CLI Tool

Command-line interface defined in [mousecloak/main.m](Mousecape/mousecloak/main.m):

**Commands:**
- `-a, --apply <path>` - Apply a cape file
- `-r, --reset` - Reset to default macOS cursors
- `-c, --create <dir>` - Create cape from directory structure
- `-x, --convert <file>` - Convert .MightyMouse file to cape
- `-e, --export <cape>` - Export cape to directory
- `-d, --dump <file>` - Dump currently applied cursors
- `-s, --scale [value]` - Get/set cursor scale multiplier
- `-o, --output <path>` - Specify output path for create/convert/export
- `--listen` - Run as daemon to re-apply cape on user events

## File Format

`.cape` files are binary plists containing:
- Cape metadata (name, author, identifier, version)
- Dictionary of cursor definitions keyed by cursor identifier (e.g., "com.apple.coregraphics.Arrow")
- Each cursor contains: size, hotspot, frameCount, frameDuration, and image representations

## Cursor Identifiers

Cursors use reverse-DNS identifiers like:
- `com.apple.coregraphics.Arrow`
- `com.apple.coregraphics.Wait`
- `com.apple.cursor.3` (IBeam)
- `com.apple.cursor.5` (Resize)

Full list can be discovered by examining system cursor names via `CGSCursorNameForSystemCursor()`.

## Special Features

**Left-handed Mode:**
- Preference stored via MCPrefs (MCPreferencesHandednessKey)
- Horizontally flips pointer cursors and adjusts hotspot
- Implemented in `applyCapeForIdentifier()` in [apply.m](Mousecape/mousecloak/apply.m)

**HiDPI Support:**
- Capes can include multiple scale representations (1x, 2x, 5x, 10x)
- System automatically selects appropriate scale
- Flag stored in cape metadata (`hiDPI` property)

## Code Organization

```
Mousecape/
├── Mousecape/                    # GUI app
│   ├── src/
│   │   ├── models/              # MCCursor, MCCursorLibrary
│   │   ├── controllers/         # Window/view controllers
│   │   ├── views/               # Custom views and cells
│   │   ├── categories/          # Obj-C category extensions
│   │   └── subclasses/          # NSFormatter subclasses
│   ├── external/                # Third-party code (BTRKit, MASPreferences, Rebel, Sparkle)
│   └── Base.lproj/              # XIB files
├── mousecloak/                  # CLI tool
│   ├── CGSInternal/             # Private CoreGraphics headers
│   ├── vendor/GBCli/            # Command-line parsing
│   ├── apply.m, backup.m, restore.m, create.m, listen.m, scale.m
│   └── MCDefs.m, MCPrefs.m      # Shared constants and preferences
└── mousecloakHelper/            # Login daemon (just runs listener())
```

## Important Patterns

1. **Memory Management**: This code uses manual retain/release (MRC), not ARC. Watch for `autorelease`, `retain`, `release` calls.

2. **Cursor Registration**: Always backup existing cursors before applying custom ones. The backup/restore mechanism is critical for resetting to defaults.

3. **Image Handling**: Animated cursors use a single vertically-stacked image. The code slices it based on `frameCount` and `size`.

4. **Error Handling**: CGSError codes from CoreGraphics functions should be checked against `kCGErrorSuccess`.

5. **Preferences**: Shared preferences between GUI and CLI use custom MCPrefs wrapper around CFPreferences.

## Testing Cursor Changes

To test cursor modifications:
1. Build the app
2. Create or import a test cape
3. Apply it (uses mousecloak functions)
4. Verify cursors changed system-wide
5. Use "Reset" or restart to restore defaults
