local M = {}

local io, system = io, system

local path = system.pathForFile ( "settings.json", system.DocumentsDirectory )
local data = {}
local json = require "json"
local needToSave = false

function M.loadData ()
	data = json.decodeFile ( path )
	if not data then
		data = {
			isVibrationAllowed = false,
			currentTheme = 1
		}
		needToSave = true
		M.saveData ()
	end
end

function M.saveData ()
	if needToSave then
		local file = io.open ( path, "w" )
		if file then
			file:write ( json.encode ( data ) )
			io.close ( file )
		end
		file = nil
		needToSave = false
	end
end

function M.get ( name )
	return data[name]
end

function M.set ( name, value )
	data[name] = value
	needToSave = true
end

return M