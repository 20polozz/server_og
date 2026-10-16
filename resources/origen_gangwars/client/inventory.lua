Internal.GetInventoryPath = function()
    local paths = {
        ['origen_inventory'] = 'https://cfx-nui-origen_inventory/ui/images/',
        ['ox_inventory'] = 'https://cfx-nui-ox_inventory/web/images/',
        ['ps-inventory'] = 'https://cfx-nui-ps-inventory/html/images/',
        ['new-ps-inventory'] = 'https://cfx-nui-ps-inventory/html/images/',
        ['qb-inventory'] = 'https://cfx-nui-qb-inventory/html/images/',
        ['new-qb-inventory'] = 'https://cfx-nui-qb-inventory/html/images/',
        ['core_inventory'] = 'https://cfx-nui-core_inventory/html/img/',
        ['codem-inventory'] = 'https://cfx-nui-codem-inventory/html/itemimages/',
        ['qs-inventory'] = 'https://cfx-nui-qs-inventory/html/images/',
        ['ak47_inventory'] = 'https://cfx-nui-ak47_inventory/html/img/items/',

        ['tgiann-inventory'] = 'https://cfx-nui-tgiann-inventory/html/inventory_images/images/',
    }

    return paths[Config.Inventory] or Custom.GetInventoryPath()
end