fx_version 'cerulean'
game 'gta5'

name 'aklrp-cityhall'
author 'Braiden Marshall (modified)'
description 'City Hall / WINZ for QBCore: job selection, buy licenses/ID card, and Food Grant applications. (With webhooks + debug)'
version '1.3.0-debug'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/app.js'
}

shared_script 'config.lua'

client_scripts {
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
