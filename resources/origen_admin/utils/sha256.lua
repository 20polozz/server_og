local master_key = "ABCDEFGHIJKLMNOPQRS"

-- Función para convertir una cadena en una tabla de bytes
local function stringToBytes(str)
    local bytes = {}
    for i = 1, #str do
        table.insert(bytes, str:byte(i))
    end
    return bytes
end

-- Función para convertir una tabla de bytes en una cadena
local function bytesToString(bytes)
    local chars = {}
    for i = 1, #bytes do
        table.insert(chars, string.char(bytes[i]))
    end
    return table.concat(chars)
end

-- Función para encriptar/desencriptar usando XOR
local function xorEncryptDecrypt(message)
    local messageBytes = stringToBytes(message)
    local keyBytes = stringToBytes(master_key)
    local keyLength = #keyBytes
    local encryptedBytes = {}

    for i = 1, #messageBytes do
        local keyByte = keyBytes[(i - 1) % keyLength + 1]
        table.insert(encryptedBytes, messageBytes[i] ~ keyByte)
    end

    return bytesToString(encryptedBytes)
end

exports("xorEncryptDecrypt", xorEncryptDecrypt)

-- local encrypted_message = xorEncryptDecrypt(message, master_key)
-- print("Mensaje encriptado:", encrypted_message)

-- local decrypted_message = xorEncryptDecrypt(encrypted_message, master_key)
-- print("Mensaje desencriptado:", decrypted_message)