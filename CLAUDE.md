# GambitStudio - Claude Configuration

## MAIN RULE
**Build the app COMPLETELY. Don't stop until it's finished. Iterate as many times as necessary.**
- Don't ask "should I continue?" - CONTINUE
- Don't ask "should I implement X?" - IMPLEMENT IT
- If something makes sense for the app, add it
- Only stop when the app is ready to publish

---

## Developer
- João Flores | GambitStudio
- Experienced developer, publishing apps for years
- Communication: PT-BR
- Focus: maximum productivity, less talk, more code

---

## PLATFORM: iOS (Swift + SwiftUI)

### Tech Stack
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum iOS**: 17.0
- **Architecture**: MVVM
- **Package Manager**: Swift Package Manager (SPM)

---

## CODE STANDARDS (MANDATORY)

### Language
- **ALL code in English** (variables, functions, classes, comments)
- Only localization files (.strings, .xcstrings) contain translated strings
- Communication with dev in PT-BR, but code always in English

### Documentation with MARK
Every Swift file must use MARK comments for organization:

```swift
// MARK: - Properties
private let title: String
private var count: Int

// MARK: - Computed Properties
var isValid: Bool {
    count > 0
}

// MARK: - Lifecycle
init() {
    // ...
}

// MARK: - Public Methods
func submit() {
    // ...
}

// MARK: - Private Methods
private func validate() {
    // ...
}

// MARK: - View Body
var body: some View {
    // ...
}
```

### MARK Categories (use in order)
```swift
// MARK: - Constants
// MARK: - Properties
// MARK: - Published Properties (for ViewModels)
// MARK: - Computed Properties
// MARK: - Lifecycle / Init
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Actions
// MARK: - Navigation
// MARK: - View Body (SwiftUI)
// MARK: - Subviews (private view builders)
```

---

## MVVM ARCHITECTURE (MANDATORY)

### Project Structure
```
[AppName]/
├── App/
│   ├── [AppName]App.swift
│   └── AppDelegate.swift (if needed)
│
├── Core/
│   ├── Constants/
│   │   ├── AppConstants.swift
│   │   ├── StorageKeys.swift
│   │   └── RouteNames.swift
│   ├── Extensions/
│   │   ├── View+Extensions.swift
│   │   ├── Color+Extensions.swift
│   │   ├── String+Extensions.swift
│   │   └── Date+Extensions.swift
│   ├── Theme/
│   │   ├── AppTheme.swift
│   │   ├── AppColors.swift
│   │   ├── AppFonts.swift
│   │   └── AppSpacing.swift
│   ├── Utils/
│   │   ├── HapticManager.swift
│   │   └── Validators.swift
│   └── Localization/
│       ├── Localizable.xcstrings
│       └── String+Localized.swift
│
├── Data/
│   ├── Models/
│   │   └── [Entity]Model.swift
│   ├── Repositories/
│   │   └── [Entity]Repository.swift
│   └── Services/
│       ├── StorageService.swift
│       ├── NotificationService.swift
│       ├── ReviewService.swift
│       └── PurchaseService.swift
│
├── Presentation/
│   ├── Common/
│   │   ├── Components/
│   │   │   ├── AppButton.swift
│   │   │   ├── AppCard.swift
│   │   │   ├── LoadingView.swift
│   │   │   ├── EmptyStateView.swift
│   │   │   └── ErrorView.swift
│   │   └── Modifiers/
│   │       └── CardModifier.swift
│   │
│   ├── Onboarding/
│   │   ├── Views/
│   │   │   └── OnboardingView.swift
│   │   ├── ViewModels/
│   │   │   └── OnboardingViewModel.swift
│   │   └── Components/
│   │
│   ├── Home/
│   │   ├── Views/
│   │   │   └── HomeView.swift
│   │   ├── ViewModels/
│   │   │   └── HomeViewModel.swift
│   │   └── Components/
│   │
│   ├── [Feature]/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Components/
│   │
│   ├── Paywall/
│   │   ├── Views/
│   │   │   └── PaywallView.swift
│   │   └── ViewModels/
│   │       └── PaywallViewModel.swift
│   │
│   ├── Settings/
│   │   ├── Views/
│   │   │   └── SettingsView.swift
│   │   └── ViewModels/
│   │       └── SettingsViewModel.swift
│   │
│   └── TabBar/
│       └── MainTabView.swift
│
├── Navigation/
│   └── AppRouter.swift
│
└── Resources/
    ├── Assets.xcassets/
    └── Fonts/
```

