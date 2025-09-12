fx_version 'cerulean'
game 'gta5'

name 'aklrp-cityhall'
author 'Braiden Marshall'
description 'City Hall / WINZ for QBCore: job selection, buy licenses/ID card, and Food Grant applications.'
version '1.1.0'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/app.js'
}

shared_script 'config.lua'

client_scripts {
  '@qb-target/shared.lua',
  'client/main.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/main.lua'
}

dependencies {
  'qb-core',
  'qb-target'
}
