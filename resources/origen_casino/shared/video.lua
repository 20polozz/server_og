--[[ ══════════════════════════════════════════════════════════════════════════
     MÁQUINAS DE VÍDEO

     Cuatro juegos con pantalla, uno por máquina. El juego se pinta en la
     pantalla del mueble (client/video.lua) y lo deciden los motores de
     server/juegos/video/. Aquí están sus números: símbolos, pesos, pagos y
     bonos.

     Cada símbolo lleva una LETRA (`c`): la rejilla viaja al cliente como un
     texto de letras, columna a columna, de arriba abajo. Una tirada de bono
     de El Golpe son treinta rejillas de 49 casillas; en letras son unos
     pocos KB, en tablas serían diez veces más.

     ── La devolución ───────────────────────────────────────────────────────

     Los pagos de abajo salen de simular millones de tiradas
     (pruebas/video_rtp.py). Si se cambia un peso o un pago, hay que volver a
     pasar la simulación: en estos juegos la devolución no sale de una cuenta
     cerrada como en la tragaperras de tres rodillos, porque las cascadas y
     los multiplicadores encadenan unas tiradas con otras.
   ══════════════════════════════════════════════════════════════════════════ ]]

Config.Video = {}

--[[ Lo que tarda la pantalla en enseñar cada cosa, en milisegundos. Los usan
     la pantalla del mueble y el cliente de Lua, que con ellos sabe cuándo ha
     acabado de enseñarse una jugada (VideoDuracion, abajo) sin preguntárselo
     a la pantalla. Con «rápido» (Espacio mientras gira) todo va a un tercio. ]]
Config.Video.tiempos = {
    caida = 520, entreColumnas = 70,     -- la tirada entra columna a columna
    mostrar = 700, borrar = 320, relleno = 420,
    finTirada = 300,
    bonoIntro = 2200, respin = 750, final = 2200,
    granPremio = 2600, granDesde = 20,   -- el cartel de premio gordo, desde X veces la apuesta
}

--- Las apuestas que ofrecen todas (dentro del mínimo y máximo de cada juego).
Config.Video.fichas = { 50, 100, 200, 500, 1000, 2000, 5000 }

--[[ ── EL GOLPE ─────────────────────────────────────────────────────────────
     Rejilla de 7×7. Paga un GRUPO de 5 o más símbolos iguales que se tocan
     por un lado. Los que ganan se van, cae lo de arriba y se vuelve a mirar
     (cascada).

     Cada casilla que gana deja una MARCA; si vuelve a ganar ahí, la marca
     pasa a ×2, y luego se dobla cada vez (×4, ×8…, hasta el tope). Un grupo
     que gana encima de marcas multiplica por la SUMA de sus multiplicadores.
     En la tirada normal las marcas se borran al acabar; en las gratis se
     quedan hasta el final del bono.

     3 planos o más en cualquier sitio dan tiradas gratis. ]]
Config.Video.golpe = {
    ancho = 7, alto = 7, minGrupo = 5,
    simbolos = {
        { id = 'pistola',  c = 'A', nombre = 'Pistola',      peso = 20 },
        { id = 'mascara',  c = 'B', nombre = 'Pasamontañas', peso = 19 },
        { id = 'saco',     c = 'C', nombre = 'Saco',         peso = 17 },
        { id = 'fajo',     c = 'D', nombre = 'Fajo',         peso = 15 },
        { id = 'lingote',  c = 'E', nombre = 'Lingote',      peso = 12 },
        { id = 'reloj',    c = 'F', nombre = 'Reloj',        peso = 10 },
        { id = 'diamante', c = 'G', nombre = 'Diamante',     peso = 8 },
    },
    plano = { id = 'plano', c = 'S', nombre = 'Plano', peso = 0.7, pesoBono = 0.5 },
    --[[ En las gratis los símbolos baratos salen más: hay más grupos, más
         cascadas y las marcas crecen. Es lo que hace que el bono valga. ]]
    pesosBono = { pistola = 24, mascara = 22, saco = 18, fajo = 14, lingote = 10, reloj = 7, diamante = 5 },
    --- En las gratis la primera marca ya multiplica ×2.
    marcaBono = 2,
    --[[ Lo que paga un grupo, en veces la apuesta, según su tamaño. Cada
         fila son los tramos 5-6, 7-8, 9-10, 11-12, 13-14 y 15 o más. ]]
    tramos = { 5, 7, 9, 11, 13, 15 },
    pagos = {
        pistola  = { 0.42, 0.84, 2.1, 4.2, 8.4, 21 },
        mascara  = { 0.53, 1.05, 2.6, 5.3, 10.5, 26 },
        saco     = { 0.63, 1.32, 3.2, 6.3, 12.7, 32 },
        fajo     = { 0.84, 1.69, 4.2, 8.4, 16.9, 42 },
        lingote  = { 1.05, 2.1, 5.3, 10.5, 21, 63 },
        reloj    = { 1.58, 3.2, 8.4, 16.9, 32, 105 },
        diamante = { 2.1, 5.3, 12.7, 26, 53, 210 },
    },
    multTope = 128,
    --- Planos que hacen falta → tiradas gratis.
    gratis = { [3] = 10, [4] = 12, [5] = 15, [6] = 20, [7] = 30 },
    --- Comprar el bono: veces la apuesta.
    precioCompra = 100,
    --- Lo más que puede pagar una tirada con su bono, en veces la apuesta.
    topePremio = 5000,
}