### MVVM Components

#### Model (Data/Models/)
```swift
/// Entity model representing a data entity.
struct EntityModel: Codable, Identifiable {
    // MARK: - Properties
    let id: UUID
    let name: String
    let createdAt: Date

    // MARK: - Init
    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
```

#### ViewModel (Presentation/[Feature]/ViewModels/)
```swift
/// ViewModel for FeatureView.
@MainActor
final class FeatureViewModel: ObservableObject {
    // MARK: - Dependencies
    private let repository: EntityRepository
    private let storageService: StorageService

    // MARK: - Published Properties
    @Published private(set) var items: [EntityModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Computed Properties
    var hasError: Bool { errorMessage != nil }
    var isEmpty: Bool { items.isEmpty && !isLoading }

    // MARK: - Init
    init(
        repository: EntityRepository = EntityRepository(),
        storageService: StorageService = .shared
    ) {
        self.repository = repository
        self.storageService = storageService
    }

    // MARK: - Public Methods
    func fetchItems() async {
        isLoading = true
        errorMessage = nil

        do {
            items = try await repository.getItems()
        } catch {
            errorMessage = "Failed to load items"
        }

        isLoading = false
    }
}
```

#### View (Presentation/[Feature]/Views/)
```swift
/// Feature screen displaying content.
struct FeatureView: View {
    // MARK: - Properties
    @StateObject private var viewModel = FeatureViewModel()

    // MARK: - View Body
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Feature")
                .task {
                    await viewModel.fetchItems()
                }
        }
    }

    // MARK: - Subviews
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            LoadingView()
        } else if viewModel.hasError {
            ErrorView(
                message: viewModel.errorMessage ?? "",
                onRetry: {
                    Task { await viewModel.fetchItems() }
                }
            )
        } else if viewModel.isEmpty {
            EmptyStateView(
                message: "No items found",
                systemImage: "tray"
            )
        } else {
            itemsList
        }
    }

    private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.items) { item in
                    ItemCardView(item: item)
                }
            }
            .padding()
        }
    }
}
```

---

## DESIGN SYSTEM (MANDATORY)

### Visual Style
- **ALWAYS dark mode** as default
- iOS-first aesthetic (SF Symbols, native components)
- Clean, minimalist, premium
- Inspiration: Apple apps (Health, Fitness, Notes)

### Default Colors
```swift
/// App color palette following iOS design guidelines.
enum AppColors {
    // MARK: - Dark Theme Colors
    static let background = Color(hex: "000000")
    static let surface = Color(hex: "1C1C1E")
    static let surfaceVariant = Color(hex: "2C2C2E")

    // MARK: - Primary Colors
    static let primary = Color(hex: "0A84FF")
    static let secondary = Color(hex: "30D158")
    static let accent = Color(hex: "FF9F0A")

    // MARK: - Semantic Colors
    static let error = Color(hex: "FF453A")
    static let success = Color(hex: "30D158")
    static let warning = Color(hex: "FF9F0A")

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8E8E93")
    static let textTertiary = Color(hex: "636366")
}
```

### Typography
- Font: SF Pro (system font)
- Use `.font(.system())` with appropriate weights
- Titles: bold, large
- Body: regular, good readability
- Clear hierarchy

### Animations (ALWAYS include)
- **Page transitions**: fade + subtle slide
- **Buttons**: scale down on press (0.95)
- **Lists**: sequential fade in with `.animation(.easeOut)`
- **Modals**: `.sheet` with custom detents
- **Feedback**: haptic feedback on important actions
- Default duration: 0.2-0.3 seconds
- Use `.animation(.spring())` for natural feel

### Components
- Border radius: 12-16pt (`.cornerRadius()`)
- Generous spacing (16pt minimum)
- Always respect safe areas
- Use `.sheet()` or `.fullScreenCover()` for modals

