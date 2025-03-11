# 定义目录路径
$directory = "C:\Users\Administrator\AppData\Local\Google\Chrome\User Data\Default\Extensions"

# 定义一个函数，用于从 _locales 目录中读取消息值
function Get-MessageValue {
    param (
        [string]$MessageKey,   # 消息键（如 __MSG_application_title__）
        [string]$ManifestPath  # manifest.json 所在的目录路径
    )

    # 去掉 __MSG_ 前缀和 __ 后缀，获取消息键
    $messageKey = $MessageKey -replace "^__MSG_", "" -replace "__$", ""

    # 查找 _locales 目录
    $localesPath = Join-Path -Path $ManifestPath -ChildPath "_locales"
    if (-not (Test-Path -Path $localesPath)) {
        Write-Host "Warning: _locales directory not found for $ManifestPath"
        return $MessageKey
    }

    # 获取默认语言（通常是 en）
    $defaultLanguage = "zh_CN"
    $messagesPath = Join-Path -Path $localesPath -ChildPath "$defaultLanguage\messages.json"

    # 如果默认语言文件不存在，尝试其他语言文件
    if (-not (Test-Path -Path $messagesPath)) {
        $languages = Get-ChildItem -Path $localesPath -Directory
        if ($languages.Count -eq 0) {
            Write-Host "Warning: No language files found in _locales for $ManifestPath"
            return $MessageKey
        }
        $messagesPath = Join-Path -Path $localesPath -ChildPath "$($languages[0].Name)\messages.json"
    }

    # 检查文件是否存在
    if (-not (Test-Path -Path $messagesPath)) {
        Write-Host "Warning: messages.json file not found at $messagesPath"
        return $MessageKey
    }

    # 读取文件内容并尝试转换为 JSON
    try {
        $messagesContent = Get-Content -Path $messagesPath -Raw -Encoding UTF8 -ErrorAction Stop

        # 如果文件内容不完整，尝试修复
        if (-not ($messagesContent -match "\}$")) {
            $messagesContent = $messagesContent.Trim() 
            #Write-Host "Fixed incomplete JSON in $messagesPath"
        }

        $messagesContent = $messagesContent | ConvertFrom-Json -ErrorAction Stop
        if ($messagesContent.$messageKey) {
            return $messagesContent.$messageKey.message
        } else {
            Write-Host "Warning: Message key '$messageKey' not found in $messagesPath"
            return $MessageKey
        }
    } catch {
        Write-Host "Error: Failed to parse JSON from $messagesPath. Ensure the file is valid JSON."
        return $MessageKey
    }
}

# 获取目录下所有的 manifest.json 文件
$manifestFiles = Get-ChildItem -Path $directory -Recurse -Filter "manifest.json"

# 遍历每个文件并读取 name 和 description
foreach ($file in $manifestFiles) {
    # 读取文件内容并转换为 JSON 对象
    $jsonContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json

    # 提取 name 和 description
    $name = $jsonContent.name
    $description = $jsonContent.description

    # 如果 name 是 __MSG_ 开头的占位符，读取实际值
    if ($name -like "__MSG_*") {
        $name = Get-MessageValue -MessageKey $name -ManifestPath $file.DirectoryName
    }

    # 如果 description 是 __MSG_ 开头的占位符，读取实际值
    if ($description -like "__MSG_*") {
        $description = Get-MessageValue -MessageKey $description -ManifestPath $file.DirectoryName
    }

    # 输出结果
    Write-Host "File: $($file.FullName)"
    Write-Host "Name: $name"
    Write-Host "Description: $description"
    Write-Host "-----------------------------"
}

pause