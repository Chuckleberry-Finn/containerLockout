require "ISObjectClickHandler"

local containerLockout = require "containerLockout-shared"

local ISObjectClickHandler_doClick = ISObjectClickHandler.doClick
function ISObjectClickHandler.doClick(object, x, y)
    if containerLockout.canInteract(object, getPlayer()) then ISObjectClickHandler_doClick(object, x, y) end
end


