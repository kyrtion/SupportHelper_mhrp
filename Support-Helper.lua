script_name('Support-Helper')
script_description('Support-Helper for special project MyHome RP')
script_author('kyrtion#7310')
script_properties('work-in-pause')
script_version('0.1')

require 'lib.moonloader'
local dlstatus = require('moonloader').download_status

if not doesDirectoryExist('moonloader/config') then createDirectory('moonloader/config') end
if not doesDirectoryExist('moonloader/config/Support-Helper') then createDirectory ('moonloader/config/Support-Helper') end

local imgui = require 'mimgui' -- теперь мимгуй, а не имгуй...
local encoding = require 'encoding'
local ffi = require 'ffi'
local sampev = require 'lib.samp.events'
local inicfg = require 'inicfg'

function json(filePath)
	local f = {}

	function f:read()
		local f = io.open(filePath, "r+")
		local jsonInString = f:read("*a")
		f:close()
		local jsonTable = decodeJson(jsonInString)
		return jsonTable
	end

	function f:write(t)
		f = io.open(filePath, "w")
		f:write(encodeJson(t))
		f:flush()
		f:close()
	end

	return f
end

encoding.default = 'CP1251'
u8 = encoding.UTF8

local askJson = getWorkingDirectory()..'/config/Support-Helper/ask.json'; local askList = {}
local tempJson = getWorkingDirectory()..'/config/Support-Helper/temp.json'; local tempList = {}

local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local renderWindow = new.bool(false)
local menuWindow = new.bool(false)
local tab = new.int(1)
local askInput = new.char[256]('')
local newAskInput = new.char[256]('')
local newAnswerInput = new.char[256]('')
local delAsk = ''
local delAnswer = ''
local searchInput = new.char[256]('')
local searchLog = new.char[256]('')
local searchSelf = new.char[256]('')
local idNew = 0
local idDel = 0


local askPlayer, askDate, askText = 'Awe Some[123]', '16.07.2022 10:53:11', 'awesome text, dude'
local notAdNick = false
local confirm = false
local block = false
local fplayer, fask, fold_date, fmsg, fchar, fnew_date = '', '', '', '', '', ''
local nplayer, nask, nchar, nold_date = '', '', '', ''
local lockAskSession = false
local lockAnswerSession = false
local copying = false
local autoFocus = false
local hex = '0xB894ff'

local update_state = false
local checkVerify = false
local lockVerify = false
local lockFailed = false
local newVersion = 'None'
local oldVersion = 'None'

-- --! origin/master
-- local update_url = 'https://raw.githubusercontent.com/kyrtion/SupportHelper_mhrp/master/version_sh.ini'
-- local update_path = getWorkingDirectory() .. '/update_sh.ini'
-- local script_vers = tostring(thisScript().version)
-- local script_url = 'https://github.com/kyrtion/SupportHelper_mhrp/blob/master/LSN-Helper.lua?raw=true'
-- local script_path = thisScript().path

-- --! origin/beta
-- local update_url = 'https://raw.githubusercontent.com/kyrtion/SupportHelper_mhrp/beta/version_sh.ini'
-- local update_path = getWorkingDirectory() .. '/update_sh.ini'
-- local script_vers = tostring(thisScript().version)
-- local script_url = 'https://github.com/kyrtion/SupportHelper_mhrp/blob/beta/LSN-Helper.lua?raw=true'
-- local script_path = thisScript().path

function send(result) sampAddChatMessage('Support-Helper » '.. result, hex) end

imgui.OnInitialize(function() imgui.DarkTheme(); imgui.GetIO().IniFilename = nil; end)

