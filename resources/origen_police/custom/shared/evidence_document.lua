-- ====================================================================
-- ORIGEN NETWORK — SISTEMA FORENSE Y GENERADOR DE FICHAS DE INFORME
-- Genera documentos periciales SVG ultranítidos (GSR, Huellas, Radar, Lab)
-- Totalmente autocontenidos en formato Data-URI (base64) compatibles con
-- la NUI, el visor fotográfico (CameraHud) y la MDT de Informes Policiales.
-- ====================================================================

local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function Base64Encode(data)
    if not data or #data == 0 then return "" end
    local len = #data
    local out = {}
    local outIdx = 1
    local i = 1
    while i <= len do
        local b1 = string.byte(data, i)
        local b2 = (i + 1 <= len) and string.byte(data, i + 1) or nil
        local b3 = (i + 2 <= len) and string.byte(data, i + 2) or nil
        
        local n = (b1 << 16) | ((b2 or 0) << 8) | (b3 or 0)
        
        local c1 = (n >> 18) & 63
        local c2 = (n >> 12) & 63
        local c3 = (n >> 6) & 63
        local c4 = n & 63
        
        out[outIdx] = string.sub(b64chars, c1 + 1, c1 + 1)
        out[outIdx + 1] = string.sub(b64chars, c2 + 1, c2 + 1)
        out[outIdx + 2] = b2 and string.sub(b64chars, c3 + 1, c3 + 1) or '='
        out[outIdx + 3] = b3 and string.sub(b64chars, c4 + 1, c4 + 1) or '='
        
        outIdx = outIdx + 4
        i = i + 3
    end
    return table.concat(out)
end

local function EscapeXml(str)
    if str == nil then return "" end
    local s = tostring(str)
    s = string.gsub(s, "&", "&amp;")
    s = string.gsub(s, "<", "&lt;")
    s = string.gsub(s, ">", "&gt;")
    s = string.gsub(s, '"', "&quot;")
    s = string.gsub(s, "'", "&apos;")
    return s
end

local function FormatTimestamp(ts)
    if not ts or ts == 0 then
        return os.date("%d/%m/%Y %H:%M")
    end
    return os.date("%d/%m/%Y %H:%M", tonumber(ts))
end

local function FormatEvidenceItem(ev)
    local rawType = ev.type or "Evidencia"
    local typeLabel = rawType
    local desc = ev.description or ""

    if rawType == "Shoot" then
        typeLabel = "Casquillo Balístico"
        if desc == "" then
            local parts = {}
            if ev.ammo and ev.ammo ~= "" then table.insert(parts, "Calibre: " .. ev.ammo) end
            if ev.fkserie and ev.fkserie ~= "" and ev.fkserie ~= "UNKNOW" then table.insert(parts, "Serie: " .. ev.fkserie) end
            if ev.count and tonumber(ev.count) and tonumber(ev.count) > 1 then table.insert(parts, "Cant: " .. ev.count) end
            desc = #parts > 0 and table.concat(parts, " | ") or "Casquillo recuperado en la escena"
        end
    elseif rawType == "Impact" then
        typeLabel = "Impacto de Proyectil"
        if desc == "" then
            local parts = {}
            if ev.ammo and ev.ammo ~= "" then table.insert(parts, "Calibre: " .. ev.ammo) end
            if ev.fkserie and ev.fkserie ~= "" and ev.fkserie ~= "UNKNOW" then table.insert(parts, "Serie: " .. ev.fkserie) end
            desc = #parts > 0 and table.concat(parts, " | ") or "Impacto balístico analizado"
        end
    elseif rawType == "BloodRest" or rawType == "NpcBlood" then
        if rawType == "NpcBlood" then
            typeLabel = "Muestra Hemática (No identificada)"
            desc = "Muestra biológica no humana o sin registro"
        else
            if ev.matched then
                typeLabel = "Muestra de Sangre [IDENTIFICADA]"
                desc = ("CODIS: %s | Grupo: %s"):format(ev.adn or "Identificado", ev.bloodType or "Desc.")
            else
                typeLabel = "Muestra de Sangre [SIN COINCIDENCIA]"
                desc = ("Sin registro previo | Grupo: %s (Pendiente hisopo)"):format(ev.bloodType or "Desc.")
            end
        end
    elseif rawType == "DNA" or rawType == "Hisopo" then
        typeLabel = "Registro Genético (ADN)"
        if desc == "" then
            desc = "Frotis bucal homologado en base CODIS"
        end
    elseif rawType == "VehCrash" then
        typeLabel = "Restos de Accidente"
        if desc == "" then
            local parts = {}
            if ev.model and ev.model ~= "" then table.insert(parts, "Modelo: " .. ev.model) end
            if ev.count and tonumber(ev.count) and tonumber(ev.count) > 1 then table.insert(parts, "Fragmentos: " .. ev.count) end
            desc = #parts > 0 and table.concat(parts, " | ") or "Restos de carrocería analizados"
        end
    elseif rawType == "FinguerPrint" or rawType == "FingerPrint" then
        typeLabel = "Huella Dactilar"
        if desc == "" then
            local fp = ev.fingerprint or ev.adn or ev.name
            desc = fp and ("Identificación: " .. fp) or "Huella dactilar cotejada"
        end
    elseif rawType == "GSR" or rawType == "Gsr" then
        typeLabel = "Residuos de Disparo (GSR)"
        if desc == "" then
            desc = ev.gsrResult and ("Resultado: " .. ev.gsrResult) or "Test de deflagración balística"
        end
    elseif rawType == "Drug" then
        typeLabel = "Sustancia Estupefaciente"
        if desc == "" then
            desc = "Muestra de sustancia química ilícita"
        end
    end

    if desc == "" then
        desc = "Indicio pericial procesado"
    end

    return typeLabel, desc
