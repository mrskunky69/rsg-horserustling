fx_version "adamant"
games {"rdr3"}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

author 'Mack'
description 'Rustle Script'
version '1.0.0'

shared_script 'config.lua'

client_script 'client.lua'


server_script {
   'server.lua'
}
dependency 'rsg-core'