local composer = require "composer"

local scene = composer.newScene()

-- built-in modules & functions
local json = require "json"
local rand = math.random

local packagesPath = "packages."
local progress = require ( packagesPath .. "progressmanager" )
local theme    = require ( packagesPath .. "thememanager" )
local settings = require ( packagesPath .. "settingsmanager" )
local widgets  = require ( packagesPath .. "widgets" )

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
	local words = json.decodeFile ( system.pathForFile ( "data/wordlist.json", system.ResourceDirectory ) )
	local wordsCount = #words
	local currentWordIndex = wordsCount

	settings.loadData ()
	theme.loadData ()
	progress.loadData ()

	local currentThemeIndex = settings.get ( "currentTheme" )

	widgets:setTheme ( theme.get ( currentThemeIndex ) )
	widgets:init ( sceneGroup )


	local word
	local progressView
	local toggleButton
	local score
	local progressView

	local isVibrationAllowed = settings.get ( "isVibrationAllowed" )

	local totalAnswersCount = 0
	local correctAnswersCount = 0

	local function shuffle ()
		for i=wordsCount, 1, -1 do
			local j = rand ( i )
			words[i], words[j] = words[j], words[i]
		end
	end

	local function getNextWord ()
		if currentWordIndex == wordsCount then
			shuffle ()
			currentWordIndex = 0
		end
		currentWordIndex = currentWordIndex + 1
		local word = words[currentWordIndex]
		return word
	end

	local function nextWord ()
		local w = getNextWord ()
		word = widgets.word.new ( w )
		word:appear ()
		timer.performWithDelay ( word.effectTime + 10, function () toggleButton:enable ( "newWord_function" ) end, 1 )
	end

	local function check ( event )
		if event.correct then
			correctAnswersCount = correctAnswersCount + 1
			timer.performWithDelay ( word.effectTime + 10, nextWord, 1 )
			word:disappear ()
			toggleButton:disable ( "check_function" )
			score:add ()
		else
			if isVibrationAllowed then system.vibrate () end
		end
		totalAnswersCount = totalAnswersCount + 1
	end

	local function toTrain ()
		currentWordIndex = wordsCount
		toggleButton:disable ( "toTrain_function" )
		progressView:disappear ()
		score = widgets.wordsCounter ()
		timer.performWithDelay ( 600, nextWord, 1 )
	end

	local function toMenu ()
		word:disappear ()
		score:disappear ()
		if totalAnswersCount > 0 then
			progress.progress ( totalAnswersCount, correctAnswersCount )
		end
		totalAnswersCount, rightAnswersCount = 0, 0
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
	local themeIcon = display.newImageRect ( "assets/theme.png", 128, 128 )
	themeIcon:translate ( w - 110, 110 )
	widgets.button ( themeIcon, false, function ()
		currentThemeIndex = currentThemeIndex == 1 and 2 or 1
		widgets:setTheme ( theme.get ( currentThemeIndex ) )
		widgets:refresh ()
		settings.set ( "currentTheme", currentThemeIndex )
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
