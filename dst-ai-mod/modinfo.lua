name = "DST AI Player (MCP)"
description = "AI controls your DST character through MCP. Auto-enables on spawn."
author = "AI Assistant"
version = "1.0.0"

forumthread = ""
api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
all_clients_require_mod = false
client_only_mod = true

server_filter_tags = {"character", "utility"}

configuration_options =
{
    {
        name = "sync_dir",
        label = "Sync Directory",
        hover = "File sync directory for MCP server communication",
        options =
        {
            {description = "%USERPROFILE%\\dst-ai-sync\\", data = "%USERPROFILE%\\dst-ai-sync\\"},
        },
        default = "%USERPROFILE%\\dst-ai-sync\\",
    },
    {
        name = "update_interval",
        label = "Update Interval (frames)",
        hover = "State collection and command check interval in frames",
        options =
        {
            {description = "1 frame (fastest)", data = 1},
            {description = "5 frames", data = 5},
            {description = "10 frames (recommended)", data = 10},
            {description = "20 frames", data = 20},
        },
        default = 10,
    },
    {
        name = "scan_radius",
        label = "Scan Radius",
        hover = "Entity scan range around player",
        options =
        {
            {description = "10 units", data = 10},
            {description = "15 units", data = 15},
            {description = "20 units (recommended)", data = 20},
            {description = "30 units", data = 30},
        },
        default = 20,
    },
    {
        name = "max_entities",
        label = "Max Entities",
        hover = "Maximum number of nearby entities to collect",
        options =
        {
            {description = "10", data = 10},
            {description = "15 (recommended)", data = 15},
            {description = "20", data = 20},
            {description = "30", data = 30},
        },
        default = 15,
    },
}
