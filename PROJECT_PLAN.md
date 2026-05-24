# IceVault Project Plan

## Source Parameters

- Project folder: `app_209`
- App name: `IceVault`
- Bundle identifier: `app.IceVault.ios`
- Display name: `IceVault`
- Platform: iOS 16+, SwiftUI, SwiftData, URLSession
- Third-party packages: do not use OneSignal, Alamofire, AppsFlyer, or any new package dependencies
- Functional reference: `/Users/belzephyrus/Documents/gambling/book_69/app_267`

## Concept

- Style: Secure / private / premium cold blue
- Palette: Primary #1D3557, Secondary #A8DADC, Background #F1FAEE, Accent #457B9D, Text #0B132B
- Onboarding theme: Keep books and plans under control.
- Main UI goal: the app must feel like an independent product, not a recolored BookMood copy.

## Unique Code Structure

Plan the structure without copying names from the reference:

```text
IceVault/
  Application/
    VaultGateView.swift
    VaultSectionTabs.swift
  Design/
    IceVaultDesign.swift
    SecuredBookCell.swift
  Features/
    Onboarding/SecureIceIntro.swift
    Discovery/VaultLookupView.swift
    Scanner/VaultISBNScannerLock.swift
    Library/
    Details/
    Progress/
    Notes/
    Weekly/WeekVaultPlan.swift
    Insights/
    Settings/
  Data/
    OpenLibrary/
    LocalStore/
  Domain/
    Models/
    Services/
```

Names can be refined during implementation, but they must not match `BookMood`, `BookNest`, `SearchView`, `LibraryView`, `OnboardingView`, `AppDependencies`, or other reference names.

## Functionality To Transfer

- Search books through OpenLibrary by title and general query.
- Search by ISBN through OpenLibrary `q=` after code normalization.
- Show OpenLibrary work details, authors, year, subjects, and description.
- Load covers from `https://covers.openlibrary.org`.
- Store a local SwiftData library with `wantToRead`, `reading`, `finished`, and `paused` statuses.
- Add books from search and curated lists to the local library.
- Edit status, rating, note, and reading progress.
- Keep page progress history.
- Build mood/genre picks through OpenLibrary subjects.
- Show statistics: book counts, statuses, finished books, and progress.
- Settings: reset onboarding, change library display mode, clear local data.
- Weekly future reading list: `WeekVaultPlan` must provide a 7-day plan, add books from library/search, move books between days, and persist locally.

## Required ISBN Scanner

Implement `VaultISBNScannerLock` without third-party packages:

- use `AVFoundation` and `UIViewControllerRepresentable`;
- recognize `ean13`, `ean8`, and `upce` when supported by the device;
- show a clear camera-required message in Simulator;
- normalize the scanned ISBN and run OpenLibrary search;
- add `NSCameraUsageDescription` to the project settings;
- handle denied camera permission and empty scanner states.

## Screens

- `SecureIceIntro`: 2-4 unique onboarding screens with custom copy, pagination, and buttons.
- `VaultGateView`: root scene that decides whether to show onboarding or the app.
- `VaultSectionTabs`: unique navigation across the main sections.
- `VaultLookupView`: book search with loading, empty, error, and offline states; opens details.
- Book details: a `IceVault`-style hero section, add-to-library action, description, and subjects.
- Library: status filters, local shelf search, sorting, and delete action.
- Progress: page input, event log, and visual progress indicator.
- Notes: rating and text note.
- Mood/subject picks: OpenLibrary subject-based picks and saved lists.
- `WeekVaultPlan`: weekly future reading list.
- Insights: local library statistics and aggregates.
- Settings: local settings without web gate, push, or attribution SDKs.

## Design System

Create `IceVaultDesign` with its own tokens:

- project palette colors;
- background, surface, card, border, primary text, secondary text, error, and success;
- primary and secondary buttons;
- `SecuredBookCell` card component;
- empty state component;
- input fields;
- chip/status badge;
- navigation/tab styling;
- subtle animations matching the project concept.

## Implementation Plan

1. Update Xcode project metadata: display name `IceVault`, bundle id `app.IceVault.ios`, camera usage description.
2. Replace the starter `ContentView.swift` and `app_209App.swift` with the unique app structure.
3. Add SwiftData models for preferences, books, progress, mood lists, and the weekly plan.
4. Add an OpenLibrary data layer based on `URLSession`, without Alamofire.
5. Implement onboarding and persist `hasCompletedOnboarding`.
6. Implement search, ISBN scanner, book details, and add-to-library flow.
7. Implement library, progress, notes, insights, and settings.
8. Implement `WeekVaultPlan` for the weekly future reading plan.
9. Make UI, copy, components, file names, and animations unique.
10. Build the project and verify the main flows on different iPhone sizes.

## Readiness Checklist

- The project builds without errors.
- Bundle id equals `app.IceVault.ios`.
- The project contains no OneSignal, Alamofire, or AppsFlyer.
- ISBN scanner exists and is connected to search.
- OpenLibrary works through `URLSession`.
- Data persists locally through SwiftData.
- Weekly reading list survives app restart.
- UI and copy do not match the other 19 projects or the reference.
