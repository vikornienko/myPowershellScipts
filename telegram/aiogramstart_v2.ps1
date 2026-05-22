

# =============================================================================
# Скрипт для старта проекта на aiogram и автоматической установки зависимостей.
# Версия: 2.0.0
# Автор В.И. Корниенко vikornienko76@gmail.com
# Скрипт автоматизирует старт проекта telegram bot на aiogram3.
# =============================================================================

# --- Настройки ---
$ErrorActionPreference = "Stop"

# Зависимости для установки через uv
$Dependencies = @(
    "aiogram",
    "python-decouple",
    "aiosqlite",
    "sqlalchemy"
)

# Содержимое .gitignore
$GitignoreContent = @"
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Logs
/logs/

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.py,cover
.hypothesis/
.pytest_cache/
cover/

# Translations
*.mo
*.pot

# Django stuff:
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal

# Flask stuff:
instance/
.webassets-cache

# Scrapy stuff:
.scrapy

# Sphinx documentation
docs/_build/

# PyBuilder
.pybuilder/
target/

# Jupyter Notebook
.ipynb_checkpoints

# IPython
profile_default/
ipython_config.py

# PEP 582; used by e.g. github.com/David-OConnor/pyflow
__pypackages__/

# Celery stuff
celerybeat-schedule
celerybeat.pid

# SageMath parsed files
*.sage.py

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
.dmypy.json
dmypy.json

# Pyre type checker
.pyre/

# pytype static type analyzer
.pytype/

# Cython debug symbols
cython_debug/

# Editors
.vscode/
.idea/

# Vagrant
.vagrant/

# Mac/OSX
.DS_Store

# Windows
Thumbs.db

# pyenv
.python-version

# Project specific
functionalTesting/geckodriver.log
functionalTesting/swb/geckodriver
/other_files/
/getinfoapp/files/
"@

# Шаблон стартового файла бота
$BotStarterContent = @"
import asyncio

from aiogram import Bot, Dispatcher
from aiogram.filters import Command
from aiogram.types import Message
from decouple import config

dp = Dispatcher()


# Command handler
@dp.message(Command("start"))
async def command_start_handler(message: Message) -> None:
    await message.answer("Hello! I'm a bot created with aiogram.")


# Run the bot
async def main() -> None:
    bot = Bot(token=config("BOT_TOKEN"))
    await dp.start_polling(bot)


if __name__ == "__main__":
    asyncio.run(main())
"@

# =============================================================================
# Вспомогательные функции
# =============================================================================

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("INFO", "SUCCESS", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        INFO    = "Cyan"
        SUCCESS = "Green"
        WARN    = "Yellow"
        ERROR   = "Red"
    }
    $color = $colorMap[$Level]
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Request-UserCancel {
    <#
    .SYNOPSIS
    Проверяет, хочет ли пользователь прервать выполнение скрипта.
    Возвращает $true, если пользователь ввёл "q" или "quit".
    #>
    param(
        [string]$Prompt = "Нажмите Enter для продолжения или введите 'q' для отмены"
    )

    Write-Host "$Prompt : " -NoNewline -ForegroundColor DarkGray
    $input_val = Read-Host

    if ($input_val -in @("q", "quit", "Q", "Quit", "QUIT")) {
        Write-Log "Выполнение прервано пользователем." -Level WARN
        return $true
    }
    return $false
}

# =============================================================================
# Основные функции скрипта
# =============================================================================

