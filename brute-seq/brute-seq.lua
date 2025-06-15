-- @description brute-seq Drumbrute Impact sequencer for Reaper
-- @author eritiro
-- @license GPL v3
-- @version 0.0.5
-- @provides
--   [main] brute-seq.lua
--   [nomain] Modules/*.lua
--   Images/*.png
--   Fonts/*.ttc

-- General configuration
time_resolution = 4         -- 4 currentPattern.steps per beat (adjust if you changed it)

-- velocity used to add regular notes
local normalVelocity = 100

-- velocity used to add accented notes
local accentVelocity = 127

-- used to understand whether a note is accented. it has to be between the two accent and the normal velocity
local accentThreshold = 110 

local reaper = reaper
script_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]
local modules_path = script_path .. 'Modules/'

-- check dependencies 

if not reaper.APIExists('ImGui_GetVersion') then
    local text = 'This script requires the ReaImGui extension to run. You can install it through ReaPack.'
    reaper.ShowMessageBox(text, 'Error - Missing Dependency', 0)
    return
end


-- requires script_path
dofile(script_path .. 'Modules/GUI.lua')
-- requires time_resolution
dofile(script_path .. 'Modules/Transport.lua')

dofile(script_path .. 'Modules/Storage.lua')

dofile(script_path .. 'Modules/MIDI.lua')

local function passSpacebar(ctx)
    local spaceKey  = reaper.ImGui_Key_Space()
    local CMD_PLAY   = 40044   -- Transport: Play/Stop
    
    if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Space(), false) then
        reaper.Main_OnCommand(CMD_PLAY, 0)
    end
end

local function passThroughShortcuts(ctx)
    passSpacebar(ctx)
end

local Pattern = {}

function Pattern:new(item)
    local obj = {
        item  = item,                      
        steps = getItemSteps(item),
        times = getItemTimes(item),
    }
    return setmetatable(obj, Pattern)
end

local function getPattern(track, index)
    local item = reaper.GetTrackMediaItem(track, index)
    return item and Pattern:new(item) or nil
end

-----------------------------------------------------------------------
-- main loop
-----------------------------------------------------------------------
local followCursor = reaper.GetExtState("BruteSeq", "FollowCursor") == "1"
local loopPattern  = reaper.GetExtState("BruteSeq", "LoopPattern")  == "1"
local loopSong     = reaper.GetExtState("BruteSeq", "LoopSong")     == "1"
local ripple       = reaper.GetExtState("BruteSeq", "Ripple")       == "1"

local currentPatternIndex = 1

local function updateCurrentPatternIndex()
    sequencerTrack = getSequencerTrack()
    local patternCount   = reaper.CountTrackMediaItems(sequencerTrack)
    local itemIndexAtCursor = getItemIndexAtCursor(sequencerTrack)
    if followCursor and itemIndexAtCursor and itemIndexAtCursor ~= currentPatternIndex - 1 then
        currentPatternIndex = itemIndexAtCursor + 1
    else
        currentPatternIndex = math.min(currentPatternIndex, patternCount);        
    end
end

local function updateCursor(currentItem, nextItem)
    if followCursor then
        jumpToItem(currentItem, nextItem)
    end
end

local function updateTimeSelection()
    local sequencerTrack = getSequencerTrack()
    if loopPattern then
        local currentPattern = getPattern(sequencerTrack, currentPatternIndex - 1)
        if currentPattern then
            setTimeSelectionFromItem(currentPattern.item)
        end
    elseif loopSong then
        setTimeSelectionFromTrack(sequencerTrack)
    end
end

local function processPattern(currentPattern, lanes)
    -- Navigation Step Bar
    local currentStepTotal = getCurrentStep(currentPattern.item)
    local currentStep = currentStepTotal and (currentStepTotal % currentPattern.steps) + 1 or -1 
    local currentTime = currentStepTotal and (currentStepTotal // currentPattern.steps) + 1 or -1

    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 2, 2) -- (x,y)
    
    drawTrackLabel(ctx, images.Channel_button_on, "Sequencer")
    for s=1, currentPattern.steps do
        reaper.ImGui_SameLine(ctx)
        local isCurrent = currentStep and s == currentStep
        drawStepCursor(isCurrent)
        
        if reaper.ImGui_IsItemClicked(ctx) then
            jumpToStep(currentPattern.item, s - 1)
        end
    end

    if currentPattern.times > 1 then
        drawTimesSeparator()
        for s=1, currentPattern.times do
            reaper.ImGui_SameLine(ctx)
            local isCurrent = currentTime and s == currentTime
            drawStepCursor(isCurrent)

            if reaper.ImGui_IsItemClicked(ctx) then
                jumpToStep(currentPattern.item, (s - 1) * currentPattern.steps)
            end
        end    
    end
    
    -- Step Grid

    for ti,trk in ipairs(lanes) do
        local id       = '##ch' .. ti
        local selected = false
        local sprite   = selected and images.Channel_button_on
                                    or  images.Channel_button_off

        drawTrackLabel(ctx, sprite, trk.name)
        reaper.ImGui_SameLine(ctx)

        for s=1, currentPattern.steps do
            local stepVelocity = getStepVelocity(currentPattern.item, s, trk.note)
            local active = stepVelocity ~= nil
            local odd    = ((s-1)//4)%2==0
            local accent = active and (stepVelocity > accentThreshold) 

            drawStepButton(active, odd, accent)

            if s < currentPattern.steps then reaper.ImGui_SameLine(ctx) end

            local clicked = reaper.ImGui_IsItemClicked(ctx)
            if clicked then                    
                local shift = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftShift())

                local shouldDelete = active
                local shouldCreate = not active or (shift ~= accent)
                
                if shouldDelete then
                    deleteMidiNote(currentPattern.item, s, trk.note)
                end
                if shouldCreate then
                    local newVelocity = shift and accentVelocity or normalVelocity
                    addMidiNote(currentPattern.item, s, trk.note, newVelocity)
                end
            end
        end
    end
    reaper.ImGui_PopStyleVar(ctx)
end    


-- UI state -----------------------------------------------------------
local editText

local function showLanesConfigPopup()
    local visibleOK = reaper.ImGui_BeginPopupModal(ctx, "Edit Lanes", nil,
                                                reaper.ImGui_WindowFlags_AlwaysAutoResize())
    if visibleOK then
        reaper.ImGui_Text(ctx, "Edit the configuration describing the track lanes:")
        changed, editText = reaper.ImGui_InputTextMultiline(ctx, "##lanesSrc", editText,
                                        480, 260, reaper.ImGui_InputTextFlags_AllowTabInput())

        local valid = validateTextAsLanes(editText)
        if not valid then
            reaper.ImGui_TextColored(ctx, 0xFF4444FF, "Invalid format!")
        end

        if reaper.ImGui_Button(ctx, "OK") then
            if valid then
                lanes = stringToLanes(editText)
                storeLanes(sequencerTrack, lanes)
                reaper.ImGui_CloseCurrentPopup(ctx)
            end
        end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, "Cancel") then
            reaper.ImGui_CloseCurrentPopup(ctx)
        end
        reaper.ImGui_EndPopup(ctx)
    end
    return visibleOK
end

local function addMenuBar()
    local openLanesPopup
    if reaper.ImGui_BeginMenuBar(ctx) then
        if reaper.ImGui_BeginMenu(ctx, "Options") then
            openLanesPopup = reaper.ImGui_MenuItem(ctx, "Configure track lanes")
            reaper.ImGui_EndMenu(ctx)
        end
        reaper.ImGui_EndMenuBar(ctx)
    end
    if openLanesPopup then
        editText = lanesToString(loadLanes(getSequencerTrack()))
        reaper.ImGui_OpenPopup(ctx, "Edit Lanes")
    end
end

local function loop()
    reaper.ImGui_PushFont(ctx,font)
    reaper.ImGui_SetNextWindowSize(ctx,900,420,reaper.ImGui_Cond_FirstUseEver())
    visible, open = reaper.ImGui_Begin(ctx,'BRUTE SEQ',true, reaper.ImGui_WindowFlags_MenuBar())
    if visible then

        local sequencerTrack      = getSequencerTrack()
        local lanes = loadLanes(sequencerTrack)

        local patternCount   = reaper.CountTrackMediaItems(sequencerTrack)
        updateCurrentPatternIndex()
        local currentPattern = getPattern(sequencerTrack, currentPatternIndex - 1)
        local command = nil

        reaper.ImGui_PushStyleColor(ctx,reaper.ImGui_Col_WindowBg(),0x222222FF)
        if currentPattern then            

            addMenuBar()

            -- top bar
            pushToolbarStyles(ctx)

            reaper.ImGui_SameLine(ctx) 
            reaper.ImGui_AlignTextToFramePadding(ctx)
            reaper.ImGui_Text(ctx, 'Pattern:')
            reaper.ImGui_SameLine(ctx)
            changedPattern, currentPatternIndex = drawSlider(ctx, '##Pattern', currentPatternIndex, 1, patternCount, 140)
            reaper.ImGui_SameLine(ctx)
            
            local removePattern = drawButton(ctx, "-")
            local addPattern = drawButton(ctx, "+")
            local dupPattern = drawButton(ctx, "++")

            reaper.ImGui_Text(ctx, 'Steps:')
            reaper.ImGui_SameLine(ctx)
            changedSteps, currentPattern.steps = drawSlider(ctx, '##Length', currentPattern.steps, 1, 64, 140, 4, 4)
            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Text(ctx, 'Times:')
            reaper.ImGui_SameLine(ctx)
            changedTimes, currentPattern.times = drawSlider(ctx, '##Times', currentPattern.times, 1, 32, 140, 4, 4)

            -- draw options
            SameLineAutoWrap(ctx, 1000)
            changedFollowOption, followCursor = reaper.ImGui_Checkbox(ctx, "Follow", followCursor)
            reaper.ImGui_SameLine(ctx)
            changedLoopPatternOption, loopPattern = reaper.ImGui_Checkbox(ctx, "Loop pattern", loopPattern)
            reaper.ImGui_SameLine(ctx)
            changedLoopSongOption, loopSong = reaper.ImGui_Checkbox(ctx, "Loop song", loopSong)
            reaper.ImGui_SameLine(ctx)
            changedRippleOption, ripple = reaper.ImGui_Checkbox(ctx, "Ripple", ripple)
    
            popToolbarStyles(ctx)
            reaper.ImGui_Separator(ctx)

            if isMidi(currentPattern.item) then
                processPattern(currentPattern, lanes)
            else
                reaper.ImGui_AlignTextToFramePadding(ctx)
                reaper.ImGui_Text(ctx, "Non MIDI items are not supported in the sequencer track")                
            end

            -- Update logic

            -- update options in reaper extended state
            if changedFollowOption or changedLoopPatternOption or changedLoopSongOption or changedRippleOption then
                -- ensure loop consistency
                loopSong = loopSong and not changedLoopPatternOption
                loopPattern = loopPattern and not changedLoopSongOption
                reaper.SetExtState("BruteSeq", "FollowCursor", followCursor and "1" or "0", true)
                reaper.SetExtState("BruteSeq", "LoopPattern", loopPattern and "1" or "0", true)
                reaper.SetExtState("BruteSeq", "LoopSong", loopSong and "1" or "0", true)
                reaper.SetExtState("BruteSeq", "Ripple", ripple and "1" or "0", true)
                if changedLoopPatternOption or changedLoopSongOption then
                    updateTimeSelection()
                end
            -- Delete pattern
            elseif removePattern then
                removeItem(currentPattern.item)
                updateCurrentPatternIndex()
                updateTimeSelection()
            -- Add pattern
            elseif addPattern then
                newItem = createItem(sequencerTrack, currentPattern.steps > 0 and currentPattern.steps or 16)
                updateCursor(currentPattern.item, newItem)
                currentPatternIndex = patternCount + 1
                updateTimeSelection()
            elseif dupPattern then
                newItem = createItem(sequencerTrack, currentPattern.steps)
                copyMidiContent(currentPattern.item, newItem)
                updateCursor(currentPattern.item, newItem)
                currentPatternIndex = patternCount + 1
                updateTimeSelection()
            -- Resize pattern
            elseif changedSteps or changedTimes then
                reaper.Undo_BeginBlock()
                local originalLength = reaper.GetMediaItemInfo_Value(currentPattern.item, 'D_LENGTH')
                if changedSteps then
                    resizeSource(currentPattern.item, currentPattern.steps)
                end
                resizeItem(currentPattern.item, currentPattern.times)
                if ripple then
                    rippleFollowingItems(sequencerTrack, currentPattern.item, originalLength)
                end
                updateTimeSelection()
                reaper.Undo_EndBlock('Resize pattern',-1)
            elseif changedPattern then
                nextPattern = getPattern(sequencerTrack, currentPatternIndex - 1)
                updateCursor(currentPattern.item, nextPattern.item)
                updateTimeSelection()
            end
        else -- if currentPattern 
            reaper.ImGui_SameLine(ctx) 
            reaper.ImGui_AlignTextToFramePadding(ctx)
            reaper.ImGui_Text(ctx, "Add a pattern to start")
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, "Add Pattern") then
                createItem(sequencerTrack, 16)
                currentPatternIndex = 1
            end
        end
        reaper.ImGui_PopStyleColor(ctx)
        local popupActive = showLanesConfigPopup()
        if not popupActive then
            passThroughShortcuts(ctx)
        end
        reaper.ImGui_End(ctx)
    end
    reaper.ImGui_PopFont(ctx)
    if open then
        reaper.defer(loop)
    end
end
loop()
