local M = {}	-- Module table

M.objects = {}		-- Table for all created objects
M.currentTheme = {}	-- Current widget's theme
M.group = nil		-- Group for all widgets

-- Localized global variables for better acces
local string, display, unpack, floor, ceil = string, display, unpack, math.floor, math.ceil

local x, y = display.contentCenterX, display.contentCenterY
local w, h = display.contentWidth, display.contentHeight

-- Initializing the module
-- ( background is created automaticaly )
function M:init ( group )
	self.group = display.newGroup ()
	self.font = native.newFont "assets/UbuntuMono-B.ttf"
	-- self.subFont = native.newFont "scene/lib/texgyrecursor-bold.otf"
	group:insert ( self.group )
	
	-- Implementing the background
	-- As it's created once a launch, it's no need to write a special function
	do
		local self = M
		local t = M.currentTheme
		local bg = display.newRect ( self.group, x, y, w, h )
		function bg:refresh ()
			t = M.currentTheme
			self:setFillColor ( unpack ( t.background ) )
		end
		bg:refresh ()
		bg:toBack ()
		bg.index = #self.objects + 1
		self.objects[bg.index] = bg
		function bg:delete ()
			display.delete ( bg )
			M.objects[self.index] = nil
		end
	end

	self.messagegroup = display.newGroup ()
	group:insert ( self.messagegroup )
	
	do
		local self = M
		local t = self.currentTheme
		local text = display.newText ( self.group, "", w - 5, h - 5, native.systemFont, 36 )
		text.text = "(c) 2020 NebelHund, @nebelhund.ich"
		text.anchorX, text.anchorY = 1, 1
		function text:refresh ()
			t = M.currentTheme
			self:setFillColor ( unpack ( t.textdefault ) )
		end
		transition.from ( text, { time = 1000, x = w * 2, delay = 200 } )
		text:refresh ()
		text.index = #self.objects + 1
		self.objects[text.index] = text
	end
end


-- Set for vowals with own seek in function
local vowals = {}
do
	local str = "ауеиіоюяєї"
	for i=1, string.len ( str ) - 1, 2 do
		local key = string.sub ( str, i, i + 1 )
		vowals[key] = true
	end
end
function vowals:contain ( v )
	return self[v] ~= nil
end

-- For setting theme for this module
function M:setTheme ( theme )
	self.currentTheme = theme
end

-- For refreshing all widgets with new theme
function M:refresh ()
	for _, obj in ipairs ( self.objects ) do
		obj:refresh ()
	end
end

-- The part of module for creating words
M.word = {
	fsize = 200,
	nsize = 76,
	offset = 16,
	x = x,
	y = y + 120,
	width = floor ( w * 0.95 )
}

