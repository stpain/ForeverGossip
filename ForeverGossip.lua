

local addonName, addon = ...;

local SavedVars = addon.SavedVars;

-- local function ScanTooltipbyLink(link)
--     ForeverGossipScanningTooltip:ClearLines()
--     ForeverGossipScanningTooltip:SetHyperlink(link)
--     local textLines = {}
--     local regions = {ForeverGossipScanningTooltip:GetRegions()}
--     for _, r in ipairs(regions) do
--         if r:IsObjectType("FontString") then
--         table.insert(textLines, r:GetText())
--         end
--     end
--     return textLines
-- end


--[[
    This is a basic function to allign object vertically
    used for the quest rewards stuff
]]
local function AllignRewards(parent, layout)
    for _, obj in ipairs(layout) do
        obj.region:ClearAllPoints();
    end
    layout[1].region:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0);
    layout[1].region:Show();
    if (#layout > 1) then
        for i = 2, #layout do
            layout[i].region:SetPoint("TOPLEFT", layout[i-1].region, "BOTTOMLEFT", layout[i].x, layout[i].y);
            layout[i].region:Show();
        end
    end
end


ForeverGossipMixin = {}

function ForeverGossipMixin:OnLoad()

    self:RegisterForDrag("LeftButton");
    
    self:RegisterEvent("PLAYER_ENTERING_WORLD");

    self:RegisterEvent("GOSSIP_SHOW");
    self:RegisterEvent("GOSSIP_CLOSED");
    
    self:RegisterEvent("QUEST_GREETING");
    self:RegisterEvent("QUEST_ACCEPTED");
    self:RegisterEvent("QUEST_DETAIL");
    self:RegisterEvent("QUEST_PROGRESS");
    self:RegisterEvent("QUEST_FINISHED");
    self:RegisterEvent("QUEST_COMPLETE");

    --self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW");

    local ButtonResetFunc = function(pool, button)
        button.Text:SetText("");
        button.Icon:SetTexture(nil);
        button:SetScript("OnClick", nil);
        button:ClearAllPoints();
        button:Hide();
    end
    local QuestRewardItemButtonResetFunc = function(pool, button)
        button.type = nil;
        button.objectType = nil;
        button.Icon:SetTexture(nil);
        button:ClearAllPoints();
        button:Hide();
        ForeverGossipQuestInfoItemHighlight:ClearAllPoints();
        ForeverGossipQuestInfoItemHighlight:Hide();
        SetItemButtonTextureVertexColor(button, 1.0, 1.0, 1.0);
        SetItemButtonNameFrameVertexColor(button, 1.0, 1.0, 1.0);
        SetItemButtonQuality(button, nil, nil);
        SetItemButtonCount(button, nil);
    end

    self.gossipHistory = {};

    self.GossipOptionButtonPool = CreateFramePool("Button", self.GossipParent, "ForeverGossipOptionTemplate", ButtonResetFunc)
    self.QuestRewardButtonPool = CreateFramePool("Button", self, "LargeQuestRewardItemButtonTemplate", QuestRewardItemButtonResetFunc)

    self.Model:SetPortraitZoom(-0.12);
    self.Model:SetPosition(0, 0.40, 0);
    self.Model:SetRotation(-0.45);


    QuestFrame:HookScript("OnHide", function()
        self:ValidateClose();
    end)

    local function IsSelected(option)
        return SavedVars:Get(option);
    end

    local function SetSelected(option)
        local currentOption = SavedVars:Get(option);
        SavedVars:Set(option, not option);
    end

    self.Options:SetScript("OnClick", function()
        local menu = MenuUtil.CreateContextMenu(self.Options, function(_, rootDescription)
            rootDescription:CreateTitle(OPTIONS);
            rootDescription:CreateDivider();

            rootDescription:CreateCheckbox("Speak Quest Text", IsSelected, SetSelected, "speakQuestText")
        end)
    end)

    --self.AvailableQuestParent.QuestDescriptionText.ScrollBox.lowerShadow = "AftLevelup-GlowLine";
end

function ForeverGossipMixin:PLAYER_ENTERING_WORLD(...)
    local isInitial, isReload = ...;

    if (isInitial or isReload) then
        SavedVars:Init()
    end

end

function ForeverGossipMixin:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...);
    end
