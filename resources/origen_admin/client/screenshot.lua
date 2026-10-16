RegisterNetEvent("origen_admin:client:requestPhoto", function(webhook)
    exports['screenshot-basic']:requestScreenshotUpload(webhook, Config.Fields[Config.UploadMethod], function(data)
    end)
end)