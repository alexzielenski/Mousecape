# macOS 26 Tahoe Update Plan for Mousecape

**Document Version:** 1.0
**Target macOS:** 26.x (Tahoe)
**Current Deployment Target:** 10.13 (High Sierra)
**Last Updated:** January 2026

## Executive Summary

This document outlines the comprehensive plan for updating Mousecape to be fully compatible with macOS 26 Tahoe. The update requires addressing deprecated APIs, modernizing the codebase, updating security requirements, and ensuring compatibility with Apple Silicon and modern macOS security frameworks.

## Current State Analysis

### Project Configuration
- **Deployment Target:** macOS 10.13 (High Sierra)
- **Build System:** Xcode project (Mousecape.xcodeproj)
- **Memory Management:** Manual Retain/Release (MRC) - No ARC
- **Language:** Objective-C (no Swift)
- **Architecture:** Likely Universal Binary needed for Intel + Apple Silicon
- **Dependencies:** Sparkle (git submodule), GBCli, MASPreferences, BTRKit, Rebel

### Critical Components Using Private APIs
1. **CoreGraphics Services (CGS) APIs** - Core functionality
   - `CGSRegisterCursorWithImages()`
   - `CGSSetRegisteredCursor()`
   - `CoreCursorUnregisterAll()`
   - Location: [mousecloak/CGSInternal/](../Mousecape/mousecloak/CGSInternal/)