local newFrame = imgui.OnFrame(
	function() return renderWindow[0] end,
	function(player)
		local resX, resY = getScreenResolution()
		local sizeX, sizeY = 700, 310
		imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY * 1.04))
		imgui.Begin(u8'Ask | Support-Helper '..thisScript().version, nil, imgui.WindowFlags.NoMove + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

		imgui.SetCursorPos(imgui.ImVec2(20, 40))
		imgui.TextColoredRGB('Игрок:')

		imgui.SameLine((sizeX - 15) / 2 + 11)
		imgui.TextColoredRGB('Рассмотрение вопроса от:')

		imgui.SetCursorPos(imgui.ImVec2(20, 60));
		imgui.BeginChild('ChildWindowsPlayer', imgui.ImVec2(sizeX - 371, 25), true)
		imgui.TextColoredRGB('{FFFFFF}' .. askPlayer)
		imgui.EndChild()
		imgui.SameLine((sizeX - 15) / 2 + 10);

		imgui.BeginChild('ChildWindowsDate', imgui.ImVec2(sizeX - 371, 25), true)
		imgui.TextColoredRGB(askDate)
		imgui.EndChild()
		
		
		imgui.SetCursorPos(imgui.ImVec2(20, 120))
		imgui.BeginChild('ChildWindowsAsk', imgui.ImVec2(sizeX - 40, 25), true)
		imgui.TextColoredRGB(askText)
		imgui.EndChild()

		imgui.SetCursorPos(imgui.ImVec2(20, 165))
		--imgui.TextColoredRGB('Введите новый текст для этого объявления. Но не оставьте поле пустым!')

		imgui.SetCursorPos(imgui.ImVec2(20, 180))
		imgui.TextColoredRGB('Ответ:')
		--imgui.TextColoredRGB('Вы так-же можете отклонить объявление с написанной в поле причиной и нажав после кнопку "Отклонить".')

		if copying then
			imgui.SetCursorPos(imgui.ImVec2(21, 160))
			imgui.TextColoredRGB('{FFAA00}Вопрос совпадает одной и тоже, скопировано ответ в прошлом раз. Проверьте, всё правильно ли написано.')
		end

		
		imgui.SetCursorPos(imgui.ImVec2(20, 100))
		imgui.TextColoredRGB('Вопрос:')
		
		imgui.SetCursorPos(imgui.ImVec2(20, sizeY - 110))
		imgui.PushItemWidth(sizeX - 40);
		if imgui.IsWindowAppearing() then imgui.SetKeyboardFocusHere(-1) end
		imgui.PushAllowKeyboardFocus(false)
		imgui.InputText(u8'##askInput', askInput, sizeof(askInput))
		imgui.PopAllowKeyboardFocus()

		imgui.SetCursorPos(imgui.ImVec2(20, sizeY - 60))
		imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.34, 0.42, 0.51, 1.0))
		imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.34, 0.42, 0.51, 0.9))
		imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.34, 0.42, 0.51, 0.8))
		if imgui.Button(u8'Передать в /h', imgui.ImVec2((sizeX - 42) / 2 , 25)) then
			if (u8:decode(askText)) == (nil or '') then
				send('В тексте пусто, зачем передать?', -1)
			else
				sampSendChat('/h << Вопрос >> '.. askPlayer .. ': '.. askText)
			end
		end
		imgui.PopStyleColor(3)

		imgui.SameLine((sizeX - 17) / 2 + 10)
		if imgui.Button(u8'Поиск', imgui.ImVec2((sizeX - 42) / 2 , 25)) then
			imgui.OpenPopup(u8'Поиск | Support-Helper '..thisScript().version)
		end

		if imgui.BeginPopupModal(u8'Поиск | Support-Helper '..thisScript().version, _, imgui.WindowFlags.NoMove + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse) then
			local pSize = imgui.ImVec2(1000, 360)
			imgui.SetWindowSizeVec2(pSize)
	
			imgui.SetCursorPos(imgui.ImVec2(20, 45))
			imgui.Text(u8'Текст:') imgui.SameLine(70) imgui.TextColoredRGB(askText)
				
			imgui.SetCursorPos(imgui.ImVec2(20, 70)) imgui.Text(u8'Поиск:')
			
			imgui.SetCursorPos(imgui.ImVec2(70, 66))
			imgui.PushItemWidth(pSize.x - 90)
			if imgui.IsWindowAppearing() then imgui.SetKeyboardFocusHere(-1) end
			imgui.PushAllowKeyboardFocus(false)
			if imgui.InputText('##searchInput', searchInput, sizeof(searchInput)) then str(searchInput):find(str(searchInput):gsub("%p", "%%%1")) end
			imgui.PopAllowKeyboardFocus()
			imgui.PopItemWidth()
			
			imgui.SetCursorPos(imgui.ImVec2(21, 108))
			imgui.Text(u8'Результаты:')
	
			imgui.SetCursorPos(imgui.ImVec2(20, 130))
			imgui.BeginChild('ChildWindowsS', imgui.ImVec2(pSize.x/2 + 460, pSize.y/2 - 0), true)

			local bbts = imgui.ImVec2(50, 15)
			for i=1, #askList do
				if string.len(str(searchInput)) ~= 0 then
					if	string.find(u8(askList[i].ask), str(searchInput), 1, true) or
						string.find(u8(askList[i].answer), str(searchInput), 1, true) then -- список вопросов
						imgui.Columns(2)
						if imgui.Selectable(u8'/H##'..tonumber(i), true, _, bbts) then
							sampSendChat('/h >> '..askList[i].ask)
						end
						if imgui.Selectable(u8'PASTE##'..tonumber(i), true, _, bbts) then
							imgui.StrCopy(askInput, u8(askList[i].answer))
							imgui.CloseCurrentPopup()
							searchInput = new.char[256]('')
						end
						imgui.SetColumnWidth(0, 60)
						imgui.NextColumn()
						if askList[i].type == 'self' then imgui.TextColoredRGB('{ffffff}Вопрос {68e625}$ {ffffff}'..askList[i].ask) else imgui.TextColoredRGB('{ffffff}Вопрос {fac146}: {ffffff}'..askList[i].ask) end
						if askList[i].type == 'self' then imgui.TextColoredRGB('{ffffff}Ответ {68e625}$ {ffffff}'..askList[i].answer) else imgui.TextColoredRGB('{ffffff}Ответ {fac146}: {ffffff}'..askList[i].answer) end
						imgui.NextColumn()
						if i ~= #askList then imgui.Separator() end
					end
				else -- если в поиске ничего нет, даже никакое значение
					imgui.Columns(2)
					if imgui.Selectable(u8'/H##'..tonumber(i), true, _, bbts) then
						sampSendChat('/h >> '..askList[i].ask)
					end
					if imgui.Selectable(u8'PASTE##'..tonumber(i), true, _, bbts) then
						imgui.StrCopy(askInput, u8(askList[i].answer))
						imgui.CloseCurrentPopup()
						searchInput = new.char[256]('')
					end
					imgui.SetColumnWidth(0, 60)
					imgui.NextColumn()
					if askList[i].type == 'self' then imgui.TextColoredRGB('{ffffff}Вопрос {68e625}$ {ffffff}'..askList[i].ask) else imgui.TextColoredRGB('{ffffff}Вопрос {fac146}: {ffffff}'..askList[i].ask) end
					if askList[i].type == 'self' then imgui.TextColoredRGB('{ffffff}Ответ {68e625}$ {ffffff}'..askList[i].answer) else imgui.TextColoredRGB('{ffffff}Ответ {fac146}: {ffffff}'..askList[i].answer) end
					imgui.NextColumn()
					if i ~= #askList then imgui.Separator() end
				end
			end

			imgui.EndChild()

			imgui.SetCursorPos(imgui.ImVec2(20, pSize.y - 40))
			if imgui.Button(u8'Закрыть', imgui.ImVec2(pSize.x/2 + 460, 25)) then
				searchInput = new.char[256]('')
				imgui.CloseCurrentPopup()
			end
	
			imgui.EndPopup()
		end

		imgui.SetCursorPos(imgui.ImVec2(20, sizeY - 33))
		imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.77, 0.33, 1.0))
		imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.2, 0.77, 0.33, 0.9))
		imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.2, 0.77, 0.33, 0.8))
		if imgui.Button(u8'Ответить', imgui.ImVec2((sizeX - 42) / 2 , 25)) then
			local tempText = (u8:decode(str(askInput)))
			
			if (u8:decode(str(askInput))) == (nil or '') then
				send('В ответе пусто, зачем отправлять?', -1)
			else
				sampSendDialogResponse(6921, 1, 0, (u8:decode(str(askInput))))
				renderWindow[0] = false
				askPlayer, askDate, askText = '', '', ''
				confirm = false
			end
		end
		imgui.PopStyleColor(3)

		imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.00, 0.25, 0.25, 1.0))
		imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00, 0.25, 0.25, 0.9))
		imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1.00, 0.25, 0.25, 0.8))
		imgui.SameLine((sizeX - 17) / 2 + 10)
		if imgui.Button(u8'Игнорить', imgui.ImVec2((sizeX - 42) / 2 , 25)) then
			imgui.OpenPopup(u8'Игнор | Support-Helper '..thisScript().version)
		end
		imgui.PopStyleColor(3)

		if imgui.BeginPopupModal(u8'Игнор | Support-Helper '..thisScript().version, _, imgui.WindowFlags.NoMove + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse) then
			local pSize = imgui.ImVec2(560, 160)
			imgui.SetWindowSizeVec2(pSize)
	
			imgui.SetCursorPos(imgui.ImVec2(20, 45))
			imgui.Text(u8'Вопрос:') imgui.SameLine(70) imgui.TextColoredRGB(askText)
				
			imgui.SetCursorPos(imgui.ImVec2(20, 70))
			imgui.Text(u8'Вы не знаете как отвечать и хотите это проигнорить вопрос?')

			imgui.SetCursorPos(imgui.ImVec2(20, pSize.y - 45))
			local but = imgui.ImVec2((pSize.x/2) - 23, 25)
			imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.77, 0.33, 1.0))
			imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.2, 0.77, 0.33, 0.9))
			imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.2, 0.77, 0.33, 0.8))
			if imgui.Button(u8'Да', but) then
				renderWindow[0] = false
				imgui.CloseCurrentPopup()
				sampSendDialogResponse(6921, 0, 0, '')
				askPlayer, askDate, askText = '', '', ''
			end
			imgui.PopStyleColor(3)

			imgui.SameLine(280)

			imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.00, 0.25, 0.25, 1.0))
			imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00, 0.25, 0.25, 0.9))
			imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1.00, 0.25, 0.25, 0.8))
			if imgui.Button(u8'Нет', but) then
				imgui.CloseCurrentPopup()
			end
			imgui.PopStyleColor(3)
			imgui.EndPopup()
		end
		imgui.End()
	end
)

