# Code Style And Conventions

## Analyzer/Linting
- Uses `flutter_lints` via `analysis_options.yaml`.
- Prefer fixes that satisfy `flutter analyze` and existing lint rules.

## Naming And Structure
- `PascalCase` for classes/enums/widgets.
- `lowerCamelCase` for variables, methods, and fields.
- Private members prefixed with `_`.
- Uses feature-layered folders (`data/domain/models/platform/state/ui`).

## State And Data Patterns
- Riverpod providers declared near state orchestration.
- App state is treated as immutable and updated with `copyWith`.
- Collections are commonly typed explicitly (`<Type>[]`) and often created with `growable: false`.

## Flutter/UI Patterns
- Strong use of `const` constructors/widgets where possible.
- Stateless/Consumer widgets compose screens; controller methods handle actions.
- Material 3 theme and standard Flutter widget composition.

## Async/Resource Handling
- Uses `unawaited(...)` for fire-and-forget operations.
- Stream subscriptions are tracked and cancelled in `dispose()`.