end

function ForeverGossipMixin:GOSSIP_SHOW(...)
    self.allowClose = false;
    self:LoadGossip();
end
function ForeverGossipMixin:GOSSIP_CLOSED(...)
    self.allowClose = true;
    self:ValidateClose();
end

function ForeverGossipMixin:ValidateClose()
    if (GetNumAvailableQuests() > 0) then
        self:LoadQuestGiver();
        return;
    end
    if (self.allowClose) then
        self:Hide();
        return;
    end
    if (QuestFrame:IsShown() == false) and (GossipFrame:IsShown() == false) then
        self:Hide();
    end
end

function ForeverGossipMixin:Clear()
    self.GossipOptionButtonPool:ReleaseAll();
    self.QuestRewardButtonPool:ReleaseAll();
    self.GossipParent:Hide();
    self.AvailableQuestParent:Hide();
    self.ActiveQuestParent:Hide();
    self.CompleteQuestParent:Hide();
    QuestRewardsContainer:Hide();
    ForeverGossipGoldCoinIcon:SetParent(UIParent);
    ForeverGossipGoldCoinIcon:ClearAllPoints();
    ForeverGossipGoldCoinIcon:Hide();
end

-- function ForeverGossipMixin:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(...)
--     self:Hide();
-- end
-- function ForeverGossipMixin:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(...)
--     local arg = ...;
--     if (npcInteractions[arg] == true) then
--         self.interaction = arg;
--         self:Show();
--     end
-- end

function ForeverGossipMixin:QUEST_PROGRESS()
    self:LoadActiveQuest();
end

function ForeverGossipMixin:QUEST_ACCEPTED(...)
    self:ValidateClose();
end

function ForeverGossipMixin:QUEST_FINISHED()
    self:ValidateClose();
end

function ForeverGossipMixin:QUEST_COMPLETE()
    self:LoadCompleteQuest();
end

function ForeverGossipMixin:QUEST_GREETING()
    self:LoadQuestGiver();
end

function ForeverGossipMixin:QUEST_DETAIL(...)
    local questStartItemID = ...;
    local questID = GetQuestID();
    if (questStartItemID == 0) then
        self:LoadAvailableQuest();
        --print("event")
    end
end

function ForeverGossipMixin:OnShow()
    self.Model:SetUnit("target");
    --self.TitleText:SetText(UnitName("target"));

    local function PlayAnimation()
        self.Model:SetAnimation(60);
    end

    if (self.Model:HasAnimation(67)) then
        self.Model:SetAnimation(67);
    end

    local delay = math.random(2,5);
    C_Timer.After(delay, PlayAnimation)

    -- self.Model:SetScript("OnAnimFinished", function()
    --     print("anim finished")
    --     local delay = math.random(2,5);
    --     C_Timer.After(delay, PlayAnimation)
    -- end)
end

function ForeverGossipMixin:OnHide()
    self.Model:SetUnit("player");
    self:Clear();
end


function ForeverGossipMixin:SpeakText(text)
    if (SavedVars:Get("speakQuestText") == true) then
        C_VoiceChat.SpeakText(1, text, 1, 80);
    end
end


function ForeverGossipMixin:Gossip_InitAvailableQuestButton(button, quest)
    button.Text:SetText(quest.title);
    button.Icon:SetAtlas("QuestNormal");
    button:SetScript("OnClick", function()
        C_GossipInfo.SelectAvailableQuest(quest.questID);
        --self:LoadAvailableQuest(quest);
        --print("gossip option click")
    end)
    button:Show();
end

