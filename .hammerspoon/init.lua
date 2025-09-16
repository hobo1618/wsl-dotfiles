-- ========= Leader: Cmd+; → F18 via Karabiner =========
local leaderKey = "f18" -- Karabiner maps Cmd+; to F18
local leaderTimeout = 1.2 -- seconds
local subTimeout = 1.5

-- Hardcode BANK_DIR so GUI env can't mess it up
local BANK_DIR = "/Users/will/Documents/askerra/content/bank"

-- Runner helpers -------------------------------------------------------------
local function run_bash(cmd, onExit)
	hs.task
		.new("/bin/bash", function(exitCode, _, _)
			if onExit then
				onExit(exitCode)
			end
		end, { "-lc", cmd })
		:start()
end

local function shot_to(target)
	-- Use BANK_DIR explicitly so ~/bin/shot sees it
	local cmd = string.format("BANK_DIR=%q ~/bin/shot %s", BANK_DIR, target)
	run_bash(cmd)
end

local function clipboard_only()
	-- One interactive selection to clipboard only (no file)
	run_bash("screencapture -ci")
end

-- UI helpers ----------------------------------------------------------------
local function hint(txt)
	hs.alert.show(txt, { radius = 8 }, 0.7)
end

-- Leader modal (1st key) ----------------------------------------------------
local leader = hs.hotkey.modal.new()
local leaderTimer

local function leaderEnter()
	leader:enter()
	hint("leader: s = screenshot")
	if leaderTimer then
		leaderTimer:stop()
	end
	leaderTimer = hs.timer.doAfter(leaderTimeout, function()
		leader:exit()
	end)
end

hs.hotkey.bind({}, leaderKey, leaderEnter)
leader:bind({}, "escape", function()
	leader:exit()
end)

-- Screenshot submodal (2nd key) --------------------------------------------
local shotModal = hs.hotkey.modal.new()
local shotTimer

local function shotEnter()
	shotModal:enter()
	hint("screenshot: c=clipboard  b=bank  p=pictures")
	if shotTimer then
		shotTimer:stop()
	end
	shotTimer = hs.timer.doAfter(subTimeout, function()
		shotModal:exit()
	end)
end

leader:bind({}, "s", function()
	leader:exit()
	shotEnter()
end)

shotModal:bind({}, "escape", function()
	shotModal:exit()
end)

-- sc: clipboard only
shotModal:bind({}, "c", function()
	shotModal:exit()
	hs.task.new("/bin/bash", nil, { "-lc", [[ ~/bin/shot clip ]] }):start()
end)

-- sb: BANK + clipboard
shotModal:bind({}, "b", function()
	shotModal:exit()
	local cmd = string.format([[ BANK_DIR=%q ~/bin/shot bank ]], BANK_DIR)
	hs.task.new("/bin/bash", nil, { "-lc", cmd }):start()
end)

-- sp: Pictures + clipboard
shotModal:bind({}, "p", function()
	shotModal:exit()
	hs.task.new("/bin/bash", nil, { "-lc", [[ ~/bin/shot pictures ]] }):start()
end)

-- Ready message
hs.alert.show("Hammerspoon reloaded", { radius = 8 }, 0.5)
