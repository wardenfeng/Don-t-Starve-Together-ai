## ADDED Requirements

### Requirement: State file format
The system SHALL write game state to `state.txt` in JSON format with the following fields:
- `v`: Protocol version (integer)
- `hp`: Health percent (float 0-1)
- `hu`: Hunger percent (float 0-1)
- `sa`: Sanity percent (float 0-1)
- `x`: Player X position (float)
- `z`: Player Z position (float)
- `day`: World day count (integer)
- `time`: World time (float 0-1)

#### Scenario: Valid state file
- **WHEN** the game writes state
- **THEN** state.txt contains valid JSON with all required fields
- **AND** all numeric values are within expected ranges

#### Scenario: Update frequency
- **WHEN** the game is running
- **THEN** state.txt is updated every 5 frames (~80ms)
- **AND** file writes are atomic (complete or not at all)

### Requirement: Command file format
The system SHALL read commands from `cmd.txt` in JSON format with the following structure:
- `v`: Protocol version (integer)
- `actions`: Array of action objects

Each action object SHALL contain:
- `type`: Action type (move, chop, mine, attack, pickup, etc.)
- Optional `target`: Position object {x, y, z} for movement
- Optional `entity`: Entity prefab name for targeted actions
- Optional `item`: Item prefab name for item-related actions

#### Scenario: Valid command file
- **WHEN** MCP writes commands
- **THEN** cmd.txt contains valid JSON with actions array
- **AND** each action has a valid type

#### Scenario: Command execution
- **WHEN** commands are read from cmd.txt
- **THEN** each action is executed in order
- **AND** cmd.txt is cleared after reading

### Requirement: Control file format
The system SHALL support control commands via `control.txt` with the following values:
- `enable`: Enable AI control
- `disable`: Disable AI control

#### Scenario: Enable command
- **WHEN** control.txt contains "enable"
- **THEN** AI control is activated
- **AND** state writing begins

#### Scenario: Disable command
- **WHEN** control.txt contains "disable"
- **THEN** AI control is deactivated
- **AND** statistics are logged

### Requirement: File location
The system SHALL use a configurable sync directory defaulting to `C:\dst-ai-sync\`.

#### Scenario: Default directory
- **WHEN** no custom directory is specified
- **THEN** files are written to C:\dst-ai-sync\

#### Scenario: Custom directory
- **WHEN** a custom directory is configured
- **THEN** files are written to the configured location

### Requirement: Error handling
The system SHALL handle file I/O errors gracefully without crashing.

#### Scenario: Directory not found
- **WHEN** the sync directory does not exist
- **THEN** the system attempts to create it
- **AND** logs an error if creation fails

#### Scenario: Invalid JSON in command file
- **WHEN** cmd.txt contains invalid JSON
- **THEN** the file is skipped
- **AND** an error is logged

### Requirement: Performance
The system SHALL complete file I/O operations within 10ms.

#### Scenario: State write latency
- **WHEN** writing state
- **THEN** the write operation completes within 10ms
- **AND** does not block game rendering

#### Scenario: Command read latency
- **WHEN** reading commands
- **THEN** the read operation completes within 5ms
