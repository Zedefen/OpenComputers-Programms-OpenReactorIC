--#requires
 
local fs = require("filesystem")
local term = require("term")
local serialization = require("serialization")
local component = require("component")
local event = require("event")
local colors = require("colors")

local function safeLoadCom(name)
  if component.isAvailable(name) then
    return component.getPrimary(name), true
  else
    return 'ERROR! Компонент '..name..' не найден!', false
  end
end
--#variables
local gpu = component.gpu
local ow, oh = gpu.maxResolution(ow, oh)
local rs = safeLoadCom("redstone")
local config = {}
local reactor = safeLoadCom("reactor")
local running = true
local screen = "main"
local rside = 3

if not component.isAvailable("reactor") then
print("нет компонента reactor")
os.exit()
end
if component.isAvailable("batbox") then
cap = component.batbox
capstormax = cap.getEUCapacity()
capstor = cap.getEUStored()
elseif component.isAvailable("cesu") then
cap = component.cesu
capstormax = cap.getEUCapacity()
capstor = cap.getEUStored()
elseif component.isAvailable("mfe") then
cap = component.mfe
capstormax = cap.getEUCapacity()
capstor = cap.getEUStored()
elseif component.isAvailable("mfsu") then
cap = component.mfsu
capstormax = cap.getEUCapacity()
capstor = cap.getEUStored()
elseif component.isAvailable("afsu") then
cap = component.afsu
capstormax = cap.getEUCapacity()
capstor = cap.getEUStored()
elseif component.isAvailable("capacitor_bank") then
cap = component.capacitor_bank
capstormax = cap.getMaxEnergyStored()
capstor = cap.getEnergyStored()
else print("не найдено ни одного накопителя энергии")
os.exit()
end

--intro
function intro()
  term.clear()
  gpu.setResolution(80,25)
  print("OpenReactor IC2")
  os.sleep(2)
end
intro()
--#install
 
function install()
  screen = "install"
  term.clear()
  print("Требования:")
  print("Экран 2 уровня и выше")
  print("Видеокарта 2 уровня и выше")
  print("Подключенный к адаптеру ядерный реактор IC2")
  print("Подключенное к адаптеру энергохранилище")
  print()
  print("Все требования выполнены? (y/n)")
  --21,49
  local result = false
  while not result do
    local name, adress, char, code, player = event.pull("key_down")
    if code == 21 then
      result = true
    elseif code == 49 then
      os.exit()
    else
      print("Invalid response")
    end
  end
  --set resolution and continue
  gpu.setResolution(80,25)
  gpu.setForeground(0x000000)
  term.clear()
  gpu.setBackground(0x000000)
  term.clear()
  gpu.setBackground(0x808080)
  gpu.fill(20,9,40,6," ")
  term.setCursor(20,9)
  print("Благодарим за использование ПО")
  term.setCursor(20,10)
  print("OpenReactor")
  term.setCursor(20,11)
  print("нажмите ок для продолжения")
  term.setCursor(20,12)
  print("нажмите отмена чтобы прервать установку ПО")
  gpu.setBackground(0x008000)
  gpu.fill(20,14,20,1," ")
  term.setCursor(29,14)
  print("ок")
  gpu.setBackground(0x800000)
  gpu.fill(40,14,20,1," ")
  term.setCursor(48,14)
  print("отмена")
  local event_running = true
  while event_running do
    local name, address, x, y, button, player = event.pull("touch")
    if x >= 20 and x <= 39 and y == 14 then
      print("ок")
      event_running = false
    elseif x>=40 and x <= 59 and y == 14 then
      os.exit()
    end
  end
  set_color_scheme()
  save_config()
  main()
end

--#set_color_scheme
 
function set_color_scheme()
  config.color_scheme = {}
  config.color_scheme.background = 0x000000
  config.color_scheme.button = 0x606060
  config.color_scheme.button_disabled = 0xC0C0C0
  config.color_scheme.foreground = 0x000000
  config.color_scheme.progressBar = {}
  config.color_scheme.progressBar.background = 0x000000
  config.color_scheme.progressBar.foreground = 0xFFFFFF
  config.color_scheme.menubar={}
  config.color_scheme.menubar.background = 0x000000
  config.color_scheme.menubar.foreground = 0xFFFFFF
  config.color_scheme.success = 0x008000
  config.color_scheme.error = 0x800000
  config.color_scheme.info = 0x808000
  config.auto_power = {}
  config.auto_power.enabled = true
  config.auto_power.start_percent = 10
  config.auto_power.stop_percent = 65
end

--#main
 
