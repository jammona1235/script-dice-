-- DICE PRIVATE — versione con pannello rigged integrato
-- /panel per scegliere colore dominante e numero dadi (1-4)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HS = game:GetService("HttpService")
local player = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- CONFIG RIGGED (deve stare PRIMA dell'intro per essere usato)
-- ═══════════════════════════════════════════════════════════════
_GACC = _GACC or {}
_GACC.diceConfig = _GACC.diceConfig or {
    accentColor = "BLUE",
    count = 3,
}
_GACC.DICE_PALETTE = {
    SILVER  = Color3.fromRGB(220,220,220),
    BLUE    = Color3.fromRGB(60,140,255),
    RED     = Color3.fromRGB(230,70,70),
    GREEN   = Color3.fromRGB(80,220,120),
    PURPLE  = Color3.fromRGB(170,90,240),
    GOLD    = Color3.fromRGB(255,200,60),
    CYAN    = Color3.fromRGB(60,220,230),
    PINK    = Color3.fromRGB(255,120,200),
    ORANGE  = Color3.fromRGB(255,140,50),
    LIME    = Color3.fromRGB(180,255,80),
    MAGENTA = Color3.fromRGB(240,60,180),
    WHITE   = Color3.fromRGB(255,255,255),
    BLACK   = Color3.fromRGB(30,30,35),
}
_GACC._introDieCounter = 1

local _PANEL_SAVE = "Dice_Panel.json"
local function loadDiceConfig()
    if not (isfile and isfile(_PANEL_SAVE)) then return end
    pcall(function()
        local ok, d = pcall(function() return HS:JSONDecode(readfile(_PANEL_SAVE)) end)
        if ok and type(d) == "table" and type(d.diceConfig) == "table" then
            if _GACC.DICE_PALETTE[d.diceConfig.accentColor] then
                _GACC.diceConfig.accentColor = d.diceConfig.accentColor
            end
            if tonumber(d.diceConfig.count) then
                _GACC.diceConfig.count = math.clamp(math.floor(d.diceConfig.count), 1, 4)
            end
        end
    end)
end
loadDiceConfig()

_GACC.applyDiceColors = function(diceParts)
    if type(diceParts) ~= "table" then return end
    local cfg = _GACC.diceConfig
    local color = _GACC.DICE_PALETTE[cfg.accentColor] or Color3.fromRGB(220,220,220)
    local n = math.clamp(tonumber(cfg.count) or 0, 0, 6)
    for i, entry in ipairs(diceParts) do
        local inst = (type(entry) == "table") and entry.instance or entry
        if i <= n and inst then
            pcall(function()
                if inst:IsA("BasePart") then inst.Color = color
                elseif inst:IsA("Frame") then inst.BackgroundColor3 = color
                elseif inst:IsA("ImageLabel") then inst.ImageColor3 = color
                elseif inst:IsA("TextLabel") then inst.TextColor3 = color
                elseif inst:IsA("Model") then
                    for _, p in ipairs(inst:GetDescendants()) do
                        if p:IsA("BasePart") then p.Color = color end
                    end
                end
            end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- INTRO CONFIG
-- ═══════════════════════════════════════════════════════════════
local introSoundEnabled = true
if isfile and isfile("Dice_Mobile.json") then
    local ok, data = pcall(function() return HS:JSONDecode(readfile("Dice_Mobile.json")) end)
    if ok and type(data) == "table" and data.introSoundEnabled ~= nil then
        introSoundEnabled = data.introSoundEnabled
    end
end

local animEnabled = false
local backgroundEnabled = false
local backgroundIndex = 1
local currentColorTheme = "SILVER"

local THEME_DEFS = {
    SILVER = {accent=Color3.fromRGB(220,220,220), accentDark=Color3.fromRGB(150,150,150), accentBg=Color3.fromRGB(22,22,25),  accentHover=Color3.fromRGB(75,75,80),  accentRowHover=Color3.fromRGB(18,18,20), bgAsset="106065423404162"},
}

do local _t0=THEME_DEFS[currentColorTheme] or THEME_DEFS.SILVER
    _GACC.accent=_t0.accent; _GACC.accentDark=_t0.accentDark
    _GACC.accentBg=_t0.accentBg; _GACC.accentHover=_t0.accentHover
    _GACC.accentRowHover=_t0.accentRowHover
end

local _themeExtRefs = {}
local _themeStealPills = {}

local function _gAccentGrad(t)
    local a=_GACC.accent; local d=_GACC.accentDark
    local pulse=math.sin(t*0.7)*0.14
    local aR=math.clamp(math.floor(a.R*255*(1+pulse)),0,255)
    local aG=math.clamp(math.floor(a.G*255*(1+pulse)),0,255)
    local aB=math.clamp(math.floor(a.B*255*(1+pulse)),0,255)
    local dR=math.clamp(math.floor(d.R*255*(0.75+pulse*0.25)),0,255)
    local dG=math.clamp(math.floor(d.G*255*(0.75+pulse*0.25)),0,255)
    local dB=math.clamp(math.floor(d.B*255*(0.75+pulse*0.25)),0,255)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(dR,dG,dB)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(aR,aG,aB)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.82,Color3.fromRGB(aR,aG,aB)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(dR,dG,dB))
    })
end

if isfile and isfile("Dice_Mobile.json") then
    local ok2, d2 = pcall(function() return HS:JSONDecode(readfile("Dice_Mobile.json")) end)
    if ok2 and type(d2)=="table" then
        if type(d2.animEnabled)=="boolean" then animEnabled=d2.animEnabled end
        if type(d2.backgroundEnabled)=="boolean" then backgroundEnabled=d2.backgroundEnabled end
        if type(d2.backgroundIndex)=="number" then backgroundIndex=d2.backgroundIndex end
        if type(d2.colorThemeName)=="string" and THEME_DEFS[d2.colorThemeName] then currentColorTheme=d2.colorThemeName end
    end
end

