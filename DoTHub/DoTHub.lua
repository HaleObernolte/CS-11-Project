-- Data ----------------------------------------------------------------

DOT_HUB = "DoT Hub";
DOT_HUB_WHITELIST = "DoT Hub Whitelist";
WHITELIST_BUTTON = "Whitelist";
USE_WHITELIST = "Use Whitelist";
USE_WHITELIST_TOOLTIP = "When enabled, only spells manually specified in the whitelist frame will be tracked.";

local NO_NAME_FOUND = "Waiting for unit data...";
local MAX_NAMEPLATES = 5; -- TODO: Enforce
local MAX_DEBUFFS = 6; -- TODO: Enforce
local NAMEPLATE_PADDING = -20;
local DOT_HUB_BASE_HEIGHT = 160;
local debugLinkedList = false;

DOT_HUB_WHITELISTS = {
	{},
	{},
	{},
	{},
};
DOT_HUB_USE_WHITELIST = false;

-- End Data ------------------------------------------------------------


-- Hooks ---------------------------------------------------------------

-- End Hooks -----------------------------------------------------------


-- Core Code -----------------------------------------------------------

local unitFramePool = {};
local debuffFramePool = {};
 
local function RemoveUnitFrame(f)
    f:Hide();
    tinsert(unitFramePool, f);
end
 
local function GetNewUnitFrame(parent)
    local f = tremove(unitFramePool);
    if ( not f ) then
        f = CreateFrame("Frame", nil, parent, "DoTHubUnitFrameTemplate");
        f.Debuffs = {};
    else
    	f:SetParent(parent);
        f:ClearAllPoints();
        f:ClearDebuffs();
        f:SetGUID(nil);
        f.PrevNode = nil;
        f.NextNode = nil;
        f.DebuffLinkedListStart = nil;
        f.Name:SetText("");
        f:Show();
    end
    return f;
end

local function RemoveDebuffFrame(f)
    f:Hide();
    tinsert(debuffFramePool, f);
end
 
local function GetNewDebuffFrame(parent)
    local f = tremove(debuffFramePool);
    if ( not f ) then
        f = CreateFrame("Frame", nil, parent, "DoTHubDebuffFrameTemplate");
    else
    	f:SetParent(parent);
    	f:ClearAllPoints();
        f.Icon:SetTexture(nil);
        f.Countdown:SetText("");
        f.PrevNode = nil;
        f.NextNode = nil;
        CooldownFrame_Clear(f.Cooldown);
        f:Show();
    end
    return f;
end

local function CheckLinkedList(listStart)
	local currNode = listStart;
	local seenNodes = {};
	while ( currNode ) do
		for _, node in ipairs(seenNodes) do
			if ( node == currNode ) then
				print("|cFFFF0000DoT Hub Error: Node duplicated in linked list.");
			end
		end
		if ( currNode.PrevNode == currNode ) then
			print("|cFFFF0000DoT Hub Error: Node points to itself in PrevNode.");
		end
		if ( currNode.NextNode == currNode ) then
			print("|cFFFF0000DoT Hub Error: Node points to itself in NextNode.");
		end

		tinsert(seenNodes, currNode);
		currNode = currNode.NextNode;
	end
end

local function PrintLinkedList(listStart)
	local currNode = listStart;
	local printed = false;
	if ( currNode and currNode.GetGUID ) then
		print("|cFF0000FFPrinting Unit List...|r");
	elseif ( currNode ) then
		print("|cFF0000FFPrinting Debuff List...|r");
	end
	while ( currNode ) do
		printed = true;
		print("Curr node at:", currNode)
		print("Prev node at:", currNode.PrevNode)
		if ( currNode.PrevNode == currNode ) then
			print("|cFFFF0000Whoops! Node pointing to itself in PrevNode =(");
			break;
		end
		print("Next node at:", currNode.NextNode)
		if ( currNode.NextNode == currNode ) then
			print("|cFFFF0000Whoops! Node pointing to itself in NextNode =(");
			break;
		end
		currNode = currNode.NextNode;
	end
	if ( printed ) then
		print("|cFF0000FFFinished printing list|r");
	end
end


