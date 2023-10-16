local utils = require('dotnet.utils')
local queries = require("dotnet.queries")
local log = require('dotnet.log')

local M = {}

M.get_references = function (project_file_path)
	local fileContent = utils.readFile(project_file_path)

	local parser = vim.treesitter.get_string_parser(fileContent, "xml")
	if not parser then
		log.error("Could not create parser for " .. project_file_path)
		return
	end
	parser:parse()
	local tree = parser:trees()[1]
	if not tree then
		log.error("Could not load tree from parser for " .. project_file_path)
		return
	end
	local references = { names = {}, versions = {}}
	local resultQuery = vim.treesitter.query.parse("xml", queries.projectReferences)
	for id, node, _ in resultQuery:iter_captures(tree:root(), fileContent, 0, -1) do
		local name = resultQuery.captures[id]
		if name == "packageName" then
			local packageName = vim.treesitter.get_node_text(node, fileContent):sub(2,-2)
			table.insert(references.names, packageName)
		end
		if name == "packageVersion" then
			local packageVersion = vim.treesitter.get_node_text(node, fileContent):sub(2,-2)
			table.insert(references.versions, packageVersion)
		end
	end
	local ret = {}
	for key in pairs(references.names) do
		table.insert(ret, {
			name = references.names[key],
			version = references.versions[key]
		})
	end

	return ret;
end

M.is_test_project = function (project_file_path)
	return utils.find(M.get_references(project_file_path), function (reference)
		return reference.name == "Microsoft.NET.Test.Sdk"
	end) ~= nil
end

M.is_file_of_project = function(project, file_path)
		return file_path:find(project.path, 1, true) ~= nil
end


return M