local introSoundInstance = nil
if introSoundEnabled then
    task.spawn(function()
        local urlIntro = "https://files.catbox.moe/66xaq4.mp3"
        local numeFisier = "dicenew_introo.mp3"
        if not (isfile and isfile(numeFisier)) then
            local ok, data = pcall(function() return game:HttpGet(urlIntro) end)
            if ok and data then pcall(function() writefile(numeFisier, data) end) end
        end
        introSoundInstance = Instance.new("Sound")
        pcall(function()
            introSoundInstance.SoundId = getcustomasset(numeFisier)
            introSoundInstance.Volume = 3
            introSoundInstance.Looped = false
            introSoundInstance.Parent = game:GetService("CoreGui")
            introSoundInstance:Play()
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- INTRO ANIMATA CON DADI RIGGED
-- ═══════════════════════════════════════════════════════════════
if introSoundEnabled then
    task.spawn(function()
        local introStarted=tick()
        task.wait(.35)
        local introGui=Instance.new("ScreenGui")
        introGui.Name="DicePrivateDiceIntro"; introGui.ResetOnSpawn=false; introGui.IgnoreGuiInset=true
        introGui.DisplayOrder=9999; introGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(introGui) end end)
        if not pcall(function() introGui.Parent=game:GetService("CoreGui") end) then introGui.Parent=player:WaitForChild("PlayerGui") end
        local stage=Instance.new("Frame",introGui); stage.Size=UDim2.fromScale(1,1); stage.BackgroundTransparency=1; stage.ClipsDescendants=true
        local function waitForIntroSecond(second)
            local remaining=second-(tick()-introStarted)
            if remaining>0 then task.wait(remaining) end
        end
        local layouts={
            [1]={{.5,.5}},
            [2]={{.28,.28},{.72,.72}},
            [3]={{.27,.27},{.5,.5},{.73,.73}},
            [4]={{.28,.28},{.72,.28},{.28,.72},{.72,.72}},
            [5]={{.27,.27},{.73,.27},{.5,.5},{.27,.73},{.73,.73}},
            [6]={{.28,.23},{.72,.23},{.28,.5},{.72,.5},{.28,.77},{.72,.77}},
        }

        local function makeIntroDie(size,pos,value)
            local group=Instance.new("CanvasGroup",stage)
            group.AnchorPoint=Vector2.new(.5,.5); group.Position=pos; group.Size=UDim2.fromOffset(size+14,size+16); group.BackgroundTransparency=1; group.ZIndex=20; group.ClipsDescendants=true

            local dieIndex = _GACC._introDieCounter or 1
            _GACC._introDieCounter = dieIndex + 1
            local nDice = tonumber(_GACC.diceConfig.count) or 0
            local isRigged = dieIndex <= nDice
            local rigColor = _GACC.DICE_PALETTE[_GACC.diceConfig.accentColor] or Color3.fromRGB(60,140,255)

            local shadow=Instance.new("Frame",group); shadow.Size=UDim2.fromOffset(size,size); shadow.Position=UDim2.fromOffset(10,11)
            shadow.BackgroundColor3=Color3.fromRGB(0,0,0); shadow.BackgroundTransparency=.48; shadow.BorderSizePixel=0; Instance.new("UICorner",shadow).CornerRadius=UDim.new(0,math.floor(size*.2))
            local depth=Instance.new("Frame",group); depth.Size=UDim2.fromOffset(size,size); depth.Position=UDim2.fromOffset(8,8)
            depth.BackgroundColor3=Color3.fromRGB(80,83,98); depth.BorderSizePixel=0; Instance.new("UICorner",depth).CornerRadius=UDim.new(0,math.floor(size*.2))
            local face=Instance.new("Frame",group); face.Size=UDim2.fromOffset(size,size); face.Position=UDim2.fromOffset(7,5)
            face.BackgroundColor3 = isRigged and rigColor or Color3.fromRGB(225,228,238)
            face.BorderSizePixel=0; face.ZIndex=22; Instance.new("UICorner",face).CornerRadius=UDim.new(0,math.floor(size*.2))
            local stroke=Instance.new("UIStroke",face); stroke.Color=isRigged and Color3.fromRGB(255,255,255) or _GACC.accentDark; stroke.Transparency=isRigged and .25 or 0; stroke.Thickness=2
            local grad=Instance.new("UIGradient",face)
            if isRigged then
                grad.Color=ColorSequence.new({
                    ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,255,255)),
                    ColorSequenceKeypoint.new(.55, rigColor),
                    ColorSequenceKeypoint.new(1,   Color3.fromRGB(
                        math.floor(rigColor.R*255*0.55),
                        math.floor(rigColor.G*255*0.55),
                        math.floor(rigColor.B*255*0.55)
                    ))
                })
            else
                grad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(.55,Color3.fromRGB(211,214,225)),ColorSequenceKeypoint.new(1,Color3.fromRGB(126,130,147))})
            end
            grad.Rotation=35
            local rim=Instance.new("Frame",face); rim.Size=UDim2.new(1,-10,1,-10); rim.Position=UDim2.fromOffset(5,5); rim.BackgroundTransparency=1; rim.ZIndex=23; Instance.new("UICorner",rim).CornerRadius=UDim.new(0,math.floor(size*.15))
            local rimStroke=Instance.new("UIStroke",rim); rimStroke.Color=Color3.fromRGB(255,255,255); rimStroke.Transparency=.58; rimStroke.Thickness=1
            for _,point in ipairs(layouts[value]) do
                local pip=Instance.new("Frame",face); pip.AnchorPoint=Vector2.new(.5,.5); pip.Position=UDim2.fromScale(point[1],point[2])
                pip.Size=UDim2.fromOffset(math.max(7,math.floor(size*.13)),math.max(7,math.floor(size*.13))); pip.BackgroundColor3=Color3.fromRGB(16,17,24); pip.BorderSizePixel=0; pip.ZIndex=24
                Instance.new("UICorner",pip).CornerRadius=UDim.new(1,0); local pipStroke=Instance.new("UIStroke",pip); pipStroke.Color=Color3.fromRGB(255,255,255); pipStroke.Transparency=.8; pipStroke.Thickness=1
            end
            local scale=Instance.new("UIScale",group)
            return group,scale,grad
        end

        _GACC._introDieCounter = 1
        local dice={}
        local routes={
            {44,UDim2.new(-.1,0,.24,0),UDim2.new(.27,0,.33,0),1,900,.00},
            {54,UDim2.new(-.12,0,.65,0),UDim2.new(.31,0,.62,0),4,1080,.08},
            {38,UDim2.new(.22,0,-.12,0),UDim2.new(.40,0,.27,0),2,-900,.16},
            {46,UDim2.new(.38,0,1.12,0),UDim2.new(.42,0,.72,0),5,1080,.12},
            {44,UDim2.new(1.1,0,.25,0),UDim2.new(.73,0,.34,0),3,-900,.00},
            {54,UDim2.new(1.12,0,.68,0),UDim2.new(.69,0,.63,0),6,-1080,.08},
            {38,UDim2.new(.78,0,-.12,0),UDim2.new(.60,0,.27,0),4,900,.16},
            {46,UDim2.new(.64,0,1.12,0),UDim2.new(.58,0,.72,0),2,-1080,.12},
        }
        for _,route in ipairs(routes) do
            local die,scale,grad=makeIntroDie(route[1],route[2],route[4]); scale.Scale=.35; die.GroupTransparency=.18
            table.insert(dice,{die,scale,grad,route[3],route[5],route[2]})
            task.delay(route[6],function()
                TweenService:Create(die,TweenInfo.new(.78,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=route[3],Rotation=route[5],GroupTransparency=0}):Play()
                TweenService:Create(scale,TweenInfo.new(.7,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
                TweenService:Create(grad,TweenInfo.new(.78),{Rotation=route[5]>0 and 395 or -325,Offset=Vector2.new(route[5]>0 and .28 or -.28,0)}):Play()
            end)
        end
        task.wait(.88)
        for i,item in ipairs(dice) do
            local drift=i%2==0 and 32 or -32
            TweenService:Create(item[1],TweenInfo.new(.48,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Rotation=item[1].Rotation+drift}):Play()
        end
        waitForIntroSecond(4.4)
        for _,item in ipairs(dice) do
            local direction=item[5]>0 and 1 or -1
            local retreat=item[4]:Lerp(item[6],.42)
            TweenService:Create(item[1],TweenInfo.new(.46,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{Position=retreat,Rotation=item[1].Rotation+direction*360}):Play()
            TweenService:Create(item[2],TweenInfo.new(.46,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Scale=.82}):Play()
            TweenService:Create(item[3],TweenInfo.new(.46),{Offset=Vector2.new(-direction*.2,0),Rotation=direction*210}):Play()
        end
        waitForIntroSecond(5.0)
        for _,item in ipairs(dice) do
            local direction=item[5]>0 and 1 or -1
            TweenService:Create(item[1],TweenInfo.new(.58,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=item[4],Rotation=item[1].Rotation+direction*720}):Play()
            TweenService:Create(item[2],TweenInfo.new(.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
            TweenService:Create(item[3],TweenInfo.new(.58),{Offset=Vector2.new(direction*.3,0),Rotation=direction*395}):Play()
        end
        local center,centerScale,centerGrad=makeIntroDie(98,UDim2.new(.5,0,1.18,0),6); centerScale.Scale=.56; center.GroupTransparency=.08; center.ZIndex=40
        TweenService:Create(center,TweenInfo.new(.82,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out),{Position=UDim2.new(.5,0,.5,0),Rotation=1440,GroupTransparency=0}):Play()
        TweenService:Create(centerScale,TweenInfo.new(.66,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play(); TweenService:Create(centerGrad,TweenInfo.new(.82),{Rotation=430,Offset=Vector2.new(.42,0)}):Play()
        task.wait(.76)
        local impact=Instance.new("Frame",stage); impact.AnchorPoint=Vector2.new(.5,.5); impact.Position=UDim2.fromScale(.5,.5); impact.Size=UDim2.fromOffset(80,80); impact.BackgroundTransparency=1; impact.ZIndex=15
        Instance.new("UICorner",impact).CornerRadius=UDim.new(1,0); local impactStroke=Instance.new("UIStroke",impact); impactStroke.Color=_GACC.accent; impactStroke.Thickness=3; impactStroke.Transparency=.05
        TweenService:Create(impact,TweenInfo.new(.52,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(310,310)}):Play(); TweenService:Create(impactStroke,TweenInfo.new(.52),{Transparency=1,Thickness=1}):Play()
        for i=1,12 do
            local spark=Instance.new("Frame",stage); spark.AnchorPoint=Vector2.new(.5,.5); spark.Position=UDim2.fromScale(.5,.5); spark.Size=UDim2.fromOffset(i%3==0 and 6 or 3,i%3==0 and 18 or 12)
            spark.BackgroundColor3=i%2==0 and _GACC.accent or Color3.fromRGB(245,247,255); spark.BorderSizePixel=0; spark.ZIndex=16; spark.Rotation=i*30; Instance.new("UICorner",spark).CornerRadius=UDim.new(1,0)
            local angle=math.rad(i*30); local radius=115+(i%3)*18
            TweenService:Create(spark,TweenInfo.new(.48,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.new(.5,math.cos(angle)*radius,.5,math.sin(angle)*radius),BackgroundTransparency=1,Rotation=i*30+90}):Play()
        end
        TweenService:Create(centerScale,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=.88}):Play(); task.wait(.12); TweenService:Create(centerScale,TweenInfo.new(.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
        task.wait(.55); for _,item in ipairs(dice) do TweenService:Create(item[1],TweenInfo.new(.38,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Position=UDim2.fromScale(.5,.5),Rotation=item[1].Rotation+180,GroupTransparency=1}):Play(); TweenService:Create(item[2],TweenInfo.new(.38),{Scale=.3}):Play() end
        TweenService:Create(center,TweenInfo.new(.34,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Position=UDim2.new(.5,0,.45,0),Rotation=1530,GroupTransparency=1}):Play(); TweenService:Create(centerScale,TweenInfo.new(.34),{Scale=.55}):Play()
        task.wait(.25)
        local title=Instance.new("TextLabel",stage); title.AnchorPoint=Vector2.new(.5,.5); title.Position=UDim2.new(.5,0,.62,0); title.Size=UDim2.new(0,360,0,80)
        title.BackgroundTransparency=1; title.RichText=true; title.Text='DICE <font color="rgb(166,170,182)">PRIVATE</font>'; title.TextColor3=Color3.fromRGB(245,247,255); title.TextSize=46; title.Font=Enum.Font.GothamBlack
        title.TextTransparency=1; title.TextStrokeColor3=Color3.fromRGB(10,10,16); title.TextStrokeTransparency=1; title.ZIndex=30
        TweenService:Create(title,TweenInfo.new(.52,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(.5,0,.5,0),TextTransparency=0,TextStrokeTransparency=.3}):Play()
        local underline=Instance.new("Frame",stage); underline.AnchorPoint=Vector2.new(.5,.5); underline.Position=UDim2.new(.5,0,.555,0); underline.Size=UDim2.fromOffset(0,2); underline.BackgroundColor3=_GACC.accent; underline.BorderSizePixel=0; underline.ZIndex=30; Instance.new("UICorner",underline).CornerRadius=UDim.new(1,0)
        TweenService:Create(underline,TweenInfo.new(.55,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(148,2)}):Play()
        task.wait(1.25); TweenService:Create(title,TweenInfo.new(.38,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Position=UDim2.new(.5,0,.42,0),TextTransparency=1,TextStrokeTransparency=1}):Play()
        TweenService:Create(underline,TweenInfo.new(.3,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Size=UDim2.fromOffset(0,2),BackgroundTransparency=1}):Play()
        task.wait(.4); pcall(function() introGui:Destroy() end)
    end)
end

repeat task.wait() until game:IsLoaded()

local CANDY_SKY_TAG = "MoveeSkyTheme"
local currentSkyTheme = "Night"
local CANDY_SKY_PRESETS = {
    ["Off"]={kind="off"},
    ["Night"]={clock=22,brightness=2,ambient={110,100,130},outAmb={120,110,140},sky={stars=4000,moon=18,sun=0,moonTex=true},atm={dens=0.45,color={120,60,180},decay={60,20,100},glare=0.5,haze=1.2}},
    ["Aurora"]={clock=14,brightness=3,ambient={150,120,150},outAmb={160,130,150},atm={dens=0.55,color={255,80,200},decay={255,20,150},glare=2.5,haze=3},clouds={cover=0.7,dens=0.7,color={255,240,250}}},
    ["Sunset"]={clock=17.2,brightness=2.5,ambient={170,120,100},outAmb={180,130,110},sky={stars=0,sun=25,moon=0},atm={dens=0.5,color={255,130,60},decay={255,80,30},glare=2,haze=2.5},clouds={cover=0.55,dens=0.55,color={255,200,140}}},
    ["Galaxy"]={clock=0,brightness=1.5,ambient={70,60,100},outAmb={80,70,110},sky={stars=10000,moon=30,sun=0},atm={dens=0.15,color={40,20,80},decay={20,10,50},glare=0.3,haze=0.5}},
    ["Cyber"]={clock=21,brightness=2.2,ambient={90,130,170},outAmb={100,140,180},sky={stars=2000,moon=12},atm={dens=0.4,color={0,200,255},decay={150,0,255},glare=2,haze=2},clouds={cover=0.4,dens=0.6,color={100,200,255}}},
    ["Sakura"]={clock=11,brightness=3.5,ambient={170,150,160},outAmb={180,160,170},sky={sun=8},atm={dens=0.3,color={255,200,220},decay={255,170,200},glare=1,haze=1.5},clouds={cover=0.6,dens=0.4,color={255,250,252}}},
    ["Pink Night"]={clock=23,brightness=2.2,ambient={120,60,110},outAmb={140,70,120},sky={stars=5000,moon=22,sun=0,moonTex=true},atm={dens=0.5,color={255,80,180},decay={140,30,100},glare=0.7,haze=1.4},clouds={cover=0.3,dens=0.5,color={180,90,150}}},
    ["Blood Moon"]={clock=22.5,brightness=1.6,ambient={130,40,40},outAmb={150,50,50},sky={stars=1500,moon=28,sun=0,moonTex=true},atm={dens=0.6,color={220,30,30},decay={120,10,10},glare=1.4,haze=2},clouds={cover=0.5,dens=0.7,color={120,30,30}}},
    ["Emerald Dawn"]={clock=6.5,brightness=2.8,ambient={130,170,140},outAmb={140,180,150},sky={sun=18,moon=0,stars=0},atm={dens=0.4,color={80,200,140},decay={40,150,90},glare=1.8,haze=2.2},clouds={cover=0.5,dens=0.5,color={200,255,220}}},
    ["Volcanic"]={clock=19,brightness=2,ambient={180,80,40},outAmb={200,90,50},sky={stars=200,sun=12,moon=0},atm={dens=0.75,color={255,60,0},decay={180,20,0},glare=3,haze=3.5},clouds={cover=0.8,dens=0.9,color={120,40,20}}},
    ["Arctic"]={clock=9,brightness=3.2,ambient={200,220,235},outAmb={210,230,245},sky={sun=10,stars=0,moon=0},atm={dens=0.3,color={180,220,255},decay={140,200,240},glare=1.5,haze=1.8},clouds={cover=0.7,dens=0.6,color={250,253,255}}},
    ["Midnight Ocean"]={clock=1.5,brightness=1.7,ambient={60,90,130},outAmb={70,100,140},sky={stars=6000,moon=24,sun=0,moonTex=true},atm={dens=0.5,color={20,60,140},decay={10,30,90},glare=0.6,haze=1.5}},
    ["Vaporwave"]={clock=19.5,brightness=2.4,ambient={180,120,200},outAmb={190,130,210},sky={stars=1000,moon=14},atm={dens=0.45,color={255,100,220},decay={120,60,255},glare=2.2,haze=2.4},clouds={cover=0.5,dens=0.55,color={200,150,255}}},
    ["Toxic"]={clock=13,brightness=2.5,ambient={140,180,80},outAmb={150,190,90},atm={dens=0.55,color={100,220,40},decay={60,150,20},glare=1.8,haze=2.6},clouds={cover=0.65,dens=0.7,color={180,255,120}}},
    ["Solar Eclipse"]={clock=12,brightness=0.9,ambient={50,40,60},outAmb={60,50,70},sky={stars=3500,sun=22,moon=0},atm={dens=0.5,color={255,140,40},decay={30,20,40},glare=2.8,haze=1.8}},
    ["Hellscape"]={clock=18,brightness=1.8,ambient={200,60,30},outAmb={220,70,40},sky={stars=100,sun=30,moon=0},atm={dens=0.85,color={255,30,0},decay={120,0,0},glare=3.5,haze=4},clouds={cover=0.95,dens=0.95,color={80,20,10}}},
    ["Heaven"]={clock=12,brightness=4,ambient={240,235,210},outAmb={250,245,220},sky={sun=16,moon=0,stars=0},atm={dens=0.25,color={255,250,220},decay={255,240,200},glare=3,haze=1.5},clouds={cover=0.85,dens=0.5,color={255,255,255}}},
    ["Storm"]={clock=15,brightness=1.4,ambient={90,90,110},outAmb={100,100,120},sky={stars=0,sun=6,moon=0},atm={dens=0.65,color={80,90,120},decay={40,50,80},glare=0.5,haze=3},clouds={cover=0.95,dens=0.95,color={60,65,80}}},
    ["Sunrise"]={clock=6.2,brightness=2.8,ambient={220,180,130},outAmb={230,190,140},sky={sun=22,stars=0,moon=0},atm={dens=0.45,color={255,180,100},decay={255,140,80},glare=2.4,haze=2.2},clouds={cover=0.4,dens=0.4,color={255,220,180}}},
    ["Deep Space"]={clock=0,brightness=1,ambient={30,25,50},outAmb={40,35,60},sky={stars=15000,moon=0,sun=0},atm={dens=0.08,color={15,5,40},decay={5,0,20},glare=0.2,haze=0.3}},
    ["Lavender Dream"]={clock=18.5,brightness=2.6,ambient={180,160,220},outAmb={190,170,230},sky={stars=800,moon=16,sun=0},atm={dens=0.4,color={200,160,255},decay={160,120,220},glare=1.4,haze=1.8},clouds={cover=0.55,dens=0.5,color={220,200,255}}},
    ["Inferno"]={clock=17.5,brightness=2.2,ambient={220,100,40},outAmb={235,110,50},sky={sun=26,moon=0,stars=0},atm={dens=0.6,color={255,90,20},decay={200,40,0},glare=3,haze=3.2},clouds={cover=0.7,dens=0.7,color={200,80,40}}},
    ["Mint Sky"]={clock=10,brightness=3.2,ambient={180,230,210},outAmb={190,240,220},sky={sun=10},atm={dens=0.32,color={150,255,210},decay={100,220,180},glare=1.6,haze=1.6},clouds={cover=0.55,dens=0.45,color={240,255,250}}},
}
local SkyOrder={"Off","Night","Aurora","Sunset","Galaxy","Cyber","Sakura","Pink Night","Blood Moon","Emerald Dawn","Volcanic","Arctic","Midnight Ocean","Vaporwave","Toxic","Solar Eclipse","Hellscape","Heaven","Storm","Sunrise","Deep Space","Lavender Dream","Inferno","Mint Sky"}
local function candyColor(rgb) return Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end
local function CandyApplyCustomSky(mode)
    for _,child in ipairs(Lighting:GetChildren()) do if child:GetAttribute(CANDY_SKY_TAG) then pcall(function() child:Destroy() end) end end
    local terrain=workspace:FindFirstChildOfClass("Terrain")
    if terrain then for _,child in ipairs(terrain:GetChildren()) do if child:GetAttribute(CANDY_SKY_TAG) then pcall(function() child:Destroy() end) end end end
    local preset=CANDY_SKY_PRESETS[mode]
    if not preset or preset.kind=="off" then Lighting.ClockTime=14;Lighting.Brightness=2;Lighting.OutdoorAmbient=Color3.fromRGB(127,127,127);Lighting.Ambient=Color3.fromRGB(127,127,127);Lighting.FogEnd=100000;Lighting.GlobalShadows=true;return end
    Lighting.FogStart=0;Lighting.FogEnd=100000;Lighting.FogColor=Color3.fromRGB(200,200,200);Lighting.ColorShift_Top=Color3.fromRGB(0,0,0);Lighting.ColorShift_Bottom=Color3.fromRGB(0,0,0);Lighting.GlobalShadows=true
    Lighting.ClockTime=preset.clock or 14;Lighting.Brightness=preset.brightness or 2
    if preset.outAmb then Lighting.OutdoorAmbient=candyColor(preset.outAmb) end
    if preset.ambient then Lighting.Ambient=candyColor(preset.ambient) end
    if preset.sky then
        local skyInst=Instance.new("Sky");skyInst:SetAttribute(CANDY_SKY_TAG,true)
        if preset.sky.stars then skyInst.StarCount=preset.sky.stars end
        if preset.sky.moon then skyInst.MoonAngularSize=preset.sky.moon end
        if preset.sky.sun then skyInst.SunAngularSize=preset.sky.sun end
        if preset.sky.moonTex then skyInst.MoonTextureId="rbxasset://sky/moon.jpg" end
        skyInst.Parent=Lighting
    end
    if preset.atm then
        local atm=Instance.new("Atmosphere");atm:SetAttribute(CANDY_SKY_TAG,true)
        atm.Density=preset.atm.dens or 0.3;atm.Color=candyColor(preset.atm.color);atm.Decay=candyColor(preset.atm.decay);atm.Glare=preset.atm.glare or 1;atm.Haze=preset.atm.haze or 1;atm.Parent=Lighting
    end
    if preset.clouds and terrain then
        local clouds=Instance.new("Clouds");clouds:SetAttribute(CANDY_SKY_TAG,true)
        clouds.Cover=preset.clouds.cover or 0.5;clouds.Density=preset.clouds.dens or 0.5;clouds.Color=candyColor(preset.clouds.color);clouds.Parent=terrain
    end
end

local TS=TweenService
local LP=Players.LocalPlayer
local NS,CS=59,29
local LAGGER_SPEED=30
local LAGGER_CARRY_SPEED=15
local carrySpeedActive = false
local laggerModeEnabled = false

local antiRagdollEnabled,infJumpEnabled=false,false
local medusaCounterEnabled,batCounterEnabled,unwalkEnabled=false,false,false
local medusaDebounce,medusaLastUsed,dropActive=false,0,false
local autoLeftEnabled,autoRightEnabled=false,false
local autoLeftSetVisual,autoRightSetVisual=nil,nil
local speedLabel=nil
local autoBatEnabled=false
local batDesyncTpEnabled=false
local batDesyncTpSetVisual=nil
local autoSwingEnabled=true
local autoMoveSwingEnabled=false
local autoMoveSwingInterval=0.3
local _alSwingDebounce=false
local _arSwingDebounce=false
local autoBatSetVisual=nil
local resetAutoBatMotion=nil
local setBatCounterVisual=nil
local startBatCounter,stopBatCounter
local antiLagEnabled,removeAccessoriesEnabled,antiLagDescConn=false,false,nil
local stretchRezEnabled,stretchRezConn,setStretchRezVisual=false,nil,nil
local unwalkSavedAnimate,_anyKeyListening=nil,false
local autoTPEnabled,autoTPHeight,autoTPConn,setAutoTPVisual=false,20,nil,nil
local cursedResetRemote=nil
local CURSED_RESET_GUID="f888ee6e-c86d-46e1-93d7-0639d6635d42"
local guiTransparencyEnabled,mobileButtonsEnabled,mobileButtonsLocked=false,true,true
local mobileButtonsSize=64
local circleButtonsEnabled=false
local stealBarFrame
local mobBtnRefs={}
local mobGuiRef=nil
local fovValue=80
local fovOptions={80,120,180}
local fovIndex=1
local laggerModePillRef=nil
local carryModePillRef=nil
local autoSwitchSpeedEnabled=false
local mobBtnTransparencyEnabled=false
local perButtonDragEnabled=false
_GACC.mobileButtonPositions={}
_GACC.mobileGroupPosition={x=.86,y=.5}
_GACC.mobileButtonsGrouped=false
_GACC.pingDismissed=false
local brainrotDetected=false
_GACC.safeModeEnabled=false
_GACC.safeModeActive=false
_GACC.autoCarrySpeedEnabled=false
local activeBatBillboard=nil
local activeMedusaBillboard=nil
local espEnabled=false
local espObjects={}
local espConnections={}
local ragdollGuiEnabled=true
local persistentRagdollGui=nil
local uiLocked=false
local infJumpMode="manual"
local holdInfJumpConn=nil
local DROP_ASCEND_DURATION=0.2
local DROP_ASCEND_SPEED=150
local _GuiKeys = nil
local pingNotification = nil
local _perfFps,_perfPing=0,0

local bgImageRef = nil
local bgImageContainer = nil
local bgImageCorner = nil
local function applyBackgroundImage()
    if bgImageRef then bgImageRef.Visible = false end
    backgroundEnabled = false
end

local RembembiAnims = {
    WalkAnim  = 73718308412641,
    RunAnim   = 135515454877967,
    JumpAnim  = 78508480717326,
    FallAnim  = 78147885297412,
    SwimIdle  = 129183123083281,
    Swim      = 110657013921774,
    ClimbAnim = 129447497744818,
    Animation1 = 92849173543269,
    Animation2 = 132238900951109,
}

local startAnimToggle, stopAnimToggle
do
    local AnimRefs = { heartbeat=nil, savedAnimate=nil, originalAnims=nil }
    local LP_anim = Players.LocalPlayer
    local function isRembembiAnim(id)
        if not id then return false end
        for _,v in pairs(RembembiAnims) do if v == id then return true end end
        return false
    end
    local function saveOriginalAnims(char)
        local animate = char:FindFirstChild("Animate")
        if not animate then return end
        local function g(obj) return obj and obj.AnimationId or nil end
        local ids = {
            walk=g(animate.walk and animate.walk.WalkAnim),
            run=g(animate.run and animate.run.RunAnim),
            jump=g(animate.jump and animate.jump.JumpAnim),
            fall=g(animate.fall and animate.fall.FallAnim),
            climb=g(animate.climb and animate.climb.ClimbAnim),
            swim=g(animate.swim and animate.swim.Swim),
            swimidle=g(animate.swimidle and animate.swimidle.SwimIdle),
            idle1=g(animate.idle and animate.idle.Animation1),
            idle2=g(animate.idle and animate.idle.Animation2),
        }
        if not isRembembiAnim(ids.walk) then AnimRefs.originalAnims = ids end
    end
    local function applyRembembiAnims(char)
        local animate = char:FindFirstChild("Animate")
        if not animate then return end
        local function s(obj, id) if obj then obj.AnimationId = "rbxassetid://" .. id end end
        s(animate.walk and animate.walk.WalkAnim, RembembiAnims.WalkAnim)
        s(animate.run and animate.run.RunAnim, RembembiAnims.RunAnim)
        s(animate.jump and animate.jump.JumpAnim, RembembiAnims.JumpAnim)
        s(animate.fall and animate.fall.FallAnim, RembembiAnims.FallAnim)
        s(animate.climb and animate.climb.ClimbAnim, RembembiAnims.ClimbAnim)
        s(animate.swim and animate.swim.Swim, RembembiAnims.Swim)
        s(animate.swimidle and animate.swimidle.SwimIdle, RembembiAnims.SwimIdle)
        s(animate.idle and animate.idle.Animation1, RembembiAnims.Animation1)
        s(animate.idle and animate.idle.Animation2, RembembiAnims.Animation2)
    end
    local function restoreOriginalAnims(char)
        local orig = AnimRefs.originalAnims
        if not orig then return end
        local animate = char:FindFirstChild("Animate")
        if not animate then return end
        local function s(obj, id) if obj and id then obj.AnimationId = id end end
        s(animate.walk and animate.walk.WalkAnim, orig.walk)
        s(animate.run and animate.run.RunAnim, orig.run)
        s(animate.jump and animate.jump.JumpAnim, orig.jump)
        s(animate.fall and animate.fall.FallAnim, orig.fall)
        s(animate.climb and animate.climb.ClimbAnim, orig.climb)
        s(animate.swim and animate.swim.Swim, orig.swim)
        s(animate.swimidle and animate.swimidle.SwimIdle, orig.swimidle)
        s(animate.idle and animate.idle.Animation1, orig.idle1)
        s(animate.idle and animate.idle.Animation2, orig.idle2)
    end
    function startAnimToggle()
        if AnimRefs.heartbeat then AnimRefs.heartbeat:Disconnect(); AnimRefs.heartbeat = nil end
        local char = LP_anim.Character
        if char then saveOriginalAnims(char); applyRembembiAnims(char) end
        AnimRefs.heartbeat = RunService.Heartbeat:Connect(function()
            if not animEnabled then return end
            local c = LP_anim.Character
            if c then applyRembembiAnims(c) end
        end)
    end
    function stopAnimToggle()
        if AnimRefs.heartbeat then AnimRefs.heartbeat:Disconnect(); AnimRefs.heartbeat = nil end
        local char = LP_anim.Character
        if char then restoreOriginalAnims(char) end
    end
end

local cursedInstaReset
_GACC.extras={}
do
local ANIMATION_PACKS={
    ["Adidas Sports"]={WalkAnim=18537392113,RunAnim=18537384940,JumpAnim=18537380791,FallAnim=18537367238,SwimIdle=18537387180,Swim=18537389531,Animation1=18537376492,Animation2=18537371272,ClimbAnim=18537363391},
    ["Adidas Community"]={WalkAnim=122150855457006,RunAnim=82598234841035,JumpAnim=75290611992385,FallAnim=98600215928904,SwimIdle=109346520324160,Swim=133308483266208,Animation1=122257458498464,Animation2=102357151005774,ClimbAnim=88763136693023},
    ["Adidas Aura"]={WalkAnim=83842218823011,RunAnim=118320322718866,JumpAnim=109996626521204,FallAnim=95603166884636,SwimIdle=94922130551805,Swim=134530128383903,Animation1=110211186840347,Animation2=114191137265065,ClimbAnim=97824616490448},
    ["Wicked Popular"]={WalkAnim=92072849924640,RunAnim=72301599441680,JumpAnim=104325245285198,FallAnim=121152442762481,Animation1=118832222982049,ClimbAnim=131326830509784,SwimIdle=113199415118199,Swim=99384245425157,Animation2=76049494037641},
    Elder={WalkAnim=10921111375,RunAnim=10921104374,JumpAnim=10921107367,FallAnim=10921105765,SwimIdle=10921110146,Swim=10921108971,ClimbAnim=10921100400,Animation1=10921101664,Animation2=10921102574},
    Zombie={WalkAnim=10921355261,RunAnim=616163682,JumpAnim=10921351278,FallAnim=10921350320,SwimIdle=10921353442,Swim=10921352344,Animation1=10921344533,Animation2=10921345304,ClimbAnim=10921343576},
    Mage={WalkAnim=10921152678,RunAnim=10921148209,JumpAnim=10921149743,FallAnim=10921148939,SwimIdle=10921151661,Swim=10921150788,ClimbAnim=10921143404,Animation1=10921144709,Animation2=10921145797},
    ["Catwalk Glam"]={WalkAnim=109168724482748,RunAnim=81024476153754,JumpAnim=116936326516985,FallAnim=92294537340807,SwimIdle=98854111361360,Swim=134591743181628,ClimbAnim=119377220967554,Animation1=133806214992291,Animation2=94970088341563},
    Astronaut={WalkAnim=10921046031,RunAnim=10921039308,JumpAnim=10921042494,FallAnim=10921040576,SwimIdle=10921045006,Swim=10921044000,ClimbAnim=10921032124,Animation1=10921034824,Animation2=10921036806},
    ['Wicked "Dancing Through Life"']={WalkAnim=73718308412641,RunAnim=135515454877967,JumpAnim=78508480717326,FallAnim=78147885297412,SwimIdle=129183123083281,Swim=110657013921774,ClimbAnim=129447497744818,Animation1=92849173543269,Animation2=132238900951109},
    Werewolf={WalkAnim=10921342074,RunAnim=10921336997,FallAnim=10921337907,SwimIdle=10921341319,Swim=10921340419,ClimbAnim=10921329322,Animation1=10921330408,Animation2=10921333667},
    Superhero={WalkAnim=10921298616,RunAnim=10921291831,JumpAnim=10921294559,FallAnim=10921293373,SwimIdle=10921297391,Swim=10921295495,ClimbAnim=10921286911,Animation1=10921288909,Animation2=10921290167},
    Toy={WalkAnim=10921312010,RunAnim=10921306285,JumpAnim=10921308158,FallAnim=10921307241,SwimIdle=10921310341,Swim=10921309319,ClimbAnim=10921300839,Animation1=10921301576},
    ["No Boundaries"]={WalkAnim=18747074203,RunAnim=18747070484,JumpAnim=18747069148,FallAnim=18747062535,SwimIdle=18747071682,Swim=18747073181,ClimbAnim=18747060903,Animation1=18747067405,Animation2=18747063918},
    NFL={WalkAnim=110358958299415,RunAnim=117333533048078,JumpAnim=119846112151352,FallAnim=129773241321032,SwimIdle=79090109939093,Swim=132697394189921,ClimbAnim=134630013742019,Animation1=92080889861410,Animation2=74451233229259},
    ["Amazon Unboxed"]={WalkAnim=90478085024465,RunAnim=134824450619865,JumpAnim=121454505477205,FallAnim=94788218468396,SwimIdle=129126268464847,Swim=105962919001086,ClimbAnim=121145883950231,Animation1=98281136301627},
    Vampire={WalkAnim=10921326949,RunAnim=10921320299,JumpAnim=10921322186,FallAnim=10921321317,SwimIdle=10921325443,Swim=10921324408,ClimbAnim=10921314188,Animation1=10921315373},
    Ninja={Run=656118852,Walk=656121766,Jump=656117878,Fall=656115606,Swim=656119721,SwimIdle=656121397,Climb=656114359,Idle={656117400,656118341,886742569}},
    Robot={Run=616091570,Walk=616095330,Jump=616090535,Fall=616087089,Swim=616092998,SwimIdle=616094091,Climb=616086039,Idle={616088211,616089559,885531463}},
    Levitation={Run=616010382,Walk=616013216,Jump=616008936,Fall=616005863,Swim=616011509,SwimIdle=616012453,Climb=616003713,Idle={616006778,616008087,886862142}},
    Stylish={Run=616140816,Walk=616146177,Jump=616139451,Fall=616134815,Swim=616143378,SwimIdle=616144772,Climb=616133594,Idle={616136790,616138447,886888594}},
    Bubbly={Run=910025107,Walk=910034870,Jump=910016857,Fall=910001910,Swim=910028158,SwimIdle=910030921,Climb=909997997,Idle={910004836,910009958,1018536639}},
    Cartoon={Run=742638842,Walk=742640026,Jump=742637942,Fall=742637151,Swim=742639220,SwimIdle=742639812,Climb=742636889,Idle={742637544,742638445,885477856}},
}
local selectedAnimPack="Adidas Sports"
local headlessEnabled=false
local korbloxEnabled=false
local bodyLockEnabled=false
local bodyLockRadius=60
local bodyLockConn=nil
local autoResetOnDeath=false
local deathResetConn=nil
local deathResetCharConn=nil
local HEADLESS_MESH_ID="rbxassetid://1095708"
local KORBLOX_MESH_ID="rbxassetid://101851696"
local KORBLOX_TEXTURE_ID="rbxassetid://101851254"
local cosmeticState=setmetatable({},{__mode="k"})

local function animPick(pack,...)
    for i=1,select("#",...) do local v=pack[select(i,...)]; if v~=nil then return v end end
end
local function ensureAnimation(folder,name)
    if not folder then return nil end
    local obj=folder:FindFirstChild(name)
    if not obj then obj=Instance.new("Animation"); obj.Name=name; obj.Parent=folder end
    return obj
end
local applyingAnimPack=false
local function applyAnimationPack(packName,char)
    if applyingAnimPack then return false end
    local pack=ANIMATION_PACKS[packName]; if not pack then return false end
    applyingAnimPack=true
    char=char or LP.Character
    if not char then applyingAnimPack=false; return false end
    local animate,animateReady
    for _=1,40 do
        animate=char:FindFirstChild("Animate")
        if animate and animate:FindFirstChild("idle") and animate:FindFirstChild("run") and animate:FindFirstChild("walk") then animateReady=true; break end
        task.wait(.1)
    end
    if not animateReady then applyingAnimPack=false; return false end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then for _,track in ipairs(hum:GetPlayingAnimationTracks()) do pcall(function() track:Stop(0) end) end end
    local function set(folder,objName,id) local obj=ensureAnimation(animate:FindFirstChild(folder),objName); if obj and id then obj.AnimationId="rbxassetid://"..tostring(id) end end
    set("walk","WalkAnim",animPick(pack,"WalkAnim","Walk")); set("run","RunAnim",animPick(pack,"RunAnim","Run"))
    set("jump","JumpAnim",animPick(pack,"JumpAnim","Jump")); set("fall","FallAnim",animPick(pack,"FallAnim","Fall"))
    set("climb","ClimbAnim",animPick(pack,"ClimbAnim","Climb")); set("swim","Swim",animPick(pack,"Swim"))
    set("swimidle","SwimIdle",animPick(pack,"SwimIdle") or animPick(pack,"Swim"))
    local idle=animate:FindFirstChild("idle")
    if idle then
        local ids=pack.Idle or {animPick(pack,"Animation1"),animPick(pack,"Animation2")}
        if ids[1] or ids[2] then
            local id1=ids[1] or ids[2]; local id2=ids[2] or ids[1]
            local a1=ensureAnimation(idle,"Animation1"); local a2=ensureAnimation(idle,"Animation2")
            if a1 then a1.AnimationId="rbxassetid://"..tostring(id1) end
            if a2 then a2.AnimationId="rbxassetid://"..tostring(id2) end
            for i=3,#ids do local a=ensureAnimation(idle,"Animation"..i); if a then a.AnimationId="rbxassetid://"..tostring(ids[i]) end end
        end
    end
    animate.Disabled=true; task.wait(.06); animate.Disabled=false
    if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Landed); task.wait(.03); hum:ChangeState(Enum.HumanoidStateType.Running) end) end
    selectedAnimPack=packName; applyingAnimPack=false; return true
end

local function applyHeadless(char,enabled)
    local head=char and char:FindFirstChild("Head"); if not head then return end
    local state=cosmeticState[char] or {}; cosmeticState[char]=state
    if enabled then
        if state.headTransparency==nil then state.headTransparency=head.Transparency; state.headCanCollide=head.CanCollide; local face=head:FindFirstChild("face"); state.face=face and face:Clone() or nil end
        head.Transparency=1; head.CanCollide=false
        local face=head:FindFirstChild("face"); if face then face:Destroy() end
        local old=head:FindFirstChild("DiceHeadlessMesh"); if old then old:Destroy() end
        local mesh=Instance.new("SpecialMesh",head); mesh.Name="DiceHeadlessMesh"; mesh.MeshType=Enum.MeshType.FileMesh; mesh.MeshId=HEADLESS_MESH_ID; mesh.Scale=Vector3.new(.001,.001,.001)
    else
        local mesh=head:FindFirstChild("DiceHeadlessMesh"); if mesh then mesh:Destroy() end
        if state.headTransparency~=nil then
            head.Transparency=state.headTransparency; head.CanCollide=state.headCanCollide
            if state.face and not head:FindFirstChild("face") then state.face:Clone().Parent=head end
            state.headTransparency=nil; state.headCanCollide=nil; state.face=nil
        end
    end
end

local function applyKorblox(char,enabled)
    local hum=char and char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local state=cosmeticState[char] or {}; cosmeticState[char]=state
    if hum.RigType==Enum.HumanoidRigType.R6 then
        local leg=char:FindFirstChild("Right Leg"); if not leg then return end
        if enabled then
            if not state.r6LegColor then state.r6LegColor=leg.Color; state.r6Meshes={}; for _,v in ipairs(leg:GetChildren()) do if v:IsA("SpecialMesh") or v:IsA("CharacterMesh") then table.insert(state.r6Meshes,v:Clone()); v:Destroy() end end end
            leg.Color=Color3.fromRGB(64,64,64); local old=leg:FindFirstChild("DiceKorbloxMesh"); if old then old:Destroy() end
            local mesh=Instance.new("SpecialMesh",leg); mesh.Name="DiceKorbloxMesh"; mesh.MeshType=Enum.MeshType.FileMesh; mesh.MeshId=KORBLOX_MESH_ID; mesh.TextureId=KORBLOX_TEXTURE_ID
        else
            local mesh=leg:FindFirstChild("DiceKorbloxMesh"); if mesh then mesh:Destroy() end
            if state.r6LegColor then leg.Color=state.r6LegColor end
            if state.r6Meshes then for _,v in ipairs(state.r6Meshes) do v:Clone().Parent=leg end end
            state.r6LegColor=nil; state.r6Meshes=nil
        end
    else
        local upper=char:FindFirstChild("RightUpperLeg"); local lower=char:FindFirstChild("RightLowerLeg"); local foot=char:FindFirstChild("RightFoot")
        if not upper then return end
        if enabled then
            if not state.r15Transparency then state.r15Transparency={upper.Transparency,lower and lower.Transparency or 0,foot and foot.Transparency or 0} end
            upper.Transparency=1; if lower then lower.Transparency=1 end; if foot then foot.Transparency=1 end
            local old=char:FindFirstChild("DiceKorbloxLeg"); if old then old:Destroy() end
            local leg=Instance.new("Part",char); leg.Name="DiceKorbloxLeg"; leg.Size=Vector3.new(1,2,1); leg.Anchored=false; leg.CanCollide=false; leg.Massless=true; leg.Color=Color3.fromRGB(64,64,64)
            local mesh=Instance.new("SpecialMesh",leg); mesh.MeshType=Enum.MeshType.FileMesh; mesh.MeshId=KORBLOX_MESH_ID; mesh.TextureId=KORBLOX_TEXTURE_ID
            local weld=Instance.new("Weld",leg); weld.Name="DiceKorbloxWeld"; weld.Part0=upper; weld.Part1=leg; weld.C0=CFrame.new(0,-.8,0)
        else
            local vals=state.r15Transparency
            if vals then upper.Transparency=vals[1]; if lower then lower.Transparency=vals[2] end; if foot then foot.Transparency=vals[3] end end
            local leg=char:FindFirstChild("DiceKorbloxLeg"); if leg then leg:Destroy() end; state.r15Transparency=nil
        end
    end
end

local function nearestBodyLockTarget()
    local char=LP.Character; local root=char and char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local nearest,shortest=nil,math.huge
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LP and plr.Character then local tr=plr.Character:FindFirstChild("HumanoidRootPart"); local hum=plr.Character:FindFirstChildOfClass("Humanoid")
            if tr and hum and hum.Health>0 then local dist=(tr.Position-root.Position).Magnitude; if dist<=bodyLockRadius and dist<shortest then shortest=dist; nearest=plr end end
        end
    end
    return nearest
end
local function stopBodyLock()
    bodyLockEnabled=false; if bodyLockConn then bodyLockConn:Disconnect(); bodyLockConn=nil end
    local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.AutoRotate=true end
end
local function startBodyLock()
    if bodyLockConn then return end; bodyLockEnabled=true
    bodyLockConn=RunService.Heartbeat:Connect(function()
        if not bodyLockEnabled then return end
        local char=LP.Character; local root=char and char:FindFirstChild("HumanoidRootPart"); local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health<=0 then return end
        local target=nearestBodyLockTarget(); local tr=target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if tr then local offset=Vector3.new(tr.Position.X,root.Position.Y,tr.Position.Z)-root.Position
            if offset.Magnitude>.1 then hum.AutoRotate=false; local cross=root.CFrame.LookVector:Cross(offset.Unit); local av=root.AssemblyAngularVelocity; root.AssemblyAngularVelocity=Vector3.new(av.X,cross.Y*40,av.Z) end
        else hum.AutoRotate=true end
    end)
end

local function setupAutoResetOnDeath()
    if deathResetConn then deathResetConn:Disconnect(); deathResetConn=nil end
    if autoResetOnDeath then
        local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then deathResetConn=hum.Died:Connect(function() if autoResetOnDeath and cursedInstaReset then cursedInstaReset() end end) end
        if not deathResetCharConn then deathResetCharConn=LP.CharacterAdded:Connect(function() task.wait(.5); setupAutoResetOnDeath() end) end
    elseif deathResetCharConn then deathResetCharConn:Disconnect(); deathResetCharConn=nil end
end

_GACC.extras.packs=ANIMATION_PACKS
_GACC.extras.getPack=function() return selectedAnimPack end
_GACC.extras.setPack=function(name,applyNow,char)
    if ANIMATION_PACKS[name] then selectedAnimPack=name; if applyNow then return applyAnimationPack(name,char) end; return true end
    return false
end
_GACC.extras.applyPack=applyAnimationPack
_GACC.extras.getHeadless=function() return headlessEnabled end
_GACC.extras.setHeadless=function(on,char) headlessEnabled=on==true; if char then applyHeadless(char,headlessEnabled) end end
_GACC.extras.getKorblox=function() return korbloxEnabled end
_GACC.extras.setKorblox=function(on,char) korbloxEnabled=on==true; if char then applyKorblox(char,korbloxEnabled) end end
_GACC.extras.getBodyLock=function() return bodyLockEnabled end
_GACC.extras.setBodyLockState=function(on) bodyLockEnabled=on==true end
_GACC.extras.startBodyLock=startBodyLock
_GACC.extras.stopBodyLock=stopBodyLock
_GACC.extras.getBodyLockRadius=function() return bodyLockRadius end
_GACC.extras.setBodyLockRadius=function(v) bodyLockRadius=math.clamp(tonumber(v) or 60,5,200); return bodyLockRadius end
_GACC.extras.getAutoReset=function() return autoResetOnDeath end
_GACC.extras.setAutoResetState=function(on) autoResetOnDeath=on==true end
_GACC.extras.setupAutoReset=setupAutoResetOnDeath
_GACC.extras.onCharacter=function(char)
    applyHeadless(char,headlessEnabled); applyKorblox(char,korbloxEnabled)
    if selectedAnimPack and ANIMATION_PACKS[selectedAnimPack] then task.spawn(function() task.wait(.2); applyAnimationPack(selectedAnimPack,char) end) end
end
_GACC.extras.reset=function(char)
    selectedAnimPack="Adidas Sports"; headlessEnabled=false; korbloxEnabled=false; autoResetOnDeath=false; bodyLockRadius=60
    stopBodyLock(); setupAutoResetOnDeath()
    if char then applyHeadless(char,false); applyKorblox(char,false) end
    task.spawn(function() applyAnimationPack(selectedAnimPack) end)
end
end

-- PARTE 1 FINISCE QUI ══════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
-- PARTE 2 — Funzioni speed, combat, steal, esp, movement, GUI, pannello
-- ═══════════════════════════════════════════════════════════════

local refreshSpeedModeLabel,saveConfig
local startUnwalk,stopUnwalk,setupMedusa,stopMedusaCounter
local startAntiRagdoll,stopAntiRagdoll,startAutoLeft,stopAutoLeft,startAutoRight,stopAutoRight
local startAutoTP,stopAutoTP,enableAntiLag,disableAntiLag,enableStretchRez,disableStretchRez
local startBatAimbot,stopBatAimbot,queueAutoBatStart,runDrop,runTPFloor
local startBatDesyncTp,stopBatDesyncTp
local startAutoSteal,stopAutoSteal,toggleCarryMode,toggleLaggerMode

local findBat = function()
    local c = LP.Character; if not c then return nil end
    local bp = LP:FindFirstChildOfClass("Backpack")
    for _,ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _,ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    return nil
end

local isNearPodiumWithPrompt

local function addShimmerToLabel(lbl,color1,color2)
    local gr=Instance.new("UIGradient",lbl)
    gr.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,  color1 or Color3.fromRGB(150,150,150)),
        ColorSequenceKeypoint.new(0.3,Color3.fromRGB(230,230,230)),
        ColorSequenceKeypoint.new(0.6,color2 or Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1,  color1 or Color3.fromRGB(150,150,150))
    })
    gr.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.3,0),NumberSequenceKeypoint.new(0.5,0,0),NumberSequenceKeypoint.new(1,0.3,0)})
    return gr
