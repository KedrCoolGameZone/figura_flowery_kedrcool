vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(false)
vanilla_model.CAPE:setVisible(false)
vanilla_model.ELYTRA:setVisible(false)

-- THE OUTLINE
-- local outline = require "outline"
-- outline(models.model,{color=vec(0, 0, 0)})

-- CUSTOM PARTICLES
local confetti = require("confetti")
-- Confetti.registerSprite(name, sprite, bounds, lifetime, pivot)
confetti.registerSprite("flowers", textures["particles"], vec(0,0,15,15))
confetti.registerSprite("dust", textures["particles"], vec(62,0,63,1))

-- STOP THE FLICKERING OF THE PLANES... 
models:setPrimaryRenderType("Translucent_Cull")
-- SPEAKING
function events.chat_send_message(msg)
	if not player:isLoaded() then return end
    animations.model.talk:play()
    return msg
end

-- ########## THE ACTION WHEEL ##########
-- creates and sets main page
local mainPage = action_wheel:newPage()
action_wheel:setPage(mainPage)

-- Voice Clips
function pings.toggleSFX(state)
	if state == true then
		voiceclips = false
	else
		voiceclips = true
	end
end

-- Voice Clips Icon
local modelToggle = mainPage:newAction()
	:title("Disable Voice Clips")
	:toggleTitle("Enable Voice Clips")
	:item("minecraft:redstone_torch")
	:toggleItem("minecraft:lever")
	:hoverColor(1, 1, 1)
	:setOnToggle(pings.toggleSFX)
	
-- BECOME FLOWER
function pings.toggleFlower(state)
	models.model.model:setVisible(not state)
	models.model.Flower:setVisible(state)
	if state == true then
		renderer:setShadowRadius(0.2)
	else
		renderer:setShadowRadius(0.5)
	end
end

-- BECOME FLOWER ICON
local modelToggle = mainPage:newAction()
	:title("Flowerify")
	:toggleTitle("Humanify")
	:item("minecraft:dandelion")
	:toggleItem("minecraft:player_head")
	:hoverColor(1, 1, 1)
	:setOnToggle(pings.toggleFlower)

-- -- MANTLE
-- function pings.toggleMantle(state)
	-- models.model.model.Body.torso.mantle_nooutline:setVisible(not state)
-- end

-- -- MANTLE ICON
-- local modelToggle = mainPage:newAction()
	-- :title("Mantle")
	-- :toggleTitle("Unmantle")
	-- :item("minecraft:egg")
	-- :toggleItem("minecraft:leather_helmet")
	-- :hoverColor(1, 1, 1)
	-- :setOnToggle(pings.toggleMantle)

function events.render(delta, context)
-- voice clips toggle. i tried putting this in a tick event but it still played like the first bit of the sounds?
    if voiceclips == false then
        sounds:stopSound()
	end
-- AIR ATTACK, the length of jumpdown is long to always be playing
-- define when attacking
	if animations.model.attackR:isPlaying() or animations.model.attackL:isPlaying() then
	flowerattack = true
	else flowerattack = false
	end
-- define when jumping
	if animations.model.jumpdown:isPlaying() or animations.model.walkjumpdown:isPlaying() or animations.model.sprintjumpdown:isPlaying() then
	flowerjump = true
	else flowerjump = false
	end
-- if jumping and attacking, do an air kick animation
	if flowerattack and flowerjump == true then
	animations.model.jumpdown:stop()
	animations.model.walkjumpdown:stop()
	animations.model.sprintjumpdown:stop()
	animations.model.attackR:stop()
	animations.model.attackL:stop()
    animations.model.fair:play()
	end
-- stop kicking when on the ground
	if player:isOnGround() then
	animations.model.fair:stop()
	end
-- ONLY CROUCH WHEN CROUCHING i dont think this does anything actually
	if player:isSneaking() and player:isOnGround() then
	animations.model.crouch:play()
	else
	animations.model.crouch:stop()
	end
	if not player:isSneaking() then
		animations.model.crouch:stop()
	end
-- so CROUCHING WHILE MINING doesnt look weird. it kind of sucks but it works
-- if mining while crouching, stop the crouch animation
	if animations.model.mineR:isPlaying() and animations.model.crouch:isPlaying() then
	animations.model.crouch:stop()
-- if you stop mining while crouching, resume crouch animation
	elseif player:isSneaking() and not animations.model.mineR:isPlaying() and not animations.model.flydown:isPlaying() and not animations.model.fly:isPlaying() then animations.model.crouch:play()
	end
-- stop doing a crouch animation while flying
	if player:isSneaking() and animations.model.flydown:isPlaying() or animations.model.fly:isPlaying() then
		animations.model.crouch:stop()
	end
-- stop doing a crouch animation while jumping!!
	if not player:isOnGround() and player:isSneaking() then
		animations.model.crouch:stop()
		animations.model.crouchjumpup:setPriority(1)
		animations.model.crouchjumpup:play()
	else
		animations.model.crouchjumpup:stop()
	end
-- OVERRIDE IDLE
	if animations.model.attackR:isPlaying() then
	animations.model.attackR:setPriority(1)
	end
end

function events.tick()
	
-- properly use bow animation
	local mainHand = player:getHeldItem()
	local offHand = player:getItem(2)
	if mainHand.id:find("bow") or mainHand.id:find("crossbow") or offHand.id:find("bow") or offHand.id:find("crossbow") then
		animations.model.idle:stop()
		animations.model.holdR:stop()
	end
