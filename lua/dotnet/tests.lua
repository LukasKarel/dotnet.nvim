local log = require('dotnet.log')
local queries = require('dotnet.queries')
local global = require('dotnet.global')
local utils = require('dotnet.utils')

local M = {}

local merge_test_data = function(state)
	local tests = {}
	for key in pairs(state.names) do
		table.insert(tests, {
			name = state.names[key],
			succeeded = state.results[key],
			output = state.outputs[key],
			trace = state.traces[key],
		})
	end
	return tests
end

local extract_test_data = function(test_output_file)
	local fileContent = utils.readFile(test_output_file)
	fileContent = fileContent:sub(4)
	local parser = vim.treesitter.get_string_parser(fileContent, "xml", nil)
	if not parser then
		log.error('could not create parser for ' .. test_output_file)
		return
	end
	parser:parse();
	local tree = parser:trees()[1]
	if not tree then
		log.error('could not load tree from parser for ' .. test_output_file)
		return
	end
	local state = { names = {}, results = {}, outputs = {}, traces = {}}
	local resultQuery = vim.treesitter.query.parse("xml", queries.TestResult)
	for id, node, _ in resultQuery:iter_captures(tree:root(), fileContent, 0, -1) do
		local name = resultQuery.captures[id]
		if name == "testName" then
			local testName = vim.treesitter.get_node_text(node, fileContent, nil):sub(2, -2)
			table.insert(state.names, testName)
		end
		if(name == "testResult") then
			local resultString = vim.treesitter.get_node_text(node, fileContent, nil):sub(2, -2)
			local success = resultString:lower() == "passed"
			table.insert(state.results, success)
		end
		if(name == "output") then
			local output = vim.treesitter.get_node_text(node, fileContent, nil)
			state.outputs[#state.names] = output
		end
		if(name == "stackTrace") then
			local trace = vim.treesitter.get_node_text(node, fileContent, nil)
			state.traces[#state.names] = trace
		end
	end

	return merge_test_data(state)
end


local run_tests = function(project_name, output_file, callback)
	vim.fn.jobstart({"dotnet", "test", project_name, "--logger", "\"trx;logfilename=".. output_file .."\""}, {
		on_exit = function()
			if callback then
				callback(project_name)
			end
		end,
		cwd = global.working_directory,
	})
end

local get_path_to_testfile = function(project_name, file_name)
	return global.working_directory .. "/" .. project_name .. "/TestResults/" .. file_name
end

local extract_functions = function(text, method_offset)
	local parser = vim.treesitter.get_string_parser(text, "c_sharp", nil)
	if not parser then
		log.error('could not create parser for to extract functions of ' .. text)
		return
	end
	parser:parse();
	local tree = parser:trees()[1]
	if not tree then
		log.error('could not load tree from parser for functions of ' .. text)
		return
	end
	local query = vim.treesitter.query.parse("c_sharp", queries.methods)
	local methods = {}
	for id, node in query:iter_captures(tree:root(), text, 0, -1) do
		local name = query.captures[id]
		if(name == "methodname") then
			local line = node:range()
			local method = vim.treesitter.get_node_text(node, text, nil)
			table.insert(methods, { name = method, line = method_offset + line})
		end
	end
	return methods
end

local extract_tests = function(file)
	local fileContent = utils.readFile(file)
	local parser = vim.treesitter.get_string_parser(fileContent, "c_sharp", nil)
	if not parser then
		log.error('could not create parser for ' .. file)
		return
	end
	parser:parse();
	local tree = parser:trees()[1]
	if not tree then
		log.error('could not load tree from parser for ' .. file)
	end
	local query = vim.treesitter.query.parse("c_sharp", queries.namespace_class)
	local state = {namespace = nil, classes = {}}
	for id, node in query:iter_captures(tree:root(), fileContent, 0, -1) do
		local name = query.captures[id]
		if(name == "namespace") then
			local namespace = vim.treesitter.get_node_text(node, fileContent, nil)
			state.namespace = namespace
		end
		if(name == "classname") then
			local class = vim.treesitter.get_node_text(node, fileContent, nil)
			table.insert(state.classes, {name = class, methods = {}})
		end
		if(name == "decl") then
			local method = vim.treesitter.get_node_text(node, fileContent, nil)
			local beginline = node:range()
			local methods = extract_functions(method, beginline)
			state.classes[#state.classes].methods = methods
		end
	end

	local tests = {}
	for _, class in pairs(state.classes) do
		for _, method in pairs(class.methods) do
			table.insert(tests, {
				name = state.namespace .. "." .. class.name .. "." .. method.name,
				line = method.line
			})
		end
	end
	return tests
end


M.run_tests = run_tests
M.extract_test_data = extract_test_data
M.get_path_to_testfile = get_path_to_testfile
M.get_test_methods_of_file = extract_tests


return M

