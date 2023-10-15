local log = require('nvim-dotnet.log')
local queries = require('nvim-dotnet.queries')

local M = {}

local method_get_params = function(method_node)
	local line = method_node:start()
	local end_line = method_node:end_()
	local bufNr = vim.api.nvim_get_current_buf()
	local query = vim.treesitter.query.parse("c_sharp", queries.method_parameters)
	local params = {}
	for id, node in query:iter_captures(method_node, bufNr, line, end_line) do
		local name = query.captures[id]
		if(name == "name") then
			local param_name = vim.treesitter.get_node_text(node, bufNr, nil)
			table.insert(params, param_name)
		end
	end
	return params
end

local method_get_return_type = function(method_node)
	local line = method_node:start()
	local end_line = method_node:end_()
	local bufNr = vim.api.nvim_get_current_buf()
	local query = vim.treesitter.query.parse("c_sharp", queries.method_return_type)
	for id, node in query:iter_captures(method_node, bufNr, line, end_line) do
		local name = query.captures[id]
		if(name == "return_type") then
			return vim.treesitter.get_node_text(node, bufNr, nil)
		end
	end
	return nil
end

local method_commenting = function(method_node)
	local line, col = method_node:start()
	local bufNr = vim.api.nvim_get_current_buf()
	local params = method_get_params(method_node)
	local return_type = method_get_return_type(method_node)
	local summary = vim.fn.input("Summary of method functionality: ")
	local descs = {}
	for _, v in pairs(params) do
		local param_desc = vim.fn.input("Description for " .. v .. ": ")
		table.insert(descs, param_desc)
	end

	local lines = {}
	local intend = string.rep(" ", col) .. "/// "
	table.insert(lines, intend .. "<summary>")
	table.insert(lines, intend .. summary)
	table.insert(lines, intend .. "</summary>")
	for idx, v in pairs(descs) do
		table.insert(lines, intend .. "<param name=\"" .. params[idx] .. "\">" .. v .. "</param>")
	end
	if return_type ~= "void" then
		local return_value_description = vim.fn.input("Description of return value: ")
		table.insert(lines, intend .. "<returns>" .. return_value_description .. "</returns>")
	end
	vim.api.nvim_buf_set_lines(bufNr, line, line, false, lines)
end

local class_commenting = function(node)
	local bufNr = vim.api.nvim_get_current_buf()
	vim.ui.input({ prompt = "Summary of class functionality: "}, function(input)
		local lines = {}
		local line, col = node:start()
		table.insert(lines, string.rep(" ", col) .. "/// <summary>")
		table.insert(lines, string.rep(" ", col) .. "/// " .. input)
		table.insert(lines, string.rep(" ", col) .. "/// </summary>")
		vim.api.nvim_buf_set_lines(bufNr, line, line, false, lines)
	end)
end

M.comment = function()
	local node = vim.treesitter.get_node()
	while node do
		if node:type() == "method_declaration" then
			method_commenting(node)
			return
		end
		if node:type() == "class_declaration" then
			class_commenting(node)
			return
		end
		node = node:parent()
	end
end

return M
