#!/bin/bash
######################################################
#       Go Quadrans bash installer for Linux         #
#       Script created by Piersandro Guerrera        #
#          piersandro.guerrera@quadrans.io           #
#                                                    #
# Feel free to modify, but please give credit where  #
# it's due. Thanks!                                  #
######################################################

# Version
version=1.1.3L

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

        # Previous installation check
        if [ -f /home/quadrans/environment ]; then
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

                # Dependency check
                printf "\n\e[1mDependency checker...\e[0m\n"

                if command -v systemctl >/dev/null 2>&1; then
                    printf "systemctl found"
                    echo ""
                    echo ""
                else
                    printf "systemctl \e[31mnot found.\e[0m\n
Please install systemd and systemctl on your computer than relaunch this installer."
                    echo ""
                    exit 1
                fi

                # Quadrans user check
                if getent passwd quadrans >/dev/null; then
                    printf "You have a Quadrans Node installed on this computer
\e[31mInstallation aborted.\e[0m\n"
                    exit 1
                else
                    # Quadrans user creation
                    printf "\e[1mQuadrans Node installation in progress...\e[0m
Node user creation in progress... "
                    useradd -r -m quadrans
                    chown -R quadrans:quadrans /home/quadrans
                    printf "\e[32mdone \n\n\e[0m"
                fi

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

                        printf "\e[1mDownloading Go Quadrans for your CPU architecture:\e[0m "

                        if [ "$arch" == 'x86_64' ]; then
                            printf "x86_64 found\n"
                            mkdir -p /usr/local/bin/ && wget -q --show-progress --progress=bar:force:noscroll -x -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/amd64/gqdc

                        elif [ "$arch" == 'x86_32' ]; then
                            printf "x86 found\n"
                            mkdir -p /usr/local/bin/ && wget -q --show-progress --progress=bar:force:noscroll -x -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/i386/gqdc

                        elif [ "$arch" == 'aarch64' ]; then
                            printf "ARM64 found\n"
                            mkdir -p /usr/local/bin/ && wget -q --show-progress --progress=bar:force:noscroll -x -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/arm/arm64/gqdc

                        elif [[ "$arch" == 'armv7'* ]]; then
                            printf "ARMv7 found\n"
                            mkdir -p /usr/local/bin/ && wget -q --show-progress --progress=bar:force:noscroll -x -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/arm/arm7/gqdc

                        else
                            printf "Unsupported processor found, you cannot install a Quadrans node on this machine\n"
                            exit 1
                        fi

                        # Mainnet binary executable
                        chmod +x /usr/local/bin/gqdc
                        printf "\n\e[1mGo Quadrans binary\e[0m \e[32m...downloaded \e[0m\n"

                        # Mainnet launcher creation
                        cat >/home/quadrans/gqdc.sh <<'EOF'
#!/bin/bash
source /home/quadrans/environment

MINER_OPTS=""
STATS_OPTS=""

if [ "${MINER_OPTIONS}" = "true" ]; then
    MINER_OPTS="--mine --unlock ${MINER_WALLET} --password ${MINER_PASSWORD}"
fi

if [ $(grep -c "NODE_LISTED=true" /home/quadrans/environment ) -eq 1 ]; then
    STATS_OPTS=$(printf "%sethstats \"%s\":\"QuadransStatsNetwork\"@status.quadrans.io:3000" "--" "${NODE_NAME}")
fi

eval "/usr/local/bin/gqdc ${GETH_PARAMS} ${MINER_OPTS} ${STATS_OPTS}"
EOF
                        chown quadrans:quadrans /home/quadrans/gqdc.sh
                        chmod +x /home/quadrans/gqdc.sh

                        printf "\e[1mGo Quadrans launcher\e[0m \e[32m...created \e[0m\n"

                        # Mainnet service creation
                        cat >/etc/systemd/system/quadrans-node.service <<'EOF'
Description=Quadrans Node Service
After=network.target

[Service]
Type=simple
User=quadrans
WorkingDirectory=/home/quadrans
EnvironmentFile=/home/quadrans/environment
ExecStart=/home/quadrans/gqdc.sh
Restart=on-failure
RestartSec=60
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=QuadransNode

[Install]
WantedBy=default.target
EOF

                        printf "\e[1mGo Quadrans service\e[0m \e[32m...created \e[0m\n"

                        # Node configuration
                        # Node name
                        printf "\e[1mChoose a name for your Quadrans node\e[0m
The name will appear in Quadrans Network Status page and it is mandatory for mining.
If you leave it empty this node will be a Lightnode.
Please visit Quadrans Documentation for other information: https://docs.quadrans.io\n\n"

                        environmentfile='/home/quadrans/environment'
                        read -p "Enter the name of your node: " nodename
                        if [ "$nodename" != "" ]; then
                            su quadrans -c "echo \"export NODE_LISTED=true\" >> $environmentfile"
                            su quadrans -c "echo \"export NODE_NAME=\\\"$nodename\\\"\" >> $environmentfile"

                            # Node wallet password
                            printf "\n\e[1mCreate a new Quadrans Wallet and enable mining\e[0m
To create a new wallet you need to set a password
If you leave it empty the wallet creation will be skipped\n\n"

                            passwordfile='/home/quadrans/password.txt'
                            read -p 'Type your new wallet password (empty to skip): ' nodepassword
                            if [ "$nodepassword" != "" ]; then
                                echo $nodepassword >>$passwordfile
                                WALLET_ADDR=$(su quadrans -c "/usr/local/bin/gqdc account new --datadir /home/quadrans/.quadrans --password /home/quadrans/password.txt | grep -o -e \"\{[A-Za-z0-9]*\}\" | tail -c +2 | head -c -2")
                                su quadrans -c "echo \"export MINER_OPTIONS=true\" >> $environmentfile"
                                su quadrans -c "echo \"export MINER_WALLET=\"0x$WALLET_ADDR\"\" >> $environmentfile"
                                su quadrans -c "echo \"export MINER_PASSWORD=/home/quadrans/password.txt\" >> $environmentfile"
                            fi
                        else
                            su quadrans -c "touch $environmentfile"

                        fi

                        printf "\e[1mQuadrans node configuration\e[0m \e[32m...done \e[0m\n"

                        systemctl enable quadrans-node
                        printf "\e[1mGo Quadrans service\e[0m \e[32m...enabled \e[0m\n"
                        systemctl start quadrans-node
                        printf "\e[1mGo Quadrans service\e[0m \e[32m...started \e[0m\n"

                        break
                        ;;
                    "Testnet")

                        # Testnet binary download

                        network='Testnet'

                        printf "\e[1mDownloading Go Quadrans for Testnet for your CPU architecture:\e[0m "

                        if [ "$arch" == 'x86_64' ]; then
                            printf "x86_64 found\n\n"
                            mkdir -p /usr/local/bin/ && wget -q --show-progress --progress=bar:force:noscroll -x -O /usr/local/bin/gqdc-testnet http://repo.quadrans.io/linux/test/amd64/gqdc

                        elif [ "$arch" == 'x86_32' ]; then
                            printf "x86 found\n\n"
                            mkdir -p /usr/local/bin/ && wget -q --show-progress --progress=bar:force:noscroll -x -O /usr/local/bin/gqdc-testnet http://repo.quadrans.io/linux/test/i386/gqdc

                        elif [ "$arch" == 'aarch64' ]; then
                            printf "ARM64 found\n\n"
                            mkdir -p /usr/local/bin/ && wget -q --show-progress --progress=bar:force:noscroll -x -O /usr/local/bin/gqdc-testnet http://repo.quadrans.io/linux/test/arm/arm64/gqdc

                        elif [[ "$arch" == 'armv7'* ]]; then
                            printf "ARMv7 found\n\n"
                            mkdir -p /usr/local/bin/ && wget -q --show-progress --progress=bar:force:noscroll -x -O /usr/local/bin/gqdc-testnet http://repo.quadrans.io/linux/test/arm/arm7/gqdc

                        else
                            printf "Unsupported processor found, you cannot install a Quadrans node on this machine\n"
                            exit 1
                        fi

                        # Make Testnet binary executable
                        chmod +x /usr/local/bin/gqdc-testnet
                        printf "\n\e[1mGo Quadrans Testnet binary\e[0m \e[32m...downloaded \e[0m\n"

                        # Testnet Launcher creation
                        cat >/home/quadrans/gqdc-testnet.sh <<'EOF'
#!/bin/bash
source /home/quadrans/environment-testnet

STATS_OPTS=""

if [ $(grep -c "NODE_LISTED=true" /home/quadrans/environment-testnet ) -eq 1 ]; then
    STATS_OPTS=$(printf "%sethstats \"%s\":\"QuadransStatsNetwork\"@status.testnet.quadrans.io:3000" "--" "${NODE_NAME}")
fi

eval "/usr/local/bin/gqdc-testnet --testnet --rpc --rpcapi=\"personal,net,web3,admin,debug,clique,eth\" --rpccorsdomain \"*\" --rpcaddr \"127.0.0.1\" --allow-insecure-unlock ${STATS_OPTS}"
EOF
                        chown quadrans:quadrans /home/quadrans/gqdc-testnet.sh
                        chmod +x /home/quadrans/gqdc-testnet.sh

                        printf "\e[1mGo Quadrans Testnet launcher\e[0m \e[32m...created \e[0m\n"

                        # Testnet Service creation
                        cat >/etc/systemd/system/quadrans-node-testnet.service <<'EOF'
Description=Quadrans Node Testnet Service
After=network.target

[Service]
Type=simple
User=quadrans
WorkingDirectory=/home/quadrans
EnvironmentFile=/home/quadrans/environment-testnet
ExecStart=/home/quadrans/gqdc-testnet.sh
Restart=on-failure
RestartSec=60
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=QuadransNodeTest

[Install]
WantedBy=default.target
EOF

                        printf "\e[1mGo Quadrans Testnet service\e[0m \e[32m...created \e[0m\n"

                        # Testnet Node configuration
                        # Testnet Node name
                        printf "\e[1mChoose a name for your Quadrans node\e[0m
The name will appear in Quadrans Network Testnet Status page.\n\n"

                        environmentfile='/home/quadrans/environment-testnet'
                        read -p "Enter the name of your testnet node: " nodename
                        if [ "$nodename" != "" ]; then
                            su quadrans -c "echo \"export NODE_LISTED=true\" >> $environmentfile"
                            su quadrans -c "echo \"export NODE_NAME=\\\"$nodename\\\"\" >> $environmentfile"
                        else
                            su quadrans -c "echo \"export NODE_LISTED=false\" >> $environmentfile"
                            su quadrans -c "echo \"export NODE_NAME=\\\"\\\"\" >> $environmentfile"
                        fi

                        printf "\e[1mQuadrans node configuration\e[0m \e[32m...done \e[0m\n"

                        systemctl enable quadrans-node-testnet
                        printf "\e[1mGo Quadrans Testnet service\e[0m \e[32m...enabled \e[0m\n"
                        systemctl start quadrans-node-testnet
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
                    printf "Your private key is located in the \\\"/home/quadrans/.quadrans/keystore/\\\" directory\n\n"
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

        # Quadrans user check
        if getent passwd quadrans >/dev/null; then
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

                printf "\n\e[1mQuadrans Node update in progress...\e[0m\n"

                if [ -f /usr/local/bin/gqdc ]; then
                    echo "Quadrans Node for Mainnet found. Update in progress..."
                    service_status="$(systemctl show -p SubState --value quadrans-node)"
                    systemctl stop quadrans-node

                    # Architecture check and binary download
                    printf "\n\e[1mDownloading Go Quadrans for your CPU architecture:\e[0m "

                    if [ "$arch" == 'x86_64' ]; then
                        printf "x86_64 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/amd64/gqdc

                    elif [ "$arch" == 'x86_32' ]; then
                        printf "x86 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/i386/gqdc

                    elif [ "$arch" == 'aarch64' ]; then
                        printf "ARM64 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/arm/arm64/gqdc

                    elif [[ "$arch" == 'armv7'* ]]; then
                        printf "ARMv7 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/arm/arm7/gqdc

                    else
                        printf "Unsupported processor found, you cannot update a Quadrans node on this machine\n"
                        exit 1
                    fi

                    # Make binary executable
                    chmod +x /usr/local/bin/gqdc
                    printf "\n\e[1mGo Quadrans binary\e[0m \e[32m...updated \e[0m\n"

                    # Quadrans Node Service check

                    if [ "${service_status}" = "running" ]; then
                        # Start the node and enable the service
                        systemctl restart quadrans-node
                        printf "\e[1mGo Quadrans Mainnet service\e[0m \e[32m...restarted \e[0m\n "
                    fi

                elif

                    [ -f /usr/local/bin/gqdc-testnet ]
                then
                    echo "Quadrans Node for Testnet found. Update in progress..."
                    service_status_testnet="$(systemctl show -p SubState --value quadrans-node-testnet)"
                    systemctl stop quadrans-node-testnet

                    # Architecture check and binary download
                    printf "\n\e[1mDownloading Go Quadrans for Testnet for your CPU architecture:\e[0m "

                    if [ "$arch" == 'x86_64' ]; then
                        printf "x86_64 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc-testnet http://repo.quadrans.io/linux/test/amd64/gqdc

                    elif [ "$arch" == 'x86_32' ]; then
                        printf "x86 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc-testnet http://repo.quadrans.io/linux/test/i386/gqdc

                    elif [ "$arch" == 'aarch64' ]; then
                        printf "ARM64 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc-testnet http://repo.quadrans.io/linux/arm/arm64/gqdc

                    elif [[ "$arch" == 'armv7'* ]]; then
                        printf "ARMv7 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc-testnet http://repo.quadrans.io/linux/test/arm/arm7/gqdc

                    else
                        printf "Unsupported processor found, you cannot update a Quadrans node on this machine\n"
                        exit 1
                    fi

                    # Make binary executable
                    chmod +x /usr/local/bin/gqdc-testnet
                    printf "\n\e[1mGo Quadrans Testnet binary\e[0m \e[32m...updated \e[0m\n"

                    # Quadrans Node Testnet Service check
                    if [ "${service_status_testnet}" = "running" ]; then
                        # Start the node and enable the service
                        systemctl restart quadrans-node-testnet
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

        # Quadrans user check

        if getent passwd quadrans >/dev/null; then
            echo ""
            printf "Are you sure you want to uninstall the Quadrans Node installed on this machine?\n"
            echo ""
        else
            # Stop uninstall
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
                            systemctl disable quadrans-node && systemctl stop quadrans-node
                            # Remove service, gqdc binary and quadrans user
                            rm /etc/systemd/system/quadrans-node.service
                            printf "\e[1mGo Quadrans Mainnet service\e[0m \e[32m...removed \e[0m\n"

                            if [[ -s /home/quadrans/environment ]]; then
                                echo
                            else
                                rm /home/quadrans/environment
                            fi
                            rm /home/quadrans/gqdc.sh
                            printf "\e[1mGo Quadrans Mainnet launcher\e[0m \e[32m...deleted \e[0m\n"
                            rm /usr/local/bin/gqdc
                            printf "\e[1mGo Quadrans Mainnet binary\e[0m \e[32m...deleted \e[0m\n"

                            # End of uninstall process
                            printf "\n\e[1mQuadrans Mainnet Node uninstall completed.\e[0m
Your old Mainnet node configuration and your wallet (if existent) are located in:
\\\"/home/quadrans/\\\" directory (environment and password.txt)
\\\"/home/quadrans/.quadrans/keystore/\\\" directory (wallet private key)\n\n"

                            break
                            ;;

                        "Testnet Node")

                            printf "\n\e[1mRemoving Go Quadrans from your computer\e[0m\n"
                            # Stop the node and disable the service
                            systemctl disable quadrans-node-testnet && systemctl stop quadrans-node-testnet
                            # Remove service, gqdc binary and quadrans user
                            rm /etc/systemd/system/quadrans-node-testnet.service
                            printf "\e[1mGo Quadrans Testnet service\e[0m \e[32m...removed \e[0m\n"
                            rm /home/quadrans/environment-testnet
                            rm /home/quadrans/gqdc-testnet.sh
                            printf "\e[1mGo Quadrans Testnet launcher\e[0m \e[32m...deleted \e[0m\n"
                            rm /usr/local/bin/gqdc-testnet
                            printf "\e[1mGo Quadrans Testnet binary\e[0m \e[32m...deleted \e[0m\n"

                            # End of uninstall process
                            printf "\n\e[1mQuadrans Testnet Node uninstall completed.\e[0m