2. **ServiceManagement Framework** - Helper tool installation
   - `SMLoginItemSetEnabled()` - Deprecated in macOS 13+
   - `SMJobCopyDictionary()` - Deprecated in macOS 13+
   - Location: [MCAppDelegate.m:54-99](../Mousecape/Mousecape/MCAppDelegate.m#L54-L99)

### Known Deprecated APIs in Use
1. **NSRunAlertPanel** (deprecated since OS X 10.10)
   - Used in: [MCAppDelegate.m](../Mousecape/Mousecape/MCAppDelegate.m)
   - Should migrate to: NSAlert

2. **Carbon Framework Functions** (deprecated since 10.5)
   - Used in: [CarbonHelpers.h](../Mousecape/mousecloak/CGSInternal/CarbonHelpers.h)
   - `GetNativeWindowFromWindowRef()` / `GetWindowRefFromNativeWindow()`
   - These may not be actively used but should be audited

## Update Strategy

### Phase 1: Pre-Update Preparation (Week 1)

#### 1.1 Environment Setup
- [ ] Verify Xcode 16+ is installed (for macOS 26 SDK)
- [ ] Update Sparkle submodule to latest 2.x version
- [ ] Create feature branch: `feature/macos-26-tahoe-support`
- [ ] Set up testing environment on macOS 26 Tahoe
- [ ] Document current app behavior for regression testing

#### 1.2 Dependency Audit
- [ ] Update Sparkle framework (check if 2.x supports macOS 26)
- [ ] Review GBCli compatibility
- [ ] Review MASPreferences compatibility
- [ ] Check if any external dependencies need updates

#### 1.3 API Availability Testing
- [ ] Test if CGS private APIs still work on macOS 26
- [ ] Document any API signature changes
- [ ] Create test harness for CGS cursor registration

### Phase 2: Build System Updates (Week 1-2)

#### 2.1 Xcode Project Configuration
**File:** `Mousecape/Mousecape.xcodeproj/project.pbxproj`

Update deployment targets:
```
MACOSX_DEPLOYMENT_TARGET = 11.0  // Up from 10.13
```

Reasoning: macOS 11.0 (Big Sur) is a good minimum to support modern APIs while maintaining reasonable backward compatibility.

#### 2.2 Architecture Support
- [ ] Ensure `ARCHS = arm64 x86_64` for Universal Binary
- [ ] Update build settings for Apple Silicon optimization
- [ ] Test on both Intel and Apple Silicon Macs

#### 2.3 Compiler Warnings
- [ ] Enable stricter compiler warnings
- [ ] Fix all deprecation warnings
- [ ] Address any new warnings from updated SDK

### Phase 3: API Modernization (Week 2-3)

#### 3.1 Replace NSRunAlertPanel with NSAlert
**Priority:** HIGH
**Files Affected:** [MCAppDelegate.m](../Mousecape/Mousecape/MCAppDelegate.m)

Current code (lines 82-98):
```objc
NSRunAlertPanel(NSLocalizedString(@"Sucess", "Helper Tool Install Result Title Success"),
                NSLocalizedString(@"The Mousecape helper was successfully installed", "..."),
                NSLocalizedString(@"Sweet", "Helper Tool Install Result Gratitude 1"),
                NSLocalizedString(@"Thanks", "Helper Tool Install Result Gratitude 2"), nil);
```

Replace with:
```objc
NSAlert *alert = [[NSAlert alloc] init];
[alert setMessageText:NSLocalizedString(@"Success", "Helper Tool Install Result Title Success")];
[alert setInformativeText:NSLocalizedString(@"The Mousecape helper was successfully installed", "...")];
[alert addButtonWithTitle:NSLocalizedString(@"Sweet", "Helper Tool Install Result Gratitude 1")];
[alert addButtonWithTitle:NSLocalizedString(@"Thanks", "Helper Tool Install Result Gratitude 2")];
[alert runModal];
```

Note: Fix typo "Sucess" → "Success" in localization keys.

#### 3.2 Migrate ServiceManagement APIs
**Priority:** CRITICAL
**Files Affected:** [MCAppDelegate.m:54-99](../Mousecape/Mousecape/MCAppDelegate.m#L54-L99)

##### Current Implementation (Deprecated in macOS 13+):
- `SMLoginItemSetEnabled()` - Install/uninstall helper
- `SMJobCopyDictionary()` - Check installation status

##### New Implementation: SMAppService (macOS 13+)
```objc
#import <ServiceManagement/ServiceManagement.h>

// Check status
- (void)configureHelperToolMenuItem {
    SMAppService *service = [SMAppService loginItemServiceWithIdentifier:@"com.alexzielenski.mousecloakhelper"];
    SMAppServiceStatus status = service.status;

    BOOL isEnabled = (status == SMAppServiceStatusEnabled);
    [self.toggleHelperItem setTag:isEnabled ? 1 : 0];
    [self.toggleHelperItem setTitle:isEnabled ?
        NSLocalizedString(@"Uninstall Helper Tool", "") :
        NSLocalizedString(@"Install Helper Tool", "")];
}

// Toggle installation
- (IBAction)toggleInstall:(NSMenuItem *)sender {
    SMAppService *service = [SMAppService loginItemServiceWithIdentifier:@"com.alexzielenski.mousecloakhelper"];
    NSError *error = nil;
    BOOL success = NO;

    if (self.toggleHelperItem.tag != 0) { // Uninstall
        success = [service unregisterAndReturnError:&error];
    } else { // Install
        success = [service registerAndReturnError:&error];
    }

    if (success) {
        [self configureHelperToolMenuItem]; // Update UI
        [self showSuccessAlert:self.toggleHelperItem.tag == 0];
    } else {
        [self showFailureAlert:error];
    }
}
```

**Important:** SMAppService requires different entitlements and bundle structure. See Section 5.2.

#### 3.3 Carbon Framework Cleanup
**Priority:** MEDIUM
**Files Affected:** [CarbonHelpers.h](../Mousecape/mousecloak/CGSInternal/CarbonHelpers.h)

- [ ] Audit if Carbon functions are actually used
- [ ] If not used, remove CarbonHelpers.h
- [ ] If used, replace with modern equivalents:
  - `GetNativeWindowFromWindowRef()` → `HIWindowGetCGWindowID()`
  - `GetWindowRefFromNativeWindow()` → `HIWindowFromCGWindowID()`

### Phase 4: Security & Sandboxing (Week 3-4)

#### 4.1 Entitlements Configuration
**Files:**
- `Mousecape/Mousecape/Mousecape.entitlements` (currently empty)
- Create: `Mousecape/mousecloakHelper/mousecloakHelper.entitlements`

##### Main App Entitlements (Mousecape.entitlements)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Service Management for helper installation -->
    <key>com.apple.security.application-groups</key>
    <array>
        <string>com.alexzielenski.mousecape</string>
    </array>

    <!-- Network for Sparkle updates -->
    <key>com.apple.security.network.client</key>
    <true/>

    <!-- File access for cape library -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>

    <!-- Hardened Runtime -->
    <key>com.apple.security.cs.allow-jit</key>
    <false/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <false/>
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <false/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>
</dict>
</plist>
```

##### Helper Tool Entitlements (mousecloakHelper.entitlements)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>com.alexzielenski.mousecape</string>
    </array>
</dict>
</plist>
```

#### 4.2 Code Signing
- [ ] Update code signing settings for Hardened Runtime
- [ ] Enable "Hardened Runtime" in Xcode build settings
- [ ] Sign with Developer ID certificate
- [ ] Notarize the app bundle for distribution

#### 4.3 Privacy Considerations
macOS 26 may have stricter requirements:
- [ ] Add usage descriptions to Info.plist if needed
- [ ] Consider Transparency, Consent, and Control (TCC) implications
- [ ] Test cursor modification permissions

### Phase 5: Helper Tool Migration (Week 4-5)

#### 5.1 Bundle Structure Changes
The new SMAppService requires the helper to be a proper app bundle in `Contents/Library/LoginItems/`.

**Current Structure:**
```
Mousecape.app/
└── Contents/
    └── Library/
        └── LoginItems/
            └── com.alexzielenski.mousecloakhelper.app  ✓ Already correct!
```

**Action Items:**
- [ ] Verify helper bundle is in correct location
- [ ] Update Info.plist for helper with SMBundleIdentifier
- [ ] Ensure helper has proper CFBundleIdentifier
- [ ] Add LSUIElement key to helper's Info.plist (background agent)

#### 5.2 Helper Info.plist Updates
**File:** `Mousecape/mousecloakHelper/Info.plist`

Add/verify:
```xml
<key>LSBackgroundOnly</key>
<true/>
<key>LSUIElement</key>
<true/>
<key>SMBundleIdentifier</key>
<string>com.alexzielenski.mousecloakhelper</string>
```

#### 5.3 Copy Phase Updates
Update the Xcode copy build phase to ensure helper is embedded correctly:
- Destination: `Contents/Library/LoginItems`
- Code sign on copy: YES

### Phase 6: Private API Compatibility (Week 5-6)

#### 6.1 CGS API Testing & Validation
**Priority:** CRITICAL - This is the core functionality

Test each CGS function on macOS 26:
- [ ] `CGSRegisterCursorWithImages()` - Cursor registration
- [ ] `CGSSetRegisteredCursor()` - Set active cursor
- [ ] `CoreCursorUnregisterAll()` - Reset cursors
- [ ] `CGSCopyRegisteredCursorImages()` - Get cursor data
- [ ] `CGSGetRegisteredCursorData2()` - Get detailed cursor info

**Potential Issues:**
1. **API signatures may have changed** - Check parameters and return types
2. **Security restrictions** - macOS 26 may block cursor modification
3. **New permission requirements** - TCC database entries needed
4. **System Integrity Protection (SIP)** - May interfere with cursor registration

**Contingency Plan:**
If CGS APIs are blocked or removed:
- Research alternative approaches (accessibility APIs, input methods)
- Consider documenting limitations for macOS 26
- Investigate if cursor modification requires new entitlements
- Check if Apple has provided any replacement APIs

#### 6.2 Dynamic Linking & Symbol Resolution
Verify CGS symbols are available:
```objc
// Add runtime checks in apply.m
if (CGSRegisterCursorWithImages == NULL) {
    MMLog(BOLD RED "CGSRegisterCursorWithImages not available on this OS version!" RESET);
    return NO;
}
```

#### 6.3 Color Space Handling
**File:** [NSBitmapImageRep+ColorSpace.m](../Mousecape/mousecloak/NSBitmapImageRep+ColorSpace.m)

macOS 26 may have stricter color space requirements:
- [ ] Verify sRGB color space conversion still works
- [ ] Test with Display P3 and wide color cursors
- [ ] Ensure color accuracy on modern displays

### Phase 7: Testing & Validation (Week 6-7)

#### 7.1 Functional Testing
- [ ] Install/uninstall helper tool
- [ ] Apply custom cursor cape
- [ ] Restore default cursors
- [ ] Test cursor persistence across logout/login
- [ ] Test cursor persistence across user switching
- [ ] Verify animated cursors work
- [ ] Test HiDPI cursor scaling
- [ ] Test left-handed mode
- [ ] Import/export capes
- [ ] Create new capes

#### 7.2 Compatibility Testing
Test on multiple macOS versions:
- [ ] macOS 26.x (Tahoe) - Primary target
- [ ] macOS 25.x (Sequoia) - Should still work
- [ ] macOS 14.x (Sonoma) - Minimum supported
- [ ] macOS 13.x (Ventura) - Test SMAppService
- [ ] macOS 11.x (Big Sur) - Minimum deployment target

Test on multiple architectures:
- [ ] Apple Silicon (M1/M2/M3/M4)
- [ ] Intel (x86_64)

#### 7.3 Performance Testing
- [ ] Cursor switching latency
- [ ] Memory usage
- [ ] CPU usage when idle
- [ ] Helper tool resource consumption

#### 7.4 Security Testing
- [ ] Verify code signature
- [ ] Notarization status
- [ ] Gatekeeper acceptance
- [ ] Helper tool authorization
- [ ] Private API usage doesn't trigger security warnings

### Phase 8: Memory Management Modernization (Optional - Week 8)

#### 8.1 Consider ARC Migration
**Current:** Manual Retain/Release (MRC)
**Benefit:** Reduced memory bugs, modern code

**Files using MRC:**
- Most .m files in Mousecape/Mousecape/src/
- mousecloak CLI tool files

**Approach:**
1. Use Xcode's "Convert to Objective-C ARC" refactoring tool
2. Fix files marked with `-fno-objc-arc` compiler flag
3. Test extensively after conversion

**Risk:** High - MRC to ARC conversion can introduce subtle bugs

**Recommendation:** Only do this if time permits and after all other updates are complete.

#### 8.2 Specific MRC Patterns to Watch
Files with explicit `-fno-objc-arc` flags (from project.pbxproj):
- `NSColor+RBLCGColorAdditions.m`
- `RBLScrollView.m`
- `NSOrderedSet+AZSortedInsert.m`
- `create.m`
- `backup.m`
- `apply.m`
- `restore.m`
- `scale.m`
- `MCDefs.m`

These files must be carefully handled if migrating to ARC.

### Phase 9: CLI Tool Updates (Week 7)

#### 9.1 mousecloak Command-Line Tool
**File:** [mousecloak/main.m](../Mousecape/mousecloak/main.m)

- [ ] Update GBCli dependency if needed
- [ ] Test all command-line operations
- [ ] Verify listen mode still works
- [ ] Test create/convert/export/dump operations

#### 9.2 Cursor Scale Function
**File:** [mousecloak/scale.m](../Mousecape/mousecloak/scale.m)

- [ ] Test cursor scaling on high-DPI displays
- [ ] Verify scale multipliers work (1x, 2x, 5x, 10x)

### Phase 10: Documentation & Release (Week 8)

#### 10.1 Update Documentation
- [ ] Update README.md with macOS 26 compatibility note
- [ ] Update CLAUDE.md with new APIs and patterns
- [ ] Document any breaking changes
- [ ] Update minimum system requirements
- [ ] Document known issues/limitations

#### 10.2 Release Preparation
- [ ] Update version number in Info.plist (1820 → 1900?)
- [ ] Update copyright year (2024 → 2026)
- [ ] Create release notes
- [ ] Update Sparkle appcast.xml
- [ ] Create signed and notarized build
- [ ] Test auto-update from previous version

#### 10.3 Distribution
- [ ] Upload to GitHub Releases
- [ ] Update website/download links
- [ ] Announce on social media/forums
- [ ] Monitor for bug reports

## Risk Assessment

### Critical Risks

#### 1. CGS Private APIs Blocked (Severity: CRITICAL)
**Impact:** Core functionality broken
**Likelihood:** Medium
**Mitigation:**
- Test early in process (Phase 6)
- Research alternative approaches
- Have contingency plan for API replacement
- Consider reaching out to Apple for official cursor customization API

#### 2. ServiceManagement Changes Break Helper (Severity: HIGH)
**Impact:** Auto-apply on login broken
**Likelihood:** Low
**Mitigation:**
- Follow Apple's migration guide precisely
- Test thoroughly on macOS 13-26
- Have fallback to manual cursor application

#### 3. Notarization Issues (Severity: HIGH)
**Impact:** App won't run on user Macs
**Likelihood:** Medium
**Mitigation:**
- Follow Hardened Runtime requirements
- Use correct entitlements
- Test notarization early
- Keep signing certificates current

### Medium Risks

#### 4. Color Space/Graphics Issues (Severity: MEDIUM)
**Impact:** Cursors display incorrectly
**Likelihood:** Low
**Mitigation:**
- Test on multiple display types
- Verify color space handling
- Test HDR/wide gamut displays

#### 5. Performance Degradation (Severity: MEDIUM)
**Impact:** Slow cursor switching, high resource use
**Likelihood:** Low
**Mitigation:**
- Profile before/after updates
- Optimize hot paths
- Test on slower Macs

### Low Risks

#### 6. Sparkle Update Framework Issues (Severity: LOW)
**Impact:** Auto-updates broken
**Likelihood:** Low
**Mitigation:**
- Use latest Sparkle 2.x
- Test update flow
- Manual fallback available

## Testing Checklist

### Pre-Update Baseline
- [ ] Document current behavior on macOS 26
- [ ] Screenshot all UI elements
- [ ] Record cursor application process
- [ ] Note any existing issues

### Per-Phase Testing
- [ ] Unit tests for modified code
- [ ] Integration tests for workflows
- [ ] Regression tests for existing features
- [ ] Performance benchmarks

### Final Acceptance Testing
- [ ] All capes from library apply correctly
- [ ] Helper tool installs without admin prompt
- [ ] Cursors persist across system events
- [ ] No console errors or warnings
- [ ] No memory leaks
- [ ] Code signing valid
- [ ] Notarization successful
- [ ] App opens without Gatekeeper warnings

## Resource Requirements

### Development
- macOS 26 Tahoe test machine (Apple Silicon + Intel)
- Xcode 16+
- Apple Developer account (for code signing)
- Time: 8 weeks (with optional ARC migration)

### Testing
- Multiple Mac models (M1, M2, M3, Intel)
- Multiple macOS versions (11.0 - 26.x)
- Various display configurations (HiDPI, standard, HDR)

## Success Criteria

1. ✅ App builds without warnings on Xcode 16+
2. ✅ All deprecated APIs replaced with modern equivalents
3. ✅ Helper tool installs successfully using SMAppService
4. ✅ Cursors apply and persist correctly on macOS 26
5. ✅ App passes notarization
6. ✅ No regression in existing functionality
7. ✅ Performance equivalent or better than current version
8. ✅ Works on both Apple Silicon and Intel

## Timeline Summary

| Phase | Duration | Key Deliverable |
|-------|----------|-----------------|
| 1. Preparation | Week 1 | Environment ready, dependencies updated |
| 2. Build System | Week 1-2 | Project builds on macOS 26 |
| 3. API Modernization | Week 2-3 | All deprecated APIs replaced |
| 4. Security | Week 3-4 | Entitlements configured, code signed |
| 5. Helper Tool | Week 4-5 | SMAppService migration complete |
| 6. Private APIs | Week 5-6 | CGS APIs working or contingency active |
| 7. Testing | Week 6-7 | All tests passing |
| 8. ARC Migration | Week 8 | Optional - only if time permits |
| 9. CLI Updates | Week 7 | mousecloak tool updated |
| 10. Release | Week 8 | App shipped |

**Total:** 8 weeks (6 weeks for critical path + 2 weeks buffer)

## Next Steps

1. Create GitHub issue for tracking: "macOS 26 Tahoe Compatibility"
2. Set up milestone for v2.0 release
3. Begin Phase 1 preparation work
4. Schedule testing on macOS 26 hardware
5. Contact Apple DTS if private API issues arise

## Appendix A: Useful Resources

- [ServiceManagement SMAppService Migration Guide](https://developer.apple.com/documentation/servicemanagement/smappservice)
- [Hardened Runtime Documentation](https://developer.apple.com/documentation/security/hardened_runtime)
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [macOS 26 Release Notes](https://developer.apple.com/documentation/macos-release-notes)

## Appendix B: Contact Information

- **Project Maintainer:** Alex Zielenski
- **Repository:** https://github.com/alexzielenski/Mousecape
- **Issues:** https://github.com/alexzielenski/Mousecape/issues

---

**Document Prepared By:** Claude Code
**Last Review Date:** January 2, 2026
**Next Review Date:** Upon Phase 6 completion (CGS API testing results)
