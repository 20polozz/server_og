Config = {}

-- Intensidad visual del spray (efecto de partículas)
Config.Intensity = 5.0

-- Tiempo máximo de disparo continuo en segundos
Config.TimeUntilReload = 5.0

-- Rango de alcance del spray en metros
Config.SprayRange = 2.5

-- Tiempo en segundos que dura el efecto en el objetivo (pantalla distorsionada + suelo)
Config.SprayEffectTime = 10

-- Trabajo requerido para usar el comando /pepperspray
-- Pon false o nil si deseas permitir que cualquier jugador use el comando (modo standalone)
Config.RequiredJob = nil

-- ¿Debe el objetivo caer al suelo (ragdoll)?
Config.RagdollTarget = true

-- ¿Debe el objetivo reproducir una animación de tos/asfixia?
Config.PlayCoughAnimation = false
