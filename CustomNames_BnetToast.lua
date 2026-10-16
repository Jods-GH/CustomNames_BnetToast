local lib = LibStub("CustomNames")

-- mirrors the locals in Blizzard_BNet/<Family>/BNet.lua
local BN_TOAST_TYPE_ONLINE = 1
local BN_TOAST_TYPE_OFFLINE = 2
local BN_TOAST_TYPE_BROADCAST = 3

local function isUsable(value)
	return value ~= nil and not (issecretvalue and issecretvalue(value))
end

local function GetAccountInfo(frame)
	local toastType = frame.toastType
	if toastType ~= BN_TOAST_TYPE_ONLINE and toastType ~= BN_TOAST_TYPE_OFFLINE and toastType ~= BN_TOAST_TYPE_BROADCAST then return end
	if not frame.toastData then return end
	return C_BattleNet.GetAccountInfoByID(frame.toastData)
end

local function GetBtagCustomName(info)
	local tag = info.battleTag
	if not isUsable(tag) then return end
	local customName = lib.Get(tag)
	if customName and customName ~= tag then
		return customName
	end
end

local function UpdateTopLine(frame)
	if not frame.TopLine:IsShown() then return end
	local info = GetAccountInfo(frame)
	if not info then return end
	local customName = GetBtagCustomName(info)
	if customName then
		frame.TopLine:SetText(FRIENDS_BNET_NAME_COLOR:WrapTextInColorCode(customName))
	end
end

local function UpdateMiddleLine(frame)
	if frame.toastType ~= BN_TOAST_TYPE_ONLINE or not frame.MiddleLine:IsShown() then return end
	local info = GetAccountInfo(frame)
	local game = info and info.gameAccountInfo
	if not game or game.clientProgram ~= BNET_CLIENT_WOW then return end
	local characterName, realmName = game.characterName, game.realmName
	if not isUsable(characterName) or not isUsable(realmName) or characterName == "" or realmName == "" then return end

	local key = characterName .. "-" .. realmName:gsub("[%s-]+", "")
	local customName = lib.Get(key)
	if not customName or customName == key then return end
	-- a char linked to the btag would just repeat the top line
	if customName == GetBtagCustomName(info) then return end

	local text = frame.MiddleLine:GetText()
	if not isUsable(text) then return end
	-- keep the client icon (|T..|t on retail, |A..|a on classic)
	local prefix = text:match("^(.*|[ta]%s?)") or ""
	-- SetText (not SetFormattedText) so our own hook doesn't fire again
	frame.MiddleLine:SetText(prefix .. customName)
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_BNet", function()
	hooksecurefunc(BNToastFrame, "ShowToast", function(self)
		UpdateTopLine(self)
		UpdateMiddleLine(self)
	end)
	-- retail fills the middle line from an async texture callback after ShowToast returns
	hooksecurefunc(BNToastFrame.MiddleLine, "SetFormattedText", function()
		UpdateMiddleLine(BNToastFrame)
	end)
end)
