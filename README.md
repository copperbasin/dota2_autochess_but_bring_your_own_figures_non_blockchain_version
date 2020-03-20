# dota2_autochess_but_bring_your_own_figures_non_blockchain_version
This is **NON** blockchain version of https://github.com/copperbasin/dota2_autochess_but_bring_your_own_figures

# How to install
install nodejs

    # install https://github.com/nvm-sh/nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
    # relogin OR source ~/.bashrc
    nvm i 12

install iced coffee script globally

    npm i -g iced-coffee-script

copy this repo

    git clone https://github.com/copperbasin/dota2_autochess_but_bring_your_own_figures_non_blockchain_version
    cd dota2_autochess_but_bring_your_own_figures_non_blockchain_version

start front in first terminal

    cd front
    npm ci
    ./server.coffee

start back in second terminal

    cd back
    npm ci
    ./server.coffee

# How to play
 * You need 2 independent browser windows (e.g. chrome + chrome incognito)
 * Open in both http://localhost:12000
 * Open dev tools in both
 * Execute in first tab `localStorage.player_id = "1"`
 * Execute in second tab `localStorage.player_id = "2"`
 * Refresh both tabs
How you can buy figures and go to queue