-- The general function of this part to create a word
function M.word.new ( w )

	-- A few general locals to work with
	local self = M
	local config = self.word
	local t = self.currentTheme

	-- Building the object prototype
	local object = {}
	object.group = display.newGroup ()
	object.letters = {}

	local x = 0

	local word = w.word

	-- General information about received word
	local isDouble = w.isDouble
	local origAccent = w.accent
	local accent
	if isDouble then
		accent = {}
		for _, v in ipairs ( origAccent ) do
			accent[v] = true
		end
		function accent:contain ( v )
			return self[v] ~= nil
		end
	else accent = origAccent end

	local vowalCount = 0
	local width = config.width
	local fsize, nsize, font = config.fsize, config.nsize, self.font
	local answers = isDouble and 2 or 1	-- How much letters must the user choose

	-- Creating each letter
	for i=1, string.len ( word ) -1, 2 do

		local l = {}
		local letter = string.sub ( word, i, i + 1 )
		l.isVowal = vowals:contain ( letter )

		-- Graphical experience
		l.text = display.newText ( object.group, letter, x, 0, font, fsize )
		l.text.anchorX = 0
		object.letters[#object.letters + 1] = l
		-- print ( "!> creating the letter:", letter )
		object.group:insert ( l.text )
		x = x + l.text.width + config.offset

		function l:refresh ()
			l.currThemeName = t.themename
			local color = self.isVowal and ( self.isSelected and ( self.isAnswer and t.textright or t.textwrong ) or t.highlight ) or t.textdefault
			l.text:setFillColor ( unpack ( color ) )
		end

		if l.isVowal then
			vowalCount = vowalCount + 1
			l.isAnswer = isDouble and accent:contain ( vowalCount ) or accent == vowalCount

			l.rect = display.newRect ( object.group, l.text.x + l.text.width * 0.5, 0, l.text.width + config.offset, l.text.height * 1.2 )
			l.rect:setFillColor ( 0, 0, 0, 0 )
			l.rect.isHitTestable = true
			object.group:insert ( l.rect )

			function l.rect:touch ( event )
				if event.phase == "ended" then
					if l.rect.isHitTestable then
						if l.isAnswer then
							if not l.isSelected then
								answers = answers - 1
								l.isSelected = true
								l.text:setFillColor ( unpack ( t.textright ) )
							else
								l.isSelected = false
								answers = answers + 1
								l.text:setFillColor ( unpack ( t.highlight ) )
							end

							if answers == 0 then
								object:setState ( false )
								Runtime:dispatchEvent ( { name = "Vowal", right = true } )
							end
						else
							l.isSelected = true
							l.text:setFillColor ( unpack ( t.textwrong ) )
							l.timer = timer.performWithDelay ( 350, function ()
								object:reset ()
								l:refresh ()
							end, 1 )
							Runtime:dispatchEvent ( { name = "Vowal", right = false } )
						end
						return true
					end
				end
			end
			l.rect:addEventListener ( "touch" )

			function l:delete ()
				self.rect:removeEventListener ( "touch" )
				display.remove ( self.rect )
				display.remove ( self.text )
				self.rect, self.text = nil, nil
			end

		else
			function l:delete ()
				display.remove ( self.text )
				self.text = nil
			end
		end

	end

	-- Adding the notice if it exists
	-- Notice is a child object so it has own refresh method
	if w.notice then

		object.notice = display.newGroup ()
		self.group:insert ( object.notice )
		object.notice.x, object.notice.y = config.x, config.y - fsize * 0.8

		local notice = display.newText ( object.notice, w.notice, 0, 0, font, nsize )
		notice.anchorY = 1

		local width = notice.width * 0.4
		local y = notice.height + 5
		y = 5

		local line = display.newLine ( object.notice, -width, y, width, y )
		line.strokeWidth = 4

		function object.notice:refresh ()
			notice:setFillColor ( unpack ( t.highlight ) )
			line:setStrokeColor ( unpack ( t.highlight ) )
		end
		object.notice:refresh ()

		function object.notice:disappear ()
			display.remove ( object.notice )
			notice, line = nil, nil
			object.notice = nil
		end

	end

	-- For applying current color sceme to the whole word
	function object:refresh ()
		t = M.currentTheme
		for i=1, #self.letters do
			self.letters[i]:refresh ()
		end
		if self.notice then
			self.notice:refresh ()
		end
	end

	-- For safely deleting the whole word
	function object:delete ()
		display.remove ( self.group )
		self.group = nil
		for i=#self.letters, 1, -1 do
			self.letters[i]:delete ()
			if self.letters[i].timer then
				timer.cancel ( self.letters[i].timer )
			end
			self.letters[i] = nil
		end
		if self.notice then
			self.notice:disappear ()
		end
		M.objects[self.index] = nil
	end

	-- For returning to the starting version of word
	function object:reset ()
		answers = isDouble and 2 or 1
		for i=1, #self.letters do
			local l = self.letters[i]
			if l.isVowal then
				if l.isSelected then
					l.isSelected = false
				end
			end
		end
	end

	-- For enabling or disabling the word hit events
	function object:setState ( state )
		for i=1, #self.letters do
			local l = self.letters[i]
			if l.isVowal then
				self.letters[i].rect.isHitTestable = state
			end
		end
	end
		
	-- Dancing with the word group
	object.group.x, object.group.y = config.x, config.y
	-- object.group.anchorY = 1
	object.group.anchorChildren = true
	self.group:insert ( object.group )
	object.index = #self.objects + 1
	self.objects[object.index] = object

	-- Scaling the object to fit the boundaries of the screen
	local scale = ( width / object.group.contentWidth )
	if scale < 1 then
		scale = floor ( scale * 100 ) * 0.01
		object.group.xScale = scale
		object.group.yScale = scale
	end

	-- Applying the current color sceme to the object
	object:refresh ()

	object.letterEffect = 10
	object.effectTime = object.letterEffect * #object.letters

	function object:type ( toState )
		local delta = self.letterEffect
		local time = delta
		for i=1, #self.letters do
			local l = self.letters[i]
			l.text.isVisible = not toState
			timer.performWithDelay ( time, function ()
				l.text.isVisible = toState end, 1
			)
			time = time + delta
		end
	end

	function object:appear ()
		self:type ( true )
	end
	function object:disappear ()
		self:setState ( false )
		self:type ( false )
		timer.performWithDelay ( self.effectTime + 5, function () self:delete () end, 1 )
	end

	return object

end

function M.progressView ( data )

	local self = M
	local t = self.currentTheme

	local d = data

	local object = {}
	object.parts = {}
	local group = display.newGroup ()
	self.group:insert ( group )
	group.x, group.y = x, y - 150

	local function newLabel ( parent, text, value, y )
		local group = display.newGroup ()
		parent:insert ( group )
		group.y = y
		group.anchorChildren = true

		local label = display.newText ( group, text, 0, 0, native.systemFontBold, 45 )
		label.anchorX = 1

		local value = display.newText ( group, value, 0, 0, native.systemFontBold, 50 )
		value.anchorX = 0
		function group:refresh ()
			label:setFillColor ( unpack ( t.textdefault ) )
			value:setFillColor ( unpack ( t.highlight ) )
		end
		object.parts[#object.parts + 1] = group
		return group
	end

	local weekGroup = display.newGroup ()
	group:insert ( weekGroup )
	weekGroup.anchorChildren = true

	local week = display.newText ( weekGroup, "ЗА ТИЖДЕНЬ", 0, 0, native.systemFontBold, 50 )
	week:setFillColor ( unpack ( t.highlight ) )
	local weekAccuracy = newLabel ( weekGroup, "Точність: ", tostring ( d.weekAccuracy ) .. "%", week.height )
	local weekCorrect = newLabel ( weekGroup, "Правильних: ", d.weekCorrect, weekAccuracy.y + weekAccuracy.contentHeight )
	local weekTotal = newLabel ( weekGroup, "Всього: ", d.weekCount, weekCorrect.y + weekCorrect.contentHeight )

	weekGroup.anchorY = 1
	weekGroup.y = -20


	local globalGroup = display.newGroup ()
	group:insert ( globalGroup )
	globalGroup.anchorChildren = true

	local global = display.newText ( globalGroup, "ЗА ВЕСЬ ЧАС", 0, 0, native.systemFontBold, 50 )
	-- global:setFillColor ( unpack ( t.highlight ) )
	local gAccuracy = newLabel ( globalGroup, "Точність: ", tostring ( d.globalAccuracy ) .. "%", global.height )
	local gCorrect = newLabel ( globalGroup, "Правильних: ", d.globalCorrect, gAccuracy.y + gAccuracy.contentHeight )
	local gTotal = newLabel ( globalGroup, "Всього: ", d.globalCount, gCorrect.y + gCorrect.contentHeight )

	globalGroup.anchorY = 0
	globalGroup.y = 20

	transition.from ( weekGroup, { time = 700, delay = 200, yScale = 0.01, y = -200 } )
	transition.from ( globalGroup, { time = 700, delay = 200, yScale = 0.01, y = 200 } )

	function object:refresh ()
		t = M.currentTheme
		for i=1, #self.parts do
			self.parts[i]:refresh ()
			week:setFillColor ( unpack ( t.highlight ) )
			global:setFillColor ( unpack ( t.highlight ) )
		end
	end
	object:refresh ()

	function object:disappear ()
		transition.to ( globalGroup, { time = 700, yScale = 0.01, y = 200 } )
		transition.to ( weekGroup, { time = 700, yScale = 0.01, y = -200, onComplete = function ()
		for i=1, #self.parts do
			local p = self.parts[i]
			display.remove ( p )
			self.parts[i] = nil
		end
		display.remove ( globalGroup )
		display.remove ( weekGroup )
		display.remove ( group )
		globalGroup, weekGroup, group = nil, nil, nil end }
		)
	end

	return object

end

function M.button ( instance, movex, onTouch, _state )
	local self = M
	local t = self.currentTheme
	local onTouch = onTouch
	local isToggle = _state ~= nil
	local state = _state or false
	self.group:insert ( instance )
	function instance:touch ( event )
		if event.phase == "ended" then
			if isToggle then
				state = not state
				self:refresh ()
			end
			onTouch ()
		end
	end
	instance:addEventListener ( "touch" )

	if movex then
		local xFrom = instance.x > x and w + 128 or -128
		transition.from ( instance, { x = xFrom, time = 700, delay = 200 } )
	else
		transition.from ( instance, { y = -128, time = 700, delay = 200 } )
	end

	instance.index = #self.objects + 1
	self.objects[instance.index] = instance

	function instance:refresh ()
		t = M.currentTheme
		instance:setFillColor ( unpack ( state and t.highlight or t.textdefault ) )
	end
	instance:refresh ()

end


function M.toggleButton ( toTrain, toMenu )
	local self = M
	local t = self.currentTheme
	local object = {}
	local toTrain, toMenu = toTrain, toMenu
	local width = w * 0.65
	object.effectTime = 400
	local able = 1
	local group = display.newGroup ()
	local menu = true
	self.group:insert ( group )
	group.x = x
	group.y1 = y + 250
	group.y2 = y + 400
	group.y = h + 100
	group.xScale, group.yScale = 0.4, 0.4
	object.rect = display.newRoundedRect ( group, 0, 0, w * 0.68, 100, 50 )
	object.text = display.newText ( group, "Тренуватися", 0, 0, self.font, 80 )
	function object:refresh ()
		t = M.currentTheme
		self.rect:setFillColor ( unpack ( t.highlight ) )
		self.text:setFillColor ( unpack ( t.background ) )
	end

	function object:animate ( y, label, scale )
		self:disable ( "animation" )
		transition.to ( group, { time = 300, xScale = 0.6, yScale = 0.6 } )
		transition.to ( self.text, { time = 500, yScale = 0.01, onComplete = function ()
			self.text.text = label end }
		)
		transition.to ( self.text, { time = 500, delay = 500, yScale = 1 } )
		transition.to ( group, { time = 400, delay = 300, y = y } )
		transition.to ( group, { time = 300, delay = 700, xScale = scale, yScale = scale, onComplete = function ()
			self:enable ( "animation" ) end }
		)
	end

	function object:train ()
		self:animate ( group.y2, "Закінчити", 0.8 )
	end

	function object:menu ()
		self:animate ( group.y1, "Тренуватися", 1 )
	end

	object:refresh ()

	function object.rect:touch ( event )
		if event.phase == "ended" then
			if able == 0 then
				print ( able )
				if menu then
					object:train ()
					toTrain ()
				else
					object:menu ()
					toMenu ()
				end
				menu = not menu
			end
		end
	end

	function object:enable ( source )
		able = able - 1
	end
	function object:disable ( source )
		able = able + 1
	end

	object.rect:addEventListener ( "touch" )
	object.index = #self.objects + 1
	self.objects[object.index] = object

	transition.to ( group, { time = 800, delay = 200, xScale = 1, yScale = 1, y = group.y1,
		onComplete = function () object:enable ( "first_appear" ) end }
	)

	return object

end


function M.wordsCounter ()

	local self = M
	local t = self.currentTheme

	local object = {}
	local group = display.newGroup ()
	-- group.anchorChildren = true
	self.group:insert ( group )
	group.x = x
	group.y = y - 150	-- 300
	local part1 = display.newText ( group, "слів пройдено: ", 162, 0, self.font, 50 )
	part1.anchorX = 1
	local part2 = display.newText ( group, "0", 162, 0, self.font, 60 )
	part2.anchorX = 0

	transition.from ( part1, { x = -x, time = 600 } )
	transition.from ( part2, { x = x, time = 600 } )
	transition.to ( group, { y = y - 300, time = 350, delay = 600 } )

	local count = 0
	local edge = 1

	function object:refresh ()
		t = M.currentTheme
		part1:setFillColor ( unpack ( t.textdefault ) )
		part2:setFillColor ( unpack ( t.highlight ) )
	end
	object:refresh ()

	function object:disappear ()
		transition.to ( group, { y = y - 150, time = 350 } )
		transition.to ( part1, { time = 600, delay = 350, x = -x } )
		transition.to ( part2, { time = 600, delay = 350, x = x, onComplete = function ()
			display.remove ( group )
			part1, part2, group = nil, nil, nil
			M.objects[object.index] = nil end }
		)
	end

	function object:add ()
		count = count + 1
		if count == edge then

			local old = part2.text
			part2.text = tostring ( count )
			local dx = ( part1.width - part2.width ) * 0.5
			part2.text = old
			transition.to ( part1, { time = 300, x = dx } )
			transition.to ( part2, { time = 300, x = dx } )
			edge = edge * 10
		end

		transition.to ( part2, { time = 200, yScale = 0.001, onComplete = function () part2.text = tostring ( count ) end } )
		transition.to ( part2, { time = 200, delay = 200, yScale = 1 } )
		-- part2.text = tostring ( count )
	end
	-- object:add ()

	object.index = #self.objects + 1
	self.objects[object.index] = object

	return object

end


return M