Your old Testnet node configuration file is located in:
\\\"/home/quadrans/\\\" directory (environment-testnet)\n\n"

                            break
                            ;;

                        "Both")

                            printf "\n\e[1mRemoving Go Quadrans from your computer\e[0m\n"
                            # Stop the node and disable the service
                            systemctl disable quadrans-node && systemctl stop quadrans-node && systemctl disable quadrans-node-testnet && systemctl stop quadrans-node-testnet
                            # Remove service, gqdc binary and quadrans user
                            rm /etc/systemd/system/quadrans-node.service
                            rm /etc/systemd/system/quadrans-node-testnet.service
                            printf "\e[1mGo Quadrans service\e[0m \e[32m...removed \e[0m\n"

                            if [[ -s /home/quadrans/environment ]]; then
                                echo
                            else
                                rm /home/quadrans/environment
                            fi
                            rm /home/quadrans/gqdc.sh
                            rm /home/quadrans/environment-testnet
                            rm /home/quadrans/gqdc-testnet.sh
                            printf "\e[1mGo Quadrans launcher\e[0m \e[32m...deleted \e[0m\n"
                            rm /usr/local/bin/gqdc
                            rm /usr/local/bin/gqdc-testnet
                            printf "\e[1mGo Quadrans binary\e[0m \e[32m...deleted \e[0m\n"
                            userdel quadrans
                            printf "\e[1mQuadrans user\e[0m \e[32m...deleted \e[0m\n"

                            # End of uninstall process
                            printf "\n\e[1mQuadrans Node uninstall completed.\e[0m
