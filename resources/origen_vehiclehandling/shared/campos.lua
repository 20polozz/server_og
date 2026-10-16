--[[ Todos los valores de handling que se pueden tocar, en UN solo sitio.

     Lo leen el cliente (leer los de fabrica y ponerlos en el coche), el
     servidor (que solo se guarde lo que esta aqui) y la NUI (las casillas,
     sus textos y sus barras). Para añadir uno: una linea aqui y nada mas.

     key    nombre con el que se guarda. Los de antes (mass, maxSpeed...)
            conservan su nombre para que los coches ya guardados sigan igual.
     meta   el nombre del campo en el handling.meta y en los natives.
     clase  'CHandlingData' (todos) o 'CCarHandlingData' (solo coches; las
            motos, barcos y aviones no lo tienen y se salta sin error).
     tipo   'float', 'int', 'flags' (numero en hexadecimal) o 'vec' (un eje
            de un vector: va con `eje`).
     def    solo los de antes: valor si el guardado no lo trae. Los nuevos no
            llevan: sin valor = no se toca y el coche se queda con el suyo.
     min/max/paso  lo que recorre la barra (escribiendo se puede salir).
     es/en, ayuda_es/ayuda_en  lo que ve el que lo toca: dicho para que lo
            entienda cualquiera. ]]

HandlingGrupos = {
    { key = 'motor',      icono = 'gauge',     abierto = true,
      es = 'Motor y velocidad', en = 'Engine & speed',
      ayuda_es = 'Lo rápido que acelera y hasta dónde llega.', ayuda_en = 'How fast it accelerates and how far it goes.' },
    { key = 'frenos',     icono = 'disc',      abierto = true,
      es = 'Frenos y volante', en = 'Brakes & steering',
      ayuda_es = 'Cuánto frena y cuánto gira.', ayuda_en = 'How hard it brakes and how much it turns.' },
    { key = 'agarre',     icono = 'circleDot', abierto = true,
      es = 'Agarre de las ruedas', en = 'Tyre grip',
      ayuda_es = 'Si se pega al suelo o derrapa.', ayuda_en = 'Whether it sticks to the road or slides.' },
    { key = 'suspension', icono = 'waves',     abierto = true,
      es = 'Suspensión', en = 'Suspension',
      ayuda_es = 'Lo duro o blando que va y lo alto que está.', ayuda_en = 'How stiff or soft it is and how high it sits.' },
    { key = 'peso',       icono = 'weight',    abierto = false,
      es = 'Peso y aire', en = 'Weight & air',
      ayuda_es = 'Cuánto pesa, dónde tiene el peso y cómo le frena el aire.', ayuda_en = 'How heavy it is, where the weight sits and the air drag.' },
    { key = 'danos',      icono = 'shield',    abierto = false,
      es = 'Daños', en = 'Damage',
      ayuda_es = 'Cuánto se rompe. 1 = normal, 0 = nada, 2 = el doble.', ayuda_en = 'How much it breaks. 1 = normal, 0 = none, 2 = double.' },
    { key = 'ruedas',     icono = 'car',       abierto = false, avanzado = true,
      es = 'Ruedas y extras (solo coches)', en = 'Wheels & extras (cars only)',
      ayuda_es = 'Inclinación de las ruedas, saltos y empujones. Las motos, barcos y aviones no lo tienen.', ayuda_en = 'Wheel angles, jumps and ramming. Bikes, boats and planes do not have it.' },
    { key = 'otros',      icono = 'tag',       abierto = false, avanzado = true,
      es = 'Depósitos, asiento y precio', en = 'Tanks, seat & price',
      ayuda_es = 'Cosas que casi no cambian cómo conduce.', ayuda_en = 'Things that barely change how it drives.' },
    { key = 'banderas',   icono = 'alert',     abierto = false, avanzado = true,
      es = 'Banderas (solo si sabes)', en = 'Flags (experts only)',
      ayuda_es = 'Códigos en hexadecimal que encienden comportamientos raros. Si no sabes qué es, no lo toques.', ayuda_en = 'Hex codes that switch on special behaviours. If you do not know what this is, leave it.' },
}

