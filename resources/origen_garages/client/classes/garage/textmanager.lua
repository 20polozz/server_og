TextManager = {
    activePoints = {}
}

function TextManager:ManageText(pointId, text, key, distance, showDistance)
    local point = self.activePoints[pointId]

    if distance < showDistance then
        if not point then
            self.activePoints[pointId] = { text = text, key = key, visible = true }
            Custom.DrawText(text, key)
        elseif not point.visible then
            point.visible = true
            Custom.DrawText(text, key)
        end
    elseif point and point.visible then
        point.visible = false
        Custom.HideText()
    end
end

function TextManager:RemoveText(pointId)
    if self.activePoints[pointId] and self.activePoints[pointId].visible then
        Custom.HideText()
    end
    self.activePoints[pointId] = nil
end