function main()
  screen = "main"
  gpu.setResolution(80,25)
  read_config()
  event.listen("touch",listen)
  while running do
    if config.auto_power.enabled == true then
      if (math.modf((reactor.getHeat()*100)/reactor.getMaxHeat())/100)<config.auto_power.start_percent then
        rs.setOutput(rside, 15)
      elseif (math.modf((reactor.getHeat()*100)/reactor.getMaxHeat())/100)>config.auto_power.stop_percent then
        rs.setOutput(rside, 0)
      end
    end
    gpu.setBackground(config.color_scheme.background)
    term.clear()
    draw_menubar()
    if screen == "main" then
      draw_main()
    elseif screen == "config" then
      draw_config()
    end
    os.sleep(1)
  end
end
 
--#draw_menubar
 
function draw_menubar()
  term.setCursor(1,1)
  gpu.setBackground(config.color_scheme.menubar.background)
  gpu.setForeground(config.color_scheme.menubar.foreground)
  term.clearLine()
  term.setCursor(1,1)
  term.write("Статус: ")
  if reactor.producesEnergy() then
    gpu.setForeground(config.color_scheme.success)
    term.write("Включен ")
  else
    gpu.setForeground(config.color_scheme.error)
    term.write("Отключен ")
  end
  if config.auto_power.enabled then
    gpu.setForeground(config.color_scheme.menubar.foreground)
    term.write("(")
    gpu.setForeground(config.color_scheme.info)
    term.write("Авто")
    gpu.setForeground(config.color_scheme.menubar.foreground)
    term.write(") ")
  end
  gpu.setForeground(config.color_scheme.menubar.foreground)
  term.write(" Температура реактора: ")
  gpu.setForeground(config.color_scheme.info)
  term.write(round(reactor.getHeat()).."C ")
  gpu.setForeground(config.color_scheme.menubar.foreground)
  term.write(" Энерговыход: ")
  gpu.setForeground(config.color_scheme.info)
  term.write(round(reactor.getReactorEUOutput()).."EU/t ")
  term.setCursor(74,1)
  gpu.setForeground(config.color_scheme.menubar.foreground)
  term.write("[")
  gpu.setForeground(config.color_scheme.error)
  term.write("Выход")
  gpu.setForeground(config.color_scheme.menubar.foreground)
  term.write("]")
end
 
--#save_config
 
function save_config()
  local file = io.open("or.cfg","w")
  file:write(serialization.serialize(config,false))
  file:close()
end
 
--#read_config
 
function read_config()
  local file = io.open("or.cfg","r")
  local c = serialization.unserialize(file:read(fs.size("or.cfg")))
  file:close()
  for k,v in pairs(c) do
    config[k] = v
  end
end
 
--#draw_main
 
function draw_main()
  if config.auto_power.enabled then
    gpu.setBackground(config.color_scheme.button)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1,2,69,3," ")
    term.setCursor(25,3)
    term.write("Автоактивация реактора - включено")
    gpu.setBackground(0x153F3F)
    gpu.fill(70,2,11,3," ")
    term.setCursor(71,3)
    term.write("Конфиг.")
  else
    gpu.setBackground(config.color_scheme.button)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1,2,69,3," ")
    term.setCursor(25,3)
    term.write("Автоактивация реактора - отключено")
    gpu.setBackground(0x153F3F)
    gpu.fill(70,2,11,3," ")
    term.setCursor(73,3)
    term.write(" ")
  end
  gpu.setForeground(0xFFFFFF)
  gpu.setBackground(config.color_scheme.button)
  gpu.fill(1,8,13,3," ")
  gpu.fill(1,14,13,3," ")
  gpu.fill(1,20,13,3," ")
  term.setCursor(3,9)
  term.write("Температура")
  term.setCursor(3,15)
  term.write("Энерговыход")
  term.setCursor(4,21)
  term.write("Энергохр.")

-- Bars

  drawProgressBarR(14,8,65,3,(math.modf((reactor.getHeat()*100)/reactor.getMaxHeat())/100))
  drawProgressBar(14,14,65,3,(math.modf((reactor.getReactorEUOutput()*100)/1024))/100)
  drawProgressBarG(14,20,65,3,(math.modf((capstor*100)/capstormax))/100)
  if config.auto_power.enabled then
    gpu.setBackground(config.color_scheme.success)
    gpu.fill(14+65*config.auto_power.start_percent/100,8,1,3," ")
    gpu.setBackground(config.color_scheme.error)
    gpu.fill(14+65*config.auto_power.stop_percent/100,8,1,3," ")
  end
end
 
--#draw_config
 
