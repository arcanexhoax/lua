script_name('PoliceHelper')
script_version("1.2.0")

local sampev = require 'lib.samp.events'
local keys = require 'vkeys'
local imgui = require 'imgui'
local encoding = require 'encoding'
require "lib.moonloader"

encoding.default = 'CP1251'
u8 = encoding.UTF8

-- binds variables
temp1 = nil
temp2 = nil

-- iterator
iter = 0

-- gun
gun = {}
sniper = false

-- color for messages
phcolor = 0x7129ff
col = "{7129ff}"

-- variables for events
sc = false -- /m and /s
az = false -- autoz
ad = false -- autodet
tg = false -- take gun
pos = 0 -- afind
isact = false -- is player being found
suspectid = nil -- afind, player
accessory = true -- are accessories put on
cid = nil -- criminal id
isSuMenuOpen = false -- is menu with criminal code articles open
isPlayerFrozen= false -- is player being frozen by taser

-- main color
r = 0.2
g = 0.15
b = 1
a = 0.8
-- active colors
ra = 0.25
ga = 0
ba = 1
aa = 0.8
-- hover colors
rh = 0.2
gh = 0.3
bh = 1
ah = 0.8

-- textbox lengh
len = 545
len2 = 235

-- tabs
commands = true
binds = false
other = false
config = false

-- time
tzone = nil

if not doesDirectoryExist(getWorkingDirectory().."/config/PoliceHelper/") then
	createDirectory(getWorkingDirectory().."/config/PoliceHelper/")
end

if not doesFileExist(getWorkingDirectory().."/config/PoliceHelper/PH.ini") then
	file = io.open(getWorkingDirectory().."/config/PoliceHelper/PH.ini", "w")
	file:write("[binds]\naskCarDoc1=\naskDoc2=\ngetOutOfVeh2=\ngetOutOfVeh1=\naskCarDoc2=\nbye2=\nstopVeh2=\naskDoc1=\nbye1=\nstopVeh1=\n" ..
		"[config]\naskPlayers=true\naskGang=true\nshowPts=true\ncuffAfterTaser=false\ntakeGuns=true\nfriskPlayer=true\nchaseAfterSu=true\naskNovices=true\n" .. 
		"askPolice=true\nfriskCar=true\ndontAskWithoutDuty=true\ndontFriskWithoutDuty=true\ndontAskWhenSunday=true")
	file:flush()
	file:close()
end

if not doesFileExist(getWorkingDirectory().."/config/PoliceHelper/IgnoredPlayers.txt") then
	file = io.open(getWorkingDirectory().."/config/PoliceHelper/IgnoredPlayers.txt", "a")
	file:close()
end

local inicfg = require 'inicfg'
local dirIni = "moonloader\\config\\PoliceHelper\\PH.ini"
local loadIni = inicfg.load(nil, dirIni)
local saveIni = inicfg.save(loadIni, dirIni)

-- binds
askDoc = {
	imgui.ImBuffer(loadIni.binds.askDoc1, 256),
	imgui.ImBuffer(loadIni.binds.askDoc2, 256)
}
askCarDoc = {
	imgui.ImBuffer(loadIni.binds.askCarDoc1, 256),
	imgui.ImBuffer(loadIni.binds.askCarDoc2, 256)
}
getOutOfVeh = {
	imgui.ImBuffer(loadIni.binds.getOutOfVeh1, 256),
	imgui.ImBuffer(loadIni.binds.getOutOfVeh2, 256)
}
stopVeh = {
	imgui.ImBuffer(loadIni.binds.stopVeh1, 256),
 	imgui.ImBuffer(loadIni.binds.stopVeh2, 256)
}
bye = {
	imgui.ImBuffer(loadIni.binds.bye1, 256),
	imgui.ImBuffer(loadIni.binds.bye2, 256)
}
ignoredArray = {}

-- config
showPts = imgui.ImBool(false)
askNovices = imgui.ImBool(false)
askGang = imgui.ImBool(false)
askPolice = imgui.ImBool(false)
askPlayers = imgui.ImBool(false)
friskPlayer = imgui.ImBool(false)
friskCar = imgui.ImBool(false)
cuffAfterTaser = imgui.ImBool(false)
takeGuns = imgui.ImBool(false)
dontAskWithoutDuty = imgui.ImBool(false)
dontFriskWithoutDuty = imgui.ImBool(false)
dontAskWhenSunday = imgui.ImBool(false)
chaseAfterSu = imgui.ImBool(false)

-- ignored player list
ignoredPlayers = imgui.ImBuffer(9999)

local mainWindowState = imgui.ImBool(false)

function styles()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	style.FrameRounding = 3
	style.ChildWindowRounding = 10
	style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
	style.WindowPadding = imgui.ImVec2(15, 15)
	colors[clr.WindowBg] = ImVec4(0, 0, 0, 0.97)
	colors[clr.Button] = ImVec4(r, g, b, a)
	colors[clr.ButtonHovered] = ImVec4(rh, gh, bh, ah)
	colors[clr.ButtonActive] = ImVec4(ra, ga, ba, aa)
	colors[clr.TitleBgActive] = ImVec4(r, g, b, a + 0.17)
	colors[clr.Header] = ImVec4(r, g, b, a)
	colors[clr.HeaderActive] = ImVec4(ra, ga, ba, aa)
	colors[clr.HeaderHovered] = ImVec4(rh, gh, bh, ah)
	colors[clr.ScrollbarGrab] = ImVec4(r, g, b, a)
	colors[clr.ScrollbarGrabActive] = ImVec4(ra, ga, ba, aa)
	colors[clr.ScrollbarGrabHovered] = ImVec4(rh, gh, bh, ah)
	colors[clr.CheckMark] = ImVec4(0.4, 0.4, 1, 1)
	colors[clr.FrameBg] = ImVec4(r, g, b, 0.1)
	colors[clr.FrameBgHovered] = ImVec4(rh, gh, bh, 0.4)
	colors[clr.FrameBgActive] = ImVec4(ra, ga, ba, 0.4)
end

