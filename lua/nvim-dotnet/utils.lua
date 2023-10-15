
local M = {}


M.readFile = function(path)
	local fd = assert(vim.loop.fs_open(path, "r", 438))
	local stat = assert(vim.loop.fs_fstat(fd))
	local data, _, _ = assert(vim.loop.fs_read(fd, stat.size))
	assert(vim.loop.fs_close(fd))
	return data
end

M.string_split = function(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

M.find = function(tab, cb)
        for _, value in pairs(tab) do
            if(cb(value))then
                return value
            end
        end
end

M.where = function(tab, cb)
        local ret = {}
        for _, value in pairs(tab) do
                if(cb(value))then
                        table.insert(ret, value)
                end
        end
        return ret;
end



return M;
