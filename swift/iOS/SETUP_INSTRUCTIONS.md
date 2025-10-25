# iOS App Setup Instructions

**Goal:** Create an iOS app target that uses the existing GoalTrackerKit Swift Package

**Time Required:** ~10-15 minutes

---

## Step 1: Open Project in Xcode

1. Open **Xcode**
2. Choose **File > Open**
3. Navigate to `/Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app/swift/`
4. Select the `Package.swift` file
5. Click **Open**

Xcode will resolve package dependencies (GRDB.swift). Wait for this to complete.

---

## Step 2: Create iOS App Target

### Xcode 26 Method:

1. In the menu bar, choose **File > New > Target...**
2. In the template chooser, select **iOS** tab at the top
3. Select **App** template
4. Click **Next**

**Configure the target:**
- **Product Name:** `GoalTrackerApp`
- **Team:** Select your Apple Developer team (or "None" for simulator-only testing)
- **Organization Identifier:** `com.davidwilliams` (or your preferred identifier)
- **Bundle Identifier:** Will auto-fill as `com.davidwilliams.GoalTrackerApp`
- **Interface:** SwiftUI
- **Language:** Swift
- **Minimum Deployments:** iOS 26.0
- **Include Tests:** Unchecked (we already have tests)

Click **Finish**

---

## Step 3: Clean Up Auto-Generated Files

Xcode created some template files we don't need:

1. In Project Navigator, find the new `GoalTrackerApp` folder
2. **Delete** these auto-generated files (Move to Trash):
   - `GoalTrackerAppApp.swift` (we have our own)
   - `ContentView.swift` (we use the one from the App module)
   - `Preview Content` folder (not needed)

---

## Step 4: Add Our App Entry Point

1. In Project Navigator, right-click on `GoalTrackerApp` folder
2. Choose **Add Files to "GoalTrackerApp"...**
3. Navigate to `/Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app/swift/iOS/GoalTrackerApp/`
4. Select `GoalTrackerApp.swift`
5. **Important:** Check "Copy items if needed"
6. Click **Add**

---

## Step 5: Link GoalTrackerKit Package

1. Select the **GoalTrackerApp target** in the project settings
2. Go to the **General** tab
3. Scroll down to **Frameworks, Libraries, and Embedded Content**
4. Click the **+** button
5. Select **GoalTrackerKit** (from the package)
6. Click **Add**

This links your iOS app to the shared SwiftUI views and business logic.

---

## Step 6: Configure Code Signing (Required for Physical iPhone)

### Option A: Automatic Signing (Recommended)

1. Select the **GoalTrackerApp target**
2. Go to **Signing & Capabilities** tab
3. Check **Automatically manage signing**
4. Select your **Team** from the dropdown
5. Xcode will automatically create a provisioning profile

### Option B: Manual Signing (Advanced)

1. Uncheck **Automatically manage signing**
2. Select your **Provisioning Profile** manually
3. Ensure it matches your **Bundle Identifier**

**For Simulator Testing Only:**
- You can leave Team as "None"
- Simulator doesn't require code signing

---

## Step 7: Test on iPhone Simulator

1. In Xcode toolbar, click the device selector (next to play button)
2. Choose **iPhone 15 Pro** (or any iOS 26 simulator)
3. Click the **Play** button (⌘R) to build and run

**Expected Result:**
- App launches in simulator
- You see the Goals/Actions/Values/Terms navigation
- Database initializes automatically

**If build fails:**
- Check the error in the Issue Navigator (⚠️ icon)
- Most common: Missing framework link (repeat Step 5)

---

## Step 8: Deploy to Physical iPhone

### Prerequisites:
- iPhone running iOS 26+
- iPhone connected via USB
- iPhone in Developer Mode (Settings > Privacy & Security > Developer Mode)

### Steps:

1. Connect your iPhone via USB
2. In Xcode device selector, choose your iPhone (it will appear by name)
3. **First time only:** Xcode will prompt you to register the device - click **Register**
4. Click the **Play** button (⌘R)

**If you get "Untrusted Developer" on iPhone:**
1. On iPhone: Settings > General > VPN & Device Management
2. Tap your developer profile
3. Tap **Trust "[Your Name]"**
4. Return to home screen and launch the app

---

## Troubleshooting

### "No such module 'App'" error
**Fix:** Make sure GoalTrackerKit is linked (Step 5)

### "Code signing required" error
**Fix:** Configure code signing (Step 6)

### "iPhone is locked" error
**Fix:** Unlock your iPhone and click Run again

### "Target 'GoalTrackerApp' must reside in the same Swift language version as package 'GoalTracker'"
**Fix:**
1. Select GoalTrackerApp target
2. Build Settings tab
3. Search for "Swift Language Version"
4. Set to "Swift 6"

---

## What You'll Have After Setup

✅ iOS app target that runs on iPhone and simulator
✅ Full access to Goals, Actions, Values, Terms features
✅ Same SwiftUI views work on both iOS and macOS
✅ Shared SQLite database (via GoalTrackerKit)
✅ iOS 26 Liquid Glass materials (navigation only)
✅ Ready for App Store distribution (after bundle ID registration)

---

## Next Steps After Testing

1. **Customize App Icon**
   - Add icon to `Assets.xcassets` in GoalTrackerApp target
   - Use 1024x1024 PNG

2. **Add Launch Screen**
   - Already configured in `Info.plist`
   - Customize in Xcode if desired

3. **Enable Additional Capabilities** (if needed)
   - iCloud sync: Signing & Capabilities > + Capability > iCloud
   - Push notifications: + Capability > Push Notifications

4. **Test on Multiple Devices**
   - Different iPhone models
   - iPad (if supporting larger screens)

---

**Questions?** Check the build logs in Xcode's Report Navigator (📄 icon) for detailed error messages.