function ForeverGossipMixin:Gossip_InitActiveQuestButton(button, quest)
    button.Text:SetText(quest.title);
    button.Icon:SetAtlas("QuestTurnin");
    button:SetScript("OnClick", function()
        C_GossipInfo.SelectActiveQuest(quest.questID);
    end)
    button:Show();
end

function ForeverGossipMixin:Gossip_InitOptionButton(button, gossip)
    button.Text:SetText(gossip.name);
    button.Icon:SetTexture(gossip.icon);
    button:SetScript("OnClick", function()
        C_GossipInfo.SelectOption(gossip.gossipOptionID)
    end)
    button:Show();
end

function ForeverGossipMixin:QuestGiver_InitActiveQuestButton(button, title, isComplete)
    button.Text:SetText(title);
    if (isComplete) then
        button.Icon:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon");
    else
        button.Icon:SetTexture("Interface\\GossipFrame\\IncompleteQuestIcon");
    end
    button:SetScript("OnClick", function()
        SelectActiveQuest(button:GetID());
    end)
    button:Show();
end

function ForeverGossipMixin:QuestGiver_InitAvailableQuestButton(button, title)
    button.Text:SetText(title);
    button.Icon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon");
    button:SetScript("OnClick", function()
        SelectAvailableQuest(button:GetID());
    end)
    button:Show();
end

