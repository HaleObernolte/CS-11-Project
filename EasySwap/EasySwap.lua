-- Data ----------------------------------------------------------------

EASY_SWAP = "Easy Swap";

local testSpec = {
	3,
	2,
	2,
	1,
	1,
	1,
	1,
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

local function GetTalentButton(row, col)
	return _G["PlayerTalentFrameTalentsTalentRow"..row.."Talent"..col];
end


local EasySwapFrameEvents = {
	"ADDON_LOADED",
	"PLAYER_ENTERING_WORLD",
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


EasySwapSpecButtonMixin = {};

function EasySwapSpecButtonMixin:OnClick(button, down)
	for row, col in ipairs(testSpec) do
		local talentButton = GetTalentButton(row, col);
		PlayerTalentFrameTalent_OnClick(talentButton, "LeftButton");
	end
end

-- End Core Code -------------------------------------------------------