
if vim.g.loaded_nvim_dotnet then
	return
end
vim.g.loaded_nvim_dotnet = true;


require('dotnet').setup()


-- vim.keymap.set("n", "<leader>rf", require('nvim-dotnet').parseFile, {desc = "Run File"})
--
