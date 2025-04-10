-- PointTo: Written by Olorin(Оригинальный автор)
-- Модификации: Стравинский (исправления ошибок, улучшения)

-- Version: 0.7d
-- Пофикшен баг с несоответствием количества аргументов и вызываемой функции OnLoadFrame_OnEvent
-- Оптимизирована работа метода OnLoadFrame_OnEvent
-- Пофикшен баг с вызовом DebugMode при команде /pt off
-- Добавлена поддержка события PLAYER_ENTERING_WORLD (проблему, когда некоторые подземелья меняют зону до того,
-- как игрок полностью телепортируется, что приводило к неправильному показу/скрытию фрейма)
-- Стрелочка перекрашена в зеленый, но оригинальная сохранена как - Copy

local s2 = sqrt(2);
local cos, sin, rad = math.cos, math.sin, math.rad;
local Angle=0
local PointToUnit = UnitName("party1")
local MainFrameElap, MainFrameElapsed = 0,0
local TimerFrameElap,TimerFrameElapsed = 0,0
local LocX, LocY, LocXVal, LocYVal, NoLocs,TarLoc
local PlayerXpos,PlayerYpos, UnitXPos,UnitYPos = 0,0,0,0
local PointToPointLoc,Str1, Str2
local R, G, B, A
local cmd
local Distance, DistanceX, DistanceY, Facing
local MainFrame,MainText1,ArrowFrame, ArrowTexture, GotoLoc
local OnLoadFrame=CreateFrame("Frame","PointToLoaded")
local TimerFrame=CreateFrame("Frame","PointToTimerFrame")

local function Out(message)
    DEFAULT_CHAT_FRAME:AddMessage(message)
 end

-- поддержка слэш команд
function PointTo_Command(cmd)
    if (cmd ~= nil and cmd ~= "") then
        cmd=strlower(cmd)
        Out("|cFEFED000" .."PointTo Команда: " .. cmd);
        if cmd == "on" then
            PointToDisabled = nil
            Out("|cFEFED000" .."PointTo Включен.");
            MainFrame:Show()    
        elseif cmd=="off" then
            PointToDisabled = 1
            MainFrame:Hide()
            Out("|cFEFED000" .."PointTo Выключен.");
        elseif cmd=="lock" then
            if MainFrame:IsVisible() then
                if MainFrame:IsMovable() == nil then
                    Out("PointTo Разблокирован!")
                    MainFrame:SetMovable(true)
                    MainFrame:EnableMouse(true)
                else
                    Out("PointTo Заблокирован!")
                    MainFrame:SetMovable(false)
                    MainFrame:EnableMouse(false)
                end
            else
                Out("|cFEFED000" .."PointTo Не включен, что бы включить пропишите /PT on")
            end
        elseif cmd=="autohide" then
            if PointToAutoHide == nil then
                Out("|cFEFED000" .."PointTo АвтоСкрытие включено")
                PointToAutoHide = 1
            else
                Out("|cFEFED000" .."PointTo AutoHide выключен")
                PointToAutoHide = nil
            end
        else
            Out("|cFEFED000" .."Команда /PointTo " .. cmd .. " не верная.")
        end    
    else
        Out("|cFF00FFFF".."Команды аддона:" .."|cFEFED000" .." /PointTo, /pointto, /pt or /PT")
        Out("|cFF00FFFF".."PointTo On -" .."|cFEFED000" .." Включить аддон")
        Out("|cFF00FFFF".."PointTo Off -" .."|cFEFED000" .." Выключить аддон")
        Out("|cFF00FFFF".."PointTo Lock -" .."|cFEFED000" .." Блокирует/разблокирует окошко аддона")
        Out("|cFF00FFFF".."PointTo AutoHide -" .."|cFEFED000" .." Включает/выключает автоскрытие")
    end
end

