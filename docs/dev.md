# Developer Documentation

## Project Overview
CND IPTV Downloader is a Flutter-based application designed for managing and playing IPTV content (Live TV, Movies, Series). It features a modern UI, local database caching, and background processing for performance.

## Technology Stack
- **Framework**: Flutter (MacOS target currently active)
- **Language**: Dart
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Database**: [Isar](https://isar.dev/) (NoSQL, highly performant)
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **Video Player**: [media_kit](https://pub.dev/packages/media_kit)

## Architecture
The project follows a MVVM (Model-View-ViewModel) pattern with a Repository layer.

### Directory Structure
- `lib/data/`: Data models and repositories.
  - `iptv_models.dart`: Isar collections (`IptvSource`, `IptvItem`).
  - `iptv_repository.dart`: Handles data fetching, database operations, and isolate spawning.
- `lib/viewmodels/`: Business logic and state management.
  - `iptv_vm.dart`: Contains `PaginatedIptvNotifier` for list management and global `IptvVm` for actions.
- `lib/ui/`: UI components and pages.
  - `pages/`: Main screens (`TvPage`, `MoviesPage`, `SeriesPage`, `ShellPage`).
  - `widgets/`: Reusable UI widgets.
- `lib/services/`: Helper services.
  - `isolate_parser.dart`: Runs M3U parsing in a separate thread.

## Key Features & Implementation Details

### 1. Performance Optimization
- **Isolates**: M3U playlist parsing is heavy and is offloaded to a background isolate using `compute` (`lib/services/isolate_parser.dart`).
- **Pagination**: Lists (TV, Movies, Series) are paginated to support massive playlists (10k+ items) without memory issues.
- **Lazy Loading**: The main navigation uses a `PageView` to strictly load tabs only when visited.

### 2. Database (Isar)
- We use Isar for its speed and full-text search capabilities.
- Queries for filtering (by Group, Host) and sorting are optimized to run at the database level, not in Dart memory.

### 3. State Management (Riverpod)
- `liveVmProvider`, `moviesVmProvider`, `seriesVmProvider`: Specific instances of `PaginatedIptvNotifier` for each content type.
- `favoritesProvider`: Manages local favorites.

## Getting Started

### Prerequisites
- Flutter SDK (Latest Stable)
- MacOS / Windows / Linux for desktop development (Platform specific requirements apply)

### Running the App
```bash
flutter pub get
flutter run -d macos
```

### Running Tests
Unit tests are located in `test/`.
```bash
flutter test
```

## Contribution Guidelines
1.  Use `flutter_lints` for code style.
2.  Always add tests for new logic in ViewModels.
3.  Keep UI logic separate from data logic.
