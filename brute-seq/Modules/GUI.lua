-- @noindex

-- config
local fontSize = 12


ctx  = reaper.ImGui_CreateContext('Sequencer')
local fonts_path  = script_path .. 'Fonts/'
local images_path = script_path .. 'Images/'

-----------------------------------------------------------------------
-- Load fonts
-----------------------------------------------------------------------

font = reaper.ImGui_CreateFont(fonts_path .. 'Inter.ttc', fontSize)
local fontBigger = reaper.ImGui_CreateFont(fonts_path .. 'Inter.ttc', fontSize + 4)
local fontSmall = reaper.ImGui_CreateFont(fonts_path .. 'Inter.ttc', fontSize - 1)
reaper.ImGui_Attach(ctx, font)
reaper.ImGui_Attach(ctx, fontBigger)
reaper.ImGui_Attach(ctx, fontSmall)

-----------------------------------------------------------------------
-- Load all images (png) in Images/
-----------------------------------------------------------------------

local function loadImages(dir)
  local t,i = {},0
  while true do
    local f = reaper.EnumerateFiles(dir,i)
    if not f then break end
    local key = f:match('(.+)%.png$')
    if key then
      local img = reaper.ImGui_CreateImage(dir..f)
      reaper.ImGui_Attach(ctx, img)
      local w,h = reaper.ImGui_Image_GetSize(img)
      t[key] = {i=img,w=w,h=h}
    end
    i=i+1
  end
  return t
end

images = loadImages(images_path)

-----------------------------------------------------------------------
-- helper: chose step between odd/even + on/off
-----------------------------------------------------------------------

local function stepSprite(on,odd, accent)
  if on  then 
    if accent then
      return odd and images.Step_odd_accent.i  or images.Step_even_accent.i
    else
      return odd and images.Step_odd_on.i  or images.Step_even_on.i
    end
  end
  return odd and images.Step_odd_off.i or images.Step_even_off.i
end
local cellW,cellH = images.Step_odd_off.w, images.Step_odd_off.h

local buttonColor = 0x2f2f34ff
local activeButtonColor = 0x576065ff
local slideBackgroundColor = 0x060607ff

function pushToolbarStyles(ctx)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 4, 4)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(), buttonColor)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(), activeButtonColor)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), slideBackgroundColor)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), slideBackgroundColor)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), slideBackgroundColor)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), buttonColor) 
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), buttonColor) 
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), activeButtonColor)
end

function popToolbarStyles(ctx)
    reaper.ImGui_PopStyleColor(ctx, 8)
    reaper.ImGui_PopStyleVar(ctx, 1)
end

function drawSlider(ctx, label, value, minVal, maxVal,
    width)
    local cv   = colorValues
    width      = width or 120

    -- Draw slider
    
    reaper.ImGui_PushItemWidth(ctx, width)
    reaper.ImGui_PushFont(ctx, fontSmall)


    local changed, newVal = reaper.ImGui_SliderInt(ctx, label, value, minVal, maxVal)

    reaper.ImGui_PopItemWidth(ctx)
    reaper.ImGui_PopFont(ctx)

    return changed, newVal
end

function drawStepCursor(isCurrent)
    local sprite = isCurrent and images.PlayCursor_on or images.PlayCursor_off            
    reaper.ImGui_Image(ctx,sprite.i,cellW,cellH)
end

function drawStepButton(active, odd, accent)
    local sprite = stepSprite(active, odd, accent)
    reaper.ImGui_Image(ctx,sprite,cellW,cellH)
end

function drawTimesSeparator()
    reaper.ImGui_SameLine(ctx)
    local currentY = reaper.ImGui_GetCursorPosY(ctx)
    reaper.ImGui_SetCursorPosY(ctx, currentY + cellH / 3) 
    reaper.ImGui_Text(ctx, '-')
    reaper.ImGui_SameLine(ctx)
end

function SameLineAutoWrap(ctx, widgetWidth, spacing)
    spacing = spacing or 0
    local avail_w, avail_h = reaper.ImGui_GetContentRegionAvail(ctx)
    if avail_w < widgetWidth + spacing then
        reaper.ImGui_NewLine(ctx)
    end
    reaper.ImGui_SameLine(ctx, spacing)
end

function drawTrackLabel(ctx, sprite, text)
  reaper.ImGui_Image(ctx, sprite.i, sprite.w, sprite.h)

  local minX,minY = reaper.ImGui_GetItemRectMin(ctx)
  local maxX,maxY = reaper.ImGui_GetItemRectMax(ctx)
  local tw,th     = reaper.ImGui_CalcTextSize(ctx, text)
  local cx        = (minX + maxX - tw) * 0.5
  local cy        = (minY + maxY - th) * 0.5
  local dl        = reaper.ImGui_GetWindowDrawList(ctx)
  reaper.ImGui_DrawList_AddText(dl, cx, cy, 0xFFFFFFFF, text)
end
