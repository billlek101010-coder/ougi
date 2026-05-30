AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"
ENT.PrintName = "Mirror Anomaly Clone"
ENT.Category = "Anomalies"
ENT.Spawnable = true
ENT.AdminOnly = true

local VOICE_LINES = {
    "To nie ja cię znalazłem. To twoje wątpliwości zostawiły otwarte drzwi.",
    "Nie wiem wszystkiego. Wiem tylko to, co ty próbujesz przemilczeć.",
    "Kłamstwo jest wygodne, ale wygoda zawsze zostawia ślad.",
    "Jeśli ten wybór był słuszny, czemu oglądasz się za siebie?",
    "Nie jestem potworem. Jestem korektą w marginesie twojej historii.",
    "Twoja twarz pasuje do mnie lepiej, kiedy nie muszę udawać spokoju.",
    "Nie uciekaj. Przecież to ty zaprosiłeś mnie do tej rozmowy.",
    "Ciekawe. Nawet tutaj mapa ma miejsca, których wolisz nie odwiedzać.",
    "Nie osądzam cię. Tylko przypominam werdykt, który już wydałeś.",
    "Zamknięte drzwi są najbardziej rozmowne. Wystarczy słuchać zawiasów."
}

local function convarFloat(name, fallback)
    local cv = GetConVar(name)
    if not cv then return fallback end
    return cv:GetFloat()
end

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "MirroredPlayer")
    self:NetworkVar("String", 0, "MirrorName")
end

function ENT:Initialize()
    self:SetHealth(100)
    self:SetModel("models/player/kleiner.mdl")
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetColor(Color(95, 55, 125, 230))
    self:SetCollisionGroup(COLLISION_GROUP_NPC)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))

    self.NextTalk = CurTime() + math.Rand(4, 10)
    self.HomePosition = self:GetPos()
    self.LastSeenTargetPosition = nil

    if self.loco then
        self.loco:SetAcceleration(650)
        self.loco:SetDeceleration(900)
        self.loco:SetStepHeight(24)
        self.loco:SetJumpHeight(58)
        self.loco:SetDesiredSpeed(105)
    end

    if IsValid(self.MirrorTarget) then
        self:CopyPlayerIdentity(self.MirrorTarget)
    end
end

function ENT:CopyPlayerIdentity(ply)
    if not IsValid(ply) then return end

    self.MirrorTarget = ply
    self:SetMirroredPlayer(ply)
    self:SetMirrorName(ply:Nick())
    self:SetModel(ply:GetModel())
    self:SetSkin(ply:GetSkin() or 0)

    for id = 0, ply:GetNumBodyGroups() - 1 do
        self:SetBodygroup(id, ply:GetBodygroup(id))
    end

    local playerColor = ply.GetPlayerColor and ply:GetPlayerColor() or Vector(0.25, 0.1, 0.35)
    self:SetPlayerColor(Vector(
        math.Clamp(1 - playerColor.x, 0.05, 1),
        math.Clamp(0.35 - playerColor.y * 0.25, 0.02, 0.65),
        math.Clamp(1 - playerColor.z * 0.15, 0.35, 1)
    ))

    local tint = Color(
        math.Clamp(90 + playerColor.z * 120, 40, 190),
        math.Clamp(35 + playerColor.x * 45, 20, 120),
        math.Clamp(120 + playerColor.y * 95, 90, 230),
        225
    )
    self:SetColor(tint)
end

function ENT:Use(activator)
    if IsValid(activator) and activator:IsPlayer() then
        self:Speak(activator)
    end
end

function ENT:OnInjured(dmgInfo)
    local attacker = dmgInfo:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() then
        self:Speak(attacker, "Ból jest tylko przypisem. Ważniejsze jest, dlaczego chciałeś go dopisać.")
    end
end

function ENT:OnKilled(dmgInfo)
    self:BecomeRagdoll(dmgInfo)
end

function ENT:Speak(listener, forcedLine)
    if not SERVER then return end

    local line = forcedLine or VOICE_LINES[math.random(#VOICE_LINES)]
    local name = self:GetMirrorName()
    if name == "" then name = "ktoś" end

    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) and ply:GetPos():DistToSqr(self:GetPos()) <= 1600 * 1600 then
            ply:ChatPrint("[Anomalia " .. name .. "] " .. line)
        end
    end

    self:EmitSound("vo/npc/male01/question" .. math.random(4, 9) .. ".wav", 65, math.random(78, 92), 0.45)
    self.NextTalk = CurTime() + math.Rand(convarFloat("ougi_talk_interval_min", 18), convarFloat("ougi_talk_interval_max", 45))
end

function ENT:FindInterestingPlayer()
    local mirrored = self:GetMirroredPlayer()
    if IsValid(mirrored) and mirrored:Alive() then
        return mirrored
    end

    local nearest
    local nearestDist = math.huge

    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) and ply:Alive() then
            local dist = self:GetRangeSquaredTo(ply)
            if dist < nearestDist then
                nearest = ply
                nearestDist = dist
            end
        end
    end

    return nearest
end

function ENT:Think()
    if SERVER and CurTime() >= (self.NextTalk or 0) then
        self:Speak(self:FindInterestingPlayer())
    end
end

function ENT:RunBehaviour()
    while true do
        local target = self:FindInterestingPlayer()

        if IsValid(target) then
            self.LastSeenTargetPosition = target:GetPos()

            if self:GetRangeSquaredTo(target) > 260 * 260 then
                self.loco:SetDesiredSpeed(120)
                self:StartActivity(ACT_WALK)
                self:MoveToPos(target:GetPos() + VectorRand(-120, 120), { tolerance = 90, maxage = 4 })
            else
                self:StartActivity(ACT_IDLE)
                self.loco:FaceTowards(target:GetPos())
                coroutine.wait(math.Rand(1.2, 3.4))
            end
        else
            self.loco:SetDesiredSpeed(85)
            self:StartActivity(ACT_WALK)
            self:MoveToPos(self:PickWanderPosition(), { tolerance = 80, maxage = 8 })
        end

        coroutine.yield()
    end
end

function ENT:PickWanderPosition()
    local origin = self.LastSeenTargetPosition or self.HomePosition or self:GetPos()

    if navmesh and navmesh.GetNearestNavArea then
        local area = navmesh.GetNearestNavArea(origin + VectorRand(-700, 700), false, 900, false, true)
        if IsValid(area) then
            return area:GetRandomPoint()
        end
    end

    local offset = VectorRand()
    offset.z = 0
    offset:Normalize()

    return origin + offset * math.Rand(160, 620)
end

function ENT:BodyUpdate()
    self:BodyMoveXY()
end
