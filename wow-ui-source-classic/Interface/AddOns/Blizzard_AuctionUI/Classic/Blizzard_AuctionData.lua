NUM_BROWSE_TO_DISPLAY = 8;
NUM_AUCTION_ITEMS_PER_PAGE = 50;
NUM_FILTERS_TO_DISPLAY = 15;
BROWSE_FILTER_HEIGHT = 20;
NUM_BIDS_TO_DISPLAY = 9;
NUM_AUCTIONS_TO_DISPLAY = 9;
AUCTIONS_BUTTON_HEIGHT = 37;
CLASS_FILTERS = {};
OPEN_FILTER_LIST = {};
AUCTION_TIMER_UPDATE_DELAY = 0.3;
MAXIMUM_BID_PRICE = 2000000000;
AUCTION_CANCEL_COST =  5;	--5% of the current bid
NUM_TOKEN_LOGS_TO_DISPLAY = 14;

AuctionSort = { };

-- owner sorts
AuctionSort["owner_status"] = {
	{ column = "quantity",	reverse = true	},
	{ column = "bid",		reverse = false	},
	{ column = "name",		reverse = false	},
	{ column = "level",		reverse = true	},
	{ column = "quality",	reverse = false	},
	{ column = "duration",	reverse = false	},
	{ column = "status",	reverse = false	},
};

AuctionSort["owner_bid"] = {
	{ column = "quantity",	reverse = true	},
	{ column = "name",		reverse = false	},
	{ column = "level",		reverse = true	},
	{ column = "quality",	reverse = false	},
	{ column = "duration",	reverse = false	},
	{ column = "status",	reverse = false	},
	{ column = "bid",		reverse = false	},
};

AuctionSort["owner_quality"] = {
	{ column = "bid",		reverse = false	},
	{ column = "quantity",	reverse = true	},
	{ column = "minbidbuyout",	reverse = false	},
	{ column = "name",		reverse = false	},
	{ column = "level",		reverse = true	},
	{ column = "quality",	reverse = false	},
};

AuctionSort["owner_duration"] = {
	{ column = "quantity",	reverse = true	},
	{ column = "bid",		reverse = false	},
	{ column = "name",		reverse = false	},
	{ column = "level",		reverse = true	},
	{ column = "quality",	reverse = false	},
	{ column = "status",	reverse = false	},
	{ column = "duration",	reverse = false	},
};

-- bidder sorts
AuctionSort["bidder_quality"] = {
	{ column =  "bid",		reverse = false	},
	{ column =  "quantity",	reverse = true	},
	{ column =  "minbidbuyout",	reverse = false	},
	{ column =  "name",		reverse = false	},
	{ column =  "level",	reverse = true	},
	{ column =  "quality",	reverse = false	},
};

AuctionSort["bidder_level"] = {
	{ column =  "minbidbuyout",	reverse = true	},
	{ column =  "status",	reverse = true	},
	{ column =  "bid",		reverse = true	},
	{ column =  "duration",	reverse = true	},
	{ column =  "quantity",	reverse = false	},
	{ column =  "name",		reverse = true	},
	{ column =  "quality",	reverse = true	},
	{ column =  "level",	reverse = false	},
};

AuctionSort["bidder_buyout"] = {
	{ column =  "quantity",	reverse = true	},
	{ column =  "name",		reverse = false	},
	{ column =  "level",	reverse = true	},
	{ column =  "quality",	reverse = false	},
	{ column =  "status",	reverse = false	},
	{ column =  "bid",		reverse = false	},
	{ column =  "duration",	reverse = false	},
	{ column =  "buyout",	reverse = false	},
};
 
AuctionSort["bidder_status"] = {
	{ column =  "quantity",	reverse = true	},
	{ column =  "name",		reverse = false	},
	{ column =  "level",	reverse = true	},
	{ column =  "quality",	reverse = false	},
	{ column =  "minbidbuyout",	reverse = false	},
	{ column =  "bid",		reverse = false	},
	{ column =  "duration", reverse = false	},
	{ column =  "status",	reverse = false	},
};

