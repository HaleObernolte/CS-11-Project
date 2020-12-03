-- Data ----------------------------------------------------------------

ITEM_TRACKER = "Item Tracker";
IT_START_SESSION = "Start Session";
IT_STOP_SESSION = "Stop Session";
IT_UNKNOWN_VALUE = "--|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t --|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t --|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
IT_ADD_ITEM_INSTRUCTIONS = "|cFF808080Enter item name or item ID here...|r";

IT_TRACKED_ITEMS = {};

IT_ITEM_IS_TRACKED_MAP = {};

IT_SETTINGS = {
	ShowIcons = true;
	ShowNames = true;
	ShowQuantity = true;
	ShowValuePer = true;
	ShowValueTotal = true;
	IncludeBankInCount = false;
};

-- End Data ------------------------------------------------------------


-- Hooks ---------------------------------------------------------------


-- End Hooks -----------------------------------------------------------


-- Core Code -----------------------------------------------------------

local function GetItemQuantity(itemName)
	return GetItemCount(itemName, IT_SETTINGS.IncludeBankInCount);
end


ItemTrackerFrameMixin = {};

function ItemTrackerFrameMixin:OnLoad()
	self:ClearAllPoints();
	self:RegisterForDrag("LeftButton");
	self:RegisterEvent("BAG_UPDATE");
	self.TexturesShown = true;
end

function ItemTrackerFrameMixin:OnEvent(event, ...)
	if ( event == "BAG_UPDATE" ) then
		self:UpdateItemCounts();
	end
end

function ItemTrackerFrameMixin:OnShow()
	self.ScrollList:RefreshListDisplay();
end

function ItemTrackerFrameMixin:InitScrollFrame()
	self.ScrollList:SetElementTemplate("ItemTrackerItemTemplate", self);

	local function GetNumResultsCallback()
		return self:GetNumResults();
	end

	self.ScrollList:SetGetNumResultsFunction(GetNumResultsCallback);
end

function ItemTrackerFrameMixin:GetNumResults()
	return #IT_TRACKED_ITEMS;
end

function ItemTrackerFrameMixin:GetOption(index)
	return IT_TRACKED_ITEMS[index];
end

function ItemTrackerFrameMixin:AddItem(item)
	if ( not IT_ITEM_IS_TRACKED_MAP[item.Name] ) then
		IT_ITEM_IS_TRACKED_MAP[item.Name] = true;
		tinsert(IT_TRACKED_ITEMS, item);
		self.ScrollList:RefreshListDisplay();
	end
end

function ItemTrackerFrameMixin:OnDragStart()
	self:StartMoving();
end

function ItemTrackerFrameMixin:OnDragStop()
	self:StopMovingOrSizing();
end

function ItemTrackerFrameMixin:ToggleTextures()
	self.TexturesShown = not self.TexturesShown;
	for _, texture in ipairs(self.Textures) do
		texture:SetShown(self.TexturesShown);
	end
end

function ItemTrackerFrameMixin:UpdateItemCounts()
	for _, item in ipairs(IT_TRACKED_ITEMS) do
		local newQty = GetItemQuantity(item.Name);
		item.Quantity = newQty;
	end
	self.ScrollList:RefreshListDisplay();
end


ItemTrackerItemMixin = {};

function ItemTrackerItemMixin:InitElement(itemList)
	self.itemList = itemList;
end

function ItemTrackerItemMixin:GetItemList()
	return self.itemList;
end

function ItemTrackerItemMixin:GetOption()
	return self:GetItemList():GetOption(self:GetListIndex());
end

function ItemTrackerItemMixin:UpdateDisplay()
	local option = self:GetOption();

	self.Icon:SetTexture(option.Texture or "Interface\\Icons\\INV_Misc_QuestionMark");
	self.Name:SetTextColor(GetItemQualityColor(option.Quality or 1));
	self.Name:SetText(option.Name);
	self.Quantity:SetText(option.Quantity);
	if ( option.ValuePer) then
		local valuePerText = GetCoinTextureString(option.ValuePer);
		valuePerText = strsub(valuePerText, 1, strfind(valuePerText, "|t") + 1);
		local valueTotalText = GetCoinTextureString(option.ValuePer * option.Quantity);
		valueTotalText = strsub(valueTotalText, 1, strfind(valueTotalText, "|t") + 1);
		self.ValuePer:SetText(valuePerText);
		self.ValueTotal:SetText(valueTotalText);
	else
		self.ValuePer:SetText(IT_UNKNOWN_VALUE);
		self.ValueTotal:SetText(IT_UNKNOWN_VALUE);
	end
end


ItemTrackerOptionsButtonMixin = {}

function ItemTrackerOptionsButtonMixin:OnClick(button, down)
	FOO_TEST_QTY = FOO_TEST_QTY and FOO_TEST_QTY + 1 or 1;
	local itemName, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(171831);
	local newItem = {
		Texture = itemTexture,
		Name = itemName,
		Quality = itemRarity,
		Quantity = FOO_TEST_QTY,
		ValuePer = 1251111;
	};
	self:GetParent():AddItem(newItem);
end


ItemTrackerStartSessionButtonMixin = {};

function ItemTrackerStartSessionButtonMixin:OnClick(button, down)
	IT_TRACKED_ITEMS = {};
	IT_ITEM_IS_TRACKED_MAP = {};
	self:GetParent().ScrollList:RefreshListDisplay();
end


ItemTrackerStopSessionButtonMixin = {};

function ItemTrackerStopSessionButtonMixin:OnClick(button, down)
	IT_TRACKED_ITEMS = {};
	IT_ITEM_IS_TRACKED_MAP = {};
	self:GetParent().ScrollList:RefreshListDisplay();
end


ItemTrackerAddItemBoxMixin = {};

function ItemTrackerAddItemBoxMixin:OnShow()
	self:SetText(IT_ADD_ITEM_INSTRUCTIONS);
end

function ItemTrackerAddItemBoxMixin:OnEditFocusGained()
	self:SetText("");
end

function ItemTrackerAddItemBoxMixin:OnEditFocusLost()
	self:SetText(IT_ADD_ITEM_INSTRUCTIONS);
end

function ItemTrackerAddItemBoxMixin:OnEnterPressed()
	local input = self:GetText();
	local itemName, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(input);
	if ( itemName ) then
		local newItem = {
			Texture = itemTexture,
			Name = itemName,
			Quality = itemRarity,
			Quantity = GetItemQuantity(itemName),
			ValuePer = 1251111;
		};
		self:GetParent():AddItem(newItem);
	end
	self:SetText(IT_ADD_ITEM_INSTRUCTIONS);
	self:ClearFocus();
end

function ItemTrackerAddItemBoxMixin:OnEscapePressed()
	self:SetText(IT_ADD_ITEM_INSTRUCTIONS);
	self:ClearFocus();
end

-- End Core Code -------------------------------------------------------