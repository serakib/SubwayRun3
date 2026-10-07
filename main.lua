local W, H = 960, 640

local state = "menu"
local score = 0
local best = 0
local crystals = 0
local elapsed = 0
local spawnTimer = 0
local crystalTimer = 0
local shake = 0
local stars = {}
local asteroids = {}
local crystalsList = {}
local particles = {}

local player = {
    x = W / 2,
    y = H * 0.78,
    r = 18,
    speed = 360,
    hp = 3,
    invuln = 0
}

local saveFile = "neon_orbit_save.lua"

local function loadSave()
    local chunk = love.filesystem.load(saveFile)
    if chunk then
        local ok, data = pcall(chunk)
        if ok and type(data) == "table" then
            best = tonumber(data.best) or 0
        end
    end
end

local function saveGame()
    local data = "return { best = " .. tostring(math.floor(best)) .. " }\n"
    love.filesystem.write(saveFile, data)
end

local function resetGame()
    state = "playing"
    score = 0
    crystals = 0
    elapsed = 0
    spawnTimer = 0
    crystalTimer = 1.2
    shake = 0
    asteroids = {}
    crystalsList = {}
    particles = {}

    player.x = W / 2
    player.y = H * 0.78
    player.hp = 3
    player.invuln = 0
end

local function makeStars()
    stars = {}
    for i = 1, 100 do
        stars[#stars + 1] = {
            x = math.random() * W,
            y = math.random() * H,
            r = math.random() * 2 + 0.5,
            speed = math.random() * 35 + 12
        }
    end
end

local function spawnAsteroid()
    local r = math.random(14, 34)
    asteroids[#asteroids + 1] = {
        x = math.random(r, W-r),
        y = -r,
        r = r,
        speed = math.random(130, 230) + elapsed * 4,
        rotation = math.random() * math.pi * 2,
        spin = (math.random() - 0.5) * 3
    }
end

local function spawnCrystal()
    crystalsList[#crystalsList + 1] = {
        x = math.random(25, W-25),
        y = -20,
        r = 10,
        speed = math.random(100, 155) + elapsed * 2,
        phase = math.random() * 6.28
    }
end

local function addBurst(x, y, amount, color)
    for i = 1, amount do
        local a = math.random() * math.pi * 2
        local s = math.random(50, 180)
        particles[#particles + 1] = {
            x = x, y = y,
            vx = math.cos(a) * s,
            vy = math.sin(a) * s,
            life = 0.45 + math.random() * 0.45,
            maxLife = 1,
            size = math.random(2, 5),
            color = color
        }
    end
end

local function distance(ax, ay, bx, by)
    local dx, dy = ax-bx, ay-by
    return math.sqrt(dx*dx + dy*dy)
end

local function hitAsteroid(a)
    if player.invuln > 0 then return end
    if distance(player.x, player.y, a.x, a.y) < player.r + a.r * 0.72 then
        player.hp = player.hp - 1
        player.invuln = 1.2
        shake = 0.35
        addBurst(player.x, player.y, 22, {1, 0.25, 0.3})
        if player.hp <= 0 then
            state = "gameover"
            best = math.max(best, math.floor(score))
            saveGame()
        end
        return true
    end
    return false
end

function love.load()
    love.window.setMode(W, H, {resizable=true, vsync=true})
    love.window.setTitle("Neon Orbit")
    love.graphics.setBackgroundColor(0.02, 0.025, 0.08)
    math.randomseed(os.time())
    loadSave()
    makeStars()
end

local function scale()
    local w, h = love.graphics.getDimensions()
    return math.min(w / W, h / H)
end

local function toGame(mx, my)
    local s = scale()
    local ox = (love.graphics.getWidth() - W*s)/2
    local oy = (love.graphics.getHeight() - H*s)/2
    return (mx-ox)/s, (my-oy)/s
end

