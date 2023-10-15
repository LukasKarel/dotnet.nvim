-- TODO remove
package.loaded['nvim-dotnet.queries'] = nil
package.loaded['nvim-dotnet.utils'] = nil
package.loaded['nvim-dotnet.global'] = nil
package.loaded['nvim-dotnet.solution'] = nil
package.loaded['nvim-dotnet.tests'] = nil
package.loaded['nvim-dotnet.projects'] = nil
package.loaded['nvim-dotnet.comment'] = nil
local utils = require('nvim-dotnet.utils')
local log = require('nvim-dotnet.log')
local global_state = require('nvim-dotnet.global')
local solution = require('nvim-dotnet.solution')
local tests = require('nvim-dotnet.tests')
local projectsns = require('nvim-dotnet.projects')
local commentns = require('nvim-dotnet.comment')


local M = {};

M.initialize = function ()
	global_state.solution_file = solution.search_solution()
	if not global_state.solution_file then
		log.warn("Did not find solution file")
		return
	end
	global_state.projects = solution.extract_projects(global_state.solution_file)
	if global_state.projects == nil then
		log.warn("Could not extract projects of solution file")
		return
	end
end

M.setup = function ()
	M.initialize()
	if not global_state.solution_file then
		return
	end
	vim.api.nvim_create_user_command("DotnetTest", M.test, { desc="Run all tests of the current project"})
	vim.api.nvim_create_user_command("DotnetComment", commentns.comment, { desc="Comment element under the cursor. Works with function and class."})
end


M.test = function()
	local test_projects = utils.where(global_state.projects, function(proj)
		return proj.test
	end)
	local bufnr = vim.api.nvim_get_current_buf()
	local file = vim.api.nvim_buf_get_name(bufnr)
	local test_project = utils.find(test_projects, function(project)
		return projectsns.is_file_of_project(project, file)
	end)
	if not test_project then
		log.error(file .. " is not part of a test project")
		return
	end
	tests.run_tests(test_project.name, "Tests.trx", function()
		local test_result = tests.extract_test_data(test_project.path .. "/TestResults/Tests.trx")
		local test_line_information = tests.get_test_methods_of_file(file)
		if not test_line_information then
			log.error("was not able to find test methods")
			return
		end
		if not test_result then
			log.error("Was not able to extract test result information")
			return
		end
		local test_line_mapping = {}
		for _, v in pairs(test_line_information) do
			test_line_mapping[v.name] = v.line
		end
		local diag = {}
		for _, v in pairs(test_result) do
			local line = test_line_mapping[v.name]
			local message = "Test succeeded"
			local severity = vim.diagnostic.severity.INFO
			if not v.succeeded then
				message = "Test failed"
				severity = vim.diagnostic.severity.ERROR
			end
			if line then
				table.insert(diag, {
					lnum = line,
					col = 0,
					message = message,
					severity = severity,
					source = "nvim-dotnet",
				})
			end
		end
		vim.diagnostic.set(global_state.namespace, bufnr, diag, {})
	end)
end


return M
