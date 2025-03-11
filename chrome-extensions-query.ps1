# ����Ŀ¼·��
$directory = "C:\Users\Administrator\AppData\Local\Google\Chrome\User Data\Default\Extensions"

# ����һ�����������ڴ� _locales Ŀ¼�ж�ȡ��Ϣֵ
function Get-MessageValue {
    param (
        [string]$MessageKey,   # ��Ϣ������ __MSG_application_title__��
        [string]$ManifestPath  # manifest.json ���ڵ�Ŀ¼·��
    )

    # ȥ�� __MSG_ ǰ׺�� __ ��׺����ȡ��Ϣ��
    $messageKey = $MessageKey -replace "^__MSG_", "" -replace "__$", ""

    # ���� _locales Ŀ¼
    $localesPath = Join-Path -Path $ManifestPath -ChildPath "_locales"
    if (-not (Test-Path -Path $localesPath)) {
        Write-Host "Warning: _locales directory not found for $ManifestPath"
        return $MessageKey
    }

    # ��ȡĬ�����ԣ�ͨ���� en��
    $defaultLanguage = "zh_CN"
    $messagesPath = Join-Path -Path $localesPath -ChildPath "$defaultLanguage\messages.json"

    # ���Ĭ�������ļ������ڣ��������������ļ�
    if (-not (Test-Path -Path $messagesPath)) {
        $languages = Get-ChildItem -Path $localesPath -Directory
        if ($languages.Count -eq 0) {
            Write-Host "Warning: No language files found in _locales for $ManifestPath"
            return $MessageKey
        }
        $messagesPath = Join-Path -Path $localesPath -ChildPath "$($languages[0].Name)\messages.json"
    }

    # ����ļ��Ƿ����
    if (-not (Test-Path -Path $messagesPath)) {
        Write-Host "Warning: messages.json file not found at $messagesPath"
        return $MessageKey
    }

    # ��ȡ�ļ����ݲ�����ת��Ϊ JSON
    try {
        $messagesContent = Get-Content -Path $messagesPath -Raw -Encoding UTF8 -ErrorAction Stop

        # ����ļ����ݲ������������޸�
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

# ��ȡĿ¼�����е� manifest.json �ļ�
$manifestFiles = Get-ChildItem -Path $directory -Recurse -Filter "manifest.json"

# ����ÿ���ļ�����ȡ name �� description
foreach ($file in $manifestFiles) {
    # ��ȡ�ļ����ݲ�ת��Ϊ JSON ����
    $jsonContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json

    # ��ȡ name �� description
    $name = $jsonContent.name
    $description = $jsonContent.description

    # ��� name �� __MSG_ ��ͷ��ռλ������ȡʵ��ֵ
    if ($name -like "__MSG_*") {
        $name = Get-MessageValue -MessageKey $name -ManifestPath $file.DirectoryName
    }

    # ��� description �� __MSG_ ��ͷ��ռλ������ȡʵ��ֵ
    if ($description -like "__MSG_*") {
        $description = Get-MessageValue -MessageKey $description -ManifestPath $file.DirectoryName
    }

    # ������
    Write-Host "File: $($file.FullName)"
    Write-Host "Name: $name"
    Write-Host "Description: $description"
    Write-Host "-----------------------------"
}

pause