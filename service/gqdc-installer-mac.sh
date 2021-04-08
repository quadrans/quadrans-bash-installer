#!/bin/bash

######################################################
#        Go Quadrans bash installer for Mac          #
#       Script created by Piersandro Guerrera        #
#          piersandro.guerrera@quadrans.io           #
#                                                    #
# Feel free to modify, but please give credit where  #
# it's due. Thanks!                                  #
######################################################

# Version
version=1.1M

# Architecture check
arch=$(uname -m)

# Installer description & welcome message
echo ""
printf "\e[1mWelcome to Quadrans Node Installer v.$version\e[0m\n"
printf "This tool allows to manage the Go Quadrans for Mainnet or Testnet on your machine\n"
echo ""

# Install menu
PS3='Please select: '
options=("Install new node" "Update existing node" "Uninstall your node" "Reconfigure node" "Change Network" "Abort")
select opt in "${options[@]}"; do
    case $opt in

    # Node installer

    "Install new node")

        if [ -f /Users/Shared/Quadrans/environment ]; then
            echo ""
            echo "Quadrans node configuration found, please select \"Reconfigure node\" or \"Change Network\" option"
            exit 1
        fi

        if [ -e "/usr/local/bin/gqdc" -a -e "/usr/local/bin/gqdc-testnet" ]; then
            echo ""
            printf "You already have a Quadrans Node installed on this computer.\n
Please use \"Change Network\" option"
            exit 1
        fi

        echo ""
        printf "Are you sure you want to Install the Quadrans Node on this machine?\n"
        echo ""

        PS3='Please select: '
        options=("Yes" "Cancel")
        select opt in "${options[@]}"; do
            case $opt in
            "Yes")

                echo ""
                echo "Choose the Quadrans blockchain network you want to use."
                echo ""

                PS3='Please select: '
                options=("Mainnet" "Testnet")
                select opt in "${options[@]}"; do
                    case $opt in
                    "Mainnet")

                        # Mainnet binary download

                        network='Mainnet'

                        printf "\e[1mDownloading Go Quadrans \"Darwin\" for your CPU architecture:\e[0m "
                        if [ "$arch" == 'x86_64' ]; then
                            printf "x86_64 found\n"
                            mkdir -p /usr/local/bin
                            curl -# http://repo.quadrans.io/macos/intel64/gqdc -o /usr/local/bin/gqdc

                        else
                            printf "Unsupported processor found, you cannot install a Quadrans node on this machine\n"
                            exit 1

                        fi

                        # Mainnet binary executable
                        chmod +x /usr/local/bin/gqdc
                        printf "\n\e[1mGo Quadrans binary\e[0m \e[32m...downloaded \e[0m\n"

                        # Mainnet launcher creation
                        mkdir -p /Users/Shared/Quadrans/
                        cat >/Users/Shared/Quadrans/gqdc.sh <<'EOF'
#!/bin/bash
source /Users/Shared/Quadrans/environment

MINER_OPTS=""
STATS_OPTS=""

if [ "${MINER_OPTIONS}" = "true" ]; then
    MINER_OPTS="--mine --unlock ${MINER_WALLET} --password ${MINER_PASSWORD}"
fi

if [ $(grep -c "NODE_LISTED=true" /Users/Shared/Quadrans/environment ) -eq 1 ]; then
    STATS_OPTS=$(printf "%sethstats \"%s\":\"QuadransStatsNetwork\"@status.quadrans.io:3000" "--" "${NODE_NAME}")
fi

eval "/usr/local/bin/gqdc ${GETH_PARAMS} ${MINER_OPTS} ${STATS_OPTS} --datadir /Users/Shared/Quadrans/.quadrans"
EOF
                        chmod +x /Users/Shared/Quadrans/gqdc.sh

                        printf "\e[1mGo Quadrans launcher\e[0m \e[32m...created \e[0m\n"

                        # Mainnet service creation
                        cat >/Library/LaunchDaemons/io.quadrans.gqdc.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>io.quadrans.gqdc</string>
    <key>ServiceDescription</key>
    <string>Go Quadrans Node</string>
    <key>ProgramArguments</key>
    <array>             
        <string>/Users/Shared/Quadrans/gqdc.sh</string>
    </array>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
