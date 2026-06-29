## ADDED Requirements

### Requirement: Main dashboard shell
The system SHALL display a main dashboard shell for the Windows desktop app with a top app bar, welcome area, primary work card, statistics area, and novel projects section.

#### Scenario: Dashboard opens
- **WHEN** the user opens the app main window
- **THEN** the system displays the dashboard shell without requiring any novel project to exist

#### Scenario: Dashboard uses desktop layout
- **WHEN** the main window has desktop-width space
- **THEN** the system places the primary work card and statistics area side by side

#### Scenario: Dashboard adapts to narrow width
- **WHEN** the main window does not have enough width for the side-by-side layout
- **THEN** the system stacks the primary work card, statistics area, and project section vertically

### Requirement: Real data only
The system MUST use real local app data for dashboard business values and MUST NOT show fake novel titles, fake covers, fake word counts, fake goals, fake project counts, or fake AI configuration state.

#### Scenario: No local data exists
- **WHEN** the local database has no novel projects and no writing goal
- **THEN** the system displays zero or unset states instead of demo data

#### Scenario: Local data exists
- **WHEN** the local database contains novel projects, word counts, writing goals, or recent writing state
- **THEN** the system displays values derived from that data

#### Scenario: Data is loading
- **WHEN** dashboard data is still loading
- **THEN** the system displays loading placeholders or neutral empty placeholders without inventing business values

### Requirement: First-use empty state
The system SHALL display a first-use empty state when there are no novel projects.

#### Scenario: No novels exist
- **WHEN** the novel project count is zero
- **THEN** the primary work card displays an empty-state message and direct actions to create or import a novel

#### Scenario: No novels exist in project section
- **WHEN** the novel project count is zero
- **THEN** the novel projects section displays an empty-state card instead of a project grid

#### Scenario: Search is hidden for first use
- **WHEN** the novel project count is zero
- **THEN** the system does not display a project search box

### Requirement: Populated dashboard state
The system SHALL display a populated dashboard state when at least one novel project exists.

#### Scenario: Recent writing exists
- **WHEN** at least one novel exists and recent writing state references a valid novel or chapter
- **THEN** the primary work card offers to continue that real writing target

#### Scenario: Recent writing does not exist
- **WHEN** at least one novel exists but no valid recent writing state exists
- **THEN** the primary work card prompts the user to choose a novel to continue

#### Scenario: Project list exists
- **WHEN** at least one novel exists
- **THEN** the novel projects section displays the real project list and project actions

### Requirement: Dashboard statistics
The system SHALL display dashboard statistics derived from real local state.

#### Scenario: Writing goal is set
- **WHEN** a writing goal exists for the current day
- **THEN** the system displays current progress and the target word count

#### Scenario: Writing goal is not set
- **WHEN** no writing goal exists for the current day
- **THEN** the system displays the writing goal as unset instead of using a default target

#### Scenario: Total word count
- **WHEN** the dashboard loads statistics
- **THEN** the system displays the total word count aggregated from real writing content

#### Scenario: Project count
- **WHEN** the dashboard loads statistics
- **THEN** the system displays the count of real novel projects

### Requirement: Project search and empty results
The system SHALL support searching real novel projects when projects exist.

#### Scenario: Search matches projects
- **WHEN** the user searches with a query that matches one or more novels
- **THEN** the system displays only matching real novel projects

#### Scenario: Search has no matches
- **WHEN** the user searches with a query that matches no novels
- **THEN** the system displays a search-empty state without replacing it with first-use empty state

### Requirement: Primary dashboard actions
The system SHALL provide direct dashboard actions for creating a novel, importing a novel, opening a project, opening AI configuration, and toggling theme only when those actions are backed by real app behavior.

#### Scenario: Create novel action
- **WHEN** the user activates the create novel action
- **THEN** the system starts the real create-novel flow

#### Scenario: Import novel action
- **WHEN** the user activates the import novel action
- **THEN** the system starts the real import flow

#### Scenario: Open project action
- **WHEN** the user activates a real novel project card
- **THEN** the system opens that project

#### Scenario: Optional configuration action
- **WHEN** the dashboard displays an AI configuration entry
- **THEN** activating it opens a real configuration surface and does not show fake configuration state

#### Scenario: Optional theme action
- **WHEN** the dashboard displays a theme toggle
- **THEN** activating it changes the real app theme state
