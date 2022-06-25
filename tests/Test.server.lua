local Hearts = require(script.Parent.Hearts)

local me = workspace.Me.Humanoid
local enemy = workspace.Enemy.Humanoid

Hearts.AddGlobalModifier(function(_, _, data: Hearts.Data)
    data.X = 1
end)

Hearts.HumanoidDamaged:Connect(function(hum: Humanoid, heal: number, data: Hearts.Data)
    print(data)
end)

Hearts.Damage(me, 100000)