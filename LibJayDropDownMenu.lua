local MAJOR = "LibJayDropDownMenu"
local MINOR = 1

assert(LibStub, format("%s requires LibStub.", MAJOR))

local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

local MAX_BUTTONS = 10

lib.frame = lib.frame or CreateFrame("Frame", nil, UIParent, "VerticalLayoutFrame")
local frame = lib.frame

frame:Hide()
frame:SetFrameStrata("DIALOG")
frame:EnableKeyboard(true)
frame:SetClampedToScreen(true)

frame.expand = true
frame.leftPadding = 5
frame.rightPadding = 5
frame.topPadding = 5
frame.bottomPadding = 5

frame:SetBackdrop({
    bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
    edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
    tile = false,
    tileEdge = false,
    tileSize = 16,
    edgeSize = 8,
    insets = {left = 2, right = 2, top = 2, bottom = 2},
})
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

frame.gradient = frame.gradient or frame:CreateTexture(nil, "BORDER")
frame.gradient:ClearAllPoints()
frame.gradient:SetPoint("TOPLEFT", 2, -2)
frame.gradient:SetPoint("BOTTOMRIGHT", -2, 2)
frame.gradient:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
frame.gradient:SetBlendMode("ADD")
frame.gradient:SetGradientAlpha("VERTICAL", 0.1, 0.1, 0.1, 0, 0.25, 0.25, 0.25, 1)

local open

local PopupButtonMixin = {}

local type = type
---@param info table
---@param key string
---@return any
local function getInfoValue(info, key, ...)
    if not info then return end
    local value = info[key]
    if type(value) == "function" then return value(info, info.arg, ...) end
    return value
end

local MouseIsOver = MouseIsOver
---@param self table
local function UpdateFont(self)
    if self:IsEnabled() then
        if MouseIsOver(self) then
            self.text:SetFontObject("GameFontHighlightSmallLeft")
        else
            self.text:SetFontObject("GameFontHighlightSmallLeft")
        end
    else
        self.text:SetFontObject(getInfoValue(self.info, "isTitle") and "GameFontNormalSmallLeft" or
                                    "GameFontDisableSmallLeft")
    end
end

---@param self table
local function OnEnable(self)
    self.arrow:SetDesaturated()
    UpdateFont(self)
end

---@param self table
local function OnDisable(self)
    self.arrow:SetDesaturated()
    UpdateFont(self)
end

---@param self table
---@param motion boolean
local function OnEnter(self, motion) UpdateFont(self) end

---@param self table
---@param motion boolean
local function OnLeave(self, motion) UpdateFont(self) end

local U_CHAT_SCROLL_BUTTON_SOUND = SOUNDKIT.U_CHAT_SCROLL_BUTTON
local PlaySound = PlaySound
---@param self table
---@param button string
---@param down boolean
local function OnClick(self, button, down)
    if not getInfoValue(self.info, "noClickSound") then PlaySound(U_CHAT_SCROLL_BUTTON_SOUND) end

    local menuList = getInfoValue(self.info, "menuList")

    if menuList then
        local title = getInfoValue(self.info, "text")
        if title then
            local textColor = getInfoValue(self.info, "textColor")
            if textColor then title = "|c" .. textColor .. title .. "|r" end
        end
        open(menuList, title)
        return
    end

    local checked = getInfoValue(self.info, "checked")

    if getInfoValue(self.info, "keepShownOnClick") then
        if not getInfoValue(self.info, "notCheckable") then
            if checked then
                self.check:Hide()
                self.unCheck:Show()
                checked = false
            else
                self.check:Show()
                self.unCheck:Hide()
                checked = true
            end
        end
    else
        lib:Close()
    end
    getInfoValue(self.info, "checked", checked)

    getInfoValue(self.info, "func", checked)
end