local function LinkedListAddFront(f, listStart)
	if ( debugLinkedList ) then
		print("|cFF00FF00Adding node at:|r", f);
	end

	f.PrevNode = nil;
	f.NextNode = listStart;
	if ( listStart ) then
		listStart.PrevNode = f;
	end
	listStart = f;

	if ( debugLinkedList ) then
		CheckLinkedList(listStart);
		PrintLinkedList(listStart);
	end
	return listStart;
end

local function LinkedListRemove(f, listStart)
	if ( debugLinkedList ) then
		print("|cFF00FF00Removing node at:|r", f);
	end
	
	if ( not f or not listStart ) then
		return;
	end

	if ( listStart == f ) then
		listStart = f.NextNode;
	end

	if ( f.NextNode ) then
		f.NextNode.PrevNode = f.PrevNode;
	end

	if ( f.PrevNode ) then
		f.PrevNode.NextNode = f.NextNode;
	end

	if ( debugLinkedList ) then
		CheckLinkedList(listStart);
		PrintLinkedList(listStart);
	end
	return listStart;
end


local GUIDToUnitCache = {};
local UnitToGUIDCache = {};
local needNameFromUnit = {};

local function UpdateUnitGUIDCaches(unit)
	local newGUID = UnitGUID(unit);
	local oldGUID = UnitToGUIDCache[unit];

	if ( GUIDToUnitCache[oldGUID] ) then
		for i, u in ipairs(GUIDToUnitCache[oldGUID]) do
			if ( u == unit ) then
				tremove(GUIDToUnitCache[oldGUID], i);
				break;
			end
		end
	end

	UnitToGUIDCache[unit] = newGUID;
	if ( newGUID and not GUIDToUnitCache[newGUID] ) then
		GUIDToUnitCache[newGUID] = {unit};
	elseif ( newGUID ) then
		tinsert(GUIDToUnitCache[newGUID], unit);
	end

	if ( needNameFromUnit[newGUID] ) then
		local name = UnitName(unit);
		for _, f in pairs(needNameFromUnit[newGUID]) do
			f.Name:SetText(name);
		end
		needNameFromUnit[newGUID] = nil;
	end
end


local function GetCurrentWhitelist()
	local spec = GetSpecialization();
	return DOT_HUB_WHITELISTS[spec];
end


DoTHubUnitFrameMixin = {};

function DoTHubUnitFrameMixin:AddDebuff(spellId)
	local debuffFrame = self.Debuffs[spellId];
	if ( not self.Debuffs[spellId] ) then
		self.NumDebuffs = self.NumDebuffs and self.NumDebuffs + 1 or 1;
		debuffFrame = GetNewDebuffFrame(self);
		self.Debuffs[spellId] = debuffFrame;
		self.DebuffsLinkedListStart = LinkedListAddFront(debuffFrame, self.DebuffsLinkedListStart);
		debuffFrame:ClearAllPoints();
		if ( debuffFrame.NextNode ) then
			debuffFrame:SetPoint("BOTTOMLEFT", debuffFrame.NextNode, "BOTTOMRIGHT", 0, 0);
		else
			debuffFrame:SetPoint("CENTER", self, "LEFT", -20, -20);
		end 
		local _, _, spellIcon = GetSpellInfo(spellId);
		debuffFrame.Icon:SetTexture(spellIcon);
	end
	CooldownFrame_Clear(debuffFrame.Cooldown);
end

function DoTHubUnitFrameMixin:RemoveDebuff(spellId)
	local debuffFrame = self.Debuffs[spellId];
	if ( not self.Debuffs[spellId] ) then
		return;
	end

	self.NumDebuffs = self.NumDebuffs - 1;
	local currFrame = debuffFrame.PrevNode;
	while ( currFrame ) do
		currFrame:ClearAllPoints();
		local relativeTo = currFrame.NextNode;
		if ( currFrame.NextNode == debuffFrame ) then
			relativeTo = relativeTo.NextNode
		end
		if ( relativeTo ) then
			currFrame:SetPoint("BOTTOMLEFT", relativeTo, "BOTTOMRIGHT", 0, 0);
		else
			currFrame:SetPoint("CENTER", self, "LEFT", -20, -20);
		end
		currFrame = currFrame.PrevNode;
	end
	self.Debuffs[spellId] = nil;
	self.DebuffsLinkedListStart = LinkedListRemove(debuffFrame, self.DebuffsLinkedListStart);
	RemoveDebuffFrame(debuffFrame);

	if ( self.NumDebuffs == 0 ) then
		local DoTHubFrame = self:GetParent();
		local guid = self:GetGUID();
		DoTHubFrame:RemoveUnit(guid);
	end