styles()

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(0) end
	
	autoupdate("https://raw.githubusercontent.com/arcanexhoax/lua/master/PoliceHelper.json")

	sampAddChatMessage(col .. "PoliceHelperNew {ffffff}çàïóùåí. Ìåíþ: " .. col .. "/pmenu{ffffff}. Àâòîð " .. col .. "_jumbo_{ffffff}.", phcolor)

	thread1 = lua_thread.create_suspended(thread)
	
	tzone = tonumber(string.format("%+.2d%.2d", math.modf((timezone or os.offset()) / 3600)):match("[+-]%d+")) / 100

	sampRegisterChatCommand("pmenu", menu)
	sampRegisterChatCommand("sh", askDocuments)
	sampRegisterChatCommand("pt", askCarDocuments)
	sampRegisterChatCommand("gv", getPlayerOutOfVeh)
	sampRegisterChatCommand("st", stopPlayerVeh)
	sampRegisterChatCommand("by", byePlayer)
	sampRegisterChatCommand("fr", frisk)
	sampRegisterChatCommand("cu", cuffPlayer)
	sampRegisterChatCommand("un", unCuffPlayer)
	sampRegisterChatCommand("zp", chasePlayer)
	sampRegisterChatCommand('auz', autoZ)
	sampRegisterChatCommand('aud', autoDet)
	sampRegisterChatCommand('afind', autoFind)

	showPts = imgui.ImBool(toBool(loadIni.config.showPts))
	askNovices = imgui.ImBool(toBool(loadIni.config.askNovices))
	askGang = imgui.ImBool(toBool(loadIni.config.askGang))
	askPolice = imgui.ImBool(toBool(loadIni.config.askPolice))
	askPlayers = imgui.ImBool(toBool(loadIni.config.askPlayers))
	friskPlayer = imgui.ImBool(toBool(loadIni.config.friskPlayer))
	friskCar = imgui.ImBool(toBool(loadIni.config.friskCar))
	cuffAfterTaser = imgui.ImBool(toBool(loadIni.config.cuffAfterTaser))
	takeGuns = imgui.ImBool(toBool(loadIni.config.takeGuns))
	dontAskWithoutDuty = imgui.ImBool(toBool(loadIni.config.dontAskWithoutDuty))
	dontFriskWithoutDuty = imgui.ImBool(toBool(loadIni.config.dontFriskWithoutDuty))
	dontAskWhenSunday = imgui.ImBool(toBool(loadIni.config.dontAskWhenSunday))
	chaseAfterSu = imgui.ImBool(toBool(loadIni.config.chaseAfterSu))

	i = 1

	for nick in io.lines("moonloader/config/PoliceHelper/IgnoredPlayers.txt") do
  		ignoredPlayers.v = ignoredPlayers.v .. nick .. '\n'
		ignoredArray[i] = imgui.ImBuffer(nick, 256)
		i = i + 1
	end

	imgui.Process = false

	while true do
		wait(0)

		if isKeyJustPressed(53) then
			autoZ()
		end

		local valid, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)

	    if valid and doesCharExist(ped) then
			local result, id = sampGetPlayerIdByCharHandle(ped)

			if result then
				if isKeyJustPressed(49) or isKeyJustPressed(VK_Q) then
					askDocuments(id)
				end
				if isKeyJustPressed(50) then
					askCarDocuments(id)
				end
				if isKeyJustPressed(51) then
					byePlayer(id)
				end
				if isKeyJustPressed(52) or isKeyJustPressed(VK_E) then
					frisk(id)
				end
				if isKeyJustPressed(53) or isKeyJustPressed(VK_X) then
					cuffPlayer(id)
				end
				if isKeyJustPressed(54) or isKeyJustPressed(VK_U) then
					unCuffPlayer(id)
				end
				if isKeyJustPressed(55) then
					chasePlayer(id)
				end
			end
	    end

		if mainWindowState.v then
			loadIni.binds.askDoc1 = askDoc[1].v
			loadIni.binds.askDoc2 = askDoc[2].v
			loadIni.binds.askCarDoc1 = askCarDoc[1].v
			loadIni.binds.askCarDoc2 = askCarDoc[2].v
			loadIni.binds.getOutOfVeh1 = getOutOfVeh[1].v
			loadIni.binds.getOutOfVeh2 = getOutOfVeh[2].v
			loadIni.binds.stopVeh1 = stopVeh[1].v
			loadIni.binds.stopVeh2 = stopVeh[2].v
			loadIni.binds.bye1 = bye[1].v
			loadIni.binds.bye2 = bye[2].v

			loadIni.config.showPts = showPts.v
			loadIni.config.askNovices = askNovices.v
			loadIni.config.askGang = askGang.v
			loadIni.config.askPolice = askPolice.v
			loadIni.config.askPlayers = askPlayers.v
			loadIni.config.friskPlayer = friskPlayer.v
			loadIni.config.friskCar = friskCar.v
			loadIni.config.cuffAfterTaser = cuffAfterTaser.v
			loadIni.config.takeGuns = takeGuns.v
			loadIni.config.dontAskWithoutDuty = dontAskWithoutDuty.v
			loadIni.config.dontFriskWithoutDuty = dontFriskWithoutDuty.v
			loadIni.config.dontAskWhenSunday = dontAskWhenSunday.v
			loadIni.config.chaseAfterSu = chaseAfterSu.v

			inicfg.save(loadIni, dirIni)
		end

		if tg and takeGuns.v then
			if not sampIsDialogActive() and iter == 3 and gun[3] then
				for i = 1, #gun do
					if gun[i] then
						sampSendChat("/take " .. gun[i])
						gun[i] = nil
					end
				end

				tg = false
				iter = 0
			end
		end

		if (isCurrentCharWeapon(PLAYER_PED, 34) or isCurrentCharWeapon(PLAYER_PED, 35)) and isKeyDown(2) and not isCharInAir(PLAYER_PED) and
				not isCharInAnyCar(PLAYER_PED) and not isCharInWater(PLAYER_PED) and (sampGetPlayerAnimationId(getMyId()) == 1167 or 
				sampGetPlayerAnimationId(getMyId()) == 1365 or (sampGetPlayerAnimationId(getMyId()) >= 1158 and sampGetPlayerAnimationId(getMyId()) <= 1163)) then 
			if not sniper and accessory then
				sampSendChat("/head") 
				sniper = true
				accessory = false
			end
		else
			sniper = false

			if not isCurrentCharWeapon(PLAYER_PED, 34) and not accessory then
				accessory = true
				sampSendChat("/helmet")
				sampSendChat("/glass")
				sampSendChat("/mask")
			end
		end

		if not mainWindowState.v then
			imgui.Process = false
		end
	end
end

function menu(args)
	mainWindowState.v = not mainWindowState.v
	imgui.Process = mainWindowState.v
end