EOF

                        printf "\e[1mGo Quadrans service\e[0m \e[32m...created \e[0m\n"

                        # Node configuration
                        # Node name
                        printf "\e[1mChoose a name for your Quadrans node\e[0m
The name will appear in Quadrans Network Status page and it is mandatory for mining.
If you leave it empty this node will be a Lightnode.
Please visit Quadrans Documentation for other information: https://docs.quadrans.io\n\n"

                        environmentfile='/Users/Shared/Quadrans/environment'
                        read -p "Enter the name of your node: " nodename
                        if [ "$nodename" != "" ]; then
                            echo "export NODE_LISTED=true" >>$environmentfile
                            echo "export NODE_NAME=\"$nodename\"" >> $environmentfile

                            # Node wallet password
                            printf "\n\e[1mCreate a new Quadrans Wallet and enable mining\e[0m
To create a new wallet you need to set a password
If you leave it empty the wallet creation will be skipped\n\n"

                            passwordfile='/Users/Shared/Quadrans/password.txt'
                            read -p 'Type your new wallet password (empty to skip): ' nodepassword
                            if [ "$nodepassword" != "" ]; then
                                echo $nodepassword >>$passwordfile
                                WALLET_ADDR=$(/usr/local/bin/gqdc account new --datadir /Users/Shared/Quadrans/.quadrans --password /Users/Shared/Quadrans/password.txt | grep -o -e {[A-Za-z0-9]*} | sed 's/^.//;s/.$//')
                                echo "export MINER_OPTIONS=true" >>$environmentfile
                                echo "export MINER_WALLET=\"0x$WALLET_ADDR\"" >>$environmentfile
                                echo "export MINER_PASSWORD=/Users/Shared/Quadrans/password.txt" >>$environmentfile
                            fi
                        else
                            touch $environmentfile

                        fi

                        printf "\e[1mQuadrans node configuration\e[0m \e[32m...done \e[0m\n"

                        launchctl load -w /Library/LaunchDaemons/io.quadrans.gqdc.plist
                        launchctl enable system/io.quadrans.gqdc
                        printf "\e[1mGo Quadrans service\e[0m \e[32m...enabled \e[0m\n"
                        launchctl start io.quadrans.gqdc
                        printf "\e[1mGo Quadrans service\e[0m \e[32m...started \e[0m\n"

                        break
                        ;;
                    "Testnet")

                        # Testnet binary download

                        network='Testnet'

                        printf "\e[1mDownloading Go Quadrans \"Darwin\" for Testnet for your CPU architecture:\e[0m "

                        if [ "$arch" == 'x86_64' ]; then
                            printf "x86_64 found\n"
                            mkdir -p /usr/local/bin
                            curl -# http://repo.quadrans.io/macos/test/intel64/gqdc -o /usr/local/bin/gqdc-testnet

                        else
                            printf "Unsupported processor found, you cannot install a Quadrans node on this machine\n"
                            exit 1

                        fi

                        # Mainnet binary executable
                        chmod +x /usr/local/bin/gqdc-testnet
                        printf "\n\e[1mGo Quadrans Testnet binary\e[0m \e[32m...downloaded \e[0m\n"

                        # Mainnet launcher creation
                        mkdir -p /Users/Shared/Quadrans/
                        cat >/Users/Shared/Quadrans/gqdc-testnet.sh <<'EOF'
#!/bin/bash
source /Users/Shared/Quadrans/environment-testnet

STATS_OPTS=""

if [ $(grep -c "NODE_LISTED=true" /Users/Shared/Quadrans/environment ) -eq 1 ]; then
    STATS_OPTS=$(printf "%sethstats \"%s\":\"QuadransStatsNetwork\"@status.testnet.quadrans.io:3000" "--" "${NODE_NAME}")
fi

