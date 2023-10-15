

local state = {}


state.command_group = vim.api.nvim_create_augroup("nvim-dotnet", { clear = true})
state.namespace = vim.api.nvim_create_namespace("nvim-dotnet")
state.working_directory = "/home/lukas/dev/src/neovim"
state.solution_file = nil
state.projects = {}




return state


