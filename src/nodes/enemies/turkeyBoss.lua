local Enemy = require 'nodes/enemy'
local gamestate = require 'vendor/gamestate'
local Timer = require 'vendor/timer'
local Projectile = require 'nodes/projectile'
local sound = require 'vendor/TEsound'

return {
    name = 'turkeyBoss',
    attack_sound = 'gobble_boss',
    height = 115,
    width = 215,
    damage = 4,
    jumpkill = false,
    last_jump = 0,
    bb_width = 75,
    bb_height = 105,
    bb_offset = { x = -50, y = 10},
    velocity = {x = 0, y = 1},
    hp = 50,
    tokens = 15,
    hand_x = -40,
    hand_y = 70,
    tokenTypes = { -- p is probability ceiling and this list should be sorted by it, with the last being 1
        { item = 'coin', v = 1, p = 0.9 },
        { item = 'health', v = 1, p = 1 }
    },
    animations = {
        jump = {
            right = {'loop', {'3-4,2'}, 0.25},
            left = {'loop', {'3-4,3'}, 0.25}
        },
        default = {
            right = {'loop', {'1-2,2'}, 0.25},
            left = {'loop', {'1-2,3'}, 0.25}
        },
        dying = {
            right = {'once', {'1-4,2'}, 0.25},
            left = {'once', {'1-4,3'}, 0.25}
        },
        enter = {
            right = {'once', {'1,4'}, 0.25},
            left = {'once', {'1,4'}, 0.25}
        },
        hatch = {
            right = {'once', {'2-3,4','1-3,1'}, 0.25},
            left = {'once', {'2-3,4','1-3,1'}, 0.25}
        },
    },
    enter = function( enemy )
        enemy.direction = math.random(2) == 1 and 'left' or 'right'
        enemy.state = 'enter'
        enemy.hatched = false
    end,
    die = function( enemy )
        local NodeClass = require('nodes/key')
        local node = {
                    type = 'key',
                    name = 'white_crystal',
                    x = enemy.node.x + enemy.width/2 - 12,
                    y = enemy.node.y + enemy.height - 24,
                    width = 24,
                    height = 24,
                    properties = {},
                    }
        local spawnedNode = NodeClass.new(node, enemy.collider)
        spawnedNode.position.x = enemy.position.x + enemy.width/2
        spawnedNode.position.y = enemy.position.y + enemy.height - spawnedNode.height
        local level = gamestate.currentState()
        level:addNode(spawnedNode)
    end,
    attackBasketball = function( enemy )
        local node = {
            type = 'projectile',
            name = 'basketball',
            x = enemy.position.x,
            y = enemy.position.y,
            width = 18,
            height = 16,
            properties = {}
        }
        local basketball = Projectile.new( node, enemy.collider )
        basketball.enemyCanPickUp = true
        local level = enemy.containerLevel
        level:addNode(basketball)

        enemy:registerHoldable(basketball)
        enemy:pickup()
        
        enemy.currently_held:launch(enemy)

        basketballenemyCanPickUp = false
    end,
    update = function( dt, enemy, player, level )
        if enemy.dead then
            return
        end
        
        local direction = player.position.x > enemy.position.x and -1 or 1
        
        if enemy.velocity.y > 1 and not enemy.hatched then
            enemy.state = 'enter'
        elseif math.abs(enemy.velocity.y) < 1 and not enemy.hatched then
            enemy.state = 'hatch'
            Timer.add(2, function() enemy.hatched = true end)
        elseif enemy.hatched then
            
        enemy.last_jump = enemy.last_jump + dt
        
        local pause = 1.0
        
        if enemy.hp < 20 then
            pause = 0.5
        end
        
        if enemy.last_jump > pause+math.random() then
            enemy.props.attackBasketball(enemy)
            enemy.state = 'jump'
            enemy.last_jump = 0
            enemy.velocity.y = -math.random(300,800)
            enemy.direction = math.random(2) == 1 and 'right' or 'left'
        end
        if enemy.velocity.y == 0 and enemy.hatched then
            enemy.state = 'default'
        end
         
        end

    end    
}