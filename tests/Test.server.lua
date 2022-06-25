local Hearts = require(script.Parent.Hearts)

local me = workspace.Me.Humanoid
local enemy = workspace.Enemy.Humanoid

Hearts.AddModifier(me, function(healthSum: number)
    if healthSum < 0 then
        --return healthSum / 2
    end
end)

Hearts.HumanoidDamaged:Connect(function(hum: Humanoid, heal: number, data: Hearts.Data)
    print(heal)
end)

Hearts.Damage(me, 100000)