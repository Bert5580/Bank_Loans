fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Bank Loan System with ESX Legacy Integration'
version '2.1.0'

lua54 'yes'

client_scripts {
    'config.lua',
    'locales/en.lua',
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server.lua'
}

dependencies {
    'es_extended',
    'oxmysql'
}
