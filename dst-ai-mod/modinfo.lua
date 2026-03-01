name = "DST AI Player"
description = "AI controls your DST character through MCP protocol."
author = "AI Assistant"
version = "1.0.0"

forumthread = ""
api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
all_clients_require_mod = true
client_only_mod = false

server_filter_tags = {"character", "utility"}

configuration_options =
{
    {
        name = "sync_dir",
        label = "Sync Directory",
        hover = "Directory for MCP server communication",
        options =
        {
            {description = "Default", data = "%USERPROFILE%\\dst-ai-sync\\"},
        },
        default = "%USERPROFILE%\\dst-ai-sync\\",
    },
    {
        name = "update_interval",
        label = "Update Interval (frames)",
        hover = "State collection and command check interval",
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
        hover = "Entity collection range",
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
        hover = "Maximum number of entities to collect",
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
