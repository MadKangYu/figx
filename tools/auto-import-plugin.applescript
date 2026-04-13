-- Auto-import figma-mcp-go development plugin into Figma Desktop.
-- Locale-aware menu traversal (EN/KO/JA/ZH) — no Quick Actions.
--
-- Usage:
--   osascript auto-import-plugin.applescript /absolute/path/to/manifest.json

on run argv
	if (count of argv) < 1 then error "usage: auto-import-plugin.applescript <manifest.json path>"
	set manifestPath to item 1 of argv

	-- Locale menu names
	set pluginMenuNames to {"Plugins", "플러그인", "プラグイン", "插件"}
	set devMenuNames to {"Development", "개발", "開発", "开发"}
	set importNames to {"Import plugin from manifest…", "Import plugin from manifest...", "Import plugin from manifest", "매니페스트에서 플러그인 가져오기…", "매니페스트에서 플러그인 가져오기...", "매니페스트에서 플러그인 가져오기"}

	tell application "Figma" to activate
	delay 0.6

	tell application "System Events"
		tell process "Figma"
			set topNames to name of every menu bar item of menu bar 1

			-- Plugins menu
			set pluginMenu to missing value
			repeat with cand in pluginMenuNames
				if topNames contains (cand as text) then
					set pluginMenu to menu bar item (cand as text) of menu bar 1
					exit repeat
				end if
			end repeat
			if pluginMenu is missing value then error "Plugins menu not found (" & (topNames as text) & ")"
			click pluginMenu
			delay 0.3

			-- Development submenu
			set devItem to missing value
			tell menu 1 of pluginMenu
				set subNames to name of every menu item
				repeat with cand in devMenuNames
					if subNames contains (cand as text) then
						set devItem to menu item (cand as text)
						exit repeat
					end if
				end repeat
			end tell
			if devItem is missing value then error "Development submenu not found"
			click devItem
			delay 0.3

			-- Import-from-manifest item
			set importClicked to false
			tell menu 1 of devItem
				set devSubNames to name of every menu item
				repeat with cand in importNames
					if devSubNames contains (cand as text) then
						click menu item (cand as text)
						set importClicked to true
						exit repeat
					end if
				end repeat
			end tell
			if not importClicked then error "Import-plugin-from-manifest item not found"

			delay 1.0

			-- File dialog now open. Cmd+Shift+G → type path → Enter → Enter.
			keystroke "g" using {command down, shift down}
			delay 0.5
			keystroke manifestPath
			delay 0.3
			key code 36 -- Return (Go)
			delay 0.7
			key code 36 -- Return (Open)
		end tell
	end tell

	return "✓ import dispatched: " & manifestPath
end run