eval "/usr/local/bin/gqdc-testnet --testnet --rpc --rpcapi=\"personal,net,web3,admin,debug,clique,eth\" --rpccorsdomain \"*\" --rpcaddr \"127.0.0.1\" --allow-insecure-unlock ${STATS_OPTS}"
EOF
                        chmod +x /Users/Shared/Quadrans/gqdc-testnet.sh

                        printf "\e[1mGo Quadrans Testnet launcher\e[0m \e[32m...created \e[0m\n"

                        # Mainnet service creation
                        cat >/Library/LaunchDaemons/io.quadrans.gqdc-testnet.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>io.quadrans.gqdc</string>
    <key>ServiceDescription</key>
    <string>Go Quadrans Node Test</string>
    <key>ProgramArguments</key>
    <array>             
        <string>/Users/Shared/Quadrans/gqdc-testnet.sh</string>
    </array>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
EOF

                        printf "\e[1mGo Quadrans service\e[0m \e[32m...created \e[0m\n"

                        # Node configuration
                        # Node name
                        printf "\e[1mChoose a name for your Quadrans node\e[0m
The name will appear in Quadrans Network Status page and it is mandatory for mining.
If you leave it empty this node will be a Lightnode.
Please visit Quadrans Documentation for other information: https://docs.quadrans.io\n\n"

                        environmentfile='/Users/Shared/Quadrans/environment-testnet'
                        read -p "Enter the name of your node: " nodename
                        if [ "$nodename" != "" ]; then
                            echo "export NODE_LISTED=true" >>$environmentfile
                            echo "export NODE_NAME=\"$nodename\"" >>$environmentfile
                        fi

                        printf "\e[1mQuadrans node configuration\e[0m \e[32m...done \e[0m\n"

                        launchctl load -w /Library/LaunchDaemons/io.quadrans.gqdc-testnet.plist
                        launchctl enable system/io.quadrans.gqdc-testnet
                        printf "\e[1mGo Quadrans Testnet service\e[0m \e[32m...enabled \e[0m\n"
                        launchctl start io.quadrans.gqdc-testnet
                        printf "\e[1mGo Quadrans Testnet service\e[0m \e[32m...started \e[0m\n"

                        break
                        ;;
                    *) echo "invalid option $REPLY" ;;
                    esac
                done

                # End of installation
                printf "\n\e[1mQuadrans Node installation completed.\e[0m\n\n"
                printf "\e[1mQuadrans Node Information\e[0m\n"
                printf "Your node network is: \e[32m$network\e[0m\n"
                if [ "$nodename" != "" ]; then
                    printf "Your node name is: \e[32m$nodename\e[0m\n"
                fi
                if [ "$nodepassword" != "" ]; then
                    printf "Your public address is: \e[32m0x$WALLET_ADDR\e[0m\n"
                    printf "Your wallet password is: \e[32m$nodepassword\e[0m\n"
                    printf "Your private key is located in the \\\"/Users/Shared/Quadrans/.quadrans/keystore/\\\" directory\n\n"
                fi

                break
                ;;
            "Cancel")
                break
                ;;
            *) echo "invalid option $REPLY" ;;
            esac
        done

        # Node update
        break
        ;;
    "Update existing node")

        # Quadrans node check check
        if [ -f /usr/local/bin/gqdc ] || [ -f /usr/local/bin/gqdc-testnet ]; then
            echo ""
            printf "Are you sure you want to Update the Quadrans Node installed on this machine with the latest version?\n"
            echo ""

        else
            # Stop update
            printf "\nYou don't have a Quadrans Node installed on this computer to be updated.