local min = math.min
local unpack = unpack
local UIParent = UIParent
---@param self table
local function Update(self)
    local info = self.info

    self.arrow:SetShown(getInfoValue(info, "menuList") and true)

    local disabled = getInfoValue(info, "disabled")
    self:SetEnabled(not disabled)

    local isTitle = getInfoValue(info, "isTitle")
    if isTitle then self:Disable() end

    local text = getInfoValue(info, "text")
    if text then
        local textColor = getInfoValue(info, "textColor")
        if textColor then
            self.text:SetText("|c" .. textColor .. text .. "|r")
        else
            self.text:SetText(text)
        end
    else
        self.text:SetText()
    end
    self:SetWidth(min(self.text:GetStringWidth() + 60, UIParent:GetWidth() * 0.5))

    local icon = getInfoValue(info, "icon")
    if icon then
        self.icon:SetTexture(icon)
        local texCoords = getInfoValue(info, "texCoords")
        if texCoords then
            self.icon:SetTexCoord(unpack(texCoords))
        else
            self.icon:SetTexCoord(0, 1, 0, 1)
        end
        self.icon:ClearAllPoints()
        if getInfoValue(info, "iconExpandX") then self.icon:SetPoint("LEFT") end
        self.icon:SetPoint("RIGHT")
        local iconHeight = getInfoValue(info, "iconHeight")
        iconHeight = (iconHeight and iconHeight <= 16) and iconHeight or 16
        self.icon:SetHeight(iconHeight)
        self.icon:SetDesaturated(disabled)
    end
    self.icon:SetShown(icon and true)

    if getInfoValue(info, "notCheckable") or isTitle then
        self.check:Hide()
        self.unCheck:Hide()
    else
        if getInfoValue(info, "checked") then
            self.check:Show()
            self.unCheck:Hide()
        else
            self.check:Hide()
            self.unCheck:Show()
        end
        if getInfoValue(info, "isNotRadio") then
            self.check:SetTexCoord(0, 0.5, 0, 0.5)
            self.unCheck:SetTexCoord(0.5, 1, 0, 0.5)
        else
            self.check:SetTexCoord(0, 0.5, 0.5, 1)
            self.unCheck:SetTexCoord(0.5, 1, 0.5, 1)
        end
    end

    self:GetParent():MarkDirty()
end

---@param self table
---@param elapsed number
local function OnUpdate(self, elapsed)
    self.lastUpdate = (self.lastUpdate or 0) + elapsed
    if self.lastUpdate >= 0.2 then
        self.lastUpdate = 0
        Update(self)
    end
end

---@param self table
---@param info table
---@param parentList table
---@param parentTitle string
local function SetInfo(self, info, parentList, parentTitle)
    self.info = info
    self.parentList = parentList
    self.parentTitle = parentTitle

    Update(self)
end

function PopupButtonMixin:OnLoad()
    self.OnLoad = nil

    self:SetHeight(16)

    self.check = self.check or self:CreateTexture(nil, "ARTWORK")
    self.check:ClearAllPoints()
    self.check:SetPoint("LEFT")
    self.check:SetTexture([[Interface\Common\UI-DropDownRadioChecks]])
    self.check:SetTexCoord(0, 0.5, 0.5, 1)
    self.check:SetSize(16, 16)

    self.unCheck = self.unCheck or self:CreateTexture(nil, "ARTWORK")
    self.unCheck:ClearAllPoints()
    self.unCheck:SetPoint("LEFT")
    self.unCheck:SetTexture([[Interface\Common\UI-DropDownRadioChecks]])
    self.unCheck:SetTexCoord(0.5, 1, 0.5, 1)
    self.unCheck:SetSize(16, 16)

    self.icon = self.icon or self:CreateTexture(nil, "ARTWORK")
    self.icon:ClearAllPoints()
    self.icon:SetPoint("RIGHT")
    self.icon:SetSize(16, 16)

    self.text = self.text or self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmallLeft")
    self.text:ClearAllPoints()
    self.text:SetPoint("LEFT", self.check, "RIGHT", 0, 0)
    self.text:SetPoint("RIGHT")

    self.arrow = self.arrow or self:CreateTexture(nil, "ARTWORK")
    self.arrow:ClearAllPoints()
    self.arrow:SetPoint("RIGHT")
    self.arrow:SetTexture([[Interface\ChatFrame\ChatFrameExpandArrow]])
    self.arrow:SetSize(16, 16)

    self:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]], "ADD")

    self:SetScript("OnEnable", OnEnable)
    self:SetScript("OnDisable", OnDisable)
    self:SetScript("OnEnter", OnEnter)
    self:SetScript("OnLeave", OnLeave)
    self:SetScript("OnClick", OnClick)
    self:SetScript("OnUpdate", OnUpdate)
