-- Client Hooks — edit here to add custom logic without touching the core.

-- Fired when the client receives a new tag to render (on save or zone sync).
-- @param row.id         DB tag ID
-- @param row.coords     vector3 center
-- @param row.created_by license identifier
-- @param row.image_url  public image URL
-- @param row.created_at UTC timestamp string
AddEventHandler('graffiti:hook:onTagAdded', function(row)
end)

-- Fired when the client removes a tag from the local world.
-- @param id     tag DB ID
-- @param coords vector3 where the tag was
AddEventHandler('graffiti:hook:onTagRemoved', function(id, coords)
end)

-- Fired when local player enters or exits canvas mode (active painting session).
-- Useful to hide/show HUD, radial menus, etc.
-- @param active  boolean (true=enter canvas, false=exit canvas)
-- @param context table   { state, sessionId, isOwner }
AddEventHandler('graffiti:hook:onCanvasModeChanged', function(active, context)
end)
