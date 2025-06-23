---@class Fuzzypath
---@field LP LearningProcess
---@field FuzzySystem FuzzySystem
---@field modpath string

local modpath = core.get_modpath("fuzzypath")
if not modpath then
  core.log("error", "Modpath not found, mod not loaded")
  return
end

local storage = core.get_mod_storage()

local raw_target = storage:get_string("target")
local raw_spawn = storage:get_string("spawn")
local raw_chromossomes = storage:get_string("saved_generation")

local deserialized_target = raw_target and core.deserialize(raw_target)
local deserialized_spawn = raw_spawn and core.deserialize(raw_spawn)
local saved_chromossomes = raw_chromossomes and core.deserialize(raw_chromossomes)

local saved_target = deserialized_target and vector.new(deserialized_target)
local saved_spawn = deserialized_spawn and vector.new(deserialized_spawn)

core.log("action",
  "Fuzzypath: Loaded " .. tostring(saved_chromossomes and #saved_chromossomes or 0) .. " saved chromossomes.")


---@type Fuzzypath
Fuzzypath = {
  modpath = modpath,
  FuzzySystem = dofile(modpath .. "/FuzzySystem.lua"),
  LP = {
    spawn = saved_spawn or vector.new(0, 0, 0),
    target = saved_target or vector.new(0, 0, 0),
    saved_chromossomes = saved_chromossomes,
    active = false,
    lp = {
      popSize = 300,
      elitism = 10,
      conseqMutRate = 0.1,
      conseqMutWeight = 2,
      anteceMutRate = 0.1
    },
    entities = {},
    is_logging = false,
    generation_counter = 0,
    log_file_handle = nil
  }
}

dofile(modpath .. "/entity.lua")
dofile(modpath .. "/learn.lua")
dofile(modpath .. "/kill.lua")