AuctionSort["bidder_bid"] = {
	{ column =  "quantity",	reverse = true	},
	{ column =  "name",		reverse = false	},
	{ column =  "level",	reverse = true	},
	{ column =  "quality",	reverse = false	},
	{ column =  "minbidbuyout",	reverse = false	},
	{ column =  "status",	reverse = false	},
	{ column =  "duration",	reverse = false	},
	{ column =  "bid",		reverse = false	},
};

AuctionSort["bidder_duration"] = {
	{ column =  "quantity",	reverse = true	},
	{ column =  "name",		reverse = false	},
	{ column =  "level",	reverse = true	},
	{ column =  "quality",	reverse = false	},
	{ column =  "minbidbuyout",	reverse = false	},
	{ column =  "status",	reverse = false	},
	{ column =  "bid",		reverse = false	},
	{ column =  "duration",	reverse = false	},
};

-- list sorts
AuctionSort["list_level"] = {
	{ column = "duration",	reverse = true	},
	{ column = "bid",		reverse = true	},
	{ column = "quantity",	reverse = false	},
	{ column = "minbidbuyout",	reverse = true	},
	{ column = "name",		reverse = true	},
	{ column = "quality",	reverse = true	},
	{ column = "level",		reverse = false	},
};
AuctionSort["list_duration"] = {
	{ column = "bid",		reverse = false	},
	{ column = "quantity",	reverse = true	},
	{ column = "minbidbuyout",	reverse = false	},
	{ column = "name",		reverse = false	},
	{ column = "level",		reverse = true	},
	{ column = "quality",	reverse = false	},
	{ column = "duration",	reverse = false	},
};
AuctionSort["list_seller"] = {
	{ column = "duration",	reverse = false	},
	{ column = "bid",		reverse = false },
	{ column = "quantity",	reverse = true	},
	{ column = "minbidbuyout",	reverse = false	},
	{ column = "name",		reverse = false	},
	{ column = "level",		reverse = true	},
	{ column = "quality",	reverse = false	},
	{ column = "seller",	reverse = false	},
};
AuctionSort["list_bid"] = {
	{ column = "duration",	reverse = false	},
	{ column = "quantity",	reverse = true	},
	{ column = "name",		reverse = false	},
	{ column = "level",		reverse = true	},
	{ column = "quality",	reverse = false	},
	{ column = "bid",		reverse = false	},
};

AuctionSort["list_quality"] = {
	{ column = "duration",	reverse = false	},
	{ column = "bid",		reverse = false	},
	{ column = "quantity",	reverse = true	},
	{ column = "minbidbuyout",	reverse = false	},
	{ column = "name",		reverse = false	},
	{ column = "level",		reverse = true	},
	{ column = "quality",	reverse = false	},
};

AuctionCategories = {};

local function FindDeepestCategory(categoryIndex, ...)
	local categoryInfo = AuctionCategories[categoryIndex];
	for i = 1, select("#", ...) do
		local subCategoryIndex = select(i, ...);
		if categoryInfo and categoryInfo.subCategories and categoryInfo.subCategories[subCategoryIndex] then
			categoryInfo = categoryInfo.subCategories[subCategoryIndex];
		else
			break;
		end
	end
	return categoryInfo;
end

function AuctionFrame_GetDetailColumnString(categoryIndex, subCategoryIndex)
	local categoryInfo = FindDeepestCategory(categoryIndex, subCategoryIndex);
	return categoryInfo and categoryInfo:GetDetailColumnString() or REQ_LEVEL_ABBR;
end

function AuctionFrame_DoesCategoryHaveFlag(flag, categoryIndex, subCategoryIndex, subSubCategoryIndex)
	local categoryInfo = FindDeepestCategory(categoryIndex, subCategoryIndex, subSubCategoryIndex);
	if categoryInfo then
		return categoryInfo:HasFlag(flag);
	end
	return false;
end

