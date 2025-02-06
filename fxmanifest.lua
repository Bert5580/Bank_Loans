fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Bank Loan System with QB-Core Integration'
version 'Qv1.0.4'

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
    'qb-core',
    'oxmysql'
}
