-- DST AI Mod - 状态采集器
-- 负责收集玩家、世界状态并提供给通信层

local StateCollector = Class(function(self, inst)
    self.inst = inst
    self.updateInterval = 0.5  -- 每0.5秒更新一次
    self.lastUpdate = 0
end)

-- 获取玩家状态
function StateCollector:GetPlayerState()
    if not self.inst or not self.inst:IsValid() then
        return nil
    end

    local pos = self.inst:GetPosition()
    local state = {
        hp = 1,
        hu = 1,
        sa = 1,
        x = math.floor(pos.x * 10) / 10,
        z = math.floor(pos.z * 10) / 10
    }

    -- 获取生命值
    if self.inst.components.health then
        state.hp = math.floor(self.inst.components.health:GetPercent() * 100) / 100
    end

    -- 获取饥饿值
    if self.inst.components.hunger then
        state.hu = math.floor(self.inst.components.hunger:GetPercent() * 100) / 100
    end

    -- 获取理智值
    if self.inst.components.sanity then
        state.sa = math.floor(self.inst.components.sanity:GetPercent() * 100) / 100
    end

    return state
end

-- 获取世界状态
function StateCollector:GetWorldState()
    if not TheWorld then
        return { day = 0, time = 0 }
    end

    local state = TheWorld.state
    return {
        day = state.cycles or 0,
        time = state.time or 0,
        season = state.season or "autumn",
        isday = state.isday or false,
        isnight = state.isnight or false,
        isdusk = state.isdusk or false,
        moonphase = state.moonphase or "new",
        israining = state.israining or false
    }
end

-- 检查是否需要更新
function StateCollector:ShouldUpdate(currentTime)
    return currentTime - self.lastUpdate >= self.updateInterval
end

-- 更新时间戳
function StateCollector:MarkUpdated(currentTime)
    self.lastUpdate = currentTime
end

return StateCollector