function AuctionFrame_CreateCategory(name)
	local category = CreateFromMixins(AuctionCategoryMixin);
	category.name = name;
	AuctionCategories[#AuctionCategories + 1] = category;
	return category;
end

AuctionCategoryMixin = {};

function AuctionCategoryMixin:SetDetailColumnString(detailColumnString)
	self.detailColumnString = detailColumnString;
end

function AuctionCategoryMixin:GetDetailColumnString()
	if self.detailColumnString then
		return self.detailColumnString;
	end
	if self.parent then
		return self.parent:GetDetailColumnString();
	end
	return REQ_LEVEL_ABBR;
end

function AuctionCategoryMixin:CreateSubCategory(classID, subClassID, inventoryType)
	local name = "";
	if inventoryType then
		name = C_Item.GetItemInventorySlotInfo(inventoryType);
	elseif classID and subClassID then
		name = C_Item.GetItemSubClassInfo(classID, subClassID);
	elseif classID then
		name = GetItemClassInfo(classID);
	end
	return self:CreateNamedSubCategory(name);
end

function AuctionCategoryMixin:CreateNamedSubCategory(name)
	self.subCategories = self.subCategories or {};

	local subCategory = CreateFromMixins(AuctionCategoryMixin);
	self.subCategories[#self.subCategories + 1] = subCategory;
	assert(name and #name > 0);
	subCategory.name = name;
	subCategory.parent = self;
	subCategory.sortIndex = #self.subCategories;
	return subCategory;
end

function AuctionCategoryMixin:CreateNamedSubCategoryAndFilter(name, classID, subClassID, inventoryType)
	local category = self:CreateNamedSubCategory(name);
	category:AddFilter(classID, subClassID, inventoryType);

	return category;
end

function AuctionCategoryMixin:CreateSubCategoryAndFilter(classID, subClassID, inventoryType)
	local category = self:CreateSubCategory(classID, subClassID, inventoryType);
	category:AddFilter(classID, subClassID, inventoryType);

	return category;
end

function AuctionCategoryMixin:AddBulkInventoryTypeCategories(classID, subClassID, inventoryTypes)
	for i, inventoryType in ipairs(inventoryTypes) do
		self:CreateSubCategoryAndFilter(classID, subClassID, inventoryType);
	end
end

function AuctionCategoryMixin:AddFilter(classID, subClassID, inventoryType)
	self.filters = self.filters or {};
	self.filters[#self.filters + 1] = { classID = classID, subClassID = subClassID, inventoryType = inventoryType, };

	if self.parent then
		self.parent:AddFilter(classID, subClassID, inventoryType);
	end
end

do
	local function GenerateSubClassesHelper(self, classID, ...)
		for i = 1, select("#", ...) do
			local subClassID = select(i, ...);
			self:CreateSubCategoryAndFilter(classID, subClassID);
		end
	end

	function AuctionCategoryMixin:GenerateSubCategoriesAndFiltersFromSubClass(classID)
		GenerateSubClassesHelper(self, classID, GetAuctionItemSubClasses(classID));
	end
end

function AuctionCategoryMixin:FindSubCategoryByName(name)
	if self.subCategories then
		for i, subCategory in ipairs(self.subCategories) do
			if subCategory.name == name then
				return subCategory;
			end
		end
	end
end

function AuctionCategoryMixin:SortSubCategories()
	if self.subCategories then
		table.sort(self.subCategories, function(left, right)
			return left.sortIndex < right.sortIndex;
		end)
	end
end

function AuctionCategoryMixin:SetSortIndex(sortIndex)
	self.sortIndex = sortIndex
end

function AuctionCategoryMixin:SetFlag(flag)
	self.flags = self.flags or {};
	self.flags[flag] = true;
end

function AuctionCategoryMixin:ClearFlag(flag)
	if self.flags then
		self.flags[flag] = nil;
	end
end

function AuctionCategoryMixin:HasFlag(flag)
	return not not (self.flags and self.flags[flag]);
end

local function HasValidSubClasses(classID)
	return GetAuctionItemSubClasses(classID);
end

do -- Weapons
	local weaponsCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_WEAPONS);

	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Axe1H);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Axe2H);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Bows);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Guns);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Mace1H);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Mace2H);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Polearm);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Sword1H);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Sword2H);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Staff);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Unarmed);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Generic);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Dagger);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Thrown);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Crossbow);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Wand);
	weaponsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Fishingpole);
