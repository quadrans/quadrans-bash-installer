@echo off
:: Usage: open a Command Prompt or PowerShell on Windows and execute these commands:
:: curl -# https://repo.quadrans.io/installer/gqdc-winstaller.bat -o gqdc-winstaller.bat
:: gqdc-winstaller.bat
::
:: This is a command line tool to install Quadrans node
::
:: For assistance:
::   read the documentation: https://docs.quadrans.io
::   contact the team on Telegram: https://t.me/quadrans
:: 
::      Go Quadrans batch installation launcher
::       Script created by Piersandro Guerrera
::          piersandro.guerrera@quadrans.io
::
:: Feel free to modify, but please give credit where
:: it's due. Thanks!
echo:
echo   ___                  _                       _   _           _      
echo  / _ \ _   _  __ _  __^| ^|_ __ __ _ _ __  ___  ^| \ ^| ^| ___   __^| ^| ___ 
echo ^| ^| ^| ^| ^| ^| ^|/ _` ^|/ _` ^| `__/ _` ^| `_ \/ __^| ^|  \^| ^|/ _ \ / _` ^|/ _ \
echo ^| ^|_^| ^| ^|_^| ^| (_^| ^| (_^| ^| ^| ^| (_^| ^| ^| ^| \__ \ ^| ^|\  ^| (_) ^| (_^| ^|  __/
echo  \__\_\\__,_^|\__,_^|\__,_^|_^|  \__,_^|_^| ^|_^|___/ ^|_^| \_^|\___/ \__,_^|\___^|
echo:
echo Welcome to Quadrans Node Installer v. 0.1 for Windows
echo:
echo This is a simple tool that allows to install a Go Quadrans binary for Windows.
echo With easy steps it will download the node on your PC, create a wallet and enable mining.
echo:
set /p Q="Press Enter key to continue or CTRL+C to abort the installation." 
echo:
echo As first step, this script will download "gqdc.exe" on %USERPROFILE% folder
echo inside a new "QuadransNode" directory.
mkdir %USERPROFILE%\QuadransNode
cd %USERPROFILE%\QuadransNode
echo:
echo Downloading latest Go Quadrans binary for Windows...
curl -# https://repo.quadrans.io/windows/amd64/binary/gqdc.exe -o gqdc.exe
echo:
echo Insert your Node Name for Quadrans Network Status (mandatory for Miner and Masternode) an press Enter.
set /p NODE_NAME="Node Name: "
echo:
echo Choose a random password to create your Quadrans Coin wallet on your node an press Enter.
set /p PASSWORD="Password: "
echo %PASSWORD% > password.txt
echo: 
echo Quadrans Node wallet creation
gqdc account new --password password.txt --datadir .
echo:
echo Copy and paste the content of the parentheses {...} in the next prompt
echo by selecting the text with your pointer and double right click on your mouse or trackpad an press Enter.
set /p NODE_WALLET="Wallet Address: "
echo gqdc --mine --unlock 0x%NODE_WALLET%  --password password.txt --ethstats "%NODE_NAME%":QuadransStatsNetwork@status.quadrans.io:3000 --datadir . > gqdc-launcher.bat
echo: 
echo Quadrans Node Installation completed.
echo To run your node go on %USERPROFILE% folder and execute gqdc-launcher.bat file.