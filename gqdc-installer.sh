#!/bin/bash
#/ Usage: sudo bash gqdc-installer.sh [options]
#/
#/ This is a command line tool to install Quadrans node
#/
#/ Options:
#/   -h | --help       Show this message.
#/   -v | --version    Show version number.
#/
#/ For assistance:
#/   read the documentation: https://docs.quadrans.io
#/   contact the team on Telegram: https://t.me/quadrans

######################################################
#      Go Quadrans bash installation launcher        #
#       Script created by Piersandro Guerrera        #
#          piersandro.guerrera@quadrans.io           #
#                                                    #
# Feel free to modify, but please give credit where  #
# it's due. Thanks!                                  #
######################################################

version=1.2

# Parse arguments
while true; do
  case "$1" in
  -h | --help)
    show_help=true
    shift
    ;;
  -v | --version)
    echo "Version $version"
    exit 1
    ;;
  -*)
    echo "Error: invalid argument: '$1'" 1>&2
    exit 1
    ;;
  *)
    break
    ;;
  esac
done

print_usage() {
  grep '^#/' <"$0" | cut -c 4-
  exit 1
}

if [ -n "$show_help" ]; then
  print_usage
else
  for x in "$@"; do
    if [ "$x" = "--help" ] || [ "$x" = "-h" ]; then
      print_usage
    fi
  done
fi

if [ "$(id -u)" != "0" ]; then
  echo "You must be the superuser to run this script. Use 'sudo bash gqdc-installer.sh'" >&2
  exit 1
fi

# banner
echo '
  ___                  _                       _   _           _      
 / _ \ _   _  __ _  __| |_ __ __ _ _ __  ___  | \ | | ___   __| | ___ 
| | | | | | |/ _` |/ _` | `__/ _` | `_ \/ __| |  \| |/ _ \ / _` |/ _ \
| |_| | |_| | (_| | (_| | | | (_| | | | \__ \ | |\  | (_) | (_| |  __/
 \__\_\\__,_|\__,_|\__,_|_|  \__,_|_| |_|___/ |_| \_|\___/ \__,_|\___|
'
# Operating system check
opsys=$(uname)

if [ "$opsys" == 'Linux' ]; then
  # Internet connection check
  printf "\e[1mConnection test... \e[0m"
  wget -q --spider http://www.google.com
  if [ $? -eq 0 ]; then
    printf "\e[32mpassed \n\e[0m"

    printf "\e[1mDownloading latest installer... \e[0m"
    wget -q http://repo.quadrans.io/installer/service/gqdc-installer-linux.sh
    printf "\e[32mdone \n\e[0m"
    chmod +x gqdc-installer-linux.sh
    ./gqdc-installer-linux.sh 2>&1 | tee -a /var/log/gqdc-installer.log
    rm gqdc-installer-linux.sh*
  else
    printf "\e[31moffline.\e[0m\nQuadrans Node installation aborted for no Internet connection.\n"
    echo ""
    exit 1
  fi

elif [ "$opsys" == 'Darwin' ]; then
  # Internet connection check
  printf "\e[1mConnection test... \e[0m"
  if curl -s --head --request GET www.google.com | grep "200 OK" >/dev/null; then
    printf "\e[32mpassed \n\e[0m"
    curl -s http://repo.quadrans.io/installer/service/gqdc-installer-mac.sh > gqdc-installer-mac.sh
    chmod +x gqdc-installer-mac.sh
    ./gqdc-installer-mac.sh 2>&1 | tee -a /var/log/gqdc-installer.log
    rm gqdc-installer-mac.sh*
  else
    printf "\e[31moffline.\e[0m\nQuadrans Node installation aborted for no Internet connection.\n"
    echo ""
    exit 1
  fi

else
  printf "Unsupported operating system, you cannot install a Quadrans node on this machine\n"
  exit 1

fi

echo ""
echo "Elapsed time: $SECONDS seconds"
