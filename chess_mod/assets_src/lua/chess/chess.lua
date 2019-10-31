local Wargroove = require "wargroove/wargroove"
local ChessBoard = require "wargroove/chess_board"

local Chess = {}

local moves = {}
local masterUnit = nil
local origin = nil


local function globalToLocal(pos)
    return { x = pos.x - origin.x, y = 7 - (pos.y - origin.y) }
end


local function localToGlobal(pos)
    return { x = pos.x + origin.x, y = (7 - pos.y) + origin.y }
end


function Chess.updateMoves()
    Chess.updateOrigin()

    -- Create a board for the current state
    local board = ChessBoard:new()
    for playerId = 0, 1 do
        for i, u in ipairs(Wargroove.getAllUnitsForPlayer(playerId, true)) do
            local moved = Wargroove.getUnitState(u, "moved") == "true"
            board:addPiece({ id = unit.id, type = unit.unitClassId, player = playerId, pos = globalToLocal(u.pos), moved = moved })
        end
    end

    -- Find all valid moves
    moves = board:findMoves()

    -- Offset moves by origin
    for i, unitMoves in ipairs(moves) do
        for j, move in ipair(unitMoves) do
            move = localToGlobal(move)
        end
    end
end


function Chess.updateOrigin()
    -- Player 1's king is the master unit - all global state will be stored there
    if masterUnit == nil then
        for i, u in ipairs(Wargroove.getAllUnitsForPlayer(playerId, true)) do
            if u.unitClassId == "chess_king" then
                masterUnit = u
                break
            end
        end
    end

    -- If origin hasn't been set yet, do it. Otherwise, retrieve it.
    if origin == nil then
        if Wargroove.getUnitState(masterUnit, "originX") == nil then
            -- Origin will be the smallest X,Y coordinates found
            local x = 9999
            local y = 9999
            for playerId = 0, 1 do
                for i, u in ipairs(Wargroove.getAllUnitsForPlayer(playerId, true)) do
                    x = math.min(x, u.pos.x)
                    y = math.min(y, u.pos.y)
                end
            end
            origin.x = x
            origin.y = y
            Wargroove.setUnitState(masterUnit, "originX", tostring(x))
            Wargroove.setUnitState(masterUnit, "originY", tostring(y))
        else
            origin.x = tonumber(Wargroove.getUnitState(masterUnit, "originX"))
            origin.y = tonumber(Wargroove.getUnitState(masterUnit, "originY"))
        end
    end
end


function Chess.canMoveTo(unit, targetPos)
    if moves[unit.id] == nil then
        return false
    else
        for i, v in ipairs(moves[unit.id]) do
            if v.x == targetPos.x and v.y == targetPos.y then
                return true
            end
        end
        return false
    end
end


return Chess