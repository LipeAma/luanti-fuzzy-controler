---@meta

---@class PointedNothing
---@field type "nothing"

---@class PointedNode
---@field type "node"
---@field under vector
---@field above vector

---@class PointedObject
---@field type "object"
---@field ref ObjectRef

---@class PointedRaycastOnly
---@field intersection_point vector
---@field box_id integer
---@field intersection_normal vector

---@class PointedNodeRaycast : PointedNode, PointedRaycastOnly
---@class PointedNothingRaycast : PointedNothing, PointedRaycastOnly
---@class PointedObjectRaycast : PointedObject, PointedRaycastOnly

---@class CollisionInfo
---@field type "node"|"object" The type of thing collided with.
---@field axis "x"|"y"|"z" The axis of collision.
---@field node_pos? vector The position of the node, if type is "node".
---@field object? ObjectRef The object reference, if type is "object".
---@field new_pos? vector The position of the entity when the collision occurred.
---@field old_velocity? vector
---@field new_velocity? vector

---@class MoveResult
---@field touching_ground boolean True if the entity was moving and collided with ground.
---@field collides boolean
---@field standing_on_object boolean
---@field collisions CollisionInfo[] A list of collisions that occurred during the step.

---@class ColorTable
---@field r number integer value from 0-255 for the red component.
---@field g number integer value from 0-255 for the green component.
---@field b number integer value from 0-255 for the blue component.
---@field a? number integer value from 0-255 for the alpha component (defaults to 255).

---@class SoundParams
---@field to_player? string
---@field gain? number
---@field pitch? number
---@field fade? number
---@field ephemeral? boolean
---@field pos? vector
---@field max_hear_distance? number
---@field loop? boolean
---@field start_time? number

---@class LuantiGameInfo
---@field id string
---@field title string
---@field author string
---@field path string

---@class LuantiPlayerInformation
---@field address string
---@field ip_version number
---@field connection_uptime number
---@field protocol_version number
---@field formspec_version number
---@field lang_code string
---@field min_rtt? number
---@field max_rtt? number
---@field avg_rtt? number
---@field min_jitter? number
---@field max_jitter? number
---@field avg_jitter? number
---@field version_string? string

---@class LuantiPlayerWindowInformation
---@field size {x: number, y: number}
---@field max_formspec_size {x: number, y: number}
---@field real_gui_scaling number
---@field real_hud_scaling number
---@field touch_controls boolean

---@class LuantiVersionInfo
---@field project string
---@field string string
---@field proto_min number
---@field proto_max number
---@field hash string
---@field is_dev boolean

---@class PlayerHPChangeReason
---@field type '"set_hp"'|'"punch"'|'"fall"'|'"node_damage"'|'"drown"'|'"respawn"'
---@field from '"mod"'|'"engine"'
---@field object? ObjectRef
---@field node? string
---@field node_pos? vector

---@class HTTPApiTable
---@field fetch fun(req: HTTPRequest, callback: fun(res: HTTPRequestResult))
---@field fetch_async fun(req: HTTPRequest): number
---@field fetch_async_get fun(handle: number): HTTPRequestResult

---@class HTTPRequest
---@field url string
---@field timeout? number
---@field method? '"GET"'|'"POST"'|'"PUT"'|'"DELETE"'|'"HEAD"'|'"PATCH"'
---@field user_agent? string
---@field extra_headers? table<string, string>
---@field data? string
---@field binary? boolean
---@field credentials? {user:string, password:string}

---@class HTTPRequestResult
---@field succeeded boolean
---@field code number
---@field data string
---@field headers table<string, string>

---@class ItemStack
---@field name string
---@field count number
---@field wear number
---@field metadata table
---@field get_name fun(self: ItemStack):string
---@field get_count fun(self: ItemStack):number
---@field get_wear fun(self: ItemStack):number
---@field get_meta fun(self: ItemStack):table
---@field set_name fun(self: ItemStack, name: string)
---@field set_count fun(self: ItemStack, count: number)
---@field set_wear fun(self: ItemStack, wear: number)
---@field set_meta fun(self: ItemStack, meta: table)
---@field clear fun(self: ItemStack)
---@field to_table fun(self: ItemStack):table
---@field to_string fun(self: ItemStack):string
---@field is_empty fun(self: ItemStack):boolean
---@field equals fun(self: ItemStack, other: ItemStack):boolean

---@class NodeMetaRef
---@field get_string fun(self: NodeMetaRef, key: string):string
---@field get_int fun(self: NodeMetaRef, key: string):number
---@field get_float fun(self: NodeMetaRef, key: string):number
---@field get_table fun(self: NodeMetaRef):table
---@field set_string fun(self: NodeMetaRef, key: string, value: string)
---@field set_int fun(self: NodeMetaRef, key: string, value: number)
---@field set_float fun(self: NodeMetaRef, key: string, value: number)

---@class NodeTimerRef
---@field start fun(self: NodeTimerRef, timeout: number)
---@field stop fun(self: NodeTimerRef)
---@field get_timeout fun(self: NodeTimerRef):number
---@field get_elapsed fun(self: NodeTimerRef):number

---@class VoxelManip
---@field read_from_map fun(self: VoxelManip, p1: vector, p2: vector)
---@field write_to_map fun(self: VoxelManip)
---@field get_data fun(self: VoxelManip):table
---@field set_data fun(self: VoxelManip, data: table)
---@field get_node fun(self: VoxelManip, pos: vector):NodeItemTable
---@field set_node fun(self: VoxelManip, pos: vector, node: NodeItemTable)
---@field update_map fun(self: VoxelManip)

---@class StorageRef
---@field get fun(self: StorageRef, key: string):string?
---@field set fun(self: StorageRef, key: string, value: string)
---@field get_string fun(self: StorageRef, key: string):string?
---@field set_string fun(self: StorageRef, key: string, value: string)
---@field get_int fun(self: StorageRef, key: string):number?
---@field set_int fun(self: StorageRef, key: string, value: number)
---@field get_float fun(self: StorageRef, key: string):number?
---@field set_float fun(self: StorageRef, key: string, value: number)

---@class Job
---@field cancel fun(self: Job)

---@class Settings
---@field get fun(self: Settings, name: string):any
---@field get_bool fun(self: Settings, name: string):boolean
---@field get_pos fun(self: Settings, name: string):vector?

---@class ModChannel
---@field name string
---@field joined boolean
---@field send_to_all fun(self: ModChannel, message: string)
---@field send_to_player fun(self: ModChannel, player_name: string, message: string)
