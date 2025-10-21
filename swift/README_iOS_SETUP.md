# iOS App Setup Instructions

Your Ten Week Goal App is now ready to run on iOS! Follow these simple steps:

## Quick Start (Recommended)

1. **Open Xcode**
2. **File → Open**
3. **Navigate to this folder** (`ten_week_goal_app/swift/`)
4. **Select `Package.swift`** and click Open
5. **Wait for dependencies** to resolve (Xcode will download GRDB automatically)
6. **Click the Run button** (▶️) or press `Cmd+R`
7. **Select iOS Simulator** from the destination menu (e.g., "iPhone 15 Pro")

That's it! Your app will build and launch in the simulator.

## What You'll See

- **Home Screen**: "Ten Week Goal Tracker" with database initialization status
- **Actions Button**: Tap to see your actions list (currently empty)
- **SwiftUI Previews**: Available in Xcode for instant UI testing

## Project Structure

```
swift/
├── Package.swift              # Swift Package configuration
├── Sources/
│   ├── Models/               # Domain entities (Action, Goal, Value, Term)
│   ├── Database/             # GRDB database layer + Records
│   ├── App/                  # SwiftUI views and view models
│   │   ├── TenWeekGoalApp.swift    # App entry point (@main for iOS/macOS)
│   │   ├── ContentView.swift        # Root view with navigation
│   │   └── Views/Actions/           # Actions list and detail views
│   └── AppRunner/            # CLI executable wrapper (for terminal use)
└── Tests/                    # Unit tests
```

## Adding Test Data

To see your actions list in action, you can add test data in two ways:

### Option 1: Via the App (Coming Soon)
- Tap the "+" button in Actions view
- Fill in the form
- Save

### Option 2: Via Database Directly
```swift
// In ContentView.swift or any view, add this to the .task block:
let action = Action(
    friendlyName: "Morning run",
    measuresByUnit: ["km": 5.0, "minutes": 30],
    logTime: Date()
)
try? await appViewModel.databaseManager?.saveAction(action)
```

## Next Steps: Implement Action Row Layout

You have a **TODO(human)** waiting in `Sources/App/Views/Actions/ActionRowView.swift`!

This is your chance to design how actions appear in the list:
- Which properties to show (name? measurements? time?)
- How to format them (bold? colors? badges?)
- Layout structure (vertical stack? horizontal?)

Open that file and follow the guidance in the comments.

## Troubleshooting

**"Cannot find module 'TenWeekGoalApp'"**
- Make sure you opened `Package.swift`, not a folder
- Wait for SPM to finish resolving dependencies

**"No such module 'GRDB'"**
- Wait for Xcode to finish downloading dependencies
- If stuck, try: Product → Clean Build Folder

**Preview not working**
- Previews work best with individual view files
- Try opening `ContentView.swift` and clicking "Resume" in the preview panel

**Simulator not showing**
- In Xcode toolbar, click destination dropdown
- Select any iPhone or iPad simulator

## Running on Physical Device

To run on your iPhone/iPad:
1. Connect your device via USB
2. Select it from the destination dropdown
3. You may need to configure signing:
   - Select the `TenWeekGoalApp` target
   - Go to "Signing & Capabilities"
   - Select your team

Enjoy building your goal tracker! 🎯
