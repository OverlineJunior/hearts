local Signal = require(script.Parent.Signal)

--[=[
    @type Data {[any]: any?}
    @within Hearts

    Optional table that can be passed to [Hearts.Damage] and [Hearts.Heal]'s third parameter, which is then passed to modifiers
    and the [Hearts.HumanoidDamaged] and [Hearts.HumanoidHealed] events.

    ```lua
    -- myHumanoid is now a hedgehog, every humanoid that damages it now takes half of that damage.
    Hearts.HumanoidDamaged:Connect(function(target: Humanoid, damage: number, data: Hearts.Data)
        if target == myHumanoid and data.Source then
            Hearts.Damage(data.Source, damage / 2)
        end
    end)

    Hearts.Damage(myHumanoid, 20, {
        Source = enemyHumanoid,
    })
    ```
]=]
export type Data = {[any]: any?}
type ModifierFn = (number, Data) -> number?
type GlobalModifierFn = (Humanoid, number, Data) -> number?

local modifiers: {[Humanoid]: {[number]: ModifierFn?}} = {}
local globalModifiers: {[number]: GlobalModifierFn?} = {}
local nextID = 1


local function IsEmpty(t: {}): boolean
    return next(t) == nil
end


--[=[
    @class Hearts
]=]
local Hearts = {}

--[=[
    @prop HumanoidDamaged Signal<Humanoid, number, Data>
    @within Hearts
    @tag Event
]=]
Hearts.HumanoidDamaged = Signal.new() --> (Humanoid, damage: number, Data)
--[=[
    @prop HumanoidHealed Signal<Humanoid, number, Data>
    @within Hearts
    @tag Event
]=]
Hearts.HumanoidHealed = Signal.new() --> (Humanoid, heal: number, Data)


--- Removes health from the target, accepting an optional data table (empty if not given) that will be passed to modifiers and the [Hearts.HumanoidDamaged] event.
function Hearts.Damage(target: Humanoid, amount: number, data: Data?)
    if amount < 0 then return end

    Hearts._Add(target, -amount, data)
end


--- Adds health to the target, accepting an optional data table (empty if not given) that will be passed to modifiers and the [Hearts.HumanoidHealed] event.
function Hearts.Heal(target: Humanoid, amount: number, data: Data?)
    if amount < 0 then return end

    Hearts._Add(target, amount, data)
end


--[=[
    @param target Humanoid
    @param modifierFn (number, Data) -> number?
    @return number

    Adds a function that will be called everytime *target* is either damaged or healed, capable of modifying the health change by returning a different
    value (remaining the same if nothing is returned). Multiple can be used and all are automatically garbage collected when the *target* is destroyed.

    ```lua
    -- For each time myHumanoid is about to be healed, double the healing.
    Hearts.AddModifier(myHumanoid, function(healthChange: number)
        -- If healthChange is positive, it means it is healing, not damaging.
        if healthChange > 0 then
            return healthChange * 2
        end
    end)

    -- Because of the modifier, heals 100 health.
    Hearts.Heal(myHumanoid, 50)
    ```
]=]
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


--[=[
    @param globalModifierFn (Humanoid, number, Data) -> number?
    @return number

    Similar to [Hearts.AddModifier], but applies to every possible humanoid instead of a specific one.

    ```lua
    -- For every humanoid, deny letal damage.
    Hearts.AddGlobalModifier(function(humanoid: Humanoid, healthChange: number)
        -- If healthChange is damaging and letal, deny it.
        if humanoid.Health + healthChange <= 0 then
            return 0
        end
    end)

    -- If myHumanoid had 50 health or less, this call would be ignored because the damage would be letal.
    Hearts.Damage(myHumanoid, 50)
    ```

    Global modifiers can be useful for making sure data is sent the way our whole game expects it to be sent:

    ```lua
    Hearts.AddGlobalModifier(function(_, _, data: Hearts.Data)
        assert(data.Source, 'Source not defined')
    end)

    -- All good, the damage source was defined.
    Hearts.Damage(myHumanoid, 20, {
        Source = enemyHumanoid,
    })

    -- Errors because the damage source was not defined.
    Hearts.Damage(myHumanoid, 20)
    ```
]=]
function Hearts.AddGlobalModifier(globalModifierFn: GlobalModifierFn): number
    globalModifiers[nextID] = globalModifierFn
    nextID += 1

    return nextID - 1
end


--[=[
    Removes a modifier by its id, which is returned by [Hearts.AddModifier] and [Hearts.AddGlobalModifier].

    ```lua
    -- Denies every damage and heal directed to myHumanoid.
    local id = Hearts.AddModifier(myHumanoid, function()
        return 0
    end)

    -- Denied.
    Hearts.Damage(myHumanoid, 50)

    Hearts.RemoveModifier(id)

    -- Deals 50 damage since the modifier no longer exists.
    Hearts.Damage(myHumanoid, 50)
    ```
]=]
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
