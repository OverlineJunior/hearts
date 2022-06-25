local Hearts = require(script.Parent.Hearts)

local me = workspace.Me.Humanoid
local enemy = workspace.Enemy.Humanoid

Hearts.AddModifier(me, function(_, data: Hearts.Data)
    data.X = 1
end)

Hearts.AddModifier(enemy, function() end)

Hearts.AddModifier(me, function() end)

Hearts.HumanoidDamaged:Connect(function(hum: Humanoid, heal: number, data: Hearts.Data)
    --print(data)
end)

task.wait(1)
Hearts.Damage(me, 90)
task.wait(1)
Hearts.Heal(me, 80)

task.delay(1, function()
    me:Destroy()
end)