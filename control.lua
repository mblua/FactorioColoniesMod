--game.player[1] = Allways Admin
function isEmpty(value)
    return value == nil or value == ''
end

function getRandomSign()
    if (math.random() < 0.5) then
        return -1
    else
        return 1
    end
end

function getNewPositionRelativeTotalPlayers()
    local randomLimit = global.preferredSpawnDistances * global.totalPlayers
    local randomDistanceX = math.random(randomLimit, randomLimit + global.preferredSpawnDistances) * getRandomSign()
    local randomDistanceY = math.random(randomLimit, randomLimit + global.preferredSpawnDistances) * getRandomSign()
    local x = {}
    x.x = randomDistanceX
    x.y = randomDistanceY
    return x
end

function getPlayersTotal()
    local count = 0
    for index, value in pairs(game.players) do
        count = count + 1
    end
    return count
end

function getPlayersTotalOnline()
    local count = 0
    for index, value in pairs(game.players) do
        if (value.connected) then
            count = count + 1
        end
    end
    return count
end

function getPlayersOnlineNames()
    local names
    local count = 0
    for index, value in pairs(game.players) do
        if (value.connected) then
            count = count + 1
            if (count == 1) then
                names = value.name
            else
                names = names .. "," .. value.name
            end
        end
    end
    return names
end

function tryNewSpawnPoint(player)
    --Setea un lugar nuevo de spawn
    local randomPosition = getNewPositionRelativeTotalPlayers()
    
    
    player.teleport{
        randomPosition.x,
        randomPosition.y
    }
    
    while ((game.surfaces[player.surface.name].get_tile(player.position.x, player.position.y).collides_with("water-tile")) == true)
    do
        
        goodPosition = game.surfaces[1].find_non_colliding_position("player", randomPosition, 0, 1)
        player.teleport{
            goodPosition.x,
            goodPosition.y
        }
    
        player.force.set_spawn_position({
            goodPosition.x,
            goodPosition.y
        }, game.surfaces[1])
    end
    
end

script.on_event(defines.events.on_player_created, function(event)
        --Called after the player was created.Just the first time in multiplayer games.
		local player = game.players[event.player_index]
        
        global.totalPlayers = global.totalPlayers + 1
        
        local newForce = game.create_force("force" .. event.player_index)
        player.force = newForce
		resetPlayerData(event.player_index)
        game.forces["enemy"].set_cease_fire(newForce, true)
        game.forces["player"].set_cease_fire(newForce, false)
        game.forces["neutral"].set_cease_fire(newForce, false)
        tryNewSpawnPoint(player)
        
        initGui(player)        
        player.print({"server-messages.welcome"})
        printHelp(player)
end)

function initGui(player)
    player.gui.left.add{
        type = "frame", caption = {"gui-colonies.main"}, name = "main", direction = "vertical", style = "side_menu_frame_style"
    }
end

