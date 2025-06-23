---@class LearningProcess
---@field lp LearningParams
---@field spawn vector
---@field target vector
---@field active boolean
---@field entities FuzzyEntity[]
---@field saved_chromossomes Chromossome[]
---@field is_logging boolean,
---@field generation_counter number,
---@field log_file_handle file*?

---@class LearningParams
---@field anteceMutRate number
---@field conseqMutWeight number
---@field conseqMutRate number
---@field popSize number
---@field elitism number

---@class RatedChromossome
---@field chromossome Chromossome
---@field fitness number

---@class RatedIndividual
---@field entity LuaEntity A referência da entidade avaliada
---@field chromossome Chromossome O cromossomo da entidade
---@field fitness number A pontuação de fitness


local storage = core.get_mod_storage()
local LP = Fuzzypath.LP
local auxiliar = dofile(Fuzzypath.modpath .. "/auxiliar.lua")
local mutate = auxiliar.mutate
local crossover = auxiliar.crossover

--- Coleta os dados de uma geração e os escreve no arquivo de log.
---@param generation_number number
---@param rated_population RatedIndividual[] A população já avaliada e ordenada
local function log_generation_data(generation_number, rated_population)
  -- Se o log não estiver ativo ou não houver arquivo, não faz nada
  if not LP.is_logging or not LP.log_file_handle or #rated_population == 0 then
    return
  end

  -- 1. Coletar estatísticas de fitness
  local best_fitness = rated_population[1].fitness
  local worst_fitness = rated_population[#rated_population].fitness
  local sum_fitness = 0
  for _, individual in ipairs(rated_population) do
    sum_fitness = sum_fitness + individual.fitness
  end
  local avg_fitness = sum_fitness / #rated_population

  -- 2. Coletar estatísticas do melhor indivíduo (o elite)
  local elite_entity = rated_population[1].entity
  if not elite_entity or not elite_entity:is_valid() then return end
  local elite_table = elite_entity:get_luaentity()
  if not elite_table then return end

  local elite_best_distance = elite_table.best_distance
  local elite_collision_count = elite_table.collision_count
  local elite_time = elite_table.time_at_best_distance

  -- 3. Formatar a linha do CSV
  local log_line = string.format(
    "%d,%.6f,%.6f,%.6f,%.2f,%d,%.2f\n",
    generation_number,
    best_fitness,
    avg_fitness,
    worst_fitness,
    elite_best_distance,
    elite_collision_count,
    elite_time
  )

  -- 4. Escrever no arquivo e forçar a gravação no disco
  LP.log_file_handle:write(log_line)
  LP.log_file_handle:flush()
end


local SIMULATION_TIME = 5

---@param entity FuzzyEntity
local function getFitness(entity)
  local entity_table = entity:get_luaentity()

  if not entity_table or not entity_table.is_training then
    return 0
  end

  local initial_distance = (LP.spawn - LP.target):length()

  if initial_distance < 0.1 then return 1.0 end

  if entity_table.best_distance >= initial_distance then
    return 0.0001
  end

  local p_d = 1 / (1 + entity_table.best_distance)

  local p_e = (initial_distance - entity_table.best_distance) / initial_distance

  local base_reward = (p_d + p_e) / 2

  local MAX_COLLISIONS_FOR_PENALTY = 50.0
  local MIN_COLLISION_FACTOR = 0.1
  local penalty_per_collision = (1.0 - MIN_COLLISION_FACTOR) / MAX_COLLISIONS_FOR_PENALTY
  local linear_penalty = 1.0 - (entity_table.collision_count * penalty_per_collision)
  local p_c = math.max(MIN_COLLISION_FACTOR, linear_penalty)

  local time_score = (SIMULATION_TIME - entity_table.time_at_best_distance) / SIMULATION_TIME
  local p_t = math.max(0, time_score)

  local final_fitness = base_reward * p_c * p_t

  -- core.log("action",
  --   string.format("Fitness: [BaseRew:%.2f, p_c:%.2f, p_t:%.2f] -> Total: %.4f", base_reward, p_c, p_t, final_fitness))

  return final_fitness
end


local function learningStop()
  core.log("action", "Terminating learning process")
  for i, entity in ipairs(LP.entities) do
    entity:remove()
    -- core.log("action", "Removed entity " .. tostring(i))
  end
  core.log("action", "Learning process terminated")
  LP.active = false
end

local real_time_start_of_generation = nil

local function nextGeneration()
  SIMULATION_TIME = math.min(SIMULATION_TIME * (1+3/SIMULATION_TIME))
  if real_time_start_of_generation then
    local real_time_elapsed = os.time() - real_time_start_of_generation
    core.log("warning", "DURAÇÃO REAL DA GERAÇÃO: " .. real_time_elapsed .. " segundos.")
  end
  real_time_start_of_generation = os.time()
  ---@type RatedIndividual[] -- Esta anotação agora funciona por causa da declaração no topo do arquivo.
  local rated_population = {}
  for _, entity in ipairs(LP.entities) do
    if entity:is_valid() then
      local entityTable = entity:get_luaentity()
      if entityTable then
        table.insert(rated_population, {
          entity = entity,
          chromossome = entityTable.fuzzySystem.chromossome,
          fitness = getFitness(entity)
        })
      end
    end
  end

  table.sort(rated_population, function(a, b) return a.fitness > b.fitness end)

  if LP.is_logging then
    log_generation_data(LP.generation_counter, rated_population)
    LP.generation_counter = LP.generation_counter + 1
  end

  -- Extrai os cromossomos dos elites
  ---@type Chromossome[]
  local elites = {}
  local num_elites = math.min(LP.lp.elitism, #rated_population)
  for i = 1, num_elites do
    table.insert(elites, rated_population[i].chromossome)
  end

  -- Remove as entidades antigas
  for _, individual in ipairs(rated_population) do
    if individual.entity:is_valid() then
      individual.entity:remove()
    end
  end

  if #elites == 0 then
    core.log("warning", "No elites survived. Stopping learning process.")
    learningStop()
    return
  end

  ---@type FuzzyEntity[]
  local entities = {}

  for _, chromossome in ipairs(elites) do
    ---@type Staticdata
    local staticdata = {
      target = LP.target,
      chromossome = chromossome,
      is_training = true,
      spawn_is_visible = true,
    }
    local entity = core.add_entity(LP.spawn, "fuzzypath:entity", core.serialize(staticdata))
    if not entity then
      core.log("error", "Failed to add learning entity, Total=" .. tostring(#entities))
    else
      entity:set_yaw(math.random() * 2 * math.pi)
      table.insert(entities, entity)
      -- core.log("action", "New entity added to learning process. Total=" .. tostring(#entities))
    end
  end



  while #entities < LP.lp.popSize do
    local parent1 = elites[math.random(LP.lp.elitism)]
    local parent2 = elites[math.random(LP.lp.elitism)]

    local child_chromossome = crossover(parent1, parent2)

    mutate(child_chromossome, LP.lp)

    ---@type Staticdata
    local staticdata = {
      target = LP.target,
      chromossome = child_chromossome,
      is_training = true
    }

    local entity = core.add_entity(LP.spawn, "fuzzypath:entity", core.serialize(staticdata))
    if not entity then
      core.log("error", "Failed to add learning entity, Total=" .. tostring(#entities))
    else
      entity:set_yaw(math.random() * 2 * math.pi)
      table.insert(entities, entity)
      -- core.log("action", "New entity added to learning process. Total=" .. tostring(#entities))
    end
  end

  LP.entities = entities

  ---@type Chromossome[]
  local chromossomes_to_save = {}
  for _, entity in ipairs(LP.entities) do
    local entityTable = entity:get_luaentity()
    if entityTable and entityTable.fuzzySystem and entityTable.fuzzySystem.chromossome then
      table.insert(chromossomes_to_save, entityTable.fuzzySystem.chromossome)
    end
  end

  storage:set_string("saved_generation", core.serialize(chromossomes_to_save))
  core.log("action", "Fuzzypath: Saved " .. #chromossomes_to_save .. " chromossomes to storage.")
  core.after(SIMULATION_TIME, nextGeneration)
end


local function learningStart()
  core.log("action", "Initiating learning process")
  ---@type FuzzyEntity[]
  local entityArray = {}

  if LP.saved_chromossomes and #LP.saved_chromossomes > 0 then
    core.log("action", "Loading population from saved generation.")
    for _, chromossome in ipairs(LP.saved_chromossomes) do
      ---@type Staticdata
      local staticdata = {
        target = LP.target,
        chromossome = chromossome,
        is_training = true,
        spawn_is_visible = math.random() < 0.1
      }
      local entity = core.add_entity(LP.spawn, "fuzzypath:entity", core.serialize(staticdata))
      if entity then
        entity:set_yaw(math.random() * 2 * math.pi) -- Também adicionamos o ângulo aleatório aqui!
        table.insert(entityArray, entity)
      end
    end
  else
    core.log("action", "Creating new random population.")
    for _ = 1, LP.lp.popSize do
      ---@type Staticdata
      local staticdata = { target = LP.target, is_training = true }
      local entity = core.add_entity(LP.spawn, "fuzzypath:entity", core.serialize(staticdata))
      if entity then
        entity:set_yaw(math.random() * 2 * math.pi) -- E aqui também!
        table.insert(entityArray, entity)
      end
    end
  end

  LP.entities = entityArray
  LP.active = true -- Marca o processo como ativo
  core.log("action", "Initialization complete. Population size: " .. #LP.entities)
  core.after(SIMULATION_TIME, nextGeneration)
end



---@type ChatCommandCallback
local learn = function(name, param)
  local player = core.get_player_by_name(name)
  if not player then
    return false, "Player \"" .. name .. "\" not found."
  end

  local cmd, arg = param:match("([^ ]+) ?(.*)")
  if not cmd then
    return false, "Invalid argument. See /help learn"
  end

  -- >> INÍCIO DA CORREÇÃO <<
  -- Adicionando a lógica para os comandos de log
  if cmd == "log_start" then
    if LP.is_logging then
      return true, "Logging is already active."
    end
    -- Cria um nome de arquivo único com data e hora
    local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
    local file_path = core.get_worldpath() .. "/fuzzypath_log_" .. timestamp .. ".csv"

    -- Abre o arquivo em modo de escrita ('w')
    LP.log_file_handle = io.open(file_path, "w")
    if not LP.log_file_handle then
      return false, "Failed to open log file at: " .. file_path
    end

    -- Escreve o cabeçalho do CSV
    LP.log_file_handle:write(
      "generation,best_fitness,avg_fitness,worst_fitness,elite_best_distance,elite_collision_count,elite_time\n")
    LP.is_logging = true
    LP.generation_counter = 0 -- Reseta o contador a cada novo log

    return true, "Logging started. File: " .. file_path
  elseif cmd == "log_stop" then
    if not LP.is_logging then
      return true, "Logging is not active."
    end
    if LP.log_file_handle then
      LP.log_file_handle:close()
    end
    LP.log_file_handle = nil
    LP.is_logging = false
    return true, "Logging stopped and file saved."
  elseif cmd == "start" then
    if LP.active then
      return true, "Learning process has started already"
    elseif not LP.target then
      return false, "No learning target"
    elseif not LP.spawn then
      return false, "No learning spawn"
    else
      if arg == "reset" then
        core.log("action", "RESET command received. Clearing saved generation...")
        LP.saved_chromossomes = nil
        storage:set_string("saved_generation", "")
        return true, "Saved generation cleared. Starting new training from scratch."
      end

      learningStart()
      return true, "Learning started."
    end
  elseif cmd == "stop" then
    if LP.active then
      learningStop()
      return true, "Learning process stopped"
    else
      return true, "There is no learning process to stop."
    end
  elseif cmd == "target" then
    LP.target = player:get_pos()
    storage:set_string("target", core.serialize(LP.target))
    return true, "Target set and saved at " .. tostring(LP.target)
  elseif cmd == "spawn" then
    LP.spawn = player:get_pos()
    storage:set_string("spawn", core.serialize(LP.spawn))
    return true, "Spawn set and saved at " .. tostring(LP.spawn)
  end

  return false, "Invalid argument \"" .. param .. "\""
end


---@type ChatCommandDefinition
local commandDefinition = {
  params = "<start [reset]>|<stop>|<target>|<spawn>|<log_start>|<log_stop>",
  description = "Controls the learning process. Use 'log_start' and 'log_stop' to record data.",
  privs = {},
  func = learn,
}
core.register_chatcommand("learn", commandDefinition)
