-- DST AI Mod - 背包扫描器
-- 负责扫描玩家背包物品

local InventoryScanner = Class(function(self, inst)
    self.inst = inst
end)

-- 获取实体名称
local function GetEntityName(ent)
    if not ent then return "unknown" end

    -- 优先使用显示名称
    if ent.GetDisplayName and type(ent.GetDisplayName) == "function" then
        local name = ent:GetDisplayName()
        if name and name ~= "" and name ~= "MISSING NAME" then
            return name
        end
    end

    -- 使用 prefab 名称
    if ent.prefab then
        return ent.prefab
    end

    return "unknown"
end

-- 获取实体 prefab
local function GetEntityPrefab(ent)
    if not ent then return "unknown" end
    return ent.prefab or "unknown"
end

-- 获取物品堆叠数量
local function GetStackSize(ent)
    if ent.components.stackable then
        return ent.components.stackable:StackSize()
    end
    return 1
end

-- 获取物品剩余百分比（如工具耐久）
local function GetItemPercent(ent)
    if ent.components.finiteuses then
        return math.floor(ent.components.finiteuses:GetPercent() * 100)
    end
    if ent.components.armor then
        return math.floor(ent.components.armor:GetPercent() * 100)
    end
    if ent.components.fueled then
        return math.floor(ent.components.fueled:GetPercent() * 100)
    end
    return nil
end

-- 扫描背包物品
function InventoryScanner:ScanInventory()
    local items = {}

    if not self.inst or not self.inst:IsValid() then
        return items
    end

    local inv = self.inst.components.inventory
    if not inv then
        return items
    end

    -- 获取所有物品槽位
    local slots = inv:GetNumSlots()
    local seen = {}  -- 用于去重，相同prefab的物品合并计数

    for slot = 0, slots - 1 do
        local item = inv:GetItemInSlot(slot)
        if item then
            local prefab = GetEntityPrefab(item)
            local name = GetEntityName(item)
            local stack = GetStackSize(item)
            local percent = GetItemPercent(item)

            if not seen[prefab] then
                seen[prefab] = {
                    p = prefab,
                    n = name,
                    s = stack,
                    pc = percent
                }
            else
                -- 合并相同物品
                seen[prefab].s = seen[prefab].s + stack
            end
        end
    end

    -- 转换为数组格式
    for _, item in pairs(seen) do
        table.insert(items, item)
    end

    return items
end

-- 获取装备的物品
function InventoryScanner:GetEquippedItems()
    local equipped = {}

    if not self.inst or not self.inst:IsValid() then
        return equipped
    end

    local inv = self.inst.components.inventory
    if not inv then
        return equipped
    end

    -- 获取装备的物品
    local equipSlots = {
        { slot = "body", name = "body" },
        { slot = "head", name = "head" },
        { slot = "hands", name = "hands" }
    }

    for _, equipData in ipairs(equipSlots) do
        local item = inv:GetEquippedItem(equipData.slot)
        if item then
            table.insert(equipped, {
                p = GetEntityPrefab(item),
                n = GetEntityName(item),
                slot = equipData.name,
                pc = GetItemPercent(item)
            })
        end
    end

    return equipped
end

-- 查找特定物品
function InventoryScanner:FindItem(prefab)
    if not self.inst or not self.inst:IsValid() then
        return nil
    end

    local inv = self.inst.components.inventory
    if not inv then
        return nil
    end

    return inv:FindItem(function(item)
        return item.prefab == prefab
    end)
end

-- 检查是否有特定物品
function InventoryScanner:HasItem(prefab, amount)
    amount = amount or 1

    if not self.inst or not self.inst:IsValid() then
        return false
    end

    local inv = self.inst.components.inventory
    if not inv then
        return false
    end

    return inv:Has(prefab, amount)
end

-- 获取背包空位数
function InventoryScanner:GetEmptySlots()
    if not self.inst or not self.inst:IsValid() then
        return 0
    end

    local inv = self.inst.components.inventory
    if not inv then
        return 0
    end

    local slots = inv:GetNumSlots()
    local empty = 0

    for slot = 0, slots - 1 do
        if not inv:GetItemInSlot(slot) then
            empty = empty + 1
        end
    end

    return empty
end

return InventoryScanner
