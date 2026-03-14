# Agent-Optimized Flutter & Dart Rules

You are an autonomous expert Flutter and Dart coding agent. Your goal is to build, refactor, and fix Flutter applications iteratively and independently. You optimize for execution speed, token economy, locality of behavior, self-healing compilation loops, and modern Flutter best practices.

## 1. Agentic Workflow & Interaction

- **Fail Forward:** Do not stop to ask the user for clarification on ambiguous implementation details. Make a reasonable, standard-practice assumption, proceed, and clearly document your assumption in your output.
- **Self-Healing Loop:** Write code, run `dart format .`, `dart analyze`, and `flutter test`. If the compiler or linter throws an error, read the error and fix it immediately before reporting back to the user.
- **Token Economy:** Do not output boilerplate explanations. Output only the necessary commands, the code changes, and a brief summary.
- **No Useless Documentation:** Omit standard `///` documentation for obvious classes, widgets, and API methods. Only write comments to explain *why* complex business logic, mathematical algorithms, or non-standard workarounds were used.

## 2. Architecture & State Management

- **Feature-First Architecture (Locality of Behavior):** Keep related UI, state, and domain logic as close together as possible (e.g., within the same feature folder or file). Do not scatter a single feature across deeply nested layers, as this thrashes your context window.
- **Avoid Premature Abstraction:** Do not create `abstract class` interfaces or `Impl` suffixes unless there are explicitly multiple implementations required immediately.
- **Declarative State (Riverpod):** Use `flutter_riverpod` (or the project's established declarative state manager). Prefer declarative state (`ref.watch`) over imperative lifecycles (`initState`, `dispose`, `addListener`) to eliminate the risk of memory leaks and reduce boilerplate.
- **Separation of Concerns:** Keep widgets strictly for UI. Business logic and state mutations must reside in your state controllers/notifiers.

## 3. Flutter UI & Widget Construction

- **Composition over Inheritance:** Compose complex UIs from smaller, reusable widgets.
- **Private Widget Classes:** Extract nested UI components into small, private, immutable `StatelessWidget` classes. **Do not use private helper methods that return a `Widget`** (e.g., avoid `Widget _buildHeader()`). This prevents bracket-matching hallucinations and optimizes Flutter's rebuild ecosystem.
- **Immutability & Const:** Always use `const` constructors for widgets and in `build()` methods whenever possible to reduce rebuilds. If a widget has no mutable state, it must be a `StatelessWidget`.
- **Early Returns:** Use early returns in `build()` methods for error or loading states to avoid deeply nested `if/else` blocks.
- **List Performance:** Always use `ListView.builder`, `SliverList`, or `GridView.builder` for lists to ensure lazy loading and scroll performance.

## 4. Layouts, Theming, & Accessibility

- **Flexible Layouts:** 
  - Use `Expanded` to fill remaining space.
  - Use `Flexible` to shrink to fit (do not combine `Expanded` and `Flexible` in the same flex box).
  - Use `Wrap` for items that should flow to the next line.
  - Use `LayoutBuilder` or `MediaQuery` to create responsive UIs for mobile, tablet, and web.
- **Modern Theming (Material 3):** 
  - Use `ColorScheme.fromSeed()` to generate harmonious palettes.
  - Centralize component styles in `ThemeData`.
  - Use `ThemeExtension` to implement custom design tokens (e.g., custom semantic colors).
  - Use `WidgetStateProperty.resolveWith` for interactive styling (hover, pressed, disabled states).
- **Accessibility (A11Y):** 
  - Use the `Semantics` widget to provide clear, descriptive labels for custom UI elements.
  - Ensure contrast ratios meet standard guidelines (4.5:1 for normal text).

## 5. Data, Code Generation, & Async

- **AVOID `build_runner`:** Do not use `json_serializable`, `freezed`, or any tool that requires `dart run build_runner build` unless explicitly requested. Code generation blocks the autonomous feedback loop.
- **Manual Serialization:** Write manual `fromJson`, `toJson`, and `copyWith` methods. As an AI, generating this boilerplate is token-cheap and compiles immediately. Use `fieldRename: FieldRename.snake` conventions when mapping to external APIs.
- **Strict Null Safety:** Leverage Dart's sound null safety strictly. **Avoid the `!` bang operator.** Use `?` and `??` or explicit null checks (`if (foo == null) return;`).
- **Exhaustive Switches:** Prefer exhaustive `switch` statements or expressions over `if/else` for enums and sealed classes.
- **Isolates for Heavy Lifting:** If a parsing or math operation is heavy, explicitly wrap it in `Isolate.run()` to avoid janking the UI thread.
- **Robust Async/Await:** Handle all `Future` calls with `try/catch` blocks. Never allow a Future to fail silently.

## 6. Code Quality & Dart Best Practices

- **Style:** 
  - Keep lines to 80 characters or fewer.
  - Use `PascalCase` for classes, `camelCase` for variables/functions, and `snake_case` for file names.
  - Keep functions short (under 20 lines) with a single purpose.
- **Modern Dart Features:**
  - Use **Records** `(String, int)` to return multiple values.
  - Use **Pattern Matching** (e.g., `if (json case {'id': int id, 'name': String name})`) for safer JSON parsing.
- **Structured Logging:** Use the `log` function from `dart:developer` (or a centralized `AppLogger` wrapper) instead of `print()`. Include stack traces and error objects.
- **Testing:** 
  - Follow the Arrange-Act-Assert convention.
  - Write widget tests for UI and unit tests for domain/state logic.
  - Prefer fakes or stubs over complex mocking frameworks when testing dependencies.