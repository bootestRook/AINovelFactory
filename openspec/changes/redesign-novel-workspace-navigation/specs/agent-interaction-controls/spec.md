## ADDED Requirements

### Requirement: Show current agent context
The system SHALL display the current selected agent, its role, and its responsibilities in the agent pane.

#### Scenario: User selects an agent
- **WHEN** the user selects an agent from the agent list
- **THEN** the current agent panel updates to that agent's name, role, and responsibilities

### Requirement: Enable and disable agents
The system SHALL allow users to enable or disable agents from the agent list.

#### Scenario: User disables an agent
- **WHEN** the user unchecks an enabled agent
- **THEN** the agent is marked disabled in the UI

#### Scenario: User enables an agent
- **WHEN** the user checks a disabled agent
- **THEN** the agent is marked enabled in the UI

### Requirement: Bind modules to relevant agents
The system SHALL show which agents are relevant to the currently selected module.

#### Scenario: User changes modules
- **WHEN** the user selects a different module
- **THEN** the agent pane highlights or lists the agents relevant to that module

### Requirement: Provide current-agent chat input
The system SHALL provide a chat input scoped to the current selected agent.

#### Scenario: User enters an agent message
- **WHEN** the user types a message in the agent chat input
- **THEN** the system keeps the message scoped to the selected current agent

### Requirement: Provide agent planning controls
The system SHALL provide controls for inspecting the agent plan and changing the enabled agent set before running generation.

#### Scenario: User opens agent planning
- **WHEN** the user selects "智能体规划"
- **THEN** the content pane shows the planned agent sequence and controls for agent participation