function ForeverGossipMixin:LoadGossip()

    self.allowClose = false;

    self:Clear();
    self.GossipParent:Show();

    self.GreetingText:SetFontObject("GameFontNormal");
    local greeting = C_GossipInfo.GetText();
    self.GreetingText:SetText(greeting);

    local gossipOptions = C_GossipInfo.GetOptions();
    local availableQuests = C_GossipInfo.GetAvailableQuests();
    local activeQuests = C_GossipInfo.GetActiveQuests();

    if (#gossipOptions + #availableQuests + #activeQuests) == 0 then

    else

    end

    table.sort(gossipOptions, function(a, b)
        return a.orderIndex < b.orderIndex;
    end)

    local lastButton = nil;
    local offsetX, offsetY = 60, -5;

    if (#availableQuests > 0) then
        for _, quest in ipairs(availableQuests) do
            
            local button = self.GossipOptionButtonPool:Acquire();
            button:SetParent(self.GossipParent);
            self:Gossip_InitAvailableQuestButton(button, quest);

            if (lastButton == nil) then
                button:SetPoint("TOPLEFT", offsetX, offsetY);
                lastButton = button;
            else
                button:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -5);
                lastButton = button;
            end

        end
    end

    if (#activeQuests > 0) then
        for _, quest in ipairs(activeQuests) do
            
            local button = self.GossipOptionButtonPool:Acquire();
            button:SetParent(self.GossipParent);
            self:Gossip_InitActiveQuestButton(button, quest);

            if (lastButton == nil) then
                button:SetPoint("TOPLEFT", offsetX, offsetY);
                lastButton = button;
            else
                button:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -5);
                lastButton = button;
            end

        end
    end

    if (#gossipOptions > 0) then
        for _, gossip in ipairs(gossipOptions) do
            
            local button = self.GossipOptionButtonPool:Acquire();
            button:SetParent(self.GossipParent);
            self:Gossip_InitOptionButton(button, gossip);

            if (lastButton == nil) then
                button:SetPoint("TOPLEFT", offsetX, offsetY);
                lastButton = button;
            else
                button:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -5);
                lastButton = button;
            end
            
        end
    end

    self:Show();

end

function ForeverGossipMixin:LoadRewards(parent, anchor, offsetY, isSelectable)

    QuestRewardsContainer:SetParent(parent);
    QuestRewardsContainer:ClearAllPoints();
    QuestRewardsContainer:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, offsetY);

    local numQuestRewards = GetNumQuestRewards();
	local numQuestChoices = GetNumQuestChoices();
	-- local spellRewards = C_QuestInfoSystem.GetQuestRewardSpells(questID) or {};
	-- local numQuestSpellRewards = #spellRewards;
	local money = GetRewardMoney();
	local honor = GetRewardHonor();
    local xp = GetRewardXP();
	local playerTitle = GetRewardTitle();

    local xpHeader = QuestRewardsContainer.ExperienceRewardsHeader;
    local moneyHeader = QuestRewardsContainer.MoneyRewardsHeader;
    local questRewardHeader = QuestRewardsContainer.RewardsHeader;
    local choiceRewardHeader = QuestRewardsContainer.ChoiceRewardsHeader;

    xpHeader:Hide();
    moneyHeader:Hide();
    questRewardHeader:Hide();
    choiceRewardHeader:Hide();

    questRewardHeader:SetText(REWARD_ITEMS_ONLY);

    if (xp > 0) then
        --xpHeader:SetText(CreateAtlasMarkup("GarrMission_CurrencyIcon-Xp", 48, 48).." "..EXPERIENCE_COLON.." "..xp);
        xpHeader:SetText(EXPERIENCE_COLON.." "..xp);
    end

    if (money > 0) then
        QuestRewardsContainer.QuestMoneyReward:SetAmount(money);
        QuestRewardsContainer.QuestMoneyReward:Show();
        moneyHeader:Show();
    else
        QuestRewardsContainer.QuestMoneyReward:Hide();
        moneyHeader:Hide();
    end

    --[[
        When the addon is released, the default quest frame will just be hidden off screen
        an advantage to this is that we can piggy back on a lot of blizz code where they
        set values on the frame
    ]]
    QuestInfoFrame.itemChoice = 0;
    ForeverGossipQuestInfoItemHighlight:ClearAllPoints();
    ForeverGossipQuestInfoItemHighlight:Hide();


    local regions = {};

    --[[
        if there is a choice reward list it first

        then check for money > xp > given rewards
    ]]
    if (numQuestChoices > 0) then
        choiceRewardHeader:SetText(REWARD_CHOOSE);
        table.insert(regions, {region = choiceRewardHeader, x = 0, y = 0});
    else
        if (money > 0) then
            table.insert(regions, {region = moneyHeader, x = 0, y = 0});
        else
            if (xp > 0) or (numQuestChoices > 0) or (numQuestRewards > 0) then
                table.insert(regions, {region = questRewardHeader, x = 0, y = -6});
            end
        end

        if (xp > 0) then
            table.insert(regions, {region = xpHeader, x = 0, y = -6});
        end
    end


    local function GetRewardButton(_type, objectType, isUsable, quality, name, texture, id, link, numItems)
        local button = self.QuestRewardButtonPool:Acquire();
        button.type = _type;
        button.objectType = objectType;

        button:SetID(id);
        button.Icon:SetTexture(texture);
        button.Name:SetText(name);

        SetItemButtonQuality(button, quality, link);
        SetItemButtonCount(button, numItems);
        if ( isUsable ) then
            SetItemButtonTextureVertexColor(button, 1.0, 1.0, 1.0);
            SetItemButtonNameFrameVertexColor(button, 1.0, 1.0, 1.0);
        else
            SetItemButtonTextureVertexColor(button, 0.9, 0, 0);
            SetItemButtonNameFrameVertexColor(button, 0.9, 0, 0);
        end

        button:SetScript("OnClick", function()
            if ( IsModifiedClick() and button.objectType == "item") then
                HandleModifiedItemClick(GetQuestItemLink(button.type, button:GetID()));
                -- if ( QuestInfoFrame.questLog ) then
                --     HandleModifiedItemClick(GetQuestLogItemLink(button.type, button:GetID()));
                -- else
                --     HandleModifiedItemClick(GetQuestItemLink(button.type, button:GetID()));
                -- end
            else
                -- if ( QuestInfoFrame.chooseItems ) then
                --     QuestInfoItem_OnClick(button);
                -- end
                if isSelectable and ( button.type == "choice" ) then
                    ForeverGossipQuestInfoItemHighlight:SetParent(button);
                    ForeverGossipQuestInfoItemHighlight:Raise();
                    ForeverGossipQuestInfoItemHighlight:SetPoint("TOPLEFT", -8, 7);
                    ForeverGossipQuestInfoItemHighlight:Show();

                    QuestInfoFrame.itemChoice = button:GetID();
                end
            end
        end)

        return button;
    end

    local bestCopper = 0;
    local vendorRewardButton;

    local lastButton, firstButton;
    local index = 1;
    if (numQuestChoices > 0) then
        for i = 1, numQuestChoices do
            local name, texture, numItems, quality, isUsable = GetQuestItemInfo("choice", i);
            local link = GetQuestItemLink("choice", i)
            
            local button = GetRewardButton("choice", "item", isUsable, quality, name, texture, i, link, numItems)
            
            local sellPrice = select(11, C_Item.GetItemInfo(link));
            if (sellPrice > bestCopper) then
                bestCopper = sellPrice;
                vendorRewardButton = button;
                --print("found better vendor item", link);
            end
            
            if (lastButton == nil) then
                button:SetPoint("TOPLEFT", choiceRewardHeader, "BOTTOMLEFT", 0, -2);
                lastButton = button;
                firstButton = button;

            else
                if (index == 5) then
                    button:SetPoint("TOPLEFT", firstButton, "BOTTOMLEFT", 0, -2);
                    lastButton = button;
                    firstButton = button;
                    index = 1;
                else
                    button:SetPoint("LEFT", lastButton, "RIGHT", 2, 0);
                    lastButton = button;
                end
            end

            index = index + 1;

            button:Show();
        end

        local offsetY = (math.ceil(numQuestChoices / 4) * 41) + 16;

        if (money > 0) then
            questRewardHeader:SetText(REWARD_ITEMS);
            if (numQuestChoices > 0) then
                table.insert(regions, {region = moneyHeader, x = 0, y = -offsetY});
            end
        else
            if (xp > 0) or (numQuestChoices > 0) or (numQuestRewards > 0) then
                questRewardHeader:SetText(REWARD_ITEMS);
                table.insert(regions, {region = questRewardHeader, x = 0, y = -offsetY});
            end
        end

        if (xp > 0) then
            table.insert(regions, {region = xpHeader, x = 0, y = -6});
        end
    end

    if (bestCopper > 0) then
        ForeverGossipGoldCoinIcon:SetParent(vendorRewardButton);
        ForeverGossipGoldCoinIcon:SetFrameLevel(vendorRewardButton:GetFrameLevel() + 99);
        ForeverGossipGoldCoinIcon:Raise();
        --ForeverGossipGoldCoinIcon.Icon:SetTexture(237281);
        ForeverGossipGoldCoinIcon:SetPoint("BOTTOMRIGHT", vendorRewardButton, "BOTTOMRIGHT", -4, 4);
        ForeverGossipGoldCoinIcon:Show();
    end


    if (numQuestRewards > 0) then
        lastButton = nil;
        index = 1;
        for i = 1, numQuestRewards do
            local name, texture, numItems, quality, isUsable = GetQuestItemInfo("reward", i);
            local link = GetQuestItemLink("reward", i)
            local button = GetRewardButton("reward", "item", isUsable, quality, name, texture, i, link)
            
            if (lastButton == nil) then
                -- local offsetY = 8;
                -- if (xp > 0) then
                --     offsetY = offsetY + 16;
                -- end
                -- if (money > 0) then
                --     offsetY = offsetY + 16;
                -- end

                if (numQuestChoices == 0) then
                    --button:SetPoint("TOPLEFT", 0, -offsetY);
                    table.insert(regions, {region = button, x = 0, y = -6});
                elseif (numQuestChoices > 0) then
                    button:SetPoint("TOPLEFT", questRewardHeader, "BOTTOMLEFT", 0, -6);
                end

                lastButton = button;
                firstButton = button;
            else
                if (index == 5) then
                    button:SetPoint("TOPLEFT", firstButton, "BOTTOMLEFT", 0, -2);
                    lastButton = button;
                    firstButton = button;
                    index = 1;
                else
                    button:SetPoint("LEFT", lastButton, "RIGHT", 2, 0);
                    lastButton = button;
                end
            end

            index = index + 1;

            button:Show();
        end
    end

    if (#regions > 0) then
        AllignRewards(QuestRewardsContainer, regions);
    end

    QuestRewardsContainer:Show();
end

function ForeverGossipMixin:LoadQuestGiver()

    self.allowClose = false;
    
    self:Clear();
    self.QuestGiverParent:Show();
    
    self.GreetingText:SetFontObject("GameFontNormal");
    self.GreetingText:SetText(GetGreetingText());

	local numActiveQuests = GetNumActiveQuests();
	local numAvailableQuests = GetNumAvailableQuests();

    local lastButton;
    if (numActiveQuests > 0) then
        for i = 1, numActiveQuests do
            local title, isComplete = GetActiveTitle(i);

            local button = self.GossipOptionButtonPool:Acquire();
            button:SetID(i);
            button:SetParent(self.QuestGiverParent);
            self:QuestGiver_InitActiveQuestButton(button, title, isComplete); --QuestTitleButton_OnClick

            if (lastButton == nil) then
                button:SetPoint("TOPLEFT", self.QuestGiverParent, "TOPLEFT", 0, 0);
                lastButton = button;
            else
                button:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -5);
                lastButton = button;
            end
        end
    end

    if (numAvailableQuests > 0) then
        for i = (numActiveQuests + 1), (numActiveQuests + numAvailableQuests) do
            local indexOffset = (i - numActiveQuests)
            local isTrivial, isDaily, isRepeatable, isLegendary = GetAvailableQuestInfo(indexOffset);
            local title = GetAvailableTitle(indexOffset)
            local button = self.GossipOptionButtonPool:Acquire();
            
            button:SetID(indexOffset);
            button:SetParent(self.QuestGiverParent);
            self:QuestGiver_InitAvailableQuestButton(button, title); --QuestTitleButton_OnClick

            if (lastButton == nil) then
                button:SetPoint("TOPLEFT", self.QuestGiverParent, "TOPLEFT", 0, 0);
                lastButton = button;
            else
                button:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -5);
                lastButton = button;
            end
        end
    end

    self:Show();
