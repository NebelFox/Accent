-- ---------------------------------------
-- @Project: Progress Manager
--
-- @Date: December 1, 2020
-- @LastUpdate: December 1, 2020
--
-- @Version: 0.0.1a
--
-- @Author: NebelFox
-- ---------------------------------------

local M = {} -- module

local json = require "json"
local io, os, timer,  floor = io, os, timer, math.floor

local function average ( right, total )
	local result = total > 0 and floor ( ( right / total ) * 100 ) or 0
	return result
end

local weeklength = 604800	-- 60^3*24*7
local dayLen = 86400	-- 60^3*24
local updateFreq = 30000	-- 60*5*1000
local updateTimer

local path = system.pathForFile ( "progress.json", system.DocumentsDirectory )
local data = {}

function M.loadData ()
	data = json.decodeFile ( path )
	if data then
		data.globalAccuracy = average ( data.globalCorrect, data.globalCount )
		data.weekAccuracy = average ( data.weekCorrect, data.weekCount )
		M.weekCheck ()
	else
		M.setUpdatePoint ()
	end
	M.timerCall "start"
	local function system ( event )
		if event.type == "applicationSuspend" then
			M.saveData ()
			M.timerCall ( "pause" )
		elseif event.type == "applicationExit" then
			M.saveData ()
			M.timerCall ( "cancel" )
		elseif event.type == "applicationResume" then
			M.timerCall ( "resume" )
		end
	end
	Runtime:addEventListener ( "system", system )
end

function M.timerCall ( action ) -- way to controll time updating

	if action == "pause" then
		timer.pause ( updateTimer )

	elseif action == "cancel" then
		if updateTimer then
			timer.cancel ( updateTimer )
			updateTimer = nil
		end

	elseif action == "resume" then
		timer.resume ( updateTimer )

	elseif action == "start" then
		updateTimer = timer.performWithDelay ( updateFreq,
			function ()
				M.weekCheck ()
			end,
			0
		)
	end
end

function M.saveData ()
	local d = data
	local file = io.open ( path, "w" )
	if file then
		local wAcc, gAcc = d.weekAccuracy, d.globalAccuracy
		d.weekAccuracy, d.globalAccuracy = nil, nil
		file:write ( json.encode ( d ) )
		d.weekAccuracy, d.globalAccuracy = wAcc, gAcc
		io.close ( file )
	else
		error ( "The app failed to find a connected file" )
	end
	file = nil
end


function M.progress ( all, correct ) -- affecting to accuracy by new answers 

	local d = data
	d.globalCount = d.globalCount + all
	d.globalCorrect = d.globalCorrect + correct
	d.globalAccuracy = average ( d.globalCorrect, d.globalCount )
	d.weekCount = d.weekCount + all
	d.weekCorrect = d.weekCorrect + correct
	d.weekAccuracy = average ( d.weekCorrect, d.weekCount )
	M.saveData ()

end

function M.getProgress () -- returns all data values
	return data
end

function M.weekCheck ()

	local d = data

	local oldTime, curTime = d.lastUpdate, os.time ( os.date ( '*t' ) )
	local difference = os.difftime ( curTime, oldTime )
	if difference > weeklength then
		d.weekAccuracy = 0
		d.weekCount = 0
		d.weekCorrect = 0
		d.lastUpdate = oldTime + weeklength
		M.saveData ()
	end

end

function M.setUpdatePoint ()

	data = {
		weekCount = 0,
		weekCorrect = 0,
		globalCount = 0,
		globalCorrect = 0,
		weekAccuracy = 0,
		globalAccuracy = 0
	}

	local t = os.date ( '*t' )
	t.hour, t.min, t.sec = 0, nil, nil
	while t.wday ~= 2 do
		local temp = os.time ( t ) - dayLen
		t = os.date ( '*t', temp )
	end
	data.lastUpdate = os.time ( t )
	M.saveData ()

end

return M