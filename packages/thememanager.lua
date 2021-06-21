local M = {}
local io, sub, tonumber, pairs, ipairs, system = io, string.sub, tonumber, pairs, ipairs, system

local path	= system.pathForFile ( "data/themes.json", system.ResourceDirectory )
local data	= {}
local json	= require "json"

local function hex2rgb ( hex )
	local function p ( a )
		return tonumber ( "0x" .. sub ( hex, a, a + 1 ) ) / 255
	end
	return { p ( 1 ), p ( 3 ), p ( 5 ) }
end

function M.loadData ()
	data = json.decodeFile ( path )
	for _, t in ipairs ( data ) do
		for k, v in pairs ( t ) do
			t[k] = hex2rgb ( v )
		end
	end
end

function M.get ( index )
	return data[index]
end

return M