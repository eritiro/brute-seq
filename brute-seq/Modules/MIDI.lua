-- @noindex

function getSequencerTrack()
    
    local cur = reaper.GetSelectedTrack(0, 0)
    if cur then
        local _, curName = reaper.GetTrackName(cur, "")
        if curName:lower():match("sequencer$") then 
            -- it is already the right track and selected
            return cur
        end
    end
    local track
    for i = 0, reaper.CountTracks(0) - 1 do
        local t = reaper.GetTrack(0, i)
        local _, name = reaper.GetTrackName(t, "")
        if name:lower():match("sequencer$") then
            track = t
            break
        end
    end
    if not track then                                   -- create it if missing
        local idx = reaper.CountTracks(0)
        reaper.InsertTrackAtIndex(idx, true)
        track = reaper.GetTrack(0, idx)
        reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "Sequencer", true)
    end
    return track
end

function createItem(track, steps)
    local beatsInSec  = reaper.TimeMap2_beatsToTime(0, 1)
    local itemLength  = (steps / time_resolution) * beatsInSec

    -- place new pattern right after the last item (or at 0.0 if none)
    local lastPos = 0
    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
        local it  = reaper.GetTrackMediaItem(track, i)
        local pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
        if pos + len > lastPos then lastPos = pos + len end
    end

    local newItem = reaper.CreateNewMIDIItemInProj(track, lastPos, lastPos + itemLength, false)

    local take     = reaper.GetMediaItemTake(newItem, 0)
    local patNum   = reaper.CountTrackMediaItems(track)          -- simple increment
    reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "Pattern " .. patNum, true)

    reaper.UpdateArrange()

    return newItem
end

function copyMidiContent(srcItem, dstItem)
    local srcTake = reaper.GetActiveTake(srcItem)
    local dstTake = reaper.GetActiveTake(dstItem)
    -- read whole event stream from the source take
    local _, midiData = reaper.MIDI_GetAllEvts(srcTake, "")

    -- wipe any existing events in the destination take
    reaper.MIDI_SetAllEvts(dstTake, midiData) -- paste
    reaper.MIDI_Sort(dstTake)                 -- keep PPQ order

    reaper.UpdateArrange()
end

function removeItem(item)
    reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(item), item)
    reaper.UpdateArrange()    
end

local function getSourceQnFromItem(item)
    local take = reaper.GetActiveTake(item)
    local src = reaper.GetMediaItemTake_Source(take)
    return reaper.GetMediaSourceLength(src)
end

-- assumes fixed BPM through the item 
local function getItemQn(item)
    local start  = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local len    = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local bpm     = reaper.TimeMap_GetDividedBpmAtTime(start) 
    return len * bpm / 60        -- seconds → beats
end

function getItemSteps(item)
    return math.floor(getSourceQnFromItem(item) * time_resolution)
end

function getItemTimes(item)
    local sourceQn = getSourceQnFromItem(item)
    local itemQn = getItemQn(item)

    return math.floor(itemQn / sourceQn  + 0.5)
end

function resizeSource(item, newSteps)
    local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local qnStart = reaper.TimeMap_timeToQN(itemStart)
    reaper.MIDI_SetItemExtents(item, qnStart, qnStart + newSteps / time_resolution)
end

function resizeItem(item, times)
    local start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local bpm = reaper.TimeMap_GetDividedBpmAtTime(start) 
    local sourceQn = getSourceQnFromItem(item)
    
    local newLen = times * sourceQn * 60 / bpm 
    reaper.SetMediaItemInfo_Value(item,'D_LENGTH', newLen)
    reaper.SetMediaItemInfo_Value(item,'B_LOOPSRC', 1)
end

function rippleFollowingItems(track, item, originalLength)
    local start  = reaper.GetMediaItemInfo_Value(item,'D_POSITION')
    local amount = reaper.GetMediaItemInfo_Value(item,'D_LENGTH') - originalLength

    local items = {}
    for i=0, reaper.CountTrackMediaItems(track)-1 do
        local it = reaper.GetTrackMediaItem(track,i)
        if it ~= item then
            items[#items+1] = it
        end
    end
    table.sort(items, function(a,b)
        return reaper.GetMediaItemInfo_Value(a,'D_POSITION')
             < reaper.GetMediaItemInfo_Value(b,'D_POSITION')
    end)

    for _,it in ipairs(items) do
        local pos = reaper.GetMediaItemInfo_Value(it,'D_POSITION')
        if pos > start then
            reaper.SetMediaItemInfo_Value(it,'D_POSITION', pos + amount)
        end
    end
end

function getStepVelocity(item, stepIdx, pitch)
    local take = reaper.GetActiveTake(item)  

    local itemPos   = reaper.GetMediaItemInfo_Value(item,'D_POSITION')
    local secPerBt  = reaper.TimeMap2_beatsToTime(0,1)
    local stepSize  = secPerBt / time_resolution
    local tgtStart  = itemPos + (stepIdx-1) * stepSize
    local tol       = 0.0001  -- ~0.1 ms

    local ppqLo = reaper.MIDI_GetPPQPosFromProjTime(take, tgtStart - tol)
    local ppqHi = reaper.MIDI_GetPPQPosFromProjTime(take, tgtStart + tol)

    local _, noteCnt = reaper.MIDI_CountEvts(take)
    for i = 0, noteCnt-1 do
        local _,_,_, ppq,_,_, nPitch, nVel = reaper.MIDI_GetNote(take,i)
        if nPitch == pitch and ppq >= ppqLo and ppq <= ppqHi then
            return nVel
        end
    end
    return nil
end

function addMidiNote(item, stepIdx, note, velocity)
    local take = reaper.GetActiveTake(item)

    local itemPos   = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local secPerBt  = reaper.TimeMap2_beatsToTime(0, 1)
    local stepSize  = secPerBt / time_resolution
    local notePos   = itemPos + (stepIdx-1) * stepSize
    local noteEnd   = notePos + stepSize

    local ppqStart  = reaper.MIDI_GetPPQPosFromProjTime(take, notePos)
    local ppqEnd    = reaper.MIDI_GetPPQPosFromProjTime(take, noteEnd)
    reaper.MIDI_InsertNote(take, false,false, ppqStart, ppqEnd,
                           0, note, velocity, true)
    reaper.MIDI_Sort(take)
end

function deleteMidiNote(item, stepIdx, note)
    local take = reaper.GetActiveTake(item)

    local itemPos   = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local secPerBt  = reaper.TimeMap2_beatsToTime(0, 1)
    local stepSize  = secPerBt / time_resolution
    local notePos   = itemPos + (stepIdx-1) * stepSize
    local tolerance = 0.0001                          -- ~0.1 ms

    local ppqStart  = reaper.MIDI_GetPPQPosFromProjTime(take, notePos - tolerance)
    local ppqEnd    = reaper.MIDI_GetPPQPosFromProjTime(take, notePos + tolerance)

    local _, noteCnt = reaper.MIDI_CountEvts(take)
    for i = noteCnt-1, 0, -1 do
        local _,sel,mut,s_ppq,e_ppq,chan,pitch,vel = reaper.MIDI_GetNote(take,i)
        if pitch == note and s_ppq >= ppqStart and s_ppq <= ppqEnd then
            reaper.MIDI_DeleteNote(take,i)
        end
    end
    reaper.MIDI_Sort(take)
end

function isMidi(item)
    take = reaper.GetActiveTake(item)
    return take and reaper.TakeIsMIDI(take)
end
