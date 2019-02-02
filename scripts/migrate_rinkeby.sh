PKG=@0x/dev-utils yarn build
PKG=@0x/migrations yarn build

( cd ./packages/migrations && node ./lib/migrate_rinkeby.js )