end

do -- Armor
	local MiscArmorInventoryTypes = {
		Enum.InventoryType.IndexHeadType,
		Enum.InventoryType.IndexNeckType,
		Enum.InventoryType.IndexBodyType,
		Enum.InventoryType.IndexFingerType,
		Enum.InventoryType.IndexTrinketType,
		Enum.InventoryType.IndexHoldableType,
	};

	local ClothArmorInventoryTypes = {
		Enum.InventoryType.IndexHeadType,
		Enum.InventoryType.IndexShoulderType,
		Enum.InventoryType.IndexChestType,
		Enum.InventoryType.IndexWaistType,
		Enum.InventoryType.IndexLegsType,
		Enum.InventoryType.IndexFeetType,
		Enum.InventoryType.IndexWristType,
		Enum.InventoryType.IndexHandType,
		Enum.InventoryType.IndexCloakType, -- Only for Cloth.
	};

	local ArmorInventoryTypes = {
		Enum.InventoryType.IndexHeadType,
		Enum.InventoryType.IndexShoulderType,
		Enum.InventoryType.IndexChestType,
		Enum.InventoryType.IndexWaistType,
		Enum.InventoryType.IndexLegsType,
		Enum.InventoryType.IndexFeetType,
		Enum.InventoryType.IndexWristType,
		Enum.InventoryType.IndexHandType,
	};

	local armorCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_ARMOR);

	local miscCategory = armorCategory:CreateSubCategory(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Generic);
	miscCategory:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Generic, MiscArmorInventoryTypes);

	local clothCategory = armorCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Cloth);
	clothCategory:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Cloth, ClothArmorInventoryTypes);

	local clothChestCategory = clothCategory:FindSubCategoryByName(C_Item.GetItemInventorySlotInfo(Enum.InventoryType.IndexChestType));
	clothChestCategory:AddFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Cloth, Enum.InventoryType.IndexRobeType);

	local leatherCategory = armorCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Leather);
	leatherCategory:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Leather, ArmorInventoryTypes);

	local leatherChestCategory = leatherCategory:FindSubCategoryByName(C_Item.GetItemInventorySlotInfo(Enum.InventoryType.IndexChestType));
	leatherChestCategory:AddFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Leather, Enum.InventoryType.IndexRobeType);

	local mailCategory = armorCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Mail);
	mailCategory:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Mail, ArmorInventoryTypes);

	local mailChestCategory = mailCategory:FindSubCategoryByName(C_Item.GetItemInventorySlotInfo(Enum.InventoryType.IndexChestType));
	mailChestCategory:AddFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Mail, Enum.InventoryType.IndexRobeType);

	local plateCategory = armorCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Plate);
	plateCategory:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Plate, ArmorInventoryTypes);

	local plateChestCategory = plateCategory:FindSubCategoryByName(C_Item.GetItemInventorySlotInfo(Enum.InventoryType.IndexChestType));
	plateChestCategory:AddFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Plate, Enum.InventoryType.IndexRobeType);

	armorCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Shield);
	if ClassicExpansionAtLeast(LE_EXPANSION_CATACLYSM) then
		armorCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Relic);
	else
		armorCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Libram);
		armorCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Idol);
		armorCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Totem);
	end
end

do -- Containers
	local containersCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_CONTAINERS);
	--containersCategory:SetDetailColumnString(SLOT_ABBR);
	containersCategory:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Container);
end

do -- Consumables (SubClasses Added in TBC)
	local consumablesCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_CONSUMABLES);
	if ClassicExpansionAtLeast(LE_EXPANSION_BURNING_CRUSADE) and HasValidSubClasses(Enum.ItemClass.Consumable) then
		consumablesCategory:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Consumable);
	else
		consumablesCategory:AddFilter(Enum.ItemClass.Consumable);
	end
