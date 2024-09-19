--
-- OSL commands:
-- gather - Gathers the currently listed crafting orders and puts them in the buy list (Must have crafting orders open)
-- search - Searches for the buy list on the AH (Must have AH open)
-- print  - prints the buy list and quantity
function OrderShoppingList_OnLoad()
    SLASH_ORDERSHOPPINGLIST1 = "/osl";
    SlashCmdList["ORDERSHOPPINGLIST"] = OrderShoppingList_SlashCommand;

    print("done")
end

buttonCache = {}
needsRetry = false
ReagentsFromCraftingOrder = {}

local function OnEvent(self, event, w)

    if event == "AUCTION_HOUSE_SHOW" then
        AttachShopButtonToAH()
    end

    if event == "TRADE_SKILL_SHOW" then

        if ProfessionsFrame == nil then
            do
                return
            end
        end

        local f = CreateFrame("Frame", "shoppingAttach",
            ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm)

        f:SetScript("OnShow", function(self, b, d)
            AttachButtonsToReagents()
            -- Sometimes things don't quite render properly on the first try, so we will force a retry on the next update
            needsRetry = true
        end)

        f:SetScript("OnUpdate", function(self, elapsed)
            if (needsRetry) then
                AttachButtonsToReagents()
            end

        end)

        -- if ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm:IsVisible() then 
        --     -- attach stuff

        -- end 

        if ProfessionsFrame.CraftingPage.SchematicForm.Reagents.labelText then
            -- print("Reagents here!!!")
        end

    end

end

function AttachButtonsToReagents()
    -- Hide all the previous buttons we created
    for _, cacheButton in pairs(buttonCache) do
        cacheButton:Hide()
    end
    ReagentsFromCraftingOrder = ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm.Reagents
    for i, reagent in pairs(
        ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm.Reagents:GetLayoutChildren()) do
        if (reagent:GetObjectType() == "Frame") then
            if (reagent.Button == nil or not reagent.Button:IsVisible()) then

                needsRetry = true
                do
                    return
                end
            end

            AttachButtonToReagent(reagent, reagent.Button.item, reagent.Button.itemLink)
        end
    end
    print("no retry")
    needsRetry = false
end

local f = CreateFrame("Frame", "ShoppingListEventViewer")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:RegisterEvent("UPDATE_UI_WIDGET")
f:RegisterEvent("TRADE_SKILL_SHOW")
f:SetScript("OnEvent", OnEvent)

local function SearchAH()

    itemIDs = {}
    sorts = {
        sortOrder = 1,
        reverseSort = false
    }

    for id, itemID in pairs(ShoppingList) do
        table.insert(itemIDs, {
            itemID = itemID
        })
        print(itemID)
    end

    print(itemIDs)
    C_AuctionHouse.SearchForItemKeys(itemIDs, sorts)

end

local function UpdateShoppingListText() 
    local output = ""
    local eb = ShoppingTextBox
    for i, listItem in pairs(ListDisplay) do
        output = output .. listItem.link .. "x" .. listItem.qty .. "\n"
    end

    eb:SetText(output)

end 

local function MoveShoppingListFrame() 

    local parent = ProfessionsFrame

    if (parent == nil or not parent:IsVisible()) then
        parent = AuctionHouseFrame
    end

    if (parent ~= nil and parent:IsVisible())  then
        shoppingListFrame:SetPoint("TOPLEFT", parent, "TOPRIGHT")
    else
        shoppingListFrame:SetPoint("TOPLEFT", 0, -200)
end

end 

local function ShowShoppingList()
    if (shoppingListFrame ~= nil) then
        MoveShoppingListFrame()
        shoppingListFrame:Show()
        do return end
    end
    shoppingListFrame = CreateFrame("Frame", "ShoppingListFrame", UIParent, "BasicFrameTemplateWithInset")
    tex = shoppingListFrame:CreateTexture(nil, "BACKGROUND")

    shoppingListFrame:SetFrameStrata("MEDIUM")
    shoppingListFrame:SetWidth(400)
    shoppingListFrame:SetHeight(600)
    shoppingListFrame.texture = tex
    tex:SetAllPoints(true)
    shoppingListFrame.title = shoppingListFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

    shoppingListFrame.title:SetPoint("LEFT", shoppingListFrame.TitleBg, "LEFT", 5, 0)
    shoppingListFrame.title:SetText("Shopping list")

    MoveShoppingListFrame()
    
    shoppingListFrame:SetMovable(true)
    shoppingListFrame:EnableMouse(true)

    shoppingListFrame:RegisterForDrag("LeftButton")
    shoppingListFrame:SetScript("OnDragStart", function(self)
        self:StartMoving();

    end)
    shoppingListFrame:SetScript("OnDragStop", function(self)
        shoppingListFrame:StopMovingOrSizing();
    end)
    shoppingListFrame:Show()

    local sf = CreateFrame("ScrollFrame", "ShoppingScrollFrame", shoppingListFrame, "UIPanelScrollFrameTemplate")
    sf:SetSize(shoppingListFrame:GetSize())
    sf:SetPoint("LEFT", 12, 0)
    sf:SetPoint("RIGHT", 0, 0)
    sf:SetPoint("TOP", -32, -32)
    sf:SetPoint("BOTTOM", 0, 10)

    -- EditBox
    local eb = CreateFrame("EditBox", "ShoppingTextBox", ShoppingScrollFrame)
    eb:SetSize(sf:GetSize())
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false) -- dont automatically focus
    eb:SetFontObject("ChatFontNormal")
    eb:SetScript("OnEscapePressed", function()
        f:Hide()
    end)
    sf:SetScrollChild(eb)

    local clearButton = CreateButton("ShoppingListClearButton", ShoppingListFrame)
    
    clearButton:SetPoint("RIGHT", ShoppingListFrame, "TOPRIGHT", -30, -9)
    clearButton:SetWidth(80)
    clearButton:SetHeight(18)

    clearButton:SetText("Clear!")
    clearButton:SetScript("OnClick", function(self, b, d)
        ShoppingList = {}
        ListDisplay = {}
        UpdateShoppingListText()
    end)
    UpdateShoppingListText()