end

local fovConn=nil
local function applyFOV()
    if fovConn then fovConn:Disconnect() end
    fovConn=RunService.RenderStepped:Connect(function() local cam=workspace.CurrentCamera;if cam then cam.FieldOfView=fovValue end end)
end
applyFOV()

local function createPingNotification()
    if pingNotification then pcall(function() pingNotification:Destroy() end);pingNotification=nil end
    local sg=Instance.new("ScreenGui");sg.Name="PingNotification";sg.ResetOnSpawn=false;sg.IgnoreGuiInset=true;sg.DisplayOrder=999
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(sg) end end)
    if not pcall(function() sg.Parent=game:GetService("CoreGui") end) then sg.Parent=LP:WaitForChild("PlayerGui") end
    local shadow=Instance.new("Frame",sg);shadow.Size=UDim2.fromOffset(232,58);shadow.Position=UDim2.new(1,20,0,19);shadow.BackgroundColor3=Color3.fromRGB(0,0,0);shadow.BackgroundTransparency=.62;shadow.BorderSizePixel=0;shadow.ZIndex=8;Instance.new("UICorner",shadow).CornerRadius=UDim.new(0,9)
    local card=Instance.new("Frame",sg);card.Size=UDim2.fromOffset(232,58);card.Position=UDim2.new(1,16,0,14);card.BackgroundColor3=Color3.fromRGB(10,10,13);card.BackgroundTransparency=.06;card.BorderSizePixel=0;card.ZIndex=10;card.ClipsDescendants=true;Instance.new("UICorner",card).CornerRadius=UDim.new(0,9)
    local stroke=Instance.new("UIStroke",card);stroke.Color=Color3.fromRGB(66,67,75);stroke.Thickness=1;stroke.Transparency=.25
    local rail=Instance.new("Frame",card);rail.Size=UDim2.new(0,3,1,0);rail.BackgroundColor3=Color3.fromRGB(225,86,78);rail.BorderSizePixel=0;rail.ZIndex=12
    local dot=Instance.new("Frame",card);dot.Size=UDim2.fromOffset(7,7);dot.Position=UDim2.fromOffset(14,13);dot.BackgroundColor3=Color3.fromRGB(225,86,78);dot.BorderSizePixel=0;dot.ZIndex=12;Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    local warn=Instance.new("TextLabel",card);warn.Size=UDim2.fromOffset(98,18);warn.Position=UDim2.fromOffset(28,7);warn.BackgroundTransparency=1;warn.Text="HIGH PING";warn.TextColor3=Color3.fromRGB(232,233,238);warn.Font=Enum.Font.GothamBold;warn.TextSize=11;warn.TextXAlignment=Enum.TextXAlignment.Left;warn.ZIndex=12
    local duel=Instance.new("TextLabel",card);duel.Size=UDim2.fromOffset(120,17);duel.Position=UDim2.fromOffset(14,31);duel.BackgroundTransparency=1;duel.Text="Avoid duels";duel.TextColor3=Color3.fromRGB(155,157,167);duel.Font=Enum.Font.GothamMedium;duel.TextSize=10;duel.TextXAlignment=Enum.TextXAlignment.Left;duel.ZIndex=12
    local pingLbl=Instance.new("TextLabel",card);pingLbl.Size=UDim2.fromOffset(72,24);pingLbl.Position=UDim2.new(1,-98,0,17);pingLbl.BackgroundTransparency=1;pingLbl.Text="-- ms";pingLbl.TextColor3=Color3.fromRGB(224,226,232);pingLbl.Font=Enum.Font.GothamBold;pingLbl.TextSize=15;pingLbl.TextXAlignment=Enum.TextXAlignment.Right;pingLbl.ZIndex=12
    local close=Instance.new("TextButton",card);close.Size=UDim2.fromOffset(20,20);close.Position=UDim2.new(1,-24,0,5);close.BackgroundTransparency=1;close.BorderSizePixel=0;close.ZIndex=15;close.Text="X";close.TextColor3=Color3.fromRGB(115,117,126);close.Font=Enum.Font.GothamBold;close.TextSize=10
    close.MouseButton1Click:Connect(function() _GACC.pingDismissed=true;if pingNotification then pcall(function() pingNotification:Destroy() end);pingNotification=nil end end)
    TweenService:Create(card,TweenInfo.new(.42,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.new(1,-202,0,10)}):Play()
    TweenService:Create(shadow,TweenInfo.new(.42,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.new(1,-198,0,15)}):Play()
    task.spawn(function()
        while card and card.Parent do
            pcall(function() local ping=math.floor(Players.LocalPlayer:GetNetworkPing()*1000);pingLbl.Text=tostring(ping).." ms";pingLbl.TextColor3=ping>=180 and Color3.fromRGB(238,103,92) or Color3.fromRGB(224,226,232) end)
            task.wait(.2)
        end
    end)
    task.delay(7,function()
        if card and card.Parent then
            TweenService:Create(card,TweenInfo.new(.3,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Position=UDim2.new(1,16,0,14)}):Play()
            TweenService:Create(shadow,TweenInfo.new(.3,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Position=UDim2.new(1,20,0,19),BackgroundTransparency=1}):Play()
            task.delay(.34,function() if sg then pcall(function() sg:Destroy() end) end;pingNotification=nil end)
        end
    end)
    pingNotification=sg
    return sg