local function MainFrameCreate()
    MainFrame=CreateFrame("FRAME","PointToMainFrame",UIParent, BackdropTemplateMixin and "BackdropTemplate");
    MainFrame:SetBackdrop({
        bgFile="Interface\\Tooltips\\UI-Tooltip-Background", 
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
        tile=1, tileSize=10, edgeSize=10, 
        insets={left=3, right=3, top=3, bottom=3}
        })
    MainFrame:SetBackdropColor(0,0,0,0.8)
    MainFrame:SetWidth(100); MainFrame:SetHeight(125);
    MainFrame:SetPoint(MainFramePoint,UIParent, MainFrameXpos, MainFrameYpos);
    MainFrame:SetResizable(true)

    MainText1=MainFrame:CreateFontString("$parentText","ARTWORK","GameFontNormal")
    MainText1:SetHeight(14)
    MainText1:SetPoint("TOP",MainFrame,"TOP",0,-4)
    MainText1:SetText("Init String")
        
    MainText2=MainFrame:CreateFontString("$parentText","ARTWORK","GameFontNormal")
    MainText2:SetPoint("TOP",MainText1,"BOTTOM",0,-1)
    MainText2:SetHeight(14)
    
    ArrowFrame=CreateFrame("Frame","ARTWORK",MainFrame)
    ArrowFrame:SetWidth(50);ArrowFrame:SetHeight(50)
    ArrowFrame:SetPoint("TOP",MainText2,"BOTTOM",0,-2)
    
    ArrowTexture=ArrowFrame:CreateTexture(nil,"BACKGROUND")
    ArrowTexture:SetTexture("Interface\\AddOns\\bcsPointTo\\Art\\bcsArrow.tga")
    ArrowTexture:SetAllPoints(ArrowFrame) 
    ArrowFrame.texture = ArrowTexture

    GotoLoc=CreateFrame("EditBox","GotoLoc",MainFrame,"InputBoxTemplate")
    GotoLoc:SetAutoFocus(false)
    GotoLoc:SetPoint("BOTTOM",MainFrame,"BOTTOM",3,4)
    GotoLoc:EnableMouse(true)
    GotoLoc:SetMultiLine(false)
    GotoLoc:SetFontObject(GameFontNormalSmall)
    GotoLoc:SetWidth(85);GotoLoc:SetHeight(20)
    GotoLoc:SetJustifyH("CENTER") 
    GotoLoc:RegisterEvent("OnEnterPressed")
    GotoLoc:SetScript("OnEnterPressed", function() GotoLoc:ClearFocus() end)
    GotoLoc:RegisterEvent("OnEscapePressed")
    GotoLoc:SetScript("OnEscapePressed", function() GotoLoc:ClearFocus() GotoLoc:SetText("") end)
     
    TextLocX=MainFrame:CreateFontString("$parentText","ARTWORK","GameFontNormal")
    TextLocX:SetHeight(14)
    TextLocX:SetPoint("BOTTOMLEFT",GotoLoc,"TOPLEFT",-5,2)
    TextLocX:SetText("|cFEFED000".. "X:")    
    TextLocXVal=MainFrame:CreateFontString("$parentText","ARTWORK","GameFontNormal")
    TextLocXVal:SetHeight(14)
    TextLocXVal:SetPoint("BOTTOMLEFT",GotoLoc,"TOPLEFT",9,2)
    TextLocY=MainFrame:CreateFontString("$parentText","ARTWORK","GameFontNormal")
    TextLocY:SetHeight(14)
    TextLocY:SetPoint("BOTTOMLEFT",GotoLoc,"TOPLEFT",42,2)        
    TextLocY:SetText("|cFEFED000".. "Y:")
    TextLocYVal=MainFrame:CreateFontString("$parentText","ARTWORK","GameFontNormal")
    TextLocYVal:SetHeight(14)
    TextLocYVal:SetPoint("BOTTOMLEFT",GotoLoc,"TOPLEFT",55,2)
    
    MainFrame:SetScript("OnUpdate", MainFrame_OnUpdate)
    MainFrame:SetMovable(false)
    MainFrame:EnableMouse(false)
    MainFrame:SetScript("OnMouseDown",function() MainFrame:StartMoving() end)
    MainFrame:SetScript("OnMouseUp", PointToSaveLoc)
end

function PointToSaveLoc()
    MainFrame:StopMovingOrSizing()
    MainFramePoint, relativeTo, relativePoint, MainFrameXpos, MainFrameYpos = MainFrame:GetPoint()
end

local function OnLoadFrame_OnEvent(this, event)
    if event == "VARIABLES_LOADED" then
        if not MainFrame then MainFrame = 0 end
        if not MainFrameYpos then MainFrameYpos = 0 end
        if not MainFramePoint then MainFramePoint = "CENTER" end
        
        MainFrameCreate()
        
        if PointToDisabled ~= nil then
            MainFrame:Hide()
        end
        
    elseif (event == "ZONE_CHANGED_NEW_AREA") or (event == "PLAYER_ENTERING_WORLD") then
        if PointToDisabled == nil then
            if PointToAutoHide ~= nil then
                if TimerFrameElapsed ~= 0 then
                    TimerFrameElapsed = 0
                else
                    TimerFrame:Hide()
                    TimerFrame:SetScript("OnUpdate", function(self, TimerFrameElap)
                        TimerFrameElapsed = TimerFrameElapsed + TimerFrameElap
                        if TimerFrameElapsed < 5 then return end
                        
                        PlayerXpos, PlayerYpos = GetPlayerMapPosition("player")
                        if PlayerXpos == 0 and PlayerYpos == 0 then
                            MainFrame:Hide()
                        else 
                            MainFrame:Show()
                        end
                        
                        self:Hide()
                        TimerFrameElapsed = 0
                        TimerFrame:SetScript("OnUpdate", nil)
                    end)
                    
                    TimerFrame:Show()
                end
            end
        end
    end
end

