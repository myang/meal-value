# meal-value

MealValue is an iOS SwiftUI app for recording meals layer-by-layer from plate photos and estimating nutrition.

## MVP included

- Log a meal with multiple food layers
- Attach a photo for each layer
- Choose the layer category and food type
- Estimate calories, protein, carbs, fat, and fiber
- Save the full meal history locally from day one
- Show weekly and monthly nutrition summaries
- Generate simple nutrition advice based on recent meals

## Current product shape

The current build is an MVP scaffold, not a finished computer-vision product yet.

Right now the app supports:
- layer-by-layer meal capture
- local persistence
- summary dashboards
- rules-based nutrition advice

What still needs to be added for the full vision:
- actual photo recognition / food classification from images
- better portion-size estimation from the photo itself
- richer food database and localization
- HealthKit integration
- charts and trend visualizations
- iCloud sync / backup

## Project structure

- `MealValue.xcodeproj` — Xcode project
- `MealValue/MealValueApp.swift` — app entry point
- `MealValue/ContentView.swift` — tab navigation and meal list
- `MealValue/AddMealView.swift` — meal creation flow
- `MealValue/SummaryView.swift` — weekly/monthly summaries
- `MealValue/Models.swift` — app models
- `MealValue/NutritionEngine.swift` — food profiles and nutrition math
- `MealValue/AdviceEngine.swift` — summary advice rules
- `MealValue/MealStore.swift` — local persistence

## Build note

Xcode is installed on this machine, but `xcodebuild` currently fails because the local Xcode runtime/plugins are in a broken state. The project scaffold is in place, but you may need to repair Xcode before building/running.
