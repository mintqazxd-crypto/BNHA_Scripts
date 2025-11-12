-- BNHA Full System Script + Anti-AFK + Key System (20-char)
-- 🌟 Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Boku No Roblox X GAMEDES",
    LoadingTitle = "Welcome...",
    LoadingSubtitle = "By GAMEDES",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BNHAAutoScript",
        FileName = "AutoFarmQuest"
    },
    KeySystem = true,
    KeySettings = {
        Title = "Enter Script Key",
        Subtitle = "Please input your key to continue",
        Note = "Contact GAMEDES for key",
        Key = "BNHAKEY9876GAMEDES1234", -- 20 ตัวอักษร
        SaveKey = true,
        GrabKeyFromSite = false
    }
})

-- 🌟 เพิ่มปุ่ม GetKey ใต้ช่อง KeySystem
task.delay(0.5, function() -- รอให้ KeySystem สร้างเสร็จก่อน
    local keyGui = Window.MainFrame:FindFirstChild("KeySystemFrame")
    if keyGui then
        local getKeyButton = Instance.new("TextButton")
        getKeyButton.Name = "GetKeyButton"
        getKeyButton.Size = UDim2.new(0, 200, 0, 30)
        getKeyButton.Position = UDim2.new(0.5, -100, 0, 130) -- ปรับตำแหน่งใต้ช่อง Key
        getKeyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        getKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        getKeyButton.Text = "Get Key"
        getKeyButton.Parent = keyGui
        getKeyButton.MouseButton1Click:Connect(function()
            setclipboard("https://direct-link.net/1443008/ToVQGZPLskLY")
            Rayfield:Notify({
                Title = "Copied!",
                Content = "Key link copied to clipboard.",
                Duration = 3
            })
        end)
    end
end)

-- =========================
-- เริ่มสคริปต์เดิมทั้งหมด
-- =========================

local TabAuto = Window:CreateTab("⚔️ AutoFarm")
local TabSkill = Window:CreateTab("🎯 AutoSkill")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RepStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInput = game:GetService("VirtualInputManager")

local QuestModule
pcall(function()
    QuestModule = require(RepStorage.Questing.Main)
end)

-- 🌠 Defaults / Globals
_G.HitboxHeight = 11
_G.LockEnemy = true
_G.Invisible = false
_G.SkillKeys = {Q=false, Z=false, X=false, C=false, V=false, F=false}
_G.SkillDelay = 3
_G.AutoFarmMain = false

-- Anti-AFK
local VirtualUser = game:GetService("VirtualUser")
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)
print("✅ Anti-AFK active")

-- Character utilities
local function ensureCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    while not char:FindFirstChild("HumanoidRootPart") do
        char.ChildAdded:Wait()
    end
    return char
end

local function waitForAlive()
    repeat task.wait(0.5) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0
    return ensureCharacter()
end

-- Enlarge hitbox
local function enlargeHitbox(enemy, size)
    if not enemy or not enemy.Parent then return end
    local hrp = enemy:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hitbox = hrp:FindFirstChild("BNHA_FakeHitbox")
    if not hitbox then
        hitbox = Instance.new("Part")
        hitbox.Name = "BNHA_FakeHitbox"
        hitbox.Anchored = true
        hitbox.CanCollide = false
        hitbox.Parent = hrp
    end
    hitbox.Transparency = 0.7
    hitbox.Size = size
    hitbox.Material = Enum.Material.Neon
    hitbox.Color = Color3.fromRGB(255, 0, 0)
    hitbox.CFrame = hrp.CFrame
end

-- Invisible Maintainer
local function maintainInvisible()
    task.spawn(function()
        while true do
            task.wait(0.25)
            local char = LocalPlayer.Character
            if not char then continue end
            if _G.Invisible then
                for _, d in ipairs(char:GetDescendants()) do
                    if d:IsA("BasePart") then
                        d.Transparency = 1
                        d.LocalTransparencyModifier = 1
                    elseif d:IsA("Decal") then
                        d.Transparency = 1
                    elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
                        d.Enabled = false
                    elseif d:IsA("TextLabel") or d:IsA("TextButton") then
                        if d.Name == "NameTag" or d.Name == "DisplayName" then
                            d.Visible = false
                        end
                    end
                end
            else
                for _, d in ipairs(char:GetDescendants()) do
                    if d:IsA("BasePart") then
                        d.Transparency = 0
                        d.LocalTransparencyModifier = 0
                    elseif d:IsA("Decal") then
                        d.Transparency = 0
                    elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
                        d.Enabled = true
                    elseif d:IsA("TextLabel") or d:IsA("TextButton") then
                        if d.Name == "NameTag" or d.Name == "DisplayName" then
                            d.Visible = true
                        end
                    end
                end
            end
        end
    end)