end

function ForeverGossipMixin:LoadAvailableQuest(quest)

    self.allowClose = false;

    self:Clear();
    self.AvailableQuestParent:Show();


	local questID;
	if ( QuestInfoFrame.questLog ) then
		questID = GetQuestLogSelectedID();
	else
		questID = GetQuestID();
	end

    local questTitle;
	if ( QuestInfoFrame.questLog ) then
		questTitle = GetQuestLogTitle(GetQuestLogSelection());
		if ( not questTitle ) then
			questTitle = "";
		end
		if ( IsCurrentQuestFailed() ) then
			questTitle = questTitle.." - ("..FAILED..")";
		end
	else
		questTitle = GetTitleText();
	end
    self.GreetingText:SetFontObject("GameFontNormalHuge");
    self.GreetingText:SetText(questTitle);

	local questDescription = "";
	if ( QuestInfoFrame.questLog ) then
		questDescription = GetQuestLogQuestText();
	else
		questDescription = GetQuestText() or "";
	end
    self.AvailableQuestParent.QuestDescriptionText:SetText(questDescription);

    C_Timer.After(1, function()
        self:SpeakText(questDescription);
    end)

    local questDescriptionHeight = self.AvailableQuestParent.QuestDescriptionText:GetFontString():GetStringHeight();
    if (questDescriptionHeight > self.AvailableQuestParent.QuestDescriptionText:GetHeight()) then

    else

    end

    local questObjectives, _;
	if ( QuestInfoFrame.questLog ) then
		_, questObjectives = GetQuestLogQuestText();
	else
		questObjectives = GetObjectiveText();
	end
    self.AvailableQuestParent.QuestObjectiveText:SetText(questObjectives);


    self:LoadRewards(self.AvailableQuestParent, self.AvailableQuestParent.QuestObjectiveText, -16, false)
    
    self:Show();