HandlingCampos = {
    -- ── Motor y velocidad ───────────────────────────────────────────────
    { key = 'maxSpeed', meta = 'fInitialDriveMaxFlatVel', grupo = 'motor', def = 150.0, min = 0, max = 500, paso = 0.5,
      es = 'Velocidad punta', en = 'Top speed',
      ayuda_es = 'Hasta dónde llega. Más = corre más.', ayuda_en = 'How fast it can go. Higher = faster.' },
    { key = 'driveForce', meta = 'fInitialDriveForce', grupo = 'motor', def = 0.2, min = 0, max = 3, paso = 0.005,
      es = 'Aceleración (empuje)', en = 'Acceleration (drive force)',
      ayuda_es = 'La fuerza del motor. Más = sale disparado.', ayuda_en = 'Engine power. Higher = launches harder.' },
    { key = 'gears', meta = 'nInitialDriveGears', grupo = 'motor', tipo = 'int', min = 1, max = 10, paso = 1,
      es = 'Número de marchas', en = 'Number of gears',
      ayuda_es = 'Cuántas marchas tiene. Vacío = las de fábrica.', ayuda_en = 'How many gears. Empty = factory.' },
    { key = 'shiftSpeed', meta = 'fClutchChangeRateScaleUpShift', grupo = 'motor', def = 1.0, min = 0.1, max = 10, paso = 0.1,
      es = 'Rapidez al subir marcha', en = 'Upshift speed',
      ayuda_es = 'Lo que tarda en meter la siguiente. Más = más rápido.', ayuda_en = 'How quickly it shifts up. Higher = quicker.' },
    { key = 'shiftDown', meta = 'fClutchChangeRateScaleDownShift', grupo = 'motor', min = 0.1, max = 10, paso = 0.1,
      es = 'Rapidez al bajar marcha', en = 'Downshift speed',
      ayuda_es = 'Igual, pero al reducir. Vacío = igual que al subir.', ayuda_en = 'Same, when shifting down. Empty = same as upshift.' },
    { key = 'inertia', meta = 'fDriveInertia', grupo = 'motor', def = 1.0, min = 0.1, max = 3, paso = 0.01,
      es = 'Lo rápido que sube de vueltas', en = 'Rev speed (drive inertia)',
      ayuda_es = 'Más = el motor revoluciona más rápido.', ayuda_en = 'Higher = the engine revs up faster.' },
    { key = 'driveBias', meta = 'fDriveBiasFront', grupo = 'motor', def = 0.5, min = 0, max = 1, paso = 0.01,
      es = 'Qué ruedas empujan', en = 'Which wheels drive',
      ayuda_es = '0 = solo las de atrás, 1 = solo las de delante, 0.5 = 4x4.', ayuda_en = '0 = rear only, 1 = front only, 0.5 = AWD.' },

    -- ── Frenos y volante ────────────────────────────────────────────────
    { key = 'brakeForce', meta = 'fBrakeForce', grupo = 'frenos', def = 0.5, min = 0, max = 5, paso = 0.01,
      es = 'Fuerza de frenada', en = 'Brake force',
      ayuda_es = 'Más = para antes.', ayuda_en = 'Higher = stops sooner.' },
    { key = 'brakeBias', meta = 'fBrakeBiasFront', grupo = 'frenos', def = 0.5, min = 0, max = 1, paso = 0.01,
      es = 'Reparto de frenada', en = 'Brake balance',
      ayuda_es = 'Más = frena más con las de delante. Menos = con las de atrás (se cruza más).', ayuda_en = 'Higher = more front braking. Lower = more rear (spins easier).' },
    { key = 'handBrake', meta = 'fHandBrakeForce', grupo = 'frenos', min = 0, max = 5, paso = 0.01,
      es = 'Freno de mano', en = 'Handbrake force',
      ayuda_es = 'Más = el freno de mano bloquea más (para derrapar).', ayuda_en = 'Higher = stronger handbrake (for drifting).' },
    { key = 'steeringLock', meta = 'fSteeringLock', grupo = 'frenos', def = 40.0, min = 0, max = 90, paso = 0.5,
      es = 'Giro del volante', en = 'Steering angle',
      ayuda_es = 'Cuánto giran las ruedas. Más = gira más cerrado.', ayuda_en = 'How far the wheels turn. Higher = tighter turns.' },

    -- ── Agarre ──────────────────────────────────────────────────────────
    { key = 'tractionMax', meta = 'fTractionCurveMax', grupo = 'agarre', def = 2.5, min = 0, max = 5, paso = 0.01,
      es = 'Agarre en curva', en = 'Cornering grip',
      ayuda_es = 'El agarre normal. Más = va como sobre raíles.', ayuda_en = 'Normal grip. Higher = sticks like glue.' },
    { key = 'tractionMin', meta = 'fTractionCurveMin', grupo = 'agarre', def = 2.0, min = 0, max = 5, paso = 0.01,
      es = 'Agarre derrapando', en = 'Grip while sliding',
      ayuda_es = 'El agarre cuando ya patina. Más = recupera antes.', ayuda_en = 'Grip once sliding. Higher = recovers sooner.' },
    { key = 'tractionLateral', meta = 'fTractionCurveLateral', grupo = 'agarre', min = 0, max = 40, paso = 0.1,
      es = 'Cuándo empieza a derrapar', en = 'Slip angle',
      ayuda_es = 'Más = aguanta más antes de irse de lado.', ayuda_en = 'Higher = holds longer before sliding out.' },
    { key = 'tractionBias', meta = 'fTractionBiasFront', grupo = 'agarre', def = 0.5, min = 0, max = 1, paso = 0.01,
      es = 'Agarre delante o detrás', en = 'Grip balance',
      ayuda_es = 'Más = agarran más las de delante. Menos = se va de atrás (derrapa).', ayuda_en = 'Higher = more front grip. Lower = rear slides out.' },
    { key = 'tractionLoss', meta = 'fTractionLossMult', grupo = 'agarre', def = 1.0, min = 0, max = 3, paso = 0.01,
      es = 'Agarre fuera del asfalto', en = 'Off-road grip loss',
      ayuda_es = 'Más = resbala más en tierra y hierba.', ayuda_en = 'Higher = slides more on dirt and grass.' },
    { key = 'lowSpeedLoss', meta = 'fLowSpeedTractionLossMult', grupo = 'agarre', min = 0, max = 3, paso = 0.01,
      es = 'Patinar al arrancar', en = 'Wheelspin at low speed',
      ayuda_es = 'Más = quema rueda al salir. 0 = nada.', ayuda_en = 'Higher = more wheelspin at launch. 0 = none.' },
    { key = 'tractionSpring', meta = 'fTractionSpringDeltaMax', grupo = 'agarre', min = 0, max = 1, paso = 0.01,
      es = 'Margen antes de perder agarre', en = 'Traction spring',
      ayuda_es = 'Más = tarda más en perder el agarre.', ayuda_en = 'Higher = takes longer to lose grip.' },
    { key = 'camberStiffness', meta = 'fCamberStiffnesss', grupo = 'agarre', min = 0, max = 2, paso = 0.01,
      es = 'Agarre en peraltes', en = 'Camber stiffness',
      ayuda_es = 'Cuánto ayuda inclinarse en curva. Casi siempre 0.', ayuda_en = 'Grip gained from body lean. Usually 0.' },

    -- ── Suspensión ──────────────────────────────────────────────────────
    { key = 'suspensionForce', meta = 'fSuspensionForce', grupo = 'suspension', def = 2.0, min = 0, max = 10, paso = 0.05,
      es = 'Dureza', en = 'Stiffness',
      ayuda_es = 'Más = más dura, se inclina menos.', ayuda_en = 'Higher = stiffer, leans less.' },
    { key = 'suspensionComp', meta = 'fSuspensionCompDamp', grupo = 'suspension', def = 1.0, min = 0, max = 5, paso = 0.01,
      es = 'Amortiguación al bajar', en = 'Compression damping',
      ayuda_es = 'Más = se hunde más despacio en los baches.', ayuda_en = 'Higher = sinks slower over bumps.' },
    { key = 'suspensionRebound', meta = 'fSuspensionReboundDamp', grupo = 'suspension', def = 1.0, min = 0, max = 5, paso = 0.01,
      es = 'Amortiguación al subir', en = 'Rebound damping',
      ayuda_es = 'Más = rebota menos al soltar.', ayuda_en = 'Higher = bounces back less.' },
    { key = 'suspensionHeight', meta = 'fSuspensionUpperLimit', grupo = 'suspension', def = 0.0, min = -0.5, max = 0.5, paso = 0.005,
      es = 'Tope de arriba', en = 'Upper limit',
      ayuda_es = 'Hasta dónde puede subir la rueda.', ayuda_en = 'How far up the wheel can travel.' },
    { key = 'suspensionLowerLimit', meta = 'fSuspensionLowerLimit', grupo = 'suspension', def = -0.1, min = -0.5, max = 0.5, paso = 0.005,
      es = 'Tope de abajo', en = 'Lower limit',
      ayuda_es = 'Hasta dónde puede bajar la rueda.', ayuda_en = 'How far down the wheel can travel.' },
    { key = 'suspensionRaise', meta = 'fSuspensionRaise', grupo = 'suspension', min = -0.5, max = 0.5, paso = 0.005,
      es = 'Altura del coche', en = 'Ride height',
      ayuda_es = 'Más = más alto. Menos = más bajo (tumbado).', ayuda_en = 'Higher = taller. Lower = slammed.' },
    { key = 'suspensionBias', meta = 'fSuspensionBiasFront', grupo = 'suspension', min = 0, max = 1, paso = 0.01,
      es = 'Dureza delante o detrás', en = 'Stiffness balance',
      ayuda_es = 'Más = más dura delante. Menos = más dura detrás.', ayuda_en = 'Higher = stiffer front. Lower = stiffer rear.' },
    { key = 'antiRollBar', meta = 'fAntiRollBarForce', grupo = 'suspension', def = 0.5, min = 0, max = 3, paso = 0.01,
      es = 'Barra estabilizadora', en = 'Anti-roll bar',
      ayuda_es = 'Más = se inclina menos en curva.', ayuda_en = 'Higher = less body roll in corners.' },
    { key = 'antiRollBias', meta = 'fAntiRollBarBiasFront', grupo = 'suspension', min = 0, max = 1, paso = 0.01,
      es = 'Barra delante o detrás', en = 'Anti-roll balance',
      ayuda_es = 'Más = la barra trabaja más delante.', ayuda_en = 'Higher = more anti-roll at the front.' },
    { key = 'rollCentreFront', meta = 'fRollCentreHeightFront', grupo = 'suspension', def = 0.0, min = -0.5, max = 1, paso = 0.01,
      es = 'Balanceo delante', en = 'Roll centre front',
      ayuda_es = 'Más = se inclina menos delante (y puede volcar más).', ayuda_en = 'Higher = less front roll (may flip more).' },
    { key = 'rollCentreRear', meta = 'fRollCentreHeightRear', grupo = 'suspension', def = 0.0, min = -0.5, max = 1, paso = 0.01,
      es = 'Balanceo detrás', en = 'Roll centre rear',
      ayuda_es = 'Más = se inclina menos detrás (y puede volcar más).', ayuda_en = 'Higher = less rear roll (may flip more).' },

    -- ── Peso y aire ─────────────────────────────────────────────────────
    { key = 'mass', meta = 'fMass', grupo = 'peso', def = 1500.0, min = 50, max = 20000, paso = 10,
      es = 'Peso (kg)', en = 'Weight (kg)',
      ayuda_es = 'Más = más pesado: empuja a los demás pero acelera menos.', ayuda_en = 'Higher = heavier: pushes others but accelerates less.' },
    { key = 'dragCoeff', meta = 'fInitialDragCoeff', grupo = 'peso', def = 10.0, min = 0, max = 150, paso = 0.5,
      es = 'Resistencia del aire', en = 'Air drag',
      ayuda_es = 'Más = el aire lo frena más a mucha velocidad.', ayuda_en = 'Higher = more air braking at high speed.' },
    { key = 'downforce', meta = 'fDownforceModifier', grupo = 'peso', min = 0, max = 10, paso = 0.1,
      es = 'Pegado al suelo (alerón)', en = 'Downforce',
      ayuda_es = 'Más = se pega más al suelo cuanto más corre.', ayuda_en = 'Higher = more grip the faster it goes.' },
    { key = 'comX', meta = 'vecCentreOfMassOffset', tipo = 'vec', eje = 'x', grupo = 'peso', min = -2, max = 2, paso = 0.01,
      es = 'Centro del peso: a los lados', en = 'Centre of mass: sideways',
      ayuda_es = 'Mueve el peso a izquierda (-) o derecha (+). Casi siempre 0.', ayuda_en = 'Moves weight left (-) or right (+). Usually 0.' },
    { key = 'comY', meta = 'vecCentreOfMassOffset', tipo = 'vec', eje = 'y', grupo = 'peso', min = -2, max = 2, paso = 0.01,
      es = 'Centro del peso: delante/detrás', en = 'Centre of mass: front/back',
      ayuda_es = 'Más = el peso va delante. Menos = va detrás (levanta el morro).', ayuda_en = 'Higher = weight forward. Lower = weight back (wheelies).' },
    { key = 'comZ', meta = 'vecCentreOfMassOffset', tipo = 'vec', eje = 'z', grupo = 'peso', min = -2, max = 2, paso = 0.01,
      es = 'Centro del peso: altura', en = 'Centre of mass: height',
      ayuda_es = 'Menos = más bajo, vuelca menos. Más = vuelca más.', ayuda_en = 'Lower = less likely to flip. Higher = flips more.' },
    { key = 'inertiaX', meta = 'vecInertiaMultiplier', tipo = 'vec', eje = 'x', grupo = 'peso', min = 0, max = 3, paso = 0.05,
      es = 'Resistencia a cabecear', en = 'Pitch inertia',
      ayuda_es = 'Más = le cuesta más levantar o bajar el morro.', ayuda_en = 'Higher = harder to pitch nose up or down.' },
    { key = 'inertiaY', meta = 'vecInertiaMultiplier', tipo = 'vec', eje = 'y', grupo = 'peso', min = 0, max = 3, paso = 0.05,
      es = 'Resistencia a volcar', en = 'Roll inertia',
      ayuda_es = 'Más = le cuesta más inclinarse de lado.', ayuda_en = 'Higher = harder to roll sideways.' },
    { key = 'inertiaZ', meta = 'vecInertiaMultiplier', tipo = 'vec', eje = 'z', grupo = 'peso', min = 0, max = 3, paso = 0.05,
      es = 'Resistencia a girar sobre sí', en = 'Yaw inertia',
      ayuda_es = 'Más = le cuesta más hacer un trompo.', ayuda_en = 'Higher = harder to spin around.' },
    { key = 'percentSubmerged', meta = 'fPercentSubmerged', grupo = 'peso', min = 0, max = 100, paso = 1,
      es = 'Cuánto se hunde en el agua (%)', en = 'Percent submerged',
      ayuda_es = 'Más = se hunde más antes de flotar.', ayuda_en = 'Higher = sinks deeper before floating.' },

    -- ── Daños ───────────────────────────────────────────────────────────
    { key = 'collisionMult', meta = 'fCollisionDamageMult', grupo = 'danos', def = 1.0, min = 0, max = 5, paso = 0.05,
      es = 'Daño por choques', en = 'Collision damage',
      ayuda_es = 'Cuánta vida pierde al chocar.', ayuda_en = 'How much health it loses when crashing.' },
    { key = 'weaponMult', meta = 'fWeaponDamageMult', grupo = 'danos', min = 0, max = 5, paso = 0.05,
      es = 'Daño por disparos', en = 'Weapon damage',
      ayuda_es = 'Cuánta vida pierde con balas y explosiones.', ayuda_en = 'How much health it loses to bullets and blasts.' },
    { key = 'engineMult', meta = 'fEngineDamageMult', grupo = 'danos', def = 1.0, min = 0, max = 5, paso = 0.05,
      es = 'Daño del motor', en = 'Engine damage',
      ayuda_es = 'Lo rápido que se rompe el motor.', ayuda_en = 'How quickly the engine breaks.' },
    { key = 'deformationMult', meta = 'fDeformationDamageMult', grupo = 'danos', def = 1.0, min = 0, max = 5, paso = 0.05,
      es = 'Abolladuras', en = 'Body deformation',
      ayuda_es = 'Cuánto se abolla la chapa. 0 = nunca.', ayuda_en = 'How much the body dents. 0 = never.' },

    -- ── Ruedas y extras (CCarHandlingData) ──────────────────────────────
    { key = 'toeFront', meta = 'fToeFront', clase = 'CCarHandlingData', grupo = 'ruedas', min = -5, max = 5, paso = 0.05,
      es = 'Convergencia delante', en = 'Front toe',
      ayuda_es = 'Ruedas de delante mirando hacia dentro (+) o fuera (-).', ayuda_en = 'Front wheels pointing in (+) or out (-).' },
    { key = 'toeRear', meta = 'fToeRear', clase = 'CCarHandlingData', grupo = 'ruedas', min = -5, max = 5, paso = 0.05,
      es = 'Convergencia detrás', en = 'Rear toe',
      ayuda_es = 'Ruedas de detrás mirando hacia dentro (+) o fuera (-).', ayuda_en = 'Rear wheels pointing in (+) or out (-).' },
    { key = 'camberFront', meta = 'fCamberFront', clase = 'CCarHandlingData', grupo = 'ruedas', min = -10, max = 10, paso = 0.05,
      es = 'Inclinación ruedas delante', en = 'Front camber',
      ayuda_es = 'Ruedas de delante tumbadas (estilo stance).', ayuda_en = 'Front wheels tilted (stance look).' },
    { key = 'camberRear', meta = 'fCamberRear', clase = 'CCarHandlingData', grupo = 'ruedas', min = -10, max = 10, paso = 0.05,
      es = 'Inclinación ruedas detrás', en = 'Rear camber',
      ayuda_es = 'Ruedas de detrás tumbadas (estilo stance).', ayuda_en = 'Rear wheels tilted (stance look).' },
    { key = 'castor', meta = 'fCastor', clase = 'CCarHandlingData', grupo = 'ruedas', min = -10, max = 10, paso = 0.05,
      es = 'Avance (castor)', en = 'Castor',
      ayuda_es = 'Cómo vuelve el volante al centro. Casi siempre 0.', ayuda_en = 'How the steering self-centres. Usually 0.' },
    { key = 'engineResistance', meta = 'fEngineResistance', clase = 'CCarHandlingData', grupo = 'ruedas', min = 0, max = 5, paso = 0.05,
      es = 'Freno motor', en = 'Engine braking',
      ayuda_es = 'Más = frena más al soltar el acelerador.', ayuda_en = 'Higher = slows more when you lift off.' },
    { key = 'maxDriveBiasTransfer', meta = 'fMaxDriveBiasTransfer', clase = 'CCarHandlingData', grupo = 'ruedas', min = -1, max = 1, paso = 0.01,
      es = 'Reparto de empuje automático', en = 'Max drive bias transfer',
      ayuda_es = 'Cuánto pasa la fuerza de un eje a otro cuando patina. -1 = nada.', ayuda_en = 'How much power moves between axles on wheelspin. -1 = off.' },
    { key = 'jumpForce', meta = 'fJumpForceScale', clase = 'CCarHandlingData', grupo = 'ruedas', min = 0, max = 5, paso = 0.05,
      es = 'Fuerza de salto', en = 'Jump force',
      ayuda_es = 'Solo coches que saltan (como el Ruiner 2000).', ayuda_en = 'Only for cars that can jump.' },
    { key = 'rammingForce', meta = 'fIncreasedRammingForceScale', clase = 'CCarHandlingData', grupo = 'ruedas', min = 0, max = 5, paso = 0.05,
      es = 'Fuerza al embestir', en = 'Ramming force',
      ayuda_es = 'Más = empuja más fuerte a lo que golpea.', ayuda_en = 'Higher = shoves harder when ramming.' },
    { key = 'popUpCar', meta = 'fBackEndPopUpCarImpulseMult', clase = 'CCarHandlingData', grupo = 'ruedas', min = 0, max = 5, paso = 0.05,
      es = 'Rebote de la cola contra coches', en = 'Rear pop-up (cars)',
      ayuda_es = 'Cuánto se levanta la cola al chocar contra un coche.', ayuda_en = 'How much the rear lifts when hitting a car.' },
    { key = 'popUpBuilding', meta = 'fBackEndPopUpBuildingImpulseMult', clase = 'CCarHandlingData', grupo = 'ruedas', min = 0, max = 5, paso = 0.05,
      es = 'Rebote de la cola contra muros', en = 'Rear pop-up (walls)',
      ayuda_es = 'Cuánto se levanta la cola al chocar contra un muro.', ayuda_en = 'How much the rear lifts when hitting a wall.' },
    { key = 'popUpMaxDelta', meta = 'fBackEndPopUpMaxDeltaSpeed', clase = 'CCarHandlingData', grupo = 'ruedas', min = 0, max = 20, paso = 0.1,
      es = 'Tope del rebote de la cola', en = 'Rear pop-up max speed',
      ayuda_es = 'Velocidad máxima a la que pasa el rebote.', ayuda_en = 'Highest speed at which the pop-up happens.' },

    -- ── Depósitos, asiento y precio ─────────────────────────────────────
    { key = 'petrolTank', meta = 'fPetrolTankVolume', grupo = 'otros', min = 0, max = 200, paso = 1,
      es = 'Depósito de gasolina', en = 'Fuel tank',
      ayuda_es = 'Litros del depósito del juego (el sistema de gasolina puede ir aparte).', ayuda_en = 'Game fuel tank litres (fuel scripts may ignore it).' },
    { key = 'oilVolume', meta = 'fOilVolume', grupo = 'otros', min = 0, max = 20, paso = 0.1,
      es = 'Aceite', en = 'Oil volume',
      ayuda_es = 'Aceite del motor del juego.', ayuda_en = 'Game engine oil.' },
    { key = 'seatX', meta = 'fSeatOffsetDistX', grupo = 'otros', min = -1, max = 1, paso = 0.01,
      es = 'Asiento: a los lados', en = 'Seat offset X',
      ayuda_es = 'Mueve al conductor a izquierda o derecha.', ayuda_en = 'Moves the driver left or right.' },
    { key = 'seatY', meta = 'fSeatOffsetDistY', grupo = 'otros', min = -1, max = 1, paso = 0.01,
      es = 'Asiento: delante/detrás', en = 'Seat offset Y',
      ayuda_es = 'Mueve al conductor hacia delante o atrás.', ayuda_en = 'Moves the driver forward or back.' },
    { key = 'seatZ', meta = 'fSeatOffsetDistZ', grupo = 'otros', min = -1, max = 1, paso = 0.01,
      es = 'Asiento: altura', en = 'Seat offset Z',
      ayuda_es = 'Sube o baja al conductor.', ayuda_en = 'Moves the driver up or down.' },
    { key = 'monetaryValue', meta = 'nMonetaryValue', tipo = 'int', grupo = 'otros', min = 0, max = 2000000, paso = 1000,
      es = 'Valor del coche (juego)', en = 'Monetary value',
      ayuda_es = 'Lo que vale para el juego (seguros, NPC). No es el precio de la tienda.', ayuda_en = 'Game value (insurance, NPCs). Not the shop price.' },

    -- ── Banderas ────────────────────────────────────────────────────────
    { key = 'modelFlags', meta = 'strModelFlags', tipo = 'flags', grupo = 'banderas',
      es = 'Banderas del modelo', en = 'Model flags',
      ayuda_es = 'strModelFlags del handling.meta, en hexadecimal.', ayuda_en = 'strModelFlags from handling.meta, in hex.' },
    { key = 'handlingFlags', meta = 'strHandlingFlags', tipo = 'flags', grupo = 'banderas',
      es = 'Banderas de conducción', en = 'Handling flags',
      ayuda_es = 'strHandlingFlags del handling.meta, en hexadecimal.', ayuda_en = 'strHandlingFlags from handling.meta, in hex.' },
    { key = 'damageFlags', meta = 'strDamageFlags', tipo = 'flags', grupo = 'banderas',
      es = 'Banderas de daño', en = 'Damage flags',
      ayuda_es = 'strDamageFlags del handling.meta, en hexadecimal.', ayuda_en = 'strDamageFlags from handling.meta, in hex.' },
    { key = 'advancedFlags', meta = 'strAdvancedFlags', clase = 'CCarHandlingData', tipo = 'flags', grupo = 'banderas',
      es = 'Banderas avanzadas (solo coches)', en = 'Advanced flags (cars only)',
      ayuda_es = 'strAdvancedFlags de CCarHandlingData, en hexadecimal.', ayuda_en = 'strAdvancedFlags from CCarHandlingData, in hex.' },
}