end

task.spawn(function()
    while true do
        task.wait(1.5)
        pcall(function()
            local ping = math.floor(Players.LocalPlayer:GetNetworkPing()*1000)
            if ping > 100 then
                if not pingNotification and not _GACC.pingDismissed then createPingNotification() end
            else
                if pingNotification then pcall(function() pingNotification:Destroy() end); pingNotification = nil end
            end
        end)
    end
end)

local function createRagdollBillboard(duration,labelText,color)
    if not ragdollGuiEnabled then return nil end
    local guiName="MoveeRagdollTimer_"..labelText
    pcall(function() local old=game:GetService("CoreGui"):FindFirstChild(guiName); if old then old:Destroy() end end)
    pcall(function() local pgui=LP:FindFirstChild("PlayerGui"); local old=pgui and pgui:FindFirstChild(guiName); if old then old:Destroy() end end)
    local sg=Instance.new("ScreenGui"); sg.Name=guiName; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true; sg.DisplayOrder=40
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(sg) end end)
    if not pcall(function() sg.Parent=game:GetService("CoreGui") end) then sg.Parent=LP:WaitForChild("PlayerGui") end
    local holder=Instance.new("CanvasGroup",sg)
    holder.Name="DiceTimer"; holder.AnchorPoint=Vector2.new(.5,.5); holder.Position=UDim2.new(.5,0,.25,0)
    holder.Size=UDim2.fromOffset(154,122); holder.BackgroundTransparency=1; holder.Rotation=-155; holder.GroupTransparency=1
    local holderScale=Instance.new("UIScale",holder); holderScale.Scale=.55
    local shadow=Instance.new("Frame",holder); shadow.Size=UDim2.fromOffset(88,88); shadow.Position=UDim2.fromOffset(36,13)
    shadow.BackgroundColor3=Color3.fromRGB(0,0,0); shadow.BackgroundTransparency=.42; shadow.BorderSizePixel=0; Instance.new("UICorner",shadow).CornerRadius=UDim.new(0,20)
    local depth=Instance.new("Frame",holder); depth.Size=UDim2.fromOffset(88,88); depth.Position=UDim2.fromOffset(33,10)
    depth.BackgroundColor3=Color3.fromRGB(72,75,84); depth.BorderSizePixel=0; Instance.new("UICorner",depth).CornerRadius=UDim.new(0,20)
    local die=Instance.new("Frame",holder); die.Size=UDim2.fromOffset(88,88); die.Position=UDim2.fromOffset(32,7)
    die.BackgroundColor3=Color3.fromRGB(224,227,233); die.BorderSizePixel=0; die.ZIndex=3; Instance.new("UICorner",die).CornerRadius=UDim.new(0,20)
    local dieStroke=Instance.new("UIStroke",die); dieStroke.Color=Color3.fromRGB(205,210,221); dieStroke.Thickness=2
    local dieGrad=Instance.new("UIGradient",die); dieGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(.3,Color3.fromRGB(183,188,200)),ColorSequenceKeypoint.new(.52,Color3.fromRGB(248,249,252)),ColorSequenceKeypoint.new(1,Color3.fromRGB(103,108,120))}); dieGrad.Rotation=28
    local pipPositions={{.22,.2},{.78,.2},{.22,.5},{.78,.5},{.22,.8},{.78,.8}}
    for _,pt in ipairs(pipPositions) do
        local pip=Instance.new("Frame",die); pip.AnchorPoint=Vector2.new(.5,.5); pip.Position=UDim2.fromScale(pt[1],pt[2]); pip.Size=UDim2.fromOffset(10,10)
        pip.BackgroundColor3=Color3.fromRGB(16,17,24); pip.BorderSizePixel=0; pip.ZIndex=5; Instance.new("UICorner",pip).CornerRadius=UDim.new(1,0)
        local pipStroke=Instance.new("UIStroke",pip); pipStroke.Color=Color3.fromRGB(255,255,255); pipStroke.Transparency=.82; pipStroke.Thickness=1
    end
    local timerPlate=Instance.new("Frame",die); timerPlate.AnchorPoint=Vector2.new(.5,.5); timerPlate.Position=UDim2.fromScale(.5,.5); timerPlate.Size=UDim2.fromOffset(50,35)
    timerPlate.BackgroundColor3=Color3.fromRGB(13,14,19); timerPlate.BackgroundTransparency=.02; timerPlate.BorderSizePixel=0; timerPlate.ZIndex=6; Instance.new("UICorner",timerPlate).CornerRadius=UDim.new(0,10)
    local plateStroke=Instance.new("UIStroke",timerPlate); plateStroke.Color=Color3.fromRGB(185,191,204); plateStroke.Thickness=1; plateStroke.Transparency=.18
    local timerLbl=Instance.new("TextLabel",timerPlate); timerLbl.Size=UDim2.fromScale(1,1); timerLbl.BackgroundTransparency=1
    timerLbl.Text=string.format("%.1f",duration); timerLbl.TextColor3=Color3.fromRGB(247,248,255); timerLbl.Font=Enum.Font.GothamBlack; timerLbl.TextSize=17; timerLbl.ZIndex=7
    local titlePlate=Instance.new("Frame",holder); titlePlate.AnchorPoint=Vector2.new(.5,0); titlePlate.Position=UDim2.new(.5,0,0,98); titlePlate.Size=UDim2.fromOffset(142,20); titlePlate.BackgroundColor3=Color3.fromRGB(12,13,18); titlePlate.BackgroundTransparency=.12; titlePlate.BorderSizePixel=0; titlePlate.ZIndex=3; Instance.new("UICorner",titlePlate).CornerRadius=UDim.new(1,0)
    local titleStroke=Instance.new("UIStroke",titlePlate); titleStroke.Color=Color3.fromRGB(148,154,168); titleStroke.Transparency=.45; titleStroke.Thickness=1
    local titleLbl=Instance.new("TextLabel",titlePlate); titleLbl.Size=UDim2.fromScale(1,1); titleLbl.BackgroundTransparency=1; titleLbl.Text=labelText=="STONE" and "STONE TIMER" or "RAGDOLL TIMER"; titleLbl.TextColor3=Color3.fromRGB(224,228,237); titleLbl.Font=Enum.Font.GothamBlack; titleLbl.TextSize=9; titleLbl.TextStrokeColor3=Color3.fromRGB(5,5,9); titleLbl.TextStrokeTransparency=.45; titleLbl.ZIndex=4
    local titleGrad=Instance.new("UIGradient",titleLbl); titleGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(124,130,144)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(142,148,161))})
    local track=Instance.new("Frame",holder); track.Size=UDim2.fromOffset(76,3); track.Position=UDim2.fromOffset(39,92); track.BackgroundColor3=Color3.fromRGB(25,27,34); track.BorderSizePixel=0; track.ZIndex=8; Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame",track); fill.Size=UDim2.fromScale(1,1); fill.BackgroundColor3=Color3.fromRGB(213,218,228); fill.BorderSizePixel=0; fill.ZIndex=9; Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    TweenService:Create(holder,TweenInfo.new(.42,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Rotation=0,GroupTransparency=0}):Play()
    TweenService:Create(holderScale,TweenInfo.new(.42,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=.72}):Play()
    local startTime=tick();local conn
    conn=RunService.Heartbeat:Connect(function()
        holder.Size=UDim2.fromOffset(154,122)
        local remaining=math.max(0,duration-(tick()-startTime))
        if remaining<=0 then
            conn:Disconnect(); TweenService:Create(holder,TweenInfo.new(.3,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Rotation=145,GroupTransparency=1}):Play(); TweenService:Create(holderScale,TweenInfo.new(.3),{Scale=.62}):Play()
            task.delay(.31,function() pcall(function() sg:Destroy() end) end)
        elseif timerLbl and timerLbl.Parent then
            timerLbl.Text=string.format("%.1f",remaining); fill.Size=UDim2.new(remaining/duration,0,1,0); dieGrad.Offset=Vector2.new(((tick()-startTime)*.7)%2-1,0)
            if remaining<1 then timerLbl.TextColor3=Color3.fromRGB(255,255,255); dieStroke.Color=Color3.fromRGB(235,238,245); plateStroke.Transparency=.02 end
        end
    end)
    return sg
end

local function onHumanoidStateChanged(old,new)
    local char=LP.Character;if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid");if not hum then return end
    local isRag=(new==Enum.HumanoidStateType.Physics or new==Enum.HumanoidStateType.Ragdoll or new==Enum.HumanoidStateType.FallingDown)
    if isRag and not hum.PlatformStand and not activeBatBillboard then
        activeBatBillboard=createRagdollBillboard(2.6,"RAGDOLL",Color3.fromRGB(255,255,255))
        task.delay(2.6,function() if activeBatBillboard then pcall(function() activeBatBillboard:Destroy() end);activeBatBillboard=nil end end)
    end
end

local function onMedusaStateChanged()
    local char=LP.Character;if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum and hum.PlatformStand and not activeMedusaBillboard then
        activeMedusaBillboard=createRagdollBillboard(4.5,"STONE",Color3.fromRGB(255,255,255))
        task.delay(4.5,function() if activeMedusaBillboard then pcall(function() activeMedusaBillboard:Destroy() end);activeMedusaBillboard=nil end end)
    end
end

local function setupRagdollTriggers()
    local char=LP.Character;if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then hum.StateChanged:Connect(onHumanoidStateChanged);hum:GetPropertyChangedSignal("PlatformStand"):Connect(onMedusaStateChanged) end
end