local menuFrame = imgui.OnFrame(
	function() return menuWindow[0] end,
	function(player)
		local resX, resY = getScreenResolution()
		local sizeX, sizeY = 960, 400
		imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
		imgui.BeginCustomTitle(u8'Меню | Support-Helper '..tostring(thisScript().version), 30, menuWindow, imgui.WindowFlags.NoMove + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
		
		local csbutt = imgui.ImVec2(sizeX - 647, 25)
		if imgui.Button(u8'Главная', csbutt) then tab[0] = 1 end imgui.SameLine()
		if imgui.Button(u8'Готовые вопросы', csbutt) then tab[0] = 2 end imgui.SameLine()
		if imgui.Button(u8'Логи', csbutt) then tab[0] = 3 end

		local childSize = sizeX - 100
		imgui.SetCursorPos(imgui.ImVec2(5, 65))
		imgui.BeginChild('s', imgui.ImVec2(sizeX - 10, sizeY - 70), true)
		if tab[0] == 1 then -- Раздел "Главная"
			imgui.SetCursorPos(imgui.ImVec2(5, 8))

			imgui.Text(u8'Скоро...')
			
		elseif tab[0] == 2 then -- Раздел "Готовые вопросы"
			imgui.SetCursorPos(imgui.ImVec2(5, 8))
			imgui.Text(u8'Поиск: ')

			imgui.SetCursorPos(imgui.ImVec2(50, 5))
			imgui.PushItemWidth(sizeX - 370)
			if imgui.InputText('##searchSelf', searchSelf, sizeof(searchSelf)) then str(searchSelf):find(str(searchSelf):gsub("%p", "%%%1")) end
			imgui.PopItemWidth()

			imgui.SetCursorPos(imgui.ImVec2(5, 33))
			imgui.BeginChild('ChildWin1', imgui.ImVec2(sizeX/2 + 460, sizeY/2 + 92), true)
			local sbutt = imgui.ImVec2(50, 15)
			for i=1, #askList do
				if askList[i].type == 'self' then
					if string.len(str(searchSelf)) ~= 0 then
						if	string.find(u8(askList[i].ask), str(searchSelf), 1, true) or string.find(u8(askList[i].answer), str(searchSelf), 1, true) then -- список по ask и answer по type `self`
							imgui.Columns(2)
							if imgui.Selectable(u8'EDIT##'..tonumber(i), true, _, sbutt) then
								imgui.OpenPopup(u8'Редактирование готового вопроса | Support-Helper '..thisScript().version)
								idNew = i
								newAskInput = new.char[256](u8(askList[i].ask))
								newAnswerInput = new.char[256](u8(askList[i].answer))
							end
							if imgui.Selectable(u8'DELETE##'..tonumber(i), true, _, sbutt) then
								imgui.OpenPopup(u8'Удаление готового вопроса | Support-Helper '..thisScript().version)
								idDel = i
								delAsk = askList[i].ask
								delAnswer = askList[i].answer
							end
							imgui.SetColumnWidth(0, 60)
							imgui.NextColumn()
							imgui.TextColoredRGB('{ffffff}Вопрос {68e625}$ {ffffff}'..askList[i].ask)
							imgui.TextColoredRGB('{ffffff}Ответ {68e625}$ {ffffff}'..askList[i].answer)
							imgui.NextColumn()
							imgui.Separator()
						end
					else
						imgui.Columns(2)
						if imgui.Selectable(u8'EDIT##'..tonumber(i), true, _, sbutt) then
							imgui.OpenPopup(u8'Редактирование готового вопроса | Support-Helper '..thisScript().version)
							idNew = i
							newAskInput = new.char[256](u8(askList[i].ask))
							newAnswerInput = new.char[256](u8(askList[i].answer))
						end
						if imgui.Selectable(u8'DELETE##'..tonumber(i), true, _, sbutt) then
							imgui.OpenPopup(u8'Удаление готового вопроса | Support-Helper '..thisScript().version)
							idDel = i
							delAsk = askList[i].ask
							delAnswer = askList[i].answer
						end
						imgui.SetColumnWidth(0, 60)
						imgui.NextColumn()
						imgui.TextColoredRGB('{ffffff}Вопрос {68e625}$ {ffffff}'..askList[i].ask)
						imgui.TextColoredRGB('{ffffff}Ответ {68e625}$ {ffffff}'..askList[i].answer)
						imgui.NextColumn()
						imgui.Separator()
					end
				end
			end
			if imgui.BeginPopupModal(u8'Редактирование готового вопроса | Support-Helper '..thisScript().version, _, imgui.WindowFlags.NoMove + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse) then
				local sizeX, sizeY = 800, 155; local vecs = imgui.ImVec2(sizeX, sizeY); imgui.SetWindowSizeVec2(vecs)

				imgui.SetCursorPos(imgui.ImVec2(20, 40)); imgui.Text(u8'Вопрос $')
				imgui.SetCursorPos(imgui.ImVec2(78, 37)); imgui.PushItemWidth(sizeX - 99); imgui.InputText(u8'##newAskInput', newAskInput, sizeof(newAskInput)); imgui.PopItemWidth()
				imgui.SetCursorPos(imgui.ImVec2(24, 70)); imgui.Text(u8'Ответ  $')
				imgui.SetCursorPos(imgui.ImVec2(78, 67)); imgui.PushItemWidth(sizeX - 99); imgui.InputText(u8'##newAnswerInput', newAnswerInput, sizeof(newAnswerInput)); imgui.PopItemWidth()
	
				imgui.SetCursorPos(imgui.ImVec2(20, sizeY - 45))
				if imgui.Button(u8'Редактировать', imgui.ImVec2(sizeX/2 - 23, 25)) then
					askList[idNew].ask = u8:decode(str(newAskInput))
					askList[idNew].answer = u8:decode(str(newAnswerInput))
					askList[idNew].new_date = os.date('%Y.%m.%d %X')
					--table.remove()
					table.sort(askList, function(a,b) return a.old_date > b.old_date end) -- askList.old_date -> a.old_date, b.old_date
					json(askJson):write(askList)
					imgui.CloseCurrentPopup()
					newAskInput, newAnswerInput = new.char[256](''), new.char[256]('')
				end
				imgui.SameLine()

				if imgui.Button(u8'Закрыть', imgui.ImVec2(sizeX/2 - 23, 25)) then
					imgui.CloseCurrentPopup()
				end

				imgui.EndPopup()
			end
			if imgui.BeginPopupModal(u8'Удаление готового вопроса | Support-Helper '..thisScript().version, _, imgui.WindowFlags.NoMove + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse) then
				local pSize = imgui.ImVec2(900, 160)
				imgui.SetWindowSizeVec2(pSize)
		
				imgui.SetCursorPos(imgui.ImVec2(20, 40))
				imgui.TextColoredRGB('{ffffff}Вопрос {68e625}$ {ffffff}'..delAsk)

				imgui.SetCursorPos(imgui.ImVec2(20, 55))
				imgui.TextColoredRGB('{ffffff}Ответ {68e625}$ {ffffff}'..delAnswer)
					
				imgui.SetCursorPos(imgui.ImVec2(20, 80))
				imgui.Text(u8'Вы точно хотите это удалить?')
	
				imgui.SetCursorPos(imgui.ImVec2(20, pSize.y - 45))
				local but = imgui.ImVec2((pSize.x/2) - 23, 25)
				imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.77, 0.33, 1.0))
				imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.2, 0.77, 0.33, 0.9))
				imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.2, 0.77, 0.33, 0.8))
				if imgui.Button(u8'Да', but) then
					table.remove(askList, idDel)
					table.sort(askList, function(a,b) return a.old_date > b.old_date end)
					json(askJson):write(askList)
					imgui.CloseCurrentPopup()
				end
				imgui.PopStyleColor(3)
	
				imgui.SameLine()
	
				imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.00, 0.25, 0.25, 1.0))
				imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00, 0.25, 0.25, 0.9))
				imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1.00, 0.25, 0.25, 0.8))
				if imgui.Button(u8'Нет', but) then
					imgui.CloseCurrentPopup()
				end
				imgui.PopStyleColor(3)
				imgui.EndPopup()
			end
			imgui.EndChild()
			
			imgui.SetCursorPos(imgui.ImVec2(sizeX/2 + 165, 5))
			local smbutt = imgui.ImVec2(sizeX/3 - 20, 24)
		
			if imgui.Button(u8'Создать готовые вопросы', smbutt) then
				imgui.OpenPopup(u8'Создание готового вопроса | Support-Helper '..thisScript().version)
				newAskInput = new.char[256]('')
				newAnswerInput = new.char[256]('')
			end
			if imgui.BeginPopupModal(u8'Создание готового вопроса | Support-Helper '..thisScript().version, _, imgui.WindowFlags.NoMove + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse) then
				local sizeX, sizeY = 800, 155; local vecs = imgui.ImVec2(sizeX, sizeY); imgui.SetWindowSizeVec2(vecs)

				imgui.SetCursorPos(imgui.ImVec2(20, 40)); imgui.Text(u8'Вопрос $')
				imgui.SetCursorPos(imgui.ImVec2(78, 37)); imgui.PushItemWidth(sizeX - 99); imgui.InputText(u8'##newAskInput', newAskInput, sizeof(newAskInput)); imgui.PopItemWidth()
				imgui.SetCursorPos(imgui.ImVec2(24, 70)); imgui.Text(u8'Ответ  $')
				imgui.SetCursorPos(imgui.ImVec2(78, 67)); imgui.PushItemWidth(sizeX - 99); imgui.InputText(u8'##newAnswerInput', newAnswerInput, sizeof(newAnswerInput)); imgui.PopItemWidth()
	
				imgui.SetCursorPos(imgui.ImVec2(20, sizeY - 45))
				if imgui.Button(u8'Создать', imgui.ImVec2(sizeX/2 - 23, 25)) then
					local list = {
						old_date = os.date('%Y.%m.%d %X'),
						new_date = 'null',
						type = 'self',
						player = 'null',
						ask = u8:decode(str(newAskInput)),
						helper = 'null',
						answer = u8:decode(str(newAnswerInput))
					}
					table.insert(askList, list)
					table.sort(askList, function(a,b) return a.old_date > b.old_date end) -- askList.old_date -> a.old_date, b.old_date
					json(askJson):write(askList)
					imgui.CloseCurrentPopup()
					newAskInput, newAnswerInput = new.char[256](''), new.char[256]('')
				end
				imgui.SameLine()

				if imgui.Button(u8'Закрыть', imgui.ImVec2(sizeX/2 - 23, 25)) then
					imgui.CloseCurrentPopup()
				end

				imgui.EndPopup()
			end
		
		elseif tab[0] == 3 then -- Раздел "Логи"
			imgui.SetCursorPos(imgui.ImVec2(5, 8))
			imgui.Text(u8'Поиск:')
			
			imgui.SetCursorPos(imgui.ImVec2(50, 5))
			imgui.PushItemWidth(sizeX - 65)
			if imgui.IsWindowAppearing() then imgui.SetKeyboardFocusHere(-1) end
			imgui.PushAllowKeyboardFocus(false)
			if imgui.InputText('##searchLog', searchLog, sizeof(searchLog)) then str(searchLog):find(str(searchLog):gsub("%p", "%%%1")) end
			imgui.PopAllowKeyboardFocus()
			imgui.PopItemWidth()

			imgui.SetCursorPos(imgui.ImVec2(5, 33))
			imgui.BeginChild('ChildWindowsS', imgui.ImVec2(sizeX/2 + 460, sizeY/2 + 92), true)
			
			local sbutt = imgui.ImVec2(50, 15)
			for i=1, #askList do
				if askList[i].type ~= 'self' then
					if string.len(str(searchLog)) ~= 0 then
						if	string.find(u8(askList[i].ask), str(searchLog), 1, true) or
							string.find(u8(askList[i].answer), str(searchLog), 1, true) or
							string.find(u8(askList[i].player), str(searchLog), 1, true) or
							string.find(u8(askList[i].helper), str(searchLog), 1, true) or
							string.find(u8(askList[i].old_date), str(searchLog), 1, true) or
							string.find(u8(askList[i].new_date), str(searchLog), 1, true) then -- список всех типов с ask.json кроме type

							imgui.Columns(2)
							if imgui.Selectable(u8'COPY##'..tonumber(i), true, _, sbutt) then
								local clipboard = ('['..askList[i].old_date..'] [Вопрос] '..askList[i].player..': '..askList[i].ask..'\n['..askList[i].new_date..'] [Ответ] '..askList[i].helper..': '..askList[i].answer)
								setClipboardText(clipboard)
								send('Скопировано 2 строка, чтобы вставить нажмите CTRL + V')
							end
	
							if imgui.Selectable(u8'/H [Воп]##'..tonumber(i), true, _, sbutt) then
								sampSendChat('/h << Логи|Вопрос >> '..askList[i].player..': '..askList[i].ask)
							end
	
							if imgui.Selectable(u8'/H [Отв]##'..tonumber(i), true, _, sbutt) then
								sampSendChat('/h << Логи|Ответ >> '..askList[i].helper..': '..askList[i].answer)
							end
	
							imgui.SetColumnWidth(0, 60)
							imgui.NextColumn()
							imgui.Text(u8('Дата: '..askList[i].old_date..' - '..askList[i].new_date))
							
							imgui.Text(u8(askList[i].player..': '..askList[i].ask))
							imgui.Text(u8(askList[i].helper..': '..askList[i].answer))
							imgui.NextColumn()
							if i ~= #askList then imgui.Separator() end
						end
					else
						imgui.Columns(2)
						if imgui.Selectable(u8'COPY##'..tonumber(i), true, _, sbutt) then
							local clipboard = ('['..askList[i].old_date..'] [Вопрос] '..askList[i].player..': '..askList[i].ask..'\n['..askList[i].new_date..'] [Ответ] '..askList[i].helper..': '..askList[i].answer)
							setClipboardText(clipboard)
							send('Скопировано 2 строка, чтобы вставить нажмите CTRL + V')
						end
	
						if imgui.Selectable(u8'/H [Воп]##'..tonumber(i), true, _, sbutt) then
							sampSendChat('/h << Логи|Вопрос >> '..askList[i].player..': '..askList[i].ask)
						end
	
						if imgui.Selectable(u8'/H [Отв]##'..tonumber(i), true, _, sbutt) then
							sampSendChat('/h << Логи|Ответ >> '..askList[i].helper..': '..askList[i].answer)
						end
	
						imgui.SetColumnWidth(0, 60)
						imgui.NextColumn()
						imgui.Text(u8('Дата: '..askList[i].old_date..' - '..askList[i].new_date))
						
						imgui.Text(u8(askList[i].player..': '..askList[i].ask))
						imgui.Text(u8(askList[i].helper..': '..askList[i].answer))
						imgui.NextColumn()
						if i ~= #askList then imgui.Separator() end
					end
				end
			end
		end

		imgui.EndChild()
		-- if tab[0] == 1 then
			-- imgui.Text(u8'Первый исключительный раздел')
			-- здесь кнопки для первого раздела
		--end

		imgui.End()
	end
)