for _, campo in ipairs(HandlingCampos) do
    campo.clase = campo.clase or 'CHandlingData'
    campo.tipo = campo.tipo or 'float'
end

--- Un valor que llega de fuera (guardado, NUI, config) puesto en limpio.
--- Devuelve nil si no vale: entonces se usa `def` o no se toca.
function HandlingLimpiarValor(campo, valor)
    local n = tonumber(valor)
    if not n or n ~= n or n == math.huge or n == -math.huge then return nil end
    if campo.key == 'gears' then
        n = math.floor(n + 0.5)
        if n < 1 or n > 10 then return nil end
        return n
    end
    if campo.tipo == 'int' or campo.tipo == 'flags' then
        n = math.floor(n)
        if campo.tipo == 'flags' and (n < 0 or n > 4294967295.0) then return nil end
        return n
    end
    return n + 0.0
end

--- Deja solo los valores del catalogo, limpios; los de antes con su `def`.
function HandlingNormalizar(datos)
    local limpio = {}
    datos = type(datos) == 'table' and datos or {}
    for _, campo in ipairs(HandlingCampos) do
        local v = HandlingLimpiarValor(campo, datos[campo.key])
        if v == nil and campo.def ~= nil then v = campo.def end
        limpio[campo.key] = v
    end
    return limpio
end