\e[31mInstallation aborted.\e[0m\n"
            exit 1
        fi

        PS3='Please select: '
        options=("Yes" "Cancel")
        select opt in "${options[@]}"; do
            case $opt in
            "Yes")

                service_mainnet_status="$(launchctl print system/io.quadrans.gqdc | grep state)"
                service_testnet_status="$(launchctl print system/io.quadrans.gqdc | grep state)"

                printf "\n\e[1mQuadrans Node update in progress...\e[0m\n"

                if [ -f /usr/local/bin/gqdc ]; then
                    echo "Quadrans Node for Mainnet found. Update in progress..."
                    launchctl stop io.quadrans.gqdc

                    # Architecture check and binary download
                    printf "\n\e[1mDownloading Go Quadrans for your CPU architecture:\e[0m "

                    if [ "$arch" == 'x86_64' ]; then
                        printf "x86_64 found\n"
                        curl -# http://repo.quadrans.io/macos/intel64/gqdc -o /usr/local/bin/gqdc

                    else
                        printf "Unsupported processor found, you cannot install a Quadrans node on this machine\n"
                        exit 1

                    fi

                    # Make binary executable
                    chmod +x /usr/local/bin/gqdc
                    printf "\n\e[1mGo Quadrans binary\e[0m \e[32m...updated \e[0m\n"

                    # Quadrans Node Service check
                    if [[ "${service_mainnet_status}" = *"running"* ]]; then
                        # Start the node and enable the service
                        launchctl stop io.quadrans.gqdc && launchctl start io.quadrans.gqdc
                        printf "\e[1mGo Quadrans Mainnet service\e[0m \e[32m...restarted \e[0m\n "
                    fi

                elif

                    [ -f /usr/local/bin/gqdc-testnet ]
                then
                    echo "Quadrans Node for Testnet found. Update in progress..."
                    launchctl stop io.quadrans.gqdc-testnet

                    # Architecture check and binary download
                    printf "\n\e[1mDownloading Go Quadrans for Testnet for your CPU architecture:\e[0m "

                    if [ "$arch" == 'x86_64' ]; then
                        printf "x86_64 found\n"
                        curl -# http://repo.quadrans.io/macos/intel64/gqdc-testnet -o /usr/local/bin/gqdc-testnet

                    else
                        printf "Unsupported processor found, you cannot install a Quadrans node on this machine\n"
                        exit 1

                    fi

                    # Make binary executable
                    chmod +x /usr/local/bin/gqdc-testnet
                    printf "\n\e[1mGo Quadrans Testnet binary\e[0m \e[32m...updated \e[0m\n"

                    # Quadrans Node Service check
                    if [[ "${service_testnet_status}" = *"running"* ]]; then
                        # Start the node and enable the service
                        launchctl stop io.quadrans.gqdc-testnet && launchctl start io.quadrans.gqdc-testnet
                        printf "\e[1mGo Quadrans Testnet service\e[0m \e[32m...restarted \e[0m\n "
                    fi

                else

                    printf "\nYou don't have a Quadrans Node installed on this computer to be updated."
                    echo ""
                    exit 1
                fi

                # End of update process
                printf "\n\e[1mQuadrans Node update completed.\e[0m\n\n"

                break
                ;;

            "Cancel")
                break
                ;;
            *) echo "invalid option $REPLY" ;;
            esac
        done

        break
        ;;

        # Uninstall Quadrans Node
    "Uninstall your node")

        # Quadrans node check check
        if [ -f /usr/local/bin/gqdc ] || [ -f /usr/local/bin/gqdc-testnet ]; then
            echo ""
            printf "Are you sure you want to uninstall the Quadrans Node installed on this machine?\n"
            echo ""

        else
            # Stop update
            printf "\nYou don't have a Quadrans Node installed on this computer to uninstall.
\e[31mOperation aborted.\e[0m\n"
            exit 1
        fi

        PS3='Please select: '
        options=("Yes" "Cancel")
        select opt in "${options[@]}"; do
            case $opt in
            "Yes")

                if [ -f /usr/local/bin/gqdc ] && [ -f /usr/local/bin/gqdc-testnet ]; then
                    echo ""
                    printf "Quadrans Node for Mainnet and Testnet found. Please confirm which one you want to uninstall...\n"
                    echo ""

                    PS3='Please select: '
                    options=("Mainnet Node" "Testnet Node" "Both" "Cancel")
                    select opt in "${options[@]}"; do
                        case $opt in
                        "Mainnet Node")

                            printf "\n\e[1mRemoving Go Quadrans from your computer\e[0m\n"
                            # Stop the node and disable the service
                            launchctl stop io.quadrans.gqdc && launchctl unload /Library/LaunchDaemons/io.quadrans.gqdc.plist

                            # Remove service, gqdc binary and quadrans user
                            rm /Library/LaunchDaemons/io.quadrans.gqdc.plist
                            printf "\e[1mGo Quadrans Mainnet service\e[0m \e[32m...removed \e[0m\n"

                            if [[ -s /Users/Shared/Quadrans/environment ]]; then
                                echo
                            else
                                rm /Users/Shared/Quadrans/environment
                            fi
                            rm /Users/Shared/Quadrans/gqdc.sh
                            printf "\e[1mGo Quadrans Mainnet launcher\e[0m \e[32m...deleted \e[0m\n"
                            rm /usr/local/bin/gqdc
                            printf "\e[1mGo Quadrans Mainnet binary\e[0m \e[32m...deleted \e[0m\n"

                            # End of uninstall process
                            printf "\n\e[1mQuadrans Mainnet Node uninstall completed.\e[0m