end

local SEPARATOR_INFO = {
    icon = [[Interface\Common\UI-TooltipDivider-Transparent]],
    texCoords = {0, 1, 0, 1},
    iconExpandX = true,
    iconHeight = 8,
    notCheckable = true,
    disabled = true,
}

local CopyTable = CopyTable
---@return info table
function lib:GetSeparatorInfo() return CopyTable(SEPARATOR_INFO) end

local TITLE_INFO = {notCheckable = true, disabled = true, textColor = "ffffd100"}

lib.titleButton = lib.titleButton or CreateFrame("Button", nil, frame)
local titleButton = lib.titleButton
titleButton:SetParent(frame)
titleButton.layoutIndex = -1
LibStub("LibJayMixin"):Mixin(titleButton, PopupButtonMixin)
SetInfo(titleButton, TITLE_INFO)

lib.backSepButton = lib.backSepButton or CreateFrame("Button", nil, frame)
local backSepButton = lib.backSepButton
backSepButton:SetParent(frame)
backSepButton.layoutIndex = MAX_BUTTONS + 2
LibStub("LibJayMixin"):Mixin(backSepButton, PopupButtonMixin)
SetInfo(backSepButton, SEPARATOR_INFO)

local BACK_INFO = {text = BACK, keepShownOnClick = true, notCheckable = true}

lib.backButton = lib.backButton or CreateFrame("Button", nil, frame)
local backButton = lib.backButton
backButton:SetParent(frame)
backButton.layoutIndex = MAX_BUTTONS + 3
backButton.expand = true
LibStub("LibJayMixin"):Mixin(backButton, PopupButtonMixin)
SetInfo(backButton, BACK_INFO)

lib.closeButton = lib.closeButton or CreateFrame("Button", nil, frame)
local closeButton = lib.closeButton
closeButton:SetParent(frame)
closeButton.layoutIndex = MAX_BUTTONS + 4
closeButton.expand = true
LibStub("LibJayMixin"):Mixin(closeButton, PopupButtonMixin)
SetInfo(closeButton, {text = CLOSE, notCheckable = true, func = function() lib:Close() end})

lib.buttons = lib.buttons or {}

local buttons = lib.buttons
for i = 1, MAX_BUTTONS do
    buttons[i] = buttons[i] or CreateFrame("Button", nil, frame)
    local button = buttons[i]
    button:SetParent(frame)
    button.layoutIndex = i
    button.expand = true
    LibStub("LibJayMixin"):Mixin(button, PopupButtonMixin)
end

---@param self table
---@param down boolean
local function UpdateTexture(self, down)
    if self:IsEnabled() then
        self.texture:SetTexture([[Interface\Buttons\Arrow-]] .. self:GetDirection() .. (down and [[-Down]] or [[-Up]]))
    else
        self.texture:SetTexture([[Interface\Buttons\Arrow-]] .. self:GetDirection() .. [[-Disabled]])
    end
end

---@param self table
---@param direction string | "Up" | "Down"
local function SetDirection(self, direction)
    self.direction = direction == "Up" and "Up" or "Down"
    UpdateTexture(self, self:GetButtonState() == "PUSHED")
end

---@param self table
local function OnEnable(self) UpdateTexture(self) end

---@param self table
local function OnDisable(self) UpdateTexture(self) end

---@param self table
---@param button string
local function OnMouseDown(self, button) UpdateTexture(self, true) end

---@param self table
---@param button string
local function OnMouseUp(self, button) UpdateTexture(self) end

local PopupScrollButtonMixin = {}