--[[ ── VINEWOOD (clásica) ───────────────────────────────────────────────────
     Cinco rodillos, tres filas y 20 líneas fijas. Paga de izquierda a
     derecha, 3 o más iguales seguidos en una línea. El comodín sale solo en
     los rodillos 2, 3 y 4 y vale por cualquier símbolo menos la estrella.
     3 estrellas o más en cualquier sitio pagan solas y dan tiradas gratis en
     las que todo paga el triple. ]]
Config.Video.clasica = {
    ancho = 5, alto = 3,
    simbolos = {
        { id = 'cereza',  c = 'A', nombre = 'Cereza',  peso = 24 },
        { id = 'limon',   c = 'B', nombre = 'Limón',   peso = 22 },
        { id = 'uva',     c = 'C', nombre = 'Uvas',    peso = 20 },
        { id = 'campana', c = 'D', nombre = 'Campana', peso = 14 },
        { id = 'bar',     c = 'E', nombre = 'BAR',     peso = 10 },
        { id = 'siete',   c = 'F', nombre = 'Siete',   peso = 6 },
    },
    comodin = { id = 'comodin', c = 'W', nombre = 'Comodín', peso = 5 },
    estrella = { id = 'estrella', c = 'S', nombre = 'Estrella', peso = 2.8 },
    --- Paga por línea, en veces la apuesta POR LÍNEA, para 3, 4 y 5 iguales.
    pagos = {
        cereza  = { 5, 13, 50 },
        limon   = { 7, 16, 65 },
        uva     = { 8, 21, 80 },
        campana = { 13, 40, 160 },
        bar     = { 21, 65, 260 },
        siete   = { 40, 130, 650 },
    },
    --- Estrellas en cualquier sitio, en veces la apuesta TOTAL.
    pagoEstrellas = { [3] = 3, [4] = 13, [5] = 65 },
    gratis = { [3] = 10, [4] = 15, [5] = 20 },
    multGratis = 3,
    topePremio = 5000,
}

--[[ ── ATRAPA Y GANA ────────────────────────────────────────────────────────
     5×3 con 10 líneas sencillas. Las MONEDAS traen un premio pintado; con 6
     o más a la vez empieza el bono: las monedas se quedan fijas y hay 3
     tiradas; cada moneda nueva que cae devuelve el contador a 3. Al acabar se
     cobran todas. Llenar las 15 casillas suma el bote GRAND. ]]
Config.Video.atrapa = {
    ancho = 5, alto = 3,
    simbolos = {
        { id = 'herradura', c = 'A', nombre = 'Herradura', peso = 22 },
        { id = 'trebol',    c = 'B', nombre = 'Trébol',    peso = 20 },
        { id = 'dado',      c = 'C', nombre = 'Dado',      peso = 16 },
        { id = 'corona',    c = 'D', nombre = 'Corona',    peso = 10 },
    },
    moneda = { id = 'moneda', c = 'M', nombre = 'Moneda', peso = 10 },
    --- Paga por línea (10 líneas), en veces la apuesta por línea, para 3, 4 y 5.
    pagos = {
        herradura = { 3.8, 10.4, 33 },
        trebol    = { 5.7, 13.3, 38 },
        dado      = { 7.6, 19, 66 },
        corona    = { 13.3, 38, 135 },
    },
    --[[ Lo que puede traer una moneda, en veces la apuesta. Los botes MINI,
         MINOR y MAJOR son monedas con nombre. ]]
    valores = {
        { v = 1, peso = 30 }, { v = 2, peso = 24 }, { v = 3, peso = 16 }, { v = 5, peso = 11 },
        { v = 8, peso = 7 }, { v = 10, peso = 5 }, { v = 15, peso = 3 },
        { v = 25, peso = 1.6, bote = 'MINI' },
        { v = 50, peso = 0.7, bote = 'MINOR' },
        { v = 200, peso = 0.15, bote = 'MAJOR' },
    },
    minMonedas = 6,
    tiradas = 3,
    --- Probabilidad de que caiga moneda en cada casilla vacía en cada tirada del bono.
    pMoneda = 0.075,
    grand = 1000,
    topePremio = 5000,
}

--[[ ── FIEBRE (cascadas) ────────────────────────────────────────────────────
     6×5, sin líneas: paga tener 8 o más iguales en cualquier sitio. Los que
     ganan se van y cae lo de arriba. Cada cascada que vuelve a ganar sube el
     multiplicador de la tirada (×1, ×2, ×3, ×5…). En las tiradas gratis el
     multiplicador NO vuelve a ×1 entre tirada y tirada: va subiendo todo el
     bono. 4 caramelos o más dan las gratis. ]]
