# Quick Start: macOS 26 Tahoe Update

**Time to complete:** 2-3 hours for critical changes only
**For full implementation:** See [macos-26-tahoe-update-plan.md](macos-26-tahoe-update-plan.md)

## Prerequisites

- ✅ macOS 26 Tahoe installed
- ✅ Xcode 16+ installed
- ✅ Apple Developer account (for code signing)
- ✅ Repository cloned and submodules initialized

## Critical Path (Do These First)

### Step 1: Update Build Configuration (15 minutes)

```bash
# Open the project
open Mousecape/Mousecape.xcodeproj

# In Xcode:
# 1. Select project in navigator
# 2. Select "Mousecape" target
# 3. Build Settings tab
# 4. Search for "deployment"
# 5. Change "macOS Deployment Target" from 10.13 to 11.0
# 6. Repeat for "mousecloak" and "mousecloakHelper" targets
```

### Step 2: Test if CGS APIs Still Work (10 minutes)

```bash
# Build mousecloak CLI
xcodebuild -project Mousecape/Mousecape.xcodeproj -target mousecloak -configuration Debug

# Test cursor reset
build/Debug/mousecloak --reset

# If this works without errors, CGS APIs are still functional!
# If it fails, see "CGS API Blocked" section below
```

**Result:**
- ✅ **Works:** Continue to Step 3
- ❌ **Fails:** STOP - See troubleshooting section, this is critical

### Step 3: Replace ServiceManagement APIs (30 minutes)

Edit `Mousecape/Mousecape/MCAppDelegate.m`:

1. **Add header** (line ~10):
   ```objc
   #import <ServiceManagement/ServiceManagement.h>
   ```

2. **Replace `configureHelperToolMenuItem` method** (lines 54-64):
   ```objc
   - (void)configureHelperToolMenuItem {
       BOOL isInstalled = NO;
       if (@available(macOS 13.0, *)) {
           SMAppService *service = [SMAppService loginItemServiceWithIdentifier:@"com.alexzielenski.mousecloakhelper"];
           isInstalled = (service.status == SMAppServiceStatusEnabled);
       } else {
   #pragma clang diagnostic push
   #pragma clang diagnostic ignored "-Wdeprecated-declarations"
           CFDictionaryRef dict = SMJobCopyDictionary(kSMDomainUserLaunchd, CFSTR("com.alexzielenski.mousecloakhelper"));
           isInstalled = (dict != NULL);
           if (dict) CFRelease(dict);
   #pragma clang diagnostic pop
       }
       [self.toggleHelperItem setTag:isInstalled ? 1 : 0];
       [self.toggleHelperItem setTitle:isInstalled ?
           NSLocalizedString(@"Uninstall Helper Tool", "") :
           NSLocalizedString(@"Install Helper Tool", "")];
   }
   ```

