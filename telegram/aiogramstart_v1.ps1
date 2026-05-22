# Требование строгого прерывания при возникновении ошибок
$ErrorActionPreference = 'Stop'

function Get-ProjectDetails {
    Write-Host "=== Запрос параметров проекта ===" -ForegroundColor Cyan
    $projectName = Read-Host "Введите наименование проекта"
    if ([string]::IsNullOrWhiteSpace($projectName)) { 
        throw "Наименование проекта не может быть пустым." 
    }
    
    $pythonVersion = Read-Host "Введите версию Python (например, 3.11 или 3.12)"
    if ([string]::IsNullOrWhiteSpace($pythonVersion)) { 
        throw "Версия Python не может быть пустой." 
    }
    
    return @{
        Name = $projectName
        PythonVersion = $pythonVersion
    }
}

function Initialize-ProjectDirectory {
    param([string]$ProjectName)
    Write-Host "`n=== Создание и переход в папку проекта ===" -ForegroundColor Cyan
    
    if (-not (Test-Path -Path $ProjectName)) {
        New-Item -ItemType Directory -Path $ProjectName | Out-Null
        Write-Host "Папка '$ProjectName' успешно создана." -ForegroundColor Green
    } else {
        Write-Host "Папка '$ProjectName' уже существует." -ForegroundColor Yellow
    }
    
    Set-Location -Path $ProjectName
    Write-Host "Выполнен переход в директорию: $(Get-Location)" -ForegroundColor Green
}

# function Initialize-UvProject {
#     Write-Host "`n=== Инициализация uv в папке ===" -ForegroundColor Cyan
#     uv python pin $PythonVersion
#     uv init . --bare
#     if ($LASTEXITCODE -ne 0) { throw "Ошибка инициализации проекта uv." }
#     Write-Host "Проект uv успешно инициализирован." -ForegroundColor Green
# }

function Initialize-VirtualEnvironment {
    param([string]$PythonVersion)
    Write-Host "`n=== Настройка виртуального окружения ===" -ForegroundColor Cyan
    
    $hasPythonVersionFile = Test-Path -Path ".python-version"
    $hasVenvFolder = Test-Path -Path ".venv"
    
    if (-not $hasPythonVersionFile -or -not $hasVenvFolder) {
        Write-Host "Файл .python-version или папка .venv отсутствуют. Создание окружения для Python $PythonVersion..." -ForegroundColor Yellow
        uv python pin $PythonVersion
        uv init . --bare --python $PythonVersion
        uv venv
        if ($LASTEXITCODE -ne 0) { throw "Ошибка создания виртуального окружения." }
        Write-Host "Виртуальное окружение успешно создано." -ForegroundColor Green
    } else {
        Write-Host "Виртуальное окружение и файл .python-version уже существуют." -ForegroundColor Yellow
    }
}

function Install-Dependencies {
    Write-Host "`n=== Установка зависимостей ===" -ForegroundColor Cyan
    Write-Host "Установка aiogram и других библиотек..." -ForegroundColor Yellow
    uv add aiogram aiosqlite sqlalchemy python-decouple
    if ($LASTEXITCODE -ne 0) { throw "Ошибка установки зависимостей." }
    Write-Host "Зависимости успешно установлены." -ForegroundColor Green
}

function New-Gitignore {
    Write-Host "`n=== Создание файла .gitignore ===" -ForegroundColor Cyan
    $gitignoreContent = @"
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
    Set-Content -Path ".gitignore" -Value $gitignoreContent -Encoding UTF8
    Write-Host "Файл .gitignore успешно создан." -ForegroundColor Green
}

# function New-Readme {
#     param([string]$ProjectName)
#     Write-Host "`n=== Создание файла README.md ===" -ForegroundColor Cyan
#     $description = Read-Host "Введите описание проекта"
    
#     $readmeContent = @"
# # $ProjectName

# $description

# ## Стек
# - Python
# - aiogram 3
# - uv

# ## Запуск
# 1. Установите зависимости: ``uv sync``
# 2. Запустите бота: ``python src/bot.py``
# "@
#     Set-Content -Path "README.md" -Value $readmeContent -Encoding UTF8
#     Write-Host "Файл README.md успешно создан." -ForegroundColor Green
# }

function New-SourceStructure {
    Write-Host "`n=== Создание структуры исходного кода ===" -ForegroundColor Cyan
    
    if (-not (Test-Path -Path "src")) {
        New-Item -ItemType Directory -Path "src" | Out-Null
    }
    
    $botCode = @"
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
    Set-Content -Path "src/bot.py" -Value $botCode -Encoding UTF8
    Write-Host "Папка src и файл bot.py успешно созданы." -ForegroundColor Green
}

# Главная точка входа
try {
    $details = Get-ProjectDetails
    Initialize-ProjectDirectory -ProjectName $details.Name
    # Initialize-UvProject
    Initialize-VirtualEnvironment -PythonVersion $details.PythonVersion
    Install-Dependencies
    New-Gitignore
    # New-Readme -ProjectName $details.Name
    New-SourceStructure
    
    Write-Host "`n=== Проект успешно создан и готов к разработке! ===" -ForegroundColor Green
} catch {
    Write-Host "`nКРИТИЧЕСКАЯ ОШИБКА: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Выполнение скрипта прервано на этапе: $($_.InvocationInfo.InvocationName)" -ForegroundColor Red
    exit 1
}