Your old Mainnet node configuration and your wallet (if existent) are located in:
\\\"/home/quadrans/\\\" directory (environment and password.txt)
\\\"/home/quadrans/.quadrans/keystore/\\\" directory (wallet private key)
Your old Testnet node configuration file is located in:
\\\"/home/quadrans/\\\" directory (environment-testnet)\n\n"

                            break
                            ;;

                        "Cancel")
                            break
                            ;;
                        *) echo "invalid option $REPLY" ;;
                        esac
                    done

                elif

                    [ -f /usr/local/bin/gqdc ]
                then
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
                            systemctl disable quadrans-node && systemctl stop quadrans-node
                            # Remove service, gqdc binary and quadrans user
                            rm /etc/systemd/system/quadrans-node.service
                            printf "\e[1mGo Quadrans Mainnet service\e[0m \e[32m...removed \e[0m\n"

                            if [[ -s /home/quadrans/environment ]]; then
                                echo
                            else
                                rm /home/quadrans/environment
                            fi
                            rm /home/quadrans/gqdc.sh
                            printf "\e[1mGo Quadrans Mainnet launcher\e[0m \e[32m...deleted \e[0m\n"
                            rm /usr/local/bin/gqdc
                            printf "\e[1mGo Quadrans Mainnet binary\e[0m \e[32m...deleted \e[0m\n"
                            userdel quadrans
                            printf "\e[1mQuadrans user\e[0m \e[32m...deleted \e[0m\n"

                            # End of uninstall process
                            printf "\n\e[1mQuadrans Mainnet Node uninstall completed.\e[0m
