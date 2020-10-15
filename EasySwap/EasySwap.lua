-- Data ----------------------------------------------------------------

EASY_SWAP = "Easy Swap";
SAVE_CURRENT_CONFIG = "Save Talents";
TALENT_CONFIGURATION = "Talent Configuration ";
CLEAR_SPEC = "Clear";
SLASH_EASYSWAP1 = "/easyswap";
SLASH_EASYSWAP2 = "/es";

local EASY_SWAP_OFSX = 10;
local EASY_SWAP_OFSY = 4;

AUTO_SHOW_EASY_SWAP = false;

SPEC_CONFIGURATIONS = {
	{},
	{},
	{},
	{},
};

-- End Data ------------------------------------------------------------


-- Hooks ---------------------------------------------------------------

local OldPlayerTalentFrameTab_OnClick;
local TALENT_FRAME_BASE_WIDTH = 646;
local TALENT_FRAME_EXPANSION_EXTRA_WIDTH = 137;

-- End Hooks -----------------------------------------------------------


-- Core Code -----------------------------------------------------------

local function LoadTalentsTab()
	-- Hacky way of getting the game to load in all the character talent information
	for talentsTab = 2, 1, -1 do
		ToggleTalentFrame(talentsTab);
		ToggleTalentFrame(talentsTab);
	end
end

local function AddEasySwapButtonToFrame(frame, ofsX, ofsY)
	if ( frame ) then
		local ESButton = CreateFrame("Button", nil, frame, "EasySwapButton");
		ESButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", ofsX, ofsY);
		frame.EasySwapButton = ESButton;
	end
end

local function OnLoadTalentUI()
	local ofsX = -5;
	local ofsY = 5;
	AddEasySwapButtonToFrame(PlayerTalentFrame, ofsX, ofsY);

	if ( not OldPlayerTalentFrameTab_OnClick ) then
		OldPlayerTalentFrameTab_OnClick = PlayerTalentFrameTab_OnClick;
	end
	PlayerTalentFrameTab_OnClick = function(self)
		local showEasySwapButton = self:GetID() == 2;
		PlayerTalentFrame.EasySwapButton:SetShown(showEasySwapButton);
		local showEasySwapFrame = self:GetID() == 2 and AUTO_SHOW_EASY_SWAP;
		PlayerTalentFrame.EasySwapFrame:SetShown(showEasySwapFrame);
		OldPlayerTalentFrameTab_OnClick(self);
	end

 	PlayerTalentFrame_SetExpanded = function(expanded)
 		local extraWidth = EasySwapFrame:IsShown() and 310 or 0;
		if (expanded) then
			PlayerTalentFrame:SetWidth(TALENT_FRAME_BASE_WIDTH + TALENT_FRAME_EXPANSION_EXTRA_WIDTH);
			PlayerTalentFrameTalentsTRCorner:SetPoint("TOPRIGHT", -140, -2);
			PlayerTalentFrameTalentsBRCorner:SetPoint("BOTTOMRIGHT", -140, 2);
			PlayerTalentFrameTalents.PvpTalentFrame:Show();
			if (PlayerTalentFrameTalents.PvpTalentFrame.TalentList:IsShown()) then
				SetUIPanelAttribute(PlayerTalentFrame, "width", PlayerTalentFrame.superExpandedPanelWidth + extraWidth);
				PlayerTalentFrame.currentExpansionWidth = PlayerTalentFrame.superExpandedPanelWidth;
			else
				SetUIPanelAttribute(PlayerTalentFrame, "width", PlayerTalentFrame.expandedPanelWidth + extraWidth);
				PlayerTalentFrame.currentExpansionWidth = PlayerTalentFrame.expandedPanelWidth;
			end
		else
			PlayerTalentFrame:SetWidth(TALENT_FRAME_BASE_WIDTH);
			PlayerTalentFrameTalentsTRCorner:SetPoint("TOPRIGHT", -3, -2);
			PlayerTalentFrameTalentsBRCorner:SetPoint("BOTTOMRIGHT", -3, 2);
			PlayerTalentFrameTalents.PvpTalentFrame:Hide();
			SetUIPanelAttribute(PlayerTalentFrame, "width", PlayerTalentFrame.basePanelWidth + extraWidth);
			PlayerTalentFrame.currentExpansionWidth = PlayerTalentFrame.basePanelWidth;
		end
		UpdateUIPanelPositions(PlayerTalentFrame);
	end

	PlayerTalentFrameTalents.PvpTalentFrame.SelectSlot = function(self, slot)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		if (self.selectedSlotIndex) then
			local sameSelected = self.selectedSlotIndex == slot.slotIndex;
			self:UnselectSlot();
			if (sameSelected) then
				return;
			end
		end
		local extraWidth = EasySwapFrame:IsShown() and 310 or 0;
		SetUIPanelAttribute(PlayerTalentFrame, "width", PlayerTalentFrame.superExpandedPanelWidth + extraWidth);
		UpdateUIPanelPositions(PlayerTalentFrame);
		EasySwapFrame:ClearAllPoints();
		EasySwapFrame:SetPoint("TOPLEFT", PlayerTalentFrame, "TOPRIGHT", EASY_SWAP_OFSX + 190, EASY_SWAP_OFSY);
		self.selectedSlotIndex = slot.slotIndex;
		slot.Arrow:Show();
		HybridScrollFrame_SetOffset(self.TalentList.ScrollFrame, 0);
		self.TalentList:Update();
		self.TalentList:Show();
	end

	PlayerTalentFrameTalents.PvpTalentFrame.UnselectSlot = function(self)
		if (not self.selectedSlotIndex) then
			return;
		end

		local slot = self.Slots[self.selectedSlotIndex];

		slot.Arrow:Hide();
		self.TalentList:Hide();
		self.selectedSlotIndex = nil;
		EasySwapFrame:ClearAllPoints();
		EasySwapFrame:SetPoint("TOPLEFT", PlayerTalentFrame, "TOPRIGHT", EASY_SWAP_OFSX, EASY_SWAP_OFSY);
		local extraWidth = EasySwapFrame:IsShown() and 310 or 0;
		SetUIPanelAttribute(PlayerTalentFrame, "width", PlayerTalentFrame.expandedPanelWidth + extraWidth);
		UpdateUIPanelPositions(PlayerTalentFrame);
	end

	EasySwapFrame:SetParent(PlayerTalentFrame);
	PlayerTalentFrame.EasySwapFrame = EasySwapFrame;
	EasySwapFrame:ClearAllPoints();
	EasySwapFrame:SetPoint("TOPLEFT", PlayerTalentFrame, "TOPRIGHT", EASY_SWAP_OFSX, EASY_SWAP_OFSY);