script.on_event(defines.events.on_gui_click, function(event)
    local player = game.players[event.player_index]
    if (event.element.name == "main") then
        if (isEmpty(player.gui.left.main.main_restartPlayer)) then
            player.gui.left.main.add{
                type = "button", caption = {"gui-colonies.main_restartPlayer"}, name = "main_restartPlayer"
            }
        else
            player.gui.left.main.main_restartPlayer.destroy()
        end
      --[[  if (isEmpty(player.gui.left.main.main_playersList)) then
            player.gui.left.main.add{
                type = "button", caption = {"gui-colonies.main_playersList"}, name = "main_playersList"
            }
        else
            player.gui.left.main.main_playersList.destroy()
        end]]
        if (isEmpty(player.gui.left.main.main_showHelp)) then
            player.gui.left.main.add{
                type = "button", caption = {"gui-colonies.main_showHelp"}, name = "main_showHelp"
            }
        else
            player.gui.left.main.main_showHelp.destroy()
        end
        return
    end
    if (event.element.name=="main_showHelp") then
        printHelp(player)
        return
    end
    if (event.element.name == "main_restartPlayer") then
        if (isEmpty(player.gui.center.main_restartPlayer_confirmRestart)) then
            player.gui.center.add{
                type = "frame", caption = {"gui-colonies.main_restartPlayer_confirmRestart"}, name = "main_restartPlayer_confirmRestart", direction = "vertical"
            }
            player.gui.center.main_restartPlayer_confirmRestart.add{
                type = "button", caption = {"gui-colonies.main_restartPlayer_confirmRestart_yes"}, name = "main_restartPlayer_confirmRestart_yes"
            }
            player.gui.center.main_restartPlayer_confirmRestart.add{
                type = "button", caption = {"gui-colonies.main_restartPlayer_confirmRestart_no"}, name = "main_restartPlayer_confirmRestart_no"
            }
        end
        return
    end
    
    if (event.element.name == "main_playersList") then
        if (isEmpty(player.gui.center.main_playerList)) then
            player.gui.center.add{
                type = "frame", caption = {"gui-colonies.main_playerList"}, name = "main_playerList", direction = "vertical"
            }
            
            
            for index, value in pairs(game.players) do
                player.gui.center.main_playerList.add{
                    type = "label", caption = value.name, name = "guiCOLONIES" .. index
                }
                
                game.print("x1")
                for index2, value2 in pairs(global.forcesData[value.force.name].totalKills) do
                    game.print("x2.1" .. index2)
                    game.print("x2.2 " .. "main_playerList_totalKills" .. value2)
                    player.gui.center.main_playerList["main" .. index].add{
                        type = "label", caption = value2 .. "-" .. index2, name = "main_playerList_totalKills" .. value2
                    }
                end
                game.print("x3")
            --  global.forcesData[killers.name].totalKills[recentlyDeceasedEntity.name]
            end
        
        else
            player.gui.center.main_playerList.destroy()
        end
        
        return
    end
    
    
    if (event.element.name == "main_restartPlayer_confirmRestart_yes") then
        player.gui.center.main_restartPlayer_confirmRestart.destroy()
        global.playersToRemove = {}
        global.playersToRemove[1] = player
        global.totalPlayers = global.totalPlayers - 1
        player.gui.center.add{
            type = "frame", caption = {"gui-colonies.main_restartPlayer_confirmedMessage"}, name = "main_restartPlayer_confirmedMessage", direction = "vertical"
        }
        player.gui.center.main_restartPlayer_confirmedMessage.add{
            type = "button", caption = {"gui-colonies.main_restartPlayer_confirmedMessage_ok"}, name = "main_restartPlayer_confirmedMessage_ok"
        }
        return
    end
    if (event.element.name == "main_restartPlayer_confirmedMessage_yes") then
        player.gui.center.main_restartPlayer_confirmRestart.destroy()
        return
    end
    if (event.element.name == "main_restartPlayer_confirmRestart_no") then
        player.gui.center.main_restartPlayer_confirmRestart.destroy()
        return
    end
    if (event.element.name == "main_restartPlayer_confirmedMessage_ok") then
        player.gui.center.main_restartPlayer_confirmedMessage.destroy()
        return
    end
    --[[
    if (event.element.name == "notificationMessage_ok") then
        player.gui.center.notificationMessage.destroy()
        return
    end
]]


end)



--Garbage
function showNotificationMessage(playerIndex, messageId)
    if (isEmpty(game.players[playerIndex].gui.center.notificationMessage)) then

        local frame = game.players[playerIndex].gui.center.add{name = "notificationMessage", type = "frame", direction = "horizontal", style="scenario_message_dialog_style"}

        frame.add{
            type = "label", caption = {"gui-colonies.notificationMessage_" .. messageId}, name = "notificationMessage",style="entity_info_label_style"
        }

        

        game.players[playerIndex].gui.center.notificationMessage.add{
            type = "button", caption = {"gui-colonies.notificationMessage_" .. messageId .. "_ok"}, name = "notificationMessage_ok"
        }
    end
    return
end


