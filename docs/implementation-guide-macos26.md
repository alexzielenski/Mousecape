# macOS 26 Tahoe Implementation Guide

**Companion to:** [macos-26-tahoe-update-plan.md](macos-26-tahoe-update-plan.md)
**Purpose:** Detailed code-level implementation instructions

## Table of Contents

1. [ServiceManagement API Migration](#1-servicemanagement-api-migration)
2. [NSAlert Migration](#2-nsalert-migration)
3. [Entitlements Setup](#3-entitlements-setup)
4. [Build Settings Updates](#4-build-settings-updates)
5. [CGS API Compatibility Layer](#5-cgs-api-compatibility-layer)
6. [Testing Framework](#6-testing-framework)

---

## 1. ServiceManagement API Migration

### 1.1 Complete MCAppDelegate.m Refactor

**File:** `Mousecape/Mousecape/MCAppDelegate.m`

#### Replace Header
```objc
// Add to imports section (around line 10)
#import <ServiceManagement/ServiceManagement.h>

// Add availability check macro for backward compatibility
#define MOUSECAPE_SUPPORTS_SMAPPSERVICE (@available(macOS 13.0, *))
```

#### New Helper Method: Check Status
```objc
// Replace configureHelperToolMenuItem method (lines 54-64)
- (void)configureHelperToolMenuItem {
    BOOL isInstalled = NO;

    if (MOUSECAPE_SUPPORTS_SMAPPSERVICE) {
        // macOS 13+ - Use SMAppService
        SMAppService *service = [SMAppService loginItemServiceWithIdentifier:@"com.alexzielenski.mousecloakhelper"];
        SMAppServiceStatus status = service.status;
        isInstalled = (status == SMAppServiceStatusEnabled);
    } else {
        // macOS 12 and earlier - Use deprecated SMJobCopyDictionary
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CFDictionaryRef dict = SMJobCopyDictionary(kSMDomainUserLaunchd, CFSTR("com.alexzielenski.mousecloakhelper"));
        isInstalled = (dict != NULL);
        if (dict) CFRelease(dict);
#pragma clang diagnostic pop
    }

    [self.toggleHelperItem setTag:isInstalled ? 1 : 0];
    [self.toggleHelperItem setTitle:isInstalled ?
        NSLocalizedString(@"Uninstall Helper Tool", "Uninstall Helper Tool Menu Item") :
        NSLocalizedString(@"Install Helper Tool", "Install Helper Tool Menu Item")];
}
```

#### New Helper Method: Toggle Installation
```objc
// Replace toggleInstall method (lines 66-99)
- (IBAction)toggleInstall:(NSMenuItem *)sender {
    BOOL success = NO;
    NSError *error = nil;
    BOOL wasInstalled = (self.toggleHelperItem.tag != 0);

    if (MOUSECAPE_SUPPORTS_SMAPPSERVICE) {
        // macOS 13+ - Use SMAppService
        SMAppService *service = [SMAppService loginItemServiceWithIdentifier:@"com.alexzielenski.mousecloakhelper"];

        if (wasInstalled) {
            success = [service unregisterAndReturnError:&error];
        } else {
            success = [service registerAndReturnError:&error];
        }

        if (!success && error) {
            NSLog(@"SMAppService error: %@", error);
        }
    } else {
        // macOS 12 and earlier - Use deprecated SMLoginItemSetEnabled
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        success = SMLoginItemSetEnabled(CFSTR("com.alexzielenski.mousecloakhelper"), !wasInstalled);
#pragma clang diagnostic pop
    }

    if (success) {
        // Update menu item state
        [self configureHelperToolMenuItem];

        // Show appropriate alert
        if (wasInstalled) {
            [self showHelperUninstalledSuccessAlert];
        } else {
            [self showHelperInstalledSuccessAlert];
        }
    } else {
        [self showHelperErrorAlert:error];
    }
}
```

#### New Helper Methods: Alert Display
```objc
// Add new methods for showing alerts
- (void)showHelperInstalledSuccessAlert {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Success", "Helper Tool Install Result Title Success")];
    [alert setInformativeText:NSLocalizedString(@"The Mousecape helper was successfully installed", "Helper Tool Install Success Result description")];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", "Alert OK button")];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert runModal];
#ifndef __clang_analyzer__
    [alert release];
#endif
}

- (void)showHelperUninstalledSuccessAlert {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Success", "Helper Tool Uninstall Result Title Success")];
    [alert setInformativeText:NSLocalizedString(@"The Mousecape helper was successfully uninstalled", "Helper Tool Uninstall Success Result description")];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", "Alert OK button")];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert runModal];
#ifndef __clang_analyzer__
    [alert release];
#endif
}

- (void)showHelperErrorAlert:(NSError *)error {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Failure", "Helper Tool Result Title Failure")];

    NSString *message;
    if (error) {
        message = [NSString stringWithFormat:@"%@\n\nError: %@",
                   NSLocalizedString(@"The action did not complete successfully", "Helper Tool Result Failure Description"),
                   error.localizedDescription];
    } else {
        message = NSLocalizedString(@"The action did not complete successfully", "Helper Tool Result Failure Description");
    }

    [alert setInformativeText:message];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", "Alert OK button")];
    [alert setAlertStyle:NSAlertStyleCritical];
    [alert runModal];
#ifndef __clang_analyzer__
    [alert release];
#endif
}
```

### 1.2 Helper Bundle Info.plist Updates

**File:** `Mousecape/mousecloakHelper/Info.plist`

Ensure these keys exist:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.alexzielenski.mousecloakhelper</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${PRODUCT_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>

    <!-- CRITICAL: Make this a background-only app -->
    <key>LSBackgroundOnly</key>
    <true/>
    <key>LSUIElement</key>
    <true/>

    <!-- CRITICAL: For SMAppService -->
    <key>SMAuthorizedClients</key>
    <array>
        <string>identifier "com.alexzielenski.Mousecape" and anchor apple generic and certificate leaf[subject.CN] = "Mac Developer"</string>
    </array>
</dict>
</plist>
```

### 1.3 Main App Info.plist Updates

**File:** `Mousecape/Mousecape/Mousecape-Info.plist`

Add after line 50 (before NSMainNibFile):
```xml
<!-- Register the helper tool -->
<key>SMPrivilegedExecutables</key>
<dict>
    <key>com.alexzielenski.mousecloakhelper</key>
    <string>identifier "com.alexzielenski.mousecloakhelper" and anchor apple generic and certificate leaf[subject.CN] = "Mac Developer"</string>
</dict>
```

---

## 2. NSAlert Migration

### 2.1 Remove All NSRunAlertPanel Calls

**File:** `Mousecape/Mousecape/MCAppDelegate.m`

The NSRunAlertPanel calls have already been replaced in Section 1.1 above. Verify no other files use this deprecated function:

```bash
# Search for remaining usages
grep -r "NSRunAlertPanel" Mousecape/Mousecape/src/
```

If found, replace with the NSAlert pattern shown above.

---

## 3. Entitlements Setup

### 3.1 Main App Entitlements

**File:** `Mousecape/Mousecape/Mousecape.entitlements`

Replace entire file contents:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Sandbox: NOT ENABLED (would break cursor APIs) -->
    <!-- Note: Private CoreGraphics APIs likely incompatible with sandbox -->

    <!-- Hardened Runtime Options -->
    <key>com.apple.security.cs.allow-jit</key>
    <false/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <false/>
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <false/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>

    <!-- Network access for Sparkle updates -->
    <key>com.apple.security.network.client</key>
    <true/>

    <!-- File access for cape management -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>

    <!-- App Groups for sharing data with helper -->
    <key>com.apple.security.application-groups</key>
    <array>
        <string>$(TeamIdentifierPrefix)com.alexzielenski.mousecape</string>
    </array>
</dict>
</plist>
```

### 3.2 Helper Tool Entitlements

**File:** Create `Mousecape/mousecloakHelper/mousecloakHelper.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Hardened Runtime -->
    <key>com.apple.security.cs.allow-jit</key>
    <false/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <false/>

    <!-- App Groups for sharing with main app -->
    <key>com.apple.security.application-groups</key>
    <array>
        <string>$(TeamIdentifierPrefix)com.alexzielenski.mousecape</string>
    </array>
</dict>
</plist>
```

### 3.3 Add Entitlements to Xcode Project

1. Open `Mousecape.xcodeproj` in Xcode
2. Select "Mousecape" target
3. Go to "Signing & Capabilities" tab
4. Ensure "Automatically manage signing" is checked
5. Verify entitlements file is linked (should be automatic)
6. Repeat for "mousecloakHelper" target with its entitlements file

---

## 4. Build Settings Updates

### 4.1 Xcode Project Configuration

Open `Mousecape/Mousecape.xcodeproj/project.pbxproj` and update:

#### Deployment Target
Find all instances of:
```
MACOSX_DEPLOYMENT_TARGET = 10.13;
```

Replace with:
```
MACOSX_DEPLOYMENT_TARGET = 11.0;
```

**Locations:** Lines 1176, 1227 (approximately)

#### SDK Root
Verify:
```
SDKROOT = macosx;
```

This should automatically use the latest SDK.

#### Architecture Support
Add or verify:
```
ARCHS = "$(ARCHS_STANDARD)";
```

This ensures Universal Binary (arm64 + x86_64).

#### Hardened Runtime
For all targets (Mousecape, mousecloak, mousecloakHelper), add:
```
ENABLE_HARDENED_RUNTIME = YES;
```

### 4.2 Build Settings via Xcode UI

1. Open project in Xcode
2. Select each target (Mousecape, mousecloak, mousecloakHelper)
3. Build Settings tab:
   - **Deployment Target:** macOS 11.0
   - **Architectures:** Standard Architectures (arm64, x86_64)
   - **Enable Hardened Runtime:** YES
   - **Code Signing Identity:** Developer ID Application (for distribution)
   - **Other Code Signing Flags:** `--timestamp --options=runtime`

---

## 5. CGS API Compatibility Layer

### 5.1 Create Runtime Detection

**File:** Create `Mousecape/mousecloak/cgs_compatibility.h`

```objc
//
//  cgs_compatibility.h
//  Mousecape
//
//  Created for macOS 26 Tahoe compatibility
//

#ifndef cgs_compatibility_h
#define cgs_compatibility_h

#import <Foundation/Foundation.h>
#import "CGSInternal/CGSCursor.h"

// Runtime checks for CGS API availability
BOOL CGSCursorAPIsAvailable(void);

// Wrapper functions with error handling
CGError SafeCGSRegisterCursorWithImages(CGSConnectionID cid,
                                        char *cursorName,
                                        bool setGlobally,
                                        bool instantly,
                                        CGSize cursorSize,
                                        CGPoint hotspot,
                                        NSUInteger frameCount,
                                        CGFloat frameDuration,
                                        CFArrayRef imageArray,
                                        int *seed);

CGError SafeCGSSetRegisteredCursor(CGSConnectionID cid, char *cursorName, int *seed);

CGError SafeCoreReset All(CGSConnectionID cid);

#endif /* cgs_compatibility_h */
```

**File:** Create `Mousecape/mousecloak/cgs_compatibility.m`

```objc
//
//  cgs_compatibility.m
//  Mousecape
//

#import "cgs_compatibility.h"
#import <dlfcn.h>

// Function pointer types
typedef CGError (*CGSRegisterFunc)(CGSConnectionID, char*, bool, bool, CGSize, CGPoint, NSUInteger, CGFloat, CFArrayRef, int*);
typedef CGError (*CGSSetCursorFunc)(CGSConnectionID, char*, int*);
typedef CGError (*CGSUnregisterFunc)(CGSConnectionID);

// Check if CGS APIs are available at runtime
BOOL CGSCursorAPIsAvailable(void) {
    static BOOL checked = NO;
    static BOOL available = NO;

    if (!checked) {
        // Try to resolve the symbols dynamically
        void *handle = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY);
        if (handle) {
            available = (dlsym(handle, "CGSRegisterCursorWithImages") != NULL);
            // Don't dlclose - keep symbols available
        }
        checked = YES;
    }

    return available;
}

// Safe wrapper for CGSRegisterCursorWithImages
CGError SafeCGSRegisterCursorWithImages(CGSConnectionID cid,
                                        char *cursorName,
                                        bool setGlobally,
                                        bool instantly,
                                        CGSize cursorSize,
                                        CGPoint hotspot,
                                        NSUInteger frameCount,
                                        CGFloat frameDuration,
                                        CFArrayRef imageArray,
                                        int *seed) {
    if (!CGSCursorAPIsAvailable()) {
        MMLog(BOLD RED "CGS Cursor APIs not available on this macOS version!" RESET);
        return kCGErrorFailure;
    }

    // Call the actual function
    return CGSRegisterCursorWithImages(cid, cursorName, setGlobally, instantly,
                                      cursorSize, hotspot, frameCount, frameDuration,
                                      imageArray, seed);
}

// Safe wrapper for CGSSetRegisteredCursor
CGError SafeCGSSetRegisteredCursor(CGSConnectionID cid, char *cursorName, int *seed) {
    if (!CGSCursorAPIsAvailable()) {
        MMLog(BOLD RED "CGS Cursor APIs not available on this macOS version!" RESET);
        return kCGErrorFailure;
    }

    return CGSSetRegisteredCursor(cid, cursorName, seed);
}

// Safe wrapper for CoreCursorUnregisterAll
CGError SafeCoreResetAll(CGSConnectionID cid) {
    if (!CGSCursorAPIsAvailable()) {
        MMLog(BOLD RED "CGS Cursor APIs not available on this macOS version!" RESET);
        return kCGErrorFailure;
    }

    return CoreCursorUnregisterAll(cid);
}
```

### 5.2 Update apply.m to Use Compatibility Layer

**File:** `Mousecape/mousecloak/apply.m`

Add to imports:
```objc
#import "cgs_compatibility.h"
```

Replace line 22 (`CGError err = CGSRegisterCursorWithImages...`) with:
```objc
CGError err = SafeCGSRegisterCursorWithImages(CGSMainConnectionID(),
                                              idenfifier,
                                              true,
                                              true,
                                              size,
                                              hotSpot,
                                              frameCount,
                                              frameDuration,
                                              (__bridge CFArrayRef)images,
                                              &seed);
```

### 5.3 Add Files to Xcode Project

1. Add `cgs_compatibility.h` and `cgs_compatibility.m` to mousecloak target
2. Ensure they compile with `-fno-objc-arc` flag (match other mousecloak files)
3. Add to both mousecloak and mousecloakHelper targets

---

## 6. Testing Framework

### 6.1 Create Test Script

**File:** Create `Mousecape/scripts/test_cgs_apis.sh`

```bash
#!/bin/bash
# Test CGS API availability on macOS 26

echo "Testing CGS Cursor API Availability on macOS $(sw_vers -productVersion)"
echo "================================================================"

# Build mousecloak
echo "Building mousecloak..."
cd "$(dirname "$0")/.."
xcodebuild -project Mousecape.xcodeproj -target mousecloak -configuration Debug

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Test basic operations
echo ""
echo "Testing cursor reset (should restore defaults)..."
build/Debug/mousecloak --reset

echo ""
echo "Testing scale getter..."
build/Debug/mousecloak --scale

echo ""
echo "If both commands succeeded, basic CGS APIs are working!"
echo "Now test applying a cursor manually with: mousecloak --apply <path_to_cape>"
```

Make executable:
```bash
chmod +x Mousecape/scripts/test_cgs_apis.sh
```

### 6.2 Unit Test Checklist

Create `docs/testing-checklist.md`:

```markdown
# macOS 26 Testing Checklist

## Pre-Build Tests
- [ ] Project opens in Xcode 16+
- [ ] All targets build without errors
- [ ] All targets build without warnings
- [ ] Code signing succeeds
- [ ] Entitlements are correctly applied

## CGS API Tests
- [ ] `SafeCGSRegisterCursorWithImages()` returns success
- [ ] `SafeCGSSetRegisteredCursor()` returns success
- [ ] `SafeCoreResetAll()` returns success
- [ ] Cursor actually changes on screen
- [ ] Reset returns to system default

## Helper Tool Tests
- [ ] Helper installs without errors
- [ ] Helper shows as "Enabled" in System Settings > Login Items
- [ ] Helper uninstalls cleanly
- [ ] Helper re-applies cursor on login
- [ ] Helper re-applies cursor on user switch

## UI Tests
- [ ] Main window opens
- [ ] Library shows installed capes
- [ ] Can import a .cape file
- [ ] Can export a cape
- [ ] Can create new cape
- [ ] Can edit existing cape
- [ ] Apply button works
- [ ] Restore button works

## CLI Tests
- [ ] `mousecloak --help` works
- [ ] `mousecloak --reset` works
- [ ] `mousecloak --apply <cape>` works
- [ ] `mousecloak --scale` works
- [ ] `mousecloak --create` works
- [ ] `mousecloak --export` works

## Compatibility Tests
- [ ] Works on macOS 26 Apple Silicon
- [ ] Works on macOS 26 Intel
- [ ] Works on macOS 14 (Sonoma)
- [ ] Works on macOS 11 (Big Sur)

## Security Tests
- [ ] App opens without Gatekeeper warnings
- [ ] Code signature valid (`codesign -vvv --deep`)
- [ ] Notarization successful
- [ ] Hardened Runtime enabled
- [ ] No security prompts during normal use

## Performance Tests
- [ ] Cursor switch latency < 100ms
- [ ] Memory usage < 50MB
- [ ] Helper tool CPU < 1% when idle
- [ ] No memory leaks (Instruments)
```

---

## 7. Build and Notarization Script

### 7.1 Create Build Script

**File:** Create `Mousecape/scripts/build_release.sh`

```bash
#!/bin/bash
# Build, sign, and notarize Mousecape for distribution

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build/Release"

# Configuration
APP_NAME="Mousecape"
BUNDLE_ID="com.alexzielenski.Mousecape"
DEVELOPER_ID="Developer ID Application: YOUR_NAME (TEAM_ID)"
APPLE_ID="your@email.com"
TEAM_ID="YOUR_TEAM_ID"

echo "Building Mousecape for Release..."

# Clean build
xcodebuild clean -project "$PROJECT_DIR/Mousecape/Mousecape.xcodeproj"

# Build
xcodebuild \
    -project "$PROJECT_DIR/Mousecape/Mousecape.xcodeproj" \
    -scheme Mousecape \
    -configuration Release \
    -derivedDataPath "$PROJECT_DIR/build" \
    CODE_SIGN_IDENTITY="$DEVELOPER_ID" \
    DEVELOPMENT_TEAM="$TEAM_ID"

echo "Build complete!"

# Verify code signature
echo "Verifying code signature..."
codesign -vvv --deep --strict "$BUILD_DIR/$APP_NAME.app"

# Create DMG (optional)
echo "Creating DMG..."
create-dmg \
    --volname "$APP_NAME" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 175 120 \
    --hide-extension "$APP_NAME.app" \
    --app-drop-link 425 120 \
    "$BUILD_DIR/$APP_NAME.dmg" \
    "$BUILD_DIR/$APP_NAME.app"

# Notarize
echo "Notarizing app..."
xcrun notarytool submit "$BUILD_DIR/$APP_NAME.dmg" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "$BUILD_DIR/$APP_NAME.dmg"

echo "Build and notarization complete!"
echo "Release package: $BUILD_DIR/$APP_NAME.dmg"
```

Make executable:
```bash
chmod +x Mousecape/scripts/build_release.sh
```

---

## 8. Quick Reference Commands

### Development
```bash
# Build for testing
xcodebuild -project Mousecape/Mousecape.xcodeproj -scheme Mousecape -configuration Debug

# Run mousecloak CLI
./build/Debug/mousecloak --help

# Test cursor reset
./build/Debug/mousecloak --reset
```

### Code Signing
```bash
# Check signature
codesign -vvv --deep --strict Mousecape.app

# Check entitlements
codesign -d --entitlements - Mousecape.app

# Re-sign manually
codesign --force --deep --sign "Developer ID Application: ..." Mousecape.app
```

### Notarization
```bash
# Submit for notarization
xcrun notarytool submit Mousecape.dmg --apple-id you@email.com --team-id TEAMID --wait

# Check notarization status
xcrun notarytool log <submission-id> --apple-id you@email.com --team-id TEAMID

# Staple ticket
xcrun stapler staple Mousecape.dmg
```

### Debugging
```bash
# View system logs for helper
log stream --predicate 'process == "com.alexzielenski.mousecloakhelper"' --level debug

# Check SMAppService status
sfltool dumpbtm

# Check login items
sfltool list

# Enable CGS debugging (if available)
defaults write com.alexzielenski.Mousecape CGSDebug -bool YES
```

---

## 9. Troubleshooting Guide

### Issue: Helper Won't Install
**Symptoms:** SMAppService registration fails
**Solutions:**
1. Check bundle ID matches: `com.alexzielenski.mousecloakhelper`
2. Verify helper is in `Contents/Library/LoginItems/`
3. Check code signing: both app and helper must be signed
4. Verify SMAuthorizedClients in helper's Info.plist
5. Check Console.app for ServiceManagement errors

### Issue: Cursors Don't Apply
**Symptoms:** No error but cursor doesn't change
**Solutions:**
1. Test with `mousecloak --reset` first
2. Check Console for CGS errors
3. Verify SIP status: `csrutil status` (should be enabled)
4. Test if CGS APIs available: run compatibility test
5. Check color space of cursor images

### Issue: Code Signing Fails
**Symptoms:** Build succeeds but signing fails
**Solutions:**
1. Verify Developer ID cert in Keychain
2. Check entitlements are well-formed XML
3. Ensure Hardened Runtime is enabled
4. Try manual signing with verbose output
5. Check Xcode signing settings

### Issue: Notarization Rejected
**Symptoms:** Notarytool returns failure
**Solutions:**
1. Check notarization log: `xcrun notarytool log <id>`
2. Verify Hardened Runtime enabled
3. Check all binaries are signed (including frameworks)
4. Ensure no unsigned dylibs
5. Verify entitlements don't request unavailable permissions

---

## 10. Migration Checklist

Use this checklist to track implementation progress:

- [ ] Phase 1: ServiceManagement API
  - [ ] MCAppDelegate.m updated with SMAppService
  - [ ] Backward compatibility with macOS 12 maintained
  - [ ] Helper Info.plist configured
  - [ ] Main app Info.plist updated
  - [ ] Tested on macOS 13+
  - [ ] Tested on macOS 12 (fallback path)

- [ ] Phase 2: NSAlert Migration
  - [ ] All NSRunAlertPanel calls replaced
  - [ ] Alert styles set appropriately
  - [ ] Memory management correct (release in MRC)
  - [ ] Localized strings preserved

- [ ] Phase 3: Entitlements
  - [ ] Main app entitlements created
  - [ ] Helper tool entitlements created
  - [ ] App Groups configured
  - [ ] Hardened Runtime enabled
  - [ ] Entitlements linked in Xcode

- [ ] Phase 4: Build Settings
  - [ ] Deployment target updated to 11.0
  - [ ] Universal Binary architecture set
  - [ ] Hardened Runtime enabled in build settings
  - [ ] Code signing configured

- [ ] Phase 5: CGS Compatibility
  - [ ] cgs_compatibility.h/m created
  - [ ] Runtime detection implemented
  - [ ] apply.m updated to use wrappers
  - [ ] restore.m updated to use wrappers
  - [ ] Tested on macOS 26

- [ ] Phase 6: Testing
  - [ ] All checklist items pass
  - [ ] Performance benchmarks run
  - [ ] Multi-version compatibility verified
  - [ ] Multi-architecture verified

- [ ] Phase 7: Distribution
  - [ ] Build script created
  - [ ] App successfully notarized
  - [ ] DMG created and tested
  - [ ] Release notes written
  - [ ] Version number updated

---

**End of Implementation Guide**

For strategic planning, refer to [macos-26-tahoe-update-plan.md](macos-26-tahoe-update-plan.md).