-- PARTICLE when sprint jumping
	if flowerjump == true and player:isOnGround() and player:isSprinting() then -- this activates like 6 times if its not in a tick event
	particles:newParticle("firework", player:getPos(), vec(0, 0.3, 0))
	confetti.newParticle("flowers",player:getPos()+vec(0,math.random(),0),vec(0,0,0),
	{
		scale=1, --+math.random()*0.3,
		billboard = true,
		acceleration=vec(0,0.005,0),
		ticker=function(particle)
			confetti.defaultTicker(particle)
			-- some fancy math stuff to only scale it near the end of lifetime
			particle.scale = math.clamp(math.map(particle.lifetime, particle.options.lifetime, 1, 2, 0), 0, 0.8)
		end
	}
	)
	end
--dust particle when crouch walking
	if animations.model.crouch:isPlaying() and player:isMoving() and player:isOnGround() then
    confetti.newParticle(
        "dust",
        player:getPos()+vec(0,0.1,0),
        vec((math.random()-0.4)*0.22,-0.2+math.random()*0.2,(math.random()-0.4)*0.22),
        {
            acceleration=vec(0,-0.04,0),
            lifetime=10,
			billboard = true,
            ticker=function(particle)
                -- make sure to call the default ticker which will calculate the regular particle movement
                confetti.defaultTicker(particle)
                -- get velocity so we can check for collision
                local x,y,z = particle.velocity:unpack()
                -- check if previous tick _position plus velocity in each direction would be inside a block, if so flip the velocity to bounce
                if world.getBlockState(particle._position+vec(x,0,0)):isSolidBlock() or world.getBlockState(particle._position-vec(x,0,0)):isSolidBlock() then
                    particle.velocity.x = -x
                end
                if world.getBlockState(particle._position+vec(0,y,0)):isSolidBlock() or world.getBlockState(particle._position-vec(0,y,0)):isSolidBlock() then
                    particle.velocity.y = -y*0.7 -- for y velocity slow down when bouncing
                end
                if world.getBlockState(particle._position+vec(0,0,z)):isSolidBlock() or world.getBlockState(particle._position-vec(0,0,z)):isSolidBlock() then
                    particle.velocity.z = -z
                end
                -- overwrite position with our own calculation.
                -- using _position (which is the position from previous tick) because
                -- the defaultTicker already modified the current position,
                -- so we want to overwrite that with the previous tick value as a base
                particle.position = particle._position + particle.velocity
            end
        }
    )
end
end


-- ########## THIS IS THE RAINBOW'S TRAIL ##########

-- local trailblazer = require("trailblazer")
-- local trail = trailblazer:new(models.model.model, 8)
-- -- -- Argument 1: your model's root part (the one that contains parts like `Head` and `LeftArm`)
-- -- -- Argument 2: the length of the trail (how many freeze-frames should be kept before they fully fade out)

-- function trail.applyEffects(part) -- called for each freeze-frame, where `part` is the newly created part
    -- part:color(vectors.hsvToRGB(client.getSystemTime()%10000/10000, 0.5, 1)) -- rainbow effect
-- end

-- function pings.setTrail(val)
    -- if val then
        -- trail:enable()
    -- else
        -- trail:disable()
    -- end
-- end

-- mainPage:newAction():title("Toggle Trail"):item("echo_shard"):onToggle(pings.setTrail)

-- ########## CHAT SFX ##########

-- KorboSpeech v2.1.3 by @korbosoft
-- With edits by @manuel_2867, @customable, @skunkmommy179
local voiceSounds = {
"snd_flowery_voicenoise_1", "snd_flowery_voicenoise_2", "snd_flowery_voicenoise_3",
    -- put at least 1 or 2 sound names here
    -- for example: "sound1", "sound2"
    -- also use only mono channel sounds, otherwise will be heard globally!
}
local voiceSpeechRate = 2 -- rate of speech, how many ticks to wait per character
local voiceVolume = 0.3 -- voice volume
local voicePitchRange = 0 -- range of pitch randomization, set to zero to disable
local voiceMinLength = 1 -- minimum amount of sounds to play even if message is shorter
local voiceMaxLength = 10 -- maximum amount of characters to speak if you want to limit it
local cancelPreviousSound = false -- set to true if you want to avoid overlapping sounds

-- DO NOT CHANGE ANYTHING UNDER HERE!
local queue = 0
local basePitch = 1 - voicePitchRange / 2
local currentSound = nil
function pings.KorboSpeak(amount)
    if player:isLoaded() then
        queue = queue + amount
    end
end
function events.tick()
    if queue > 0 and world.getTime() % voiceSpeechRate == 0 then
        queue = queue - 1
        if cancelPreviousSound and currentSound then
            currentSound:stop()
        end
        currentSound = sounds[voiceSounds[math.random(#voiceSounds)]]
        currentSound:pos(player:getPos())
            :volume(voiceVolume)
            :pitch(basePitch + math.random() * voicePitchRange)
            :subtitle(player:getName() .. " speaks")
            :play()
    end
end
function events.chat_send_message(msg)
    if not msg then return end
    if string.sub(msg, 1, 1) ~= "/" then
        local nospaces = msg:gsub("%s+", "")
        pings.KorboSpeak(math.max(voiceMinLength, math.min(#nospaces, voiceMaxLength)))
    end
    return msg
end