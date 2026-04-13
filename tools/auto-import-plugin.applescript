-- Auto-import figma-mcp-go plugin into Figma Desktop
-- Uses macOS Accessibility + Quick Actions (Cmd+/)

on run argv
	set manifestPath to item 1 of argv

	-- Activate Figma Desktop
	tell application "Figma" to activate
	delay 1.2

	tell application "System Events"
		tell process "Figma"
			-- Open Quick Actions (Cmd+/)
			keystroke "/" using {command down}
			delay 0.8

			-- Type the action name
			keystroke "Import plugin from manifest"
			delay 0.5

			-- Confirm action
			key code 36 -- Return
			delay 1.5

			-- File dialog should be open. Use Go to Folder (Cmd+Shift+G)
			keystroke "g" using {command down, shift down}
			delay 0.6

			-- Type the manifest path
			keystroke manifestPath
			delay 0.3
			key code 36 -- Return (path go)
			delay 0.8
			key code 36 -- Return (open file)
		end tell
	end tell

	return "✓ plugin import sequence dispatched"
end run