function printCurrentServerStatus()
    if (isEmpty(getPlayersOnlineNames())) then
        log("****** Players Online/Total " .. getPlayersTotalOnline() .. "/" .. getPlayersTotal() .. " - Online now: none")
        game.print("****** Players Online/Total " .. getPlayersTotalOnline() .. "/" .. getPlayersTotal() .. " - Online now: none")
    else
        log("****** Players Online/Total " .. getPlayersTotalOnline() .. "/" .. getPlayersTotal() .. " - Online now: " .. getPlayersOnlineNames())
        game.print("****** Players Online/Total " .. getPlayersTotalOnline() .. "/" .. getPlayersTotal() .. " - Online now: " .. getPlayersOnlineNames())
    end
end

script.on_event(defines.events.on_player_left_game, function(event)
    log("****** Player " .. game.players[event.player_index].name .. " leave")
    printCurrentServerStatus()
    checkPlayerToRemove()
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    log("****** Player " .. game.players[event.player_index].name .. " joined")
    printCurrentServerStatus()
end)

function resetPlayerData(playerIndex)
    game.print("****** Player " .. game.players[playerIndex].name .. " initialized")
    global.playersData[playerIndex] = {}
    global.forcesData[game.players[playerIndex].force.name] = {}
	global.forcesData[game.players[playerIndex].force.name].totalKills = {}
end



function checkPlayerToRemove()
    if (global.playersToRemove == nil) then
        return
    else
        log("****** Reseting player " .. global.playersToRemove[1].name)
        local playersToRemove = global.playersToRemove
        global.playersToRemove = nil
        game.merge_forces(playersToRemove[1].force.name, game.forces["player"].name)
        game.remove_offline_players(playersToRemove)
        return
    end
end

function printHelp(player)        
    player.print({"briefing-messages.help"})
    player.print({"briefing-messages.reset"})
    player.print({"briefing-messages.natives"})
    player.print({"briefing-messages.humans"})
    player.print({"briefing-messages.victory"})
end

script.on_event(defines.events.on_entity_died, function(event)
    local recentlyDeceasedEntity = event.entity
    local killers = event.force
	
	log("on_entity_died X1: killers.name: " .. killers.name)
	log("on_entity_died X2: recentlyDeceasedEntity.name: " .. recentlyDeceasedEntity.name)
	
	if (killers.name=="enemy") then 
		return
	end
    if recentlyDeceasedEntity.name == "player" then

	else
        game.forces["enemy"].set_cease_fire(killers, false)
    end
    
    --Increment kind total kills
    if (isEmpty(global.gameData[recentlyDeceasedEntity.name])) then
        global.gameData.totalKills[recentlyDeceasedEntity.name] = 0
    end
    global.gameData.totalKills[recentlyDeceasedEntity.name] = global.gameData.totalKills[recentlyDeceasedEntity.name] + 1 
    
    if (isEmpty(global.forcesData[killers.name].totalKills[recentlyDeceasedEntity.name])) then
        global.forcesData[killers.name].totalKills[recentlyDeceasedEntity.name] = 0
    end
    global.forcesData[killers.name].totalKills[recentlyDeceasedEntity.name] = global.forcesData[killers.name].totalKills[recentlyDeceasedEntity.name] + 1
    
    
    if (isEmpty(global.gameData[recentlyDeceasedEntity.name])) then
        global.gameData.totalKills[recentlyDeceasedEntity.name] = 0
    end
    global.gameData.totalKills[recentlyDeceasedEntity.name] = global.gameData.totalKills[recentlyDeceasedEntity.name] + 1




end)

function coloniesInitData()
    log("Colonies 0.0.1 - on init")
    if (isEmpty(global.totalPlayers)) then
        global.totalPlayers = 0
        global.playersData = {}
        global.forcesData = {}
        global.gameData = {}
        global.gameData.totalKills = {}
        global.preferredSpawnDistances = 300
    end
    log("global.totalPlayers: " .. global.totalPlayers)
end

script.on_init(function()
    coloniesInitData()
end)
