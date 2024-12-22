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
config.disable_default_key_bindings = true

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
		wezterm.log_warn(string.format('workspace "%s" not found', last_active_workspace[2]))
		return
	end

	if last_active_workspace[2] == current_workspace then
		wezterm.log_info(string.format('workspace "%s" already active', current_workspace))
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
	copy_mode = {
		{ key = "Tab", mods = "NONE", action = action.CopyMode("MoveForwardWord") },
		{ key = "Tab", mods = "SHIFT", action = action.CopyMode("MoveBackwardWord") },
		{ key = "Enter", mods = "NONE", action = action.CopyMode("MoveToStartOfNextLine") },
		{ key = "Escape", mods = "NONE", action = action.CopyMode("Close") },
		{ key = "Space", mods = "NONE", action = action.CopyMode({ SetSelectionMode = "Cell" }) },
		{ key = "$", mods = "NONE", action = action.CopyMode("MoveToEndOfLineContent") },
		{ key = "$", mods = "SHIFT", action = action.CopyMode("MoveToEndOfLineContent") },
		{ key = ",", mods = "NONE", action = action.CopyMode("JumpReverse") },
		{ key = "0", mods = "NONE", action = action.CopyMode("MoveToStartOfLine") },
		{ key = ";", mods = "NONE", action = action.CopyMode("JumpAgain") },
		{ key = "F", mods = "NONE", action = action.CopyMode({ JumpBackward = { prev_char = false } }) },
		{ key = "F", mods = "SHIFT", action = action.CopyMode({ JumpBackward = { prev_char = false } }) },
		{ key = "G", mods = "NONE", action = action.CopyMode("MoveToScrollbackBottom") },
		{ key = "G", mods = "SHIFT", action = action.CopyMode("MoveToScrollbackBottom") },
		{ key = "H", mods = "NONE", action = action.CopyMode("MoveToViewportTop") },
		{ key = "H", mods = "SHIFT", action = action.CopyMode("MoveToViewportTop") },
		{ key = "L", mods = "NONE", action = action.CopyMode("MoveToViewportBottom") },
		{ key = "L", mods = "SHIFT", action = action.CopyMode("MoveToViewportBottom") },
		{ key = "M", mods = "NONE", action = action.CopyMode("MoveToViewportMiddle") },
		{ key = "M", mods = "SHIFT", action = action.CopyMode("MoveToViewportMiddle") },
		{ key = "O", mods = "NONE", action = action.CopyMode("MoveToSelectionOtherEndHoriz") },
		{ key = "O", mods = "SHIFT", action = action.CopyMode("MoveToSelectionOtherEndHoriz") },
		{ key = "T", mods = "NONE", action = action.CopyMode({ JumpBackward = { prev_char = true } }) },
		{ key = "T", mods = "SHIFT", action = action.CopyMode({ JumpBackward = { prev_char = true } }) },
		{ key = "V", mods = "NONE", action = action.CopyMode({ SetSelectionMode = "Line" }) },
		{ key = "V", mods = "SHIFT", action = action.CopyMode({ SetSelectionMode = "Line" }) },
		{ key = "^", mods = "NONE", action = action.CopyMode("MoveToStartOfLineContent") },
		{ key = "^", mods = "SHIFT", action = action.CopyMode("MoveToStartOfLineContent") },
		{ key = "b", mods = "NONE", action = action.CopyMode("MoveBackwardWord") },
		{ key = "b", mods = "ALT", action = action.CopyMode("MoveBackwardWord") },
		{ key = "b", mods = "CTRL", action = action.CopyMode("PageUp") },
		{ key = "c", mods = "CTRL", action = action.CopyMode("Close") },
		{ key = "d", mods = "CTRL", action = action.CopyMode({ MoveByPage = 0.5 }) },
		{ key = "e", mods = "NONE", action = action.CopyMode("MoveForwardWordEnd") },
		{ key = "f", mods = "NONE", action = action.CopyMode({ JumpForward = { prev_char = false } }) },
		{ key = "f", mods = "ALT", action = action.CopyMode("MoveForwardWord") },
		{ key = "f", mods = "CTRL", action = action.CopyMode("PageDown") },
		{ key = "g", mods = "NONE", action = action.CopyMode("MoveToScrollbackTop") },
		{ key = "g", mods = "CTRL", action = action.CopyMode("Close") },
		{ key = "h", mods = "NONE", action = action.CopyMode("MoveLeft") },
		{ key = "j", mods = "NONE", action = action.CopyMode("MoveDown") },
		{ key = "k", mods = "NONE", action = action.CopyMode("MoveUp") },
		{ key = "l", mods = "NONE", action = action.CopyMode("MoveRight") },
		{ key = "m", mods = "ALT", action = action.CopyMode("MoveToStartOfLineContent") },
		{ key = "o", mods = "NONE", action = action.CopyMode("MoveToSelectionOtherEnd") },
		{ key = "q", mods = "NONE", action = action.CopyMode("Close") },
		{ key = "t", mods = "NONE", action = action.CopyMode({ JumpForward = { prev_char = true } }) },
		{ key = "u", mods = "CTRL", action = action.CopyMode({ MoveByPage = -0.5 }) },
		{ key = "v", mods = "NONE", action = action.CopyMode({ SetSelectionMode = "Cell" }) },
		{ key = "v", mods = "CTRL", action = action.CopyMode({ SetSelectionMode = "Block" }) },
		{ key = "w", mods = "NONE", action = action.CopyMode("MoveForwardWord") },
		{
			key = "y",
			mods = "NONE",
			action = action.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
		},
		{ key = "PageUp", mods = "NONE", action = action.CopyMode("PageUp") },
		{ key = "PageDown", mods = "NONE", action = action.CopyMode("PageDown") },
		{ key = "End", mods = "NONE", action = action.CopyMode("MoveToEndOfLineContent") },
		{ key = "Home", mods = "NONE", action = action.CopyMode("MoveToStartOfLine") },
		{ key = "LeftArrow", mods = "NONE", action = action.CopyMode("MoveLeft") },
		{ key = "LeftArrow", mods = "ALT", action = action.CopyMode("MoveBackwardWord") },
		{ key = "RightArrow", mods = "NONE", action = action.CopyMode("MoveRight") },
		{ key = "RightArrow", mods = "ALT", action = action.CopyMode("MoveForwardWord") },
		{ key = "UpArrow", mods = "NONE", action = action.CopyMode("MoveUp") },
		{ key = "DownArrow", mods = "NONE", action = action.CopyMode("MoveDown") },
	},

	resize_pane = {
		{ key = "Escape", mods = "NONE", action = action.PopKeyTable },
		{ key = "[", mods = "CTRL", action = action.PopKeyTable },
		{ key = "h", mods = "NONE", action = action.AdjustPaneSize({ "Left", 1 }) },
		{ key = "j", mods = "NONE", action = action.AdjustPaneSize({ "Down", 1 }) },
		{ key = "k", mods = "NONE", action = action.AdjustPaneSize({ "Up", 1 }) },
		{ key = "l", mods = "NONE", action = action.AdjustPaneSize({ "Right", 1 }) },
		{ key = "LeftArrow", mods = "NONE", action = action.AdjustPaneSize({ "Left", 1 }) },
		{ key = "RightArrow", mods = "NONE", action = action.AdjustPaneSize({ "Right", 1 }) },
		{ key = "UpArrow", mods = "NONE", action = action.AdjustPaneSize({ "Up", 1 }) },
		{ key = "DownArrow", mods = "NONE", action = action.AdjustPaneSize({ "Down", 1 }) },
	},

	search_mode = {
		{ key = "Enter", mods = "NONE", action = action.CopyMode("PriorMatch") },
		{ key = "Escape", mods = "NONE", action = action.CopyMode("Close") },
		{ key = "n", mods = "CTRL", action = action.CopyMode("NextMatch") },
		{ key = "p", mods = "CTRL", action = action.CopyMode("PriorMatch") },
		{ key = "r", mods = "CTRL", action = action.CopyMode("CycleMatchType") },
		{ key = "u", mods = "CTRL", action = action.CopyMode("ClearPattern") },
		{ key = "PageUp", mods = "NONE", action = action.CopyMode("PriorMatchPage") },
		{ key = "PageDown", mods = "NONE", action = action.CopyMode("NextMatchPage") },
		{ key = "UpArrow", mods = "NONE", action = action.CopyMode("PriorMatch") },
		{ key = "DownArrow", mods = "NONE", action = action.CopyMode("NextMatch") },
	},

	passthru_mode = {
		{ key = "P", mods = "LEADER|SHIFT", action = action.PopKeyTable },
	},
}

