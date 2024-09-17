--
-- OSL commands:
-- gather - Gathers the currently listed crafting orders and puts them in the buy list (Must have crafting orders open)
-- search - Searches for the buy list on the AH (Must have AH open)
-- print  - prints the buy list and quantity
function OrderShoppingList_OnLoad()
    SLASH_ORDERSHOPPINGLIST1= "/osl";
    SlashCmdList["ORDERSHOPPINGLIST"] = OrderShoppingList_SlashCommand;

    print ("done") 
end

local function OnEvent(self, event, w)
    
    if event == "AUCTION_HOUSE_SHOW" then
        CreateShoppingListUI()
    end

    if event == "UPDATE_UI_WIDGET" then
        if ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm:IsVisible() then 
            
        end 
    end



end


local f = CreateFrame("Frame", "ShoppingListEventViewer")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:RegisterEvent("UPDATE_UI_WIDGET")
f:SetScript("OnEvent", OnEvent)


local function SearchAH() 

    itemIDs = {}
    sorts = {sortOrder=1, reverseSort=false}
    
    for id, itemID in pairs(ShoppingList) do
        table.insert(itemIDs, {itemID=itemID})
        print(itemID)
    end

    print(itemIDs)
    C_AuctionHouse.SearchForItemKeys(itemIDs, sorts)

end

local function ShowShoppingList() 
    buffBox = CreateFrame("Frame", "BuffBoxFrame", UIParent, "BasicFrameTemplateWithInset")
    tex = buffBox:CreateTexture(nil, "BACKGROUND")
    
    buffBox:SetFrameStrata("MEDIUM")
    buffBox:SetWidth(400)
    buffBox:SetHeight(600)
    buffBox.texture = tex
    tex:SetAllPoints(true)
    buffBox.title = buffBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    
    buffBox.title:SetPoint("LEFT", buffBox.TitleBg, "LEFT", 5, 0)
    buffBox.title:SetText("Shopping list")
    
    buffBox:SetPoint("TOPLEFT", 0, 0)
    buffBox:SetMovable(true)
    buffBox:EnableMouse(true)

    buffBox:RegisterForDrag("LeftButton")
    buffBox:SetScript("OnDragStart", function(self)
                                        self:StartMoving();

                                    end)
    buffBox:SetScript("OnDragStop", function(self)
                                        buffBox:StopMovingOrSizing();
                                    end
    )
    buffBox:Show()
    
    local sf = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame1", buffBox, "UIPanelScrollFrameTemplate")
    sf:SetPoint("LEFT", 16, 0)
    sf:SetPoint("RIGHT", 0, -16)
    sf:SetPoint("TOP", -32, -32)
    sf:SetPoint("BOTTOM", 0, 10)
    
    -- EditBox
    local eb = CreateFrame("EditBox", "KethoEditBoxEditBox1", KethoEditBoxScrollFrame)
    eb:SetSize(sf:GetSize())
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false) -- dont automatically focus
    eb:SetFontObject("ChatFontNormal")
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    sf:SetScrollChild(eb)

    local output = ""

    for i, listItem in pairs(ListDisplay) do
        output = output .. listItem.link .. "x" .. listItem.qty .. "\n"
    end

    eb:SetText(output)

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
        --print( TSM_API.GetItemLink("i:" .. order.itemID))
        local recipeInfo = C_TradeSkillUI.GetRecipeInfoForSkillLineAbility(order.skillLineAbilityID)
        --print (recipeInfo.hyperlink)
        --print(recipeInfo.recipeID)
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

                        ListDisplay[reagent.itemID] = {link=TSM_API.GetItemLink("i:" .. reagent.itemID), qty = currentQty}

                        print( TSM_API.GetItemLink("i:" .. reagent.itemID) .. "x" .. reagentSlotSchematic.quantityRequired)


                    end 
                end
            end
        end
    end


end




function OrderShoppingList_SlashCommand(args)  

    if args=="gather" then
        GatherOrders()
    elseif args == "search" then
        
        SearchAH()
    end


end

function CreateShoppingListUI() 


    local button = CreateFrame("Button", "only_for_testing", AuctionHouseFrame.TitleContainer)
    button:SetPoint("RIGHT", AuctionHouseFrame.TitleContainer, "RIGHT", -20, 0)
    button:SetWidth(100)
    button:SetHeight(18 )
    
    button:SetText("Shop")

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

    button:SetScript("OnClick", function(self, b, d) 
        SearchAH()
        ShowShoppingList()
    end)

end