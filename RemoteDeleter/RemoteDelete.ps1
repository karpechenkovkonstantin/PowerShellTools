# Загрузить сборку WPF
Add-Type -AssemblyName PresentationFramework

# Создать объект окна
$window = New-Object System.Windows.Window
$window.Title = "Приложения на удаленном компьютере"
$window.Width = 800
$window.Height = 600

# Создать объект сетки для размещения элементов управления
$grid = New-Object System.Windows.Controls.Grid
$window.Content = $grid

# Создать объекты строк и столбцов для сетки
$row1 = New-Object System.Windows.Controls.RowDefinition
$row1.Height = "Auto"
$row2 = New-Object System.Windows.Controls.RowDefinition
$row2.Height = "*"
$row3 = New-Object System.Windows.Controls.RowDefinition
$row3.Height = "auto"
$col1 = New-Object System.Windows.Controls.ColumnDefinition
$col1.Width = "*"
$col2 = New-Object System.Windows.Controls.ColumnDefinition
$col2.Width = "*"


# Добавить строки и столбцы в сетку
$grid.RowDefinitions.Add($row1)
$grid.RowDefinitions.Add($row2)
$grid.RowDefinitions.Add($row3)
$grid.ColumnDefinitions.Add($col1)
$grid.ColumnDefinitions.Add($col2)


# Создать объект надписи для ввода имени компьютера
$label = New-Object System.Windows.Controls.Label
$label.Content = "Введите имя компьютера:"
$label.Margin = "10,10,10,0"
$label.VerticalAlignment = "Center"

# Создать объект кнопки для удаления приложения
$button = New-Object System.Windows.Controls.Button
$button.Content = "Удалить"
$button.Margin = "10,0,10,10"
$button.VerticalAlignment = "Center"


# Добавить надпись в сетку
$grid.Children.Add($label)
[System.Windows.Controls.Grid]::SetRow($label, 0)
[System.Windows.Controls.Grid]::SetColumn($label, 0)

# Создать объект текстового поля для ввода имени компьютера
$textbox = New-Object System.Windows.Controls.TextBox
$textbox.Margin = "10,10,10,0"
$textbox.VerticalAlignment = "Center"

# Добавить текстовое поле в сетку
$grid.Children.Add($textbox)
[System.Windows.Controls.Grid]::SetRow($textbox, 0)
[System.Windows.Controls.Grid]::SetColumn($textbox, 1)

# Добавить кнопку в сетку окна
$grid.Children.Add($button)
[System.Windows.Controls.Grid]::SetRow($button,3 )
[System.Windows.Controls.Grid]::SetColumnSpan($button, 3)

# Создать объект таблицы для отображения списка приложений
$dataGrid = New-Object System.Windows.Controls.DataGrid
$dataGrid.Margin = "10,10,10,10"
$dataGrid.IsReadOnly = $true
$dataGrid.AutoGenerateColumns = $false


# Добавить таблицу в сетку
$grid.Children.Add($dataGrid)
[System.Windows.Controls.Grid]::SetRow($dataGrid, 1)
[System.Windows.Controls.Grid]::SetColumnSpan($dataGrid, 3)

# Создать объекты столбцов для таблицы
$nameColumn = New-Object System.Windows.Controls.DataGridTextColumn
$nameColumn.Header = "Название приложения"
$nameColumn.Binding = New-Object System.Windows.Data.Binding -ArgumentList "DisplayName"
$nameColumn.Width = "*"

$versionColumn = New-Object System.Windows.Controls.DataGridTextColumn
$versionColumn.Header = "Версия приложения"
$versionColumn.Binding = New-Object System.Windows.Data.Binding -ArgumentList "DisplayVersion"
$versionColumn.Width = "*"

$uninstallColumn = New-Object System.Windows.Controls.DataGridTextColumn
$uninstallColumn.Header = "Путь деинсталятора"
$uninstallColumn.Binding = New-Object System.Windows.Data.Binding -ArgumentList "UninstallString"
$uninstallColumn.Width = "*"

# Добавить столбцы в таблицу
$dataGrid.Columns.Add($nameColumn)
$dataGrid.Columns.Add($versionColumn)
$dataGrid.Columns.Add($uninstallColumn)




