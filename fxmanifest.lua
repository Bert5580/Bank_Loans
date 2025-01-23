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
    'locales/en.lua', -- Localization file for English
    'client.lua'
}

-- Server Scripts
server_scripts {
    '@mysql-async/lib/MySQL.lua', -- MySQL Async for database interaction
    'config.lua',
    'server.lua'
}

-- UI Files
ui_page 'html/index.html'

files {
    'html/index.html', -- Main HTML file for the UI
    'html/style.css',  -- CSS for styling the UI
    'html/script.js'   -- JS for UI functionality
}

-- Dependencies
dependencies {
    'qb-core', -- Core framework
    'qb-menu', -- Menu system for interactions
    'mysql-async' -- Ensure MySQL Async is available for database queries
}
