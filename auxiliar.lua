---@param chromossome Chromossome
---@param lp LearningParams
local function mutate(chromossome, lp)
  ---@return number
  local getRandomMultiplier = function()
    if math.random() < lp.conseqMutRate then
      return math.random() * (lp.conseqMutWeight - 1 / lp.conseqMutWeight) + 1 / lp.conseqMutWeight
    else
      return 1
    end
  end

  ---@type DeltaCategories[]
  local DeltaCategories = { 1, 2, 3, 4 }

  ---@param currentCategory DeltaCategories
  ---@return DeltaCategories
  local getRandomDelta = function(currentCategory)
    if math.random() < lp.anteceMutRate then
      return DeltaCategories[math.random(#DeltaCategories)]
    else
      return currentCategory
    end
  end

  ---@type SensorCategories[]
  local SensorCategories = { 1, 2, 3, 4 }

  ---@param currentCategory SensorCategories
  ---@return SensorCategories
  local getRandomSensor = function(currentCategory)
    if math.random() < lp.anteceMutRate then
      return SensorCategories[math.random(#SensorCategories)]
    else
      return currentCategory
    end
  end


  for _, rule in ipairs(chromossome.rules) do
    rule.angularVelocity = rule.angularVelocity * getRandomMultiplier()
    rule.linearVelocity = rule.linearVelocity * getRandomMultiplier()
    for i, j in ipairs(rule.deltaRules) do
      rule.deltaRules[i] = getRandomDelta(j)
    end
    for i, j in ipairs(rule.sensorRules) do
      rule.sensorRules[i] = getRandomSensor(j)
    end
  end
end



--- Cria um novo cromossomo filho combinando dois pais.
---@param parent1 Chromossome
---@param parent2 Chromossome
---@return Chromossome
local function crossover(parent1, parent2)
  ---@type Chromossome
  local child = {
    deltaParameters = {}, ---@diagnostic disable-line: missing-fields
    sensorParameters = {}, ---@diagnostic disable-line: missing-fields
    rules = {}
  }

  -- Parte 1: Crossover para os parâmetros (Delta e Sensor)
  -- Para estas tabelas pequenas, podemos fazer uma escolha aleatória para cada parâmetro.
  -- Isso é uma forma de "Crossover Uniforme".
  for key, value in pairs(parent1.deltaParameters) do
    if math.random() < 0.5 then
      child.deltaParameters[key] = value                        -- Pega do pai 1
    else
      child.deltaParameters[key] = parent2.deltaParameters[key] -- Pega do pai 2
    end
  end
  for key, value in pairs(parent1.sensorParameters) do
    if math.random() < 0.5 then
      child.sensorParameters[key] = value                         -- Pega do pai 1
    else
      child.sensorParameters[key] = parent2.sensorParameters[key] -- Pega do pai 2
    end
  end

  -- Parte 2: Crossover para a lista de 50 regras
  -- Aqui usamos o "Crossover de Ponto Único" clássico.
  local crossoverPoint = math.random(1, #parent1.rules - 1) -- Ponto de corte entre a regra 1 e 49

  for i = 1, #parent1.rules do
    if i <= crossoverPoint then
      child.rules[i] = parent1.rules[i] -- Pega as primeiras regras do pai 1
    else
      child.rules[i] = parent2.rules[i] -- Pega o resto das regras do pai 2
    end
  end

  return core.deserialize(core.serialize(child))
end


---@param moveresult table A tabela de resultado do on_step.
---@param last_y number A posição Y da entidade no tick anterior.
---@param current_y number A posição Y da entidade no tick atual.
---@return boolean
local function is_valid_collision(moveresult, last_y, current_y)
  if not moveresult or not moveresult.collisions then
    return false
  end

  local has_horizontal_collision = false
  for _, collision in ipairs(moveresult.collisions) do
    if collision.axis == "x" or collision.axis == "z" then
      has_horizontal_collision = true
      break
    end
  end

  if not has_horizontal_collision then
    return false
  end

  local did_climb = (current_y - last_y) > 0.01

  if has_horizontal_collision and not did_climb then
    return true
  end

  return false
end

return {
  mutate = mutate,
  crossover = crossover,
  is_valid_collision = is_valid_collision
}
