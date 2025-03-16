local tabline_options = {
	show_index = true,
	show_modify = true,
	fnamemodify = ":t",
	brackets = { "[", "]" },
	no_name = "No Name",
	modify_indicator = " [+]",
	inactive_tab_max_length = 0,
}

function _G.project_tabline()
	local s = ""

	for index, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
		local winnr = vim.fn.tabpagewinnr(index)
		local buflist = vim.fn.tabpagebuflist(index)
		local bufnr = buflist[winnr]
		local bufname = vim.fn.bufname(bufnr)
		local bufmodified = vim.fn.getbufvar(bufnr, "&mod")

		if index == vim.fn.tabpagenr() then
			s = s .. "%#TabLineSel#"
		else
			s = s .. "%#TabLine#"
		end

		-- tab index so mouse clicks work
		s = s .. "%" .. index .. "T"

		s = s .. " "

		-- index
		if tabline_options.show_index then
			s = s .. index .. ":"
		end

		-- project name
		if vim.t[tabpage].project ~= nil then
			s = s .. vim.t[tabpage].project .. ":"
		end

		-- buf name
		s = s .. tabline_options.brackets[1]
		local pre_title_s_len = string.len(s)

		local filetype = vim.fn.getbufvar(bufnr, "&filetype")
		if vim.tbl_contains({ "fugitive", "oil", "checkhealth" }, filetype) then
			s = s .. filetype
		else
			if bufname ~= "" then
				if type(tabline_options.fnamemodify) == "function" then
					s = s .. tabline_options.fnamemodify(bufname)
				else
					s = s .. vim.fn.fnamemodify(bufname, tabline_options.fnamemodify)
				end
			else
				s = s .. tabline_options.no_name
			end
		end
		if
			tabline_options.inactive_tab_max_length
			and tabline_options.inactive_tab_max_length > 0
			and index ~= vim.fn.tabpagenr()
		then
			s = string.sub(s, 1, pre_title_s_len + tabline_options.inactive_tab_max_length)
		end
		s = s .. tabline_options.brackets[2]

		-- modify indicator
		if bufmodified == 1 and tabline_options.show_modify and tabline_options.modify_indicator ~= nil then
			s = s .. tabline_options.modify_indicator
		end

		-- additional space at the end of each tab segment
		s = s .. " "
	end

	-- after the last tab fill with TabLineFill and reset tab page nr
	s = s .. "%#TabLineFill#%T"

	-- right-align the label to close the current tab page
	if vim.fn.tabpagenr("$") > 1 then
		s = s .. "%=%#TabLine#%999Xclose"
	end

	return s
end

vim.opt.showtabline = 1 -- always show tabline
vim.opt.tabline = "%!v:lua.project_tabline()"

local get_projects_dir = function()
	return (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/projects"
end

local get_projects = function(projects_dir)
	local projects = {}

	for name, type in vim.fs.dir(projects_dir) do
		if type == "directory" then
			table.insert(projects, name)
		end
	end

	return projects
end

local open_project = function(projects_dir)
	return function(selection)
		if not selection or selection == "" then
			return
		end

		local project_path = vim.fs.joinpath(projects_dir, selection)
		if vim.fn.isdirectory(project_path) ~= 0 then
			vim.api.nvim_command("$tabnew")
			vim.api.nvim_command(string.format("tcd %s", project_path))
			vim.t.project = vim.fs.basename(project_path)
		else
			error("Project '" .. selection .. "' does not exist", vim.log.levels.ERROR)
		end
	end
end

vim.keymap.set("n", "<Leader>p", function()
	local projects_dir = get_projects_dir()

	vim.ui.select(get_projects(projects_dir), { prompt = "Project:" }, open_project(projects_dir))
end, { desc = "Select project" })

vim.api.nvim_create_user_command("Project", function(args)
	open_project(get_projects_dir())(args["args"])
end, {
	desc = "Select a project",
	nargs = 1,
	complete = function(arg_lead, cmd_line, cursor_pos)
		_, _ = cmd_line, cursor_pos

		local completions = {}

		for _, project in ipairs(get_projects(get_projects_dir())) do
			local i, _ = string.find(project, arg_lead)
			if i == 1 then
				table.insert(completions, project)
			end
		end

		return completions
	end,
})

-- Ensure that when we do `:tabnew` outside of spawning a new project tab, we
-- start from the default working directory ($HOME).
vim.api.nvim_create_autocmd("TabNewEntered", {
	group = vim.api.nvim_create_augroup("ProjectChangeDirectory", { clear = true }),
	callback = function(args)
		_ = args

		if vim.t.project == nil then
			vim.cmd.tcd()
		end
	end,
})
