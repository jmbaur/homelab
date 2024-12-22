-- partially inspired by https://mwop.net/blog/2024-07-04-how-i-use-wezterm.html

local wezterm = require("wezterm")
local action = wezterm.action

local config = wezterm.config_builder()

config.automatically_reload_config = false
config.check_for_updates = false
config.color_scheme = "Modus-Vivendi"
config.default_domain = "local"
config.default_workspace = "default"
config.enable_scroll_bar = true
config.font = wezterm.font("monospace")
config.front_end = "WebGpu"
config.inactive_pane_hsb = { saturation = 0.7, brightness = 0.7 }
config.leader = { key = "s", mods = "CTRL" }
config.switch_to_last_active_tab_when_closing_tab = true
config.tab_bar_at_bottom = true
config.unix_domains = { { name = "unix" } }
config.use_dead_keys = false
config.use_fancy_tab_bar = false
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

local last_active_workspace = { config.default_workspace, config.default_workspace }

wezterm.on("update-status", function(window, _)
	local status = {}
	if window:leader_is_active() then
		table.insert(status, { Text = "\xc2\xb7" .. " " })
	end

	local active_workspace = window:active_workspace()
	table.insert(status, { Text = active_workspace })
	window:set_right_status(wezterm.format(status))

	if last_active_workspace[1] ~= active_workspace then
		last_active_workspace[2] = last_active_workspace[1]
		last_active_workspace[1] = active_workspace
	end
end)

local switch_to_last_active_workspace = wezterm.action_callback(function(window, pane)
	_, _ = window, pane

	local current_workspace = wezterm.mux.get_active_workspace()

	local last_active_found = false
	local workspaces = wezterm.mux.get_workspace_names()
	for _, workspace in ipairs(workspaces) do
		if workspace == last_active_workspace[2] then
			last_active_found = true
			break
		end
	end

	if not last_active_found then
		wezterm.log_warn(string.format("workspace '%s' not found", last_active_workspace[2]))
		return
	end

	if last_active_workspace[2] == current_workspace then
		wezterm.log_info(string.format("workspace '%s' already active", current_workspace))
		return
	end

	wezterm.mux.set_active_workspace(last_active_workspace[2])

	last_active_workspace[2] = last_active_workspace[1]
	last_active_workspace[1] = current_workspace
end)

local rename_tab = action.PromptInputLine({
	description = "Rename tab",
	action = wezterm.action_callback(function(window, _, line)
		if line then -- line is nil if user input is cancelled
			window:active_tab():set_title(line)
		end
	end),
})

local rename_workspace = action.PromptInputLine({
	description = "Rename workspace",
	action = wezterm.action_callback(function(window, pane, line)
		_, _ = window, pane
		if line then -- line is nil if user input is cancelled
			wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
		end
	end),
})

config.key_tables = {
	resize_pane = {
		{ key = "LeftArrow", action = action.AdjustPaneSize({ "Left", 1 }) },
		{ key = "h", action = action.AdjustPaneSize({ "Left", 1 }) },

		{ key = "RightArrow", action = action.AdjustPaneSize({ "Right", 1 }) },
		{ key = "l", action = action.AdjustPaneSize({ "Right", 1 }) },

		{ key = "UpArrow", action = action.AdjustPaneSize({ "Up", 1 }) },
		{ key = "k", action = action.AdjustPaneSize({ "Up", 1 }) },

		{ key = "DownArrow", action = action.AdjustPaneSize({ "Down", 1 }) },
		{ key = "j", action = action.AdjustPaneSize({ "Down", 1 }) },

		{ key = "Escape", action = "PopKeyTable" },
		{ key = "[", mods = "CTRL", action = "PopKeyTable" },
	},
}

config.keys = {
	-- { key = "l", mods = "LEADER|SHIFT", action = switch_to_last_active_tab }, -- TODO(jared): implement this
	{ key = "$", mods = "LEADER|SHIFT", action = rename_workspace },
	{ key = "%", mods = "LEADER|SHIFT", action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "&", mods = "LEADER|SHIFT", action = action.CloseCurrentTab({ confirm = true }) },
	{ key = "(", mods = "LEADER|SHIFT", action = action.SwitchWorkspaceRelative(-1) },
	{ key = ")", mods = "LEADER|SHIFT", action = action.SwitchWorkspaceRelative(1) },
	{ key = ",", mods = "LEADER", action = rename_tab },
	{ key = ";", mods = "LEADER", action = action.ActivatePaneDirection("Prev") },
	{ key = "?", mods = "LEADER|SHIFT", action = action.ShowLauncher },
	{ key = "L", mods = "LEADER|SHIFT", action = switch_to_last_active_workspace },
	{ key = "[", mods = "LEADER", action = wezterm.action.ActivateCopyMode },
	{ key = '"', mods = "LEADER|SHIFT", action = action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "]", mods = "LEADER", action = action.PasteFrom("Clipboard") },
	{ key = "c", mods = "LEADER", action = action.SpawnTab("CurrentPaneDomain") },
	{ key = "d", mods = "LEADER", action = action.DetachDomain({ DomainName = "unix" }) },
	{ key = "n", mods = "LEADER", action = action.ActivateTabRelative(1) },
	{ key = "o", mods = "LEADER", action = action.ActivatePaneDirection("Next") },
	{ key = "p", mods = "LEADER", action = action.ActivateTabRelative(-1) },
	{
		key = "r",
		mods = "LEADER",
		action = action.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
	},
	{
		key = "s",
		mods = "LEADER",
		action = action.ShowLauncherArgs({ flags = "WORKSPACES", title = "workspaces" }),
	},
	{
		key = "w",
		mods = "LEADER",
		action = action.ShowLauncherArgs({ flags = "TABS", title = "tabs" }),
	},
	{ key = "x", mods = "LEADER", action = action.CloseCurrentPane({ confirm = true }) },
	{ key = "z", mods = "LEADER", action = action.TogglePaneZoomState },
	{ key = config.leader.key, mods = "LEADER|CTRL", action = action.SendKey(config.leader) },
}

for i = 1, 9 do
	-- LEADER + number to activate that tab
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = action.ActivateTab(i - 1),
	})
end

return config