function PopupScrollButtonMixin:OnLoad()
    self:SetHeight(16)

    self:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]], "ADD")

    self.texture = self.texture or self:CreateTexture(nil, "ARTWORK")
    self.texture:ClearAllPoints()
    self.texture:SetPoint("CENTER")

    self:SetScript("OnEnable", OnEnable)
    self:SetScript("OnDisable", OnDisable)
    self:SetScript("OnMouseDown", OnMouseDown)
    self:SetScript("OnMouseUp", OnMouseUp)
end

---@return string direction
function PopupScrollButtonMixin:GetDirection() return self.direction or "Up" end

lib.scrollUpButton = lib.scrollUpButton or CreateFrame("Button", nil, frame)
lib.scrollDownButton = lib.scrollDownButton or CreateFrame("Button", nil, frame)

local scrollUpButton = lib.scrollUpButton
local scrollDownButton = lib.scrollDownButton

LibStub("LibJayMixin"):Mixin(scrollUpButton, PopupScrollButtonMixin)
LibStub("LibJayMixin"):Mixin(scrollDownButton, PopupScrollButtonMixin)

SetDirection(scrollDownButton, "Down")

scrollUpButton.layoutIndex = 0
scrollDownButton.layoutIndex = MAX_BUTTONS + 1

scrollUpButton.expand = true
scrollDownButton.expand = true

local ANCHORS = {
    ANCHOR_TOP = {"BOTTOM", "TOP"},
    ANCHOR_RIGHT = {"BOTTOMLEFT", "TOPRIGHT"},
    ANCHOR_BOTTOM = {"TOP", "BOTTOM"},
    ANCHOR_LEFT = {"BOTTOMRIGHT", "TOPLEFT"},
    ANCHOR_TOPRIGHT = {"BOTTOMRIGHT", "TOPRIGHT"},
    ANCHOR_BOTTOMRIGHT = {"TOPLEFT", "BOTTOMRIGHT"},
    ANCHOR_TOPLEFT = {"BOTTOMLEFT", "TOPLEFT"},
    ANCHOR_BOTTOMLEFT = {"TOPRIGHT", "BOTTOMLEFT"},
}

local error = error
local format = format
local GetCursorPosition = GetCursorPosition
---@param owner table
---@param anchor string
---@param ofsX number
---@param ofsY number
function lib:SetOwner(owner, anchor, ofsX, ofsY)
    if type(owner) ~= "table" then
        error(format("Usage: %s:SetOwner(owner, anchor[, ofsX, ofsY]): 'owner' - table expected got %s", MAJOR,
                     type(owner), 2))
    end
    if type(anchor) ~= "string" then
        error(format("Usage: %s:SetOwner(owner, anchor[, ofsX, ofsY]): 'anchor' - string expected got %s", MAJOR,
                     type(anchor), 2))
    end
    ofsX = ofsX or 0
    if type(ofsX) ~= "number" then
        error(format("Usage: %s:SetOwner(owner, anchor[, ofsX, ofsY]): 'ofsX' - number expected got %s", MAJOR,
                     type(ofsX), 2))
    end
    ofsY = ofsY or 0
    if type(ofsY) ~= "number" then
        error(format("Usage: %s:SetOwner(owner, anchor[, ofsX, ofsY]): 'ofsY' - number expected got %s", MAJOR,
                     type(ofsY), 2))
    end
    self.owner = owner

    local relativeTo = owner
    local point, relativePoint
    if anchor == "ANCHOR_CURSOR" then
        point = "TOPLEFT"
        relativeTo = UIParent
        relativePoint = "BOTTOMLEFT"
        local x, y = GetCursorPosition()
        local effectiveScale = frame:GetEffectiveScale()
        ofsX = (x + ofsX) / effectiveScale
        ofsY = (y + ofsY) / effectiveScale
    elseif ANCHORS[anchor] then
        point, relativePoint = unpack(ANCHORS[anchor])
    end
    if point then
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, ofsX, ofsY)
    end
end

