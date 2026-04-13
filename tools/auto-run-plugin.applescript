-- Run the already-imported figma-mcp-go development plugin
-- Uses menu navigation (locale-independent positional)

on run argv
	set pluginName to item 1 of argv

	tell application "Figma" to activate
	delay 0.8

	tell application "System Events"
		tell process "Figma"
			-- Try English Quick Actions first
			keystroke "/" using {command down}
			delay 0.6
			keystroke "Figma MCP Go"
			delay 0.5
			key code 36 -- Return
		end tell
	end tell

	return "✓ dispatched: " & pluginName
end run