end
maintainInvisible()

-- AutoSkill loop
task.spawn(function()
    while true do
        for key, enabled in pairs(_G.SkillKeys) do
            if enabled then
                pcall(function()
                    VirtualInput:SendKeyEvent(true, key, false, game)
                    task.wait(0.03)
                    VirtualInput:SendKeyEvent(false, key, false, game)
                end)
                task.wait(0.05)
            end
        end
        task.wait(math.max(0.1, _G.SkillDelay))
    end
end)

-- AutoFarm function with lock-oldest enemy
function AutoFarmMain(flagName, questId, npcNames, folders)
    task.spawn(function()
        ensureCharacter()
        local currentTarget = nil
        local stayStart = nil

        while _G[flagName] do
            pcall(function()
                -- ตรวจสอบ Quest
                if QuestModule then
                    local userQuest = QuestModule.PlayerQuests.getQuestFromUser(LocalPlayer, questId)
                    if not userQuest or userQuest:IsFinished() then
                        pcall(function() QuestModule.startQuest(LocalPlayer, questId) end)
                        task.wait(2)
                        currentTarget = nil
                    end
                end

                folders = folders or {workspace:FindFirstChild("NPCs")}
                -- เลือก NPC ตัวเก่าที่สุด
                if not currentTarget or not currentTarget:FindFirstChild("Humanoid") or currentTarget.Humanoid.Health <= 0 or (stayStart and tick()-stayStart>=45) then
                    currentTarget = nil
                    stayStart = nil
                    for _, folder in ipairs(folders) do
                        if folder then
                            for _, npc in ipairs(folder:GetChildren()) do
                                if table.find(npcNames, npc.Name) and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health>0 and npc:FindFirstChild("HumanoidRootPart") then
                                    currentTarget = npc
                                    stayStart = tick()
                                    -- Hitbox
                                    if currentTarget.Name:find("Awakened Tomura") then
                                        enlargeHitbox(currentTarget, Vector3.new(14,20,14))
                                    elseif currentTarget.Name:find("High End") then
                                        enlargeHitbox(currentTarget, Vector3.new(12,20,12))
                                    elseif currentTarget.Name:find("Nomu") then
                                        enlargeHitbox(currentTarget, Vector3.new(10,15,10))
                                    elseif currentTarget.Name:find("Villain") then
                                        enlargeHitbox(currentTarget, Vector3.new(8,12,8))
                                    else
                                        enlargeHitbox(currentTarget, Vector3.new(6,10,6))
                                    end
                                    break -- เจอแล้วหยุด ล็อกตัวเก่าที่สุด
                                end
                            end
                        end
                    end
                end

                -- วาป/โจมตี
                if currentTarget then
                    local char = LocalPlayer.Character
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local targetHRP = currentTarget:FindFirstChild("HumanoidRootPart")
                    if hrp and hum and targetHRP then
                        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
                        if _G.LockEnemy then
                            pcall(function()
                                targetHRP.Anchored=true
                                targetHRP.Velocity=Vector3.new(0,0,0)
                            end)
                        end
                        local targetPos = targetHRP.Position + Vector3.new(0,_G.HitboxHeight,0)
                        local angle = CFrame.Angles(math.rad(-90),0,0)
                        local smooth = 0.25
                        while currentTarget and currentTarget:FindFirstChild("Humanoid") and currentTarget.Humanoid.Health>0 and _G[flagName] and hum.Health>0 do
                            local goal = CFrame.new(targetPos)*angle
                            pcall(function()
                                hrp.AssemblyLinearVelocity=Vector3.zero
                                hrp.AssemblyAngularVelocity=Vector3.zero
                                hrp.CFrame = hrp.CFrame:Lerp(goal,smooth)
                            end)
                            if not hum.Sit then hum.Sit=true end
                            local swing = char:FindFirstChild("Main") and char.Main:FindFirstChild("Swing")
                            if swing then pcall(function() swing:FireServer(targetHRP.Position,targetHRP) end) end
                            RunService.Heartbeat:Wait()
                        end
                        if hum then pcall(function() hum.Sit=false end) end
                        if targetHRP then pcall(function() targetHRP.Anchored=false end) end
                    end
                    currentTarget=nil
                end
            end)
            task.wait(0.5)
        end
    end)