end

function DoTHubUnitFrameMixin:OnUpdate()
	local guid = self:GetGUID();
	local unit = GUIDToUnitCache[guid] and GUIDToUnitCache[guid][1];
	if ( unit ) then
		AuraUtil.ForEachAura(unit, "HARMFUL", MAX_TARGET_BUFFS, function(...)
        	local debuffName, icon, _, _, duration, expirationTime, caster, _, _ , spellId = ...;
        	if ( caster == "player" ) then
        		local debuffFrame = self.Debuffs[spellId];
        		if ( not debuffFrame ) then
        			print("|cFFFF0000DoT Hub: ERROR! Untracked debuff found:|r", debuffName);
        			return;
        		end
        		debuffFrame.Icon:SetTexture(icon);
        		CooldownFrame_Set(debuffFrame.Cooldown, expirationTime - duration, duration, duration > 0, true);
        	end
        end);
	end
end

function DoTHubUnitFrameMixin:SetGUID(GUID)
	self.GUID = GUID;
end

function DoTHubUnitFrameMixin:GetGUID()
	return self.GUID;
end

function DoTHubUnitFrameMixin:ClearDebuffs()
	for _, f in pairs(self.Debuffs) do
		RemoveDebuffFrame(f);
	end
	self.Debuffs = {};
	self.DebuffsLinkedListStart = nil;
	self.NumDebuffs = 0;
end


local DoTHubFrameEvents = {
	"COMBAT_LOG_EVENT_UNFILTERED",
	"PLAYER_REGEN_DISABLED",
	"PLAYER_REGEN_ENABLED",
	"UNIT_TARGET",
	"NAME_PLATE_UNIT_ADDED",
	"NAME_PLATE_UNIT_REMOVED",
};

DoTHubFrameMixin = {};

function DoTHubFrameMixin:OnLoad()
	self.UnitFrames = {};
	self:ClearAllPoints();
	self:RegisterForDrag("LeftButton");
	for _, event in ipairs(DoTHubFrameEvents) do
		self:RegisterEvent(event);
	end
end