function main()
	while not isSampAvailable() do wait(0) end

	if not doesFileExist(askJson) then json(askJson):write({}) end
	askList = json(askJson):read()

	if not doesFileExist(tempJson) then json(tempJson):write({}) end
	--json(tempJson):write({}) -- удаляем временные вопросы после запуска скрипта
	tempList = json(tempJson):read()
-- 	local ttaf = [[
-- типотакfфа
-- 1
-- 2
-- 3]]
-- 	setClipboardText(ttaf)
	--for i=1, #tempList do
	table.sort(tempList, function(a,b) return a.old_date > b.old_date end)
	json(tempJson):write(tempList)

	-- внесение в json по i (без цикла проверки)
	sampRegisterChatCommand('de', function(index)
		if tonumber(index:match('%d+')) > 0 then
			send('you selected index: '..index)
			table.remove(tempList, index) -- рабочий код, протестирован, удаляется толькот от 1 до беск.+ индекса
			json(tempJson):write(tempList)
			send('deleted!')
		else
			send('/de [index]')
		end
	end)

	sampRegisterChatCommand('ad', function()
		send('try adding')
		local list = {
			old_date = os.date('%Y.%m.%d %X'),
			type = 'temp',
			player = 'Martin Sonnet[233]',
			ask = 'Как зарабатывать деньги? Требую длинный ответ!'
		}
		table.insert(tempList, list)
		json(tempJson):write(tempList)
		send('created!')
	end)

	send('Скрипт успешно загружено. Версия: '..thisScript().version)
	print(); print('Script Support-Helper '..thisScript().version..' loaded - Discord: kyrtion#7310')

	--! debug window (dont use)
	sampRegisterChatCommand('sh_ask', function()
		renderWindow[0] = not renderWindow[0]
	end)

	sampRegisterChatCommand('sh_menu', function()
		menuWindow[0] = not menuWindow[0]
	end)

	sampRegisterChatCommand('sh_verify', function()
		if lockVerify then
			if renderWindow[0] and sampIsDialogActive() then				
				send('Закройте диалог и снова вводите /sh_verify')
			else
				checkVerify = true
				send('Обновляю '..oldVersion ..' -> '..newVersion..' ...')
				lockVerify = false
			end
		end
	end)

	downloadUrlToFile(update_url, update_path, function(id, status)
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			updateIni = inicfg.load(nil, update_path)
			if updateIni.info.version == nil or updateIni == nil then
				send('Невозможно проверить наличие обновление. Нажмите CTRL + R чтобы перезагрузить')
				sampAddChatMessage('wut', -1)
			else
				newVersion = tostring(updateIni.info.version):gsub('"', '')
				oldVersion = tostring(thisScript().version)
				if newVersion ~= oldVersion then
					send('Есть обновление! Версия: '..newVersion..'. Чтобы обновить вводите /verify', -1)
					update_state = true
					lockVerify = true
				end
				os.remove(update_path)
			end
		end
	end)
	
	while true do
		wait(0)
		if update_state and checkVerify then
			downloadUrlToFile(script_url, script_path, function(id, status)
				if status == dlstatus.STATUS_ENDDOWNLOADDATA then
					send('Скрипт успешно обновлен! Сейчас будет перезагружен', -1)
					lockFailed = true
					thisScript():reload()
				end
			end)
			break
		end
	end
