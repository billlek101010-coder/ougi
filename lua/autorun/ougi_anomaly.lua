--[[
    Mirror Anomaly Clone
    Garry's Mod addon entrypoint.

    This addon creates an original, Monogatari-inspired anomaly that mirrors a
    player's playermodel, recolors it, wanders around, and speaks unsettling
    self-critical lines. It intentionally does not ship copyrighted characters,
    models, voices, or exact dialogue from any series.
]]

OUGI_ANOMALY = OUGI_ANOMALY or {}
OUGI_ANOMALY.Version = "1.0.0"
OUGI_ANOMALY.EntityClass = "ougi_anomaly_clone"

local function addEntityFile(path)
    if SERVER then
        AddCSLuaFile(path)
    end
end

addEntityFile("entities/ougi_anomaly_clone/shared.lua")
addEntityFile("entities/ougi_anomaly_clone/cl_init.lua")
addEntityFile("entities/ougi_anomaly_clone/init.lua")

if SERVER then
    CreateConVar("ougi_autospawn", "1", FCVAR_ARCHIVE, "Whether Mirror Anomalies spawn automatically near players.", 0, 1)
    CreateConVar("ougi_autospawn_min", "180", FCVAR_ARCHIVE, "Minimum seconds between automatic anomaly spawn attempts.", 30, 3600)
    CreateConVar("ougi_autospawn_max", "420", FCVAR_ARCHIVE, "Maximum seconds between automatic anomaly spawn attempts.", 30, 7200)
    CreateConVar("ougi_max_clones", "3", FCVAR_ARCHIVE, "Maximum active Mirror Anomaly clones.", 1, 32)
    CreateConVar("ougi_spawn_radius", "1400", FCVAR_ARCHIVE, "Maximum automatic spawn radius around a chosen player.", 128, 8192)
    CreateConVar("ougi_talk_interval_min", "18", FCVAR_ARCHIVE, "Minimum seconds between anomaly speech lines.", 5, 600)
    CreateConVar("ougi_talk_interval_max", "45", FCVAR_ARCHIVE, "Maximum seconds between anomaly speech lines.", 5, 900)

    local function getActiveClones()
        local clones = {}

        for _, ent in ipairs(ents.FindByClass(OUGI_ANOMALY.EntityClass)) do
            if IsValid(ent) then
                clones[#clones + 1] = ent
            end
        end

        return clones
    end

    local function choosePlayer(query)
        local humans = {}

        for _, ply in ipairs(player.GetHumans()) do
            if IsValid(ply) and ply:Alive() then
                humans[#humans + 1] = ply
            end
        end

        if query and query ~= "" then
            query = string.lower(query)

            for _, ply in ipairs(humans) do
                if string.find(string.lower(ply:Nick()), query, 1, true) or string.find(string.lower(ply:SteamID()), query, 1, true) then
                    return ply
                end
            end
        end

        if #humans == 0 then return nil end

        return humans[math.random(#humans)]
    end

    local function findSpawnPosition(ply, radius)
        if not IsValid(ply) then return nil end

        radius = radius or GetConVar("ougi_spawn_radius"):GetFloat()

        if navmesh and navmesh.GetNearestNavArea then
            for _ = 1, 18 do
                local offset = VectorRand()
                offset.z = 0
                offset:Normalize()
                offset = offset * math.Rand(220, radius)

                local area = navmesh.GetNearestNavArea(ply:GetPos() + offset, false, 600, false, true)

                if IsValid(area) then
                    return area:GetRandomPoint() + Vector(0, 0, 12)
                end
            end
        end

        for _ = 1, 24 do
            local offset = VectorRand()
            offset.z = 0
            offset:Normalize()
            offset = offset * math.Rand(160, radius)

            local startPos = ply:GetPos() + offset + Vector(0, 0, 256)
            local trace = util.TraceHull({
                start = startPos,
                endpos = startPos - Vector(0, 0, 1024),
                mins = Vector(-16, -16, 0),
                maxs = Vector(16, 16, 72),
                mask = MASK_PLAYERSOLID
            })

            if trace.Hit and not trace.StartSolid then
                return trace.HitPos + Vector(0, 0, 8)
            end
        end

        return ply:GetPos() + ply:GetForward() * 96 + Vector(0, 0, 8)
    end

    function OUGI_ANOMALY.SpawnClone(target, pos, creator)
        target = IsValid(target) and target or choosePlayer()
        if not IsValid(target) then return nil, "No living player found to mirror." end

        local maxClones = GetConVar("ougi_max_clones"):GetInt()
        if #getActiveClones() >= maxClones then
            return nil, "Clone limit reached."
        end

        local ent = ents.Create(OUGI_ANOMALY.EntityClass)
        if not IsValid(ent) then return nil, "Could not create anomaly entity." end

        pos = pos or findSpawnPosition(target)
        ent:SetPos(pos)
        ent:SetAngles(Angle(0, math.random(0, 359), 0))
        ent:SetCreator(IsValid(creator) and creator or target)
        ent.MirrorTarget = target
        ent:Spawn()
        ent:Activate()

        if ent.CopyPlayerIdentity then
            ent:CopyPlayerIdentity(target)
        end

        return ent
    end

    local function scheduleAutoSpawn()
        timer.Remove("OugiAnomalyAutoSpawn")

        local minDelay = math.max(30, GetConVar("ougi_autospawn_min"):GetFloat())
        local maxDelay = math.max(minDelay, GetConVar("ougi_autospawn_max"):GetFloat())

        timer.Create("OugiAnomalyAutoSpawn", math.Rand(minDelay, maxDelay), 1, function()
            if GetConVar("ougi_autospawn"):GetBool() then
                OUGI_ANOMALY.SpawnClone(choosePlayer())
            end

            scheduleAutoSpawn()
        end)
    end

    hook.Add("Initialize", "OugiAnomalyStartAutoSpawn", scheduleAutoSpawn)
    cvars.AddChangeCallback("ougi_autospawn_min", scheduleAutoSpawn, "OugiAnomalyMinChanged")
    cvars.AddChangeCallback("ougi_autospawn_max", scheduleAutoSpawn, "OugiAnomalyMaxChanged")

    concommand.Add("ougi_spawn", function(ply, _, args)
        if IsValid(ply) and not ply:IsAdmin() then
            ply:ChatPrint("Only admins can summon the anomaly.")
            return
        end

        local target = choosePlayer(args[1]) or (IsValid(ply) and ply or nil)
        local pos

        if IsValid(ply) then
            local trace = ply:GetEyeTrace()
            if trace.Hit then
                pos = trace.HitPos + Vector(0, 0, 8)
            end
        end

        local clone, err = OUGI_ANOMALY.SpawnClone(target, pos, ply)
        local msg = IsValid(clone) and ("Mirror Anomaly spawned for " .. target:Nick() .. ".") or ("Mirror Anomaly spawn failed: " .. tostring(err))

        if IsValid(ply) then
            ply:ChatPrint(msg)
        else
            print(msg)
        end
    end, nil, "Spawn a Mirror Anomaly clone. Optional argument: partial player name or SteamID.")

    concommand.Add("ougi_remove", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then
            ply:ChatPrint("Only admins can remove the anomaly.")
            return
        end

        local count = 0
        for _, ent in ipairs(getActiveClones()) do
            ent:Remove()
            count = count + 1
        end

        local msg = "Removed " .. count .. " Mirror Anomaly clone(s)."
        if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
    end, nil, "Remove all active Mirror Anomaly clones.")
end