function draw_config()
  gpu.setBackground(config.color_scheme.button)
  gpu.fill(5,9,71,9," ")
  gpu.setForeground(0xFFFFFF)
  term.setCursor(36,9)
  term.write("Конфигурация")
  term.setCursor(35,10)
  term.write("Start: "..config.auto_power.start_percent.."%")
  term.setCursor(36,11)
  term.write("Stop: "..config.auto_power.stop_percent.."%")
  drawProgressBar(8,12,65,3,(math.modf((reactor.getHeat()*100)/reactor.getMaxHeat()))/100)
  gpu.setBackground(config.color_scheme.success)
  gpu.fill(8+65*config.auto_power.start_percent/100,12,1,3," ")
  gpu.setBackground(config.color_scheme.error)
  gpu.fill(8+65*config.auto_power.stop_percent/100,12,1,3," ")
  gpu.setBackground(config.color_scheme.button)
  gpu.setForeground(0xFFFFFF)
  term.setCursor(37+#("Start: "..config.auto_power.start_percent.."%"),10)
  term.write("[")
  gpu.setForeground(config.color_scheme.error)
  term.write("-")
  gpu.setForeground(0xFFFFFF)
  term.write("]  [")
  gpu.setForeground(config.color_scheme.success)
  term.write("+")
  gpu.setForeground(0xFFFFFF)
  term.write("]")
  term.setCursor(38+#("Stop: "..config.auto_power.stop_percent.."#"),11)
  term.write("[")
  gpu.setForeground(config.color_scheme.error)
  term.write("-")
  gpu.setForeground(0xFFFFFF)
  term.write("]  [")
  gpu.setForeground(config.color_scheme.success)
  term.write("+")
  gpu.setForeground(0xFFFFFF)
  term.write("]")
  term.setCursor(5,9)
  term.write("[")
  gpu.setForeground(config.color_scheme.info)
  term.write("Назад")
  gpu.setForeground(0xFFFFFF)
  term.write("]")
end

--#drawProgressBarRed
 
function drawProgressBarR(x,y,w,h,percent)
  gpu.setBackground(config.color_scheme.progressBar.background)
  gpu.fill(x,y,w,h," | ")
  gpu.setBackground(0xFF0000)
  gpu.fill(x,y,w*percent,h," ")
end

--#drawProgressBarGreen
 
function drawProgressBarG(x,y,w,h,percent)
  gpu.setBackground(config.color_scheme.progressBar.background)
  gpu.fill(x,y,w,h," ")
  gpu.setBackground(0x00FF00)
  gpu.fill(x,y,w*percent,h," ")
end
 

--#drawProgressBar
 
function drawProgressBar(x,y,w,h,percent)
  gpu.setBackground(config.color_scheme.progressBar.background)
  gpu.fill(x,y,w,h," ")
  gpu.setBackground(config.color_scheme.progressBar.foreground)
  gpu.fill(x,y,w*percent,h," ")
end
 
--#listen
 
function listen(name,address,x,y,button,player)
  if x >= 74 and x <= 80 and y == 1 then
    running = false
  end
  if screen == "main" then
    if x >= 70 and y >=2 and x <= 80 and y <= 4 and config.auto_power.enabled ~= true then
      reactor.producesEnegry(not reactor.producesEnergy())
    elseif x >= 1 and y >=2 and x <= 69 and y <= 4 then
      config.auto_power.enabled = not config.auto_power.enabled
      save_config()
    elseif x >= 70 and y >= 2 and x <= 80 and y <= 4 and config.auto_power.enabled then
      screen = "config"
    end
  elseif screen=="config" then
    if x>= 5 and x <= 10 and y == 9 then
      screen="main"
    elseif x >= 37 + #("Start: "..config.auto_power.start_percent.."%") and x <= 40+#("Start: "..config.auto_power.start_percent.."%") and y == 10 and config.auto_power.start_percent ~= 0 then
      config.auto_power.start_percent = config.auto_power.start_percent-1
      save_config()
    elseif x >= 43 + #("Start: "..config.auto_power.start_percent.."%") and x <= 46+#("Start: "..config.auto_power.start_percent.."%") and y == 10 and config.auto_power.start_percent+1 ~= config.auto_power.stop_percent then
      config.auto_power.start_percent = config.auto_power.start_percent+1
      save_config()
    elseif x >= 38 + #("Stop: "..config.auto_power.stop_percent.."%") and x <= 41 + #("Stop: "..config.auto_power.stop_percent.."%") and y == 11 and config.auto_power.stop_percent - 1 ~= config.auto_power.start_percent then
      config.auto_power.stop_percent = config.auto_power.stop_percent - 1
      save_config()
    elseif x >= 44 + #("Stop: "..config.auto_power.stop_percent.."%") and x <= 47 + #("Stop: "..config.auto_power.stop_percent.."%") and y == 11 and config.auto_power.stop_percent ~= 100 then
      config.auto_power.stop_percent = config.auto_power.stop_percent + 1
      save_config()
    end
  end
end
 
--#countTable
 
function countTable(table)
local result = 0
  for k,v in pairs(table) do
    result = result+1
  end
return result
end
 
--#round
 
function round(num,idp)
  local mult = 10^(idp or 0)
  return math.floor(num*mult+0.5)/mult
end
 
--#init
if not fs.exists("or.cfg") then
  install()
else
  main()
end
event.ignore("touch",listen)
gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
gpu.setResolution(ow, oh)
term.clear()