end



function onWindowMessage(msg, wparam, lparam)
	if msg == 0x100 or msg == 0x101 then
		if (wparam == VK_ESCAPE and (renderWindow[0]) or (menuWindow[0])) and not isPauseMenuActive() and not sampIsChatInputActive() and not isSampfuncsConsoleActive() then
			consumeWindowMessage(true, false)
		end
	end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
	if id == 6921 and style == 1 and title:find('%{6333FF%}Рассмотрение вопроса от') then
		msg = (text:gsub('%{......}%')):gsub('\n', '')
		askDate = title:match('%{6333FF%}Рассмотрение вопроса от (.*)')
		askPlayer, askText = msg:match('Вопрос от (.*)%: (.*)')
		
		for i=1, #askList do
			if askList[i].ask == askText then
				imgui.StrCopy(askInput, u8(askList[i].answer))
				copying = true
				break
			end
		end
		renderWindow[0] = true
		return false
	end
end

function sampev.onServerMessage(color, text)
	if color == (-1616928769 or -667156735) and (text == "Используйте: /ans [id игрока] [текст]") then send(text) return false end

	if color == -1616928769 and (
		text == "Подсказка: Чтобы открыть инвентарь, нажмите 'Y'" or
		text == "Подсказка: Чтобы взаимодействовать с ботом/игроком, нажмите 'пр. кнопка мыши' + 'H'" or
		text == "Подсказка: Чтобы открыть багажник машины, нажмите 'пр. кнопка мыши' + 'Прыжок'" or
		text == "Подсказка: Вы можете отключить помощь в /mm -> настройки"
	) then
		return false
	end

	if lockAnswerSession then
		if color == -1 and not text:find('%{......%}') then fmsg = (fmsg..text) end
		local list = {
			old_date = fold_date,
			new_date = fnew_date,
			type = 'chat',
			player = fplayer,
			ask = fask,
			helper = fhelper,
			answer = fmsg
		}
		table.insert(askList, list)
		table.sort(askList, function(a,b) return a.old_date > b.old_date end) -- askList.old_date -> a.old_date, b.old_date
		json(askJson):write(askList)

		lockAnswerSession = false
		return true
	end

	if lockAskSession then
		if color == -1 and not text:find('%{......%}') then nask = (nask..text) end
		local list = {
			type = 'temp',
			player = nplayer,
			ask = nask,
			old_date = nold_date,
		}
		table.insert(tempList, list)
		json(tempJson):write(tempList)

		lockAskSession = false
		return true
	end

	--! этот код только в самом конце функции
	-- Хелпер ответил на вопросы
	if color == -1 and text:find('%{C26EFF%}Помощник (.*) ответил игроку (.*)%: %{FFFFFF%}(.*)') then
		local msg = text:gsub('%{......%}', '')
		local msgHelper, msgPlayer, msgAnswer = msg:match('Помощник (.*) ответил игроку (.*)%: (.*)')
		lua_thread.create(function() -- создаем поток для цикла, без него будет крашнуть/вылетать/ошибки появлять
			for i=1, #tempList do
				if msgPlayer == tempList[i].player then -- если в temp.json совпадает игрок с ид
					lockAnswerSession = true
					fnew_date = os.date('%Y.%m.%d %X')
					fplayer = msgPlayer:gsub('%[%d+%]', '')
					fask = tempList[i].ask
					fold_date = tempList[i].old_date
					fhelper = msgHelper:gsub('%[%d+%]', '')
					fmsg, fchar = msgAnswer:match('(.+)(%p)$')
					if fchar ~= nil then print('Символ перенос строка: '..tostring(fchar)) else print('Символ перенос строка: nil (f638)') end

					table.remove(tempList, i)
					json(tempJson):write(tempList)
					break
				end
			end
		end)
		return true
	elseif color == -1 and text:find('%{8914DC%}%[Вопрос%] (.*)%: %{FFFFFF%}(.*)') then
		local msg = text:gsub('%{......%}', '')
		nold_date = os.date('%Y.%m.%d %X')
		nplayer, nask = msg:match('%[Вопрос%] (.*)%: (.*)')
		nask, nchar = nask:match('(.+)(%p)$')
		if nchar ~= ('' or nil) then print('Символ перенос строка: '..tostring(nchar)) end
		lockAskSession = true
		return true
	end
