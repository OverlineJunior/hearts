local Hearts = require(script.Parent.Hearts)

local me = workspace.Me.Humanoid
local enemy = workspace.Enemy.Humanoid

local id1 = Hearts.AddModifier(me, function(healthSum: number)
    if healthSum < 0 then
        return healthSum / 2
    end
end)

local id2 = Hearts.AddGlobalModifier(function(healthSum: number)
    if healthSum < 0 then
        return healthSum / 2
    end
end)

Hearts.RemoveModifier(id1)
Hearts.RemoveModifier(id2)

Hearts.Damage(me, 50)
Hearts.Damage(enemy, 50)
task.wait(2)
Hearts.Heal(me, 50)