end

-- ========================
-- UI: AutoFarm toggles
-- ========================
TabAuto:CreateToggle({
    Name = "👊 Criminal 1–100",
    CurrentValue = false,
    Callback = function(val)
        _G.AutoFarmCriminal = val
        if val then AutoFarmMain("AutoFarmCriminal","QUEST_INJURED MAN_1",{"Criminal"}) end
    end
})
TabAuto:CreateToggle({
    Name = "🔥 Weak Villain 100–300",
    CurrentValue = false,
    Callback = function(val)
        _G.AutoFarmVillain100 = val
        if val then AutoFarmMain("AutoFarmVillain100","QUEST_AIZAWA_1",{"Weak Villain"}) end
    end
})
TabAuto:CreateToggle({
    Name = "👻 Villain 300–650",
    CurrentValue = false,
    Callback = function(val)
        _G.AutoFarmVillain300 = val
        if val then AutoFarmMain("AutoFarmVillain300","QUEST_HERO_1",{"Villain"}) end
    end
})
TabAuto:CreateToggle({
    Name = "🐱‍👤 Weak Nomu 650–1000",
    CurrentValue = false,
    Callback = function(val)
        _G.AutoFarmNomu = val
        if val then AutoFarmMain("AutoFarmNomu","QUEST_JEANIST_1",{"Weak Nomu 1","Weak Nomu 2","Weak Nomu 3","Weak Nomu 4"}) end
    end
})
TabAuto:CreateToggle({
    Name = "🧛‍♂️ High End 1000–MAX",
    CurrentValue = false,
    Callback = function(val)
        _G.AutoFarmHighEnd = val
        if val then AutoFarmMain("AutoFarmHighEnd","QUEST_MIRKO_1",{"High End 1","High End 2","High End 3","High End 4"},{workspace:FindFirstChild("NPCs")}) end
    end
})
TabAuto:CreateToggle({
    Name = "🧛‍♀️ Awakened Tomura 1000–MAX",
    CurrentValue = false,
    Callback = function(val)
        _G.AutoFarmTomura = val
        if val then AutoFarmMain("AutoFarmTomura","QUEST_MIRKO_1",{"Awakened Tomura"},{workspace:FindFirstChild("NPCs")}) end
    end
})

TabAuto:CreateSlider({
    Name = "📏 Attack Height",
    Range = {5,200},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = _G.HitboxHeight,
    Flag = "HitHeight",
    Callback = function(Value)
        _G.HitboxHeight = Value
        Rayfield:Notify({
            Title = "Height Adjusted",
            Content = "Current attack height: "..tostring(Value).." studs",
            Duration=3
        })
    end
})

TabAuto:CreateToggle({
    Name = "🧷 Lock Enemy",
    CurrentValue = _G.LockEnemy,
    Callback = function(v) _G.LockEnemy=v end
})

TabAuto:CreateToggle({
    Name = "👻 Invisible + Hide Name",
    CurrentValue = _G.Invisible,
    Callback = function(v) _G.Invisible=v end
})

-- ========================
-- UI: AutoSkill toggles + Delay
-- ========================
for _, k in ipairs({"Q","Z","X","C","V","F"}) do
    TabSkill:CreateToggle({
        Name = "Auto Skill ["..k.."]",
        CurrentValue = false,
        Callback = function(v)_G.SkillKeys[k]=v end
    })
end

TabSkill:CreateSlider({
    Name = "⏱️ Skill Delay (sec)",
    Range={1,10},
    Increment=0.5,
    Suffix="s",
    CurrentValue=_G.SkillDelay,
    Callback=function(v)_G.SkillDelay=v end
})

Rayfield:Notify({ Title="BNHA Script", Content="Script loaded + Anti-AFK", Duration=4 })