end

local function SaveCurrentConfig(spec, config)
	local newConfig = {};
	local setTalents = false;
	for tier = 1, MAX_TALENT_TIERS do
		for col = 1, 3 do
			local talentButton = _G["PlayerTalentFrameTalentsTalentRow"..tier.."Talent"..col];
			local selected = talentButton.knownSelection:IsShown();
			if ( selected ) then
				newConfig[tier] = col;
				SPEC_CONFIGURATIONS["Spec"..spec.."Tier"..tier.."Config"..config.."Info"] = {
					ID = talentButton:GetID();
					icon = talentButton.icon:GetTexture();
				};
				setTalents = true;
				break;
			end
		end
	end
	if ( setTalents ) then
		SPEC_CONFIGURATIONS[spec][config] = newConfig;
	end
end

local function GetTalentButton(row, col)
	return _G["PlayerTalentFrameTalentsTalentRow"..row.."Talent"..col];
end

local function ActivateConfiguration(spec, config)
	local configuration = SPEC_CONFIGURATIONS[spec][config];
	if ( configuration ) then
		for row, col in ipairs(configuration) do
			local talentButton = GetTalentButton(row, col);
			PlayerTalentFrameTalent_OnClick(talentButton, "LeftButton");
		end
	end
end

local function PrintUsage()
	print("|cFF0000FF-------------------------------------------------------------------------------------|r");
	print("|cFF42e0f5Easy Swap Usage:|r");
	print('|cFFf59342Type (or macro) "/easyswap n" to switch to talent configuration n.|r');
	print("|cFFf59342Example:|r /easyswap 2");
	print("|cFF0000FF-------------------------------------------------------------------------------------|r");
end

local function HandleSlash(msg, editbox)
	local configNumber = tonumber(msg);
	if ( configNumber and configNumber >= 1 and configNumber <= 4 ) then
		local currSpec = GetSpecialization();
		ActivateConfiguration(currSpec, configNumber);
	else
		PrintUsage();
	end
end

SlashCmdList["EASYSWAP"] = HandleSlash;


local EasySwapFrameEvents = {
	"ADDON_LOADED",
	"PLAYER_ENTERING_WORLD",
	"PLAYER_SPECIALIZATION_CHANGED",
};

EasySwapFrameMixin = {};

function EasySwapFrameMixin:OnLoad()
	for _, event in ipairs(EasySwapFrameEvents) do
		self:RegisterEvent(event);
	end
end

function EasySwapFrameMixin:OnEvent(event, ...)
	if ( event == "ADDON_LOADED" ) then
		local addonName = ...;
		if ( addonName == "Blizzard_TalentUI" ) then
			OnLoadTalentUI();
		end
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		if ( not IsAddOnLoaded("Blizzard_TalentUI") ) then
			LoadTalentsTab();
		end
		self:Update();
	elseif ( event == "PLAYER_SPECIALIZATION_CHANGED" ) then
		self:Update();
	end
end

