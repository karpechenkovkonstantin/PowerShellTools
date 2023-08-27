# Remote Remover
## Описание
Простенький GUI для удаления программ на удалённом ПК через **PSSession**

## Принцип работы
В основе лежит трансляция комманд через набор коммандлетов **PSSession**

- Открываем сеанс через `New-PSSession -ComputerName {ComputerName}`
- Получаем данные реестра из:
	- x64: `Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName}`
	- x32: `Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName }`
- Загружаем их в табличку
- При выборе программы в таблице и клике на кнопку "Удалить" происходит следующее:
	- Проверяем установлена ли программа через **MSI**
		- Если да: Обращаемся к msiexec.exe с ключами /x /qn
		- Если нет: Стартуем деинсталятор по пути в `$uninstallString` с ключами `/S /SILENT /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-`. Лишние он должен проигнорировать
	- Ждём окончания процедуры
	- Обновляем таблицу
