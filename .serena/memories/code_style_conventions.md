# Code Style And Conventions

## Analyzer/Linting
- Uses `flutter_lints` via `analysis_options.yaml`.
- Strictly follow `flutter_lints`. Resolve all issues reported by `flutter analyze`.

## Naming And Structure
- `PascalCase` for classes, enums, and widgets.
- `camelCase` for variables, methods, and fields.
- `snake_case` for file names.
- Private members prefixed with `_`.
- Use feature-layered folders (`data/domain/models/platform/state/ui`).
- Functions should be short (<20 lines) and single-purpose.

## State And Data Patterns
- **Riverpod**: Providers should be declared near state orchestration. Use `ConsumerWidget` or `Consumer` for UI.
- **Immutability**: Treat app state as immutable. Use `copyWith` for updates.
- **Data Handling**: Use `json_serializable` for JSON operations.
- Prefer manual constructor dependency injection to make class dependencies explicit.

## Flutter/UI Patterns
- **Material 3**: Use Material 3 themes and standard widget composition.
- **Const**: Use `const` constructors everywhere possible to reduce unnecessary rebuilds.
- **Composition**: Favor composition over inheritance. Build complex UIs from smaller, reusable widgets.
- **Layout**: Use `ListView.builder` for lists. Use `Expanded`/`Flexible` for responsive layouts.

## Visual Design Standards (Desired)
- **Typography**: Emphasize font sizes (hero text, section headlines) for better readability.
- **Depth**: Use multi-layered drop shadows for cards to create a "lifted" feel.
- **Interaction**: Buttons and interactive elements should have an elegant color-based "glow" effect.
- **Tactile Feel**: Apply subtle noise textures to the main background for a premium feel (when supported).

## Async/Resource Handling
- Use `unawaited(...)` for fire-and-forget operations.
- Properly handle Stream subscriptions (track and cancel in `dispose()`).