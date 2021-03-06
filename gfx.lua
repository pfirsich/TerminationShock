function animNew(image, frames, from, to)
    local anim = {}
    anim.image = image
    anim.time = 0
    anim.from = from
    anim.to = to
    anim.speed = 1.0
    anim.frames = {}
    local frameWidth = image:getWidth()/frames
    for i = from, to do
        anim.frames[#anim.frames+1] = love.graphics.newQuad((i-1)*frameWidth, 0, frameWidth, image:getHeight(), image:getWidth(), image:getHeight())
    end

    return anim
end

function animFrame(anim)
    return math.floor(anim.time * anim.speed) % (anim.to - anim.from) + anim.from
end

function animRelTime(anim)
    return (math.floor(anim.time * anim.speed) % (anim.to - anim.from)) / (anim.to - anim.from)
end

function animDraw(anim, x, y, scale, flipped)
    scale = scale ~= nil and scale or 1.0
    love.graphics.draw(anim.image, anim.frames[animFrame(anim)], x, y, 0, scale * (flipped and -1.0 or 1.0), scale, anim.image:getWidth()/#anim.frames/2.0, anim.image:getHeight()/2)
end

function initGFX()
    astronautScale = 0.5
    astronautImage = love.graphics.newImage("media/images/survivor.png")
    astroHead = love.graphics.newImage("media/images/head.png")
    astroWalk = love.graphics.newImage("media/images/walkingsprite50.png")
    astroFall = love.graphics.newImage("media/images/fallingsprite.png")
    astroIdle = love.graphics.newImage("media/images/idlesprite.png")
    astroJump = love.graphics.newImage("media/images/jumpingsprite.png")

    exitLight = love.graphics.newImage("media/images/light_exit.png")
    astroHeadLight = love.graphics.newImage("media/images/light_head.png")
    astroWalkLight = love.graphics.newImage("media/images/light_walkingsprite.png")
    astroFallLight = love.graphics.newImage("media/images/light_fallingsprite.png")
    astroIdleLight = love.graphics.newImage("media/images/light_idlesprite.png")
    astroJumpLight = love.graphics.newImage("media/images/light_jumpingsprite.png")


    backgrounds = {
        love.graphics.newImage("media/images/Background1.png"),
        love.graphics.newImage("media/images/Background2.png"),
        love.graphics.newImage("media/images/Background3.png"),
    }
    bgSize = {backgrounds[1]:getWidth(), backgrounds[1]:getHeight()}
    bgCountX, bgCountY = math.ceil(love.window.getWidth()/bgSize[1]), math.ceil(love.window.getHeight()/bgSize[2])

    headlightImage = love.graphics.newImage("media/images/headlight.png")
    spotlightImage = love.graphics.newImage("media/images/spot.png")
    lightMapScale = 4
    shadowMesh = love.graphics.newMesh(500, nil, "triangles")

    blurShader = love.graphics.newShader([[
    uniform float bloomStrength = 1.0;
    extern bool horizontal = true;
    const int radius = 5;
    const float gaussKernel[11] = float[11](0.0402,0.0623,0.0877,0.1120,0.1297,0.1362,0.1297,0.1120,0.0877,0.0623,0.0402);

    //const int radius = 7;
    //const float gaussKernel[15] = float[15](0.034619, 0.044859, 0.055857, 0.066833, 0.076841, 0.084894, 0.090126, 0.09194, 0.090126, 0.084894, 0.076841, 0.066833, 0.055857, 0.044859, 0.034619);

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    	vec2 delta;
    	if(horizontal) {
    		delta = vec2(1.0/love_ScreenSize.x, 0.0);
    	} else {
    		delta = vec2(0.0, 1.0/love_ScreenSize.y);
    	}

    	vec2 coord = texture_coords - radius * delta;
    	vec3 col = vec3(0.0);
    	for(int i = 0; i < radius*2 + 1; ++i) {
    		col += gaussKernel[i] * Texel(texture, coord).rgb;
    		coord += delta;
    	}

    	return vec4(col, bloomStrength);
    }]])

    composeShader = love.graphics.newShader([[
    uniform Image lightMap;
    uniform Image noiseMap;
    uniform vec2 noiseOffset;


    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec3 col = mix(Texel(noiseMap, texture_coords + noiseOffset).rgb, Texel(texture, texture_coords).rgb * Texel(lightMap, texture_coords).rgb * 2.2, vec3(0.95));
        return vec4(col, 1.0);
    }
    ]])

    tileSetImage = love.graphics.newImage("media/images/tiles.png")
    tilesX, tilesY = math.floor(tileSetImage:getWidth() / TILESIZE), math.floor(tileSetImage:getHeight() / TILESIZE)
    tileMap = {}
    for y = 0, tilesY - 1 do
        for x = 0, tilesX - 1 do
            tileMap[y*tilesX+x+1] = love.graphics.newQuad(x*(TILESIZE+2)+1, y*(TILESIZE+2)+1, TILESIZE, TILESIZE, tileSetImage:getWidth(), tileSetImage:getHeight())
        end
    end

    love.graphics.setFont(love.graphics.newFont(24))

    reinitGFX()
