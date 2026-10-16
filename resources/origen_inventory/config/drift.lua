Config = Config or {}

Config.EnableDriftMode = false
Config.DriftHandling = {
    -- Initial drag coefficient: Influences the aerodynamic resistance of the vehicle.
    InitialDragCoeff = 90.22,
    
    -- Driving inertia: Affects the acceleration of the vehicle. Higher values ​​make the car accelerate more slowly.
    DriveInertia = 0.31,
    
    -- Steering lock: Defines the maximum angle at which the front wheels can turn. Higher values ​​allow tighter turns.
    SteeringLock = 22,
    
    -- Maximum cornering traction: Controls the maximum amount of grip the vehicle has when cornering at high speeds. Negative values ​​indicate that it is a special value in this context.
    TractionCurveMax = -1.1,
    
    -- Minimum cornering traction: Controls the minimum amount of grip the vehicle has when cornering at low speeds. Also in negative values ​​here.
    TractionCurveMin = -0.4,
    
    -- Lateral traction in curves: It influences how the vehicle behaves laterally in curves, that is, its lateral stability.
    TractionCurveLateral = 2.5,
    
    -- Low Speed ​​Traction Loss Multiplier: Affects how much the vehicle loses grip at low speeds. Negative values ​​in this context indicate a specific setting.
    LowSpeedTractionLossMult = -0.57
}