end

local function IncrementShoppingListItem(itemID, itemLink, qty) 
    if ShoppingList == nil then
        ShoppingList = {}
    end

    if ListDisplay == nil then
        ListDisplay = {}
    end

    if qty == nil then
        qty = 1
    end 
    -- Essentially a no-op if it is already in the shopping list
    ShoppingList[itemID] = itemID
    local currentQty = 0
    if ListDisplay[itemID] ~= nil then
        currentQty = ListDisplay[itemID].qty
    end

    currentQty = currentQty + qty

    ListDisplay[itemID] = {
        link = itemLink,
        qty = currentQty
    }
end 


local function GatherOrders()

    if ShoppingList == nil then
        ShoppingList = {}
    end

    if ListDisplay == nil then
        ListDisplay = {}
    end

    local orders = C_CraftingOrders.GetCrafterOrders()
    for _, order in pairs(orders) do
        -- print( TSM_API.GetItemLink("i:" .. order.itemID))
        local recipeInfo = C_TradeSkillUI.GetRecipeInfoForSkillLineAbility(order.skillLineAbilityID)
        -- print (recipeInfo.hyperlink)
        -- print(recipeInfo.recipeID)
        local schematic = C_TradeSkillUI.GetRecipeSchematic(order.spellID, false)

        for _, reagentSlotSchematic in pairs(schematic.reagentSlotSchematics) do
            if reagentSlotSchematic.reagentType == 1 then
                for i, reagent in pairs(reagentSlotSchematic.reagents) do

                    ShoppingList[reagent.itemID] = reagent.itemID

                    if i == 1 then

                        local currentQty = 0

                        if ListDisplay[reagent.itemID] ~= nil then
                            currentQty = ListDisplay[reagent.itemID].qty
                        end

                        currentQty = currentQty + reagentSlotSchematic.quantityRequired

                        ListDisplay[reagent.itemID] = {
                            link = TSM_API.GetItemLink("i:" .. reagent.itemID),
                            qty = currentQty
                        }

                        print(TSM_API.GetItemLink("i:" .. reagent.itemID) .. "x" ..
                                  reagentSlotSchematic.quantityRequired)

                    end
                end
            end
        end
    end

end

function OrderShoppingList_SlashCommand(args)

    if args == "gather" then
        GatherOrders()
    elseif args == "search" then
        SearchAH()
    elseif args == "" then
        ShowShoppingList()    
    
    end

end

offset = 15

function AttachButtonToReagent(reagentFrame, itemID, itemLink)
    if (reagentFrame == nil or itemID == nil) then
        do
            return
        end
    end

    itemName, itemLinkFromCall, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
    itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType,
    expacID, setID, isCraftingReagent
        = GetItemInfo(itemID) 

    -- Don't attach buttons to soulbound stuff.
    if (bindType == 1) then
        do return end
    end

    local button = nil
    if (reagentFrame.hasShopButton == nil) then
        button = CreateButton(nil, reagentFrame)
        table.insert(buttonCache, button)
    else
        button = reagentFrame.ShopButton
        button:Show()
    end

    button:SetPoint("RIGHT", reagentFrame, "RIGHT", offset, 0)
    button:SetWidth(20)
    button:SetHeight(18)

    button:SetText("+")

  
    button:SetScript("OnClick", function(self, b, d)
        for x,y in pairs(reagentFrame.reagentSlotSchematic.reagents) do
            _, innerLink = GetItemInfo(y.itemID) 
            IncrementShoppingListItem(y.itemID, innerLink)
        end
        
        if (ShoppingListFrame == nil or ShoppingListFrame:IsVisible() == false ) then
            ShowShoppingList()
        end 
        UpdateShoppingListText()
    end)
    reagentFrame.hasShopButton = true
    reagentFrame.ShopButton = button

end

function CreateButton(name, parent) 
    local button = CreateFrame("Button", name, parent)
    button:SetNormalFontObject("GameFontNormal")

    local ntex = button:CreateTexture()
    ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
    ntex:SetTexCoord(0, 0.625, 0, 0.6875)
    ntex:SetAllPoints()
    button:SetNormalTexture(ntex)

    local htex = button:CreateTexture()
    htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
    htex:SetTexCoord(0, 0.625, 0, 0.6875)
    htex:SetAllPoints()
    button:SetHighlightTexture(htex)

    local ptex = button:CreateTexture()
    ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
    ptex:SetTexCoord(0, 0.625, 0, 0.6875)
    ptex:SetAllPoints()
    button:SetPushedTexture(ptex)

    return button
end 

function AttachShopButtonToAH()

    local button = CreateButton("ShopButton", AuctionHouseFrame.TitleContainer)
    button:SetPoint("RIGHT", AuctionHouseFrame.TitleContainer, "RIGHT", -20, 0)
    button:SetWidth(100)
    button:SetHeight(18)

    button:SetText("Shop")

    button:SetScript("OnClick", function(self, b, d)
        SearchAH()
        ShowShoppingList()

    end)

end
