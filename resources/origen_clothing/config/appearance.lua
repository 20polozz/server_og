AppearanceData = {
    props = {
        hats = { index = 0, value = 0, id = 'hats', texture = 0 },
        glasses = { index = 1, value = 0, id = 'glasses', texture = 0 },
        earrings = { index = 2, value = 0, id = 'earrings', texture = 0 },
        watches = { index = 6, value = 0, id = 'watches', texture = 0 },
        bracelets = { index = 7, value = 0, id = 'bracelets', texture = 0 }
    },

    drawables = {
        masks = { index = 1, value = 0, id = 'masks', texture = 0 },
        hair = { index = 2, value = 0, id = 'hair', texture = 0 },
        torsos = { index = 3, value = 0, id = 'torsos', texture = 0 },
        legs = { index = 4, value = 0, id = 'legs', texture = 0 },
        bags = { index = 5, value = 0, id = 'bags', texture = 0 },
        shoes = { index = 6, value = 0, id = 'shoes', texture = 0 },
        neck = { index = 7, value = 0, id = 'neck', texture = 0 },
        shirts = { index = 8, value = 0, id = 'shirts', texture = 0 },
        vest = { index = 9, value = 0, id = 'vest', texture = 0 },
        decals = { index = 10, value = 0, id = 'decals', texture = 0 },
        jackets = { index = 11, value = 0, id = 'jackets', texture = 0 },
    },

    headOverlay = {
        Blemishes = { index = 0, overlayOpacity = 0.5, firstColor = 0, colourType = 0, secondColor = 0, id = "Blemishes", overlayValue = 1, value = 1 },
        FacialHair = { index = 1, overlayOpacity = 1.0, firstColor = 3, colourType = 1, secondColor = 4, id = "FacialHair", overlayValue = 1, value = 1 },
        Eyebrows = { index = 2, overlayOpacity = 0.8, firstColor = 1, colourType = 1, secondColor = 2, id = "Eyebrows", overlayValue = 1, value = 0 },
        Ageing = { index = 3, overlayOpacity = 0.8, firstColor = 1, colourType = 0, secondColor = 2, id = "Ageing", overlayValue = 1, value = 1 },
        Makeup = { index = 4, overlayOpacity = 0.8, firstColor = 1, colourType = 1, secondColor = 2, id = "Makeup", overlayValue = 1, value = 1 },
        Blush = { index = 5, overlayOpacity = 0.8, firstColor = 1, colourType = 1, secondColor = 2, id = "Blush", overlayValue = 1, value = 1 },
        Complexion = { index = 6, overlayOpacity = 0.8, firstColor = 1, colourType = 0, secondColor = 2, id = "Complexion", overlayValue = 1, value = 1 },
        SunDamage = { index = 7, overlayOpacity = 0.8, firstColor = 1, colourType = 0, secondColor = 2, id = "SunDamage", overlayValue = 1, value = 1 },
        Lipstick = { index = 8, overlayOpacity = 0.8, firstColor = 1, colourType = 1, secondColor = 2, id = "Lipstick", overlayValue = 1, value = 1 },
        Moles = { index = 9, overlayOpacity = 0.8, firstColor = 1, colourType = 0, secondColor = 2, id = "Moles", overlayValue = 1, value = 1 },
        ChestHair = { index = 10, overlayOpacity = 1.0, firstColor = 3, colourType = 1, secondColor = 4, id = "ChestHair", overlayValue = 1, value = 1 },
        BodyBlemishes = { index = 11, overlayOpacity = 0.8, firstColor = 1, colourType = 0, secondColor = 2, id = "BodyBlemishes", overlayValue = 1, value = 1 }
    },

    headStructure = {
        Nose_Width = { index = 0, value = 0.0, id = "Nose_Width" },
        Nose_Peak_Height = { index = 1, value = 0.0, id = "Nose_Peak_Height" },
        Nose_Peak_Lenght = { index = 2, value = 0.0, id = "Nose_Peak_Lenght" },
        Nose_Bone_Height = { index = 3, value = 0.0, id = "Nose_Bone_Height" },
        Nose_Peak_Lowering = { index = 4, value = 0.0, id = "Nose_Peak_Lowering" },
        Nose_Bone_Twist = { index = 5, value = 0.0, id = "Nose_Bone_Twist" },
        Eyebrows_Height = { index = 6, value = 0.0, id = "Eyebrows_Height" },
        Eyebrows_Depth = { index = 7, value = 0.0, id = "Eyebrows_Depth" },
        Cheeks_Bone_High = { index = 8, value = 0.0, id = "Cheeks_Bone_High" },
        Cheeks_Width = { index = 9, value = 0.0, id = "Cheeks_Width" },
        Cheeks_Bone_Width = { index = 10, value = 0.0, id = "Cheeks_Bone_Width" },
        Eyes_Openning = { index = 11, value = 0.0, id = "Eyes_Openning" },
        Lips_Thickness = { index = 12, value = 0.0, id = "Lips_Thickness" },
        Jaw_Bone_Width = { index = 13, value = 0.0, id = "Jaw_Bone_Width" },
        Jaw_Bone_Back_Lenght = { index = 14, value = 0.0, id = "Jaw_Bone_Back_Lenght" },
        Chin_Bone_Lowering = { index = 15, value = 0.0, id = "Chin_Bone_Lowering" },
        Chin_Bone_Length = { index = 16, value = 0.0, id = "Chin_Bone_Length" },
        Chin_Bone_Width = { index = 17, value = 0.0, id = "Chin_Bone_Width" },
        Chin_Hole = { index = 18, value = 0.0, id = "Chin_Hole" },
        Neck_Thikness = { index = 19, value = 0.0, id = "Neck_Thikness" }
    },

    headBlend = { -- Indexing is needed because the 0x2746BD9D88C5C5D0 native return a table in the same order
        {
            index = "shapeFirst",
            value = 0
        },
        {
            index = "shapeSecond",
            value = 0
        },
        {
            index = "shapeThird",
            value = 0
        },
        {
            index = "skinFirst",
            value = 0
        },
        {
            index = "skinSecond",
            value = 0
        },
        {
            index = "skinThird",
            value = 0
        },
        {
            index = "shapeMix",
            value = 0.0
        },
        {
            index = "skinMix",
            value = 0.0
        },
        {
            index = "thirdMix",
            value = 0.0
        }
    }
}