local function setupESPForPlayer(player)
    if player==LP then return end
    if espObjects[player] then return end
    local function doSetup(char)
        if not char then return end
        if not espEnabled then return end
        local head=char:FindFirstChild("Head"); local hrp=char:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then return end
        if espObjects[player] then pcall(function() if espObjects[player].espGui then espObjects[player].espGui:Destroy() end end) end
        local espGui=Instance.new("ScreenGui"); espGui.Name="DiceESP_"..player.Name
        espGui.ResetOnSpawn=false; espGui.IgnoreGuiInset=true
        espGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; espGui.DisplayOrder=50
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(espGui) end end)
        if not pcall(function() espGui.Parent=game:GetService("CoreGui") end) then espGui.Parent=LP:FindFirstChildOfClass("PlayerGui") end
        local tracer=Instance.new("Frame",espGui)
        tracer.AnchorPoint=Vector2.new(.5,.5); tracer.BackgroundColor3=Color3.fromRGB(178,184,215)
        tracer.BackgroundTransparency=.16; tracer.BorderSizePixel=0; tracer.ZIndex=49; tracer.Visible=false
        local tracerStroke=Instance.new("UIStroke",tracer)
        tracerStroke.Color=Color3.fromRGB(20,21,30); tracerStroke.Transparency=.25; tracerStroke.Thickness=1
        local bubble=Instance.new("Frame",espGui)
        bubble.AnchorPoint=Vector2.new(.5,.5); bubble.BackgroundColor3=Color3.fromRGB(112,126,190)
        bubble.BackgroundTransparency=.91; bubble.BorderSizePixel=0; bubble.ZIndex=50; bubble.Visible=false
        Instance.new("UICorner",bubble).CornerRadius=UDim.new(1,0)
        local bubbleStroke=Instance.new("UIStroke",bubble)
        bubbleStroke.Color=Color3.fromRGB(205,211,242); bubbleStroke.Transparency=.05; bubbleStroke.Thickness=2
        local nearLbl=Instance.new("TextLabel",espGui)
        nearLbl.AnchorPoint=Vector2.new(.5,.5); nearLbl.Size=UDim2.new(0,118,0,22)
        nearLbl.BackgroundColor3=Color3.fromRGB(15,16,24); nearLbl.BackgroundTransparency=.08
        nearLbl.BorderSizePixel=0; nearLbl.Text="PLAYER NEAR"; nearLbl.TextColor3=Color3.fromRGB(245,247,255)
        nearLbl.TextSize=10; nearLbl.Font=Enum.Font.GothamBlack; nearLbl.TextStrokeTransparency=.55
        nearLbl.ZIndex=55; nearLbl.Visible=false; Instance.new("UICorner",nearLbl).CornerRadius=UDim.new(0,7)
        local lblFrame=Instance.new("Frame",espGui)
        lblFrame.BackgroundColor3=Color3.fromRGB(10,11,17); lblFrame.BackgroundTransparency=.1; lblFrame.BorderSizePixel=0
        lblFrame.ZIndex=52; lblFrame.AnchorPoint=Vector2.new(0.5,1)
        lblFrame.Size=UDim2.new(0,142,0,40); lblFrame.Visible=false
        Instance.new("UICorner",lblFrame).CornerRadius=UDim.new(0,7)
        local labelStroke=Instance.new("UIStroke",lblFrame)
        labelStroke.Color=Color3.fromRGB(83,87,108); labelStroke.Transparency=.2; labelStroke.Thickness=1
        local spdLbl=Instance.new("TextLabel",lblFrame)
        spdLbl.Size=UDim2.new(1,-18,0,17); spdLbl.Position=UDim2.new(0,13,0,19)
        spdLbl.BackgroundTransparency=1; spdLbl.Text="0.0 SPD  •  0m"
        spdLbl.TextColor3=Color3.fromRGB(166,171,194); spdLbl.Font=Enum.Font.GothamMedium
        spdLbl.TextSize=9; spdLbl.TextXAlignment=Enum.TextXAlignment.Left
        local nameLbl=Instance.new("TextLabel",lblFrame)
        nameLbl.Size=UDim2.new(1,-18,0,17); nameLbl.Position=UDim2.new(0,13,0,3)
        nameLbl.BackgroundTransparency=1; nameLbl.Text=player.DisplayName
        nameLbl.TextColor3=Color3.fromRGB(238,240,250); nameLbl.Font=Enum.Font.GothamBold
        nameLbl.TextSize=11; nameLbl.TextXAlignment=Enum.TextXAlignment.Left
        espObjects[player]={espGui=espGui,spdLbl=spdLbl,lblFrame=lblFrame,nameLbl=nameLbl,tracer=tracer,bubble=bubble,nearLbl=nearLbl}
        task.spawn(function()
            local frame=0
            while espEnabled and espGui and espGui.Parent do
                frame=frame+1
                local tc=player.Character; local mc=LP.Character
                if tc and mc then
                    local tHRP=tc:FindFirstChild("HumanoidRootPart")
                    local tHead=tc:FindFirstChild("Head")
                    local mHRP=mc:FindFirstChild("HumanoidRootPart")
                    local tChest=tc:FindFirstChild("UpperTorso") or tc:FindFirstChild("Torso") or tHRP
                    local mChest=mc:FindFirstChild("UpperTorso") or mc:FindFirstChild("Torso") or mHRP
                    if tHRP and tHead and mHRP and tChest and mChest then
                        local distance=(tHRP.Position-mHRP.Position).Magnitude
                        if frame%4==0 then
                            local vel=tHRP.AssemblyLinearVelocity
                            spdLbl.Text=string.format("%.1f SPD  •  %dm",Vector3.new(vel.X,0,vel.Z).Magnitude,math.floor(distance+.5))
                        end
                        local cam=workspace.CurrentCamera
                        local topSP,topVis=cam:WorldToViewportPoint(tHead.Position+Vector3.new(0,0.7,0))
                        local targetSP,targetVis=cam:WorldToViewportPoint(tChest.Position)
                        local localSP,localVis=cam:WorldToViewportPoint(mChest.Position)
                        if topVis then lblFrame.Position=UDim2.new(0,topSP.X,0,topSP.Y-3); lblFrame.Visible=true
                        else lblFrame.Visible=false end
                        if targetVis and localVis then
                            local dx=targetSP.X-localSP.X; local dy=targetSP.Y-localSP.Y
                            local length=math.sqrt(dx*dx+dy*dy)
                            tracer.Position=UDim2.fromOffset((targetSP.X+localSP.X)/2,(targetSP.Y+localSP.Y)/2)
                            tracer.Size=UDim2.fromOffset(length,distance<=15 and 2.5 or 1.5)
                            tracer.Rotation=math.deg(math.atan2(dy,dx)); tracer.Visible=true
                            tracer.BackgroundColor3=distance<=15 and Color3.fromRGB(245,205,108) or Color3.fromRGB(178,184,215)
                        else tracer.Visible=false end
                        local near=distance<=15 and targetVis
                        bubble.Visible=near; nearLbl.Visible=near
                        if near then
                            local edgeSP=cam:WorldToViewportPoint(tChest.Position+cam.CFrame.RightVector*3.5)
                            local radius=math.clamp(math.abs(edgeSP.X-targetSP.X),30,105)
                            bubble.Size=UDim2.fromOffset(radius*2,radius*2); bubble.Position=UDim2.fromOffset(targetSP.X,targetSP.Y)
                            nearLbl.Position=UDim2.fromOffset(targetSP.X,targetSP.Y+radius+16)
                            nearLbl.Text="PLAYER NEAR  •  "..math.floor(distance+.5).."m"
                        end
                    else lblFrame.Visible=false; tracer.Visible=false; bubble.Visible=false; nearLbl.Visible=false end
                else lblFrame.Visible=false; tracer.Visible=false; bubble.Visible=false; nearLbl.Visible=false end
                task.wait(0.03)
            end
            pcall(function() espGui:Destroy() end)
            if espObjects[player] and espObjects[player].espGui==espGui then espObjects[player]=nil end
        end)
    end
    local c=player.Character
    if c then task.spawn(doSetup,c) end
    local charConn=player.CharacterAdded:Connect(function(newChar)
        task.wait(1.5)
        if espEnabled then
            if espObjects[player] then pcall(function() if espObjects[player].espGui then espObjects[player].espGui:Destroy() end end); espObjects[player]=nil end
            doSetup(newChar)
        end
    end)
    table.insert(espConnections,charConn)
end

local function startESP()
    espEnabled=true
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then task.spawn(setupESPForPlayer,p) end end
    local c1=Players.PlayerAdded:Connect(function(p) task.wait(2); if espEnabled then setupESPForPlayer(p) end end)
    local c2=Players.PlayerRemoving:Connect(function(p)
        local obj=espObjects[p]
        if obj then pcall(function() if obj.espGui then obj.espGui:Destroy() end end); espObjects[p]=nil end
    end)
    table.insert(espConnections,c1); table.insert(espConnections,c2)
end

local function stopESP()
    espEnabled=false
    for _,obj in pairs(espObjects) do pcall(function() if obj.espGui then obj.espGui:Destroy() end end) end
    espObjects={}
    for _,c in ipairs(espConnections) do pcall(function() c:Disconnect() end) end
    espConnections={}
end

local function setupSpeedIndicator(char)
    local head=char:WaitForChild("Head",5);if not head then return end
    if head:FindFirstChild("MoveeSpeedBB") then head.MoveeSpeedBB:Destroy() end
    speedLabel=nil
    local bb=Instance.new("BillboardGui",head);bb.Name="MoveeSpeedBB";bb.Size=UDim2.fromOffset(260,92);bb.StudsOffset=Vector3.new(0,3.35,0);bb.AlwaysOnTop=true;bb.LightInfluence=0;bb.MaxDistance=180
    speedLabel=Instance.new("TextLabel",bb);speedLabel.Size=UDim2.new(1,0,0,37);speedLabel.BackgroundTransparency=1;speedLabel.Text="0.0 SPEED";speedLabel.TextColor3=Color3.fromRGB(238,241,247);speedLabel.Font=Enum.Font.GothamBlack;speedLabel.TextSize=28;speedLabel.TextXAlignment=Enum.TextXAlignment.Center;speedLabel.TextStrokeColor3=Color3.fromRGB(5,5,9);speedLabel.TextStrokeTransparency=.08
end

local function getActiveMoveSpeed()
    if laggerModeEnabled then return carrySpeedActive and LAGGER_CARRY_SPEED or LAGGER_SPEED
    elseif carrySpeedActive then return CS
    else return NS end
end

local function getAutoPathSpeed()
    if laggerModeEnabled then return carrySpeedActive and LAGGER_CARRY_SPEED or LAGGER_SPEED
    else return NS end
end

do
    local _autoSwitchWasSteal=false
    local function updateAutoSwitchSpeed()
        if not autoSwitchSpeedEnabled then return end
        local char=LP.Character;if not char then return end
        local h=char:FindFirstChildOfClass("Humanoid");if not h then return end
        local isStealSpeed=h.WalkSpeed<25
        if isStealSpeed==_autoSwitchWasSteal then return end
        _autoSwitchWasSteal=isStealSpeed
        if isStealSpeed then carrySpeedActive = true else carrySpeedActive = false end
        if refreshSpeedModeLabel then refreshSpeedModeLabel() end
        if mobBtnRefs.carrySpeed then mobBtnRefs.carrySpeed(carrySpeedActive) end
    end
    task.spawn(function() while true do task.wait(0.1);updateAutoSwitchSpeed() end end)
end

local function startHoldInfJump()
    if holdInfJumpConn then holdInfJumpConn:Disconnect() end
    holdInfJumpConn=RunService.Heartbeat:Connect(function()
        if not infJumpEnabled then return end
        local char=LP.Character;if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart");local hum=char:FindFirstChildOfClass("Humanoid");if not root or not hum then return end
        local isJumpHeld=UIS:IsKeyDown(Enum.KeyCode.Space) or (hum.Jump==true)
        if isJumpHeld and root.Velocity.Y<35 then root.Velocity=Vector3.new(root.Velocity.X,55,root.Velocity.Z) end
        if root.Velocity.Y<-120 then root.Velocity=Vector3.new(root.Velocity.X,-120,root.Velocity.Z) end
    end)
end
local function stopHoldInfJump() if holdInfJumpConn then holdInfJumpConn:Disconnect();holdInfJumpConn=nil end end

-- (rimuovi blacklist pastebin per sicurezza nel tuo gioco)
-- pcall(function()
--     if hookfunction and newcclosure then
--         local oldFire
--         oldFire=hookfunction(Instance.new("RemoteEvent").FireServer,newcclosure(function(self,...)
--             if not cursedResetRemote and typeof(self)=="Instance" and self:IsA("RemoteEvent") and self.Name:sub(1,3)=="RE/" then cursedResetRemote=self end
--             return oldFire(self,...)
--         end))
--     end
-- end)

task.spawn(function()
    task.wait(2);if cursedResetRemote then return end
    for _,desc in ipairs(game:GetDescendants()) do
        if desc:IsA("RemoteEvent") and desc.Name:sub(1,3)=="RE/" then cursedResetRemote=desc;break end
    end
end)

cursedInstaReset=function()
    if not cursedResetRemote then
        for _,desc in ipairs(game:GetDescendants()) do if desc:IsA("RemoteEvent") and desc.Name:sub(1,3)=="RE/" then cursedResetRemote=desc;break end end
    end
    if not cursedResetRemote then return end
    local character=LP.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health<=0 then pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID,LP,"balloon") end);return end
    local resetDetected=false;local conns={}
    if humanoid then table.insert(conns,humanoid.Died:Connect(function() resetDetected=true end)) end
    if character then table.insert(conns,character.AncestryChanged:Connect(function(_,parent) if not parent then resetDetected=true end end)) end
    task.spawn(function()
        for _=1,50 do if resetDetected then break end;pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID,LP,"balloon") end);task.wait() end
        for _,conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
    end)
end

local KB={DropBrainrot={kb=nil,gp=nil},AutoLeft={kb=nil,gp=nil},AutoRight={kb=nil,gp=nil},AutoBat={kb=nil,gp=nil},TPFloor={kb=nil,gp=nil},InstaReset={kb=nil,gp=nil},GuiHide={kb=nil,gp=nil},SpeedToggle={kb=nil,gp=nil},LaggerToggle={kb=nil,gp=nil}}
local AP_L1,AP_L2=Vector3.new(-476.47,-6.28,92.73),Vector3.new(-483.12,-4.95,94.81)
local AP_R1,AP_R2=Vector3.new(-476.16,-6.52,25.62),Vector3.new(-483.06,-5.03,25.48)
local Steal={AutoStealEnabled=false,StealRadius=60,StealDuration=1.4,Data={}}
local stealMode="normal"
local SemiSteal={State={active=false,startTime=0,inRange=false,phase="idle",label="",lastResult="",lastResultTime=0,totalSteals=0,failedSteals=0},CONFIG={HOLD_MIN=1.3,HOLD_MAX=2.6,ENTRY_DELAY=0.3,COOLDOWN=.05,STEAL_RANGE=9,PRIME_RANGE=80}}
local startSemiAutoSteal,stopSemiAutoSteal
local isStealing,stealStartTime=false,nil
local Conns={autoSteal=nil,antiRag=nil,batCounter=nil,anchor={}}
local MEDUSA_COOLDOWN=25;local batCounterDebounce=false
local modeValLbl;local lastMoveDir=Vector3.new(0,0,0)
local MOVE_KEYS={[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,[Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true}

local function isRagdollState(hum)
    if not hum then return true end;local st=hum:GetState()
    return hum.PlatformStand or st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
end

do
local function isMyPlotByName(plotName)
    local plots=workspace:FindFirstChild("Plots");if not plots then return false end
    local plot=plots:FindFirstChild(plotName);if not plot then return false end
    local sign=plot:FindFirstChild("PlotSign")
    if sign then local yb=sign:FindFirstChild("YourBase");if yb and yb:IsA("BillboardGui") then return yb.Enabled==true end end
    return false
end
isNearPodiumWithPrompt = function()
    local char=LP.Character;local hrpL=char and char:FindFirstChild("HumanoidRootPart");if not hrpL then return false end
    local plots=workspace:FindFirstChild("Plots");if not plots then return false end
    for _,plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local podiums=plot:FindFirstChild("AnimalPodiums");if not podiums then continue end
        for _,podium in ipairs(podiums:GetChildren()) do
            local base=podium:FindFirstChild("Base");if not base then continue end
            local sp=base:FindFirstChild("Spawn");if not sp then continue end
            local d=(hrpL.Position-sp.Position).Magnitude;if d>Steal.StealRadius then continue end
            local att=sp:FindFirstChild("PromptAttachment");if not att then continue end
            for _,obj in ipairs(att:GetChildren()) do if obj:IsA("ProximityPrompt") and obj.Enabled then return true,d end end
        end
    end
    return false,math.huge
end
local function findNearestPrompt()
    local char=LP.Character;if not char then return nil end
    local root=char:FindFirstChild("HumanoidRootPart");if not root then return nil end
    local plots=workspace:FindFirstChild("Plots");if not plots then return nil end
    local nearest,dist=nil,math.huge
    for _,plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local pods=plot:FindFirstChild("AnimalPodiums");if not pods then continue end
        for _,pod in ipairs(pods:GetChildren()) do
            local base=pod:FindFirstChild("Base");local sp=base and base:FindFirstChild("Spawn")
            if sp then
                local d=(sp.Position-root.Position).Magnitude
                if d<=Steal.StealRadius and dist>d then
                    local att=sp:FindFirstChild("PromptAttachment")
                    if att then for _,prompt in ipairs(att:GetChildren()) do if prompt:IsA("ProximityPrompt") and prompt.ActionText:find("Steal") then nearest,dist=prompt,d end end end
                end
            end
        end
    end
    return nearest
end
local function executeSteal(prompt)
    if isStealing then return end
    if not Steal.Data[prompt] then
        Steal.Data[prompt]={hold={},trigger={},ready=true}
        if getconnections then
            for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(Steal.Data[prompt].hold,c.Function) end end
            for _,c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(Steal.Data[prompt].trigger,c.Function) end end
        end
    end
    local data=Steal.Data[prompt];if not data.ready then return end
    data.ready=false;isStealing=true;stealStartTime=tick()
    task.spawn(function()
        for _,fn in ipairs(data.hold) do task.spawn(fn) end
        task.wait(Steal.StealDuration)
        for _,fn in ipairs(data.trigger) do task.spawn(fn) end
        if _GACC.autoCarryWatch then _GACC.autoCarryWatch(1.25) end
        data.ready=true;isStealing=false;stealStartTime=nil
    end)
end
startAutoSteal=function()
    if stealMode=="op" then if startSemiAutoSteal then startSemiAutoSteal() end; return end
    if Conns.autoSteal then return end
    Conns.autoSteal=RunService.Heartbeat:Connect(function()
        if not Steal.AutoStealEnabled or isStealing then return end
        local p=findNearestPrompt();if p then executeSteal(p) end
    end)
end
stopAutoSteal=function()
    if stopSemiAutoSteal then stopSemiAutoSteal() end
    if Conns.autoSteal then Conns.autoSteal:Disconnect();Conns.autoSteal=nil end
    isStealing=false;stealStartTime=nil
end
end

do
    local opConnection=nil
    local opPromptData={}
    local function opIsMyPlot(plot)
        local sign=plot and plot:FindFirstChild("PlotSign")
        local yourBase=sign and sign:FindFirstChild("YourBase")
        return yourBase and yourBase:IsA("BillboardGui") and yourBase.Enabled==true
    end
    local function opPromptPosition(prompt)
        local attachment=prompt and prompt.Parent
        local spawn=attachment and attachment.Parent
        return spawn and spawn:IsA("BasePart") and spawn.Position or nil
    end
    local function findNearestOPPrompt()
        local character=LP.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local plotsFolder=workspace:FindFirstChild("Plots")
        if not root or not plotsFolder then return nil end
        local nearest,minDistance=nil,math.huge
        for _,plot in ipairs(plotsFolder:GetChildren()) do
            if not opIsMyPlot(plot) then
                local podiums=plot:FindFirstChild("AnimalPodiums")
                if podiums then
                    for _,podium in ipairs(podiums:GetChildren()) do
                        local base=podium:FindFirstChild("Base")
                        local spawn=base and base:FindFirstChild("Spawn")
                        local attachment=spawn and spawn:FindFirstChild("PromptAttachment")
                        if spawn and attachment then
                            local distance=(spawn.Position-root.Position).Magnitude
                            if distance<=SemiSteal.CONFIG.PRIME_RANGE and distance<minDistance then
                                for _,child in ipairs(attachment:GetChildren()) do
                                    if child:IsA("ProximityPrompt") and child.Enabled and child.ActionText:find("Steal") then
                                        nearest,minDistance=child,distance
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return nearest
    end
    local function finishOPSteal(data,fired)
        if fired then
            SemiSteal.State.totalSteals=SemiSteal.State.totalSteals+1
            SemiSteal.State.lastResult="OP steal completed"
            if _GACC.autoCarryWatch then _GACC.autoCarryWatch(1.25) end
        else
            SemiSteal.State.failedSteals=SemiSteal.State.failedSteals+1
            SemiSteal.State.lastResult="OP steal cancelled"
        end
        SemiSteal.State.lastResultTime=tick()
        SemiSteal.State.active=false;SemiSteal.State.inRange=false;SemiSteal.State.phase="idle"
        isStealing=false;stealStartTime=nil
        data.ready=true
    end
    local function executeOPSteal(prompt)
        if isStealing or not prompt or not prompt.Parent then return end
        if not opPromptData[prompt] then
            local data={hold={},trigger={},ready=true}
            if getconnections then
                local okHold,holdConnections=pcall(getconnections,prompt.PromptButtonHoldBegan)
                if okHold then for _,connection in ipairs(holdConnections) do if connection.Function then table.insert(data.hold,connection.Function) end end end
                local okTrigger,triggerConnections=pcall(getconnections,prompt.Triggered)
                if okTrigger then for _,connection in ipairs(triggerConnections) do if connection.Function then table.insert(data.trigger,connection.Function) end end end
            end
            opPromptData[prompt]=data
        end
        local data=opPromptData[prompt]
        if not data.ready then return end
        data.ready=false;isStealing=true;stealStartTime=tick()
        SemiSteal.State.active=true;SemiSteal.State.startTime=stealStartTime;SemiSteal.State.phase="holding";SemiSteal.State.inRange=false
        task.spawn(function()
            for _,callback in ipairs(data.hold) do task.spawn(callback) end
            local duration=math.max(tonumber(Steal.StealDuration) or 1.4,.05)
            while Steal.AutoStealEnabled and stealMode=="op" and prompt.Parent and tick()-stealStartTime<duration do
                local position=opPromptPosition(prompt)
                local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                SemiSteal.State.inRange=position and root and (root.Position-position).Magnitude<=SemiSteal.CONFIG.STEAL_RANGE or false
                task.wait()
            end
            local position=opPromptPosition(prompt)
            local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local canFire=Steal.AutoStealEnabled and stealMode=="op" and position and root and (root.Position-position).Magnitude<=SemiSteal.CONFIG.STEAL_RANGE
            if canFire then for _,callback in ipairs(data.trigger) do task.spawn(callback) end end
            finishOPSteal(data,canFire and true or false)
        end)
    end
    startSemiAutoSteal=function()
        if opConnection then return end
        opConnection=RunService.Heartbeat:Connect(function()
            if not Steal.AutoStealEnabled or stealMode~="op" or isStealing or SemiSteal.State.active then return end
            local prompt=findNearestOPPrompt()
            if prompt then executeOPSteal(prompt) end
        end)
    end
    stopSemiAutoSteal=function()
        if opConnection then opConnection:Disconnect();opConnection=nil end
        SemiSteal.State.active=false;SemiSteal.State.inRange=false;SemiSteal.State.phase="idle"
        isStealing=false;stealStartTime=nil
    end
end

do
    local function showRoundResultMessage(text)
        local guiName="MoveeRoundResult"
        pcall(function() local old=game:GetService("CoreGui"):FindFirstChild(guiName); if old then old:Destroy() end end)
        pcall(function() local pgui=LP:FindFirstChild("PlayerGui"); local old=pgui and pgui:FindFirstChild(guiName); if old then old:Destroy() end end)
        local sg=Instance.new("ScreenGui"); sg.Name=guiName; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true; sg.DisplayOrder=90
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(sg) end end)
        if not pcall(function() sg.Parent=game:GetService("CoreGui") end) then sg.Parent=LP:WaitForChild("PlayerGui") end
        local lbl=Instance.new("TextLabel",sg)
        lbl.AnchorPoint=Vector2.new(0.5,0.5); lbl.Position=UDim2.new(0.5,0,0.38,0); lbl.Size=UDim2.new(0,500,0,70)
        lbl.BackgroundTransparency=1; lbl.Text=text; lbl.Font=Enum.Font.GothamBlack; lbl.TextSize=44
        lbl.TextColor3=Color3.fromRGB(255,255,255); lbl.TextStrokeTransparency=0.15; lbl.TextTransparency=1
        TweenService:Create(lbl,TweenInfo.new(0.25),{TextTransparency=0}):Play()
        task.delay(1.6,function() if lbl and lbl.Parent then TweenService:Create(lbl,TweenInfo.new(0.4),{TextTransparency=1,Position=UDim2.new(0.5,0,0.34,0)}):Play() end end)
        task.delay(2.2,function() pcall(function() sg:Destroy() end) end)
    end
    local lastRoundText,lastRoundTime="",0
    local function handleRoundText(txt)
        if type(txt)~="string" or txt=="" then return end
        local trimmed=txt:gsub("^%s+",""):gsub("%s+$","")
        local name=trimmed:match("^@?([%w_]+)%s+[Ww][Oo][Nn]%s+[Tt][Hh][Ii][Ss]%s+[Rr][Oo][Uu][Nn][Dd]!?$")
        if not name then return end
        local now=tick()
        if trimmed==lastRoundText and (now-lastRoundTime)<3 then return end
        lastRoundText=trimmed; lastRoundTime=now
        if string.lower(name)==string.lower(LP.Name) then showRoundResultMessage("Good job!")
        else showRoundResultMessage("Lock In") end
    end
    local function isOwnGui(inst)
        local cur=inst
        while cur do
            local n=cur.Name
            if type(n)=="string" and n:sub(1,5)=="Movee" then return true end
            cur=cur.Parent
        end
        return false
    end
    local function watchInstance(inst)
        if not (inst:IsA("TextLabel") or inst:IsA("TextButton")) then return end
        if isOwnGui(inst) then return end
        handleRoundText(inst.Text)
        inst:GetPropertyChangedSignal("Text"):Connect(function() handleRoundText(inst.Text) end)
    end
    local function watchGuiRoot(root)
        if not root then return end
        for _,d in ipairs(root:GetDescendants()) do pcall(watchInstance,d) end
        root.DescendantAdded:Connect(function(d) pcall(watchInstance,d) end)
    end
    task.spawn(function()
        watchGuiRoot(LP:WaitForChild("PlayerGui"))
        pcall(function() watchGuiRoot(game:GetService("CoreGui")) end)
    end)
end

RunService.Stepped:Connect(function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            for _,part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide=false end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local char=LP.Character;if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid");local hrp=char:FindFirstChild("HumanoidRootPart");if not hum or not hrp then return end
    if isRagdollState(hum) then lastMoveDir=Vector3.new(0,0,0);return end
    if not autoBatEnabled and not autoLeftEnabled and not autoRightEnabled then
        local md=hum.MoveDirection;local spd=getActiveMoveSpeed()
        if md.Magnitude>0 then lastMoveDir=md;hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
        elseif antiRagdollEnabled and lastMoveDir.Magnitude>0 then
            local anyHeld=false;for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld=true;break end end
            if anyHeld then hrp.Velocity=Vector3.new(lastMoveDir.X*spd,hrp.Velocity.Y,lastMoveDir.Z*spd) end
        end
    end
    if speedLabel then speedLabel.Text=string.format("%.1f SPEED",Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude) end
end)

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5);setupSpeedIndicator(char);setupRagdollTriggers()
    if medusaCounterEnabled then setupMedusa(char) end
    if batCounterEnabled then startBatCounter() end
    if unwalkEnabled then task.wait(0.5);startUnwalk() end
    if refreshSpeedModeLabel then refreshSpeedModeLabel() end
    if mobBtnRefs.carrySpeed then mobBtnRefs.carrySpeed(carrySpeedActive) end
    if mobBtnRefs.lagger then mobBtnRefs.lagger(laggerModeEnabled) end
    _GACC.extras.onCharacter(char)
