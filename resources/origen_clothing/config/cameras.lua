Config.CameraZones = { -- W axis will contains the female height of each zone
    whole = "ZONE_SHIRTS",
    ZONE_HEAD = {
        boneId = 31086,
        camOffset = vector4(0.05, 0.7, 0, 0.05),
        targetOffset = vector4(0.05, 0, 0, 0.05),
        fov = 32.0
    },
    ZONE_NOSE = {
        boneId = 31086,
        camOffset = vector4(0.039, 1.0, -0.3, 0.039),
        targetOffset = vector4(0.039, 0.1, 0.0, 0.039),
        fov = 15.0
    },
    ZONE_EYEBROWS = {
        boneId = 31086,
        camOffset = vector4(0.0, 0.6, 0.0, 0.01),
        targetOffset = vector4(0.04, 0.0, 0.0, 0.04),
        fov = 19.0
    },
    ZONE_CHEEKS = {
        boneId = 31086,
        camOffset = vector4(0.0, 0.8, -0.3, 0),
        targetOffset = vector4(0.035, 0.1, 0.0, 0.035),
        fov = 20.0
    },
    ZONE_EYES = {
        boneId = 31086,
        camOffset = vector4(0.0, 0.7, 0, 0.0),
        targetOffset = vector4(0, 0, 0, 0.0),
        fov = 30.0
    },
    ZONE_LIPS = {
        boneId = 31086,
        camOffset = vector4(0.0, 0.6, 0.0, 0.02),
        targetOffset = vector4(-0.03, 0.0, 0.0, 0.02),
        fov = 10.0
    },
    ZONE_JAW = {
        boneId = 31086,
        camOffset = vector4(0.0, 0.6, 0.05, 0),
        targetOffset = vector4(-0.01, 0.0, 0.0, -0.01),
        fov = 18.0
    },
    ZONE_CHIN = {
        boneId = 31086,
        camOffset = vector4(-0.06, 0.8, -0.3, -0.06),
        targetOffset = vector4(-0.035, 0.1, 0.0, -0.035),
        fov = 15.0
    },
    ZONE_NECK = {
        boneId = 31086,
        camOffset = vector4(-0.09, 0.8, -0.3, -0.09),
        targetOffset = vector4(-0.07, 0.05, 0.0, -0.07),
        fov = 15.0
    },
    ZONE_HAIR = {
        boneId = 31086,
        camOffset = vector4(0.2, 0.8, -0.2, 0.2),
        targetOffset = vector4(0.1, 0.05, 0.0, 0.1),
        fov = 30.0
    },
    ZONE_MAKEUP = {
        boneId = 31086,
        camOffset = vector4(0, 0.7, 0, 0),
        targetOffset = vector4(0.02, 0, 0, 0.02),
        fov = 27.0
    },
    ZONE_CHEST = {
        boneId = 24818,
        camOffset = vector4(-0.05, 0.7, 0, -0.05),
        targetOffset = vector4(-0.05, 0, 0, -0.05),
        fov = 50.0
    },
    ZONE_MASKS = "ZONE_NOSE",
    ZONE_SHIRTS = {
        boneId = 24818,
        camOffset = vector4(-0.05, 0.7, 0, -0.05),
        targetOffset = vector4(-0.05, 0, 0, -0.05),
        fov = 60.0
    },
    ZONE_JACKETS = "ZONE_SHIRTS",
    ZONE_TORSOS = "ZONE_SHIRTS",
    ZONE_VEST = "ZONE_SHIRTS",
    ZONE_LEGS = {
        boneId = 24818,
        camOffset = vector4(-0.3, 0.9, 0, -0.3),
        targetOffset = vector4(-0.7, 0, 0, -0.7),
        fov = 60.0
    },
    ZONE_SHOES = {
        boneId = 24818,
        camOffset = vector4(-0.7, 0.9, 0, -0.7),
        targetOffset = vector4(-1.2, 0, 0, -1.2),
        fov = 60.0
    },
    ZONE_BAGS = {
        boneId = 24818,
        camOffset = vector4(0.2, -0.9, 0.3, 0.2),
        targetOffset = vector4(0.0, 0, 0, 0.0),
        fov = 50.0
    },
    ZONE_ACCESORIES = {
        boneId = 24818,
        camOffset = vector4(0.3, 0.5, 0, 0.3),
        targetOffset = vector4(0.13, 0, 0, 0.13),
        fov = 50.0
    },
    ZONE_DECALS = {
        boneId = 24818,
        camOffset = vector4(-0.5, 1.0, 0, -0.5),
        targetOffset = vector4(-0.5, 0, 0, -0.5),
        fov = 80.0
    },
    ZONE_HATS = "ZONE_HAIR",
    ZONE_GLASSES = "ZONE_EYES",
    ZONE_EARRINGS = "ZONE_EYES",
    ZONE_OUTFITS = "ZONE_DECALS",
    ZONE_WATCHES = {
        boneId = 24818,
        camOffset = vector4(-0.3, 0.2, 0.5, -0.3),
        targetOffset = vector4(-0.3, 0, 0.15, -0.3),
        fov = 80.0
    },
    ZONE_BRACELETS = {
        boneId = 24818,
        camOffset = vector4(-0.3, 0.2, -0.5, -0.3),
        targetOffset = vector4(-0.3, 0, -0.15, -0.3),
        fov = 80.0
    },
}

-- Don't touch this part

for k, v in pairs(Config.CameraZones) do
    if type(v) == "string" then
        Config.CameraZones[k] = Config.CameraZones[v]
    end
end