local utils = require('dotnet.utils')
local log = require('dotnet.log')
local global = require('dotnet.global')
local projectns = require('dotnet.projects')

local extract_projects = function(solution_file)
	local file_content = utils.readFile(solution_file)
	local projects = {}
	local last_begin = 1
	local capture_definition = "Project%(.*%)%s*=%s*\"(.*)\",%s*\"(.*)\",.*EndProject"
	while (last_begin ~= nil) do
		local begin_project = string.find(file_content, "Project(\"{", last_begin, true)
		if(begin_project == nil) then break end
		local _, end_project = string.find(file_content, "EndProject", begin_project)
		if(end_project == nil) then return nil end -- invalid solution file
		last_begin = end_project
		local project_line = string.sub(file_content, begin_project, end_project)
		local project_name, project_path = string.match(project_line, capture_definition)
		local project_file_path = global.working_directory .. "/" .. string.gsub(project_path, "\\", "/")
		local project_cwd = string.match(project_file_path, ".*/")
		project_cwd = string.sub(project_cwd, 1, -2)
		table.insert(projects, {name = project_name, file = project_file_path, path = project_cwd, test = projectns.is_test_project(project_file_path)})
	end
	return projects;
end


local search_solution = function()
	local pwd = global.working_directory
	local dir = assert(vim.loop.fs_scandir(pwd), "cant scan working directory")
	local dir_entry, file_type;
	repeat
		dir_entry, file_type = vim.loop.fs_scandir_next(dir)
		if(file_type and file_type:lower() == "file") and dir_entry:find(".sln", -4, true) then
			return global.working_directory .. "/" .. dir_entry
		end
	until not dir_entry
end


local solution = {
	search_solution = search_solution,
	extract_projects = extract_projects,
}




return solution
