require "ISUI/ISInventoryPane"
require "ISUI/ISInventoryPage"

local containerLockOut = require "containerLockout-shared"

---Prevents transfer from or to a locked container
local ISInventoryTransferAction_isValid = ISInventoryTransferAction.isValid
function ISInventoryTransferAction:isValid()
    if self.destContainer and self.srcContainer then
        local playerObj = self.character
        if containerLockOut.canInteract(self.destContainer:getParent(),playerObj) and containerLockOut.canInteract(self.srcContainer:getParent(), playerObj) then
            return ISInventoryTransferAction_isValid(self)
        end
    end
end


---Prevents dragging items out of a locked container
local ISInventoryPage_dropItemsInContainer = ISInventoryPage.dropItemsInContainer
function ISInventoryPage:dropItemsInContainer(button)
    local container = self.mouseOverButton and self.mouseOverButton.inventory or nil
    local allow = true

    if container then
        local mapObj = container:getParent()
        local playerObj = getSpecificPlayer(self.player)
        if mapObj then allow = containerLockOut.canInteract(mapObj, playerObj) end
    end

    if allow then ISInventoryPage_dropItemsInContainer(self, button)
    else
        if ISMouseDrag.draggingFocus then
            ISMouseDrag.draggingFocus:onMouseUp(0,0)
            ISMouseDrag.draggingFocus = nil
            ISMouseDrag.dragging = nil
        end
        self:refreshWeight()
        return true
    end
end


---Slides the inventory page over to the next available page when scrolling up
local ISInventoryPage_prevUnlockedContainer = ISInventoryPage.prevUnlockedContainer
function ISInventoryPage:prevUnlockedContainer(index, wrap)
    local _index = ISInventoryPage_prevUnlockedContainer(self, index, wrap)
    local playerObj = getSpecificPlayer(self.player)
    for i=_index,1,-1 do
        local backpack = self.backpacks[i]
        local object = backpack.inventory:getParent()
        if containerLockOut.canInteract(object, playerObj) then return i end
    end
    return wrap and self:prevUnlockedContainer(#self.backpacks + 1, false) or -1
end


---Slides the inventory page over to the next available page when scrolling down
local ISInventoryPage_nextUnlockedContainer = ISInventoryPage.nextUnlockedContainer
function ISInventoryPage:nextUnlockedContainer(index, wrap)
    local _index = ISInventoryPage_nextUnlockedContainer(self, index, wrap)

    local playerObj = getSpecificPlayer(self.player)
    for i=_index,#self.backpacks do
        local backpack = self.backpacks[i]
        local object = backpack.inventory:getParent()
        if containerLockOut.canInteract(object, playerObj) then return i end
    end
    return wrap and self:nextUnlockedContainer(0, false) or -1

end


---Slides the inventory page over to the next available page on update
local ISInventoryPage_update = ISInventoryPage.update
function ISInventoryPage:update()
    ISInventoryPage_update(self)
    if not self.onCharacter then
        local playerObj = getSpecificPlayer(self.player)
        -- If the currently-selected container is locked to the player, select another container.
        local object = self.inventory and self.inventory:getParent() or nil
        if object and #self.backpacks > 1 and (not containerLockOut.canInteract(object, playerObj)) then
            local currentIndex = self:getCurrentBackpackIndex()
            local unlockedIndex = self:prevUnlockedContainer(currentIndex, false)
            if unlockedIndex == -1 then
                unlockedIndex = self:nextUnlockedContainer(currentIndex, false)
            end
            if unlockedIndex ~= -1 then
                if playerObj:getJoypadBind() ~= -1 then
                    self.backpackChoice = unlockedIndex
                end
                self:selectContainer(self.backpacks[unlockedIndex])
            end
        end
    end
end


---Places the lock texture over the button and prevents it from working
local function hideButtons(UI, STEP)
    if STEP == "end" and (not UI.onCharacter) then
        for _,containerButton in ipairs(UI.backpacks) do
            local mapObj = containerButton.inventory:getParent()
            if mapObj then

                local playerObj = getSpecificPlayer(UI.player)
                local canView = containerLockOut.canInteract(mapObj, playerObj)
                if not canView then
                    if containerButton then
                        containerButton.onclick = nil
                        containerButton.onmousedown = nil
                        containerButton.onMouseUp = nil
                        containerButton.onRightMouseDown = nil
                        containerButton:setOnMouseOverFunction(nil)
                        containerButton:setOnMouseOutFunction(nil)
                        containerButton.textureOverride = getTexture(containerLockOut.texture)
                    end
                end
            end
        end
    end
end
Events.OnRefreshInventoryWindowContainers.Add(hideButtons)