end)

if LP.Character then setupSpeedIndicator(LP.Character);setupRagdollTriggers() end

do
local alConn,arConn=nil,nil;local alPhase,arPhase=1,1
stopAutoLeft=function()
    if alConn then alConn:Disconnect();alConn=nil end;alPhase=1
    local char=LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
    if autoLeftSetVisual then autoLeftSetVisual(false) end
    if mobBtnRefs.autoLeft then mobBtnRefs.autoLeft(false) end
end
stopAutoRight=function()
    if arConn then arConn:Disconnect();arConn=nil end;arPhase=1
    local char=LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
    if autoRightSetVisual then autoRightSetVisual(false) end
    if mobBtnRefs.autoRight then mobBtnRefs.autoRight(false) end
end
startAutoLeft=function()
    if _GACC.safeBlocked and _GACC.safeBlocked() then autoLeftEnabled=false;if autoLeftSetVisual then autoLeftSetVisual(false) end;if mobBtnRefs.autoLeft then mobBtnRefs.autoLeft(false) end;return end
    if alConn then alConn:Disconnect() end;alPhase=1
    alConn=RunService.Heartbeat:Connect(function()
        if not autoLeftEnabled then return end
        local char=LP.Character;if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart");local hum=char:FindFirstChildOfClass("Humanoid");if not hrp or not hum then return end
        if isRagdollState(hum) then hum:Move(Vector3.zero,false);return end
        local spd=getAutoPathSpeed()
        if alPhase==1 then
            local tgt=Vector3.new(AP_L1.X,hrp.Position.Y,AP_L1.Z)
            if (tgt-hrp.Position).Magnitude<1 then alPhase=2;local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit;hum:Move(mv,false);hrp.Velocity=Vector3.new(mv.X*spd,hrp.Velocity.Y,mv.Z*spd);return end
            local d=AP_L1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit;hum:Move(mv,false);hrp.Velocity=Vector3.new(mv.X*spd,hrp.Velocity.Y,mv.Z*spd)
        elseif alPhase==2 then
            local tgt=Vector3.new(AP_L2.X,hrp.Position.Y,AP_L2.Z)
            if (tgt-hrp.Position).Magnitude<1 then hum:Move(Vector3.zero,false);hrp.Velocity=Vector3.zero;autoLeftEnabled=false;if alConn then alConn:Disconnect();alConn=nil end;alPhase=1;if autoLeftSetVisual then autoLeftSetVisual(false) end;if mobBtnRefs.autoLeft then mobBtnRefs.autoLeft(false) end;return end
            local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit;hum:Move(mv,false);hrp.Velocity=Vector3.new(mv.X*spd,hrp.Velocity.Y,mv.Z*spd)
        end
    end)
end
startAutoRight=function()
    if _GACC.safeBlocked and _GACC.safeBlocked() then autoRightEnabled=false;if autoRightSetVisual then autoRightSetVisual(false) end;if mobBtnRefs.autoRight then mobBtnRefs.autoRight(false) end;return end
    if arConn then arConn:Disconnect() end;arPhase=1
    arConn=RunService.Heartbeat:Connect(function()
        if not autoRightEnabled then return end
        local char=LP.Character;if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart");local hum=char:FindFirstChildOfClass("Humanoid");if not hrp or not hum then return end
        if isRagdollState(hum) then hum:Move(Vector3.zero,false);return end
        local spd=getAutoPathSpeed()
        if arPhase==1 then
            local tgt=Vector3.new(AP_R1.X,hrp.Position.Y,AP_R1.Z)
            if (tgt-hrp.Position).Magnitude<1 then arPhase=2;local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit;hum:Move(mv,false);hrp.Velocity=Vector3.new(mv.X*spd,hrp.Velocity.Y,mv.Z*spd);return end
            local d=AP_R1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit;hum:Move(mv,false);hrp.Velocity=Vector3.new(mv.X*spd,hrp.Velocity.Y,mv.Z*spd)
        elseif arPhase==2 then
            local tgt=Vector3.new(AP_R2.X,hrp.Position.Y,AP_R2.Z)
            if (tgt-hrp.Position).Magnitude<1 then hum:Move(Vector3.zero,false);hrp.Velocity=Vector3.zero;autoRightEnabled=false;if arConn then arConn:Disconnect();arConn=nil end;arPhase=1;if autoRightSetVisual then autoRightSetVisual(false) end;if mobBtnRefs.autoRight then mobBtnRefs.autoRight(false) end;return end
            local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit;hum:Move(mv,false);hrp.Velocity=Vector3.new(mv.X*spd,hrp.Velocity.Y,mv.Z*spd)
        end
    end)
end
end

runDrop=function()
    if dropActive then return end
    if autoBatEnabled then autoBatEnabled=false;if resetAutoBatMotion then resetAutoBatMotion() end;if autoBatSetVisual then autoBatSetVisual(false) end end
    local char = LP.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    dropActive = true
    local t0 = tick()
    local dc
    dc = RunService.Heartbeat:Connect(function()
        local r = char and char:FindFirstChild("HumanoidRootPart")
        if not r then dc:Disconnect();dropActive = false;return end
        if tick() - t0 >= DROP_ASCEND_DURATION then
            dc:Disconnect()
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {char}
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local rr = workspace:Raycast(r.Position, Vector3.new(0, -2000, 0), rp)
            if rr then
                local hum2 = char:FindFirstChildOfClass("Humanoid")
                local off = (hum2 and hum2.HipHeight or 2) + (r.Size.Y / 2)
                r.CFrame = CFrame.new(r.Position.X, rr.Position.Y + off, r.Position.Z)
                r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            dropActive = false
            return
        end
        r.Velocity = Vector3.new(r.Velocity.X, DROP_ASCEND_SPEED, r.Velocity.Z)
    end)
end

do
local function doAutoTPDown(force)
    local char=LP.Character;if not char then return end;local hrp=char:FindFirstChild("HumanoidRootPart");if not hrp then return end
    local hum2=char:FindFirstChildOfClass("Humanoid");if not hum2 then return end
    if not force then if hum2.FloorMaterial~=Enum.Material.Air then return end;if not(hrp.Position.Y>=autoTPHeight) then return end end
    hrp.CFrame=CFrame.new(hrp.Position.X,-7.00,hrp.Position.Z)*CFrame.Angles(0,select(2,hrp.CFrame:ToEulerAnglesYXZ()),0);hrp.Velocity=Vector3.zero
end
startAutoTP=function()
    if autoTPConn then task.cancel(autoTPConn);autoTPConn=nil end
    autoTPConn=task.spawn(function() while autoTPEnabled do task.wait(0.1);pcall(function() doAutoTPDown(false) end) end end)
end
stopAutoTP=function() autoTPEnabled=false;if autoTPConn then task.cancel(autoTPConn);autoTPConn=nil end end
runTPFloor=function() pcall(function() doAutoTPDown(true) end) end
end

do
local STRETCH_NAME="Movee_Stretch"
enableStretchRez=function()
    stretchRezEnabled=true;if stretchRezConn then stretchRezConn:Disconnect() end
    pcall(function() RunService:UnbindFromRenderStep(STRETCH_NAME) end)
    pcall(function() RunService:BindToRenderStep(STRETCH_NAME,Enum.RenderPriority.Last.Value-1,function() local cam=workspace.CurrentCamera;if cam then cam.CFrame=cam.CFrame*CFrame.new(0,0,0,1,0,0,0,0.8,0,0,0,1) end end) end)
end
disableStretchRez=function() stretchRezEnabled=false;pcall(function() RunService:UnbindFromRenderStep(STRETCH_NAME) end) end

local defLightBrightness,defLightClock,defLightAmbient
local function applyAntiLagDerender(obj)
    pcall(function()
        if obj:IsA("Accessory") or obj:IsA("Hat") then obj:Destroy()
        elseif obj:IsA("BasePart") then obj.Material=Enum.Material.Plastic;obj.Reflectance=0;obj.CastShadow=false
        elseif obj:IsA("Decal") or obj:IsA("Texture") then obj.Transparency=1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then obj.Enabled=false end
    end)
end
enableAntiLag=function()
    removeAccessoriesEnabled=true;antiLagEnabled=true
    defLightBrightness=defLightBrightness or Lighting.Brightness;defLightClock=defLightClock or Lighting.ClockTime;defLightAmbient=defLightAmbient or Lighting.OutdoorAmbient
    Lighting.GlobalShadows=false;Lighting.FogEnd=1e10;Lighting.Brightness=1;Lighting.EnvironmentDiffuseScale=0;Lighting.EnvironmentSpecularScale=0
    for _,e in pairs(Lighting:GetChildren()) do pcall(function() if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then e.Enabled=false end end) end
    for _,obj in ipairs(workspace:GetDescendants()) do applyAntiLagDerender(obj) end
    if antiLagDescConn then antiLagDescConn:Disconnect() end
    antiLagDescConn=workspace.DescendantAdded:Connect(function(obj) if removeAccessoriesEnabled then applyAntiLagDerender(obj) end end)
end
disableAntiLag=function()
    removeAccessoriesEnabled=false;antiLagEnabled=false;if antiLagDescConn then antiLagDescConn:Disconnect();antiLagDescConn=nil end
    pcall(function() if defLightBrightness then Lighting.Brightness=defLightBrightness end;if defLightClock then Lighting.ClockTime=defLightClock end;if defLightAmbient then Lighting.OutdoorAmbient=defLightAmbient end;Lighting.ExposureCompensation=0 end)
end
end

do
local function findMedusa()
    local c=LP.Character;if not c then return nil end
    for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower();if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end
    local bp=LP:FindFirstChild("Backpack");if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower();if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end end
    return nil
end
local function useMedusaCounter()
    if medusaDebounce then return end;if MEDUSA_COOLDOWN>(tick()-medusaLastUsed) then return end
    local c=LP.Character;if not c then return end;medusaDebounce=true
    local med=findMedusa();if not med then medusaDebounce=false;return end
    if med.Parent~=c then local hum2=c:FindFirstChildOfClass("Humanoid");if hum2 then hum2:EquipTool(med) end end
    pcall(function() med:Activate() end);medusaLastUsed=tick();medusaDebounce=false
end
local function onAnchorChanged(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function()
        if part.Anchored and part.Transparency==1 then if medusaCounterEnabled then useMedusaCounter() end end
    end)
end
setupMedusa=function(char)
    for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end;Conns.anchor={}
    if not char then return end
    for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end
    table.insert(Conns.anchor,char.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end))
end
stopMedusaCounter=function() for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end;Conns.anchor={} end
end

