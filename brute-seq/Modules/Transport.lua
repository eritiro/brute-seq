-- @noindex

function setTimeSelectionFromItem(item)
    local startPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local length   = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local endPos   = startPos + length

    reaper.GetSet_LoopTimeRange(true,  true,  startPos, endPos, false)
end

function setTimeSelectionFromTrack(track)

    local itemCnt = reaper.CountTrackMediaItems(track)
    if itemCnt == 0 then return end

    local firstStart = math.huge
    local lastEnd    = 0

    for i = 0, itemCnt - 1 do
        local it    = reaper.GetTrackMediaItem(track, i)
        local start = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
        local len   = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
        if start < firstStart       then firstStart = start end
        if start + len > lastEnd    then lastEnd    = start + len end
    end

    reaper.GetSet_LoopTimeRange(true, true, firstStart, lastEnd, false)
end

function getCursorPos()
    return (reaper.GetPlayState() & 1 == 1) and
           reaper.GetPlayPosition() or
           reaper.GetCursorPosition()
end

function getCurrentStep(item)
    if not item then return nil end

    local pos       = getCursorPos()
    local startPos  = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local endPos    = startPos + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    if pos < startPos or pos >= endPos then return nil end

    local stepSize  = reaper.TimeMap2_beatsToTime(0, 1) / time_resolution
    return math.floor((pos - startPos) / stepSize)
end

function jumpToStep(item, stepIdx)
    local startPos   = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local secPerBeat = reaper.TimeMap2_beatsToTime(0, 1)
    local stepSize   = secPerBeat / time_resolution
    local targetPos  = startPos + stepIdx * stepSize

    reaper.SetEditCurPos(targetPos, true, true)
end

function jumpToItem(currentItem, nextItem)
    local playing = reaper.GetPlayState() & 1 == 1
    local currentStart = reaper.GetMediaItemInfo_Value(currentItem, 'D_POSITION')
    local nextStart = reaper.GetMediaItemInfo_Value(nextItem, 'D_POSITION')
    
    -- it only offsets the item when playing
    local offset = playing and (reaper.GetPlayPosition2() - currentStart) or 0

    reaper.SetEditCurPos(nextStart + offset, true, true)
end

function getItemIndexAtCursor(track)
    local curPos = getCursorPos()
    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
        local it     = reaper.GetTrackMediaItem(track, i)
        local start  = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
        if curPos >= start and curPos < start + length then
            return i
        end
    end
    return nil
end