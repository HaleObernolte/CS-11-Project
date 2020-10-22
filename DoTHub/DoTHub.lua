-- Data ----------------------------------------------------------------

DOT_HUB = "DoT Hub";

local DOT_HUB_NAMEPLATE = "DoTHubNameplate";
local MAX_NAMEPLATES = 5;
local NAMEPLATE_PADDING = -20;
local DOT_HUB_BASE_HEIGHT = 120;

-- End Data ------------------------------------------------------------


-- Hooks ---------------------------------------------------------------

-- End Hooks -----------------------------------------------------------


-- Core Code -----------------------------------------------------------

DoTHubEnemyFrameMixin = {};

function DoTHubEnemyFrameMixin:Initialize(unit)
	self.statusCounter = 0;
	self.statusSign = -1;
	self.unitHPPercent = 1;
	self.unit = unit;

	local thisName = self:GetName();
	self.borderTexture = _G[thisName.."TextureFrameTexture"];
	self.highLevelTexture = _G[thisName.."TextureFrameHighLevelTexture"];
	self.pvpIcon = _G[thisName.."TextureFramePVPIcon"];
	self.prestigePortrait = _G[thisName.."TextureFramePrestigePortrait"];
	self.prestigeBadge = _G[thisName.."TextureFramePrestigeBadge"];
	self.leaderIcon = _G[thisName.."TextureFrameLeaderIcon"];
	self.raidTargetIcon = _G[thisName.."TextureFrameRaidTargetIcon"];
	self.questIcon = _G[thisName.."TextureFrameQuestIcon"];
	self.levelText = _G[thisName.."TextureFrameLevelText"];
	self.deadText = _G[thisName.."TextureFrameDeadText"];
	self.unconsciousText = _G[thisName.."TextureFrameUnconsciousText"];
	self.petBattleIcon = _G[thisName.."TextureFramePetBattleIcon"];
	self.TOT_AURA_ROW_WIDTH = TOT_AURA_ROW_WIDTH;
	-- set simple frame
	if ( not self.showLevel ) then
		self.highLevelTexture:Hide();
		self.levelText:Hide();
	end
	-- set threat frame
	local threatFrame;
	if ( self.showThreat ) then
		threatFrame = _G[thisName.."Flash"];
	end
	-- set portrait frame
	local portraitFrame;
	if ( self.showPortrait ) then
		portraitFrame = _G[thisName.."Portrait"];
	end

	_G[thisName.."HealthBar"].LeftText = _G[thisName.."TextureFrameHealthBarTextLeft"];
	_G[thisName.."HealthBar"].RightText = _G[thisName.."TextureFrameHealthBarTextRight"];
	_G[thisName.."ManaBar"].LeftText = _G[thisName.."TextureFrameManaBarTextLeft"];
	_G[thisName.."ManaBar"].RightText = _G[thisName.."TextureFrameManaBarTextRight"];

	UnitFrame_Initialize(self, unit, _G[thisName.."TextureFrameName"], portraitFrame,
						 _G[thisName.."HealthBar"], _G[thisName.."TextureFrameHealthBarText"],
						 _G[thisName.."ManaBar"], _G[thisName.."TextureFrameManaBarText"],
	                     threatFrame, "player", _G[thisName.."NumericalThreat"],
						 _G[thisName.."MyHealPredictionBar"], _G[thisName.."OtherHealPredictionBar"],
						 _G[thisName.."TotalAbsorbBar"], _G[thisName.."TotalAbsorbBarOverlay"], _G[thisName.."TextureFrameOverAbsorbGlow"],
						 _G[thisName.."TextureFrameOverHealAbsorbGlow"], _G[thisName.."HealAbsorbBar"],
						 _G[thisName.."HealAbsorbBarLeftShadow"], _G[thisName.."HealAbsorbBarRightShadow"]);

	TargetFrame_Update(self);
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("UNIT_HEALTH");
	if ( self.showLevel ) then
		self:RegisterEvent("UNIT_LEVEL");
	end
	self:RegisterEvent("UNIT_FACTION");
	if ( self.showClassification ) then
		self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED");
	end
	if ( self.showLeader ) then
		self:RegisterEvent("PLAYER_FLAGS_CHANGED");
	end
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("RAID_TARGET_UPDATE");
	self:RegisterUnitEvent("UNIT_AURA", unit);

	local frameLevel = _G[thisName.."TextureFrame"]:GetFrameLevel();

	SecureUnitButton_OnLoad(self, self.unit);
end


local DoTHubFrameEvents = {
	"NAME_PLATE_UNIT_ADDED",
};

DoTHubFrameMixin = {};

function DoTHubFrameMixin:OnLoad()
	self.nameplates = {};
	self:ClearAllPoints();
	self:RegisterForDrag("LeftButton");
	for _, event in ipairs(DoTHubFrameEvents) do
		self:RegisterEvent(event);
	end
end

function DoTHubFrameMixin:OnEvent(event, ...)
	if ( event == "NAME_PLATE_UNIT_ADDED" ) then 
		local nameplate = ...;
		local numNameplates = #self.nameplates; 
		if ( UnitCanAttack("player", nameplate) and numNameplates < MAX_NAMEPLATES ) then
			local newPlate = CreateFrame("Button", DOT_HUB_NAMEPLATE..(numNameplates + 1), self, "DoTHubEnemyFrameTemplate");
			newPlate:ClearAllPoints();
			if ( numNameplates == 0 ) then
				newPlate:SetPoint("TOP", self, "TOP", 20, -30);
			else
				newPlate:SetPoint("TOP", self.nameplates[numNameplates], "BOTTOM", 0, NAMEPLATE_PADDING);
			end
			table.insert(self.nameplates, newPlate);
			newPlate.showLevel = true;
			newPlate.showPortrait = true;
			newPlate:Initialize(nameplate);
			local newHeight = DOT_HUB_BASE_HEIGHT + (100 + NAMEPLATE_PADDING + 20) * #self.nameplates;
			self:SetHeight(newHeight);
		end
	end
end

function DoTHubFrameMixin:OnEnter()
	for _, texture in ipairs(self.Textures) do
		texture:Show();
	end
end

function DoTHubFrameMixin:OnLeave()
	local mouseFrame = GetMouseFocus();
	local mouseFrameName = mouseFrame and mouseFrame:GetName() or "";
	local lenName = string.len(mouseFrameName);
	local namePrefix = string.sub(mouseFrameName, 1, lenName - 1);
	if ( namePrefix ~= DOT_HUB_NAMEPLATE ) then
		for _, texture in ipairs(self.Textures) do
			texture:Hide();
		end
	end
end

function DoTHubFrameMixin:OnDragStart()
	self:StartMoving();
end

function DoTHubFrameMixin:OnDragStop()
	self:StopMovingOrSizing();
end

-- End Core Code -------------------------------------------------------