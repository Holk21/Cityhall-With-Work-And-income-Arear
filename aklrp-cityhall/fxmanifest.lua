fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'aklrp-cityhall'
author 'Braiden Marshall (modified for Qbox/QBCore + ox_target/qb-target by ChatGPT)'
description 'City Hall / WINZ for Qbox & QBCore with ox_target/qb-target support'
version '1.4.0'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/app.js'
}

client_scripts {
  'client/main.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/main.lua'
}

-- Don’t hard-require target resources so either one can be used.
-- Keep core optional too: we detect qbx_core or qb-core at runtime.
-- dependencies { 'oxmysql' }
