local Hearts = require(script.Parent.Hearts)

local me = workspace.Me.Humanoid
local enemy = workspace.Enemy.Humanoid

Hearts.HumanoidDamaged:Connect(function(target: Humanoid, damage: number, data: Hearts.Data)
    if target == me and data.Source then
        Hearts.Damage(data.Source, damage / 2)
    end
end)

Hearts.Damage(me, 50, {
    Source = enemy,
})