Config.Video.cascadas = {
    ancho = 6, alto = 5, minIguales = 8,
    simbolos = {
        { id = 'platano', c = 'A', nombre = 'Plátano', peso = 20 },
        { id = 'uva',     c = 'B', nombre = 'Uvas',    peso = 19 },
        { id = 'sandia',  c = 'C', nombre = 'Sandía',  peso = 18 },
        { id = 'ciruela', c = 'D', nombre = 'Ciruela', peso = 16 },
        { id = 'manzana', c = 'E', nombre = 'Manzana', peso = 14 },
        { id = 'azul',    c = 'F', nombre = 'Caramelo azul',  peso = 10 },
        { id = 'verde',   c = 'G', nombre = 'Caramelo verde', peso = 8 },
        { id = 'morado',  c = 'H', nombre = 'Caramelo morado', peso = 6 },
        { id = 'corazon', c = 'I', nombre = 'Corazón',  peso = 4 },
    },
    caramelo = { id = 'piruleta', c = 'S', nombre = 'Piruleta', peso = 2.0, pesoBono = 1.0 },
    --[[ En las gratis la fruta barata sale más y los caramelos menos: más
         cascadas seguidas, y el multiplicador sube más deprisa. ]]
    pesosBono = { platano = 24.2, uva = 22.2, sandia = 19.2, ciruela = 16, manzana = 12.8,
                  azul = 8.8, verde = 6.8, morado = 4.8, corazon = 2.9 },
    --- Veces la apuesta, para 8-9, 10-11 y 12 o más iguales.
    tramos = { 8, 10, 12 },
    pagos = {
        platano = { 0.24, 0.73, 1.96 },
        uva     = { 0.39, 0.88, 3.9 },
        sandia  = { 0.49, 0.98, 4.9 },
        ciruela = { 0.78, 1.18, 7.8 },
        manzana = { 0.98, 1.47, 9.8 },
        azul    = { 1.47, 1.96, 11.8 },
        verde   = { 1.96, 4.9, 14.7 },
        morado  = { 2.5, 9.8, 24 },
        corazon = { 9.8, 24, 49 },
    },
    --- El multiplicador de cada cascada que gana, en orden. Pasado el último se queda en él.
    escalera = { 1, 2, 3, 5, 8, 10, 15, 20, 25 },
    gratis = { [4] = 10, [5] = 12, [6] = 15 },
    masGratis = 5,          -- 3 piruletas en el bono
    precioCompra = 100,
    topePremio = 5000,
}

-- ══ Lo que comparten servidor, cliente y pantalla ═════════════════════════

--[[ La tabla de un juego para la pantalla: los símbolos con su letra, los
     pagos y los números del bono. Sin las cachés que los motores cuelgan de
     la configuración (`_porLetra`…). ]]
function VideoTabla(juego)
    local cfg = Config.Video[juego]
    if not cfg then return nil end
    local t = { juego = juego, simbolos = {}, pagos = cfg.pagos, tramos = cfg.tramos,
                ancho = cfg.ancho, alto = cfg.alto, tiempos = Config.Video.tiempos }
    for _, s in ipairs(cfg.simbolos) do
        t.simbolos[#t.simbolos + 1] = { id = s.id, c = s.c, nombre = s.nombre }
    end
    for _, clave in ipairs({ 'plano', 'comodin', 'estrella', 'moneda', 'caramelo' }) do
        local e = cfg[clave]
        if e then t.simbolos[#t.simbolos + 1] = { id = e.id, c = e.c, nombre = e.nombre, especial = clave } end
    end
    t.gratis, t.precioCompra, t.pagoEstrellas = cfg.gratis, cfg.precioCompra, cfg.pagoEstrellas
    t.multGratis, t.escalera, t.minMonedas, t.grand = cfg.multGratis, cfg.escalera, cfg.minMonedas, cfg.grand
    t.valores, t.topePremio, t.minGrupo, t.minIguales = cfg.valores, cfg.topePremio, cfg.minGrupo, cfg.minIguales
    return t
end

--[[ Cuánto tarda la pantalla en enseñar una jugada entera, con las mismas
     cuentas que hace ella (source-ui/src/pantalla/Pantalla.vue, `duracion`).
     Si se cambia una, se cambia la otra. ]]
function VideoDuracion(jugada)
    local T = Config.Video.tiempos
    local cfg = Config.Video[jugada.juego] or {}
    local ancho = cfg.ancho or 5
    local function Tirada(t)
        local ms = T.caida + T.entreColumnas * (ancho - 1) + T.finTirada
        for _ = 1, #(t.pasos or {}) do ms = ms + T.mostrar + T.borrar + T.relleno end
        return ms
    end
    local ms = 0
    if jugada.base then ms = ms + Tirada(jugada.base) end
    local b = jugada.bono
    if b then
        ms = ms + T.bonoIntro + T.final
        if b.tipo == 'monedas' then
            ms = ms + T.respin * #b.tiradas
        else
            for _, t in ipairs(b.tiradas) do ms = ms + Tirada(t) end
        end
    end
    if (jugada.premio or 0) >= (jugada.apuesta or 1) * T.granDesde then ms = ms + T.granPremio end
    return ms
end
