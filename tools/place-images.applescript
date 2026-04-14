on run argv
	if (count of argv) is less than 1 then error "directory path required"
	set targetDir to item 1 of argv

	tell application "Figma" to activate
	delay 0.6

	tell application "System Events"
		if UI elements enabled is false then error "Accessibility access is required for System Events"

		tell process "Figma"
			keystroke "k" using {command down, shift down}
			delay 1.0

			keystroke "g" using {command down, shift down}
			delay 0.5

			keystroke targetDir
			delay 0.2
			key code 36
			delay 0.8

			keystroke "a" using {command down}
			delay 0.2
			key code 36
		end tell
	end tell

	return "ok"
end run
