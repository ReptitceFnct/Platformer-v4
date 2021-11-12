-- title:  Main.lua
-- author(s): ReptitceFnct
-- desc:  
-- script: lua
-- input:
-- saveid: Platformer v4

--=========--
-- H E A D --
--=========--

-- This line make mark in the console during the excution 
io.stdout:setvbuf('no')

-- Stop love filters when we re-size image, it's essential for pixel art
love.graphics.setDefaultFilter("nearest")

-- with this line we can debugg step with step in Zerobrain
--if arg[#arg] == "-debug" then require("mobdebug").start() end

--===================--
-- V A R I A B L E S --
--===================--

------------
-- images --
------------

local imgTiles = {}

imgTiles["1"] = love.graphics.newImage("_Resources_/images/tile1.png")
imgTiles["2"] = love.graphics.newImage("_Resources_/images/tile2.png")
imgTiles["3"] = love.graphics.newImage("_Resources_/images/tile3.png")
imgTiles["4"] = love.graphics.newImage("_Resources_/images/tile4.png")
imgTiles["5"] = love.graphics.newImage("_Resources_/images/tile5.png")
imgTiles["="] = love.graphics.newImage("_Resources_/images/tile=.png")
imgTiles["["] = love.graphics.newImage("_Resources_/images/tile[.png")
imgTiles["]"] = love.graphics.newImage("_Resources_/images/tile].png")
imgTiles["H"] = love.graphics.newImage("_Resources_/images/tileH.png")
imgTiles["#"] = love.graphics.newImage("_Resources_/images/tile#.png")
imgTiles["g"] = love.graphics.newImage("_Resources_/images/tileg.png")
imgTiles[">"] = love.graphics.newImage("_Resources_/images/tile-arrow-right.png")
imgTiles["<"] = love.graphics.newImage("_Resources_/images/tile-arrow-left.png")

imgPlayer = love.graphics.newImage("_Resources_/images/player/idle1.png")

-- Map and levels

local map = {}
local level = {}
local currentLevel = 0
local listSprites = {}
local player = nil

-- Globals

local bJumpReady

-- screen 

playScreen = false
deathScreen = false
endScreen = false

--------------
-- constant --
--------------

-- tilesize

local TILESIZE = 16
local GRAVITY = 500
local SCREENWIDTH = 1200
local SCREENHEIGHT = 900

--===================--
-- F U N C T I O N S --
--===================--

-- Collision detection function;
-- Returns true if two boxes overlap, false if they don't;
-- x1,y1 are the top-left coords of the first box, while w1,h1 are its width and height;
-- x2,y2,w2 & h2 are the same, but for the second box.
-- FROM https://love2d.org/wiki/BoundingBox.lua 
function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  
  return x1 < x2+w2 and x2 < x1+w1 and y1 < y2+h2 and y2 < y1+h1
end

function isStart(pPlayer)
  
  pPlayer.x = 10
  pPlayer.y = 10
end

local levels = { "The beginning", "Welcome in hell" }

function LoadLevel(pNum)
  
  if pNum > #levels then
    
    print("There is no level "..pNum)
    return
  end
  
  currentLevel = pNum
  map = {}
  local filename = "_Resources_/levels/level"..tostring(pNum)..".txt"
  
  for line in love.filesystem.lines(filename) do 
    
    map[#map + 1] = line
  end
  
  -- Look for the sprites in the map
  lstSprites = {}
  level = {}
  level.playerStart = {}
  level.playerStart.col = 0
  level.playerStart.lin = 0
  level.coins = 0
  
  for l=1,#map do
    
    for c=1,#map[1] do
      
      local char = string.sub(map[l], c, c)
      
      if char == "P" then
        
        level.playerStart.col = c
        level.playerStart.lig = l
        player = CreatePlayer(c, l)
        
      elseif char == "c" then
        
        CreateCoin(c, l)
        level.coins = level.coins + 1
        
      elseif char == "D" then
        
        CreateDoor(c, l)
        
      elseif char == "@" then
        
        CreatePNJ(c, l)
      end
    end
  end
  
--CreatePlayer(level.playerStart.col,level.playerStart.lig)
end

function NextLevel()
  
  currentLevel = currentLevel + 1
  
  if currentLevel > #levels then
    
    currentLevel = 1
  end
  
  LoadLevel(currentLevel)
end

function isSolid(pID)
  
  if pID == "0" then
    
    return false 
  
  elseif pID == "1" then
    
    return true 
  
  elseif pID == "5" then
    
    return true 
  
  elseif pID == "4" then
    
    return true 
  
  elseif pID == "=" then
    
    return true 
  
  elseif pID == "[" then
    
    return true 
  
  elseif pID == "]" then
    
    return true 
  end
  
  return false
end

function isJumpThrough(pID)
  
  if pID == "g" then
    
    return true 
  end
  
  return false
end

function isLadder(pID)
  
  if pID == "H" then
    
    return true 
  end
  
  if pID == "#" then
    
    return true 
  end
  
  return false
end

function isInvisible(pID)
  
  if pID == ">" or pID == "<" then
    
    return true
  end
  
  return false
end

function CreateSprite(pType, pX, pY)
  
  local mySprite = {}
  
  mySprite.x = pX
  mySprite.y = pY
  mySprite.vx = 0
  mySprite.vy = 0
  mySprite.gravity = 0
  mySprite.isJumping = false
  mySprite.type = pType
  mySprite.standing = false
  mySprite.flip = false
  
  mySprite.currentAnimation = ""
  mySprite.frame = 0
  mySprite.animationSpeed = 1/8
  mySprite.animationTimer = mySprite.animationSpeed
  mySprite.animations = {}
  mySprite.images = {}
  
  mySprite.AddImages = function(psDir, plstImage)
    
    for k,v in pairs(plstImage) do
      
      local fileName = psDir.."/"..v..".png"
      mySprite.images[v] = love.graphics.newImage(fileName)
    end
  end
  
  mySprite.AddAnimation = function(psDir, psName, plstImages)
    
    mySprite.AddImages(psDir, plstImages)
    mySprite.animations[psName] = plstImages
  end
  
  mySprite.PlayAnimation = function(psName)
    
    if mySprite.currentAnimation ~= psName then
      
      mySprite.currentAnimation = psName
      mySprite.frame = 1
    end
  end
  
  table.insert(lstSprites, mySprite)
  
  return mySprite
end

function CreatePlayer(pCol, pLin)
  
  local myPlayer = CreateSprite("player", (pCol - 1) * TILESIZE, (pLin - 1) * TILESIZE)
  myPlayer.gravity = GRAVITY
  myPlayer.AddAnimation("_Resources_/images/player", "idle", { "idle1", "idle2", "idle3", "idle4" })
  myPlayer.AddAnimation("_Resources_/images/player", "run", { "run1", "run2", "run3", "run4", "run5", "run6", "run7", "run8", "run9", "run10" })
  myPlayer.AddAnimation("_Resources_/images/player", "climb", { "climb1", "climb2" })
  myPlayer.AddAnimation("_Resources_/images/player", "climb_idle", { "climb1" })
  myPlayer.PlayAnimation("idle")
  bJumpReady = true
  
  return myPlayer
end

function CreateCoin(pCol, pLin)
  
  local myCoin = CreateSprite("coin", (pCol - 1) * TILESIZE, (pLin - 1) * TILESIZE)
  myCoin.AddAnimation("_Resources_/images/coin", "idle", { "coin1", "coin2", "coin3", "coin4" })
  myCoin.PlayAnimation("idle")
end

function CreateDoor(pCol, pLin)
  
  local myDoor = CreateSprite("door", (pCol - 1) * TILESIZE, (pLin - 1) * TILESIZE)
  myDoor.AddAnimation("_Resources_/images/door", "close", { "door-close" })
  myDoor.AddAnimation("_Resources_/images/door", "open", { "door-open" })
  myDoor.PlayAnimation("close")
end

function OpenDoor()
  
  for nSprite=#lstSprites, 1, -1 do
    
    local sprite = lstSprites[nSprite]
    
    if sprite.type == "door" then
      
      sprite.PlayAnimation("open")
    end
  end
end

function CreatePNJ(pCol, pLin)
  
  local myPNJ = CreateSprite("PNJ", (pCol - 1) * TILESIZE, (pLin - 1) * TILESIZE)
  myPNJ.AddAnimation("_Resources_/images/pnj", "walk", { "walk0", "walk1", "walk2", "walk3", "walk4", "walk5" })
  myPNJ.PlayAnimation("walk")
  myPNJ.direction = "right"
end

function InitGame(pNiveau)
  
  LoadLevel(pNiveau)
end

function love.load()
  
  love.window.setMode(SCREENWIDTH, SCREENHEIGHT)
  love.window.setTitle("Platformer")
  InitGame(1)
  playScreen = true
end

function AlignOnLine(pSprite)
  
  local lig = math.floor((pSprite.y + TILESIZE / 2) / TILESIZE) + 1
  pSprite.y = (lig-1)*TILESIZE
end

function AlignOnColumn(pSprite)
  
  local col = math.floor((pSprite.x + TILESIZE / 2) / TILESIZE) + 1
  pSprite.x = (col - 1) * TILESIZE
end

function updatePlayer(pPlayer, dt)
  
  -- Locals for Physics
  local accel = 350
  local friction = 120
  local maxSpeed = 100
  local jumpSpeed = -190
  
  -- Tile under the player
  local idUnder = getTileAt(pPlayer.x + TILESIZE / 2, pPlayer.y + TILESIZE)
  local idOverlap = getTileAt(pPlayer.x + TILESIZE / 2, pPlayer.y + TILESIZE - 1)
  
  -- Stop Jump?
  if pPlayer.isJumping and (CollideBelow(pPlayer) or isLadder(idUnder)) then
    
    pPlayer.isJumping = false
    pPlayer.standing = true
    AlignOnLine(pPlayer)
  end
  
  -- Friction
  if pPlayer.vx > 0 then
    
    pPlayer.vx = pPlayer.vx - friction * dt
    
    if pPlayer.vx < 0 then
      
      pPlayer.vx = 0 
    end
  end
  if pPlayer.vx < 0 then
    
    pPlayer.vx = pPlayer.vx + friction * dt
    
    if pPlayer.vx > 0 then
      
      pPlayer.vx = 0
    end
  end
  
  local newAnimation = "idle"
  
  -- Keyboard
  if love.keyboard.isDown("right") then
    
    pPlayer.vx = pPlayer.vx + accel * dt
    
    if pPlayer.vx > maxSpeed then
      
      pPlayer.vx = maxSpeed 
    end
    
    pPlayer.flip = false
    newAnimation = "run"
  end
  
  if love.keyboard.isDown("left") then
    
    pPlayer.vx = pPlayer.vx - accel * dt
    if pPlayer.vx < -maxSpeed then
      
      pPlayer.vx = -maxSpeed
    end
    
    pPlayer.flip = true
    newAnimation = "run"
  end
  
  -- Check if the player overlap a ladder
  local isOnLadder = isLadder(idUnder) or isLadder(idOverlap)
  
  if isLadder(idOverlap) == false and isLadder(idUnder) then
    
    pPlayer.standing = true
  end
  
  -- Jump
  if love.keyboard.isDown("up") and pPlayer.standing and bJumpReady and isLadder(idOverlap) == false then
    
    pPlayer.isJumping = true
    pPlayer.gravity = GRAVITY
    pPlayer.vy = jumpSpeed
    pPlayer.standing = false
    bJumpReady = false
  end
  
  -- Climb
  if isOnLadder and pPlayer.isJumping == false then
    
    pPlayer.gravity = 0
    pPlayer.vy = 0
    bJumpReady = false
  end
  
  if isLadder(idUnder) and isLadder(idOverlap) then
    
    newAnimation = "climb_idle"
  end
  
  if love.keyboard.isDown("up") and isOnLadder == true and pPlayer.isJumping == false then
    
    pPlayer.vy = -50
    newAnimation = "climb"
  end
  
  if love.keyboard.isDown("down") and isOnLadder == true then
    
    pPlayer.vy = 50
    newAnimation = "climb"
  end
  
  -- Not climbing
  if isOnLadder == false and pPlayer.gravity == 0 and pPlayer.isJumping == false then
    
    pPlayer.gravity = GRAVITY
  end
  
  -- Ready for next jump
  if love.keyboard.isDown("up") == false and bJumpReady == false and pPlayer.standing == true then
    
    bJumpReady = true
  end
  
  pPlayer.PlayAnimation(newAnimation)
end

function getTileAt(pX, pY)
  
  local col = math.floor(pX / TILESIZE) + 1
  local lig = math.floor(pY / TILESIZE) + 1
  
  if col > 0 and col <= #map[1] and lig > 0 and lig <= #map then
    
    local id = string.sub(map[lig], col, col)
    
    return id
  end
  
  return 0
end

function CollideRight(pSprite)
  
  local id1 = getTileAt(pSprite.x + TILESIZE, pSprite.y + 3)
  local id2 = getTileAt(pSprite.x + TILESIZE, pSprite.y + TILESIZE - 2)
  
  if isSolid(id1) or isSolid(id2) then
    
    return true
  end
  
  return false
end

function CollideLeft(pSprite)
  
  local id1 = getTileAt(pSprite.x - 1, pSprite.y + 3)
  local id2 = getTileAt(pSprite.x - 1, pSprite.y + TILESIZE - 2)
  
  if isSolid(id1) or isSolid(id2) then
    
    return true 
  end
  
  return false
end

function CollideBelow(pSprite)
  
  local id1 = getTileAt(pSprite.x + 1, pSprite.y + TILESIZE)
  local id2 = getTileAt(pSprite.x + TILESIZE - 2, pSprite.y + TILESIZE)
  
  if isSolid(id1) or isSolid(id2) then
    
    return true
  end
  
  if isJumpThrough(id1) or isJumpThrough(id2) then
    
    local lig = math.floor((pSprite.y + TILESIZE / 2) / TILESIZE) + 1
    local yLine = (lig - 1) * TILESIZE
    local distance = pSprite.y - yLine
    
    if distance >= 0 and distance < 10 then
      
      return true
    end
  end
  
  return false
end

function CollideAbove(pSprite)
  
  local id1 = getTileAt(pSprite.x + 1, pSprite.y - 1)
  local id2 = getTileAt(pSprite.x + TILESIZE - 2, pSprite.y - 1)
  
  if isSolid(id1) or isSolid(id2) then
    
    return true
  end
  
  return false
end

function updatePNJ(pSprite, dt)
  
  --Tile behind the sprite
  local idOverlap = getTileAt(pSprite.x + TILESIZE / 2, pSprite.y + TILESIZE - 1)
  
  if idOverlap == ">" then
    
    pSprite.direction = "right"
    pSprite.flip = false
    
  elseif idOverlap == "<" then
    
    pSprite.direction = "left"
    pSprite.flip = true
  end
  
  if pSprite.direction == "right" then
    
    pSprite.vx = 25
    
  elseif pSprite.direction == "left" then
    
    pSprite.vx = -25
    
  end
end

function updateSprite(pSprite, dt)
  
  -- Locals for Collisions
  local oldX = pSprite.x
  local oldY = pSprite.y

  -- Specific behavior for the player
  if pSprite.type == "player" then
    
    updatePlayer(pSprite, dt)
    
  elseif pSprite.type == "PNJ" then
    
    updatePNJ(pSprite, dt)
  end
  
  -- Animation
  if pSprite.currentAnimation ~= "" then
    
    pSprite.animationTimer = pSprite.animationTimer - dt
    if pSprite.animationTimer <= 0 then
      
      pSprite.frame = pSprite.frame + 1
      pSprite.animationTimer = pSprite.animationSpeed
      
      if pSprite.frame > #pSprite.animations[pSprite.currentAnimation] then
        
        pSprite.frame = 1
      end
    end
  end

  -- Collision detection
  local collide = false
  
  -- Above
  if pSprite.vy < 0 then
    
    collide = CollideAbove(pSprite)
    if collide then
      
      pSprite.vy = 0
      AlignOnLine(pSprite)
    end
  end
  
  collide = false
  
  -- Below
  if pSprite.standing or pSprite.vy > 0 then
    
    collide = CollideBelow(pSprite)
    
    if collide then
      
      pSprite.standing = true
      pSprite.vy = 0
      AlignOnLine(pSprite)
      
    else
      if pSprite.gravity ~= 0 then
        
        pSprite.standing = false
      end
    end
  end
  
  collide = false
  
  -- On the right
  if pSprite.vx > 0 then
    
    collide = CollideRight(pSprite)
  end
  
  -- On the left
  if pSprite.vx < 0 then
    
    collide = CollideLeft(pSprite)
  end
  
  -- Stop!
  if collide then
    
    pSprite.vx = 0
    AlignOnColumn(pSprite)
  end
  
  -- Sprite falling
  if pSprite.standing == false then
    
    pSprite.vy = pSprite.vy + pSprite.gravity * dt
  end
  
  -- Move
  pSprite.x = pSprite.x + pSprite.vx * dt
  pSprite.y = pSprite.y + pSprite.vy * dt
end

function love.update(dt)
  
  for nSprite=#lstSprites, 1, -1 do
    
    local sprite = lstSprites[nSprite]
    updateSprite(sprite, dt)
  end
  
  -- Check collision with the player
  for nSprite=#lstSprites, 1, -1 do
    
    local sprite = lstSprites[nSprite]
    
    if sprite.type ~= "player" then
      
      -- Check rectangle collision
      if CheckCollision(player.x, player.y, TILESIZE, TILESIZE, sprite.x, sprite.y, TILESIZE, TILESIZE) then
        
        if sprite.type == "coin" then
          
          table.remove(lstSprites, nSprite)
          level.coins = level.coins - 1
          
          if level.coins == 0 then
            
            -- Open door!
            OpenDoor()
          end
          
        elseif sprite.type == "door" then
          
          if level.coins == 0 then
            
            NextLevel()
            
          end
          
        elseif sprite.type == "PNJ" then
          
          playScreen = false
          deathScreen = true
          
        end
      end
    end
  end  
end

function drawSprite(pSprite)
  
  local imgName = pSprite.animations[pSprite.currentAnimation][pSprite.frame]
  local img = pSprite.images[imgName]
  local halfw = img:getWidth()  / 2
  local halfh = img:getHeight() / 2
  local flipCoef = 1
  
  if pSprite.flip then
    
    flipCoef = -1 
  end
  
  love.graphics.draw(
    img, -- Image
    pSprite.x + halfw, -- horizontal position
    pSprite.y + halfh, -- vertical position
    0, -- rotation (none = 0)
    1 * flipCoef, -- horizontal scale
    1, -- vertical scale (normal size = 1)
    halfw, halfh -- horizontal and vertical offset
    )
end

function love.draw()
  
  if playScreen == true then
    
    love.graphics.scale(3,3)
    
    for l = 1, #map do
      for c = 1, #map[1] do
        
        local char = string.sub(map[l], c, c)
        
        if tonumber(char) ~= 0 and isInvisible(char) == false then
          
          if imgTiles[char] ~= nil then
            
            love.graphics.draw(imgTiles[char], (c - 1)  *TILESIZE, (l - 1) * TILESIZE)
          end
        end
      end
    end
    
    for nSprite=#lstSprites,1,-1 do
      
      local sprite = lstSprites[nSprite]
      drawSprite(sprite)
    end
    
    love.graphics.print("Level "..currentLevel..": "..levels[currentLevel], 5, (TILESIZE * 18) - 3)
  end
  
  if deathScreen == true then
    
    love.graphics.print("you die", (SCREENWIDTH / 2) - 50, (SCREENHEIGHT / 2) - 50, 0, 4)
    love.graphics.print("press space to restart", (SCREENWIDTH / 2) - 40, (SCREENHEIGHT / 2) + 25, 0, 3)
  end
end


function love.keypressed(key)
  
  if key == "escape" then
    
    love.event.quit()
  end
  
  if deathScreen == true then
    
    if key == "space" then
      
      deathScreen = false
      playScreen = true
      for nSprite=#lstSprites, 1, -1 do
        
        local sprite = lstSprites[nSprite]
        
        if sprite.type == "player" then
          
          
          isStart(sprite)
        end
      end
    end
  end
  
  -- display all the key use in the console (useful for debugg)
  --print(key)
end