Your old Mainnet node configuration and your wallet (if existent) are located in:
\\\"/home/quadrans/\\\" directory (environment and password.txt)
\\\"/home/quadrans/.quadrans/keystore/\\\" directory (wallet private key)\n\n"

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
                            systemctl disable quadrans-node-testnet && systemctl stop quadrans-node-testnet
                            # Remove service, gqdc binary and quadrans user
                            rm /etc/systemd/system/quadrans-node-testnet.service
                            printf "\e[1mGo Quadrans Testnet service\e[0m \e[32m...removed \e[0m\n"
                            rm /home/quadrans/environment-testnet
                            rm /home/quadrans/gqdc-testnet.sh
                            printf "\e[1mGo Quadrans Testnet launcher\e[0m \e[32m...deleted \e[0m\n"
                            rm /usr/local/bin/gqdc-testnet
                            printf "\e[1mGo Quadrans Testnet binary\e[0m \e[32m...deleted \e[0m\n"
                            userdel quadrans
                            printf "\e[1mQuadrans user\e[0m \e[32m...deleted \e[0m\n"

                            # End of uninstall process
                            printf "\n\e[1mQuadrans Testnet Node uninstall completed.\e[0m
Your old Testnet node configuration file is located in:
\\\"/home/quadrans/\\\" directory (environment-testnet)\n\n"

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
        if [ -f /home/quadrans/environment ]; then
            printf "\n\e[1mQuadrans Mainnet node configuration found, reinstallation in progress...\e[0m\n\n"

            # Quadrans user check
            if getent passwd quadrans >/dev/null; then
                printf "quadrans user \e[31malready exists.\e[0m