local function PointToCalcDistance()
    if ( UnitXPos - PlayerXpos) < 0 then
        DistanceX = -( UnitXPos - PlayerXpos) 
    else
        DistanceX = ( UnitXPos - PlayerXpos) 
    end
    
    if ( UnitYPos - PlayerYpos) < 0 then
        DistanceY = -( UnitYPos - PlayerYpos) 
    else
        DistanceY = ( UnitYPos - PlayerYpos) 
    end
    Distance = DistanceX + DistanceY
end

local function CalcCorner(Angle)
    local r = rad(Angle);
    return 0.5 + cos(r) / s2, 0.5 + sin(r) / s2;
end

local function RotateTexture(texture, Angle)
    local LRx, LRy = CalcCorner(Angle + 45);
    local LLx, LLy = CalcCorner(Angle + 135);
    local ULx, ULy = CalcCorner(Angle + 225);
    local URx, URy = CalcCorner(Angle - 45);
    texture:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
end

local function PointToGetPlayerLocs()
    PlayerXpos,PlayerYpos = GetPlayerMapPosition("player")
    PlayerXpos=PlayerXpos*100
    PlayerYpos=PlayerYpos*100
    LocXVal = string.format("%.4f", PlayerXpos)
    LocYVal = string.format("%.4f", PlayerYpos)
    TextLocXVal:SetText("|cFF00FFFF".. (string.format("%.1f", PlayerXpos)))
    TextLocYVal:SetText("|cFF00FFFF".. (string.format("%.1f", PlayerYpos)))
end

function PointToGetTargetLocs()
    if ValidTargetType == 2 then
        UnitXPos=tonumber(Str1)
        UnitYPos=tonumber(Str2)
    else
        UnitXPos,UnitYPos = GetPlayerMapPosition(PointToUnit)
        UnitXPos=UnitXPos*100
        UnitYPos=UnitYPos*100    
    end
    if ValidTargetType ~= nil then
        TarLoc = ("party1 X: ".. (string.format("%.4f", UnitXPos)) .. " Y: ".. (string.format("%.4f", UnitYPos)))
    end
    TempVal=(((math.atan2((UnitYPos)-PlayerYpos, (UnitXPos -PlayerXpos )))/math.pi/2)*360)+180
    Facing = ((GetPlayerFacing()/math.pi/2)*360)
end

function MainFrame_OnUpdate(self, MainFrameElap)
    MainFrameElapsed = MainFrameElapsed + MainFrameElap
    if MainFrameElapsed < .1 then return end
    MainFrameElapsed = 0 
    ValidTargetType = nil
    InputLoc = GotoLoc:GetText()
    PointToGetPlayerLocs()
    if (PlayerXpos ~= 0 and PlayerYpos ~= 0) then 
        if InputLoc ~= nil and InputLoc ~= "" then
            if UnitExists(InputLoc) then
                PointToUnit = InputLoc    
                ValidTargetType = 1
                PointToGetTargetLocs()
                MainText1:SetText(UnitName(PointToUnit))
            else
                Str1, Str2 =strsplit(",",InputLoc)
                if (tonumber(Str1) ~= nil and tonumber(Str2) ~= nil) then
                    ValidTargetType = 2
                    PointToGetTargetLocs()
                    MainText1:SetText("Поз введена")
                else 
                    MainText1:SetText("Поз неверна")
                end
            end
        else
            if UnitExists("Party1") then
                PointToUnit = "Party1"
                ValidTargetType = 1
                PointToGetTargetLocs()
                MainText1:SetText(UnitName(PointToUnit))
            else 
                MainText1:SetText("Не в группе")          
            end
        end
        if ((UnitXPos == 0) and (UnitYPos ==0) and (ValidTargetType == 1)) then
            ArrowFrame:Hide()
            MainText2:SetText("Не та же зона")
        elseif ValidTargetType~=nil then
            ArrowFrame:Show()
            PointToCalcDistance()
            RotateTexture(ArrowTexture, -((Facing + TempVal)-90 ))
            if Distance < .4 then
                MainText2:SetText("Прибыли!")
            else
                MainText2:SetText(string.format("%.0f", Distance*10).." Ярдов")
            end
        else 
            ArrowFrame:Hide()
            MainText2:SetText("")
        end
    else
        ArrowFrame:Hide()
        MainText2:SetText("")
        MainText1:SetText("Нет Поз-й")
    end
end

-- определение слэш команд, на которые будет реагировать аддон
SLASH_PointTo1 = "/pointto"
SLASH_PointTo2 = "/PointTo"
SLASH_PointTo3 = "/pt"
SLASH_PointTo4 = "/PT"

SlashCmdList["PointTo"] = PointTo_Command

OnLoadFrame:RegisterEvent("VARIABLES_LOADED")
OnLoadFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
OnLoadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
OnLoadFrame:SetScript("OnEvent", OnLoadFrame_OnEvent)