function Get-UserInput {
    <#
    .SYNOPSIS
    Запрашивает у пользователя наименование проекта и версию Python.
    #>

    Write-Log "Запрос входных данных у пользователя..."

    # --- Наименование проекта ---
    while ($true) {
        $script:ProjectName = Read-Host "Введите наименование проекта"

        if ([string]::IsNullOrWhiteSpace($script:ProjectName)) {
            Write-Log "Наименование проекта не может быть пустым." -Level WARN
            continue
        }

        if ($script:ProjectName -match '[<>:"/\\|?*]') {
            Write-Log "Наименование содержит недопустимые символы: < > : "" / \ | ? *" -Level WARN
            continue
        }
        break
    }

    # --- Версия Python ---
    while ($true) {
        $script:PythonVersion = Read-Host "Введите версию Python (например, 3.12)"

        if ([string]::IsNullOrWhiteSpace($script:PythonVersion)) {
            Write-Log "Версия Python не может быть пустой." -Level WARN
            continue
        }

        if ($script:PythonVersion -notmatch '^\d+\.\d+(\.\d+)?$') {
            Write-Log "Некорректный формат версии. Используйте формат: X.Y или X.Y.Z" -Level WARN
            continue
        }
        break
    }

    Write-Log "Проект: $script:ProjectName | Python: $script:PythonVersion" -Level SUCCESS
}

function Confirm-Proceed {
    <#
    .SYNOPSIS
    Спрашивает пользователя, продолжать ли создание проекта.
    #>

    Write-Host ""
    Write-Host "--- Подтверждение ---" -ForegroundColor White
    Write-Host "  Проект:   $script:ProjectName"
    Write-Host "  Python:   $script:PythonVersion"
    Write-Host "  Путь:     $(Join-Path $PWD $script:ProjectName)"
    Write-Host ""

    if (Request-UserCancel "Продолжить? (Enter — да, q — отмена)") {
        exit 0
    }
}

function Initialize-ProjectFolder {
    <#
    .SYNOPSIS
    Проверяет наличие папки проекта и создаёт её при необходимости.
    #>

    $projectPath = Join-Path $PWD $script:ProjectName

    if (Test-Path $projectPath) {
        Write-Log "Папка '$script:ProjectName' уже существует." -Level WARN
        if (Request-UserCancel "Использовать существующую папку? (Enter — да, q — отмена)") {
            exit 0
        }
    }
    else {
        New-Item -ItemType Directory -Path $projectPath | Out-Null
        Write-Log "Папка '$script:ProjectName' создана." -Level SUCCESS
    }

    $script:ProjectPath = $projectPath
}

function Initialize-UvProject {
    <#
    .SYNOPSIS
    Инициализирует проект через uv, проверяет/создаёт виртуальное окружение.
    #>

    Set-Location $script:ProjectPath
    Write-Log "Рабочая директория: $script:ProjectPath"

    # Инициализация uv
    Write-Log "Инициализация проекта через uv..."
    uv python pin $script:PythonVersion
    uv init . --bare | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) {
        throw "Ошибка при выполнении 'uv init'."
    }
    Write-Log "uv init выполнен успешно." -Level SUCCESS

    # Проверка .python-version и .venv
    $pythonVersionFile = Join-Path $script:ProjectPath ".python-version"
    $venvPath = Join-Path $script:ProjectPath ".venv"
    $needVenv = $false

    if (-not (Test-Path $pythonVersionFile)) {
        Write-Log "Файл .python-version не найден." -Level WARN
        $needVenv = $true
    }
    else {
        Write-Log "Файл .python-version найден."
    }

    if (-not (Test-Path $venvPath)) {
        Write-Log "Папка .venv не найдена." -Level WARN
        $needVenv = $true
    }
    else {
        Write-Log "Папка .venv найдена."
    }

    if ($needVenv) {
        Write-Log "Создание виртуального окружения (Python $script:PythonVersion)..."
        uv venv --python $script:PythonVersion 2>&1 | ForEach-Object { Write-Host "  $_" }
        if ($LASTEXITCODE -ne 0) {
            throw "Ошибка при создании виртуального окружения. Убедитесь, что Python $script:PythonVersion доступен в системе."
        }
        Write-Log "Виртуальное окружение создано." -Level SUCCESS
    }
}

function Install-Dependencies {
    <#
    .SYNOPSIS
    Устанавливает зависимости проекта через uv.
    #>

    Write-Log "Установка зависимостей..."

    foreach ($dep in $script:Dependencies) {
        Write-Log "  -> $dep"
        uv add $dep 2>&1 | ForEach-Object { Write-Host "    $_" }
        if ($LASTEXITCODE -ne 0) {
            throw "Ошибка при установке зависимости '$dep'."
        }
    }

    Write-Log "Все зависимости установлены." -Level SUCCESS
}

