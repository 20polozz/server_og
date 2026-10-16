--[[
    EL PANEL DE ADMINISTRACIÓN · lado cliente

    El puente entre el hub de origen_admin y la NUI. Igual que en los demás
    recursos: el hub llama a openManagement(), aquí se comprueba el permiso, se
    abre la pantalla y, al cerrarla, se devuelve el foco al hub.

    Ninguna de estas llamadas decide nada: lo que puede hacerse y lo que no lo
    dice el servidor, que vuelve a comprobar el permiso en cada callback.
]]

local desdeElHub = false

--- Cierra la pantalla y, si se abrió desde el hub, devuelve el foco allí.
local function cerrar()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeAdminBanking' })

    if desdeElHub then
        desdeElHub = false
        exports['origen_admin']:ReturnToScripts()
    end
end

exports('openManagement', function()
    desdeElHub = true

    CreateThread(function()
        local puedes = lib.callback.await('origen_banking:admin:puedes', false)
        if not puedes then
            lib.notify({
                title = 'Banco',
                description = 'No tienes permiso para administrar el banco',
                type = 'error',
            })
            desdeElHub = false
            exports['origen_admin']:ReturnToScripts()
            return
        end

        local resumen = lib.callback.await('origen_banking:admin:resumen', false)

        SendNUIMessage({
            action = 'openAdminBanking',
            data = { resumen = resumen },
        })

        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    end)
end)

RegisterNUICallback('adminCerrar', function(_, cb)
    cb('ok')
    cerrar()
end)

--- Las lecturas: se pasan tal cual y la pantalla se apaña con la respuesta.
local LECTURAS = {
    adminResumen = 'origen_banking:admin:resumen',
    adminCuentas = 'origen_banking:admin:cuentas',
    adminCuenta = 'origen_banking:admin:cuenta',
    adminMovimientos = 'origen_banking:admin:movimientos',
    adminBancos = 'origen_banking:admin:bancos',
    adminPuntos = 'origen_banking:admin:puntos',
}

for nombreNui, callback in pairs(LECTURAS) do
    RegisterNUICallback(nombreNui, function(datos, cb)
        cb(lib.callback.await(callback, false, datos))
    end)
end

--- Las escrituras: lo mismo, pero además avisan de cómo ha ido. El aviso lo
--- da el juego y no la pantalla, para que se vea aunque el panel se cierre.
local ESCRITURAS = {
    adminSaldo = 'origen_banking:admin:saldo',
    adminRenombrar = 'origen_banking:admin:renombrar',
    adminQuitarAcceso = 'origen_banking:admin:quitarAcceso',
    adminPermiso = 'origen_banking:admin:permiso',
    adminBorrar = 'origen_banking:admin:borrar',
    adminSaldoBanco = 'origen_banking:admin:saldoBanco',
    adminGuardarPunto = 'origen_banking:admin:guardarPunto',
    adminBorrarPunto = 'origen_banking:admin:borrarPunto',
}

for nombreNui, callback in pairs(ESCRITURAS) do
    RegisterNUICallback(nombreNui, function(datos, cb)
        local r = lib.callback.await(callback, false, datos) or {}
        lib.notify({
            title = 'Banco',
            description = r.mensaje or 'Sin respuesta del servidor',
            type = r.ok and 'success' or 'error',
            position = 'top-right',
            duration = 5000,
        })
        cb(r)
    end)
end
