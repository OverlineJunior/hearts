--[[
    TODO: Documentation.
]]

local Signal = require(script.Parent.Signal)

export type Data = {[any]: any}
type ModifierFn = (number, Data) -> number?
type GlobalModifierFn = (Humanoid, number, Data) -> number?

local modifiers: {[Humanoid]: {[number]: ModifierFn?}} = {}
local globalModifiers: {[number]: GlobalModifierFn?} = {}
local nextID = 1


local function IsEmpty(t: {}): boolean
    return next(t) == nil
end


local Hearts = {}

Hearts.HumanoidDamaged = Signal.new() --> (Humanoid, damage: number, Data)
Hearts.HumanoidHealed = Signal.new() --> (Humanoid, heal: number, Data)


function Hearts.Damage(target: Humanoid, amount: number, data: Data?)
    if amount < 0 then return end

    Hearts._Add(target, -amount, data)
end


function Hearts.Heal(target: Humanoid, amount: number, data: Data?)
    if amount < 0 then return end

    Hearts._Add(target, amount, data)
end


function Hearts.AddModifier(target: Humanoid, modifierFn: ModifierFn): number
    if not modifiers[target] then
        modifiers[target] = {}

        target.Destroying:Connect(function()
            for id in modifiers[target] do
                Hearts.RemoveModifier(id)
            end
        end)
    end

    modifiers[target][nextID] = modifierFn
    nextID += 1

    return nextID - 1
end


function Hearts.AddGlobalModifier(modifierFn: GlobalModifierFn): number
    globalModifiers[nextID] = modifierFn
    nextID += 1

    return nextID - 1
end


function Hearts.RemoveModifier(id: number)
    if globalModifiers[id] then
        globalModifiers[id] = nil
    else
        for hum, dict in modifiers do
            dict[id] = nil

            if IsEmpty(dict) then
                modifiers[hum] = nil
            end
        end
    end
end


function Hearts._Add(target: Humanoid, healthSum: number, data: Data)
    data = data or {}

    local function applyModifier(callback)
        local newHealthSum = callback()

        assert(
            type(newHealthSum) == 'number' or newHealthSum == nil,
            string.format('Expected modifier function to return either a number or nil, got %q instead', typeof(newHealthSum))
        )

        healthSum = newHealthSum or healthSum
    end

    for _, modifierFn in modifiers[target] or {} do
        applyModifier(function()
            return modifierFn(healthSum, data)
        end)
    end

    for _, gModifierFn in globalModifiers do
        applyModifier(function()
            return gModifierFn(target, healthSum, data)
        end)
    end

    if healthSum > 0 then
        -- Always positive, but different context.
        local heal = math.clamp(healthSum, 0, target.MaxHealth - target.Health)

        if heal == 0 then return end

        target.Health += heal
        Hearts.HumanoidHealed:Fire(target, heal, data)
    else
        -- Always positive, but different context.
        local damage = math.clamp(-healthSum, 0, target.Health)

        if damage == 0 then return end

        target:TakeDamage(damage)
        Hearts.HumanoidDamaged:Fire(target, damage, data)
    end
end


return Hearts