end

function imgui.TextColoredRGB(text)
	local style = imgui.GetStyle()
	local colors = style.Colors
	local ImVec4 = imgui.ImVec4

	local explode_argb = function(argb)
		local a = bit.band(bit.rshift(argb, 24), 0xFF)
		local r = bit.band(bit.rshift(argb, 16), 0xFF)
		local g = bit.band(bit.rshift(argb, 8), 0xFF)
		local b = bit.band(argb, 0xFF)
		return a, r, g, b
	end

	local getcolor = function(color)
		if color:sub(1, 6):upper() == 'SSSSSS' then
			local r, g, b = colors[1].x, colors[1].y, colors[1].z
			local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
			return ImVec4(r, g, b, a / 255)
		end
		local color = type(color) == 'string' and tonumber(color, 16) or color
		if type(color) ~= 'number' then return end
		local r, g, b, a = explode_argb(color)
		return imgui.ImVec4(r/255, g/255, b/255, a/255)
	end

	local render_text = function(text_)
		for w in text_:gmatch('[^\r\n]+') do
			local text, colors_, m = {}, {}, 1
			w = w:gsub('{(......)}', '{%1FF}')
			while w:find('{........}') do
				local n, k = w:find('{........}')
				local color = getcolor(w:sub(n + 1, k - 1))
				if color then
					text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
					colors_[#colors_ + 1] = color
					m = n
				end
				w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
			end
			if text[0] then
				for i = 0, #text do
					imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
					imgui.SameLine(nil, 0)
				end
				imgui.NewLine()
			else imgui.Text(u8(w)) end
		end
	end

	render_text(text)
end

function imgui.BeginCustomTitle(title, titleSizeY, var, flags)
	imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
	imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
	imgui.Begin(title, var, imgui.WindowFlags.NoTitleBar + (flags or 0))
	imgui.SetCursorPos(imgui.ImVec2(0, 0))
	local p = imgui.GetCursorScreenPos()
	imgui.GetWindowDrawList():AddRectFilled(p, imgui.ImVec2(p.x + imgui.GetWindowSize().x, p.y + titleSizeY), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.TitleBgActive]), imgui.GetStyle().WindowRounding, 1 + 2)
	imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowSize().x / 2 - imgui.CalcTextSize(title).x / 2, titleSizeY / 2 - imgui.CalcTextSize(title).y / 2))
	imgui.Text(title)
	imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowSize().x - (titleSizeY - 10) - 5, 5))
	imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, imgui.GetStyle().WindowRounding)
	if imgui.Button('X##CLOSEBUTTON.WINDOW.'..title, imgui.ImVec2(titleSizeY - 10, titleSizeY - 10)) then var[0] = false end
	imgui.SetCursorPos(imgui.ImVec2(5, titleSizeY + 5))
	imgui.PopStyleVar(3)
	imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(5, 5))
