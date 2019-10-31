local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Chess = require "lua_mod/chess/chess"

local ChessMove = Verb:new()


function ChessMove:getMaximumRange(unit, endPos)
    return 15
end


function ChessMove:getTargetType()
    return "all"
end


function ChessMove:getTargets(unit, endPos, strParam)
    Chess.updateMoves()
    return Verb.getTargets(self, unit, endPos, strParam)
end


function ChessMove:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    return Chess.canMoveTo(unit, targetPos)
end


function ChessMove:execute(unit, targetPos, strParam, path)
    local target = Wargroove.getUnitAt(targetPos)
    if target ~= nil then
        target:setHealth(0, unit.id)
        Wargroove.updateUnit(target)
    end
    Wargroove.setUnitState(unit, "moved", "true")

    -- TODO: pawn promotion

    -- TODO: checkmate
end


function ChessMove:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.pos = targetPos
end


return ChessMove
