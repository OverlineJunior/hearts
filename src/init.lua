export type Data = {[any]: any}
type ModifierFn = (number, Data) -> number?
type Modifiers = {[Humanoid]: {[number]: ModifierFn?}}
type GlobalModifiers = {[number]: ModifierFn?}

local modifiers: Modifiers = {}
local globalModifiers: GlobalModifiers = {}
local nextID = 1

local Hearts = {}


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
    end

    modifiers[target][nextID] = modifierFn
    nextID += 1

    return nextID - 1
end


function Hearts.AddGlobalModifier(modifierFn: ModifierFn): number
    globalModifiers[nextID] = modifierFn
    nextID += 1

    return nextID - 1
end


function Hearts.RemoveModifier(id: number)
    globalModifiers[id] = nil

    for _, dict in modifiers do
        dict[id] = nil
    end
end


function Hearts._Add(target: Humanoid, healthSum: number, data: Data?)
    data = data or {}

    local function applyModifier(modifierFn: ModifierFn)
        local newHealthSum = modifierFn(healthSum, data)

        assert(
            type(newHealthSum) == 'number' or newHealthSum == nil,
            string.format('Expected middleware function to return either a number or nil, got %q instead', typeof(newHealthSum))
        )

        healthSum = newHealthSum or healthSum
    end

    for _, modifierFn in modifiers[target] or {} do
        applyModifier(modifierFn)
    end

    for _, modifierFn in globalModifiers do
        applyModifier(modifierFn)
    end

    if healthSum == 0 then return end

    if healthSum > 0 then
        target.Health += healthSum
    else
        target:TakeDamage(-healthSum)
    end
end


return Hearts