function love.update(dt)
    local s = scale()
    if s <= 0 then return end

    for _, star in ipairs(stars) do
        star.y = star.y + star.speed * dt
        if star.y > H then
            star.y = -3
            star.x = math.random() * W
        end
    end

    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        p.vx = p.vx * 0.985
        p.vy = p.vy * 0.985
        if p.life <= 0 then table.remove(particles, i) end
    end

    if shake > 0 then shake = shake - dt end
    if state ~= "playing" then return end

    elapsed = elapsed + dt
    score = score + dt * (20 + elapsed * 0.8)

    local moveX, moveY = 0, 0
    if love.keyboard.isDown("left", "a") then moveX = moveX - 1 end
    if love.keyboard.isDown("right", "d") then moveX = moveX + 1 end
    if love.keyboard.isDown("up", "w") then moveY = moveY - 1 end
    if love.keyboard.isDown("down", "s") then moveY = moveY + 1 end

    local len = math.sqrt(moveX*moveX + moveY*moveY)
    if len > 0 then
        moveX, moveY = moveX/len, moveY/len
        player.x = player.x + moveX * player.speed * dt
        player.y = player.y + moveY * player.speed * dt
    end

    player.x = math.max(25, math.min(W-25, player.x))
    player.y = math.max(70, math.min(H-25, player.y))

    if player.invuln > 0 then player.invuln = player.invuln - dt end

    spawnTimer = spawnTimer - dt
    if spawnTimer <= 0 then
        spawnAsteroid()
        spawnTimer = math.max(0.18, 0.65 - elapsed * 0.008)
    end

    crystalTimer = crystalTimer - dt
    if crystalTimer <= 0 then
        spawnCrystal()
        crystalTimer = 1.4 + math.random() * 1.4
    end

    for i = #asteroids, 1, -1 do
        local a = asteroids[i]
        a.y = a.y + a.speed * dt
        a.rotation = a.rotation + a.spin * dt
        if hitAsteroid(a) then
            table.remove(asteroids, i)
        elseif a.y > H + a.r then
            table.remove(asteroids, i)
        end
    end

    for i = #crystalsList, 1, -1 do
        local c = crystalsList[i]
        c.y = c.y + c.speed * dt
        c.phase = c.phase + dt * 4
        if distance(player.x, player.y, c.x, c.y) < player.r + c.r + 4 then
            crystals = crystals + 1
            score = score + 150
            addBurst(c.x, c.y, 14, {0.25, 0.9, 1})
            table.remove(crystalsList, i)
        elseif c.y > H + 30 then
            table.remove(crystalsList, i)
        end
    end
end

