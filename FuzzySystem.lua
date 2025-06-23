---@enum SensorCategories
local SensorCategories = {
  near = 1,
  medium = 2,
  far = 3,
  one = 4
}
local nOfSensorCategories = 4

---@enum DeltaCategories
local DeltaCategories = {
  negative = 1,
  zero = 2,
  positive = 3,
  one = 4
}
local nOfDeltaCategories = 4

---@enum SensorNames
local SensorNames = {
  sensor1 = 1,
  sensor2 = 2,
  sensor3 = 3,
  sensor4 = 4,
  sensor5 = 5,
}

---@enum DeltaNames
local DeltaNames = {
  deltaX = 1,
  deltaY = 2,
  deltaZ = 3,
}

---@class Rule
---@field sensorRules table<SensorNames, SensorCategories>
---@field deltaRules table<DeltaNames, DeltaCategories>
---@field linearVelocity number
---@field angularVelocity number

---@class DeltaParameters
---@field zeroStdev number
---@field sigmoidShift number
---@field sigmoidSteepness number

---@class SensorParameters
---@field nearStdev number
---@field mediumMean number
---@field mediumStdev number
---@field farShift number
---@field farSteepness number

---@class Chromossome
---@field sensorParameters SensorParameters
---@field deltaParameters DeltaParameters
---@field rules Rule[]

---@alias MembershipFunction fun(x: number): number

---@class Index
---@field getOutputs fun(self: FuzzySystem, inputs: Inputs):number, number

---@class FuzzySystem : Index
---@field chromossome Chromossome
---@field deltaMembershipFunctions table<DeltaCategories, MembershipFunction>
---@field sensorMembershipFunctions table<SensorCategories, MembershipFunction>

---@class Inputs
---@field sensorInputs table<SensorNames, number>
---@field deltaInputs table<DeltaNames, number>

---@class Outputs
---@field linearVelocity number
---@field angularVelocity number

---@return MembershipFunction
local function getGaussian(mean, stdev)
  ---@type MembershipFunction
  local function f(x)
    return math.exp(-(x - mean) ^ 2 / stdev ^ 2)
  end
  return f
end

---@return MembershipFunction
local function getSigmoid(steepness, shift)
  ---@type MembershipFunction
  local function f(x)
    return 1 / (1 + math.exp(-steepness * (x - shift)))
  end
  return f
end

---@return SensorParameters
local function getRandomSensorParameters()
  ---@type SensorParameters
  local sensorParameters = {
    nearStdev = math.random() * 10,
    mediumMean = math.random() * 20,
    mediumStdev = math.random() * 20,
    farShift = math.random() * 80 + 20,
    farSteepness = math.random(),
  }
  return sensorParameters
end

---@return DeltaParameters
local function getRandomDeltaParameters()
  ---@type DeltaParameters
  local deltaParameters = {
    zeroStdev = math.random() * 10,
    sigmoidShift = math.random() * 20 + 3,
    sigmoidSteepness = math.random(),
  }
  return deltaParameters
end

---@return Rule
local function getRandomRule()
  ---@type Rule
  local rule = {
    angularVelocity = math.random() * 4 - 2,
    linearVelocity = math.random() * 4,
    sensorRules = {},
    deltaRules = {},
  }
  for _, sensor in pairs(SensorNames) do
    rule.sensorRules[sensor] = math.random(1, nOfSensorCategories)
  end
  for _, delta in pairs(DeltaNames) do
    rule.deltaRules[delta] = math.random(1, nOfDeltaCategories)
  end
  return rule
end

---@param nOfRules number
---@return Rule[]
local function getRandomRuleSet(nOfRules)
  ---@type Rule[]
  local ruleSet = {}
  for i = 1, nOfRules do
    ruleSet[i] = getRandomRule()
  end
  return ruleSet
end

---@param deltaParameters DeltaParameters
---@return table<DeltaCategories, MembershipFunction>
local function buildDeltaMembershipFunctions(deltaParameters)
  ---@type table<DeltaCategories, MembershipFunction>
  local membershipFunctions = {
    [DeltaCategories.negative] = getSigmoid(-deltaParameters.sigmoidSteepness, -deltaParameters.sigmoidShift),
    [DeltaCategories.positive] = getSigmoid(deltaParameters.sigmoidSteepness, deltaParameters.sigmoidShift),
    [DeltaCategories.zero] = getGaussian(0, deltaParameters.zeroStdev),
    [DeltaCategories.one] = function(_) return 1 end
  }
  return membershipFunctions
end

---@param sensorParameters SensorParameters
---@return table<SensorCategories, MembershipFunction>
local function buildSensorMembershipFunctions(sensorParameters)
  ---@type table<SensorCategories, MembershipFunction>
  local membershipFunctions = {
    [SensorCategories.far] = getSigmoid(sensorParameters.farSteepness, sensorParameters.farShift),
    [SensorCategories.medium] = getGaussian(sensorParameters.mediumMean, sensorParameters.mediumStdev),
    [SensorCategories.near] = getGaussian(0, sensorParameters.nearStdev),
    [SensorCategories.one] = function(_) return 1 end
  }
  return membershipFunctions
end

---@type Index
local index = {
  getOutputs = function(self, inputs)
    local dmf = self.deltaMembershipFunctions
    local smf = self.sensorMembershipFunctions
    local angularVelocityOutput = 0
    local linearVelocityOutput = 0

    for _, rule in ipairs(self.chromossome.rules) do
      local antecedent = 1

      for sensorName, sensorCategory in pairs(rule.sensorRules) do
        antecedent = math.min(antecedent, smf[sensorCategory](inputs.sensorInputs[sensorName]))
      end

      for deltaName, deltaCategory in pairs(rule.deltaRules) do
        antecedent = math.min(antecedent, dmf[deltaCategory](inputs.deltaInputs[deltaName]))
      end
      angularVelocityOutput = angularVelocityOutput + rule.angularVelocity * antecedent
      linearVelocityOutput = linearVelocityOutput + rule.linearVelocity * antecedent
    end
    return linearVelocityOutput, angularVelocityOutput
  end
}

---@param chromossome Chromossome | nil
---@return FuzzySystem
local FuzzySystem = function(chromossome)
  local rules = chromossome and chromossome.rules or getRandomRuleSet(50)
  local deltaParameters = chromossome and chromossome.deltaParameters or getRandomDeltaParameters()
  local sensorParameters = chromossome and chromossome.sensorParameters or getRandomSensorParameters()

  local instance = {
    chromossome = {
      rules = rules,
      deltaParameters = deltaParameters,
      sensorParameters = sensorParameters,
    },
    deltaMembershipFunctions = buildDeltaMembershipFunctions(deltaParameters),
    sensorMembershipFunctions = buildSensorMembershipFunctions(sensorParameters)
  }
  setmetatable(instance, { __index = index })
  return instance
end

return FuzzySystem