end

function reinitGFX()
    filmGrainScale = 2.0
    local grainData = love.image.newImageData(love.window.getWidth()/filmGrainScale, love.window.getHeight()/filmGrainScale)
    for y = 0, love.window.getHeight()/filmGrainScale - 1 do
        for x = 0, love.window.getWidth()/filmGrainScale - 1 do
            local col = love.math.random(1, 255)
            grainData:setPixel(x, y, col, col, col, 255)
        end
    end
    filmGrainImage = love.graphics.newImage(grainData)
    filmGrainImage:setWrap("repeat", "repeat")


    albedoCanvas = love.graphics.newCanvas()
    lightMap = love.graphics.newCanvas(love.window.getWidth()/lightMapScale, love.window.getHeight()/lightMapScale)
    lightMapPong = love.graphics.newCanvas(love.window.getWidth()/lightMapScale, love.window.getHeight()/lightMapScale)
end

function drawMap(map)
    local drawRange = {
        {screenToTiles(map, 0, 0)},
        {screenToTiles(map, love.window.getWidth(), love.window.getHeight())}
    }

    for y = drawRange[1][2], drawRange[2][2] do
        for x = drawRange[1][1], drawRange[2][1] do
            local tile = map[y][x]
            if tile ~= nil and tile > 0 then
                if map[y][x] == TILE_INDICES.WALL and map.mapMeta then
                    tile = map.mapMeta[y][x].tile
                    local col = map.mapMeta[y][x].color
                    love.graphics.setColor(col, col, col, 255)
                else
                    love.graphics.setColor(255, 255, 255, 255)
                end
                love.graphics.draw(tileSetImage, tileMap[tile], tileToWorld(x, y))
            end
        end
    end
end