end

do -- Glyphs (Added in Wrath)
	if ClassicExpansionAtLeast(LE_EXPANSION_WRATH_OF_THE_LICH_KING) then
		local glyphsCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_GLYPHS);
		glyphsCategory:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Glyph);
	end
end

do -- Trade Goods (SubClasses Added in TBC)
	local tradeGoodsCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_TRADE_GOODS);
	if ClassicExpansionAtLeast(LE_EXPANSION_BURNING_CRUSADE) and HasValidSubClasses(Enum.ItemClass.Tradegoods)then
		tradeGoodsCategory:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Tradegoods);
	else
		tradeGoodsCategory:AddFilter(Enum.ItemClass.Tradegoods);
	end
end

do -- Projectile
	if ClassicExpansionAtMost(LE_EXPANSION_WRATH_OF_THE_LICH_KING) then
		local projectileCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_PROJECTILE);
		projectileCategory:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Projectile);
	end
end

do -- Quiver
	if ClassicExpansionAtMost(LE_EXPANSION_WRATH_OF_THE_LICH_KING) then
		local quiverCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_QUIVER);
		quiverCategory:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Quiver);
	end
end

do -- Recipes
	local recipesCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_RECIPES);
	if HasValidSubClasses(Enum.ItemClass.Recipe)then
		recipesCategory:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Recipe);
	else
		recipesCategory:AddFilter(Enum.ItemClass.Recipe);
	end
end

do -- Reagent (Changed to a ItemClass.Miscellaneous and other ClassIDs in TBC)
	if GetClassicExpansionLevel() == LE_EXPANSION_CLASSIC then
		local reagentCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_REAGENT);
		reagentCategory:AddFilter(Enum.ItemClass.Reagent);
	end
end

do -- Gems (Added in TBC)
	if ClassicExpansionAtLeast(LE_EXPANSION_BURNING_CRUSADE) then
		local gemsCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_GEMS);
		if HasValidSubClasses(Enum.ItemClass.Gem)then
			gemsCategory:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Gem);
		else
			gemsCategory:AddFilter(Enum.ItemClass.Gem);
		end
	end
end

do -- Miscellaneous (SubClasses Added in TBC)
	local miscellaneousCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_MISCELLANEOUS);
	miscellaneousCategory:AddFilter(Enum.ItemClass.Miscellaneous);
	if ClassicExpansionAtLeast(LE_EXPANSION_BURNING_CRUSADE) then
		miscellaneousCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.Junk);
		miscellaneousCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.Reagent);
		if not ClassicExpansionAtLeast(LE_EXPANSION_MISTS_OF_PANDARIA) then
			miscellaneousCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.CompanionPet);
		end
		miscellaneousCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.Holiday);
		miscellaneousCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.Other);
		miscellaneousCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.Mount);
	end
end

do -- Quest Items (Added in TBC)
	if ClassicExpansionAtLeast(LE_EXPANSION_BURNING_CRUSADE) then
		local questItemsCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_QUEST_ITEMS);
		questItemsCategory:AddFilter(Enum.ItemClass.Questitem);
	end
end

do -- Battle Pets (Added in MoP)
	if ClassicExpansionAtLeast(LE_EXPANSION_MISTS_OF_PANDARIA) then
		local battlePetsCategory = AuctionFrame_CreateCategory(AUCTION_CATEGORY_BATTLE_PETS);
		battlePetsCategory:AddFilter(Enum.ItemClass.Battlepet);
		battlePetsCategory:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Battlepet);
		battlePetsCategory:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.CompanionPet);
	end
end

do -- WoW Token
	local wowTokenCategory = AuctionFrame_CreateCategory(TOKEN_FILTER_LABEL);
	wowTokenCategory:AddFilter(ITEM_CLASS_WOW_TOKEN);
	wowTokenCategory:SetFlag("WOW_TOKEN_FLAG");
end