Your old Mainnet node configuration and your wallet (if existent) are located in:
\\\"/Users/Shared/Quadrans/\\\" directory (environment and password.txt)
\\\"/Users/Shared/Quadrans/.quadrans/keystore/\\\" directory (wallet private key)\n\n"

                            break
                            ;;

                        "Testnet Node")

                            printf "\n\e[1mRemoving Go Quadrans from your computer\e[0m\n"
                            # Stop the node and disable the service
                            launchctl stop io.quadrans.gqdc-testnet && launchctl unload /Library/LaunchDaemons/io.quadrans.gqdc-testnet.plist
                            # Remove service, gqdc binary and quadrans user
                            rm /Library/LaunchDaemons/io.quadrans.gqdc-testnet.plist
                            printf "\e[1mGo Quadrans Testnet service\e[0m \e[32m...removed \e[0m\n"
                            rm /Users/Shared/Quadrans/environment-testnet
                            rm /Users/Shared/Quadrans/gqdc-testnet.sh
                            printf "\e[1mGo Quadrans Testnet launcher\e[0m \e[32m...deleted \e[0m\n"
                            rm /usr/local/bin/gqdc-testnet
                            printf "\e[1mGo Quadrans Testnet binary\e[0m \e[32m...deleted \e[0m\n"

                            # End of uninstall process
                            printf "\n\e[1mQuadrans Testnet Node uninstall completed.\e[0m
Your old Testnet node configuration file is located in:
\\\"/Users/Shared/Quadrans/\\\" directory (environment-testnet)\n\n"

                            break
                            ;;

                        "Both")

                            printf "\n\e[1mRemoving Go Quadrans from your computer\e[0m\n"
                            # Stop the node and disable the service
                            launchctl stop io.quadrans.gqdc && launchctl unload /Library/LaunchDaemons/io.quadrans.gqdc.plist && launchctl stop io.quadrans.gqdc-testnet && launchctl unload /Library/LaunchDaemons/io.quadrans.gqdc-testnet.plist
                            # Remove service, gqdc binary and quadrans user
                            rm /Library/LaunchDaemons/io.quadrans.gqdc.plist
                            rm /Library/LaunchDaemons/io.quadrans.gqdc-testnet.plist
                            printf "\e[1mGo Quadrans service\e[0m \e[32m...removed \e[0m\n"

                            if [[ -s /Users/Shared/Quadrans/environment ]]; then
                                echo
                            else
                                rm /Users/Shared/Quadrans/environment
                            fi
                            rm /Users/Shared/Quadrans/gqdc.sh
                            rm /Users/Shared/Quadrans/environment-testnet
                            rm /Users/Shared/Quadrans/gqdc-testnet.sh
                            printf "\e[1mGo Quadrans launcher\e[0m \e[32m...deleted \e[0m\n"
                            rm /usr/local/bin/gqdc
                            rm /usr/local/bin/gqdc-testnet
                            printf "\e[1mGo Quadrans binary\e[0m \e[32m...deleted \e[0m\n"

                            # End of uninstall process
                            printf "\n\e[1mQuadrans Node uninstall completed.\e[0m
