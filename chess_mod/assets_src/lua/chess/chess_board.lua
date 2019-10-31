local ChessBoard = {}


local knightMoves = {
    { x =  2, y =  1},
    { x =  2, y = -1},
    { x = -2, y =  1},
    { x = -2, y = -1},
    { x =  1, y =  2},
    { x =  1, y = -2},
    { x = -1, y =  2},
    { x = -1, y = -2}
 }


 local directions = {
     { x = 1, y = 0 },
     { x = 1, y = 1 },
     { x = 0, y = 1 },
     { x = -1, y = 1 },
     { x = -1, y = 0 },
     { x = -1, y = -1 },
     { x = 0, y = -1 },
     { x = 1, y = -1 }
 }


local function posToIdx(pos)
    if pos.x < 0 or pos.y < 0 or pos.x >= 8 or pos.y >= 8 then
        return -1
    end
    return pos.x + 8 * pos.y
end


function ChessBoard:addPiece(piece)
    local idx = posToIdx(piece.pos)
    self[idx] = piece
end


function ChessBoard:findMoves()
    local moves = {}
    for idx, u in pairs(self) do
        moves[u.id] = self:findPieceMoves(u)
    end
    return moves
end


function ChessBoard:findPieceMoves(piece)
    local pieceMoves = {}

    if piece.type == "chess_pawn" then
        self:findPawnMoves(piece, pieceMoves)
    elseif piece.type == "chess_knight" then
        self:findKnightMoves(piece, pieceMoves)
    elseif piece.type == "chess_king" then
        self:findKingMoves(piece, pieceMoves)
    elseif piece.type == "chess_bishop" then
        self:findGenericMoves(piece, pieceMoves, 8, false, true)
    elseif piece.type == "chess_rook" then
        self:findGenericMoves(piece, pieceMoves, 8, true, false)
    elseif piece.type == "chess_queen" then
        self:findGenericMoves(piece, pieceMoves, 8, true, true)
    end

    -- Ensure that no moves result in check for current player
    local validMoves = {}
    for i, move in ipairs(pieceMoves) do
        local newBoard = self:copyWithMove(piece.id, move)
        if not newBoard:isInCheck(piece.player) then
            table.insert(validMoves, move)
        end
    end

    return validMoves
end


function ChessBoard:isEmpty(pos)
    if pos.x < 0 or pos.y < 0 or pos.x >= 8 or pos.y >= 8 then
        return false
    end
    return self[posToIdx(pos)] == nil
end


function ChessBoard:hasPieceOf(pos, player)
    local u = self[posToIdx(pos)]
    return u ~= nil and u.player == player
end


function ChessBoard:moveOnly(piece, pos, moves)
    if self:isEmpty(pos) then
        table.insert(moves, pos)
        return true
    end
    return false
end


function ChessBoard:captureOnly(piece, pos, moves)
    if self:hasPieceOf(pos, 1 - piece.player) then
        table.insert(moves, pos)
    end
    return false
end


function ChessBoard:moveOrCapture(piece, pos, moves)
    if self:isEmpty(pos) then
        table.insert(moves, pos)
        return true
    elseif self:hasPieceOf(pos, 1 - piece.player) then
        table.insert(moves, pos)
    end
    return false
end


function ChessBoard:findPawnMoves(piece, moves)
    local dir = 1
    if piece.player == 1 then
        dir = -1
    end

    self:moveOnly(piece, { x = piece.pos.x, y = piece.pos.y + dir }, moves)
    if piece.moved == false then
        self:moveOnly(piece, { x = piece.pos.x, y = piece.pos.y + dir * 2 }, moves)
    end
    self:captureOnly(piece, { x = piece.pos.x - 1, y = piece.pos.y + dir }, moves)
    self:captureOnly(piece, { x = piece.pos.x + 1, y = piece.pos.y + dir }, moves)

    -- TODO: en passant capture
end


