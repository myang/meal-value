# MealValue

An iOS meal nutrition recording and evaluation app that uses AI-powered food recognition to analyze your meals layer by layer.

## Features

### Meal Recording
- **Layer-by-layer photography**: Take photos of each layer of your plate (e.g., base vegetables, middle grains, top proteins)
- **AI food recognition**: Uses OpenAI GPT-4 Vision to automatically identify food items and estimate portions from photos
- **Manual food entry**: Built-in database of 30+ common foods with nutrition data for manual entry or AI fallback
- **Nutrition scoring**: Each meal receives a 0-100 quality score based on protein balance, fiber, vegetable content, and more

### Nutrition Analysis
- **Detailed nutrition breakdown**: Calories, protein, carbs, fat, fiber, sugar, sodium, cholesterol, vitamins, and minerals
- **Macro distribution**: Visual breakdown of protein/carbs/fat ratios
- **Per-layer analysis**: See nutrition contribution from each food layer

### Weekly & Monthly Summaries
- **Calorie tracking charts**: Daily calorie intake with target line
- **Macro trend charts**: Stacked bar charts showing protein/carb/fat distribution over time
- **Score trend**: Line chart tracking meal quality scores
- **Smart nutrition advice**: Personalized tips based on your eating patterns

### Data Storage
- **Local persistence**: SwiftData for on-device meal history
- **Google Drive sync**: Automatic backup of all meal data and photos to your Google Drive
- **Data export**: JSON export of all nutrition records

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

### 1. Generate Xcode Project

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation:

```bash
brew install xcodegen
xcodegen generate
open MealValue.xcodeproj
```

Alternatively, create a new Xcode project and add the `MealValue/` source folder.

### 2. Configure API Keys

In the app's Settings tab:

1. **OpenAI API Key**: Get your key from [platform.openai.com](https://platform.openai.com)
   - Required for AI food photo analysis
   - Uses GPT-4o Vision model

2. **Google Drive**:
   - Create a project in [Google Cloud Console](https://console.cloud.google.com)
   - Enable Google Drive API
   - Create OAuth 2.0 credentials (iOS client)
   - Enter the Client ID in Settings

## Architecture

```
MealValue/
├── App/                    # App entry point and root navigation
│   ├── MealValueApp.swift
│   └── ContentView.swift
├── Models/                 # SwiftData models
│   ├── Meal.swift          # Main meal record
│   ├── FoodLayer.swift     # Layer within a meal
│   ├── FoodItem.swift      # Individual food item
│   ├── NutritionInfo.swift # Nutrition data model
│   └── MealExportData.swift # Codable export format
├── Services/               # Business logic
│   ├── OpenAIVisionService.swift   # ChatGPT food analysis
│   ├── GoogleDriveService.swift    # Google Drive backup
│   ├── NutritionDatabase.swift     # Built-in food database
│   └── NutritionAdviceEngine.swift # Smart advice generator
├── ViewModels/             # MVVM view models
│   ├── MealViewModel.swift
│   ├── SummaryViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── Home/               # Main screen with today's meals
│   ├── Camera/             # Photo capture
│   ├── MealComposition/    # Layer recording and food entry
│   ├── MealDetail/         # Detailed meal view
│   ├── Summary/            # Charts and weekly/monthly reports
│   ├── Settings/           # API keys and preferences
│   └── Components/         # Reusable UI components
├── Extensions/             # Swift extensions
└── Resources/              # Info.plist, entitlements
```

### Key Design Patterns
- **MVVM**: Clean separation of views, view models, and models
- **SwiftData**: Modern Apple persistence framework
- **Swift Charts**: Native chart visualizations
- **Actor isolation**: Thread-safe API services using Swift actors

## How It Works

1. **Start a meal** - Choose meal type (Breakfast/Lunch/Dinner/Snack)
2. **Add layers** - Name each layer (e.g., "Base - Vegetables", "Top - Protein")
3. **Photograph each layer** - Take a photo before adding the next layer
4. **AI analyzes** - GPT-4 Vision identifies foods and estimates portions/nutrition
5. **Review & adjust** - Edit recognized items, add manual entries if needed
6. **Save** - Meal is scored and stored with full nutrition data
7. **Track trends** - View weekly/monthly charts and get personalized advice