Do you have a Quadrans Node installed on this computer?
\e[31mInstallation aborted.\e[0m\n"
                exit 1
            else
                # Quadrans user creation and folder permission restore
                printf "\e[1mQuadrans Node configuration in progress...\e[0m
Node user creation in progress... "
                useradd -r -d /home/quadrans -M quadrans
                chown -R quadrans:quadrans /home/quadrans
                printf "\e[32mdone \n\n\e[0m"
            fi

            # Architecture check and binary download
            printf "\e[1mDownloading Go Quadrans for your CPU architecture:\e[0m "

            if [ "$arch" == 'x86_64' ]; then
                printf "x86_64 found\n"
                wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/amd64/gqdc

            elif [ "$arch" == 'x86_32' ]; then
                printf "x86 found\n"
                wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/i386/gqdc

            elif [ "$arch" == 'aarch64' ]; then
                printf "ARM64 found\n"
                wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/arm/arm64/gqdc

            elif [[ "$arch" == 'armv7'* ]]; then
                printf "ARMv7 found\n"
                wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/arm/arm7/gqdc

            else
                printf "Unsupported processor found, you cannot update a Quadrans node on this machine\n"
                exit 1
            fi

            # Make binary executable
            chmod +x /usr/local/bin/gqdc
            printf "\n\e[1mGo Quadrans binary\e[0m \e[32m...downloaded \e[0m\n"

            # Launcher creation
            cat >/home/quadrans/gqdc.sh <<'EOF'
#!/bin/bash
source /home/quadrans/environment

MINER_OPTS=""
STATS_OPTS=""

if [ "${MINER_OPTIONS}" = "true" ]; then
    MINER_OPTS="--mine --unlock ${MINER_WALLET} --password ${MINER_PASSWORD}"
fi

if [ $(grep -c "NODE_LISTED=true" /home/quadrans/environment ) -eq 1 ]; then
    STATS_OPTS=$(printf "%sethstats \"%s\":\"QuadransStatsNetwork\"@status.quadrans.io:3000" "--" "${NODE_NAME}")
fi

eval "/usr/local/bin/gqdc ${GETH_PARAMS} ${MINER_OPTS} ${STATS_OPTS}"
EOF
            chown quadrans:quadrans /home/quadrans/gqdc.sh
            chmod +x /home/quadrans/gqdc.sh

            printf "\e[1mGo Quadrans launcher\e[0m \e[32m...created \e[0m\n"

            # Service creation
            cat >/etc/systemd/system/quadrans-node.service <<'EOF'
Description=Quadrans Node Service
After=network.target

[Service]
Type=simple
User=quadrans
WorkingDirectory=/home/quadrans
EnvironmentFile=/home/quadrans/environment
ExecStart=/home/quadrans/gqdc.sh
Restart=on-failure
RestartSec=60
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=QuadransNode

[Install]
WantedBy=default.target
EOF

            if [ ! -f /home/quadrans/password.txt ]; then

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

                        environmentfile='/home/quadrans/environment'
                        passwordfile='/home/quadrans/password.txt'
                        read -p 'Type your new wallet password (empty to skip): ' nodepassword
                        if [ "$nodepassword" != "" ]; then
                            echo $nodepassword >>$passwordfile
                            WALLET_ADDR=$(su quadrans -c "/usr/local/bin/gqdc account new --datadir /home/quadrans/.quadrans --password /home/quadrans/password.txt | grep -o -e \"\{[A-Za-z0-9]*\}\" | tail -c +2 | head -c -2")
                            su quadrans -c "echo \"export MINER_OPTIONS=true\" >> $environmentfile"
                            su quadrans -c "echo \"export MINER_WALLET=\"0x$WALLET_ADDR\"\" >> $environmentfile"
                            su quadrans -c "echo \"export MINER_PASSWORD=/home/quadrans/password.txt\" >> $environmentfile"
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
            systemctl enable quadrans-node
            printf "\e[1mGo Quadrans service\e[0m \e[32m...enabled \e[0m\n"
            systemctl start quadrans-node
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

        # Quadrans user check
        if getent passwd quadrans >/dev/null; then
            echo ""
            printf "With this function you can switch your Quadrans node from Testnet to Mainnet and the other way around.\n"
            echo ""
        else
            # Stop
            printf "\nYou don't have a Quadrans Node installed on this computer.
\e[31mOperation aborted.\e[0m\n"
            exit 1
        fi

        if [ -f /usr/local/bin/gqdc ] && [ -f /usr/local/bin/gqdc-testnet ] && [ -f /home/quadrans/environment ] && [ -f /home/quadrans/environment-testnet ]; then
            echo "Quadrans Node for Mainnet and Testnet found"
            mainnet_status="$(systemctl show -p SubState --value quadrans-node)"
            testnet_status="$(systemctl show -p SubState --value quadrans-node-testnet)"

            if [ "${mainnet_status}" = "running" ]; then
                echo "Mainnet running, switching to Testnet"
            elif [ "${testnet_status}" = "running" ]; then
                echo "Testnet running, switching to Mainnet"
            fi
        elif [ -e /usr/local/bin/gqdc ] && [ -e /home/quadrans/environment ]; then
            echo "Quadrans Node for Mainnet found, switching to Testnet"
        elif [ -e /usr/local/bin/gqdc-testnet ] && [ -e /home/quadrans/environment-testnet ]; then
            echo "Quadrans Node for Testnet found, switching to Mainnet"
        fi

        printf "Do you want to proceed?\n"
        echo ""

        PS3='Please select: '
        options=("Yes" "Cancel")
        select opt in "${options[@]}"; do
            case $opt in
            "Yes")

                if [ -f /usr/local/bin/gqdc ] && [ -f /usr/local/bin/gqdc-testnet ] && [ -f /home/quadrans/environment ] && [ -f /home/quadrans/environment-testnet ]; then
                    # Quadrans Node for Mainnet and Testnet, switch the running

                    if [ "${mainnet_status}" = "running" ]; then
                        # Start the node and enable the service
                        systemctl stop quadrans-node
                        systemctl disable quadrans-node
                        systemctl enable quadrans-node-testnet
                        systemctl restart quadrans-node-testnet
                        printf "\e[1mGo Quadrans Node switched \e[0m \e[32m...from Mainnet to Testnet \e[0m\n "

                    elif [ "${testnet_status}" = "running" ]; then
                        # Start the node and enable the service
                        systemctl stop quadrans-node-testnet
                        systemctl disable quadrans-node-testnet
                        systemctl enable quadrans-node
                        systemctl restart quadrans-node
                        printf "\e[1mGo Quadrans Node switched \e[0m \e[32m...from Testnet to Mainnet \e[0m\n "

                    else
                        echo "Something goes wrong. Error code 5.1"
                        exit 1
                    fi

                elif
                    [ -e /usr/local/bin/gqdc ] && [ -e /home/quadrans/environment ]
                then
                    # Quadrans Node for Mainnet to Testnet

                    mainnet_status="$(systemctl show -p SubState --value quadrans-node)"

                    if [ "${mainnet_status}" = "running" ]; then
                        # Start the node and enable the service
                        systemctl stop quadrans-node
                        systemctl disable quadrans-node
                    fi

                    printf "\e[1mDownloading Go Quadrans for Testnet for your CPU architecture:\e[0m "

                    if [ "$arch" == 'x86_64' ]; then
                        printf "x86_64 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc-testnet http://repo.quadrans.io/linux/test/amd64/gqdc

                    elif [ "$arch" == 'x86_32' ]; then
                        printf "x86 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc-testnet http://repo.quadrans.io/linux/test/i386/gqdc

                    elif [ "$arch" == 'aarch64' ]; then
                        printf "ARM64 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc-testnet http://repo.quadrans.io/linux/test/arm/arm64/gqdc

                    elif [[ "$arch" == 'armv7'* ]]; then
                        printf "ARMv7 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc-testnet http://repo.quadrans.io/linux/test/arm/arm7/gqdc

                    else
                        printf "Unsupported processor found, you cannot install a Quadrans node on this machine\n"
                        exit 1
                    fi

                    # Make Testnet binary executable
                    chmod +x /usr/local/bin/gqdc-testnet
                    printf "\n\e[1mGo Quadrans Testnet binary\e[0m \e[32m...downloaded \e[0m\n"

                    # Testnet Launcher creation
                    cat >/home/quadrans/gqdc-testnet.sh <<'EOF'
#!/bin/bash
source /home/quadrans/environment-testnet

STATS_OPTS=""

if [ $(grep -c "NODE_LISTED=true" /home/quadrans/environment-testnet ) -eq 1 ]; then
    STATS_OPTS=$(printf "%sethstats \"%s\":\"QuadransStatsNetwork\"@status.testnet.quadrans.io:3000" "--" "${NODE_NAME}")
fi

eval "/usr/local/bin/gqdc-testnet --testnet --rpc --rpcapi=\"personal,net,web3,admin,debug,clique,eth\" --rpccorsdomain \"*\" --rpcaddr \"127.0.0.1\" --allow-insecure-unlock ${STATS_OPTS}"
EOF
                    chown quadrans:quadrans /home/quadrans/gqdc-testnet.sh
                    chmod +x /home/quadrans/gqdc-testnet.sh

                    printf "\e[1mGo Quadrans Testnet launcher\e[0m \e[32m...created \e[0m\n"

                    # Testnet Service creation
                    cat >/etc/systemd/system/quadrans-node-testnet.service <<'EOF'
Description=Quadrans Node Testnet Service
After=network.target

[Service]
Type=simple
User=quadrans
WorkingDirectory=/home/quadrans
EnvironmentFile=/home/quadrans/environment-testnet
ExecStart=/home/quadrans/gqdc-testnet.sh
Restart=on-failure
RestartSec=60
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=QuadransNodeTest

[Install]
WantedBy=default.target
EOF

                    printf "\e[1mGo Quadrans Testnet service\e[0m \e[32m...created \e[0m\n"

                    # Testnet Node configuration
                    # Testnet Node name
                    printf "\e[1mChoose a name for your Quadrans node\e[0m
The name will appear in Quadrans Network Testnet Status page.\n\n"

                    environmentfile='/home/quadrans/environment-testnet'
                    read -p "Enter the name of your testnet node: " nodename
                    if [ "$nodename" != "" ]; then
                        su quadrans -c "echo \"export NODE_LISTED=true\" >> $environmentfile"
                        su quadrans -c "echo \"export NODE_NAME=\\\"$nodename\\\"\" >> $environmentfile"
                    else
                        su quadrans -c "echo \"export NODE_LISTED=false\" >> $environmentfile"
                        su quadrans -c "echo \"export NODE_NAME=\\\"\\\"\" >> $environmentfile"
                    fi

                    printf "\e[1mQuadrans node configuration\e[0m \e[32m...done \e[0m\n"

                    systemctl enable quadrans-node-testnet
                    printf "\e[1mGo Quadrans Testnet service\e[0m \e[32m...enabled \e[0m\n"
                    systemctl start quadrans-node-testnet
                    printf "\e[1mGo Quadrans Testnet service\e[0m \e[32m...started \e[0m\n"
                    printf "\e[1mGo Quadrans Node switched \e[0m \e[32m...from Mainnet to Testnet \e[0m\n "

                elif

                    [ -e /usr/local/bin/gqdc-testnet ] && [ -e /home/quadrans/environment-testnet ]
                then
                    echo "Quadrans Node for Testnet found, switching to Mainnet"

                    testnet_status="$(systemctl show -p SubState --value quadrans-node-testnet)"

                    if [ "${testnet_status}" = "running" ]; then
                        # Start the node and enable the service
                        systemctl stop quadrans-node-testnet
                        systemctl disable quadrans-node-testnet
                    fi

                    printf "\e[1mDownloading Go Quadrans for your CPU architecture:\e[0m "

                    if [ "$arch" == 'x86_64' ]; then
                        printf "x86_64 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/amd64/gqdc

                    elif [ "$arch" == 'x86_32' ]; then
                        printf "x86 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/i386/gqdc

                    elif [ "$arch" == 'aarch64' ]; then
                        printf "ARM64 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/arm/arm64/gqdc

                    elif [[ "$arch" == 'armv7'* ]]; then
                        printf "ARMv7 found\n"
                        wget -q --show-progress --progress=bar:force:noscroll -O /usr/local/bin/gqdc http://repo.quadrans.io/linux/arm/arm7/gqdc

                    else
                        printf "Unsupported processor found, you cannot install a Quadrans node on this machine\n"
                        exit 1
                    fi

                    # Mainnet binary executable
                    chmod +x /usr/local/bin/gqdc
                    printf "\n\e[1mGo Quadrans binary\e[0m \e[32m...downloaded \e[0m\n"

                    # Mainnet launcher creation
                    cat >/home/quadrans/gqdc.sh <<'EOF'
#!/bin/bash
source /home/quadrans/environment

MINER_OPTS=""
STATS_OPTS=""

if [ "${MINER_OPTIONS}" = "true" ]; then
    MINER_OPTS="--mine --unlock ${MINER_WALLET} --password ${MINER_PASSWORD}"
fi

if [ $(grep -c "NODE_LISTED=true" /home/quadrans/environment ) -eq 1 ]; then
    STATS_OPTS=$(printf "%sethstats \"%s\":\"QuadransStatsNetwork\"@status.quadrans.io:3000" "--" "${NODE_NAME}")
fi

eval "/usr/local/bin/gqdc ${GETH_PARAMS} ${MINER_OPTS} ${STATS_OPTS}"
EOF
                    chown quadrans:quadrans /home/quadrans/gqdc.sh
                    chmod +x /home/quadrans/gqdc.sh

                    printf "\e[1mGo Quadrans launcher\e[0m \e[32m...created \e[0m\n"

                    # Mainnet service creation
                    cat >/etc/systemd/system/quadrans-node.service <<'EOF'
Description=Quadrans Node Service
After=network.target

[Service]
Type=simple
User=quadrans
WorkingDirectory=/home/quadrans
EnvironmentFile=/home/quadrans/environment
ExecStart=/home/quadrans/gqdc.sh
Restart=on-failure
RestartSec=60
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=QuadransNode

[Install]
WantedBy=default.target
EOF

                    printf "\e[1mGo Quadrans service\e[0m \e[32m...created \e[0m\n"

                    # Node configuration
                    # Node name
                    printf "\e[1mChoose a name for your Quadrans node\e[0m
The name will appear in Quadrans Network Status page and it is mandatory for mining.
If you leave it empty this node will be a Lightnode.
Please visit Quadrans Documentation for other information: https://docs.quadrans.io\n\n"

                    environmentfile='/home/quadrans/environment'
                    read -p "Enter the name of your node: " nodename
                    if [ "$nodename" != "" ]; then
                        su quadrans -c "echo \"export NODE_LISTED=true\" >> $environmentfile"
                        su quadrans -c "echo \"export NODE_NAME=\\\"$nodename\\\"\" >> $environmentfile"

                        # Node wallet password
                        printf "\n\e[1mCreate a new Quadrans Wallet and enable mining\e[0m
To create a new wallet you need to set a password
If you leave it empty the wallet creation will be skipped\n\n"

                        passwordfile='/home/quadrans/password.txt'
                        read -p 'Type your new wallet password (empty to skip): ' nodepassword
                        if [ "$nodepassword" != "" ]; then
                            echo $nodepassword >>$passwordfile
                            WALLET_ADDR=$(su quadrans -c "/usr/local/bin/gqdc account new --datadir /home/quadrans/.quadrans --password /home/quadrans/password.txt | grep -o -e \"\{[A-Za-z0-9]*\}\" | tail -c +2 | head -c -2")
                            su quadrans -c "echo \"export MINER_OPTIONS=true\" >> $environmentfile"
                            su quadrans -c "echo \"export MINER_WALLET=\"0x$WALLET_ADDR\"\" >> $environmentfile"
                            su quadrans -c "echo \"export MINER_PASSWORD=/home/quadrans/password.txt\" >> $environmentfile"
                        fi

                    fi

                    printf "\e[1mQuadrans node configuration\e[0m \e[32m...done \e[0m\n"

                    systemctl enable quadrans-node
                    printf "\e[1mGo Quadrans service\e[0m \e[32m...enabled \e[0m\n"
                    systemctl start quadrans-node
                    printf "\e[1mGo Quadrans service\e[0m \e[32m...started \e[0m\n"
                    printf "\e[1mGo Quadrans Node switched \e[0m \e[32m...from Testnet to Mainnet \e[0m\n "

                    if [ "$nodename" != "" ]; then
                        echo ""
                        printf "\e[1mQuadrans Node Information\e[0m\n"
                        printf "Your node name is: \e[32m$nodename\e[0m\n"
                        if [ "$nodepassword" != "" ]; then
                            printf "Your public address is: \e[32m0x$WALLET_ADDR\e[0m\n"
                            printf "Your wallet password is: \e[32m$nodepassword\e[0m\n"
                            printf "Your private key is located in the \\\"/home/quadrans/.quadrans/keystore/\\\" directory\n\n"
                        fi
                    fi

                else

                    echo "Error code 5.2"
                    exit 1

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

    "Abort")
        break
        ;;
    *) echo "invalid option $REPLY" ;;
    esac
done
