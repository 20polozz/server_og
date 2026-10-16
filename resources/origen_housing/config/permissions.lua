Config.Permissions = {
    ['create'] = {'god', 'admin'}, --? Acces to create a house
    ['delete'] = {'god', 'admin'}, --? Acces to delete a house
    ['edit'] = {'god', 'admin'}, --? Acces to edit a house
}

Config.Job = {
    active = true,
    allowed = {
        ['realestate'] = {
            minGrade = 1,
            create = true,
            delete = false,
            edit = false,
        },
    }
}