do
local BAT_COUNTER_SLAP_LIST={"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
local function findBatForCounter()
    local c=LP.Character;if not c then return nil end;local bp=LP:FindFirstChildOfClass("Backpack")
    for _,name in ipairs(BAT_COUNTER_SLAP_LIST) do local t=c:FindFirstChild(name) or (bp and bp:FindFirstChild(name));if t then return t end end
    for _,ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
    if bp then for _,ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
    return nil
end
local function swingBatForCounter(bat,char)
    local hum2=char:FindFirstChildOfClass("Humanoid")
    if bat.Parent~=char then if hum2 then pcall(function() hum2:EquipTool(bat) end) end;task.wait(0.05) end
    local remote=bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
    if remote and remote:IsA("RemoteEvent") then pcall(function() remote:FireServer() end);task.wait(0.15);pcall(function() remote:FireServer() end)
    else pcall(function() bat:Activate() end);task.wait(0.15);pcall(function() bat:Activate() end) end
end
startBatCounter=function()
    if Conns.batCounter then return end
    Conns.batCounter=RunService.Heartbeat:Connect(function()
        if not batCounterEnabled or batCounterDebounce then return end
        local char=LP.Character;if not char then return end;local hum2=char:FindFirstChildOfClass("Humanoid");if not hum2 then return end
        local st=hum2:GetState()
        if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
            batCounterDebounce=true;task.spawn(function() local bat=findBatForCounter();if bat then swingBatForCounter(bat,char) end;task.wait(0.5);batCounterDebounce=false end)
        end
    end)
end
stopBatCounter=function() if Conns.batCounter then Conns.batCounter:Disconnect();Conns.batCounter=nil end;batCounterDebounce=false end
end

;(function()
local CONFIG = {
    FollowSpeed = 55, MaxSpeed = 59, ActivateDistance = 13, MinFollowDistance = 1,
    PredictionTime = 0.22, PredictAhead = 3, JumpSpeedBoost = 1.5, ActivationDelay = 0.2,
    ServerTickrate = 1/60, PingSampleSize = 10, MinPingComp = 0.03, MaxPingComp = 0.25,
    VelocityHistorySize = 8, AccelHistorySize = 4, AerialHistorySize = 6, VerticalHistorySize = 5,
    VelocitySmoothing = 0.2, AerialSmoothing = 0.15, MaxVelocityChange = 150, MaxHorizontalVel = 80,
    AccelerationWeight = 0.3, Gravity = 196.2, AirControlFactor = 0.8, AerialVelocityDecay = 0.95,
    AerialDirectionWeight = 0.6, MinAirborneTime = 0.08,
}
local State = {
    TargetPlayer = nil, LastTargetPos = nil, TargetVelocity = Vector3.zero, SmoothedVelocity = Vector3.zero,
    VelocityHistory = {}, AirborneTime = 0, LastActivationTime = 0, HighYVelocityTime = 0,
    PingHistory = {}, CurrentPing = 0.1, AccelerationHistory = {}, LastDirectionChangeTime = 0,
    PreviousDirection = nil, WasAirborne = false, AerialVelocityHistory = {}, AerialSmoothVelocity = Vector3.zero,
    LastGroundedPosition = nil, LastYVelocity = 0, PeakHeight = 0, GroundHeight = 0,
    LastJumpTime = 0, IsMultiJumping = false, VerticalVelocityHistory = {}, RealPingMs = 0,
}
task.spawn(function()
    while true do
        pcall(function()
            local ok, val = pcall(function() return LP.Ping end)
            if ok and type(val) == "number" and val > 0 then State.RealPingMs = val; return end
            local stats = game:GetService("Stats")
            local ok2, val2 = pcall(function() return stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
            if ok2 and type(val2) == "number" then State.RealPingMs = math.floor(val2) end
        end)
        task.wait(0.5)
    end
end)
local function updatePing()
    local pingSeconds = State.RealPingMs / 1000
    table.insert(State.PingHistory, pingSeconds)
    if #State.PingHistory > CONFIG.PingSampleSize then table.remove(State.PingHistory, 1) end
    local sum = 0
    for _, p in ipairs(State.PingHistory) do sum = sum + p end
    State.CurrentPing = sum / #State.PingHistory
    State.CurrentPing = math.clamp(State.CurrentPing, CONFIG.MinPingComp, CONFIG.MaxPingComp)
end
task.spawn(function() while true do task.wait(0.5);pcall(updatePing) end end)
local function getNearestPlayer()
    local char = LP.Character; if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local myPos = root.Position; local nearestDist = math.huge; local nearestPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local otherRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                local dist = (myPos - otherRoot.Position).Magnitude
                if dist < nearestDist then nearestDist = dist; nearestPlayer = p end
            end
        end
    end
    return nearestPlayer
end
local function updateRotationAngular(lookDirection, rootPart)
    if not rootPart then return end
    if lookDirection.Magnitude < 0.01 then return end
    local currentLook = rootPart.CFrame.LookVector
    local targetDir = lookDirection.Unit
    local axis = currentLook:Cross(targetDir)
    local angle = math.asin(math.clamp(axis.Magnitude, -1, 1))
    if axis.Magnitude > 0.01 then rootPart.AssemblyAngularVelocity = axis.Unit * angle * 80
    else rootPart.AssemblyAngularVelocity = Vector3.zero end
end
local rootPart = nil
local humanoid = nil
local function aimbotUpdate(dt)
    if not autoBatEnabled then stopBatAimbot(); return end
    local target = getNearestPlayer()
    if not target or not target.Character then return end
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    if not rootPart then return end
    local myPos = rootPart.Position
    local targetPos = targetRoot.Position
    local targetVel = targetRoot.AssemblyLinearVelocity
    local predicted = targetPos + targetVel * 0.15
    local toTarget = predicted - myPos
    if toTarget.Magnitude > 0.1 then updateRotationAngular(toTarget, rootPart) end
    local dist = (targetPos - myPos).Magnitude
    if autoSwingEnabled and dist <= 13 then
        local now = tick()
        if now - State.LastActivationTime >= 0.3 then
            local tool = LP.Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
            State.LastActivationTime = now
        end
    end
    if toTarget.Magnitude > 1 then
        local dir = toTarget.Unit
        local speed = 55
        rootPart.AssemblyLinearVelocity = dir * speed
    end
end
local aimbotConn = nil
function startBatAimbot()
    if _GACC.safeBlocked and _GACC.safeBlocked() then autoBatEnabled=false;if autoBatSetVisual then autoBatSetVisual(false) end;if mobBtnRefs.autoBat then mobBtnRefs.autoBat(false) end;return end
    if aimbotConn then return end
    autoBatEnabled = true
    local char = LP.Character
    if not char then return end
    humanoid = char:FindFirstChildOfClass("Humanoid")
    rootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    humanoid.AutoRotate = false
    aimbotConn = RunService.RenderStepped:Connect(aimbotUpdate)
end
function stopBatAimbot()
    if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
    autoBatEnabled = false
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end
    end
end
local batDesyncTpConn = nil
local hittingCooldownDesync = false
local function getBatDesync()
    local char=LP.Character; if not char then return nil end
    local tool=char:FindFirstChild("Bat"); if tool then return tool end
    local bp2=LP:FindFirstChild("Backpack")
    if bp2 then tool=bp2:FindFirstChild("Bat"); if tool then tool.Parent=char; return tool end end
    return nil
end
local function tryHitBatDesync()
    if hittingCooldownDesync then return end; hittingCooldownDesync=true
    pcall(function()
        local bat=getBatDesync(); if bat then
            bat:Activate(); local ev=bat:FindFirstChildWhichIsA("RemoteEvent")
            if ev then ev:FireServer() end
        end
    end)
    task.delay(0.08, function() hittingCooldownDesync=false end)
end
local function getClosestPlayerDesync()
    local char = LP.Character
    if not char then return nil,math.huge end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil,math.huge end
    local cp,cd=nil,math.huge
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local tr=p.Character:FindFirstChild("HumanoidRootPart")
            if tr then local d=(hrp.Position-tr.Position).Magnitude; if d<cd then cd=d; cp=p end end
        end
    end
    return cp,cd
end
local function batDesyncTpUpdate()
    if not batDesyncTpEnabled then stopBatDesyncTp(); return end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local target,dist=getClosestPlayerDesync()
    if target and target.Character then
        local tr=target.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            if sethiddenproperty then sethiddenproperty(hrp, "PhysicsRepRootPart", tr) end
            local targetPos = tr.Position + Vector3.new(0, 0.9, 0)
            if (hrp.Position - targetPos).Magnitude > 8 then hrp.CFrame = CFrame.new(targetPos) end
            local cam = workspace.CurrentCamera
            if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, tr.Position) end
            tryHitBatDesync()
        end
    end
end
function startBatDesyncTp()
    if _GACC.safeBlocked and _GACC.safeBlocked() then batDesyncTpEnabled=false;if batDesyncTpSetVisual then batDesyncTpSetVisual(false) end;return end
    if batDesyncTpConn then return end
    batDesyncTpEnabled = true
    batDesyncTpConn = RunService.Heartbeat:Connect(batDesyncTpUpdate)
end
function stopBatDesyncTp()
    if batDesyncTpConn then batDesyncTpConn:Disconnect(); batDesyncTpConn = nil end
    batDesyncTpEnabled = false
end
function queueAutoBatStart() startBatAimbot() end
function resetAutoBatMotion()
    local char = LP.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if root then root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * 0.3; root.AssemblyAngularVelocity = Vector3.zero end
        if hum then hum.AutoRotate = true end
    end
end
LP.CharacterAdded:Connect(function(char) if autoBatEnabled then task.wait(0.5); startBatAimbot() end end)
end)()

_GACC.safeBlockedTools={bat=true,slap=true,sword=true,gun=true,pistol=true,rifle=true,medusa=true,hammer=true,axe=true,knife=true,katana=true,blade=true,fist=true,coil=true,boombox=true}
_GACC.inDuelCountdown=function()
    local ok,label=pcall(function() return LP.PlayerGui:FindFirstChild("DuelsMachineTopFrame").DuelsMachineTopFrame.Timer.Label end)
    if not ok or not label then return false end
    local text=tostring(label.Text or ""):upper():gsub("^%s+",""):gsub("%s+$","")
    if text=="GO" or text=="START" or text=="READY" then return true end
    local number=tonumber(text)
    return number~=nil and number>=0 and number<=10
end
_GACC.hasHeldBrainrot=function()
    if LP:GetAttribute("Stealing")==true or LP:GetAttribute("AntiKick")==true then return true end
    local char=LP.Character;if not char then return false end
    if char:GetAttribute("Stealing")==true then return true end
    for _,name in ipairs({"Carrying","IsCarrying","Grabbed","Holding","StealHold","HasGrab"}) do
        local value=char:FindFirstChild(name,true)
        if value and ((value:IsA("BoolValue") and value.Value) or (value:IsA("ObjectValue") and value.Value) or (value:IsA("StringValue") and value.Value~="")) then return true end
    end
    for _,obj in ipairs(char:GetChildren()) do
        local name=obj.Name:lower()
        if obj:IsA("Tool") then
            local blocked=false
            for word in pairs(_GACC.safeBlockedTools) do if name:find(word,1,true) then blocked=true;break end end
            if not blocked then return true end
        elseif obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart",true) then
            if name:find("brainrot") or name:find("animal") or name:find("carry") or name:find("grab") or name:find("steal") or name:find("hold") then return true end
        end
    end
    return false
end
_GACC.safeBlocked=function()
    if not _GACC.safeModeEnabled then _GACC.safeModeActive=false;return false end
    brainrotDetected=_GACC.hasHeldBrainrot() or _GACC.inDuelCountdown()
    _GACC.safeModeActive=brainrotDetected
    return brainrotDetected
end
_GACC.enforceSafeMode=function()
    if not _GACC.safeBlocked() then return end
    if autoBatEnabled then stopBatAimbot();if autoBatSetVisual then autoBatSetVisual(false) end;if mobBtnRefs.autoBat then mobBtnRefs.autoBat(false) end end
    if autoLeftEnabled then autoLeftEnabled=false;stopAutoLeft();if autoLeftSetVisual then autoLeftSetVisual(false) end;if mobBtnRefs.autoLeft then mobBtnRefs.autoLeft(false) end end
    if autoRightEnabled then autoRightEnabled=false;stopAutoRight();if autoRightSetVisual then autoRightSetVisual(false) end;if mobBtnRefs.autoRight then mobBtnRefs.autoRight(false) end end
    if batDesyncTpEnabled then stopBatDesyncTp();if batDesyncTpSetVisual then batDesyncTpSetVisual(false) end;if mobBtnRefs.batDesyncTp then mobBtnRefs.batDesyncTp(false) end end
end
task.spawn(function()
    while task.wait(.1) do
        brainrotDetected=_GACC.hasHeldBrainrot() or _GACC.inDuelCountdown()
        _GACC.safeModeActive=_GACC.safeModeEnabled and brainrotDetected
        if _GACC.safeModeActive then _GACC.enforceSafeMode() end
    end
end)
;(function()
    local state={applied=false,waiting=false,watchUntil=0,graceUntil=0,savedMode=nil,stealWasActive=false}
    local function modeName() if laggerModeEnabled then return carrySpeedActive and "Lagger Carry" or "Lagger" end;return carrySpeedActive and "Carry" or "Normal" end
    local function setModes(lagger,carry)
        laggerModeEnabled=lagger;carrySpeedActive=carry
        if refreshSpeedModeLabel then refreshSpeedModeLabel() end
        if _GACC.safeLaggerVisual then _GACC.safeLaggerVisual(lagger) end
        if _GACC.safeCarryVisual then _GACC.safeCarryVisual(carry) end
        if mobBtnRefs.lagger then mobBtnRefs.lagger(lagger) end
        if mobBtnRefs.carrySpeed then mobBtnRefs.carrySpeed(carry) end
    end
    local function isIgnoredTool(name)
        local lower=tostring(name or ""):lower()
        return lower:find("bat",1,true) or lower:find("slap",1,true) or lower:find("medusa",1,true) or lower:find("head",1,true) or lower:find("stone",1,true)
    end
    _GACC.autoCarryDetect=function()
        local char=LP.Character;if not char then return false end
        for _,name in ipairs({"Carrying","IsCarrying","Grabbed","Holding","StealHold","HasGrab"}) do
            local value=char:FindFirstChild(name,true)
            if value and ((value:IsA("BoolValue") and value.Value) or (value:IsA("ObjectValue") and value.Value) or (value:IsA("StringValue") and value.Value~="")) then return true end
        end
        for _,child in ipairs(char:GetChildren()) do
            local lower=child.Name:lower()
            if child:IsA("Model") and child:FindFirstChildWhichIsA("BasePart",true) then
                if (child:FindFirstChildOfClass("Humanoid") and child:FindFirstChild("HumanoidRootPart")) or lower:find("brainrot") or lower:find("animal") or lower:find("carry") or lower:find("grab") or lower:find("steal") or lower:find("hold") then return true end
            elseif child:IsA("Tool") and not isIgnoredTool(child.Name) then return true end
        end
        return false
    end
    local function enableCarry()
        state.waiting=false;state.watchUntil=0
        if not state.applied then state.savedMode=modeName() end
        state.applied=true;state.graceUntil=tick()+.75
        local wasLagger=state.savedMode=="Lagger" or state.savedMode=="Lagger Carry" or laggerModeEnabled
        if wasLagger then setModes(true,true) else setModes(false,true) end
    end
    local function disableCarry()
        if not state.applied and not state.waiting then return end
        local wasApplied=state.applied;local saved=state.savedMode
        state.applied=false;state.waiting=false;state.watchUntil=0;state.graceUntil=0;state.savedMode=nil
        if not wasApplied then return end
        if saved=="Lagger" or saved=="Lagger Carry" then setModes(true,false)
        elseif saved=="Carry" then setModes(false,true)
        else setModes(false,false) end
    end
    _GACC.autoCarryWatch=function(seconds)
        if not _GACC.autoCarrySpeedEnabled then return end
        state.waiting=true;state.watchUntil=tick()+(seconds or 1.25)
    end
    _GACC.disableAutoCarry=disableCarry
    RunService.RenderStepped:Connect(function()
        if not _GACC.autoCarrySpeedEnabled then disableCarry();return end
        local char=LP.Character;local hum=char and char:FindFirstChildOfClass("Humanoid");local root=char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hum or not root then disableCarry();state.stealWasActive=false;return end
        local humanoidState=hum:GetState()
        local gotHit=humanoidState==Enum.HumanoidStateType.Physics or humanoidState==Enum.HumanoidStateType.Ragdoll or humanoidState==Enum.HumanoidStateType.FallingDown
        local stealing=LP:GetAttribute("Stealing")==true or char:GetAttribute("Stealing")==true
        local carrying=_GACC.autoCarryDetect()
        if stealing and not state.stealWasActive then state.stealWasActive=true;enableCarry()
        elseif not stealing then state.stealWasActive=false end
        if state.waiting then
            if gotHit or tick()>state.watchUntil then state.waiting=false;state.watchUntil=0
            elseif carrying then enableCarry() end
        end
        if carrying and not state.applied then enableCarry() end
        if state.applied and (gotHit or (tick()>state.graceUntil and not carrying and not stealing)) then disableCarry() end
    end)
end)()

saveConfig=function()
    local function ks(e)
        if e.kb then return {kb=e.kb.Name,gp=e.gp and e.gp.Name}
        elseif e.gp then return {gp=e.gp.Name}
        else return {kb=nil,gp=nil} end
    end
    local cfg={normalSpeed=NS,carrySpeed=CS,dropBrainrotKey=ks(KB.DropBrainrot),autoLeftKey=ks(KB.AutoLeft),autoRightKey=ks(KB.AutoRight),autoBatKey=ks(KB.AutoBat),laggerToggleKey=ks(KB.LaggerToggle),tpFloorKey=ks(KB.TPFloor),instaResetKey=ks(KB.InstaReset),guiHideKey=ks(KB.GuiHide),speedToggleKey=ks(KB.SpeedToggle),grabRadius=Steal.StealRadius,stealDuration=Steal.StealDuration,stealMode=stealMode,antiRagdoll=antiRagdollEnabled,autoStealEnabled=Steal.AutoStealEnabled,infiniteJump=infJumpEnabled,infJumpMode=infJumpMode,medusaCounter=medusaCounterEnabled,batCounter=batCounterEnabled,carrySpeedActive=carrySpeedActive,laggerModeEnabled=laggerModeEnabled,laggerSpeed=LAGGER_SPEED,laggerCarrySpeed=LAGGER_CARRY_SPEED,autoBat=autoBatEnabled,autoSwing=autoSwingEnabled,unwalkEnabled=unwalkEnabled,antiLag=antiLagEnabled,stretchRez=stretchRezEnabled,autoTPEnabled=autoTPEnabled,autoTPHeight=autoTPHeight,guiTransparencyEnabled=guiTransparencyEnabled,mobileButtonsEnabled=mobileButtonsEnabled,mobileButtonsLocked=mobileButtonsLocked,mobileButtonsGrouped=_GACC.mobileButtonsGrouped,mobileButtonsSize=mobileButtonsSize,circleButtonsEnabled=circleButtonsEnabled,autoSwitchSpeed=autoSwitchSpeedEnabled,fovValue=fovValue,perButtonDrag=perButtonDragEnabled,skyTheme=currentSkyTheme,medusaReset=medusaResetEnabled,autoMoveSwing=autoMoveSwingEnabled,autoMoveSwingInterval=autoMoveSwingInterval,ragdollGui=ragdollGuiEnabled,introSoundEnabled=introSoundEnabled,animEnabled=false,animationPack=_GACC.extras.getPack(),headlessEnabled=_GACC.extras.getHeadless(),korbloxEnabled=_GACC.extras.getKorblox(),bodyLockEnabled=_GACC.extras.getBodyLock(),bodyLockRadius=_GACC.extras.getBodyLockRadius(),autoResetOnDeath=_GACC.extras.getAutoReset(),backgroundEnabled=backgroundEnabled,backgroundIndex=backgroundIndex,colorThemeName=currentColorTheme,keys=(function() if not _GuiKeys then return {} end;local t={};for k,v in pairs(_GuiKeys) do t[k]=v.Name end;return t end)()}
    cfg.safeModeEnabled=_GACC.safeModeEnabled
    cfg.autoCarrySpeedEnabled=_GACC.autoCarrySpeedEnabled
    cfg.controllerKeys=(function() local t={};for k,v in pairs(_GACC.ControllerKeys or {}) do if v then t[k]=v.Name end end;return t end)()
    cfg.opStealRange=SemiSteal.CONFIG.STEAL_RANGE
    cfg.opPrimeRange=SemiSteal.CONFIG.PRIME_RANGE
    cfg.mobileButtonPositions=_GACC.mobileButtonPositions
    cfg.mobileGroupPosition=_GACC.mobileGroupPosition
    -- salva anche diceConfig del pannello
    cfg.diceConfig = _GACC.diceConfig
    if writefile then pcall(function() writefile("Dice_Mobile.json",HS:JSONEncode(cfg)) end) end
end
task.spawn(function() while task.wait(5) do saveConfig() end end)

local function resetAllSettings()
    NS=59;CS=29;LAGGER_SPEED=30;LAGGER_CARRY_SPEED=15;carrySpeedActive=false;laggerModeEnabled=false
    autoSwitchSpeedEnabled=false;antiRagdollEnabled=false;infJumpEnabled=false;infJumpMode="manual"
    medusaCounterEnabled=false;batCounterEnabled=false;unwalkEnabled=false
    autoLeftEnabled=false;autoRightEnabled=false;autoBatEnabled=false;autoSwingEnabled=true;autoMoveSwingEnabled=false
    autoTPEnabled=false;autoTPHeight=20;antiLagEnabled=false;stretchRezEnabled=false
    Steal.AutoStealEnabled=false;Steal.StealRadius=60;Steal.StealDuration=1.4;SemiSteal.CONFIG.STEAL_RANGE=9;SemiSteal.CONFIG.PRIME_RANGE=80;stealMode="normal"
    guiTransparencyEnabled=false;mobileButtonsEnabled=true;mobileButtonsLocked=true;_GACC.mobileButtonsGrouped=false;mobileButtonsSize=64
    _GACC.mobileButtonPositions={}
    _GACC.mobileGroupPosition={x=.86,y=.5}
    circleButtonsEnabled=false;uiLocked=false;fovValue=80;fovIndex=1
    introSoundEnabled=true
    _GACC.safeModeEnabled=false;_GACC.safeModeActive=false;_GACC.autoCarrySpeedEnabled=false;if _GACC.disableAutoCarry then _GACC.disableAutoCarry() end
    _GACC.extras.reset(LP.Character)
    KB.DropBrainrot={kb=nil,gp=nil};KB.AutoLeft={kb=nil,gp=nil};KB.AutoRight={kb=nil,gp=nil}
    KB.AutoBat={kb=nil,gp=nil};KB.TPFloor={kb=nil,gp=nil};KB.InstaReset={kb=nil,gp=nil}
    KB.GuiHide={kb=nil,gp=nil};KB.SpeedToggle={kb=nil,gp=nil};KB.LaggerToggle={kb=nil,gp=nil}
    if refreshSpeedModeLabel then refreshSpeedModeLabel() end
    if mobBtnRefs.carrySpeed then mobBtnRefs.carrySpeed(carrySpeedActive) end
    if mobBtnRefs.lagger then mobBtnRefs.lagger(laggerModeEnabled) end
    if mobBtnRefs.autoLeft then mobBtnRefs.autoLeft(false) end
    if mobBtnRefs.autoRight then mobBtnRefs.autoRight(false) end
    if mobBtnRefs.autoBat then mobBtnRefs.autoBat(false) end
    if _GACC.safeModeVisual then _GACC.safeModeVisual(false) end
    if _GACC.autoCarryVisual then _GACC.autoCarryVisual(false) end
    stopBatAimbot();stopAutoSteal();stopAutoLeft();stopAutoRight();stopAntiRagdoll();stopAutoTP();stopHoldInfJump()
    if stretchRezEnabled then disableStretchRez() end;if antiLagEnabled then disableAntiLag() end;saveConfig()
end

local setInfJumpVisual,setAntiRagVisual,setMedusaVisual,setUnwalkVisual
refreshSpeedModeLabel=function()
    if modeValLbl then
        if laggerModeEnabled then modeValLbl.Text = carrySpeedActive and "Lagger Carry" or "Lagger Mode"
        elseif carrySpeedActive then modeValLbl.Text="Carry"
        else modeValLbl.Text="Normal" end
    end
end
toggleCarryMode=function()
    carrySpeedActive = not carrySpeedActive
    refreshSpeedModeLabel()
    if mobBtnRefs.carrySpeed then mobBtnRefs.carrySpeed(carrySpeedActive) end
    if _GACC.safeCarryVisual then _GACC.safeCarryVisual(carrySpeedActive) end
end
toggleLaggerMode=function()
    laggerModeEnabled = not laggerModeEnabled
    refreshSpeedModeLabel()
    if mobBtnRefs.lagger then mobBtnRefs.lagger(laggerModeEnabled) end
    if _GACC.safeLaggerVisual then _GACC.safeLaggerVisual(laggerModeEnabled) end
end

;(function()
    local resetCooldown=0
    local function forceReset()
        local char=LP.Character
        if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        local root=char:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health<=0 then return end
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            root.Velocity=Vector3.zero;root.RotVelocity=Vector3.zero
            root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
            for _,obj in ipairs(char:GetDescendants()) do
                if obj:IsA("Motor6D") then obj.Enabled=true end
                if obj:IsA("Constraint") then obj.Enabled=true end
            end
            if workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject=hum end
            hum.AutoRotate=true;hum.PlatformStand=false;hum.Sit=false
        end)
    end
    startAntiRagdoll=function()
        if Conns.antiRag then return end
        antiRagdollEnabled=true
        Conns.antiRag=RunService.Heartbeat:Connect(function()
            if not antiRagdollEnabled then return end
            local char=LP.Character;if not char then return end
            local hum=char:FindFirstChildOfClass("Humanoid");if not hum or hum.Health<=0 then return end
            local state=hum:GetState()
            local ragdolled=(state==Enum.HumanoidStateType.Physics or state==Enum.HumanoidStateType.Ragdoll or state==Enum.HumanoidStateType.FallingDown)
            if ragdolled then
                local now=tick()
                if now-resetCooldown>.15 then resetCooldown=now;forceReset() end
            end
        end)
    end
    stopAntiRagdoll=function()
        antiRagdollEnabled=false
        if Conns.antiRag then Conns.antiRag:Disconnect();Conns.antiRag=nil end
    end
end)()

