## ADDED Requirements

### Requirement: Provide four workspace regions
The system SHALL present the workspace as four regions: tool rail, module tree, content pane, and agent pane.

#### Scenario: User opens the workspace
- **WHEN** the workspace loads on a desktop viewport
- **THEN** the system displays the tool rail, module tree, content pane, and agent pane at the same time

### Requirement: Treat module tree entries as functional modules
The system SHALL map each module tree item to a module definition with title, purpose, related data, available actions, and related agents.

#### Scenario: User selects a module
- **WHEN** the user clicks a module tree item
- **THEN** the content pane updates to that module's title, description, data, and actions

### Requirement: Support System modules
The system SHALL provide functional System modules for Overview and Entity Relationship Graph.

#### Scenario: User selects Overview
- **WHEN** the user selects "概览"
- **THEN** the content pane shows current work summary, status, and primary next actions

#### Scenario: User selects Entity Relationship Graph
- **WHEN** the user selects "实体关系图"
- **THEN** the content pane shows relationship-oriented empty state or relationship data for people, forces, places, items, and hooks

### Requirement: Support Creation modules
The system SHALL provide functional Creation modules for Chapters, Outline, Characters, and Foreshadowing.

#### Scenario: User selects Chapters
- **WHEN** the user selects "章节"
- **THEN** the content pane shows chapter-related records and chapter actions

#### Scenario: User selects Outline
- **WHEN** the user selects "大纲"
- **THEN** the content pane shows outline-related records and outline actions

#### Scenario: User selects Characters
- **WHEN** the user selects "人物"
- **THEN** the content pane shows character-related records and character actions

#### Scenario: User selects Foreshadowing
- **WHEN** the user selects "伏笔"
- **THEN** the content pane shows hook-related records and hook actions

### Requirement: Support Setting modules
The system SHALL provide functional Setting modules for worldbuilding, map, forces, creatures, items, skills, and materials.

#### Scenario: User selects a setting module
- **WHEN** the user selects any Setting module
- **THEN** the content pane shows records and actions specific to that setting domain

### Requirement: Support AI modules
The system SHALL provide functional AI modules for chat, roundtable, monologue, skit, roleplay, agent planning, and agent skills.

#### Scenario: User selects an AI module
- **WHEN** the user selects any AI module
- **THEN** the content pane shows AI workflow controls and the agent pane updates to the related agent context