function imgui.OnDrawFrame()
	local sw, sh = getScreenResolution()
	imgui.LockPlayer = true
	imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(760, 520), imgui.Cond.FirstUseEver)
	imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(0, 0, 0, a - 0.4))
	imgui.Begin("\tPoliceHelper", mainWindowState, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
		if imgui.Button(u8'Êîìàíäû', imgui.ImVec2(100,30)) then
			commands = true
			binds = false
			other = false
			config = false
		end
		imgui.SameLine()
		if imgui.Button(u8'Äðóãîå', imgui.ImVec2(100,30)) then
			commands = false
			binds = false
			other = true
			config = false
		end
		imgui.SameLine()
		if imgui.Button(u8'Áèíäû', imgui.ImVec2(100,30)) then
			commands = false
			binds = true
			other = false
			config = false
		end
		imgui.SameLine()
		if imgui.Button(u8'Íàñòðîéêè', imgui.ImVec2(100,30)) then
			commands = false
			binds = false
			other = false
			config = true
		end
		imgui.Text("")
		imgui.BeginChild("main", imgui.ImVec2(730,420), true)
			if commands then
				if imgui.Button(u8"/sh") then
					askDocuments(nil)
				end

				imgui.SameLine()
				imgui.Text(u8" -   Ñïðîñèòü äîêóìåíòû ó áëèæàéøåãî èãðîêà")
				imgui.Spacing()

				if imgui.Button(u8"/pt") then
					askCarDocuments(nil)
				end

				imgui.SameLine()
				imgui.Text(u8" -   Ñïðîñèòü äîêóìåíòû íà ò/ñ")
				imgui.Spacing()

				if imgui.Button(u8"/gv") then
					getPlayerOutOfVeh(nil)
				end

				imgui.SameLine()
				imgui.Text(u8" -   Ïîïðîñèòü áëèæàéøåãî èãðîêà ïîêèíóòü ò/ñ")
				imgui.Spacing()

				if imgui.Button(u8"/st") then
					stopPlayerVeh(nil)
				end

				imgui.SameLine()
				imgui.Text(u8" -   Ïîïðîñèòü áëèæàéøåãî èãðîêà îñòàíîâèòü ò/ñ")
				imgui.Spacing()

				if imgui.Button(u8"/by") then
					byePlayer(nil)
				end

				imgui.SameLine()
				imgui.Text(u8" -   Ïîïðîùàòüñÿ ñ èãðîêîì")
				imgui.Spacing()

				if imgui.Button(u8"/fr") then
					frisk(nil)
				end

				imgui.SameLine()
				imgui.Text(u8" -   Îáûñêàòü áëèæàéøåãî èãðîêà")
				imgui.Spacing()

				if imgui.Button(u8"/cu") then
					cuffPlayer(nil)
				end

				imgui.SameLine()
				imgui.Text(u8" -   Íàäåòü íàðó÷íèêè íà áëèæàéøåãî èãðîêà")
				imgui.Spacing()

				if imgui.Button(u8"/un") then
					unCuffPlayer(nil)
				end

				imgui.SameLine()
				imgui.Text(u8" -   Ñíÿòü íàðó÷íèêè ñ áëèæàéøåãî èãðîêà")
				imgui.Spacing()

				if imgui.Button(u8"/zp") then
					chasePlayer(nil)
				end

				imgui.SameLine()
				imgui.Text(u8" -   Íà÷àòü ïðåñëåäîâàíèå áëèæàéøåãî èãðîêà")
				imgui.Spacing()

				if imgui.Button(u8"/auz") then
					autoZ()
				end

				imgui.SameLine()
				imgui.Text(u8" -   Íà÷àòü ïðåñëåäîâàíèå âñåõ èãðîêîâ èç /wanted â ðàäèóñå 25ì")
				imgui.Spacing()

				if imgui.Button(u8"/aud") then
					autoDet()
				end

				imgui.SameLine()
				imgui.Text(u8" -   Íà÷àòü êîíâîèðîâàíèå âñåõ èãðîêîâ èç /wanted, êîòîðûå ñäàëèñü â ðàäèóñå 25ì")
				imgui.Spacing()

				imgui.Button(u8"/afind")
				imgui.SameLine()
				imgui.Text(u8" -   Àâòîìàòè÷åñêèé ïîèñê èãðîêà. Àêòèâàöèÿ: /afind [ID]. Äåàêòèâàöèÿ: /afind off")
			elseif other then
				imgui.Button(u8"ÏÊÌ + 1")
				imgui.SameLine()
				imgui.Text(u8" -   Ñïðîñèòü äîêóìåíòû ó èãðîêà")
				imgui.Spacing()
				imgui.Button(u8"ÏÊÌ + 2")
				imgui.SameLine()
				imgui.Text(u8" -   Ñïðîñèòü äîêóìåíòû íà ò/ñ")
				imgui.Spacing()
				imgui.Button(u8"ÏÊÌ + 3")
				imgui.SameLine()
				imgui.Text(u8" -   Ïîïðîùàòüñÿ ñ èãðîêîì")
				imgui.Spacing()
				imgui.Button(u8"ÏÊÌ + 4")
				imgui.SameLine()
				imgui.Text(u8" -   Îáûñêàòü èãðîêà")
				imgui.Spacing()
				imgui.Button(u8"ÏÊÌ + 5")
				imgui.SameLine()
				imgui.Text(u8" -   Íàäåòü íàðó÷íèêè íà èãðîêà")
				imgui.Spacing()
				imgui.Button(u8"ÏÊÌ + 6")
				imgui.SameLine()
				imgui.Text(u8" -   Ñíÿòü íàðó÷íèêè ñ èãðîêà")
				imgui.Spacing()
				imgui.Button(u8"ÏÊÌ + 7")
				imgui.SameLine()
				imgui.Text(u8" -   Íà÷àòü ïðåñëåäîâàíèå èãðîêà")
				imgui.Spacing()
			elseif binds then
				if imgui.CollapsingHeader(u8'Èíôîðìàöèÿ') then
					imgui.Spacing()
					imgui.Spacing()
					imgui.Text(u8"Äëÿ îáðàùåíèÿ ê èãðîêó ïî íèêó èëè ID èñïîëüçóéòå {nick} èëè {id} â ëþáûõ òåêñòîâûõ ïîëÿõ íèæå.")
					imgui.Spacing()
					imgui.Spacing()
				end
				if imgui.CollapsingHeader(u8'Ñîîáùåíèÿ ïðè ïðîâåðêå äîêóìåíòîâ') then
					imgui.Spacing()
					imgui.Spacing()
					imgui.PushItemWidth(len)
					imgui.InputText(u8"Îñíîâíîé òåêñò ", askDoc[1])
					imgui.PopItemWidth()
					imgui.Spacing()
					imgui.PushItemWidth(len)
					imgui.InputText(u8"Äîïîëíèòåëüíûé òåêñò ", askDoc[2])
					imgui.PopItemWidth()
					imgui.Spacing()
					imgui.Spacing()
				end
				if imgui.CollapsingHeader(u8'Ñîîáùåíèÿ ïðè ïðîâåðêå äîêóìåíòîâ íà òðàíñïîðò') then
					imgui.Spacing()
					imgui.Spacing()
					imgui.PushItemWidth(len)
					imgui.InputText(u8"Îñíîâíîé òåêñò  ", askCarDoc[1])
					imgui.PopItemWidth()
					imgui.Spacing()
					imgui.PushItemWidth(len)
					imgui.InputText(u8"Äîïîëíèòåëüíûé òåêñò  ", askCarDoc[2])
					imgui.PopItemWidth()
					imgui.Spacing()
					imgui.Spacing()
				end
				if imgui.CollapsingHeader(u8'Ñîîáùåíèÿ ñ ïðîñüáîé ïîêèíóòü òðàíñïîðò') then
					imgui.Spacing()
					imgui.Spacing()
					imgui.PushItemWidth(len)
					imgui.InputText(u8"Îñíîâíîé òåêñò   ", getOutOfVeh[1])
					imgui.PopItemWidth()
					imgui.Spacing()
					imgui.PushItemWidth(len)
					imgui.InputText(u8"Äîïîëíèòåëüíûé òåêñò   ", getOutOfVeh[2])
					imgui.PopItemWidth()
					imgui.Spacing()
					imgui.Spacing()
				end
				if imgui.CollapsingHeader(u8'Ñîîáùåíèÿ ñ ïðîñüáîé îñòàíîâèòü òðàíñïîðò') then
					imgui.Spacing()
					imgui.Spacing()
					imgui.PushItemWidth(len)
					imgui.InputText(u8"Îñíîâíîé òåêñò    ", stopVeh[1])
					imgui.PopItemWidth()
					imgui.Spacing()
					imgui.PushItemWidth(len)
					imgui.InputText(u8"Äîïîëíèòåëüíûé òåêñò    ", stopVeh[2])
					imgui.PopItemWidth()
					imgui.Spacing()
					imgui.Spacing()
				end
				if imgui.CollapsingHeader(u8'Ñîîáùåíèÿ ñ ïðîùàíèåì ñ èãðîêîì') then
					imgui.Spacing()
					imgui.Spacing()
					imgui.PushItemWidth(len)
					imgui.InputText(u8"Îñíîâíîé òåêñò      ", bye[1])
					imgui.PopItemWidth()
					imgui.Spacing()
					imgui.PushItemWidth(len)
					imgui.InputText(u8"Äîïîëíèòåëüíûé òåêñò      ", bye[2])
					imgui.PopItemWidth()
					imgui.Spacing()
					imgui.Spacing()
				end
			elseif config then
				imgui.Checkbox(u8"\tÏîêàçûâàòü /ens ïðè ïðîâåðêå äîêóìåíòîâ", showPts)
				imgui.Spacing()
				imgui.Checkbox(u8"\tÀâòîìàòè÷åñêè îáûñêèâàòü èãðîêà ïðè ïðîâåðêå äîêóìåíòîâ", friskPlayer)
				imgui.Spacing()
				imgui.Checkbox(u8"\tÀâòîìàòè÷åñêè îáûñêèâàòü òðàíñïîðò ïðè ïðîñüáå ïîêèíóòü òðàíñïîðò", friskCar)
				imgui.Spacing()
				imgui.Checkbox(u8"\tÀâòîìàòè÷åñêè íàäåâàòü íàðó÷íèêè ïîñëå âûñòðåëà èç òàéçåðà. Íå ðàáîòàåò âìåñòå ñ ChatID.sf", cuffAfterTaser)
				imgui.Spacing()
				imgui.Checkbox(u8"\tÀâòîìàòè÷åñêè äîñòàâàòü îðóæèå ïîñëå ïîëó÷åíèå â îðóæåéíîé", takeGuns)
				imgui.Spacing()
				imgui.Checkbox(u8"\tÀâòîìàòè÷åñêè ïðåñëåäîâàòü èãðîêà ïîñëå âûäà÷è ðîçûñêà", chaseAfterSu)
				imgui.Spacing()
				imgui.Spacing()
				imgui.Separator()
				imgui.Spacing()
				imgui.Spacing()
				imgui.Checkbox(u8"\tÍå ñïðàøèâàòü äîêóìåíòû â âîñêðåñåíüå", dontAskWhenSunday)
				imgui.Spacing()
				imgui.Checkbox(u8"\tÍå ñïðàøèâàòü äîêóìåíòû íå íà ñìåíå èëè íà àíîíèìíîé ñìåíå FBI", dontAskWithoutDuty)
				imgui.Spacing()
				imgui.Checkbox(u8"\tÍå îáûñêèâàòü íå íà ñìåíå èëè íà àíîíèìíîé ñìåíå FBI", dontFriskWithoutDuty)
				imgui.Spacing()
				imgui.Checkbox(u8"\tÍå ñïðàøèâàòü äîêóìåíòû ó íîâè÷êîâ 1-2 lvl", askNovices)
				imgui.Spacing()
				imgui.Checkbox(u8"\tÍå ñïðàøèâàòü äîêóìåíòû ó ÎÏÃ", askGang)
				imgui.Spacing()
				imgui.Checkbox(u8"\tÍå ñïðàøèâàòü äîêóìåíòû ó ÏÎ", askPolice)
				imgui.Spacing()
				imgui.Checkbox(u8"\tÍå ñïðàøèâàòü äîêóìåíòû ó èãðîêîâ èç ñïèñêà", askPlayers)
				imgui.Spacing()
				imgui.Spacing()
				imgui.Separator()
				imgui.Spacing()
				imgui.Text(u8"Èãðîêè, êîòîðûå íå áóäóò ïðîâåðÿòüñÿ:")
				imgui.Spacing()
				imgui.PushItemWidth(len2)
				imgui.InputTextMultiline(u8" ", ignoredPlayers)
				imgui.PopItemWidth()

				if imgui.Button(u8"\t\t\t\t\t   Ñîõðàíèòü   \t\t\t\t\t") then
					ignoredArray = {}
					if not (ignoredPlayers.v == "") and not (ignoredPlayers.v == nil) then
						local i = 1
						file = io.open("moonloader/config/PoliceHelper/IgnoredPlayers.txt", "w")

						for line in string.gmatch(ignoredPlayers.v, "[^\r\n]+") do
							ignoredArray[i] = imgui.ImBuffer(line, 256)
							i = i + 1
							file:write(line .. '\n')
						end

						file:close()
					else

					end
				end
			end
		imgui.EndChild()
	imgui.End()
	imgui.PopStyleColor(1)
end

function askDocuments(pID)
	local weekday = os.date("%w", os.time() - 3600 * (tzone - 3))

	if weekday ~= "0" or not dontAskWhenSunday.v then
		local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local myColor = sampGetPlayerColor(myId)

		if not (myColor == 4294967295 or myColor == -1) or not dontAskWithoutDuty.v then
			local playerID = getPlayer()

			if pID ~= "" and pID ~= nil and pID ~= false then
				playerID = pID
			end

			if playerID ~= -1 then
				local ped = sampGetCharHandleBySampPlayerId(playerID)
				local score = sampGetPlayerScore(playerID)

				if (score < 1) then
					playerID = getPlayer()
					ped = sampGetCharHandleBySampPlayerId(playerID)
					score = sampGetPlayerScore(playerID)
				end

				if (score >= 3 or not askNovices) then
					if showPts.v then
						sampSendChat('/ens')
					end

					temp1 = string.gsub(askDoc[1].v, "{nick}", sampGetPlayerNickname(playerID))
					temp1 = string.gsub(temp1, "{id}", playerID)
					temp2 = string.gsub(askDoc[2].v, "{nick}", sampGetPlayerNickname(playerID))
					temp2 = string.gsub(temp2, "{id}", playerID)

					sampSendChat(u8:decode(temp1))
					sampSendChat(u8:decode(temp2))

					lua_thread.create(function()
						if friskPlayer.v then
							wait(1000)
							sampSendChat('/frisk '..playerID)
						end
					end)
				else
					sampAddChatMessage("Èãðîê {ffffff}" .. sampGetPlayerNickname(playerID) .. "[" .. playerID .. "]{7129ff}" .. " èìååò " .. score .. " lvl", phcolor)
				end
			else
				sampAddChatMessage('Íå íàéäåíî íè îäíîãî èãðîêà ïîáëèçîñòè', phcolor)
			end
		else
			sampAddChatMessage("Âû íå íà ñìåíå", phcolor)
		end
	else
		sampAddChatMessage("Ñåãîäíÿ âîñêðåñåíüå.", phcolor)
	end
end

function askCarDocuments(pID)
	local weekday = os.date("%w", os.time() - 3600 * (tzone - 3))

	if weekday ~= "0" or not dontAskWhenSunday.v then
		local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local myColor = sampGetPlayerColor(myId)

		if not (myColor == 4294967295 or myColor == -1) or not dontAskWithoutDuty.v then
			local playerID = getPlayer()

			if pID ~= "" and pID ~= nil and pID ~= false then
				playerID = pID
			end

			if playerID ~= -1 then
				local ped = sampGetCharHandleBySampPlayerId(playerID)
				local score = sampGetPlayerScore(playerID)

				if (score < 1) then
					playerID = getPlayer()
					ped = sampGetCharHandleBySampPlayerId(playerID)
					score = sampGetPlayerScore(playerID)
				end

				if (score >= 3  or not askNovices) then
					temp1 = string.gsub(askCarDoc[1].v, "{nick}", sampGetPlayerNickname(playerID))
					temp1 = string.gsub(temp1, "{id}", playerID)
					temp2 = string.gsub(askCarDoc[2].v, "{nick}", sampGetPlayerNickname(playerID))
					temp2 = string.gsub(temp2, "{id}", playerID)

					sampSendChat(u8:decode(temp1))
					sampSendChat(u8:decode(temp2))
				else
					sampAddChatMessage("Èãðîê {ffffff}" .. sampGetPlayerNickname(playerID) .. "[" .. playerID .. "]{7129ff}" .. " èìååò " .. score .. " lvl", phcolor)
				end
			else
				sampAddChatMessage('Íå íàéäåíî íè îäíîãî èãðîêà ïîáëèçîñòè', phcolor)
			end
		else
			sampAddChatMessage("Âû íå íà ñìåíå", phcolor)
		end
	else
		sampAddChatMessage("Ñåãîäíÿ âîñêðåñåíüå.", phcolor)
	end
end

function getPlayerOutOfVeh(pID)
	local weekday = os.date("%w", os.time() - 3600 * (tzone - 3))

	if weekday ~= "0" or not dontAskWhenSunday.v then
		local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local myColor = sampGetPlayerColor(myId)

		if not (myColor == 4294967295 or myColor == -1) or not dontAskWithoutDuty.v then
			local playerID = getPlayer()

			if pID ~= "" and pID ~= nil and pID ~= false then
				playerID = pID
			end

			if playerID ~= -1 then
				ped = sampGetCharHandleBySampPlayerId(playerID)
				score = sampGetPlayerScore(playerID)

				if (score < 1) then
					playerID = getPlayer()
					ped = sampGetCharHandleBySampPlayerId(playerID)
					score = sampGetPlayerScore(playerID)
				end

				if (score >= 3  or not askNovices) then
					temp1 = string.gsub(getOutOfVeh[1].v, "{nick}", sampGetPlayerNickname(playerID))
					temp1 = string.gsub(temp1, "{id}", playerID)
					temp2 = string.gsub(getOutOfVeh[2].v, "{nick}", sampGetPlayerNickname(playerID))
					temp2 = string.gsub(temp2, "{id}", playerID)

					sampSendChat(u8:decode(temp1))
					sampSendChat(u8:decode(temp2))

					lua_thread.create(function()
						if friskCar.v then
							wait(1000)
							sampSendChat('/friskcar')
						end
					end)
				else
					sampAddChatMessage("Èãðîê {ffffff}" .. sampGetPlayerNickname(playerID) .. "[" .. playerID .. "]{7129ff}" .. " èìååò " .. score .. " lvl", phcolor)
				end
			else
				sampAddChatMessage('Íå íàéäåíî íè îäíîãî èãðîêà ïîáëèçîñòè', phcolor)
			end
		else
			sampAddChatMessage("Âû íå íà ñìåíå", phcolor)
		end
	else
		sampAddChatMessage("Ñåãîäíÿ âîñêðåñåíüå.", phcolor)
	end
end

function stopPlayerVeh(pID)
	local weekday = os.date("%w", os.time() - 3600 * (tzone - 3))

	if weekday ~= "0" or not dontAskWhenSunday.v then
		local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local myColor = sampGetPlayerColor(myId)

		if not (myColor == 4294967295 or myColor == -1) or not dontAskWithoutDuty.v then
			local playerID = getPlayer()

			 if pID ~= "" and pID ~= nil and pID ~= false then
			 	playerID = pID
			 end

			if playerID ~= -1 then
				ped = sampGetCharHandleBySampPlayerId(playerID)
				score = sampGetPlayerScore(playerID)

				if (score < 1) then
					playerID = getPlayer()
					ped = sampGetCharHandleBySampPlayerId(playerID)
					score = sampGetPlayerScore(playerID)
				end

				if (score >= 3  or not askNovices) then
					temp1 = string.gsub(stopVeh[1].v, "{nick}", sampGetPlayerNickname(playerID))
					temp1 = string.gsub(temp1, "{id}", playerID)
					temp2 = string.gsub(stopVeh[2].v, "{nick}", sampGetPlayerNickname(playerID))
					temp2 = string.gsub(temp2, "{id}", playerID)

					lua_thread.create(function()
						sc = true

						sampSendChat("/m " .. u8:decode(temp1))
						wait(200)

						if sc then
							sampSendChat("/m " .. u8:decode(temp2))
						end

						wait(200)
						sc = false
					end)
				else
					sampAddChatMessage("Èãðîê {ffffff}" .. sampGetPlayerNickname(playerID) .. "[" .. playerID .. "]{7129ff}" .. " èìååò " .. score .. " lvl", phcolor)
				end
			else
				sampAddChatMessage('Íå íàéäåíî íè îäíîãî èãðîêà ïîáëèçîñòè', phcolor)
			end
		else
			sampAddChatMessage("Âû íå íà ñìåíå", phcolor)
		end
	else
		sampAddChatMessage("Ñåãîäíÿ âîñêðåñåíüå.", phcolor)
	end
end

function byePlayer(pID)
	local weekday = os.date("%w", os.time() - 3600 * (tzone - 3))

	if weekday ~= "0" or not dontAskWhenSunday.v then
		local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local myColor = sampGetPlayerColor(myId)

		if not (myColor == 4294967295 or myColor == -1) or not dontAskWithoutDuty.v then
			local playerID = getPlayer()

			if pID ~= "" and pID ~= nil and pID ~= false then
				playerID = pID
			end

			if playerID ~= -1 then
				ped = sampGetCharHandleBySampPlayerId(playerID)

				temp1 = string.gsub(bye[1].v, "{nick}", sampGetPlayerNickname(playerID))
				temp1 = string.gsub(temp1, "{id}", playerID)
				temp2 = string.gsub(bye[2].v, "{nick}", sampGetPlayerNickname(playerID))
				temp2 = string.gsub(temp2, "{id}", playerID)

				sampSendChat(u8:decode(temp1))
				sampSendChat(u8:decode(temp2))
			else
				sampAddChatMessage('Íå íàéäåíî íè îäíîãî èãðîêà ïîáëèçîñòè', phcolor)
			end
		else
			sampAddChatMessage("Âû íå íà ñìåíå", phcolor)
		end
	else
		sampAddChatMessage("Ñåãîäíÿ âîñêðåñåíüå.", phcolor)
	end
end

function frisk(pID)
	local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
	local myColor = sampGetPlayerColor(myId)

	if not (myColor == 4294967295 or myColor == -1) or not dontFriskWithoutDuty.v then
		local playerID = getPlayer()

		if pID ~= "" and pID ~= nil and pID ~= false then
			playerID = pID
		end

		if playerID ~= -1 then
			ped = sampGetCharHandleBySampPlayerId(playerID)
			sampSendChat("/frisk " .. playerID)
		else
			sampAddChatMessage('Íå íàéäåíî íè îäíîãî èãðîêà ïîáëèçîñòè', phcolor)
		end
	else
		sampAddChatMessage("Âû íå íà ñìåíå", phcolor)
	end
end

function cuffPlayer(pID)
	local playerID = getPlayer()

	if pID ~= "" and pID ~= nil and pID ~= false then
		playerID = pID
	end

	if playerID ~= -1 then
		ped = sampGetCharHandleBySampPlayerId(playerID)
		sampSendChat("/cuff " .. playerID)
	else
		sampAddChatMessage('Íå íàéäåíî íè îäíîãî èãðîêà ïîáëèçîñòè', phcolor)
	end
end

function unCuffPlayer(pID)
	local playerID = getPlayer()

	if pID ~= "" and pID ~= nil and pID ~= false then
		playerID = pID
	end

	if playerID ~= -1 then
		ped = sampGetCharHandleBySampPlayerId(playerID)
		sampSendChat("/uncuff " .. playerID)
	else
		sampAddChatMessage('Íå íàéäåíî íè îäíîãî èãðîêà ïîáëèçîñòè', phcolor)
	end
end

function chasePlayer(pID)
	local playerID = getPlayer()

	if pID ~= "" and pID ~= nil and pID ~= false then
		playerID = pID
	end

	if playerID ~= -1 then
		ped = sampGetCharHandleBySampPlayerId(playerID)
		sampSendChat("/z " .. playerID)
	else
		sampAddChatMessage('Íå íàéäåíî íè îäíîãî èãðîêà ïîáëèçîñòè', phcolor)
	end
end

function autoZ()
	az = true

	lua_thread.create(function ()
		sampSendChat("/wanted")
		wait(100)
		az = false
	end)
end

function autoDet()
	ad = true

	lua_thread.create(function ()
		sampSendChat("/wanted")
		wait(100)
		ad = false
	end)
end

function autoFind(id)
	if id ~= '' and id ~= "off" and id:find("^[0-9]+$") then
		suspectid = id

		if sampIsPlayerConnected(suspectid) then
			if isact then
				thread1:terminate()
			end

			isact = true
			sampAddChatMessage("Àâòîìàòè÷åñêèé ïîèñê {ffffff}"..sampGetPlayerNickname(suspectid).."["..suspectid.."]{ffffff}.", phcolor)
			sampSendChat('/find ' .. suspectid)
			thread1:run()
		end
	elseif id == "off" then
		if isact then
			isact = not isact
			sampAddChatMessage("Îñòàíîâêà àâòîïîèñêà {ffffff}"..sampGetPlayerNickname(suspectid).."["..suspectid.."]", phcolor)
		else
			sampAddChatMessage("Àâòîìàòè÷åñêèé ïîèñê íå áûë àêòèâèðîâàí", phcolor)
		end
	else
		if isact then
			sampAddChatMessage("Àâòîìàòè÷åñêèé ïîèñê óæå àêòèâèðîâàí", phcolor)
		else
			sampAddChatMessage("ID èãðîêà óêàçàí íåâåðíî", phcolor)
		end
	end
end

function getPlayer()
    local maxDist = 60.0
    local closestPlayer = -1
	local myPosX, myPosY, myPosZ = getCharCoordinates(PLAYER_PED)

    for i = 0, sampGetMaxPlayerId(true) do
		if sampIsPlayerConnected(i) and not sampIsPlayerNpc(i) then
			if sampGetCharHandleBySampPlayerId(i) then
				local playerPosX, playerPosY, playerPosZ = getCharCoordinates(select(2, sampGetCharHandleBySampPlayerId(i)))
				local dist = getDistanceBetweenCoords3d(myPosX, myPosY, myPosZ, playerPosX, playerPosY, playerPosZ)
				local name = sampGetPlayerNickname(i)

				if dist < maxDist then
					if not (sampGetPlayerColor(i) == 4294967040 or sampGetPlayerColor(i) == 4291237375 or sampGetPlayerColor(i) == 4279826207 or
							sampGetPlayerColor(i) == 4279228922 or sampGetPlayerColor(i) == 4292396898 or sampGetPlayerColor(i) == 4294910464 or
							sampGetPlayerColor(i) == 4286070681 or sampGetPlayerColor(i) == 4286023833 or sampGetPlayerColor(i) == 4287102976 or
							sampGetPlayerColor(i) == 4278550420 or sampGetPlayerColor(i) == 4278220612 or sampGetPlayerColor(i) == 4279900698 or
							sampGetPlayerColor(i) == 4282006074) or not askGang.v then
						if not (sampGetPlayerColor(i) == 4280963554 or sampGetPlayerColor(i) == 4282655487) or not askPolice.v then
							if not askPlayers.v then
								local result, handle = sampGetCharHandleBySampPlayerId(i)
								maxDist, closestPlayer = dist, i
							else
								lastClosestPlayer = closestPlayer
								local result, handle = sampGetCharHandleBySampPlayerId(i)
								maxDist, closestPlayer = dist, i

								for it = 1, #ignoredArray do
									if ignoredArray[it].v == name then
										closestPlayer = lastClosestPlayer
										break
									end
								end
							end
						end
					end
				end
			end
        end
    end

    return closestPlayer
end

function sampev.onServerMessage(color, text)
	if sc then
		if text:find("Ïîáëèçîñòè íåò òî÷åê,.*") or text:find("Ýòî òðàíñïîðòíîå ñðåäñòâî íå.*") then
			sampSendChat("/s " .. u8:decode(temp1))
			sampSendChat("/s " .. u8:decode(temp2))

			sc = false
			return false
		end
	end

	if az then
		if text:find("Ëþäè, êîòîðûå íàõîäÿòñÿ â ðîçûñêå:") then
			return false
		elseif text:find("Íà äàííûé ìîìåíò íèêòî íå ðàçûñêèâàåòñÿ.") then
			return true
		elseif text:find(".* .ID %d+..") and color == -169954305 then
			for id in string.gmatch	(text, "ID %d+") do
				sampSendChat("/z " .. id:match("%d+"))
			end
		else
			return true
		end
	end

	if ad then
		if text:find("Ëþäè, êîòîðûå íàõîäÿòñÿ â ðîçûñêå:") then
			return false
		elseif text:find("Íà äàííûé ìîìåíò íèêòî íå ðàçûñêèâàåòñÿ.") then
			return true
		elseif text:find(".* .ID %d+.. %d+ çâ {34C924}.surrender.{F5DEB3}.") then
			for id in string.gmatch	(text, " .ID %d+.. %d+ çâ {34C924}.surrender.{F5DEB3}.") do
				sampSendChat("/det " .. id:match("ID %d+"):match("%d+"))
			end
		else
			return true
		end
	end

	if chaseAfterSu.v and text:find("W: ") then 
		
	end

	if text:find("Âû âûñòðåëèëè èç øîêåðà â èãðîêà {abcdef}.+{ffffff} è îáåçäâèæèëè åãî íà .*") and cuffAfterTaser.v then
		isPlayerFrozen = true

		lua_thread.create(function()
			wait(100)
			sampSendChat("/cuff " .. text:match("}.*{"):match("([%w_%[%]%.%(%)]+)(%[%d+%])"))
			sampSendChat("/cuff " .. text:match("}.*{"):match("[%w_%[%]%.%(%)]+"))
			wait(100)
			isPlayerFrozen = false
		end)

		return true
	end

	if isPlayerFrozen and (text:find("Âû ñëèøêîì äàëåêî äðóã îò äðóãà.") or text:find("Íà ñåðâåðå íå íàéäåíî èãðîêîâ ïî óêàçàííûì âàìè ïàðàìåòðàì.")) then 
		return false
	end

	if text:find("Âû âçÿëè â îðóæåéíîé .+") and takeGuns.v then
		iter = iter + 1
		gun[iter] = text:match("}.+{")
		tg = true

		if gun[iter]:find("desert") then
			gun[iter] = "deagle"
		elseif gun[iter]:find("ñíàéïåð") then
			gun[iter] = "sniper"
		elseif gun[iter]:find("mp5") then
			gun[iter] = "mp5"
		elseif gun[iter]:find("m4") then
			gun[iter] = "m4"
		elseif gun[iter]:find("10 òàáåëüíûõ ãðàíàò") then
			gun[iter] = "gren"	
		elseif gun[iter]:find("10 òàáåëüíûõ äûìîâûõ øàøåê") then
			gun[iter] = "smoke"
		elseif gun[iter]:find("äðîáîâèê") then
			gun[iter] = "shot"
		elseif gun[iter]:find("âèíòîâêó") then
			gun[iter] = "rifle"
		elseif gun[iter]:find("îáðåç") then
			gun[iter] = "sawn"
		end

		sampAddChatMessage(gun[iter], -1)

		return true
	end

	if isact then
		if text:find('Îáúåêò .* îáíàðóæåí.') then
			pos = 0
		end
		if text:find('Ñèãíàë îò óêàçàííîãî èãðîêà ñëèøêîì ñëàá.') then
			sampAddChatMessage("Îñòàíîâêà àâòîïîèñêà {ffffff}"..sampGetPlayerNickname(suspectid).."["..suspectid.."]" .. col .. ". Îáúåêò ñïðÿòàëñÿ â çäàíèè.", phcolor)
			isact = not isact
			return false
		end
		if text:find('Óêàçàííûé âàìè èãðîê íå çàëîãèíåí.') then
			sampAddChatMessage("Îñòàíîâêà àâòîïîèñêà {ffffff}"..sampGetPlayerNickname(suspectid).."["..suspectid.."]" .. col .. ".", phcolor)
			isact = not isact
		end
		if text:find('Óêàçàííûé âàìè èãðîê íå çàñïàâíåí.') then
			isact = not isact
		end
		if text:find('Âû íå ìîæåòå íàéòè ñàìîãî ñåáÿ.') then
			isact = not isact
		end
		if text:find('Íà ñåðâåðå íå íàéäåíî èãðîêîâ ïî óêàçàííûì âàìè.*') then
			isact = not isact
		end
		if text:find('Óêàçàííûé âàìè èãðîê ÿâëÿåòñÿ áîòîì.') then
			sampAddChatMessage("Îñòàíîâêà àâòîïîèñêà {ffffff}"..sampGetPlayerNickname(suspectid).."["..suspectid.."]" .. col .. ". Óêàçàííûé âàìè èãðîê ÿâëÿåòñÿ áîòîì.", phcolor)
			isact = not isact
			return false
		end
		if text:find('Âû íàõîäèòåñü â ïîìåùåíèè è íå ñìîæåòå ïðèíèìàòü ñèãíàëû ñî ñïóòíèêà') then
			sampAddChatMessage("Îñòàíîâêà àâòîïîèñêà {ffffff}"..sampGetPlayerNickname(suspectid).."["..suspectid.."]" .. col .. ". Âû íàõîäèòåñü â ïîìåùåíèè.", phcolor)
			isact = not isact
			return false
		end
		if text:find("Çàïðåùàåòñÿ çàïðàøèâàòü ïîäîáíóþ èíôîðìàöèþ ñëèøêîì ÷àñòî. Ïîäîæäèòå åùå {fbec5d}%d ñåê{ffffff}.") then
			thread1:terminate()
			wtime = tonumber(text:match("%d ñåê"):match("%d"))

			lua_thread.create(function()
				wait(wtime + 500)
				sampSendChat("/find " .. suspectid)
				thread1:run()
			end)

			return false
		end
	end

	if takeGuns.v then
		if text:find("Àãåíò .* âçÿë óäîñòîâåðåíèå è âûøåë íà ñëóæáó.") then
			sampSendChat("/take knife")
			return true
		end
	end

	if accessory then
		if text:find("^Â âàøåì èíâåíòàðå íåò àêñåññóàðîâ äëÿ íèæíåé ÷àñòè ëèöà, ñîâìåñòèìûõ ñ ýòèì ñêèíîì.") or text:find("Â âàøåì èíâåíòàðå íåò øëåìîâ, çàùèùàþùèõ ãîëîâó, ñîâìåñòèìûõ ñ ýòèì ñêèíîì.") or
				text:find("Â âàøåì èíâåíòàðå íåò àêñåññóàðîâ äëÿ ãëàç, ñîâìåñòèìûõ ñ ýòèì ñêèíîì.") then
			return false
		end
	end
end

function sampev.onSendCommand(command)
	if command:find("^/frisk") then
		local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local myColor = sampGetPlayerColor(myId)

		if dontFriskWithoutDuty.v and (myColor == 4294967295 or myColor == -1) then
			sampAddChatMessage("Âû ïûòàåòåñü îáûñêàòü áóäó÷è íå íà ñìåíå.", phcolor)
			return false
		end
	end
end

function sampev.onShowDialog(dialogId, style, title, button1, button, text) 
	if accessory and dialogId == 45 and sampGetDialogText():find("Âû íå ìîæåòå èñïîëüçîâàòü ýòîò àêñåññóàð ïðè íèçêîì óðîâíå ãèãèåíû") then 
		sampCloseCurrentDialogWithButton(0)
		return true
	end 

	if (dialogId == 999 or dialogId == 45) and sampGetDialogText():find("Âû íå ìîæåòå èñïîëüçîâàòü ýòî îðóæèå â èíòåðüåðå") then 
		sampAddChatMessage("Âû íå ìîæåòå èñïîëüçîâàòü ýòî îðóæèå â èíòåðüåðå.", phcolor)
		setVirtualKeyDown(VK_RETURN, true)
		setVirtualKeyDown(VK_RETURN, false)
		return false
	end
end

function getMyId() 
	local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
	return myId
end

function thread()
	wait(100)

	while isact do
		if pos == 0 then
			wait(14100)

			if isact then
				sampSendChat('/find '..suspectid)
			end
		end
		if pos == 1 then
			wait(2000)

			if isact then
				sampSendChat('/find '..suspectid)
			end
		end
	end
end

function toBool(par)
	if par and par ~= "false" and par ~= 0 and par ~= "" then
		return true
	else
		return false
	end
end

function os.offset()
   local currenttime = os.time()
   local datetime = os.date("!*t",currenttime)
   datetime.isdst = true
   return currenttime - os.time(datetime)
end

function autoupdate(json_url)
	local dlstatus = require('moonloader').download_status
	local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'

	if doesFileExist(json) then 
		os.remove(json) 
	end

	downloadUrlToFile(json_url, json,
		function(id, status, p1, p2)
			if status == dlstatus.STATUSEX_ENDDOWNLOAD then
				if doesFileExist(json) then 
					local f = io.open(json, 'r')

					if f then
						local info = decodeJson(f:read('*a'))
						updatelink = info.updateurl
						updateversion = info.latest
						f:close()
						os.remove(json)

						if updateversion ~= thisScript().version then
							lua_thread.create(function()
								local dlstatus = require('moonloader').download_status
								local color = -1
								sampAddChatMessage(('Îáíàðóæåíî îáíîâëåíèå. Ïûòàþñü îáíîâèòüñÿ c '..thisScript().version..' íà '..updateversion), color)
								wait(250)

								downloadUrlToFile(updatelink, thisScript().path,
									function(id3, status1, p13, p23)
										if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
											print(string.format('Çàãðóæåíî %d èç %d.', p13, p23))
										elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
											print('Çàãðóçêà îáíîâëåíèÿ çàâåðøåíà.')
											sampAddChatMessage(('Îáíîâëåíèå çàâåðøåíî!'), color)
											goupdatestatus = true
											
											lua_thread.create(function() 
												wait(500) 
												thisScript():reload() 
											end)
										end
										if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
											if goupdatestatus == nil then
												sampAddChatMessage(('Îáíîâëåíèå ïðîøëî íåóäà÷íî. Çàïóñêàþ óñòàðåâøóþ âåðñèþ..'), color)
												update = false
											end
										end
									end
								)
							end)
						else
							update = false
							print('v'..thisScript().version..': Îáíîâëåíèå íå òðåáóåòñÿ.')
						end
					end
        		else
					print('v'..thisScript().version..': Íå ìîãó ïðîâåðèòü îáíîâëåíèå')
					update = false
        		end
      		end
		end
	)
  	while update ~= false do wait(100) end
end
