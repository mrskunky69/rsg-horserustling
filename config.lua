Config = {}

Config.HorseModels = {
    "A_C_Horse_AmericanPaint_Greyovero",
    "A_C_Horse_AmericanStandardbred_Palominodapple",
    "A_C_Horse_Andalusian_DarkBay",
    "A_C_Horse_Appaloosa_LeopardBlanket",
    "A_C_Horse_Arabian_White",
    "A_C_Horse_Ardennes_IronGreyRoan",
    "A_C_Horse_Kentucky_ChestnutPinto",
    "A_C_Horse_Shire_LightGrey",
    "A_C_Horse_SuffolkPunch_RedChestnut",
    "A_C_Horse_TennesseeWalker_FlaxenRoan"
}

-- Cow spawn settings
Config.horseSpawnLocation = vector3(-1666.76, -1445.34, 84.69)
Config.horseSpawnHeading = 180.0 -- Facing South
Config.NumberOfhorse = 4
---Config.horseModel = "a_c_horse_americanpaint_overo"
Config.horseBlipSprite = GetHashKey("blip_ambient_ped_medium")  -- You may need to find the appropriate sprite hash for a cow blip
Config.horseBlipText = "Rustled"

-- Bandit spawn settings
Config.BanditSpawnLocation = vector3(-1668.71, -1428.27, 84.90 -1)
Config.BanditSpawnHeading = 270.0 -- Facing West
Config.NumberOfBandits = 3
Config.BanditModel = "g_m_m_uniranchers_01"
Config.HorseModel = "a_c_horse_kentuckysaddle_black"

-- Selling settings
Config.SellNPCLocation = vector3(-374.39, -341.21, 87.58)
Config.SellNPCModel = "u_m_m_valbutcher_01"
Config.SellNPCHeading = 0.0 -- Facing North
Config.SellingRadius = 5.0
Config.PricePerhorse = 50
Config.MissionTriggerRadius = 50.0
Config.horseSellDistance = 10.0 

Config.AddGPSRoute = true


Config.SellPointBlip = {
    name = 'auction yard',
    sprite = 423351566,
    x = -373.57,
    y = -343.24,
    z = 87.28
}



Config.BanditAggroRadius = 20.0  -- Distance at which bandits become aggressive
Config.BanditAttackInterval = 5000  -- Time in ms between bandit attacks


Config.PoliceJobName = "leo"


Config.MissionResetTime = 60