### Shadows (IMPORTANT)
- **NEVER use colored shadows** - always use black shadows only
- Shadows should be subtle and elegant: `.shadow(color: .black.opacity(0.15), radius: 10)`
- Only use shadows when they add elegance, not on everything
- Prefer no shadow over colored glow effects

---

## LOCALIZATION (MANDATORY)

### Languages: PT-BR, EN-US, ES-ES (always all 3)

Structure:
```
Core/Localization/
├── Localizable.xcstrings (new format)
└── String+Localized.swift
```

```swift
// Usage with String Catalog
Text(String(localized: "home_title"))
Text(String(localized: "welcome_message \(userName)"))
```

- Use String Catalog (Localizable.xcstrings) for modern localization
- Detect system language automatically
- Allow manual switch in Settings
- NEVER hardcode strings

---

## INITIAL APP LAUNCH
**IMPORTANT**: First version of any app should be FREE:
- Set `isPurchasesEnabled = false` in AppConstants
- Hide all premium/paywall UI when flag is false
- Keep StoreKit 2 code ready but dormant
- User will set flag to `true` when ready to monetize

---

## MANDATORY FEATURES (implement without asking)

### 1. Elegant Onboarding
- 3-4 screens with SF Symbols/animations
- TabView with `.tabViewStyle(.page)`
- Page indicator with custom styling
- Discreet "Skip" button
- Highlighted "Get Started" button
- Persist `onboardingComplete` in UserDefaults

### 2. Smart In-App Review
- Use `StoreKit.requestReview()`
- Trigger after positive moment (3rd use, complete action)
- Cooldown: 60 days between requests
- Tracking in UserDefaults: `lastReviewRequest`, `reviewCount`

### 3. Complete Settings
- Language (PT/EN/ES)
- Appearance (always dark, but leave option)
- Notifications
- Rate app → opens App Store
- Share app
- Feedback/Support (email)
- Privacy Policy (WebView or Safari)
- Terms of Use
- App version (from Bundle)
- Restore purchases (if IAP enabled)

### 4. Share App
- Use `ShareLink` or `UIActivityViewController`
- Localized text
- App Store link

### 5. UI States
- **Loading**: Custom shimmer effect or `ProgressView`
- **Empty**: SF Symbol + text + CTA button
- **Error**: Friendly message + retry button
- **Success**: Visual feedback + haptic

### 6. Navigation
- `TabView` for bottom navigation (max 5 items)
- SF Symbols icons
- Animation on selection
- No labels if icons are clear

### 7. Persistence
- `UserDefaults` for configs (via `@AppStorage`)
- `SwiftData` or Core Data for complex data
- iCloud sync when applicable

### 8. Haptic Feedback
```swift
// HapticManager.swift
enum HapticManager {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
```

---

## IN-APP PURCHASES (StoreKit 2 - Native Apple)

**IMPORTANT**: Always use native Apple StoreKit 2, NEVER use third-party SDKs like RevenueCat.

### Feature Flag
Use a feature flag to enable/disable purchases:
```swift
// AppConstants.swift
enum AppConstants {
    /// Set to true to enable in-app purchases and premium features
    static let isPurchasesEnabled = false
}
```

### Setup (when enabled)
```swift
// PurchaseService.swift
import StoreKit

@MainActor
final class PurchaseService: ObservableObject {
    // MARK: - Singleton
    static let shared = PurchaseService()

    // MARK: - Published Properties
    @Published private(set) var isPremium = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []

    // MARK: - Constants
    private let productIDs = ["app_monthly", "app_annual"]

    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Init
    private init() {
        guard AppConstants.isPurchasesEnabled else { return }
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - Private Methods
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    await self?.updatePurchasedProducts()
                    await transaction?.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
        isPremium = !purchased.isEmpty
    }
}

enum StoreError: Error {
    case failedVerification
}
```

---

## APP STORE

### Main Platform: iOS
- Build ID: NZC6LC8NWM
- Test on iPhone SE (smallest) and iPad
- Bundle: com.gambitstudio.[appname]