---@param owner table
---@return boolean isOwned
function lib:IsOwned(owner)
    if type(owner) ~= "table" then
        error(format("Usage: %s:IsOwned(owner): 'owner' - table expected got %s", MAJOR, type(owner), 2))
    end
    return self.owner == owner
end

---@return table owner
function lib:GetOwner() return self.owner end

local currentList, currentTitle
local offset = 0

local function updateButtons()
    if not currentList then
        lib:Close()
        return
    end
    local infoCount = #currentList

    for i = 1, MAX_BUTTONS do
        local index = i + offset
        local button = buttons[i]
        local info = currentList[index]

        SetInfo(button, info)
        button:SetShown(info and true)
    end

    if currentTitle then
        TITLE_INFO.text = currentTitle
        titleButton:Show()
    else
        titleButton:Hide()
    end

    if currentList ~= lib.menuList then
        BACK_INFO.func = function() open(lib.menuList, lib.title) end
        backButton:Show()
        backSepButton:Show()
    else
        backButton:Hide()
        backSepButton:Hide()
    end

    scrollUpButton:SetEnabled(offset > 0)
    scrollDownButton:SetEnabled(infoCount - MAX_BUTTONS > offset)

    scrollUpButton:SetShown(infoCount > MAX_BUTTONS)
    scrollDownButton:SetShown(infoCount > MAX_BUTTONS)

    scrollUpButton:SetWidth(26)
    scrollDownButton:SetWidth(26)

    frame:MarkDirty()
    --[[ frame:SetShown(infoCount > 0) ]]
    frame:Show()
end

---@param menuList table
---@param title string
open = function(menuList, title)
    currentList = menuList
    currentTitle = title
    offset = 0
    updateButtons()
end

local max = math.max
---@param delta number
local function updateOffset(delta)
    if not currentList then
        lib:Close()
        return
    end

    offset = offset + (delta * -1)
    offset = max(0, min(offset, #currentList - MAX_BUTTONS))
    updateButtons()
end

---@param menuList table
---@param title string
---@param parentList table
---@param parentTitle string
function lib:Open(menuList, title)
    if type(menuList) ~= "table" then
        error(format("Usage: %s:Open(menuList[, title]): 'menuList' - table expected got %s", MAJOR, type(menuList), 2))
    end
    if type(self:GetOwner()) ~= "table" then
        error(format("Usage: %s:Open(menuList[, title]): Owner not set.", MAJOR, 2))
    end

    self.menuList = menuList
    self.title = title

    open(menuList, title)
end

function lib:Close()
    self.owner = nil
    frame:ClearAllPoints()
    frame:Hide()
end

---@return boolean isOpen
function lib:IsOpen() return frame:IsShown() end

frame:SetScript("OnHide", function(self) self.owner = nil end)
local IsShiftKeyDown = IsShiftKeyDown
frame:SetScript("OnMouseWheel", function(self, delta) updateOffset(delta * (IsShiftKeyDown() and 10 or 1)) end)
frame:SetScript("OnKeyDown", function(self, key)
    self:SetPropagateKeyboardInput(false)
    if key == "ESCAPE" or key == "ENTER" then
        lib:Close()
    elseif key == "DOWN" then
        updateOffset(-1 * (IsShiftKeyDown() and 10 or 1))
    elseif key == "UP" then
        updateOffset(1 * (IsShiftKeyDown() and 10 or 1))
    elseif key == "SPACE" then
        for i = 1, #buttons do
            local button = buttons[i]
            if button:IsVisible() and button:IsMouseOver() then
                button:Click()
                break
            end
        end
    else
        self:SetPropagateKeyboardInput(true)
    end
end)
frame:SetScript("OnUpdate", function(self, elapsed)
    if self:IsDirty() then
        scrollUpButton:SetWidth(26)
        scrollDownButton:SetWidth(26)
        self:Layout()
    end
end)
scrollUpButton:SetScript("OnClick", function(self, button, down) updateOffset(1) end)
scrollDownButton:SetScript("OnClick", function(self, button, down) updateOffset(-1) end)