end

function GenerateEvidenceDocumentSVG(data, itemName)
    data = data or {}
    local evType = data.type or ""
    if evType == "" then
        if itemName == "evidence_gsr" then
            evType = "GSR"
        elseif itemName == "evidence_ne" then
            evType = "FinguerPrint"
        elseif itemName == "ticket_radar" then
            evType = "Ticket Radar"
        elseif itemName == "evidence_dna" then
            evType = "DNA"
        else
            evType = "Report"
        end
    end

    local name = EscapeXml(data.name or data.targetName or data.target or "Sujeto no filiado")
    local cid = EscapeXml(data.adn or data.citizenid or "SIN-CID")
    local dateStr = EscapeXml(data.date or FormatTimestamp(data.time))
    local serie = EscapeXml(data.serie or data.serial or ("EV-" .. (os.time() or 0)))
    local officer = EscapeXml(data.officer or data.agent or "División Científica SAPD")

    local title = "INFORME DE ANÁLISIS FORENSE"
    local subtitle = "DEPARTAMENTO DE POLICÍA CIENTÍFICA"
    local resultSection = ""

    if evType == "DNA" or evType == "Hisopo" or itemName == "evidence_dna" then
        title = "CERTIFICADO DE PERFIL GENÉTICO"
        subtitle = "REGISTRO BIOLÓGICO Y COTEJO CODIS (SAN ANDREAS)"
        local bloodType = EscapeXml(data.bloodType or data.bloodtype or "No determinado")

        resultSection = string.format([[
      <!-- Subject Info Box -->
      <g transform="translate(32, 210)">
        <rect width="576" height="74" rx="8" fill="#10151f" stroke="#1d2635" stroke-width="1"/>
        <text x="18" y="24" font-size="10" font-weight="800" fill="#64748b" letter-spacing="1">SUJETO REGISTRADO</text>
        <text x="18" y="47" font-size="16" font-weight="800" fill="#f8fafc">%s</text>
        <text x="18" y="64" font-family="monospace" font-size="11" font-weight="700" fill="#94a3b8">CID: <tspan fill="#60a5fa">%s</tspan></text>

        <text x="558" y="24" font-size="10" font-weight="800" fill="#64748b" letter-spacing="1" text-anchor="end">AGENTE OPERADOR</text>
        <text x="558" y="47" font-size="13" font-weight="700" fill="#cbd5e1" text-anchor="end">%s</text>
        <text x="558" y="64" font-size="10.5" font-weight="600" fill="#64748b" text-anchor="end">GRUPO SANGUÍNEO: <tspan fill="#f43f5e">%s</tspan></text>
      </g>

      <!-- Main Result Banner -->
      <g transform="translate(32, 296)">
        <rect width="576" height="154" rx="10" fill="rgba(16, 185, 129, 0.08)" stroke="#10b981" stroke-width="1.8"/>
        <rect x="18" y="18" width="95" height="24" rx="4" fill="#059669"/>
        <text x="65.5" y="34.5" font-size="11" font-weight="800" fill="#ffffff" text-anchor="middle" letter-spacing="1">ARCHIVADO</text>
        
        <text x="125" y="35.5" font-size="15" font-weight="800" fill="#86efac" letter-spacing="0.5">PERFIL DE ADN INCORPORADO A CODIS</text>
        
        <rect x="18" y="58" width="540" height="34" rx="5" fill="#080e18" stroke="#047857" stroke-width="1"/>
        <text x="30" y="80" font-family="monospace" font-size="13" font-weight="700" fill="#34d399" letter-spacing="1">EXPEDIENTE BIOLÓGICO: CODIS-%s</text>

        <line x1="18" y1="104" x2="558" y2="104" stroke="#10b981" stroke-width="1" stroke-opacity="0.25"/>
        <text x="18" y="130" font-size="11" font-weight="600" fill="#94a3b8">DICTAMEN: <tspan fill="#f1f5f9">Frotis bucal (hisopo) analizado y catalogado para cotejos forenses del Estado.</tspan></text>
      </g>

      <!-- Analysis Details -->
      <g transform="translate(32, 462)">
        <rect width="576" height="136" rx="8" fill="#0d1219" stroke="#192230" stroke-width="1"/>
        <text x="18" y="24" font-size="10.5" font-weight="800" fill="#94a3b8" letter-spacing="1">DILIGENCIAS DEL FROTIS BUCAL</text>
        
        <circle cx="24" cy="48" r="2.5" fill="#10b981"/>
        <text x="34" y="52" font-size="11.5" font-weight="500" fill="#cbd5e1">Muestra celular epitelial extraída in vivo mediante hisopo bucal esterilizado.</text>

        <circle cx="24" cy="74" r="2.5" fill="#10b981"/>
        <text x="34" y="78" font-size="11.5" font-weight="500" fill="#cbd5e1">Secuenciación de marcadores genéticos integrada en el banco pericial de San Andreas.</text>

        <circle cx="24" cy="100" r="2.5" fill="#10b981"/>
        <text x="34" y="104" font-size="11.5" font-weight="500" fill="#cbd5e1">Válido como justificante pericial vinculable a la ficha policial del ciudadano.</text>
      </g>
        ]], name, cid, officer, bloodType, string.upper(cid))

    elseif evType == "GSR" or evType == "Gsr" then
        title = "TEST BALÍSTICO RESIDUAL (GSR)"
        subtitle = "ANÁLISIS DE RESIDUOS DE DISPARO EN MANOS Y PRENDAS"

        local isPositive = false
        if data.gsrResult then
            isPositive = (string.find(string.upper(tostring(data.gsrResult)), "POSITIVO") ~= nil)
        elseif data.description then
            isPositive = (string.find(string.upper(tostring(data.description)), "POSITIVO") ~= nil)
        end

        local badgeText = isPositive and "POSITIVO" or "NEGATIVO"
        local badgeColor = isPositive and "#dc2626" or "#059669"
        local bg = isPositive and "rgba(220, 38, 38, 0.08)" or "rgba(5, 150, 105, 0.08)"
        local stroke = isPositive and "#ef4444" or "#10b981"
        local textMain = isPositive and "RESTOS DE DISPARO DETECTADOS" or "SIN RESTOS DE DEFLAGRACIÓN"
        local textMainColor = isPositive and "#fca5a5" or "#86efac"
        local textLine1 = isPositive
            and "Se han detectado concentraciones químicas compatibles con deflagración"
            or "No se han detectado trazas químicas compatibles con residuos balísticos"
        local textLine2 = isPositive
            and "de pólvora en las manos o prendas del sujeto analizado."
            or "en las muestras recabadas del sujeto en la exploración pericial."
        local subNote = isPositive
            and "Indicio compatible con disparo o manipulación de arma de fuego."
            or "Muestra negativa para residuos de disparo en el lapso examinado."

        resultSection = string.format([[
      <!-- Subject Info Box -->
      <g transform="translate(32, 210)">
        <rect width="576" height="74" rx="8" fill="#10151f" stroke="#1d2635" stroke-width="1"/>
        <text x="18" y="24" font-size="10" font-weight="800" fill="#64748b" letter-spacing="1">SUJETO INVESTIGADO</text>
        <text x="18" y="47" font-size="16" font-weight="800" fill="#f8fafc">%s</text>
        <text x="18" y="64" font-family="monospace" font-size="11" font-weight="700" fill="#94a3b8">CID: <tspan fill="#60a5fa">%s</tspan></text>

        <text x="558" y="24" font-size="10" font-weight="800" fill="#64748b" letter-spacing="1" text-anchor="end">AGENTE ACTUANTE</text>
        <text x="558" y="47" font-size="13" font-weight="700" fill="#cbd5e1" text-anchor="end">%s</text>
        <text x="558" y="64" font-size="10.5" font-weight="600" fill="#64748b" text-anchor="end">ESTADO: <tspan fill="#10b981">REGISTRADO</tspan></text>
      </g>

      <!-- Main Result Banner -->
      <g transform="translate(32, 296)">
        <rect width="576" height="154" rx="10" fill="%s" stroke="%s" stroke-width="1.8"/>
        <rect x="18" y="18" width="90" height="24" rx="4" fill="%s"/>
        <text x="63" y="34.5" font-size="11" font-weight="800" fill="#ffffff" text-anchor="middle" letter-spacing="1">%s</text>
        
        <text x="120" y="35.5" font-size="15" font-weight="800" fill="%s" letter-spacing="0.5">%s</text>
        
        <text x="18" y="67" font-size="12" font-weight="500" fill="#e2e8f0">%s</text>
        <text x="18" y="86" font-size="12" font-weight="500" fill="#e2e8f0">%s</text>
        <line x1="18" y1="104" x2="558" y2="104" stroke="%s" stroke-width="1" stroke-opacity="0.25"/>
        <text x="18" y="130" font-size="11" font-weight="600" fill="#94a3b8">DICTAMEN: <tspan fill="#f1f5f9">%s</tspan></text>
      </g>

      <!-- Analysis Details -->
      <g transform="translate(32, 462)">
        <rect width="576" height="136" rx="8" fill="#0d1219" stroke="#192230" stroke-width="1"/>
        <text x="18" y="24" font-size="10.5" font-weight="800" fill="#94a3b8" letter-spacing="1">DILIGENCIAS PERICIALES DEL PROCEDIMIENTO</text>
        
        <circle cx="24" cy="48" r="2.5" fill="#3b82f6"/>
        <text x="34" y="52" font-size="11.5" font-weight="500" fill="#cbd5e1">Muestra química recolectada in situ con aplicador homologado de absorción dérmica.</text>

        <circle cx="24" cy="74" r="2.5" fill="#3b82f6"/>
        <text x="34" y="78" font-size="11.5" font-weight="500" fill="#cbd5e1">Ventana temporal examinada: aproximadamente 60 minutos previos a la toma.</text>

        <circle cx="24" cy="100" r="2.5" fill="#3b82f6"/>
        <text x="34" y="104" font-size="11.5" font-weight="500" fill="#cbd5e1">Ficha digitalizada y sellada para incorporación al informe policial del atestado.</text>
      </g>
        ]], name, cid, officer, bg, stroke, badgeColor, badgeText, textMainColor, textMain, textLine1, textLine2, stroke, subNote)

    elseif evType == "FinguerPrint" or evType == "FingerPrint" then
        title = "INFORME BIOMÉTRICO DACTILOSCÓPICO"
        subtitle = data.plate and "HUELLAS DACTILARES RECUPERADAS EN VEHÍCULO" or "COTEJO EN EL SISTEMA DE IDENTIFICACIÓN DACTILAR (AFIS)"
        local fp = EscapeXml(data.fingerprint or data.adn or "HUELLA-REGISTRADA")

        local detailTitle = data.plate and "DETALLES DE LA PERITACIÓN EN VEHÍCULO" or "DETALLES DEL ESCANEO BIOMÉTRICO"
        local detail1 = data.plate and string.format("Vehículo peritado: <tspan fill='#60a5fa' font-weight='700'>%s [MATRÍCULA: %s]</tspan>", EscapeXml(data.model or "Vehículo"), EscapeXml(data.plate or "")) or "Captura biométrica realizada mediante escáner óptico portátil de alta resolución."
        local detail2 = data.plate and "Muestras extraídas del volante, pomo del selector y mandos interiores." or "Identificación dactiloscópica cruzada contra el padrón biométrico del Estado."
        local detail3 = data.plate and "Coincidencia pericial positiva al 100%% en AFIS. Sin uso de guantes por el conductor." or "Ficha digitalizada y vinculable directamente a los expedientes de la central policial."

        resultSection = string.format([[
      <!-- Subject Info Box -->
      <g transform="translate(32, 210)">
        <rect width="576" height="74" rx="8" fill="#10151f" stroke="#1d2635" stroke-width="1"/>
        <text x="18" y="24" font-size="10" font-weight="800" fill="#64748b" letter-spacing="1">SUJETO INVESTIGADO</text>
        <text x="18" y="47" font-size="16" font-weight="800" fill="#f8fafc">%s</text>
        <text x="18" y="64" font-family="monospace" font-size="11" font-weight="700" fill="#94a3b8">CID: <tspan fill="#60a5fa">%s</tspan></text>

        <text x="558" y="24" font-size="10" font-weight="800" fill="#64748b" letter-spacing="1" text-anchor="end">AGENTE OPERADOR</text>
        <text x="558" y="47" font-size="13" font-weight="700" fill="#cbd5e1" text-anchor="end">%s</text>
        <text x="558" y="64" font-size="10.5" font-weight="600" fill="#64748b" text-anchor="end">SISTEMA: <tspan fill="#3b82f6">AFIS ACTIVO</tspan></text>
      </g>

      <!-- Main Result Banner -->
      <g transform="translate(32, 296)">
        <rect width="576" height="154" rx="10" fill="rgba(37, 99, 235, 0.08)" stroke="#2563eb" stroke-width="1.8"/>
        <rect x="18" y="18" width="90" height="24" rx="4" fill="#2563eb"/>
        <text x="63" y="34.5" font-size="11" font-weight="800" fill="#ffffff" text-anchor="middle" letter-spacing="1">COTEJADA</text>
        
        <text x="120" y="35.5" font-size="15" font-weight="800" fill="#93c5fd" letter-spacing="0.5">REGISTRO DACTILAR IDENTIFICADO</text>
        
        <rect x="18" y="58" width="540" height="34" rx="5" fill="#080e18" stroke="#1d4ed8" stroke-width="1"/>
        <text x="30" y="80" font-family="monospace" font-size="13" font-weight="700" fill="#60a5fa" letter-spacing="1">HUELLA REGISTRADA: %s</text>

        <line x1="18" y1="104" x2="558" y2="104" stroke="#2563eb" stroke-width="1" stroke-opacity="0.25"/>
        <text x="18" y="130" font-size="11" font-weight="600" fill="#94a3b8">VERIFICACIÓN: <tspan fill="#f1f5f9">Coincidencia verificada al 100%%%% de puntos característicos (minucias).</tspan></text>
      </g>

      <!-- Analysis Details -->
      <g transform="translate(32, 462)">
        <rect width="576" height="136" rx="8" fill="#0d1219" stroke="#192230" stroke-width="1"/>
        <text x="18" y="24" font-size="10.5" font-weight="800" fill="#94a3b8" letter-spacing="1">%s</text>
        
        <circle cx="24" cy="48" r="2.5" fill="#3b82f6"/>
        <text x="34" y="52" font-size="11.5" font-weight="500" fill="#cbd5e1">%s</text>

        <circle cx="24" cy="74" r="2.5" fill="#3b82f6"/>
        <text x="34" y="78" font-size="11.5" font-weight="500" fill="#cbd5e1">%s</text>

        <circle cx="24" cy="100" r="2.5" fill="#3b82f6"/>
        <text x="34" y="104" font-size="11.5" font-weight="500" fill="#cbd5e1">%s</text>
      </g>
        ]], name, cid, officer, fp, detailTitle, detail1, detail2, detail3)

    elseif evType == "Ticket Radar" then
        title = "BOLETÍN SANCIONADOR DE RADAR"
        subtitle = "REGISTRO CINEMOMÉTRICO DE EXCESO DE VELOCIDAD"
        local plate = EscapeXml(data.targetPlate or "DESCONOCIDA")
        local speed = EscapeXml(data.targetSpeed or "0")
        local limit = EscapeXml(data.limit or "0")
        local street = EscapeXml(data.street or "Vía pública de San Andreas")
        if #street > 30 then street = string.sub(street, 1, 28) .. "..." end
        local patrol = EscapeXml(data.policePlate or "UNIDAD POLICIAL")
        if #patrol > 18 then patrol = string.sub(patrol, 1, 16) .. "..." end

        resultSection = string.format([[
      <!-- Vehicle and Speed Banner -->
      <g transform="translate(32, 210)">
        <rect width="576" height="150" rx="10" fill="rgba(245, 158, 11, 0.08)" stroke="#f59e0b" stroke-width="1.8"/>
        <rect x="18" y="18" width="105" height="24" rx="4" fill="#f59e0b"/>
        <text x="70.5" y="34.5" font-size="11" font-weight="800" fill="#000000" text-anchor="middle" letter-spacing="1">INFRACCIÓN</text>
        
        <text x="135" y="35.5" font-size="15" font-weight="800" fill="#fde68a" letter-spacing="0.5">EXCESO DE VELOCIDAD CAPTADO</text>

        <g transform="translate(18, 56)">
          <rect width="160" height="36" rx="5" fill="#fef08a" stroke="#ca8a04" stroke-width="1.5"/>
          <text x="80" y="24" font-family="monospace" font-size="17" font-weight="900" fill="#000000" text-anchor="middle" letter-spacing="3">%s</text>
        </g>

        <text x="195" y="72" font-size="12" font-weight="600" fill="#94a3b8">VELOCIDAD DETECTADA: <tspan fill="#f87171" font-weight="800" font-size="14">%s</tspan></text>
        <text x="195" y="90" font-size="12" font-weight="600" fill="#94a3b8">LÍMITE ESTABLECIDO: <tspan fill="#e2e8f0" font-weight="700">%s</tspan></text>

        <line x1="18" y1="106" x2="558" y2="106" stroke="#f59e0b" stroke-width="1" stroke-opacity="0.25"/>
        <text x="18" y="130" font-size="11" font-weight="600" fill="#94a3b8">UBICACIÓN: <tspan fill="#f1f5f9">%s</tspan> | PATRULLA: <tspan fill="#f1f5f9">%s</tspan></text>
      </g>

      <!-- Legal Notice -->
      <g transform="translate(32, 375)">
        <rect width="576" height="150" rx="8" fill="#0d1219" stroke="#192230" stroke-width="1"/>
        <text x="18" y="24" font-size="10.5" font-weight="800" fill="#94a3b8" letter-spacing="1">NOTIFICACIÓN OFICIAL DE TRÁFICO</text>
        
        <circle cx="24" cy="48" r="2.5" fill="#f59e0b"/>
        <text x="34" y="52" font-size="11.5" font-weight="500" fill="#cbd5e1">Medición realizada por cinemómetro láser calibrado y en servicio activo.</text>

        <circle cx="24" cy="74" r="2.5" fill="#f59e0b"/>
        <text x="34" y="78" font-size="11.5" font-weight="500" fill="#cbd5e1">Captura automática de placa de matrícula y registro cronológico de paso.</text>

        <circle cx="24" cy="100" r="2.5" fill="#f59e0b"/>
        <text x="34" y="104" font-size="11.5" font-weight="500" fill="#cbd5e1">Infracción calificada según el Reglamento General de Circulación de San Andreas.</text>
      </g>
        ]], plate, speed, limit, street, patrol)

    else
        -- Combined / Multi-evidence Laboratory Report
        title = "INFORME PERICIAL DE LABORATORIO"
        subtitle = "ANÁLISIS FORENSE INTEGRAL DE EVIDENCIAS"
        local list = (type(data.list) == "table") and data.list or {}
        local displayList = {}
        for idx = 1, math.min(#list, 4) do
            table.insert(displayList, list[idx])
        end
        if #displayList == 0 then
            table.insert(displayList, { type = "Indicio", description = data.description or "Muestra procesada en laboratorio central" })
        end

        local itemsSvg = ""
        for idx, ev in ipairs(displayList) do
            local y = (idx - 1) * 64
            local typeLabel, rawDesc = FormatEvidenceItem(ev)
            local itemType = EscapeXml(typeLabel)
            local desc = EscapeXml(rawDesc)
            if #desc > 68 then desc = string.sub(desc, 1, 65) .. "..." end
            itemsSvg = itemsSvg .. string.format([[
        <g transform="translate(18, %d)">
          <rect width="540" height="54" rx="6" fill="#10151f" stroke="#222d3d" stroke-width="1"/>
          <circle cx="20" cy="27" r="4" fill="#3b82f6"/>
          <text x="34" y="24" font-size="11.5" font-weight="800" fill="#60a5fa">%s</text>
          <text x="34" y="42" font-size="10.5" font-weight="500" fill="#cbd5e1">%s</text>
          <text x="526" y="32" font-family="monospace" font-size="10" font-weight="700" fill="#64748b" text-anchor="end">ITEM #%d</text>
        </g>
            ]], 32 + y, itemType, desc, idx)
        end

        local boxHeight = 44 + (#displayList * 64)
        local dictamenY = 210 + boxHeight + 12
        local dictamenHeight = math.min(104, math.max(60, 638 - dictamenY - 10))
        resultSection = string.format([[
      <g transform="translate(32, 210)">
        <rect width="576" height="%d" rx="10" fill="#0d1219" stroke="#1d2635" stroke-width="1.8"/>
        <text x="18" y="24" font-size="10.5" font-weight="800" fill="#94a3b8" letter-spacing="1">EVIDENCIAS PROCESADAS (%d)</text>
        %s
      </g>

      <g transform="translate(32, %d)">
        <rect width="576" height="%d" rx="8" fill="#10151f" stroke="#1d2635" stroke-width="1"/>
        <text x="18" y="24" font-size="10.5" font-weight="800" fill="#94a3b8" letter-spacing="1">DICTAMEN PERICIAL CONJUNTO</text>
        <circle cx="24" cy="48" r="2.5" fill="#3b82f6"/>
        <text x="34" y="52" font-size="11.5" font-weight="500" fill="#cbd5e1">Conjunto de indicios cotejados y autenticados según protocolo de criminalística.</text>
        <circle cx="24" cy="74" r="2.5" fill="#3b82f6"/>
        <text x="34" y="78" font-size="11.5" font-weight="500" fill="#cbd5e1">Informe expedido para su vinculación directa en el registro central de informes (MDT).</text>
      </g>
        ]], boxHeight, #displayList, itemsSvg, dictamenY, dictamenHeight)
    end

    local svgTemplate = string.format([[<svg xmlns="http://www.w3.org/2000/svg" width="640" height="820" viewBox="0 0 640 820" style="font-family:system-ui,-apple-system,sans-serif;">
  <defs>
    <linearGradient id="topStripe" x1="0%%" y1="0%%" x2="100%%" y2="0%%">
      <stop offset="0%%" stop-color="#1e3a8a"/>
      <stop offset="50%%" stop-color="#2563eb"/>
      <stop offset="100%%" stop-color="#3b82f6"/>
    </linearGradient>
    <linearGradient id="cardBg" x1="0%%" y1="0%%" x2="0%%" y2="100%%">
      <stop offset="0%%" stop-color="#0f141c"/>
      <stop offset="100%%" stop-color="#090d13"/>
    </linearGradient>
  </defs>

  <!-- Background Frame -->
  <rect width="640" height="820" rx="14" fill="#070a0e"/>
  <rect x="10" y="10" width="620" height="800" rx="12" fill="url(#cardBg)" stroke="#1a2332" stroke-width="1.5"/>
  <rect x="12" y="12" width="616" height="5" rx="2.5" fill="url(#topStripe)"/>

  <!-- Shield Emblem -->
  <g transform="translate(32, 34)">
    <path d="M 20 2 L 38 10 L 38 23 C 38 35 20 44 20 44 C 20 44 2 35 2 23 L 2 10 Z" fill="#1e3a8a" stroke="#60a5fa" stroke-width="1.8"/>
    <polygon points="20,11 22.5,18 30,18 24,22.5 26,30 20,25.5 14,30 16,22.5 10,18 17.5,18" fill="#facc15"/>
  </g>

  <!-- Police Department Header -->
  <text x="86" y="52" font-size="16" font-weight="900" fill="#f8fafc" letter-spacing="1.5">SAN ANDREAS POLICE DEPARTMENT</text>
  <text x="86" y="70" font-size="10.5" font-weight="700" fill="#94a3b8" letter-spacing="1.1">DIVISIÓN DE POLICÍA CIENTÍFICA Y FORENSE</text>
  <text x="86" y="85" font-size="9" font-weight="600" fill="#64748b" letter-spacing="0.8">DEPARTAMENTO DE BALÍSTICA E IDENTIFICACIÓN</text>

  <line x1="32" y1="99" x2="608" y2="99" stroke="#1e2736" stroke-width="1.2"/>

  <!-- Title & Subtitle -->
  <text x="320" y="126" font-size="15" font-weight="800" fill="#60a5fa" text-anchor="middle" letter-spacing="0.8">%s</text>
  <text x="320" y="143" font-size="10.5" font-weight="600" fill="#64748b" text-anchor="middle" letter-spacing="0.6">%s</text>

  <!-- Serial & Date Bar -->
  <rect x="32" y="157" width="576" height="38" rx="6" fill="#121824" stroke="#202a3a" stroke-width="1"/>
  <text x="46" y="181" font-family="monospace" font-size="11" font-weight="700" fill="#94a3b8">EXPEDIENTE: <tspan fill="#f1f5f9">%s</tspan></text>
  <text x="594" y="181" font-family="monospace" font-size="11" font-weight="700" fill="#94a3b8" text-anchor="end">FECHA: <tspan fill="#f1f5f9">%s</tspan></text>

  <!-- Dynamic Result Content -->
  %s

  <!-- Footer Seal and Certification -->
  <g transform="translate(32, 638)">
    <rect width="576" height="136" rx="8" fill="#0a0e14" stroke="#161e2b" stroke-width="1"/>
    
    <!-- Stamp Seal -->
    <g transform="translate(56, 68)">
      <circle r="42" fill="none" stroke="#2563eb" stroke-width="1.8" stroke-dasharray="4,2"/>
      <circle r="34" fill="none" stroke="#2563eb" stroke-width="0.9"/>
      <text y="-7" font-size="8" font-weight="800" fill="#3b82f6" text-anchor="middle" letter-spacing="1.2">SAN ANDREAS</text>
      <text y="6" font-size="10" font-weight="900" fill="#60a5fa" text-anchor="middle" letter-spacing="0.8">FORENSE</text>
      <text y="17" font-size="7" font-weight="700" fill="#3b82f6" text-anchor="middle" letter-spacing="1">OFICIAL</text>
    </g>

    <g transform="translate(118, 30)">
      <text x="0" y="0" font-size="11.5" font-weight="800" fill="#e2e8f0" letter-spacing="0.6">CERTIFICACIÓN PERICIAL POLICIAL</text>
      <text x="0" y="17" font-family="monospace" font-size="9.5" font-weight="600" fill="#64748b">FIRMA ELECTRÓNICA: SHA256-%s</text>
      
      <text x="0" y="40" font-size="10" font-weight="500" fill="#94a3b8">
        Documento oficial emitido conforme a la normativa policial del Estado de San Andreas.
      </text>
      <text x="0" y="55" font-size="10" font-weight="500" fill="#94a3b8">
        Válido como prueba documental y pericial en atestados e informes policiales.
      </text>
    </g>

    <!-- Barcode simulation -->
    <g transform="translate(18, 112)">
      <rect x="0" y="0" width="3" height="14" fill="#334155"/>
      <rect x="6" y="0" width="1" height="14" fill="#334155"/>
      <rect x="10" y="0" width="2" height="14" fill="#334155"/>
      <rect x="15" y="0" width="1" height="14" fill="#334155"/>
      <rect x="18" y="0" width="3" height="14" fill="#334155"/>
      <rect x="24" y="0" width="2" height="14" fill="#334155"/>
      <rect x="29" y="0" width="1" height="14" fill="#334155"/>
      <rect x="33" y="0" width="2" height="14" fill="#334155"/>
      <rect x="38" y="0" width="1" height="14" fill="#334155"/>
      <rect x="42" y="0" width="3" height="14" fill="#334155"/>
      <rect x="48" y="0" width="2" height="14" fill="#334155"/>
      <rect x="53" y="0" width="1" height="14" fill="#334155"/>
      <rect x="58" y="0" width="3" height="14" fill="#334155"/>
      <rect x="64" y="0" width="2" height="14" fill="#334155"/>
      <rect x="69" y="0" width="1" height="14" fill="#334155"/>
      <rect x="73" y="0" width="3" height="14" fill="#334155"/>
      <rect x="79" y="0" width="1" height="14" fill="#334155"/>
      <rect x="83" y="0" width="2" height="14" fill="#334155"/>
      <rect x="88" y="0" width="3" height="14" fill="#334155"/>
      <rect x="94" y="0" width="1" height="14" fill="#334155"/>
      <rect x="98" y="0" width="2" height="14" fill="#334155"/>
      <rect x="103" y="0" width="3" height="14" fill="#334155"/>
      <rect x="110" y="0" width="1" height="14" fill="#334155"/>
      <rect x="114" y="0" width="2" height="14" fill="#334155"/>
      <rect x="120" y="0" width="3" height="14" fill="#334155"/>
      <rect x="126" y="0" width="1" height="14" fill="#334155"/>
      <rect x="130" y="0" width="2" height="14" fill="#334155"/>
      <rect x="135" y="0" width="3" height="14" fill="#334155"/>
      <rect x="141" y="0" width="1" height="14" fill="#334155"/>
      <rect x="145" y="0" width="2" height="14" fill="#334155"/>
      <rect x="150" y="0" width="3" height="14" fill="#334155"/>
      <rect x="156" y="0" width="1" height="14" fill="#334155"/>
      <rect x="160" y="0" width="2" height="14" fill="#334155"/>
      <rect x="165" y="0" width="3" height="14" fill="#334155"/>
      <rect x="171" y="0" width="1" height="14" fill="#334155"/>
      <rect x="175" y="0" width="2" height="14" fill="#334155"/>
      <rect x="180" y="0" width="3" height="14" fill="#334155"/>
      <rect x="186" y="0" width="1" height="14" fill="#334155"/>
      <rect x="190" y="0" width="2" height="14" fill="#334155"/>
      <rect x="195" y="0" width="3" height="14" fill="#334155"/>
    </g>
  </g>

  <!-- Bottom Notice -->
  <text x="320" y="796" font-size="9.5" font-weight="700" fill="#475569" text-anchor="middle" letter-spacing="1.5">DOCUMENTO OFICIAL CONFIDENCIAL — USO EXCLUSIVO POLICIAL Y JUDICIAL</text>
</svg>]], title, subtitle, serie, dateStr, resultSection, string.upper(serie))

    return "data:image/svg+xml;base64," .. Base64Encode(svgTemplate)
end

exports("GenerateEvidenceDocumentSVG", GenerateEvidenceDocumentSVG)