function EasySwapFrameMixin:Update()
	for _, spec in ipairs(self.EasySwapSpecs) do
		spec:Update();
	end
end


EasySwapButtonMixin = {};

function EasySwapButtonMixin:OnClick(button, up)
	local parentFrame = self:GetParent();
	local easySwapFrame = parentFrame.EasySwapFrame;
	local show = not easySwapFrame:IsShown();
	easySwapFrame:SetShown(show);
	AUTO_SHOW_EASY_SWAP = show;
	local extraWidth = show and 310 or 0;
	SetUIPanelAttribute(PlayerTalentFrame, "width", PlayerTalentFrame.currentExpansionWidth + extraWidth);
	UpdateUIPanelPositions(PlayerTalentFrame);
end


EasySwapActivateSpecButtonMixin = {};

function EasySwapActivateSpecButtonMixin:OnClick(button, down)
	local currSpec = GetSpecialization();
	local configNumber = self:GetParent().configNumber;
	ActivateConfiguration(currSpec, configNumber);
end


EasySwapSaveSpecButtonMixin = {};

function EasySwapSaveSpecButtonMixin:OnClick(button, down)
	local parent = self:GetParent();
	local currSpec = GetSpecialization();
	local configNumber = parent.configNumber;
	SaveCurrentConfig(currSpec, configNumber);
	parent:Update();
end


EasySwapClearSpecButtonMixin = {};

function EasySwapClearSpecButtonMixin:OnClick()
	local parent = self:GetParent();
	local currSpec = GetSpecialization();
	local configNumber = parent.configNumber;
	SPEC_CONFIGURATIONS[currSpec][configNumber] = nil;
	for tier = 1, MAX_TALENT_TIERS do
		SPEC_CONFIGURATIONS["Spec"..currSpec.."Tier"..tier.."Config"..configNumber.."Info"] = nil;
	end
	parent:Update();
end


EasySwapTalentChoiceMixin = {};

function EasySwapTalentChoiceMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetTalent(self.ID);
	GameTooltip:Show();
end

function EasySwapTalentChoiceMixin:OnLeave()
	GameTooltip:Hide();
end

function EasySwapTalentChoiceMixin:Update()
	local spec = GetSpecialization();
	local tier = self.rowNumber;
	local config = self:GetParent().configNumber;
	local info = SPEC_CONFIGURATIONS["Spec"..spec.."Tier"..tier.."Config"..config.."Info"];
	if ( info ) then
		self:Show();
		self.ID = info.ID;
		self.Icon:SetTexture(info.icon);
		local tierLevel = tier == 1 and 15 or 25 + 5 * (tier - 2);
		self.TierLevel:SetText(tierLevel);
	else
		self:Hide();
	end
end


EasySwapSpecMixin = {};

function EasySwapSpecMixin:OnLoad()
	self.NameBox.SpecName:SetText(TALENT_CONFIGURATION..self.configNumber);
end

function EasySwapSpecMixin:Update()
	local currSpec = GetSpecialization();
	local configNumber = self.configNumber;
	local configuration = SPEC_CONFIGURATIONS[currSpec][configNumber];
	if ( configuration ) then
		self.ActivateButton:Enable();
		self.EditNameButton:Show();
		if ( configuration.name ) then
			self.NameBox.SpecName:SetText(configuration.name);
		end
	else
		self.ActivateButton:Disable();
		self.EditNameButton:Hide();
		self.NameBox.SpecName:SetText(TALENT_CONFIGURATION..self.configNumber);
	end

	for _, choice in ipairs(self.TalentChoices) do
		choice:Update();
	end
end


EasySwapEditNameButtonMixin = {};

function EasySwapEditNameButtonMixin:OnClick()
	local nameBox = self:GetParent().NameBox;
	nameBox.NameEditBox:SetText(nameBox.SpecName:GetText());
	nameBox.SpecName:Hide();
	self:Hide();
	nameBox.NameEditBox:HighlightText();
	nameBox.NameEditBox:Show();
end


ConfigurationNameEditBoxMixin = {};

function ConfigurationNameEditBoxMixin:OnEnterPressed()
	local nameBox = self:GetParent();
	local config = nameBox:GetParent();
	local currSpec = GetSpecialization();
	local configNumber = config.configNumber;
	local configuration = SPEC_CONFIGURATIONS[currSpec][configNumber];
	local text = self:GetText()
	if ( configuration and text ~= "" ) then
		configuration.name = text;
	end
	nameBox.SpecName:Show();
	config.EditNameButton:Show();
	self:Hide();
	config:Update();
end

function ConfigurationNameEditBoxMixin:OnEscapePressed()
	local nameBox = self:GetParent();
	local config = nameBox:GetParent();
	nameBox.SpecName:Show();
	config.EditNameButton:Show();
	self:Hide();
end

-- End Core Code -------------------------------------------------------