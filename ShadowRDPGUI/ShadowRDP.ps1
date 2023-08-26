[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -assembly System.Windows.Forms
$Header = "SESSIONNAME", "USERNAME", "ID", "STATUS"
$dlgForm = New-Object System.Windows.Forms.Form
$dlgForm.Text ='SRDP GUI v 0.9 beta-early-access-concept-edition'
$dlgForm.Width = 400
$dlgForm.AutoSize = $true

# Добавляем текстовое поле для ввода IP-адреса
$dlgText = New-Object System.Windows.Forms.TextBox
$dlgText.Location = New-Object System.Drawing.Point(15,10)
$dlgText.Width = 200
$dlgText.Text = "Введите IP-адрес хоста"
$dlgForm.Controls.Add($dlgText)

# Добавляем кнопку для заполнения таблицы сеансов
$dlgBttn = New-Object System.Windows.Forms.Button
$dlgBttn.Text = 'Поиск'
$dlgBttn.Location = New-Object System.Drawing.Point(230,10)
$dlgForm.Controls.Add($dlgBttn)

# Добавляем таблицу для отображения сеансов
$dlgList = New-Object System.Windows.Forms.ListView
$dlgList.Location = New-Object System.Drawing.Point(0,50)
$dlgList.Width = $dlgForm.ClientRectangle.Width
$dlgList.Height = $dlgForm.ClientRectangle.Height
$dlgList.Anchor = "Top, Left, Right, Bottom"
$dlgList.MultiSelect = $False
$dlgList.View = 'Details'
$dlgList.FullRowSelect = 1;
$dlgList.GridLines = 1
$dlgList.Scrollable = 1
$dlgForm.Controls.add($dlgList)

# Добавляем столбцы в таблицу
foreach ($column in $Header){
$dlgList.Columns.Add($column) | Out-Null
}

# Добавляем обработчик события нажатия на кнопку заполнения таблицы
$dlgBttn.Add_Click(
{
    # Получаем IP-адрес из текстового поля
    $server_ip = $dlgText.Text

    # Проверяем, что IP-адрес валидный
    if ($server_ip -match "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"){
        # Очищаем таблицу от предыдущих данных
        $dlgList.Items.Clear()
        Write-Host "IP-адрес сервера: $server_ip"
        # Получаем данные о сеансах на сервере с помощью команды qwinsta.exe и фильтруем активные сеансы
        $(qwinsta.exe /server:$server_ip | findstr "Active") -replace "^[\s>]" , "" -replace "\s+" , "," | ConvertFrom-Csv -Header $Header | ForEach-Object {
            # Добавляем данные о сеансе в таблицу
            $dlgListItem = New-Object System.Windows.Forms.ListViewItem($_.SESSIONNAME)
            $dlgListItem.Subitems.Add($_.USERNAME) | Out-Null
            $dlgListItem.Subitems.Add($_.ID) | Out-Null
            $dlgListItem.Subitems.Add($_.STATUS) | Out-Null
            $dlgList.Items.Add($dlgListItem) | Out-Null
        }
    } else {
        # Выводим сообщение об ошибке, если IP-адрес невалидный
        [System.Windows.Forms.MessageBox]::Show("Введите корректный IP-адрес")
    }
}
)

# Добавляем обработчик события двойного клика по элементу таблицы для подключения к сеансу
$dlgList.Add_DoubleClick(
{
    # Получаем выбранный элемент таблицы
    $SelectedItem = $dlgList.SelectedItems[0]
    $server_ip = $dlgText.Text

    if ($SelectedItem -ne $null){
        # Получаем ID сеанса из выбранного элемента таблицы
        $session_id = $SelectedItem.subitems[2].text
        Write-Host "ID сеанса: $session_id"
        # Подключаемся к сеансу с помощью команды mstsc /shadow /control
        $(mstsc /shadow:$session_id /v:$server_ip /control)
    }
}
)

# Отображаем форму на экране
$dlgForm.ShowDialog()