Your old Mainnet node configuration and your wallet (if existent) are located in:
\\\"/Users/Shared/Quadrans/\\\" directory (environment and password.txt)
\\\"/Users/Shared/Quadrans/.quadrans/keystore/\\\" directory (wallet private key)
Your old Testnet node configuration file is located in:
\\\"/Users/Shared/Quadrans/\\\" directory (environment-testnet)\n\n"

                            break
                            ;;

                        "Cancel")
                            break
                            ;;
                        *) echo "invalid option $REPLY" ;;
                        esac
                    done

                elif [ -f /usr/local/bin/gqdc ]; then
                    echo ""
                    printf "Quadrans Node for Mainnet found. Do you want to proceed?\n"
                    echo ""

                    PS3='Please select: '
                    options=("Yes" "Cancel")
                    select opt in "${options[@]}"; do
                        case $opt in
                        "Yes")

                            printf "\n\e[1mRemoving Go Quadrans from your computer\e[0m\n"
                            # Stop the node and disable the service
                            launchctl stop io.quadrans.gqdc && launchctl unload /Library/LaunchDaemons/io.quadrans.gqdc.plist

                            # Remove service, gqdc binary and quadrans user
                            rm /Library/LaunchDaemons/io.quadrans.gqdc.plist
                            printf "\e[1mGo Quadrans Mainnet service\e[0m \e[32m...removed \e[0m\n"

                            if [[ -s /Users/Shared/Quadrans/environment ]]; then
                                echo
                            else
                                rm /Users/Shared/Quadrans/environment
                            fi
                            rm /Users/Shared/Quadrans/gqdc.sh
                            printf "\e[1mGo Quadrans Mainnet launcher\e[0m \e[32m...deleted \e[0m\n"
                            rm /usr/local/bin/gqdc
                            printf "\e[1mGo Quadrans Mainnet binary\e[0m \e[32m...deleted \e[0m\n"

                            # End of uninstall process
                            printf "\n\e[1mQuadrans Mainnet Node uninstall completed.\e[0m
Your old Mainnet node configuration and your wallet (if existent) are located in:
\\\"/Users/Shared/Quadrans/\\\" directory (environment and password.txt)
\\\"/Users/Shared/Quadrans/.quadrans/keystore/\\\" directory (wallet private key)\n\n"

                            break
                            ;;
                        "Cancel")
                            break
                            ;;
                        *) echo "invalid option $REPLY" ;;
                        esac
                    done

                elif [ -f /usr/local/bin/gqdc-testnet ]; then
                    echo ""
                    printf "Quadrans Node for Testnet found. Do you want to proceed?\n"
                    echo ""

                    PS3='Please select: '
                    options=("Yes" "Cancel")
                    select opt in "${options[@]}"; do
                        case $opt in
                        "Yes")

                            printf "\n\e[1mRemoving Go Quadrans from your computer\e[0m\n"
                            # Stop the node and disable the service
                            launchctl stop io.quadrans.gqdc-testnet && launchctl unload /Library/LaunchDaemons/io.quadrans.gqdc-testnet.plist
                            # Remove service, gqdc binary and quadrans user
                            rm /Library/LaunchDaemons/io.quadrans.gqdc-testnet.plist
                            printf "\e[1mGo Quadrans Testnet service\e[0m \e[32m...removed \e[0m\n"
                            rm /Users/Shared/Quadrans/environment-testnet
                            rm /Users/Shared/Quadrans/gqdc-testnet.sh
                            printf "\e[1mGo Quadrans Testnet launcher\e[0m \e[32m...deleted \e[0m\n"
                            rm /usr/local/bin/gqdc-testnet
                            printf "\e[1mGo Quadrans Testnet binary\e[0m \e[32m...deleted \e[0m\n"

                            # End of uninstall process
                            printf "\n\e[1mQuadrans Testnet Node uninstall completed.\e[0m
Your old Testnet node configuration file is located in:
\\\"/Users/Shared/Quadrans/\\\" directory (environment-testnet)\n\n"

                            break
                            ;;
                        "Cancel")
                            break
                            ;;
                        *) echo "invalid option $REPLY" ;;
                        esac
                    done

                fi

                break
                ;;
            "Cancel")
                break
                ;;
            *) echo "invalid option $REPLY" ;;
            esac
        done

        break
        ;;
    "Reconfigure node")

        # Previous installation check
        if [ -f /Users/Shared/Quadrans/environment ]; then
            printf "\n\e[1mQuadrans Mainnet node configuration found, reinstallation in progress...\e[0m\n\n"

            # Architecture check and binary download
            printf "\e[1mDownloading Go Quadrans \"Darwin\" for your CPU architecture:\e[0m "
            if [ "$arch" == 'x86_64' ]; then
                printf "x86_64 found\n"
                mkdir -p /usr/local/bin
                curl -# http://repo.quadrans.io/macos/intel64/gqdc -o /usr/local/bin/gqdc

            else
                printf "Unsupported processor found, you cannot install a Quadrans node on this machine\n"
                exit 1

            fi

            # Make binary executable
            chmod +x /usr/local/bin/gqdc
            printf "\n\e[1mGo Quadrans binary\e[0m \e[32m...downloaded \e[0m\n"

            # Mainnet launcher creation
            mkdir -p /Users/Shared/Quadrans/
            cat >/Users/Shared/Quadrans/gqdc.sh <<'EOF'