function DoTHubFrameMixin:OnEvent(event, ...)
	if ( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
		local _, subEvent, _, sourceGUID, _, _, _, destGUID,
			  destName, _, _, spellId, spellName, _, auraType  = CombatLogGetCurrentEventInfo();
		if ( subEvent == "UNIT_DIED" ) then
			self:RemoveUnit(guid);
		elseif ( subEvent == "SPELL_AURA_APPLIED" and sourceGUID == UnitGUID("player")
			     	and destGUID ~= sourceGUID and auraType == "DEBUFF" ) then
			local currWhitelist = GetCurrentWhitelist();
			if ( not DOT_HUB_USE_WHITELIST or currWhitelist[spellId] ) then
				local unitFrame = self.UnitFrames[destGUID];
				if ( not unitFrame ) then
					unitFrame = self:AddNewUnit(destGUID, destName);
				end
				unitFrame:AddDebuff(spellId);
			end
		elseif ( subEvent == "SPELL_AURA_REMOVED" and sourceGUID == UnitGUID("player")
			     	and destGUID ~= sourceGUID and auraType == "DEBUFF" ) then
			local unitFrame = self.UnitFrames[destGUID];
			if ( unitFrame ) then
				unitFrame:RemoveDebuff(spellId);
			end
		end
	elseif ( event == "PLAYER_REGEN_DISABLED" ) then
		self.WhitelistButton:Disable();
		self.WhitelistToggle:Disable();
		DoTHubWhitelistFrame:Hide();
	elseif ( event == "PLAYER_REGEN_ENABLED" ) then
		self.WhitelistButton:Enable();
		self.WhitelistToggle:Enable();
		--self:ClearUnitFrames();
	elseif ( event == "UNIT_TARGET" ) then
		local unitTarget = ...;
		local targetedUnit = unitTarget.."target";
		UpdateUnitGUIDCaches(targetedUnit);
	elseif ( event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" ) then
		local nameplateUnit = ...;
		UpdateUnitGUIDCaches(nameplateUnit);
	end
end

function DoTHubFrameMixin:ClearUnitFrames()
	for _, f in pairs(self.UnitFrames) do
		RemoveUnitFrame(f);
	end
	self.UnitFrames = {};
	self.NumUnitFrames = 0;
	self:SetHeight(DOT_HUB_BASE_HEIGHT);
	self.UnitsLinkedListStart = nil;
end

function DoTHubFrameMixin:AddNewUnit(unitGUID, unitName)
	if ( self.UnitFrames[unitGUID] ) then
		return;
	end

	self.NumUnitFrames = self.NumUnitFrames and self.NumUnitFrames + 1 or 1;
	local f = GetNewUnitFrame(self);
	self.UnitFrames[unitGUID] = f;
	f:SetGUID(unitGUID);
	local targetName = unitName or GUIDToUnitCache[unitGUID] and GUIDToUnitCache[unitGUID][1] and UnitName(GUIDToUnitCache[unitGUID][1]);
	if ( targetName ) then
		f.Name:SetText(targetName);
	else
		f.Name:SetText(NO_NAME_FOUND);
		if ( not needNameFromUnit[unitGUID] ) then
			needNameFromUnit[unitGUID] = {f};
		else
			tinsert(needNameFromUnit[unitGUID], f);
		end
	end
	self.UnitsLinkedListStart = LinkedListAddFront(f, self.UnitsLinkedListStart);
	f:ClearAllPoints();
	if ( f.NextNode ) then
		f:SetPoint("TOP", f.NextNode, "BOTTOM", 0, NAMEPLATE_PADDING);
	else
		f:SetPoint("TOP", self, "TOP", 20, -30);
	end
	local newHeight = DOT_HUB_BASE_HEIGHT + (100 + NAMEPLATE_PADDING + 20) * self.NumUnitFrames;
	self:SetHeight(newHeight);

	return f;
end

function DoTHubFrameMixin:RemoveUnit(unitGUID)
	local unitFrame = self.UnitFrames[unitGUID];
	if ( not unitFrame ) then
		return;
	end

	self.NumUnitFrames = self.NumUnitFrames - 1;
	local newHeight = DOT_HUB_BASE_HEIGHT + (100 + NAMEPLATE_PADDING + 20) * self.NumUnitFrames;
	self:SetHeight(newHeight);

	local currFrame = unitFrame.PrevNode;
	while ( currFrame ) do
		currFrame:ClearAllPoints();
		local relativeTo = currFrame.NextNode;
		if ( currFrame.NextNode == unitFrame ) then
			relativeTo = relativeTo.NextNode
		end
		if ( relativeTo ) then
			currFrame:SetPoint("TOP", relativeTo, "BOTTOM", 0, NAMEPLATE_PADDING);
		else
			currFrame:SetPoint("TOP", self, "TOP", 20, -30);
		end
		currFrame = currFrame.PrevNode;
	end

	self.UnitFrames[unitGUID] = nil;
	self.UnitsLinkedListStart = LinkedListRemove(unitFrame, self.UnitsLinkedListStart);
	RemoveUnitFrame(unitFrame);
end

function DoTHubFrameMixin:OnDragStart()
	self:StartMoving();
end

function DoTHubFrameMixin:OnDragStop()
	self:StopMovingOrSizing();
end


DoTHubWhiteListToggleButtonMixin = {};

function DoTHubWhiteListToggleButtonMixin:OnClick()
	local whitelistFrame = DoTHubWhitelistFrame;
	local show = not whitelistFrame:IsShown();
	whitelistFrame:SetShown(show);
end


DoTHubWhiteListToggleBoxMixin = {};

function DoTHubWhiteListToggleBoxMixin:OnLoad()
	self:RegisterEvent("ADDON_LOADED");
	self.Text:SetText(USE_WHITELIST);
	self.tooltip = USE_WHITELIST_TOOLTIP;
end

function DoTHubWhiteListToggleBoxMixin:OnEvent(event, ...)
	if ( event == "ADDON_LOADED" ) then
		addon = ...;
		if ( addon == "DoTHub" ) then
			local useWhitelist = DOT_HUB_USE_WHITELIST;
			self:SetChecked(useWhitelist);
			self:UnregisterEvent("ADDON_LOADED");
		end
	end
end

function DoTHubWhiteListToggleBoxMixin:OnClick()
	local useWhitelist = self:GetChecked();
	DOT_HUB_USE_WHITELIST = useWhitelist;
end

-- End Core Code -------------------------------------------------------