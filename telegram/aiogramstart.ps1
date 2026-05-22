# Скрипт для старта проекта на aiogram и автоматической установки зависимостей.
# Версия: 0.0.2
# Автор В.И. Корниенко vikornienko76@gmail.com
# Скрипт автоматизирует старт проекта telegram bot на aiogram3.


function Add-ProjectParameters {
    # Запрашивает имя проекта и версию Python
    [CmdletBinding()]
    param ()
    $projectName = Read-Host "Write project name: "
    $pythonVersion = Read-Host "Write python version: "

    # Возвращает хеш-таблицу с параметрами
    @{
        ProjectName = $projectName
        PythonVersion = $pythonVersion
    }
    
}

function New-ProjectDirectory {
    # Создаёт папку проекта и переходит в неё
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )
    
    try {
        New-Item -ItemType Directory -Name $ProjectName -ErrorAction Stop | Out-Null
        Set-Location $ProjectName
        Write-Host "Folder '$ProjectName' created." -ForegroundColor Green
    }
    catch {
        Write-Error "Не удалось создать папку '$ProjectName': $_"
        throw
    }
}

function Initialize-VirtualEnvironment {
    # Создаёт виртуальное окружение с указанной версией Python
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonVersion        
    )
    
    try {
        uv pin python $PythonVersion -ErrorAction Stop
        uv init . --bare --python $PythonVersion -ErrorAction Stop
        uv venv -ErrorAction Stop
        Write-Host "Виртуальное окружение '$VenvName' создано с Python $PythonVersion." -ForegroundColor Green
    }
    catch {
        Write-Error "Ошибка при создании виртуального окружения: $_"
        throw
    }
}

function Install-Dependencies {
    # Устанавливает зависимости (aiogram) в виртуальное окружение
            
    try {
        uv add aiogram aiosqlite sqlalchemy python-decouple -ErrorAction Stop
        Write-Host "Зависимости успешно установлены." -ForegroundColor Green
    }
    catch {
        Write-Error "Ошибка при установке зависимостей: $_"
        throw
    }
}

function New-GitignoreFile {
    # Создаёт файл .gitignore с типовым содержимым для Python-проектов
    [CmdletBinding()]
    param(
        [string]$Path = '.\.gitignore'
    )
    
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
    
    try {
        $gitignoreContent | Out-File -FilePath $Path -Encoding utf8 -ErrorAction Stop
        Write-Host ".gitignore создан." -ForegroundColor Green
    }
    catch {
        Write-Error "Не удалось создать .gitignore: $_"
        throw
    }
}

function New-BotStarterFile {
    # Создаёт простой файл bot.py для первичного старта проекта
    [CmdletBinding()]
    param(
        [string]$Path = '.\bot.py'
    )
    
    $botContent = @"
import asyncio
from aiogram import Bot, Dispatcher, types
from aiogram.enums import ParseMode
from aiogram.filters import CommandStart
from aiogram.types import Message

# Токен бота (замените на свой)
BOT_TOKEN = "YOUR_BOT_TOKEN_HERE"

bot = Bot(token=BOT_TOKEN)
dp = Dispatcher()

@dp.message(CommandStart())
async def command_start_handler(message: Message) -> None:
    await message.answer(f"Hello, {message.from_user.full_name}!")

async def main() -> None:
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())
"@
    
    try {
        $botContent | Out-File -FilePath $Path -Encoding utf8 -ErrorAction Stop
        Write-Host "Файл bot.py создан." -ForegroundColor Green
    }
    catch {
        Write-Error "Не удалось создать bot.py: $_"
        throw
    }
}

function Main {
    # Основная логика скрипта
    $params = Add-ProjectParameters

    if (-not $params.ProjectName -or -not $params.PythonVersion) {
        Write-Error "Project name and Python version are required."
        return
    }

    New-ProjectDirectory -ProjectName $params.ProjectName
    Initialize-VirtualEnvironment -PythonVersion $params.PythonVersion
    Install-Dependencies
    New-GitignoreFile
    New-BotStarterFile

    Write-Host "`nПроект '$($params.ProjectName)' успешно настроен." -ForegroundColor Cyan
    
}
# Запуск скрипта
Main