function New-Gitignore {
    <#
    .SYNOPSIS
    Создаёт файл .gitignore с заданным содержанием.
    #>

    $gitignorePath = Join-Path $script:ProjectPath ".gitignore"

    if (Test-Path $gitignorePath) {
        Write-Log "Файл .gitignore уже существует — перезапись." -Level WARN
    }

    Set-Content -Path $gitignorePath -Value $GitignoreContent -Encoding UTF8NoBOM
    Write-Log "Файл .gitignore создан." -Level SUCCESS
}

function New-Readme {
    <#
    .SYNOPSIS
    Запрашивает описание проекта и создаёт README.md.
    #>

    $projectDescription = Read-Host "Введите описание проекта"

    if ([string]::IsNullOrWhiteSpace($projectDescription)) {
        $projectDescription = "Telegram-бот на aiogram 3"
        Write-Log "Описание не указано, используется значение по умолчанию." -Level WARN
    }

    $readmeContent = @"
# $($script:ProjectName)

$projectDescription

## Технологии

- Python $($script:PythonVersion)
- [aiogram 3](https://docs.aiogram.dev/)
- python-dotenv

## Запуск

1. Создайте файл `.env` и укажите токен бота:

``

BOT_TOKEN=your_bot_token_here

``

2. Активируйте виртуальное окружение и запустите бота:

```bash
.venv\Scripts\Activate.ps1
python src\bot.py
```
"@

    $readmePath = Join-Path $script:ProjectPath "README.md"
    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8NoBOM
    Write-Log "Файл README.md создан." -Level SUCCESS
}

function New-EnvFile {
    <#
    .SYNOPSIS
    Запрашивает токен бота и создаёт файл .env.
    #>

    $botToken = Read-Host "Введите токен Telegram-бота"

    if ([string]::IsNullOrWhiteSpace($botToken)) {
        Write-Log "Токен не указан. Файл .env будет создан с пустым значением BOT_TOKEN." -Level WARN
        $botToken = ""
    }

    $envPath = Join-Path $script:ProjectPath ".env"
    Set-Content -Path $envPath -Value "BOT_TOKEN=$botToken" -Encoding UTF8NoBOM
    Write-Log "Файл .env создан." -Level SUCCESS
}

function New-SourceDirectory {
    <#
    .SYNOPSIS
    Создаёт папку src и стартовый файл бота.
    #>

    $srcPath = Join-Path $script:ProjectPath "src"

    if (-not (Test-Path $srcPath)) {
        New-Item -ItemType Directory -Path $srcPath | Out-Null
        Write-Log "Папка src создана." -Level SUCCESS
    }
    else {
        Write-Log "Папка src уже существует."
    }

    $botFilePath = Join-Path $srcPath "bot.py"
    Set-Content -Path $botFilePath -Value $BotStarterContent -Encoding UTF8NoBOM
    Write-Log "Файл src\bot.py создан." -Level SUCCESS
}

# =============================================================================
# Точка входа
# =============================================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  Создание проекта Telegram-бота (aiogram 3)" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

try {
    Get-UserInput
    Confirm-Proceed
    Initialize-ProjectFolder
    Initialize-UvProject
    Install-Dependencies
    New-Gitignore
    New-Readme
    New-EnvFile
    New-SourceDirectory

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  Проект успешно создан!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Log "Путь к проекту: $script:ProjectPath" -Level SUCCESS
    Write-Host ""
    Write-Host "Следующие шаги:" -ForegroundColor White
    Write-Host "  1. cd $script:ProjectName"
    Write-Host "  2. .venv\Scripts\Activate.ps1"
    Write-Host "  3. python src\bot.py"
    Write-Host ""
}
catch {
    Write-Log "Ошибка: $_" -Level ERROR
    Write-Log "Выполнение скрипта прервано." -Level ERROR
    exit 1
}
