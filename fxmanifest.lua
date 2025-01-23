fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Bank Loan System for QB-Core'
version '1.0.0'

-- Lua 5.4 Enablement
lua54 'yes'

-- Client Scripts
client_scripts {
    'config.lua',
    'locales/en.lua',
    'client.lua'
}

-- Server Scripts
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server.lua'
}

-- UI Files
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

-- Dependencies
dependencies {
    'qb-core',
    'qb-menu',
    'oxmysql'
}
