## 1. Data Sources

- [x] 1.1 Locate or create the minimal SQLite-backed query path for novels, word counts, writing goal, and recent writing state.
- [x] 1.2 Ensure dashboard queries return empty or unset values when data is missing instead of fallback demo values.
- [x] 1.3 Add a small runnable check for the dashboard data mapper covering no novels, novels without recent writing, and novels with recent writing.

## 2. Dashboard State Model

- [x] 2.1 Define the dashboard view state for loading, first-use empty state, populated state, no-recent-writing state, and search-empty state.
- [x] 2.2 Map real query results into the dashboard view state without hardcoded business data.
- [x] 2.3 Wire direct actions for create novel, import novel, open project, AI configuration, and theme toggle only to real app behavior.

## 3. Flutter Main Dashboard UI

- [x] 3.1 Build the dashboard shell with top app bar, welcome area, primary work card, statistics area, and novel projects section.
- [x] 3.2 Implement the first-use empty state with create and import actions and no project search box.
- [x] 3.3 Implement the populated state with recent-writing behavior, real statistics, project list, search, and search-empty state.
- [x] 3.4 Apply the reference visual style with Flutter-native widgets: light background, white cards, subtle borders, dark primary button, and restrained red accent.
- [x] 3.5 Add responsive layout behavior for wide desktop and narrow window widths.

## 4. Verification

- [x] 4.1 Verify no-novel startup shows zero/unset real states and no fake project content.
- [x] 4.2 Verify populated startup uses real novels, word totals, writing goal, and recent writing data.
- [x] 4.3 Verify search-empty state is distinct from first-use empty state.
- [x] 4.4 Run the smallest available Flutter static analysis or test command for the touched code.
