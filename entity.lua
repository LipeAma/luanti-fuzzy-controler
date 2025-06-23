---@class FuzzyEntityTable : FuzzyEntityDefinitionTable
---@field name string The registered name of the entity ("mod:thing").
---@field object FuzzyEntity A reference back to the object itself.
---@field fuzzySystem FuzzySystem
---@field target vector
---@field maxVelocity number
---@field raySize number
---@field is_training boolean
---@field collision_count number?
---@field total_time number?
---@field best_distance number?
---@field time_at_best_distance number?
---@field last_y_pos number?
---@field spawn_is_visible boolean?

---@class FuzzyEntity : LuaEntity
---@field get_luaentity fun(self: FuzzyEntity):FuzzyEntityTable?

---@class Staticdata
---@field chromossome Chromossome|nil
---@field target vector
---@field is_training boolean

local auxiliar = dofile(core.get_modpath("fuzzypath") .. "/auxiliar.lua")

local function clamp(x, a)
  a = math.abs(a)
  return math.max(-a, math.min(x, a))
end

---@class FuzzyEntityDefinitionTable : EntityDefinition
local entity = {
  ---@type ObjectProperties
  initial_properties = {
    hp_max = 10,
    breath_max = 10,
    physical = true,
    collide_with_objects = false,
    pointable = true,
    visual = "mesh",
    visual_size = { x = 10, y = 10, z = 10 },
    textures = { "entity.png" },
    mesh = "entity.obj",
    collisionbox = { -0.5, 0, -0.5, 0.5, 2, 0.5 },
    is_visible = false,
    makes_footstep_sound = false,
    stepheight = 1.1,
    automatic_face_movement_dir = 0.0,
    automatic_face_movement_max_rotation_per_sec = 360, --deg/sec
    show_on_minimap = true,
    static_save = false,
  },

  ---@param self FuzzyEntityTable
  ---@param angle number
  ---@return number
  getSensor = function(self, angle)
    local eyePos = self.object:get_pos()
    eyePos.y = eyePos.y + 1.5
    local yaw = self.object:get_yaw()
    local dir = core.yaw_to_dir(yaw + angle)
    local thing = core.raycast(eyePos, dir * self.raySize, false):next()
    if not thing then return self.raySize end
    return thing.intersection_point:length()
  end,

  ---@param self FuzzyEntityTable
  ---@return Inputs
  inputs = function(self)
    local delta = self:affineTarget()
    ---@type Inputs
    local inputs = {
      sensorInputs = {
        self:getSensor(90),
        self:getSensor(45),
        self:getSensor(0),
        self:getSensor(-45),
        self:getSensor(-90),
      },
      deltaInputs = {
        delta.x,
        delta.y,
        delta.z
      }
    }
    return inputs
  end,

  ---Computes rotation arround the Y axis, and a translation, of the target position. At the new coordinate system, the entity's position will be the origin, and the entity's yaw vector will be (1,0,0). Therefore the sign of the x coordinate indicates if the target is in front or behind the entity, and the sign of the y coordinate indicates if the target is to the left or to the right.
  ---@param self FuzzyEntityTable
  ---@return vector
  affineTarget = function(self)
    local delta = self.target - self.object:get_pos()
    local yaw = self.object:get_yaw()
    local yawVec = core.yaw_to_dir(yaw)
    local perpendicularVec = core.yaw_to_dir(yaw + math.pi / 2)
    return vector.new(yawVec:dot(delta), delta.y, perpendicularVec:dot(delta))
  end,


  ---@param self FuzzyEntityTable
  on_activate = function(self, staticdata, dtime_s)
    ---@type Staticdata
    local entitydata = core.deserialize(staticdata) or {}
    self.fuzzySystem = Fuzzypath.FuzzySystem(entitydata.chromossome)
    self.target = entitydata.target or self.object:get_pos()
    self.maxVelocity = 4
    self.raySize = 20
    self.object:set_acceleration(vector.new(0, -9.81, 0))
    self.is_training = entitydata.is_training or false
    if self.is_training then
      self.last_y_pos = self.object:get_pos().y
      self.collision_count = 0
      self.total_time = 0
      self.best_distance = math.huge
      self.time_at_best_distance = 0
    end
    if entitydata.spawn_is_visible ~= nil then
      self.object:set_properties({ is_visible = entitydata.spawn_is_visible })
    end
  end,



  ---@param self FuzzyEntityTable
  on_deactivate = function(self, removal)
  end,


  on_step = function(self, dtime, moveresult)
    local current_y = self.object:get_pos().y

    if self.is_training then
      self.total_time = self.total_time + dtime

      if auxiliar.is_valid_collision(moveresult, self.last_y_pos, current_y) then
        self.collision_count = self.collision_count + 1
      end

      local current_distance = (self.object:get_pos() - self.target):length()
      if current_distance < self.best_distance then
        self.best_distance = current_distance
        self.time_at_best_distance = self.total_time
      end
    end

    ---@type Inputs
    local inputs = self:inputs()
    local linear, angular = self.fuzzySystem:getOutputs(inputs)
    local yaw = self.object:get_yaw()
    local dir = core.yaw_to_dir(yaw)
    local velocity = dir * clamp(linear, self.maxVelocity)
    velocity.y = self.object:get_velocity().y
    self.object:set_velocity(velocity)
    self.object:set_yaw(yaw + dtime * angular)

    if self.is_training then
      self.last_y_pos = current_y
    end
  end,


  get_staticdata = function(self)
    if self.FuzzySystem and self.FuzzySystem.chromossome then
      return core.serialize(self.FuzzySystem.chromossome)
    end
  end,
}

core.register_entity("fuzzypath:entity", entity)