config.keys = {
	-- { key = "l", mods = "LEADER|SHIFT", action = switch_to_last_active_tab }, -- TODO(jared): implement this
	{ key = "Insert", mods = "SHIFT", action = action.PasteFrom("PrimarySelection") },
	{ key = "Insert", mods = "CTRL", action = action.CopyTo("PrimarySelection") },
	{ key = "Copy", mods = "NONE", action = action.CopyTo("Clipboard") },
	{ key = "Paste", mods = "NONE", action = action.PasteFrom("Clipboard") },
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
	{ key = "-", mods = "CTRL", action = action.DecreaseFontSize },
	{ key = "-", mods = "SHIFT|CTRL", action = action.DecreaseFontSize },
	{ key = "-", mods = "SUPER", action = action.DecreaseFontSize },
	{ key = "_", mods = "CTRL", action = action.DecreaseFontSize },
	{ key = "_", mods = "SHIFT|CTRL", action = action.DecreaseFontSize },
	{ key = "=", mods = "CTRL", action = action.IncreaseFontSize },
	{ key = "=", mods = "SHIFT|CTRL", action = action.IncreaseFontSize },
	{ key = "=", mods = "SUPER", action = action.IncreaseFontSize },
	{ key = "+", mods = "CTRL", action = action.IncreaseFontSize },
	{ key = "+", mods = "SHIFT|CTRL", action = action.IncreaseFontSize },
	{ key = "0", mods = "CTRL", action = action.ResetFontSize },
	{ key = "0", mods = "SHIFT|CTRL", action = action.ResetFontSize },
	{ key = "0", mods = "SUPER", action = action.ResetFontSize },
	{ key = ")", mods = "CTRL", action = action.ResetFontSize },
	{ key = ")", mods = "SHIFT|CTRL", action = action.ResetFontSize },
	{ key = "C", mods = "CTRL", action = action.CopyTo("Clipboard") },
	{ key = "C", mods = "SHIFT|CTRL", action = action.CopyTo("Clipboard") },
	{ key = "c", mods = "SHIFT|CTRL", action = action.CopyTo("Clipboard") },
	{ key = "c", mods = "SUPER", action = action.CopyTo("Clipboard") },
	{ key = "V", mods = "CTRL", action = action.PasteFrom("Clipboard") },
	{ key = "V", mods = "SHIFT|CTRL", action = action.PasteFrom("Clipboard") },
	{ key = "v", mods = "SHIFT|CTRL", action = action.PasteFrom("Clipboard") },
	{ key = "v", mods = "SUPER", action = action.PasteFrom("Clipboard") },
	{
		key = "P",
		mods = "LEADER|SHIFT",
		action = action.ActivateKeyTable({
			name = "passthru_mode",
			one_shot = false,
			prevent_fallback = false,
			replace_current = false,
			until_unknown = false,
		}),
	},
	{
		key = "r",
		mods = "LEADER",
		action = action.ActivateKeyTable({
			name = "resize_pane",
			one_shot = false,
			prevent_fallback = false,
			replace_current = false,
			until_unknown = false,
		}),
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

	--
	-- defaults:
	-- { key = "F",          mods = "CTRL",           action = action.Search "CurrentSelectionOrEmptyString" },
	-- { key = "F",          mods = "SHIFT|CTRL",     action = action.Search "CurrentSelectionOrEmptyString" },
	-- { key = "K",          mods = "CTRL",           action = action.ClearScrollback "ScrollbackOnly" },
	-- { key = "K",          mods = "SHIFT|CTRL",     action = action.ClearScrollback "ScrollbackOnly" },
	-- { key = "L",          mods = "CTRL",           action = action.ShowDebugOverlay },
	-- { key = "L",          mods = "SHIFT|CTRL",     action = action.ShowDebugOverlay },
	-- { key = "N",          mods = "CTRL",           action = action.SpawnWindow },
	-- { key = "N",          mods = "SHIFT|CTRL",     action = action.SpawnWindow },
	-- { key = "P",          mods = "CTRL",           action = action.ActivateCommandPalette },
	-- { key = "P",          mods = "SHIFT|CTRL",     action = action.ActivateCommandPalette },
	-- { key = "R",          mods = "CTRL",           action = action.ReloadConfiguration },
	-- { key = "R",          mods = "SHIFT|CTRL",     action = action.ReloadConfiguration },
	-- { key = "U",          mods = "CTRL",           action = action.CharSelect { copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" } },
	-- { key = "U",          mods = "SHIFT|CTRL",     action = action.CharSelect { copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" } },
	-- { key = "W",          mods = "CTRL",           action = action.CloseCurrentTab { confirm = true } },
	-- { key = "W",          mods = "SHIFT|CTRL",     action = action.CloseCurrentTab { confirm = true } },
	-- { key = "f",          mods = "SHIFT|CTRL",     action = action.Search "CurrentSelectionOrEmptyString" },
	-- { key = "f",          mods = "SUPER",          action = action.Search "CurrentSelectionOrEmptyString" },
	-- { key = "k",          mods = "SHIFT|CTRL",     action = action.ClearScrollback "ScrollbackOnly" },
	-- { key = "l",          mods = "SHIFT|CTRL",     action = action.ShowDebugOverlay },
	-- { key = "n",          mods = "SHIFT|CTRL",     action = action.SpawnWindow },
	-- { key = "p",          mods = "SHIFT|CTRL",     action = action.ActivateCommandPalette },
	-- { key = "r",          mods = "SHIFT|CTRL",     action = action.ReloadConfiguration },
	-- { key = "r",          mods = "SUPER",          action = action.ReloadConfiguration },
	-- { key = "u",          mods = "SHIFT|CTRL",     action = action.CharSelect { copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" } },
	-- { key = "phys:Space", mods = "SHIFT|CTRL",     action = action.QuickSelect },
	-- { key = "PageUp",     mods = "SHIFT",          action = action.ScrollByPage(-1) },
	-- { key = "PageUp",     mods = "CTRL",           action = action.ActivateTabRelative(-1) },
	-- { key = "PageUp",     mods = "SHIFT|CTRL",     action = action.MoveTabRelative(-1) },
	-- { key = "PageDown",   mods = "SHIFT",          action = action.ScrollByPage(1) },
	-- { key = "PageDown",   mods = "CTRL",           action = action.ActivateTabRelative(1) },
	-- { key = "PageDown",   mods = "SHIFT|CTRL",     action = action.MoveTabRelative(1) },
	-- { key = "LeftArrow",  mods = "SHIFT|CTRL",     action = action.ActivatePaneDirection "Left" },
	-- { key = "LeftArrow",  mods = "SHIFT|ALT|CTRL", action = action.AdjustPaneSize { "Left", 1 } },
	-- { key = "RightArrow", mods = "SHIFT|CTRL",     action = action.ActivatePaneDirection "Right" },
	-- { key = "RightArrow", mods = "SHIFT|ALT|CTRL", action = action.AdjustPaneSize { "Right", 1 } },
	-- { key = "UpArrow",    mods = "SHIFT|CTRL",     action = action.ActivatePaneDirection "Up" },
	-- { key = "UpArrow",    mods = "SHIFT|ALT|CTRL", action = action.AdjustPaneSize { "Up", 1 } },
	-- { key = "DownArrow",  mods = "SHIFT|CTRL",     action = action.ActivatePaneDirection "Down" },
	-- { key = "DownArrow",  mods = "SHIFT|ALT|CTRL", action = action.AdjustPaneSize { "Down", 1 } },
	--
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
