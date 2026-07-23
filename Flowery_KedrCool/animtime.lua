local animlist = {}
for _, v in pairs(animations:getAnimations()) do
   animlist[v:getName()] = v
end
local function err() error('', 4) end 
query = setmetatable({}, {
   __index = function(_, i)
      if i == 'anim_time' or i == "life_time" then
         local _, traceback = pcall(err)
         local name = traceback:match('^(.-) keyframe')
         return animlist[name] and animlist[name]:getTime()
      end
   end
})
q = query
local math_sin = math.sin
math.sin = function(a)
    local _, traceback = pcall(err)
    local name = traceback:match('^(.-) keyframe')
    if name then return math_sin(math.rad(a)) end
    return math_sin(a)
end
local math_cos = math.cos
math.cos = function(a)
    local _, traceback = pcall(err)
    local name = traceback:match('^(.-) keyframe')
    if name then return math_cos(math.rad(a)) end
    return math_cos(a)
end