end

function imgui.DarkTheme()
	imgui.SwitchContext()
	--==[ STYLE ]==--
	imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
	imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
	imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
	imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
	imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
	imgui.GetStyle().IndentSpacing = 0
	imgui.GetStyle().ScrollbarSize = 10
	imgui.GetStyle().GrabMinSize = 10

	--==[ BORDER ]==--
	imgui.GetStyle().WindowBorderSize = 3
	imgui.GetStyle().ChildBorderSize = 2
	imgui.GetStyle().PopupBorderSize = 3
	imgui.GetStyle().FrameBorderSize = 2
	imgui.GetStyle().TabBorderSize = 1

	--==[ ROUNDING ]==--
	imgui.GetStyle().WindowRounding = 4
	imgui.GetStyle().ChildRounding = 3
	imgui.GetStyle().FrameRounding = 3
	imgui.GetStyle().PopupRounding = 4
	imgui.GetStyle().ScrollbarRounding = 4
	imgui.GetStyle().GrabRounding = 4
	imgui.GetStyle().TabRounding = 4

	--==[ ALIGN ]==--
	imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
	imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
	
	--==[ COLORS ]==--
	imgui.GetStyle().Colors[imgui.Col.Text]                   = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
	imgui.GetStyle().Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Border]                 = imgui.ImVec4(0.25, 0.25, 0.26, 0.54)
	imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
	imgui.GetStyle().Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
	imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.00, 0.00, 0.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.51, 0.51, 0.51, 1.00)
	imgui.GetStyle().Colors[imgui.Col.CheckMark]              = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
	imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Button]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Header]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
	imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.47, 0.47, 0.47, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Separator]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(1.00, 1.00, 1.00, 0.25)
	imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(1.00, 1.00, 1.00, 0.67)
	imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(1.00, 1.00, 1.00, 0.95)
	imgui.GetStyle().Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.28, 0.28, 0.28, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = imgui.ImVec4(0.07, 0.10, 0.15, 0.97)
	imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = imgui.ImVec4(0.14, 0.26, 0.42, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(1.00, 0.00, 0.00, 0.35)
	imgui.GetStyle().Colors[imgui.Col.DragDropTarget]         = imgui.ImVec4(1.00, 1.00, 0.00, 0.90)
	imgui.GetStyle().Colors[imgui.Col.NavHighlight]           = imgui.ImVec4(0.26, 0.59, 0.98, 1.00)
	imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight]  = imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
	imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg]      = imgui.ImVec4(0.80, 0.80, 0.80, 0.20)
	imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
end

function onScriptTerminate(s, q)
	if s == thisScript() then
		if not lockFailed then
			send('Что-то пошло не так с скриптом... Отключаем, чтобы перезагрузить нажми CTRL + R', -1)
		end
		return true
	end
end
