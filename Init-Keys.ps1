<#
.SYNOPSIS
Заменяет шаблоны вида {key}, {password} и их варианты с указанием длины на криптостойкие случайные строки.
#>

param(
    [Parameter()]
    [string]$FilePath = ".env.example",
    
    [Parameter()]
    [string]$OutputPath = ".env"
)

function New-CryptographicRandomString {
    param(
        [int]$Length,
        [string]$CharacterSet
    )
    
    # Используем криптостойкий генератор случайных чисел
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = [byte[]]::new($Length)
    $rng.GetBytes($bytes)
    
    $result = [char[]]::new($Length)
    $setLength = $CharacterSet.Length
    
    for ($i = 0; $i -lt $Length; $i++) {
        $result[$i] = $CharacterSet[$bytes[$i] % $setLength]
    }
    
    $rng.Dispose()
    return [string]::new($result)
}

# Проверка существования файла
if (-not (Test-Path $FilePath)) {
    Write-Error "Файл '$FilePath' не найден"
    exit 1
}

# Читаем содержимое файла
$content = Get-Content -Path $FilePath -Raw -Encoding UTF8

# Определяем наборы символов
$keyCharset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
$passwordCharset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";#!@#$%^&*-_=+"

$content = [regex]::Replace($content, '{key(?:[:](\d+))?}', {
    param($match)
    
    # Определяем длину
    $length = 32
    if ($match.Groups[1].Success) {
        $length = [int]$match.Groups[1].Value
    }
    
    # Генерируем уникальное значение для ЭТОГО конкретного вхождения
    $unique = New-CryptographicRandomString -Length $length -CharacterSet $keyCharset
    Write-Host "Замена '$($match.Value)' на уникальный ключ" -ForegroundColor Green
    
    return $unique
})

$content = [regex]::Replace($content, '{password(?:[:](\d+))?}', {
    param($match)
    
    # Определяем длину
    $length = 24
    if ($match.Groups[1].Success) {
        $length = [int]$match.Groups[1].Value
    }
    
    # Генерируем уникальное значение для ЭТОГО конкретного вхождения
    $unique = New-CryptographicRandomString -Length $length -CharacterSet $passwordCharset
    Write-Host "Замена '$($match.Value)' на уникальный пароль" -ForegroundColor Yellow
    
    return $unique
})

# Сохраняем результат
if (-not (Test-Path $OutputPath)) {
    $content | Set-Content -Path $OutputPath -Encoding UTF8 -NoNewline
    Write-Host "Результат сохранен в файл: $OutputPath" -ForegroundColor Cyan
} else {
    # Создаем резервную копию
    $backupPath = "$OutputPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item -Path $OutputPath -Destination $backupPath
    Write-Host "Создана резервная копия: $backupPath" -ForegroundColor Cyan
    
    $content | Set-Content -Path $OutputPath -Encoding UTF8 -NoNewline
    Write-Host "Файл обновлен: $OutputPath" -ForegroundColor Cyan
}