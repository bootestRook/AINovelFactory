## ADDED Requirements

### Requirement: Open work creation as a modal
The system SHALL open work creation in a secondary modal window without replacing the main workspace.

#### Scenario: User starts a new work
- **WHEN** the user clicks "新建作品"
- **THEN** the system displays a modal dialog for work creation above the workspace

### Requirement: Capture work metadata
The system SHALL allow the user to enter a work title, cover image, description, category, work type, and custom tags.

#### Scenario: User completes work metadata
- **WHEN** the user fills the creation form and clicks "创建"
- **THEN** the system stores the metadata as the current work and closes the modal

### Requirement: Preview selected cover
The system SHALL show the selected cover image in a fixed book-cover preview area without cropping the image.

#### Scenario: User selects a cover image
- **WHEN** the user chooses an image file from the cover picker
- **THEN** the system previews the full image inside the cover frame

### Requirement: Manage custom tags
The system SHALL allow users to add multiple custom tags and remove existing tags before creating the work.

#### Scenario: User adds a tag
- **WHEN** the user enters a tag value and confirms it
- **THEN** the system adds the tag to the visible tag list

#### Scenario: User removes a tag
- **WHEN** the user clicks an existing tag
- **THEN** the system removes that tag from the visible tag list