# Определить функцию для получения списка приложений с удаленного компьютера по имени
function Get-RemoteApps {
    param(
        [string]$ComputerName # Имя компьютера
    )

    # Подключиться к удаленному компьютеру по PowerShell Remoting
    $session = New-PSSession -ComputerName $ComputerName

    # Выполнить команду на удаленном компьютере для получения свойств приложений из реестра Windows
    $apps = Invoke-Command -Session $session -ScriptBlock {
        $apps64 = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName}
        $apps32 = Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName }

        $apps64+$apps32
    }

    # Завершить сессию удаленного управления
    Remove-PSSession -Session $session

    # Вернуть список приложений
    return $apps
}

# Определить обработчик события нажатия клавиши Enter в текстовом поле
$textbox.Add_KeyDown({
    param(
        [object]$sender, # Источник события
        [System.Windows.Input.KeyEventArgs]$e # Аргументы события
    )

    # Проверить, что нажатая клавиша - это Enter
    if ($e.Key -eq "Enter") {
        # Получить имя компьютера из текстового поля
        $computerName = $textbox.Text

        # Попытаться получить список приложений с удаленного компьютера
        try {
            $apps = Get-RemoteApps -ComputerName $computerName

            # Очистить таблицу от предыдущих данных
            $dataGrid.ItemsSource = $null

            # Заполнить таблицу данными о приложениях
            $dataGrid.ItemsSource = $apps

        }
        catch {
            # Вывести сообщение об ошибке в консоль PowerShell
            Write-Error $_.Exception.Message
        }
    }
})

$button.Add_Click({
    param(
        [object]$sender, # Источник события
        [System.Windows.RoutedEventArgs]$e # Аргументы события
    )

    # Проверить, что в таблице выбрано приложение
    if ($dataGrid.SelectedItem) {
        # Получить имя и версию выбранного приложения
        $appName = $dataGrid.SelectedItem.DisplayName
        $appVersion = $dataGrid.SelectedItem.DisplayVersion
        $uninstallString = $dataGrid.SelectedItem.UninstallString

        $computerName = $textbox.Text

        # Подтвердить удаление приложения с помощью диалогового окна
        $result = [System.Windows.MessageBox]::Show("Вы действительно хотите удалить приложение $appName ($appVersion) с удаленного компьютера?", "Подтверждение", "YesNo", "Question")
        Write-Host "UN: $uninstallString"
        # Если пользователь подтвердил удаление
        if ($result -eq "Yes") {

            # Попытаться подключиться к удаленному компьютеру по PowerShell Remoting
            try {
                $session = New-PSSession -ComputerName $computerName

                # Выполнить команду удаления приложения на удаленном компьютере
                Invoke-Command -Session $session -ScriptBlock {
                 param(
                        [string]$AppName, # Имя приложения для удаления
                        [string]$uninstallString #Путь к деинсталятору приложения
                    )
                                       
                    # Если ключ для удаления найден, то выполнить команду для удаления приложения
                    if ($uninstallString) {
                        if ($uninstallString -like "msiexec.exe*") {
                            # Код для обработки случая, когда строка начинается с "msiexec.exe"
                            msiexec.exe /x $key.PSChildName /qn
                        } else {
                            # Код для обработки случая, когда строка не начинается с "msiexec.exe"
                            $uninstallString = "`"$uninstallString`""
                            Start-Process -FilePath $uninstallString.ToLower() -ArgumentList "/S /SILENT /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" -Wait
                        }

                    }
                } -ArgumentList $appName, $uninstallString

                try {
                    $apps = Get-RemoteApps -ComputerName $computerName

                    # Очистить таблицу от предыдущих данных
                    $dataGrid.ItemsSource = $null

                    # Заполнить таблицу данными о приложениях
                    $dataGrid.ItemsSource = $apps

                }
                catch {
                    # Вывести сообщение об ошибке в консоль PowerShell
                    Write-Error $_.Exception.Message
                }

                # Завершить сессию удаленного управления
                Remove-PSSession -Session $session

                # Вывести сообщение об успешном удалении приложения в консоль PowerShell
                Write-Host "Приложение $appName ($appVersion) успешно удалено с компьютера $computerName"

                # Обновить список приложений в таблице
                $apps = Get-RemoteApps -ComputerName $computerName
                $dataGrid.ItemsSource = $null
                $dataGrid.ItemsSource = $apps
            }
            catch {
                # Вывести сообщение об ошибке в консоль PowerShell
                Write-Error $_.Exception.Message
            }
        }
    }
    else {
        # Вывести сообщение о том, что нужно выбрать приложение в таблице в консоль PowerShell
        Write-Host "Пожалуйста, выберите приложение в таблице для удаления"
    }
})

# Отобразить окно на экране
$window.ShowDialog()