function ChessBoard:findKnightMoves(piece, moves)
    local p = piece.pos
    for _, m in ipairs(knightMoves) do
        self:moveOrCapture(piece, { x = p.x + m.x, y = p.y + m.y }, moves)
    end
end


function ChessBoard:findKingMoves(piece, moves)
    -- TODO: castling
    
    return self:findGenericMoves(piece, moves, 1, true, true)
end


function ChessBoard:findLineMovement(piece, moves, range, delta)
    local pos = piece.pos
    for i = 1, range do
        local p = { x = pos.x + delta.x * i, y = pos.y + delta.y * i }
        if not self:moveOrCapture(piece, p, moves) then
            break
        end
    end
end


function ChessBoard:findGenericMoves(piece, moves, range, cardinal, diagonal)
    if cardinal then
        self:findLineMovement(piece, moves, range, { x = 1, y = 0})
        self:findLineMovement(piece, moves, range, { x = -1, y = 0})
        self:findLineMovement(piece, moves, range, { x = 0, y = 1})
        self:findLineMovement(piece, moves, range, { x = 0, y = -1})
    end
    if diagonal then
        self:findLineMovement(piece, moves, range, { x = 1, y = 1})
        self:findLineMovement(piece, moves, range, { x = 1, y = -1})
        self:findLineMovement(piece, moves, range, { x = -1, y = 1})
        self:findLineMovement(piece, moves, range, { x = -1, y = -1})
    end
end


function ChessBoard:copy()
    local c = ChessBoard:new()
    for k, v in pairs(self) do
        c[k] = { id = v.id, pos = { x = v.pos.x, y = v.pos.y }, type = v.type, player = v.player, moved = v.moved }
    end
    return c
end


function ChessBoard:doMove(pieceId, move)
    for k, v in pairs(self) do
        if v.id == pieceId then
            v.pos = { x = move.x, y = move.y }
            self[k] = nil
            self[posToIdx(v.pos)] = v
            break
        end
    end
end


function ChessBoard:copyWithMove(pieceId, move)
    local c = self:copy()
    c:doMove(pieceId, move)
    return c
end


function ChessBoard:isInCheck(player)
    for k, v in pairs(self) do
        if v.player == player and v.type == "chess_king" then
            return ChessBoard:isPositionAttackedByPlayer(v.pos, 1 - player)
        end
    end

    return false
end


function ChessBoard:findFirstPiece(pos, dir)
    local p = { pos.x, pos.y }
    for i = 1, 8 do
        p.x = p.x + dir.x
        p.y = p.y + dir.y
        local piece = self[posToIdx(p)]
        if piece ~= nil then
            return piece, i
        end
    end
    return nil, 0
end


function ChessBoard:isPositionAttackedByPlayer(pos, player)
    -- Check knights
    for _, m in ipairs(knightMoves) do
        local p = { x = pos.x + m.x, y = pos.y + m.y }
        local piece = self[posToIdx(p)]
        if piece ~= nil and piece.player == player and piece.type == "chess_knight" then
            return true
        end
    end

    -- Checks bishops, rooks, queens and kings
    for _, dir in ipairs(directions) do
        local piece = nil
        local dist = 0
        piece, dist = self:findFirstPiece(pos, dir)
        if piece ~= nil and piece.player == player then
            if piece.type == "chess_queen" then
                return true
            elseif piece.type == "chess_rook" then
                if dir.x == 0 or dir.y == 0 then
                    return true
                end
            elseif piece.type == "chess_bishop" then
                if dir.x ~= 0 and dir.y ~= 0 then
                    return true
                end
            elseif piece.type == "chess_king" then
                if dist == 1 then
                    return true
                end
            end
        end
    end

    -- Checks pawns
    local pawnDir = 1
    if player == 0 then
        pawnDir = -1
    end
    for i = -1, 1, 2 do
        local p = { x = pos.x + 1, y = pos.y + pawnDir }
        local piece = self[posToIdx(p)]
        if piece ~= nil and piece.player == player and piece.type == "chess_pawn" then
            return true
        end
    end

    return false
end


function ChessBoard:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


return ChessBoard