3. **Replace `toggleInstall:` method** (lines 66-99):
   See full code in [implementation-guide-macos26.md](implementation-guide-macos26.md#11-complete-mcappdelegatem-refactor)

### Step 4: Replace NSRunAlertPanel (15 minutes)

Still in `MCAppDelegate.m`, replace all `NSRunAlertPanel` calls with NSAlert:

```objc
// OLD:
NSRunAlertPanel(@"Success", @"The action succeeded", @"OK", nil, nil);

// NEW:
NSAlert *alert = [[NSAlert alloc] init];
[alert setMessageText:@"Success"];
[alert setInformativeText:@"The action succeeded"];
[alert addButtonWithTitle:@"OK"];
[alert runModal];
[alert release]; // Only if not using ARC
```

### Step 5: Add Entitlements (10 minutes)

Edit `Mousecape/Mousecape/Mousecape.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>$(TeamIdentifierPrefix)com.alexzielenski.mousecape</string>
    </array>
</dict>
</plist>
```

### Step 6: Update Helper Info.plist (5 minutes)

Edit `Mousecape/mousecloakHelper/Info.plist`, add:

```xml
<key>LSBackgroundOnly</key>
<true/>
<key>LSUIElement</key>
<true/>
<key>SMAuthorizedClients</key>
<array>
    <string>identifier "com.alexzielenski.Mousecape"</string>
</array>
```

### Step 7: Build and Test (15 minutes)

```bash
# Build the app
xcodebuild -project Mousecape/Mousecape.xcodeproj -scheme Mousecape -configuration Debug

# Open the built app
open build/Debug/Mousecape.app

# Test checklist:
# ✓ App opens without crashing
# ✓ Can install helper tool
# ✓ Can apply a cursor cape
# ✓ Can restore default cursors
# ✓ Helper persists cursor after logout/login
```

## Verification Checklist

After completing the critical path:

- [ ] Project builds without errors on macOS 26
- [ ] `mousecloak --reset` works from command line
- [ ] App launches and main window appears
- [ ] Helper tool can be installed via menu
- [ ] Cursor cape can be applied
- [ ] Cursor persists after app quit
- [ ] Default cursors can be restored
- [ ] No crashes or hangs

## If Something Goes Wrong

### CGS APIs Blocked
**Symptom:** `mousecloak --reset` fails with error

**Immediate action:**
1. Check Console.app for error messages
2. Run: `log stream --predicate 'subsystem == "com.apple.CoreGraphics"'`
3. Try running with sudo: `sudo build/Debug/mousecloak --reset`
4. Check SIP status: `csrutil status`

**If APIs are truly blocked:**
- This is a critical issue - see [macos-26-tahoe-update-plan.md](macos-26-tahoe-update-plan.md#61-cgs-api-testing--validation)
- May need to contact Apple DTS
- May need alternative approach

### Helper Tool Won't Install
**Symptom:** Error when clicking "Install Helper Tool"

**Fix:**
1. Check Console.app for ServiceManagement errors
2. Verify bundle identifier: `com.alexzielenski.mousecloakhelper`
3. Ensure helper is properly signed: `codesign -vvv build/Debug/Mousecape.app/Contents/Library/LoginItems/com.alexzielenski.mousecloakhelper.app`
4. Try uninstalling first: `sfltool resetbtm`

### Build Fails
**Symptom:** Xcode build errors

**Common issues:**
1. Deployment target mismatch - verify all targets set to 11.0+
2. Missing frameworks - ensure all frameworks linked
3. Code signing - verify Developer ID in Xcode settings
4. Entitlements malformed - validate XML syntax

### Cursors Don't Apply
**Symptom:** No error but cursor doesn't change

**Fix:**
1. Reset first: `mousecloak --reset`
2. Check if cape file is valid: `file /path/to/cape.cape` (should be plist)
3. Verify cursor images are valid: use Preview.app to open them
4. Check Console for CoreGraphics errors
5. Test with included example cape: `Mousecape/com.maxrudberg.svanslosbluehazard.cape`

## Next Steps After Quick Start

Once the critical path is complete and tested:

1. **Review full plan:** [macos-26-tahoe-update-plan.md](macos-26-tahoe-update-plan.md)
2. **Implement remaining changes:** Follow [implementation-guide-macos26.md](implementation-guide-macos26.md)
3. **Run comprehensive tests:** Use testing checklist in implementation guide
4. **Prepare for distribution:** Code signing, notarization, release notes

## Time Estimates

| Task | Minimum | Typical | With Issues |
|------|---------|---------|-------------|
| Critical Path (Steps 1-7) | 2 hours | 3 hours | 8 hours |
| Full Implementation | 1 week | 2 weeks | 6 weeks |
| Testing & Polish | 3 days | 1 week | 2 weeks |
| Distribution Prep | 1 day | 2 days | 1 week |

## Success Criteria (Minimum Viable)

You're done with the quick start when:

1. ✅ App builds on Xcode 16 for macOS 26
2. ✅ Helper tool installs using SMAppService
3. ✅ Cursors can be applied and restored
4. ✅ No deprecated API warnings in Xcode
5. ✅ App runs without crashes

## Getting Help

- **Apple Documentation:** https://developer.apple.com/documentation/servicemanagement
- **GitHub Issues:** https://github.com/alexzielenski/Mousecape/issues
- **Apple DTS:** https://developer.apple.com/support/technical/ (for private API issues)

## Summary of Files Changed

### Modified Files
- `Mousecape/Mousecape/MCAppDelegate.m` - ServiceManagement + NSAlert migration
- `Mousecape/Mousecape/Mousecape.entitlements` - Add permissions
- `Mousecape/mousecloakHelper/Info.plist` - Add SMAppService keys
- `Mousecape/Mousecape.xcodeproj/project.pbxproj` - Deployment target

### New Files (Optional but Recommended)
- `Mousecape/mousecloak/cgs_compatibility.h` - CGS API safety layer
- `Mousecape/mousecloak/cgs_compatibility.m` - Runtime detection
- `Mousecape/mousecloakHelper/mousecloakHelper.entitlements` - Helper permissions

## Commit Message Template

```
feat: macOS 26 Tahoe compatibility

Critical updates for macOS 26:
- Migrate ServiceManagement to SMAppService (macOS 13+)
- Replace deprecated NSRunAlertPanel with NSAlert
- Update deployment target to macOS 11.0
- Add required entitlements for Hardened Runtime
- Update helper tool Info.plist for SMAppService
- Maintain backward compatibility with macOS 12

Tested on: macOS 26.2 (Apple Silicon)
Fixes: #XXX
```

---

**Good luck! 🎯**

If you run into issues, consult the detailed guides or open an issue on GitHub.
