-- ========= Leader: Cmd+; → F18 via Karabiner =========
local leaderKey = "f18" -- Karabiner maps Cmd+; to F18
local leaderTimeout = 1.2 -- seconds
local subTimeout = 1.5

local log = hs.logger.new("shot", "info")

local function trim(str)
	return (str or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function envVar(name)
	if hs and hs.processInfo and hs.processInfo.environment then
		local value = hs.processInfo.environment[name]
		if value and value ~= "" then
			return value
		end
	end

	local value = os.getenv(name)
	if value and value ~= "" then
		return value
	end

	return nil
end

local function resolveBankDir()
	local env = envVar("BANK_DIR")
	if env then
		return env
	end

	local shellCmd = [[/bin/zsh -lc 'printf %s "${BANK_DIR:-}"']]
	local output, ok, _, rc = hs.execute(shellCmd, true)
	if ok and rc == 0 then
		local value = trim(output)
		if value ~= "" then
			return value
		end
	end

	return "/Users/willhobden/Documents/askerra/content/bank"
end

local function ensureDir(path)
	if not path or path == "" then
		return
	end

	if hs.fs.attributes(path) then
		return
	end

	local ok, err = hs.fs.mkdir(path)
	if not ok then
		log.e(string.format("shot: mkdir failed for %s (%s)", path, err or "unknown error"))
	end
end

local HOME = envVar("HOME") or "~"
local BANK_DIR = resolveBankDir()
local BANK_IMAGES_DIR = string.format("%s/images", BANK_DIR)
local BANK_TO_CLEAN_DIR = string.format("%s/to-clean", BANK_IMAGES_DIR)
local PROJECTS_DIR = string.format("%s/Documents/askerra/content/projects", HOME)
local PICTURES_DIR = string.format("%s/Pictures/screenshots", HOME)

ensureDir(BANK_DIR)
ensureDir(BANK_IMAGES_DIR)
ensureDir(BANK_TO_CLEAN_DIR)
ensureDir(PROJECTS_DIR)
ensureDir(PICTURES_DIR)

-- Runner helpers -------------------------------------------------------------
local activeTasks = {}

local function run_bash(cmd, onExit)
	local task
	task = hs.task.new("/bin/bash", function(exitCode, _, _)
		activeTasks[task] = nil
		if onExit then
			onExit(exitCode)
		end
	end, { "-lc", cmd })

	if not task then
		log.e("shot: failed to create task")
		return
	end

	activeTasks[task] = true -- keep the task alive until screencapture finishes
	if not task:start() then
		activeTasks[task] = nil
		log.e("shot: failed to start task")
	end
end

local function shot_to(target, dest)
	if target == "bank" then
		ensureDir(BANK_DIR)
		ensureDir(BANK_IMAGES_DIR)
	elseif target == "pictures" then
		ensureDir(PICTURES_DIR)
	elseif target == "to" and dest and dest ~= "" then
		ensureDir(dest)
	end

	local cmd
	if target == "to" and dest and dest ~= "" then
		cmd = string.format([[ BANK_DIR=%q ~/bin/shot to %q ]], BANK_DIR, dest)
	else
		cmd = string.format([[ BANK_DIR=%q ~/bin/shot %s ]], BANK_DIR, target)
	end

	run_bash(cmd)
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
local bankModal = hs.hotkey.modal.new()
local shotTimer
local bankTimer

local function shotEnter()
	shotModal:enter()
	hint("screenshot: c=clipboard  b=bank…  p=pictures  v=projects")
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
	shot_to("clip")
end)

-- sb: BANK + clipboard
shotModal:bind({}, "b", function()
	shotModal:exit()
	bankModal:enter()
	hint("bank: b=default  g=images/to-clean")
	if bankTimer then
		bankTimer:stop()
		bankTimer = nil
	end
	bankTimer = hs.timer.doAfter(subTimeout, function()
		bankTimer = nil
		bankModal:exit()
	end)
end)

bankModal:bind({}, "escape", function()
	if bankTimer then
		bankTimer:stop()
		bankTimer = nil
	end
	bankModal:exit()
end)

bankModal:bind({}, "b", function()
	if bankTimer then
		bankTimer:stop()
		bankTimer = nil
	end
	bankModal:exit()
	shot_to("bank")
end)

bankModal:bind({}, "g", function()
	if bankTimer then
		bankTimer:stop()
		bankTimer = nil
	end
	bankModal:exit()
	shot_to("to", BANK_TO_CLEAN_DIR)
end)

-- sp: Pictures + clipboard
shotModal:bind({}, "p", function()
	shotModal:exit()
	shot_to("pictures")
end)

-- sv: Projects + clipboard
shotModal:bind({}, "v", function()
	shotModal:exit()
	shot_to("to", PROJECTS_DIR)
end)

-- Ready message
hs.alert.show("Hammerspoon reloaded", { radius = 8 }, 0.5)
