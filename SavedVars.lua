

local addonName, addon = ...;

local SavedVars = {}

local Defaults = {
    playQuestNpcAnimations = true,
    speakQuestText = true,
    showBestVendorReward = true,
}


function SavedVars:Init(reset)
    if (reset) then
        ForeverGossipAccount = nil;
    end
    if (ForeverGossipAccount == nil) then
        ForeverGossipAccount = {};
    end
    self.db = ForeverGossipAccount;
    for k, v in pairs(Defaults) do
        self.db[k] = v;
    end
end

function SavedVars:Set(key, val)
    if (self.db) then
        self.db[key] = val;
    end
end

function SavedVars:Get(key)
    if (self.db) then
        if (self.db[key] ~= nil) then
            return self.db[key];
        else
            error(string.format("[%s] '%s' doesn't exist in saved vars db!", addonName, key));
        end
    end
end


addon.SavedVars = SavedVars;