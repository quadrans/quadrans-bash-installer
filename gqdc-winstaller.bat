@echo off
:: Usage: open a Command Prompt or PowerShell on Windows and execute these commands:
:: curl -s https://repo.quadrans.io/installer/gqdc-winstaller.bat -o gqdc-winstaller.bat
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
:: Feel free to modify, but please give credit where it's due. Thanks!
set "VERSION=0.6"
echo:
echo   ___                  _                       _   _           _      
echo  / _ \ _   _  __ _  __^| ^|_ __ __ _ _ __  ___  ^| \ ^| ^| ___   __^| ^| ___ 
echo ^| ^| ^| ^| ^| ^| ^|/ _` ^|/ _` ^| `__/ _` ^| `_ \/ __^| ^|  \^| ^|/ _ \ / _` ^|/ _ \
echo ^| ^|_^| ^| ^|_^| ^| (_^| ^| (_^| ^| ^| ^| (_^| ^| ^| ^| \__ \ ^| ^|\  ^| (_) ^| (_^| ^|  __/
echo  \__\_\\__,_^|\__,_^|\__,_^|_^|  \__,_^|_^| ^|_^|___/ ^|_^| \_^|\___/ \__,_^|\___^|
echo:
echo Welcome to Quadrans Node Installer v. %VERSION% for Windows
echo:
echo This is a simple tool that allows to install a Go Quadrans binary for Windows.
echo With easy steps it will download the node on your PC, create a wallet and enable mining.
echo:
set /p Q="Press Enter key to continue or CTRL+C to abort the installation." 
echo:
echo As first step, this script will download the latest "gqdc.exe" on %USERPROFILE% folder 
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
echo %PASSWORD%>password.txt
echo: 
echo Quadrans Node wallet creation, please wait...
setlocal enabledelayedexpansion
gqdc --verbosity 1 account new --password password.txt --datadir . > temp_output.txt
for /f "tokens=1,* delims=:" %%a in (temp_output.txt) do (
    if "%%a"=="Public address of the key" (
        set "NODE_WALLET=%%b"
        goto :found
    )
)
:found
set "NODE_WALLET=!NODE_WALLET: =!"
echo gqdc --mine --unlock !NODE_WALLET! --password password.txt --ethstats "%NODE_NAME%":QuadransStatsNetwork@status.quadrans.io:3000 --datadir . > gqdc-launcher.bat
del temp_output.txt
echo: 
echo Well done! Your Quadrans Node Installation has been completed. 
echo: 
echo To configure your node as Miner/Masternode please complete the registration on Quadrans Community from
echo https://quadrans.io/get-started
echo:
echo Your Quadrans Node Information:
echo - Node Name: %NODE_NAME%
echo - QDC Wallet: !NODE_WALLET!
echo: 
echo Open Windows Explorer, go on %USERPROFILE%\QuadransNode folder and double click on gqdc-launcher.bat file
echo to execute your Quadrans Node.
echo If requested by your Firewall please Allow gqdc.exe to connect to the Internet.
echo:
echo Please remember to backup you password.txt file and the UTC... file located in the keystore folder of your
echo %USERPROFILE%\QuadransNode folder.
endlocal