function extrudeShadowEdge(vertices, edgeFrom, edgeTo, from)
    local shadowOffset = 0.0 --0.2 * TILESIZE
    local shadowLength = 10000

    local vertex = function(point, len)
        local relX, relY = point[1] - from[1], point[2] - from[2]
        local relLen = math.sqrt(relX*relX + relY*relY)
        relX, relY = relX/relLen, relY/relLen
        return {point[1] + relX * len, point[2] + relY * len, 0, 0}
    end

    local f = vertex(edgeFrom, shadowOffset) --{edgeFrom[1], edgeFrom[2], 0, 0}
    local t = vertex(edgeTo, shadowOffset) --{edgeTo[1], edgeTo[2], 0, 0}
    local ef = vertex(edgeFrom, shadowLength)
    local et = vertex(edgeTo, shadowLength)

    vertices[#vertices+1] = f
    vertices[#vertices+1] = t
    vertices[#vertices+1] = et

    vertices[#vertices+1] = f
    vertices[#vertices+1] = et
    vertices[#vertices+1] = ef
end

function drawGame(seeall)
    seell = seell or false
    local map = getState().map

    -- light map
    if not seeall then
        camera.push(1.0/lightMapScale)
            love.graphics.setCanvas(lightMap)
            local ambient = 8
            lightMap:clear(ambient, ambient, ambient, 255)
            love.graphics.setBlendMode("additive")
            local headLightScale = 0.9
            love.graphics.setColor(255, 255, 255, 150)
            love.graphics.draw( headlightImage, astronaut.position[1], astronaut.position[2] - astronautImage:getHeight()*0.5 * astronautScale/0.75,
                                vangle(astronaut.aimDirection), headLightScale, headLightScale, 25.0 * astronautScale/0.75, headlightImage:getHeight()*0.5)

            love.graphics.setColor(255, 100, 100, 255)

            local lightDrawPadding = 2.5
            drawRange = {
                {screenToTiles(map, -love.window.getWidth()*lightDrawPadding, -love.window.getHeight()*lightDrawPadding)},
                {screenToTiles(map, (1+lightDrawPadding)*love.window.getWidth(), (1+lightDrawPadding)*love.window.getHeight())}
            }

            for y = drawRange[1][2], drawRange[2][2] do
                for x = drawRange[1][1], drawRange[2][1] do
                    if map.mapMeta[y][x].light and map.mapMeta[y][x].lightStatus then
                        local scale = 0.4
                        local posX, posY = tileToWorld(x, y)
                        posX = posX + TILESIZE/2
                        posY = posY + TILESIZE
                        love.graphics.draw( spotlightImage, posX, posY, math.pi/2.0, math.min(map.mapMeta[y][x].lightHeight, 10), scale, 0.0, spotlightImage:getHeight()*0.5)
                    end

                    if map[y][x] == TILE_INDICES.GOAL then
                        local px, py = tileToWorld(x, y)
                        love.graphics.draw(exitLight, px - TILESIZE, py)
                    end
                end
            end

            drawAstronaut(astronaut.animations[astronaut.currentAnimation .. "_light"], astroHeadLight, {12 * (astronaut.flipped and -1 or 1), -10})

            bodies.drawLight()

            -- draw shadow volumes
            local vertices = {}

            local aimDir = vnormed(astronaut.aimDirection)

            local checkEdge = function(x, y, from, to)
                if y < 1 or x < 1 or y > map.height or x > map.width then return end

                if map[y][x] ~= TILE_INDICES.WALL or true then
                    local normal = vsub(to, from)
                    normal = vnormed({normal[2], -normal[1]})
                    if vdot(normal, aimDir) > 0.0 or true then -- 1337 h4ckz
                        local del = {0, 0} --vmul(normal, 0.2*TILESIZE)
                        extrudeShadowEdge(vertices, vadd(from, del), vadd(to, del), astronaut.position)
                    end
                end
            end

            local drawRange = {
                {screenToTiles(map, 0, 0)},
                {screenToTiles(map, love.window.getWidth(), love.window.getHeight())}
            }


            for y = drawRange[1][2], drawRange[2][2] do
                for x = drawRange[1][1], drawRange[2][1] do
                    local tile = map[y][x]
                    if map[y][x] == TILE_INDICES.WALL then
                        local shadowOffset = 0.15 * TILESIZE
                        local topLeftX, topLeftY = tileToWorld(x, y)
                        local sizeX, sizeY = TILESIZE, TILESIZE

                        if map[y][x-1] ~= TILE_INDICES.WALL then topLeftX = topLeftX + shadowOffset; sizeX = sizeX - shadowOffset end
                        if map[y][x+1] ~= TILE_INDICES.WALL then sizeX = sizeX - shadowOffset end

                        if map[y-1][x] ~= TILE_INDICES.WALL then topLeftY = topLeftY + shadowOffset; sizeY = sizeY - shadowOffset end
                        if map[y+1][x] ~= TILE_INDICES.WALL then sizeY = sizeY - shadowOffset end

                        checkEdge(x  , y+1, {topLeftX, topLeftY + sizeY}, {topLeftX + sizeX, topLeftY + sizeY})
                        checkEdge(x+1, y  , {topLeftX + sizeX, topLeftY + sizeY}, {topLeftX + sizeX, topLeftY})
                        checkEdge(x  , y-1, {topLeftX + sizeX, topLeftY}, {topLeftX, topLeftY})
                        checkEdge(x-1, y  , {topLeftX, topLeftY}, {topLeftX, topLeftY + sizeY})
                    end
                end
            end

            if #vertices > 0 then
                love.graphics.setBlendMode("alpha")
                local shadowColor = 0
                love.graphics.setColor(shadowColor, shadowColor, shadowColor, 255)

                shadowMesh:setVertices(vertices)
                love.graphics.draw(shadowMesh)
            end
        camera.pop()

        -- blur the light map
        love.graphics.setBlendMode("replace")
        love.graphics.setShader(blurShader)

        love.graphics.setCanvas(lightMapPong)
        blurShader:send("horizontal", false)
        love.graphics.draw(lightMap)

        love.graphics.setCanvas(lightMap)
        blurShader:send("horizontal", true)
        love.graphics.draw(lightMapPong)

        -- draw scene and combine
        love.graphics.setCanvas(albedoCanvas)
        albedoCanvas:clear(0, 0, 0, 255)
        love.graphics.setShader()
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(255, 255, 255, 255)
    end

    -- background (all this is sooo bad)
    local middle = vmul({map.width, map.height}, 0.5 * TILESIZE)
    local dx, dy = unpack(vmul(vsub({camera.x, camera.y}, middle), camera.scale * 0.9))

    local xindex, yindex = math.floor(dx/bgSize[1]), math.floor(dy/bgSize[2])
    dx = dx - xindex * bgSize[1]
    dy = dy - yindex * bgSize[2]

    local noise2D = function(x, y)
        return (x + y) % 3 + 1
    end

    for y = -1, bgCountY do
        for x = -1, bgCountX do
            local index = noise2D(x + xindex, y + yindex)
            love.graphics.draw(backgrounds[index], -dx + x * bgSize[1], -dy + y * bgSize[2])
        end
    end

    -- map and players
    camera.push()
        drawMap(map)
        if getState() == spaceship then drawTrapConnections(map) end
        drawTraps(map)
        bodies.draw()

        love.graphics.setColor(255, 100, 100, 100)
        if seeall then love.graphics.circle("fill", astronaut.position[1], astronaut.position[2], astronaut.safeRadius, 64) end
        love.graphics.setColor(255, 255, 255, 255)
        drawAstronaut(astronaut.animations[astronaut.currentAnimation], astroHead)
    camera.pop()

    if not seeall then
        love.graphics.setCanvas()
        love.graphics.setBlendMode("replace")
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.setShader(composeShader)
        composeShader:send("lightMap", lightMap)
        composeShader:send("noiseMap", filmGrainImage)
        composeShader:send("noiseOffset", {love.math.random(), love.math.random()})
        love.graphics.draw(albedoCanvas)
    end

    love.graphics.setBlendMode("alpha")
    love.graphics.setShader()
end

function drawAstronaut(anim, head, offset)
    offset = offset or {0, 0}
    animDraw(anim, astronaut.position[1] + offset[1], astronaut.position[2] + offset[2], astronautScale, astronaut.flipped)
    local xoff = (anim.headOffsetX and anim.headOffsetX(animRelTime(anim)) or 0.0) * astronautScale / 0.75
    local yoff = (anim.headOffsetY and anim.headOffsetY(animRelTime(anim)) or 0.0) * astronautScale / 0.75
    local angle = vangle(astronaut.aimDirection) + (astronaut.flipped and math.pi or 0)
    love.graphics.draw( head, astronaut.position[1] + xoff * (astronaut.flipped and -1.0 or 1.0),
                        astronaut.position[2] - anim.image:getHeight() * astronautScale * 0.4 + yoff,
                        angle, astronautScale * (astronaut.flipped and -1.0 or 1.0), astronautScale, 33, 74)
end




function drawTrapConnections(map)
    local drawRange = {
        {screenToTiles(map, 0, 0)},
        {screenToTiles(map, love.window.getWidth(), love.window.getHeight())}
    }
    love.graphics.setColor(128,255,128,128)
    for t = 1, trapCount do
        local trap = traps[t]
        if trap.trgx ~= trap.tx or trap.trgy ~= trap.ty then
            local tx = trap.trgx
            local ty = trap.trgy
            if trap.tx >= drawRange[1][1] and trap.tx <= drawRange[2][1] or tx >= drawRange[1][1] and tx <= drawRange[2][1] then 
                if trap.ty >= drawRange[1][2] and trap.ty <= drawRange[2][2] or ty >= drawRange[1][2] and ty <= drawRange[2][2] then
                    -- Draw the Line
                    local x1,y1 = tileToWorld(trap.tx+0.5, trap.ty+0.5)
                    local x2,y2 = tileToWorld(tx+0.5, ty+0.5)
                    love.graphics.line(x1,y1,x2,y2)
                end
            end
        end
    end
    love.graphics.setColor(255,255,255,255)
end



function drawTraps(map)
    local drawRange = {
        {screenToTiles(map, 0, 0)},
        {screenToTiles(map, love.window.getWidth(), love.window.getHeight())}
    }

    local img = 0
    local angle = 0
    for t = 1, trapCount do
        local trap = traps[t]
        if trap.active then love.graphics.setColor(255,255,255,255) else love.graphics.setColor(255,255,255,100) end
        if trap.tx >= drawRange[1][1] and trap.tx <= drawRange[2][1] then
            if trap.ty >= drawRange[1][2] and trap.ty <= drawRange[2][2] then
                local tempx, tempy = tileToWorld(trap.tx+0.5, trap.ty+0.5)
                angle = trap.angle
                if getState() == astronaut then
                    -- Astronaut View
                    if trap.hidden then img = false else img = trap.tp.ingameImage end
                else
                    -- Spaceship View
                    img = trap.tp.image
                    if trap.tp.directed then
                        -- Draw Arrow
                        local oldcolor = {love.graphics.getColor()}
                        love.graphics.setColor(255,255,255,128)
                        love.graphics.draw(abilities.directionImage, tempx, tempy, trap.angle, 1.0, 1.0, 128, 145)
                        love.graphics.setColor(oldcolor)
                    end
                    angle = 0
                end
                if img ~= false then
                    love.graphics.draw(img, tempx, tempy, angle, 1.0, 1.0, 128,128)
                else
                    if trap.tp.name == "Fake" then
                        img = abilities[trap.param].ingameImage
                        love.graphics.draw(img, tileToWorld(trap.tx, trap.ty))
                    end
                end
            end
        end
    end
end
