-- Data ----------------------------------------------------------------

EASY_SWAP = "Easy Swap";
SAVE_CURRENT_CONFIG = "Save Talents";
TALENT_CONFIGURATION = "Talent Configuration ";

SPEC_CONFIGURATIONS = {
	{},
	{},
	{},
	{},
};

-- End Data ------------------------------------------------------------


-- Hooks ---------------------------------------------------------------

local OldPlayerTalentFrameTab_OnClick;

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
		OldPlayerTalentFrameTab_OnClick(self);
		local showEasySwapButton = self:GetID() == 2;
		PlayerTalentFrame.EasySwapButton:SetShown(showEasySwapButton);
		local showEasySwapFrame = self:GetID() == 2 and PlayerTalentFrame.IsEasySwapShown;
		PlayerTalentFrame.EasySwapFrame:SetShown(showEasySwapFrame);
	end

	EasySwapFrame:SetParent(PlayerTalentFrame);
	PlayerTalentFrame.EasySwapFrame = EasySwapFrame;
	EasySwapFrame:ClearAllPoints();
	ofsX = 10;
	ofsY = 4;
	EasySwapFrame:SetPoint("TOPLEFT", PlayerTalentFrame, "TOPRIGHT", ofsX, ofsY);
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
	parentFrame.IsEasySwapShown = show;
end


EasySwapActivateSpecButtonMixin = {};

function EasySwapActivateSpecButtonMixin:OnClick(button, down)
	local currSpec = GetSpecialization();
	local configNumber = self:GetParent().configNumber;
	local configuration = SPEC_CONFIGURATIONS[currSpec][configNumber];
	if ( configuration ) then
		for row, col in ipairs(configuration) do
			local talentButton = GetTalentButton(row, col);
			PlayerTalentFrameTalent_OnClick(talentButton, "LeftButton");
		end
	end
end


EasySwapSaveSpecButtonMixin = {};

function EasySwapSaveSpecButtonMixin:OnClick(button, down)
	local currSpec = GetSpecialization();
	local configNumber = self:GetParent().configNumber;
	SaveCurrentConfig(currSpec, configNumber);
	self:GetParent():Update();
end


EasySwapSpecMixin = {};

function EasySwapSpecMixin:OnLoad()
	self.SpecName:SetText(TALENT_CONFIGURATION..self.configNumber);
end

function EasySwapSpecMixin:Update()
	local currSpec = GetSpecialization();
	local configNumber = self.configNumber;
	local configuration = SPEC_CONFIGURATIONS[currSpec][configNumber];
	if ( configuration ) then
		self.ActivateButton:Enable();
	else
		self.ActivateButton:Disable();
	end
end

-- End Core Code -------------------------------------------------------