### ASO Metadata (MANDATORY - generate in .metadata folder)
When project is complete, create `.metadata/` folder with txt files:
- `pt-BR.txt` - Portuguese metadata
- `en-US.txt` - English metadata
- `es-ES.txt` - Spanish metadata

Each file must contain (ASO optimized for organic search):
- **App Name** (30 chars) - include main keyword
- **Subtitle** (30 chars) - include secondary keyword
- **Keywords** (100 chars) - comma separated, no duplicates from name/subtitle
- **Description** (4000 chars) - benefit-focused, no emojis, professional
- **Promotional Text** (170 chars)
- **What's New** - bullet points for updates
- **Screenshot Descriptions** - 6 short phrases

### ASO Tips
- User does NOT do paid marketing, only organic
- Keywords must be high-volume, low-competition
- Description should include keywords naturally
- Focus on benefits, not features
- Short, impactful screenshot texts

### Screenshots
- Generate descriptions for 6 screenshots
- Focus on benefits, not features
- Short and impactful phrases

---

## PRE-RELEASE CHECKLIST

### Mandatory
- [ ] Dark theme implemented
- [ ] 3 languages working (PT/EN/ES)
- [ ] Complete onboarding
- [ ] In-app review configured
- [ ] Settings with all options
- [ ] Elegant empty states
- [ ] Loading states
- [ ] Error handling with retry
- [ ] Transition animations
- [ ] Haptic feedback
- [ ] Tested on iPhone SE
- [ ] Tested on iPad
- [ ] 1024x1024 icon
- [ ] Dark launch screen
- [ ] Build without warnings
- [ ] Metadata in 3 languages
- [ ] MARK comments in all files

### If Purchases Enabled
- [ ] StoreKit 2 configured (native Apple)
- [ ] Paywall implemented
- [ ] Restore purchases working

### Bonus
- [ ] iOS Widget
- [ ] App Shortcuts
- [ ] Spotlight Search
- [ ] Live Activities

---

## COMMANDS

| I say | You do |
|-------|--------|
| `create [description]` | Complete app from scratch, don't stop until finished |
| `continue` | Continue from where you left off |
| `status` | Show checklist of what's missing |
| `metadata` | Generate .metadata folder with ASO-optimized texts (PT/EN/ES) |
| `build` | Compile iOS, fix errors |
| `polish` | Improve animations and UI |
| `release` | Final build + metadata + ASO texts |

---

## PREFERRED PACKAGES (SPM)

**IMPORTANT**: Prefer native Apple frameworks over third-party libraries when possible.

```swift
// Package.swift dependencies or Xcode SPM - ONLY if native doesn't exist
dependencies: [
    // Lottie - Animations (only if needed)
    .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0"),
]
```

### Native Frameworks to Use (PREFER THESE)
- **SwiftUI** - UI
- **Combine** - Reactive programming
- **AVFoundation** - Audio/Video
- **StoreKit** - Reviews & purchases
- **UserNotifications** - Local notifications
- **HealthKit** - Health data (if applicable)
- **SwiftData** - Persistence
- **WidgetKit** - Widgets

---

## NAMING CONVENTIONS

### Files
- `PascalCase` for all Swift files
- Views: `[Feature]View.swift`
- ViewModels: `[Feature]ViewModel.swift`
- Models: `[Name]Model.swift`
- Repositories: `[Name]Repository.swift`
- Services: `[Name]Service.swift`
- Components: `[Name]View.swift` or `[Name]Component.swift`

### Types
- `PascalCase` for structs, classes, enums, protocols
- Views: `[Feature]View`
- ViewModels: `[Feature]ViewModel`
- Models: `[Name]Model`
- Protocols: `[Name]Protocol` or `[Name]able`

### Variables and Methods
- `camelCase` for all
- Private with `private` keyword
- Boolean prefixes: `is`, `has`, `should`, `can`
- Async methods: regular names (Swift concurrency handles it)

---

## IDEAL PROMPT EXAMPLE

```
Create an app for [topic].

Features:
- [list of features]

Note: [any specific details]
```

That's it. The rest (design, animations, languages, onboarding, review, settings, MVVM structure, MARK comments) I do automatically following this document.
