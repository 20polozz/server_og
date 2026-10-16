Config = {}
Config.Debug = false
Config.GreenScreenPos = vector4(1339.42, 5864.18, 2.57, 357.78)

Config.Save = {
    localFiles = false, -- If true the screenshots will be saved in the images folder of this resource
    fiveManageAPI = "yuKGcXFjnyikHdBjeVB8DwU4Nud6cJWF"
}

Config.ScreenshotCameras = {
    clothes = {
        [1] = {
            boneId = 31086,
            camOffset = vector4(0.039, 1.0, -0.3, 0.039),
            targetOffset = vector4(0.039, 0.1, 0.0, 0.039),
            fov = 30.0
        },
        [3] = {
            boneId = 24818,
            camOffset = vector4(-0.05, 0.7, 0, -0.05),
            targetOffset = vector4(-0.12, 0, 0, -0.05),
            fov = 70.0
        },
        [4] = {
            boneId = 24818,
            camOffset = vector4(-0.3, 0.9, 0, -0.3),
            targetOffset = vector4(-0.7, 0, 0, -0.7),
            fov = 70.0
        },
        [5] = {
            boneId = 24818,
            camOffset = vector4(0.2, -0.9, 0.3, 0.2),
            targetOffset = vector4(0.0, 0, 0, 0.0),
            fov = 50.0
        },
        [6] = {
            boneId = 24818,
            camOffset = vector4(-0.7, 0.9, 0, -0.7),
            targetOffset = vector4(-1.2, 0, 0, -1.2),
            fov = 60.0
        },
        [7] = {
            boneId = 24818,
            camOffset = vector4(0.3, 0.7, 0, 0.3),
            targetOffset = vector4(-0.05, 0, 0, 0.13),
            fov = 70.0
        },
        [8] = {
            boneId = 24818,
            camOffset = vector4(-0.05, 0.8, 0, -0.05),
            targetOffset = vector4(-0.05, 0, 0, -0.05),
            fov = 60.0
        },
        [9] = {
            boneId = 24818,
            camOffset = vector4(-0.05, 0.8, 0, -0.05),
            targetOffset = vector4(-0.05, 0, 0, -0.05),
            fov = 60.0
        },
        [10] = {
            boneId = 24818,
            camOffset = vector4(-0.5, 1.0, 0, -0.5),
            targetOffset = vector4(-0.5, 0, 0, -0.5),
            fov = 80.0
        },
        [11] = {
            boneId = 24818,
            camOffset = vector4(-0.05, 0.8, 0, -0.05),
            targetOffset = vector4(-0.05, 0, 0, -0.05),
            fov = 60.0
        }
    },
    props = {
        [0] = {
            boneId = 31086,
            camOffset = vector4(0.039, 1.0, -0.3, 0.039),
            targetOffset = vector4(0.039, 0.1, 0.0, 0.039),
            fov = 30.0
        },
        [1] = {
            boneId = 31086,
            camOffset = vector4(0.039, 1.0, -0.3, 0.039),
            targetOffset = vector4(0.039, 0.1, 0.0, 0.039),
            fov = 30.0
        },
        [2] = {
            boneId = 31086,
            camOffset = vector4(0.0, 0.7, 0, 0.0),
            targetOffset = vector4(0, 0, 0, 0.0),
            fov = 30.0
        },
        [6] = {
            boneId = 24818,
            camOffset = vector4(-0.3, 0.2, 0.5, -0.3),
            targetOffset = vector4(-0.3, 0, 0.15, -0.3),
            fov = 80.0
        },
        [7] = {
            boneId = 24818,
            camOffset = vector4(-0.3, 0.2, -0.5, -0.3),
            targetOffset = vector4(-0.3, 0, -0.15, -0.3),
            fov = 80.0
        }
    }
}

exports("GetConfig", function(key)
    return Config[key]
end)

return DATA