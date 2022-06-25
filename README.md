Simple module that expands humanoid health manipulation, such as modifying incoming damage/heal externally and passing related data.

```lua
local id: number

local function StartBlocking()
    id = Hearts.AddModifier(myHumanoid, function(healthChange: number, data: Hearts.Data)
        if healthChange < 0 and not data.IgnoresBlock then
            return healthChange / 2
        end
    end)
end

local function StopBlocking()
    Hearts.RemoveModifier(id)
end

Hearts.Damage(myHumanoid, 20) --> 20 dmg.

StartBlocking()

Hearts.Damage(myHumanoid, 20) --> 10 dmg.

Hearts.Damage(myHumanoid, 20, {
    IgnoresBlock = true,
}) --> 20 dmg.
```
