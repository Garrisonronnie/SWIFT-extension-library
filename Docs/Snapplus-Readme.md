# SnapPlus

SnapPlus is a fully independent Swift layout helper library designed to enhance Auto Layout workflows.  
It provides **responsive layouts, conflict detection, animated layouts, cross-device scaling, and debug tools** — all without modifying or depending on any other library.

## Features
- Responsive layout adjustments for all screen sizes
- Constraint conflict detection and auto-fixing
- Animated and dynamic layout changes
- Cross-device scaling for consistent layouts
- Safe-area aware constraints
- Batch activation and deactivation of constraints
- Debug overlay visualization

## Installation
1. Add `SnapPlus.swift` to your Xcode project.
2. Import the module in your Swift files:
```swift
import SnapPlus
## Usage 

let snap = SnapPlus()
snap.applyResponsiveLayout(to: myView, constraints: constraintsArray)
snap.animateConstraints(on: myView) {
    myView.frame.size.width += 50
}