startUnwalk=function()
    local c=LP.Character;if not c then return end;local hum=c:FindFirstChildOfClass("Humanoid")
    if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    local anim=c:FindFirstChild("Animate");if anim then unwalkSavedAnimate=anim:Clone();anim:Destroy() end
end
stopUnwalk=function() local c=LP.Character;if c and unwalkSavedAnimate then unwalkSavedAnimate:Clone().Parent=c;unwalkSavedAnimate=nil end end

-- ═══════════════════════════════════════════════════════════════
-- PANNELLO RIGGED /panel (colore + numero dadi 1-4)
-- ═══════════════════════════════════════════════════════════════
local function saveDiceConfig()
    if not writefile then return end
    pcall(function()
        local data = {}
        if isfile and isfile(_PANEL_SAVE) then
            local ok, d = pcall(function() return HS:JSONDecode(readfile(_PANEL_SAVE)) end)
            if ok and type(d) == "table" then data = d end
        end
        data.diceConfig = _GACC.diceConfig
        writefile(_PANEL_SAVE, HS:JSONEncode(data))
    end)
end

local panelGui
local function buildPanel()
    if panelGui and panelGui.Parent then panelGui:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "DiceRiggedPanel"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 850
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(sg) end end)
    if not pcall(function() sg.Parent = game:GetService("CoreGui") end) then
        sg.Parent = LP:WaitForChild("PlayerGui")
    end

    local frame = Instance.new("Frame", sg)
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.Position = UDim2.new(1, -18, 0, 18)
    frame.Size = UDim2.fromOffset(244, 102)
    frame.BackgroundColor3 = Color3.fromRGB(12, 13, 18)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local st = Instance.new("UIStroke", frame)
    st.Color = _GACC.DICE_PALETTE[_GACC.diceConfig.accentColor]; st.Thickness = 1.4; st.Transparency = 0.15

    local title = Instance.new("TextLabel", frame)
    title.Position = UDim2.fromOffset(10, 6)
    title.Size = UDim2.new(1, -50, 0, 16)
    title.BackgroundTransparency = 1
    title.Text = "DICE RIGGED PANEL"
    title.TextColor3 = Color3.fromRGB(225, 228, 240)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left

    local close = Instance.new("TextButton", frame)
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -6, 0, 4)
    close.Size = UDim2.fromOffset(20, 20)
    close.BackgroundColor3 = Color3.fromRGB(30, 20, 24)
    close.BorderSizePixel = 0
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(200, 130, 130)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 10
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)
    close.MouseButton1Click:Connect(function() sg.Enabled = false end)

    local colorBtn = Instance.new("TextButton", frame)
    colorBtn.Position = UDim2.fromOffset(10, 28)
    colorBtn.Size = UDim2.fromOffset(124, 28)
    colorBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    colorBtn.BorderSizePixel = 0
    colorBtn.Font = Enum.Font.GothamBold
    colorBtn.TextSize = 10
    colorBtn.TextXAlignment = Enum.TextXAlignment.Left
    colorBtn.ZIndex = 2
    local cPad = Instance.new("UIPadding", colorBtn); cPad.PaddingLeft = UDim.new(0, 8)
    Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 6)
    local cStroke = Instance.new("UIStroke", colorBtn)
    cStroke.Color = Color3.fromRGB(60, 62, 78); cStroke.Thickness = 1

    local swatch = Instance.new("Frame", colorBtn)
    swatch.AnchorPoint = Vector2.new(1, 0.5)
    swatch.Position = UDim2.new(1, -6, 0.5, 0)
    swatch.Size = UDim2.fromOffset(14, 14)
    swatch.BorderSizePixel = 0
    Instance.new("UICorner", swatch).CornerRadius = UDim.new(1, 0)
    local swatchStroke = Instance.new("UIStroke", swatch)
    swatchStroke.Color = Color3.fromRGB(255, 255, 255); swatchStroke.Thickness = 1

    local numButtons = {}
    local previewDots = {}

    local function refreshAccentVisuals()
        local c = _GACC.DICE_PALETTE[_GACC.diceConfig.accentColor] or Color3.fromRGB(220,220,220)
        colorBtn.Text = "  " .. _GACC.diceConfig.accentColor
        colorBtn.TextColor3 = c
        swatch.BackgroundColor3 = c
        st.Color = c
        cStroke.Color = c
        for i, ref in ipairs(numButtons) do
            local active = (i == _GACC.diceConfig.count)
            ref.btn.BackgroundColor3 = active and c or Color3.fromRGB(22, 22, 30)
            ref.btn.TextColor3 = active and Color3.fromRGB(15, 16, 22) or Color3.fromRGB(160, 164, 180)
            ref.stroke.Color = active and Color3.fromRGB(245, 246, 250) or Color3.fromRGB(55, 57, 72)
        end
        for i, d in ipairs(previewDots) do
            if i <= _GACC.diceConfig.count then d.BackgroundColor3 = c; d.BackgroundTransparency = 0
            else d.BackgroundTransparency = 1 end
        end
    end
    refreshAccentVisuals()

    local drop = Instance.new("ScrollingFrame", frame)
    drop.Position = UDim2.fromOffset(10, 60)
    drop.Size = UDim2.new(0, 124, 0, 0)
    drop.BackgroundColor3 = Color3.fromRGB(8, 8, 13)
    drop.BorderSizePixel = 0
    drop.ScrollBarThickness = 2
    drop.CanvasSize = UDim2.new(0, 0, 0, 0)
    drop.Visible = false
    drop.ZIndex = 5
    Instance.new("UICorner", drop).CornerRadius = UDim.new(0, 6)
    local dSt = Instance.new("UIStroke", drop)
    dSt.Color = Color3.fromRGB(55, 57, 72); dSt.Thickness = 1
    local dLay = Instance.new("UIListLayout", drop)
    dLay.SortOrder = Enum.SortOrder.LayoutOrder
    dLay.Padding = UDim.new(0, 2)
    local dPad = Instance.new("UIPadding", drop)
    dPad.PaddingTop = UDim.new(0, 3); dPad.PaddingLeft = UDim.new(0, 3); dPad.PaddingRight = UDim.new(0, 3)

    local colorNames = {}
    for name in pairs(_GACC.DICE_PALETTE) do table.insert(colorNames, name) end
    table.sort(colorNames)
    local built = false
    local function buildColorList()
        if built then return end
        built = true
        for i, name in ipairs(colorNames) do
            local choice = Instance.new("TextButton", drop)
            choice.Size = UDim2.new(1, -4, 0, 22)
            choice.LayoutOrder = i
            choice.BackgroundColor3 = Color3.fromRGB(17, 18, 25)
            choice.BackgroundTransparency = 0.12
            choice.BorderSizePixel = 0
            choice.Text = "  " .. name
            choice.TextColor3 = _GACC.DICE_PALETTE[name]
            choice.Font = Enum.Font.GothamBold
            choice.TextSize = 9
            choice.TextXAlignment = Enum.TextXAlignment.Left
            local cp = Instance.new("UIPadding", choice); cp.PaddingLeft = UDim.new(0, 6)
            Instance.new("UICorner", choice).CornerRadius = UDim.new(0, 5)
            choice.MouseEnter:Connect(function()
                choice.BackgroundColor3 = _GACC.DICE_PALETTE[name]
                choice.TextColor3 = Color3.fromRGB(15,15,22)
            end)
            choice.MouseLeave:Connect(function()
                choice.BackgroundColor3 = Color3.fromRGB(17, 18, 25)
                choice.TextColor3 = _GACC.DICE_PALETTE[name]
            end)
            choice.MouseButton1Click:Connect(function()
                _GACC.diceConfig.accentColor = name
                refreshAccentVisuals()
                drop.Visible = false
                frame.Size = UDim2.fromOffset(244, 102)
                saveDiceConfig()
                saveConfig()
                _GACC.applyDiceColors(_GACC.lastRolledDice)
            end)
        end
        drop.CanvasSize = UDim2.new(0, 0, 0, #colorNames * 24 + 6)
    end
    local colorOpen = false
    colorBtn.MouseButton1Click:Connect(function()
        colorOpen = not colorOpen
        if colorOpen then
            buildColorList()
            drop.Visible = true
            frame.Size = UDim2.fromOffset(244, 254)
            drop.Size = UDim2.fromOffset(124, 148)
        else
            drop.Visible = false
            frame.Size = UDim2.fromOffset(244, 102)
            drop.Size = UDim2.fromOffset(124, 0)
        end
    end)

    local numLbl = Instance.new("TextLabel", frame)
    numLbl.Position = UDim2.fromOffset(10, 66)
    numLbl.Size = UDim2.fromOffset(56, 28)
    numLbl.BackgroundTransparency = 1
    numLbl.Text = "DADI:"
    numLbl.TextColor3 = Color3.fromRGB(180, 184, 200)
    numLbl.Font = Enum.Font.GothamBold
    numLbl.TextSize = 10
    numLbl.TextXAlignment = Enum.TextXAlignment.Left

    for i = 1, 4 do
        local b = Instance.new("TextButton", frame)
        b.Position = UDim2.fromOffset(64 + (i - 1) * 30, 66)
        b.Size = UDim2.fromOffset(26, 28)
        b.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        b.BorderSizePixel = 0
        b.Text = tostring(i)
        b.TextColor3 = Color3.fromRGB(160, 164, 180)
        b.Font = Enum.Font.GothamBlack
        b.TextSize = 11
        b.ZIndex = 2
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local bSt = Instance.new("UIStroke", b)
        bSt.Color = Color3.fromRGB(55, 57, 72); bSt.Thickness = 1
        numButtons[i] = { btn = b, stroke = bSt }
        b.MouseButton1Click:Connect(function()
            _GACC.diceConfig.count = i
            refreshAccentVisuals()
            saveDiceConfig()
            saveConfig()
            _GACC.applyDiceColors(_GACC.lastRolledDice)
        end)
    end
    refreshAccentVisuals()

    local previewRow = Instance.new("Frame", frame)
    previewRow.Position = UDim2.fromOffset(196, 66)
    previewRow.Size = UDim2.fromOffset(40, 28)
    previewRow.BackgroundTransparency = 1
    local pLay = Instance.new("UIListLayout", previewRow)
    pLay.FillDirection = Enum.FillDirection.Horizontal
    pLay.Padding = UDim.new(0, 3)
    pLay.VerticalAlignment = Enum.VerticalAlignment.Center
    for i = 1, 4 do
        local d = Instance.new("Frame", previewRow)
        d.Size = UDim2.fromOffset(7, 7)
        d.BorderSizePixel = 0
        d.BackgroundTransparency = 1
        Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
        previewDots[i] = d
    end
    refreshAccentVisuals()

    local dragStart, dragPos, dragging = nil, nil, false
    title.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = inp.Position; dragPos = frame.Position
            inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local delta = inp.Position - dragStart
            frame.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale, dragPos.Y.Offset + delta.Y)
        end
    end)

    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if UIS:GetFocusedTextBox() then return end
        if inp.KeyCode == Enum.KeyCode.P and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            sg.Enabled = not sg.Enabled
        end
    end)

    return sg
end

local function setupChatCommand()
    local function togglePanel()
        if not panelGui or not panelGui.Parent then panelGui = buildPanel()
        else panelGui.Enabled = not panelGui.Enabled end
    end
    local function handleMessage(message)
        local m = string.lower((string.gsub(message or "", "^%s+", "")))
        if m == "/panel" or m == "/rigged" then togglePanel() end
    end
    task.spawn(function()
        local ev = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        if ev then
            local onMsg = ev:FindFirstChild("OnMessageDoneFiltering")
            if onMsg then
                onMsg.OnClientEvent:Connect(function(data)
                    if data and data.Message then handleMessage(data.Message) end
                end)
            end
        end
    end)
    task.spawn(function()
        pcall(function()
            local tcs = game:GetService("TextChatService")
            if tcs.ChatVersion ~= Enum.ChatVersion.TextChatService then return end
            local cmd = tcs:FindFirstChild("TextChatCommands")
            if not cmd then return end
            if cmd:FindFirstChild("PanelCmd") then return end
            local c = Instance.new("TextChatCommand")
            c.Name = "PanelCmd"
            c.PrimaryAlias = "/panel"
            c.SecondaryAlias = "/rigged"
            c.Triggered:Connect(togglePanel)
            c.Parent = cmd
        end)
    end)
end
setupChatCommand()

if infJumpEnabled then startHoldInfJump() end
if antiRagdollEnabled then startAntiRagdoll() end
if medusaCounterEnabled then setupMedusa(LP.Character) end
applyBackgroundImage()
CandyApplyCustomSky(currentSkyTheme)
print("[RIGGED] Sistema caricato. Digita /panel in chat (o Ctrl+P) per aprire il pannello.")
print("Config attuale: " .. _GACC.diceConfig.accentColor .. " x" .. _GACC.diceConfig.count)
