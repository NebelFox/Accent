local composer = require( "composer" )

local scene = composer.newScene()

-- built-in modules & functions
local json = require "json"
local rand = math.random

local mngpath = "packages."
local progress = require ( mngpath .. "progressmanager" )
local theme = require ( mngpath .. "thememanager" )
local settings = require ( mngpath .. "settingsmanager" )
local widgets = require "packages.widgets"

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local w, h = display.contentWidth, display.contentHeight
local x, y = display.contentCenterX, display.contentCenterY

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen
	local words = json.decodeFile ( system.pathForFile ( "data/wordlist_readable.json", system.ResourceDirectory ) )
	local wordsLen = #words
	print ( wordsLen )

	settings.loadData ()
	theme.loadData ()
	progress.loadData ()

	local whichTheme = settings.get ( "currentTheme" )

	widgets:setTheme ( theme.get ( whichTheme ) )
	widgets:init ( sceneGroup )

	local len = #words
	local index = len

	local word
	local progressView
	local toggleButton

	local isVibrationAllowed = settings.get ( "isVibrationAllowed" )

	local total = 0
	local right = 0

	local function shuffle ()
		for i=len, 1, -1 do
			local j = rand ( i )
			words[i], words[j] = words[j], words[i]
		end
	end

	local function randWord ()
		if index == len then
			shuffle ()
			index = 0
		end
		index = index + 1
		local word = words[index]
		return word
	end

	local function newWord ()
		local w = randWord ()
		word = widgets.word.new ( w )
		word:appear ()
		timer.performWithDelay ( word.effectTime + 10, function () toggleButton:enable ( "newWord_function" ) end, 1 )
	end

	local score
	local progressView

	local function check ( event )
		if event.right then
			right = right + 1
			timer.performWithDelay ( word.effectTime + 10, newWord, 1 )
			word:disappear ()
			toggleButton:disable ( "check_function" )
			score:add ()
		else
			if isVibrationAllowed then system.vibrate () end
		end
		total = total + 1
	end

	local function toTrain ()
		index = len
		toggleButton:disable ( "toTrain_function" )
		progressView:disappear ()
		score = widgets.wordsCounter ()
		timer.performWithDelay ( 600, newWord, 1 )
	end

	local function toMenu ()
		word:disappear ()
		score:disappear ()
		if total > 0 then
			progress.progress ( total, right )
		end
		total, right = 0, 0
		progressView = widgets.progressView ( progress.getProgress () )
	end


	toggleButton = widgets.toggleButton ( toTrain, toMenu )
	progressView = widgets.progressView ( progress.getProgress () )


	-- ----------------------------------------
	-- vibration functionality
	local function toggleVibrate ()
		isVibrationAllowed = not isVibrationAllowed
		settings.set ( "isVibrationAllowed", isVibrationAllowed )
	end

	local vibrateRect = display.newImageRect ( "assets/vibration.png", 128, 128 )
	vibrateRect:translate ( 110, 110 )
	widgets.button ( vibrateRect, true, toggleVibrate, isVibrationAllowed )

	-- -----------------------------------------
	-- theme changing functionality
	local themeRect = display.newImageRect ( "assets/theme.png", 128, 128 )
	themeRect:translate ( w - 110, 110 )
	widgets.button ( themeRect, false, function ()
		whichTheme = whichTheme == 1 and 2 or 1
		widgets:setTheme ( theme.get ( whichTheme ) )
		widgets:refresh ()
		settings.set ( "currentTheme", whichTheme )
	end )

	Runtime:addEventListener ( "Vowal", check )

	-- newWord ()
	local function onSystem( event )
		local t = event.type
		if t == "applicationExit" or t == "applicationSuspend" then
			settings.saveData ()
		end
	end
	Runtime:addEventListener ( "system", onSystem )

	-- widgets.progressView.new ()

end

-- There is no need of scene show|hide|destroy callbacks

-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
-- -----------------------------------------------------------------------------------

return scene
