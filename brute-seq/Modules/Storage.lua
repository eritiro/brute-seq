-- @noindex

local serpent = dofile(script_path .. 'Modules/serpent.lua')

local defaultLanes = {
    { name = "Kick",        note = 36 },  -- C2
    { name = "Snare 1",     note = 37 },
    { name = "Snare 2",     note = 38 },
    { name = "Tom High",    note = 39 },
    { name = "Tom Low",     note = 40 },
    { name = "Cymbal",      note = 41 },
    { name = "Cowbell",     note = 42 },
    { name = "Closed Hat",  note = 43 },
    { name = "Open Hat",    note = 44 },
    { name = "FM Drum",     note = 45 },
}

function lanesToString(tracks)
    return serpent.block(tracks, {
        comment = false,
        compact = false,
        indent  = "    ",
        sortkeys = true,
        nocode = true
    })
end

function stringToLanes(str)
    local ok, tbl = serpent.load(str)
    if ok and type(tbl) == "table" then 
        return tbl
    else
        return nil 
    end
end

function validateTextAsLanes(text)
    local tbl = stringToLanes(text)
    if not tbl then return false, nil end

    -- Now validate structure:
    local count = 0
    for k, v in pairs(tbl) do
        if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
            return false, nil  -- not an array
        end
        if type(v) ~= "table" then return false, nil end
        if type(v.name) ~= "string" then return false, nil end
        if type(v.note) ~= "number" then return false, nil end
        count = count + 1
    end

    -- Optional: check no gaps
    for i = 1, count do
        if tbl[i] == nil then return false, nil end
    end

    return true, tbl
end

function storeLanes(track, tbl)
    local s = lanesToString(tbl)
    reaper.GetSetMediaTrackInfo_String(track, "P_EXT:BruteSeqTracks", s, true)
end

function loadLanes(sequencerTrack)
    local ok, s = reaper.GetSetMediaTrackInfo_String(sequencerTrack, "P_EXT:BruteSeqTracks", "", false)
    if not ok or s == "" then
        return defaultLanes
    end
    local tbl = stringToLanes(s)
    return tbl or defaultLanes
end
