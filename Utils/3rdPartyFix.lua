--"Gambiarra da Braba - Início" - 01/03/2025
--This next lines were the only way found to resize texts on ACE3 widgets since it's a poorly documented lib that get almost no feature update in a long time.
--If someone knows a diferent way to do this or by the time you read this there are any changes in ACE3 label widget concerning font sizing or allowing to get
--current font style, feel free to try and push a commit on GitHub project page.
local auxFontScaleFrame = CreateFrame("Frame", "auxFontScaleFrame", UIParent, "BasicFrameTemplateWithInset")
auxFontScaleFrame.dummyTextLabel = auxFontScaleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local font, size, style = auxFontScaleFrame.dummyTextLabel:GetFont() --Essas 3 variáveis são utilizadas para ajustar a escala de textos dentro dos widgets do ACE3.
auxFontScaleFrame:Hide()

function SetACE3WidgetFontSize(_widget, _size)
    _widget:SetFont(font, _size, style)
end
--"Gambiarra da Braba - Fim"

local AceGUI = LibStub("AceGUI-3.0")

function AddLineSkip(_frame)
    local LabelLineSkip = AceGUI:Create("InteractiveLabel")
    LabelLineSkip:SetText("")
    _frame:AddChild(LabelLineSkip)
end