end

function ForeverGossipMixin:LoadActiveQuest()

    self.allowClose = false;
    
    self:Clear();
    self.ActiveQuestParent:Show();

    self.GreetingText:SetFontObject("GameFontNormalHuge");
    self.GreetingText:SetText(GetTitleText());

    local text = GetProgressText();
    self.ActiveQuestParent.QuestProgressText:SetText(text);

    C_Timer.After(1, function()
        self:SpeakText(text);
    end)

	if ( IsQuestCompletable() ) then
		self.ActiveQuestParent.QuestFrameCompleteButton:Enable();
	else
		self.ActiveQuestParent.QuestFrameCompleteButton:Disable();
	end


	local numRequiredItems = GetNumQuestItems();
	local numRequiredCurrencies = 0;--GetNumQuestCurrencies();

	if ( numRequiredItems > 0 or GetQuestMoneyToGet() > 0 or numRequiredCurrencies > 0) then
        

		if ( GetQuestMoneyToGet() > 0 ) then
			MoneyFrame_Update("QuestProgressRequiredMoneyFrame", GetQuestMoneyToGet());

			if ( GetQuestMoneyToGet() > GetMoney() ) then
                
			end

        end


        local lastButton;

        if (numRequiredItems > 0) then
            for i = 1, numRequiredItems do
                local name, texture, numItems, quality, isUsable, itemID = GetQuestItemInfo("required", i);
                local link = GetQuestItemLink("required", i)
                local button = self.QuestRewardButtonPool:Acquire();
                button.type = "required";
                button.objectType = "item";

                button:SetID(i);
                SetItemButtonCount(button, numItems);
                SetItemButtonQuality(button, quality, link);

                button.Icon:SetTexture(texture);
                button.Name:SetText(name);

                button:Show();

                if (lastButton == nil) then
                    button:SetPoint("TOPLEFT", self.ActiveQuestParent.QuestRequiredItemsHeader, "BOTTOMLEFT", 0, -2);
                    lastButton = button;
                else
                    button:SetPoint("LEFT", lastButton, "RIGHT", 2, 0);
                    lastButton = button;
                end
            end
        end

		-- for i=1, numRequiredCurrencies do
		-- 	local requiredItem = _G[questItemName..buttonIndex];
		-- 	requiredItem.type = "required";
		-- 	requiredItem.objectType = "currency";
		-- 	requiredItem:SetID(i);
		-- 	local requiredCurrencyInfo = C_QuestOffer.GetQuestRequiredCurrencyInfo(i);
		-- 	if requiredCurrencyInfo then
		-- 		SetItemButtonCount(requiredItem, requiredCurrencyInfo.requiredAmount);
		-- 		SetItemButtonTexture(requiredItem, requiredCurrencyInfo.texture);
		-- 		requiredItem:Show();
		-- 		_G[questItemName..buttonIndex.."Name"]:SetText(requiredCurrencyInfo.name);
		-- 	end
		-- 	buttonIndex = buttonIndex+1;
		-- end

	end

    self:Show();
end

function ForeverGossipMixin:LoadCompleteQuest()

    self.allowClose = false;
    
    self:Clear();

    self.GreetingText:SetFontObject("GameFontNormalHuge");
    self.GreetingText:SetText(GetTitleText());

    self.CompleteQuestParent:Show();

    local text = GetRewardText();
    self.CompleteQuestParent.QuestRewardsText:SetText(text);

    C_Timer.After(1, function()
        self:SpeakText(text);
    end)

    self:LoadRewards(self.CompleteQuestParent, self.CompleteQuestParent.QuestRewardsText, -16, true)

    self:Show();

end