local function polygon(cx, cy, radius, sides, rotation)
    local points = {}
    for i = 0, sides-1 do
        local a = rotation + i * math.pi * 2 / sides
        points[#points+1] = cx + math.cos(a) * radius
        points[#points+1] = cy + math.sin(a) * radius
    end
    return points
end

local function drawShip()
    local blink = player.invuln > 0 and math.floor(player.invuln * 12) % 2 == 0
    if blink then return end

    love.graphics.setColor(0.2, 0.9, 1)
    local pts = {
        player.x, player.y-25,
        player.x-17, player.y+20,
        player.x, player.y+12,
        player.x+17, player.y+20
    }
    love.graphics.polygon("fill", pts)

    love.graphics.setColor(0.05, 0.15, 0.25)
    love.graphics.circle("fill", player.x, player.y-5, 7)

    love.graphics.setColor(0.7, 0.95, 1)
    love.graphics.circle("fill", player.x, player.y-5, 4)

    love.graphics.setColor(1, 0.55, 0.12)
    love.graphics.polygon("fill",
        player.x-7, player.y+17,
        player.x, player.y+35+math.random(0,7),
        player.x+7, player.y+17
    )
end

local function drawWorld()
    love.graphics.setColor(0.025,0.03,0.09)
    love.graphics.rectangle("fill",0,0,W,H)

    for _, star in ipairs(stars) do
        love.graphics.setColor(0.5,0.65,0.9,0.65)
        love.graphics.circle("fill",star.x,star.y,star.r)
    end

    love.graphics.setColor(0.08,0.05,0.18,0.7)
    love.graphics.circle("fill",W*0.78,H*0.25,125)

    for _, a in ipairs(asteroids) do
        love.graphics.setColor(0.36,0.38,0.46)
        love.graphics.polygon("fill",polygon(a.x,a.y,a.r,8,a.rotation))
        love.graphics.setColor(0.52,0.55,0.62)
        love.graphics.polygon("line",polygon(a.x,a.y,a.r,8,a.rotation))
    end

    for _, c in ipairs(crystalsList) do
        local pulse=math.sin(c.phase)*2
        love.graphics.setColor(0.25,0.9,1,0.22)
        love.graphics.circle("fill",c.x,c.y,c.r+7+pulse)
        love.graphics.setColor(0.25,0.95,1)
        love.graphics.polygon("fill",
            c.x,c.y-c.r-2,
            c.x+c.r*.8,c.y,
            c.x,c.y+c.r+2,
            c.x-c.r*.8,c.y
        )
    end

    for _, p in ipairs(particles) do
        local alpha=math.max(0,p.life/p.maxLife)
        love.graphics.setColor(p.color[1],p.color[2],p.color[3],alpha)
        love.graphics.circle("fill",p.x,p.y,p.size)
    end

    drawShip()
end

local function panel()
    love.graphics.setColor(0.03,0.07,0.13,0.96)
    love.graphics.rectangle("fill",W/2-260,H/2-175,520,350,22,22)
    love.graphics.setColor(0.12,0.35,0.5,1)
    love.graphics.rectangle("line",W/2-260,H/2-175,520,350,22,22)
end

local titleFont=love.graphics.newFont(58)
local subFont=love.graphics.newFont(22)
local bodyFont=love.graphics.newFont(18)
local buttonFont=love.graphics.newFont(24)

local function centered(text,font,y,color)
    love.graphics.setFont(font)
    love.graphics.setColor(color)
    local tw=font:getWidth(text)
    love.graphics.print(text,(W-tw)/2,y)
end

local function button(text,y,active)
    local x,y0=W/2-145,y
    love.graphics.setColor(active and {0.18,0.85,1} or {0.08,0.17,0.26})
    love.graphics.rectangle("fill",x,y0,290,52,12,12)
    love.graphics.setColor(0.35,0.55,0.65)
    love.graphics.rectangle("line",x,y0,290,52,12,12)
    local col=active and {0.02,0.08,0.12} or {0.9,0.95,1}
    centered(text,buttonFont,y0+12,col)
end

local function drawHUD()
    love.graphics.setColor(0.03,0.08,0.14,0.9)
    love.graphics.rectangle("fill",16,16,W-32,62,14,14)
    love.graphics.setFont(bodyFont)
    love.graphics.setColor(0.9,0.95,1)
    love.graphics.print("SCORE  "..math.floor(score),35,35)
    love.graphics.setColor(0.25,0.95,1)
    love.graphics.print("CRYSTALS  "..crystals,430,35)
    love.graphics.setColor(1,0.82,0.25)
    love.graphics.print("BEST  "..math.floor(best),760,35)

    for i=1,3 do
        local c=(i<=player.hp) and {1,0.25,0.35} or {0.18,0.2,0.25}
        love.graphics.setColor(c)
        love.graphics.circle("fill",35+(i-1)*27,108,9)
    end
end

local function drawMenu()
    panel()
    centered("NEON ORBIT",titleFont,195,{0.85,0.96,1})
    centered("SPACE SURVIVAL",subFont,260,{0.25,0.9,1})
    centered("Dodge asteroids • Collect energy crystals",bodyFont,300,{0.55,0.65,0.75})
    button("START MISSION",350,true)
    centered("WASD / Arrow Keys to fly",bodyFont,425,{0.5,0.6,0.7})
end

local function drawPause()
    panel()
    centered("PAUSED",titleFont,210,{0.9,0.95,1})
    button("RESUME",330,true)
    button("QUIT TO MENU",400,false)
end

local function drawGameOver()
    panel()
    centered("SHIP LOST",titleFont,190,{1,0.45,0.5})
    centered("Score: "..math.floor(score),bodyFont,275,{0.9,0.95,1})
    centered("Crystals: "..crystals,bodyFont,310,{0.25,0.95,1})
    centered("Best: "..math.floor(best),bodyFont,345,{1,0.82,0.25})
    button("TRY AGAIN",395,true)
end

function love.draw()
    local s=scale()
    local ox=(love.graphics.getWidth()-W*s)/2
    local oy=(love.graphics.getHeight()-H*s)/2

    love.graphics.push()
    love.graphics.translate(ox,oy)
    love.graphics.scale(s,s)

    local dx,dy=0,0
    if shake>0 then
        dx=math.random(-4,4)
        dy=math.random(-4,4)
    end
    love.graphics.translate(dx,dy)

    drawWorld()
    drawHUD()

    if state=="menu" then
        drawMenu()
    elseif state=="paused" then
        drawPause()
    elseif state=="gameover" then
        drawGameOver()
    end

    love.graphics.pop()
end

function love.mousepressed(x,y,button)
    if button~=1 then return end
    local gx,gy=toGame(x,y)

    if state=="menu" and gx>W/2-145 and gx<W/2+145 and gy>350 and gy<402 then
        resetGame()
    elseif state=="paused" then
        if gy>330 and gy<382 then
            state="playing"
        elseif gy>400 and gy<452 then
            state="menu"
        end
    elseif state=="gameover" and gx>W/2-145 and gx<W/2+145 and gy>395 and gy<447 then
        resetGame()
    end
end

function love.keypressed(key)
    if key=="escape" or key=="p" then
        if state=="playing" then
            state="paused"
        elseif state=="paused" then
            state="playing"
        end
    end
end
