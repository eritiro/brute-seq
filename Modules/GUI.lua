-- config
local fontSize = 12


ctx  = reaper.ImGui_CreateContext('Sequencer')
local fonts_path  = script_path .. 'Fonts/'
local images_path = script_path .. 'Images/'

-----------------------------------------------------------------------
-- Load fonts
-----------------------------------------------------------------------

local font = reaper.ImGui_CreateFont(fonts_path .. 'Inter.ttc', fontSize)
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