#!/bin/bash
source /Users/Shared/Quadrans/environment

MINER_OPTS=""
STATS_OPTS=""

if [ "${MINER_OPTIONS}" = "true" ]; then
    MINER_OPTS="--mine --unlock ${MINER_WALLET} --password ${MINER_PASSWORD}"
fi

if [ $(grep -c "NODE_LISTED=true" /Users/Shared/Quadrans/environment ) -eq 1 ]; then
    STATS_OPTS=$(printf "%sethstats \"%s\":\"QuadransStatsNetwork\"@status.quadrans.io:3000" "--" "${NODE_NAME}")
fi

eval "/usr/local/bin/gqdc ${GETH_PARAMS} ${MINER_OPTS} ${STATS_OPTS}"
EOF
            chmod +x /Users/Shared/Quadrans/gqdc.sh

            printf "\e[1mGo Quadrans launcher\e[0m \e[32m...created \e[0m\n"

            # Service creation
            cat >/Library/LaunchDaemons/io.quadrans.gqdc.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>io.quadrans.gqdc</string>
    <key>ServiceDescription</key>
    <string>Go Quadrans Node</string>
    <key>ProgramArguments</key>
    <array>             
        <string>/Users/Shared/Quadrans/gqdc.sh</string>
    </array>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
EOF

            if [ ! -f /Users/Shared/Quadrans/password.txt ]; then

                # Node wallet password
                printf "\n\e[1mDo you want to create a Quadrans Wallet and enable mining on your node?\e[0m\n"
                echo ""

                PS3='Please select: '
                options=("Yes" "Skip")
                select opt in "${options[@]}"; do
                    case $opt in
                    "Yes")

                        printf "To create a new wallet you need to set a password
If you leave it empty the wallet creation will be skipped\n\n"

                        environmentfile='/Users/Shared/Quadrans/environment'
                        passwordfile='/Users/Shared/Quadrans/password.txt'
                        read -p 'Type your new wallet password (empty to skip): ' nodepassword
                        if [ "$nodepassword" != "" ]; then
                            echo $nodepassword >>$passwordfile
                            WALLET_ADDR=$(/usr/local/bin/gqdc account new --datadir /Users/Shared/Quadrans/.quadrans --password /Users/Shared/Quadrans/password.txt | grep -o -e {[A-Za-z0-9]*} | sed 's/^.//;s/.$//')
                            echo "export MINER_OPTIONS=true" >>$environmentfile
                            echo "export MINER_WALLET=\"0x$WALLET_ADDR\"" >>$environmentfile
                            echo "export MINER_PASSWORD=/Users/Shared/Quadrans/password.txt" >>$environmentfile
                        fi

                        printf "\e[1mQuadrans node configuration\e[0m \e[32m...done \e[0m\n"

                        break
                        ;;
                    "Skip")
                        break
                        ;;
                    *) echo "invalid option $REPLY" ;;
                    esac
                done

            fi

            # Start the node and enable the service
            launchctl load -w /Library/LaunchDaemons/io.quadrans.gqdc.plist
            launchctl enable system/io.quadrans.gqdc
            printf "\e[1mGo Quadrans service\e[0m \e[32m...enabled \e[0m\n"
            launchctl start io.quadrans.gqdc
            printf "\e[1mGo Quadrans service\e[0m \e[32m...started \e[0m\n"

            # End of update process
            printf "\n\e[1mQuadrans Node reconfiguration completed.\e[0m\n"

        else
            echo ""
            printf "Quadrans node configuration not found, please select install option\n"
            exit 1
        fi

        break
        ;;

    "Change Network")
        printf "Function temporarily disabled on macOS"
        break
        ;;

    "Abort")
        break
        ;;
    *) echo "invalid option $REPLY" ;;
    esac
done
