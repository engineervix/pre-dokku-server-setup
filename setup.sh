#!/usr/bin/env bash

# =================================================================================================
# description:  Initial Ubuntu VPS server setup prior to installation of Dokku (tested on 20.04, 22.04)
# author:       Victor Miti <https://github.com/engineervix>
# url:          <https://github.com/engineervix/pre-dokku-server-setup>
# version:      0.1.0
# license:      MIT
# =================================================================================================

set -e

# shellcheck disable=SC2034
ARGPARSE_DESCRIPTION="Initial Ubuntu VPS server setup prior to installation of Dokku"

function getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${current_dir}" ]]; then current_dir="$PWD"; fi
    echo "${current_dir}"
}

function includeDependencies() {
    # shellcheck source=/dev/null
    source "${current_dir}/setupLibrary.sh"

    # shellcheck source=/dev/null
    source "${current_dir}/argparse.bash" || exit 1
}

current_dir=$(getCurrentDir)
includeDependencies
output_file="output.log"

argparse "$@" <<EOF || exit 1
parser.add_argument('-s', '--sendgrid', action='store_true',
                    default=False, help='setup mail with Sendgrid [default %(default)s]')
parser.add_argument('-m', '--mailjet', action='store_true',
                    default=False, help='setup mail with MailJet [default %(default)s]')
parser.add_argument('-t', '--texlive', action='store_true',
                    default=False, help='install texlive-full [default %(default)s]')
EOF

if [[ $SENDGRID && $MAILJET ]]; then
    echo -e "\e[31mYou cannot select both Sendgrid & MailJet... \e[00m"
    exit 1
fi

function main() {
    read -rp "Do you want to create a new non-root user? (Recommended) [Y/N] " createUser

    # Run setup functions
    trap cleanup EXIT SIGHUP SIGINT SIGTERM

    if [[ $createUser == [nN] ]]; then
        username=$(whoami)
        updateUserAccount "${username}"
    elif [[ $createUser == [yY] ]]; then
        read -rp "Enter the username of the new user account: " username
        addUserAccount "${username}"
    else
	echo 'This is not a valid choice!'
	exit 1
    fi

    read -rp $'Paste in the public SSH key for the new user:\n' sshKey
    echo 'Running setup script...'
    logTimestamp "${output_file}"

    # Use exec and tee to redirect logs to stdout and a log file at the same time 
    # https://unix.stackexchange.com/a/145654
    exec > >(tee -a "${output_file}") 2>&1

    disableSudoPassword "${username}"
    addSSHKey "${username}" "${sshKey}"
    changeSSHConfig
    extraHardening
    setupUfw

    if ! hasSwap; then
        setupSwap
    fi

    setupTimezone

    echo -e "\e[35mConfiguring System Time... \e[00m"
    configureNTP

    sudo -i -u "${username}" -H bash -c "mkdir -p /home/${username}/bin"

    setupZSH
    setupRuby
    setupPython
    setupVim
    setupTmux
    if [[ $SENDGRID ]]; then
        setupMailWithSendgrid
        configureUpdatesNotificationsAndLogwatch
    fi
    if [[ $MAILJET ]]; then
        setupMailwithMailJet
        configureUpdatesNotificationsAndLogwatch
    fi
    configureUnattendedUpgrades
    furtherHardening
    miscellaneousTasks
    installExtraPackages

    sudo service ssh restart

    cleanup

    echo -e "\e[35mYou have installed ZSH $(zsh --version)\e[00m" 
    echo -e "\e[35mLet us now make ZSH your default shell ...\e[00m" 
    # shellcheck disable=SC2230
    sudo -i -u "${username}" -H bash -c "chsh -s $(which zsh)"

    sudo mv -v "${current_dir}/${output_file}" /home/"${username}"/ && sudo chown -R "${username}":"${username}" /home/"${username}"/"${output_file}"
    sudo rm -fv /home/"${username}"/oh_my_zsh_install.sh
    echo -e "Setup Done! Log file (\e[35m${output_file}\e[00m) is in \e[35m${username}\e[00m's home directory"
}

function setupSwap() {
    createSwap
    mountSwap
    tweakSwapSettings "10" "50"
    saveSwapSettings "10" "50"
}

function hasSwap() {
    [[ "$(sudo swapon -s)" == *"/swapfile"* ]]
}

function cleanup() {
    if [[ -f "/etc/sudoers.bak" ]]; then
        revertSudoers
    fi
}

function logTimestamp() {
    local filename=${1}
    {
        echo "===================" 
        echo "Log generated on $(date)"
        echo "==================="
    } >>"${filename}" 2>&1
}

function setupTimezone() {
    echo -ne "Enter the timezone for the server (Default is 'Africa/Lusaka'):\n"
    read -r timezone
    if [ -z "${timezone}" ]; then
        timezone="Africa/Lusaka"
    fi
    setTimezone "${timezone}"
    echo "Timezone is set to $(cat /etc/timezone)"
}


function extraHardening() {
    # restrict access to the server
    echo "AllowUsers ${username} dokku" | sudo tee -a /etc/ssh/sshd_config

    # Secure Shared Memory
    # tip 6 at https://hostadvice.com/how-to/how-to-harden-your-ubuntu-18-04-server/
    echo "none /run/shm tmpfs defaults,ro 0 0" | sudo tee -a /etc/fstab
}

function setupZSH() {
    sudo apt-get install zsh -y

    # ohmyzsh
    sudo wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O /home/"$username"/oh_my_zsh_install.sh
    sudo -i -u "${username}" -H bash -c "ZSH=\"/home/$username/.oh-my-zsh\" sh oh_my_zsh_install.sh --unattended"
    sudo chown -R "${username}":"${username}" /home/"${username}"/.oh-my-zsh
    sudo cp -v "${current_dir}"/extras/.zshrc /home/"$username"/ && sudo chown -R "${username}":"${username}" /home/"$username"/.zshrc
    sudo -i -u "${username}" -H bash -c "sed -i \"s/root/home\/$username/g\" /home/$username/.zshrc"
    # powerlevel10k
    sudo -i -u "${username}" -H bash -c "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-/home/$username/.oh-my-zsh/custom}/themes/powerlevel10k"
    # Replace ZSH_THEME="robbyrussell" with ZSH_THEME="powerlevel10k/powerlevel10k".
    sudo -i -u "${username}" -H bash -c "sed 's/robbyrussell/powerlevel10k\/powerlevel10k/g' -i /home/$username/.zshrc"

    # font installation
    sudo apt install fonts-inconsolata fonts-symbola -y
    sudo apt install fonts-powerline -y

    wget https://github.com/Lokaltog/powerline/raw/develop/font/PowerlineSymbols.otf https://github.com/Lokaltog/powerline/raw/develop/font/10-powerline-symbols.conf
    wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
    wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
    wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
    wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

    sudo mv -v PowerlineSymbols.otf /usr/share/fonts/
    sudo mv -v MesloLGS*.ttf /usr/share/fonts/

    sudo fc-cache -vf

    sudo mv 10-powerline-symbols.conf /etc/fonts/conf.d/

    # https://github.com/zsh-users/zsh-autosuggestions
    sudo -i -u "${username}" -H bash -c "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-/home/$username/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

    # https://github.com/zsh-users/zsh-syntax-highlighting
    sudo -i -u "${username}" -H bash -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-/home/$username/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

    echo -e "\e[35min order to use your fancy new ZSH setup, you'll have to later exit terminal and enter a new session\e[00m" 
}

function setupRuby() {
    sudo apt-get install ruby-full ruby-bundler -y
}

function setupTmux() {
    # tmux is already installed, no need to install it using apt install
    sudo apt install powerline -y
    # https://github.com/tmux-plugins/tpm
    sudo -i -u "${username}" -H bash -c "git clone https://github.com/tmux-plugins/tpm /home/$username/.tmux/plugins/tpm"
    sudo cp -v "${current_dir}"/extras/.tmux.conf /home/"$username"/ && sudo chown -R "${username}":"${username}" /home/"$username"/.tmux.conf
    # gives "error connecting to /tmp//tmux-1000/default (No such file or directory)"
    # sudo -i -u "${username}" -H bash -c "tmux source /home/$username/.tmux.conf"
}

function setupPython() {
    # some essentials (based on https://github.com/pyenv/pyenv/wiki#suggested-build-environment)
    sudo apt-get install --no-install-recommends make net-tools build-essential libssl-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev xz-utils libxml2-dev libxmlsec1-dev liblzma-dev -y

    sudo apt-get install -y python3-full python3-pip

    # virtualenvwrapper
    sudo apt-get install python3-virtualenvwrapper -y
    export WORKON_HOME=/home/$username/Env
    sudo mkdir -p "$WORKON_HOME" && sudo chown -R "${username}":"${username}" /home/"${username}"/Env/

    sudo -i -u "${username}" -H bash -c "echo \"\" >> /home/$username/.zshrc"
    sudo -i -u "${username}" -H bash -c "echo \"# virtualenvwrapper\" >> /home/$username/.zshrc"
    sudo -i -u "${username}" -H bash -c "echo \"export WORKON_HOME=~/Env\" >> /home/$username/.zshrc"
    sudo -i -u "${username}" -H bash -c "echo \"export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3\" >> /home/$username/.zshrc"
    sudo -i -u "${username}" -H bash -c "echo \"source /usr/share/virtualenvwrapper/virtualenvwrapper.sh\" >> /home/$username/.zshrc"
    sudo -i -u "${username}" -H bash -c "echo \"\" >> /home/$username/.zshrc"
}

function setupVim() {
    # Vim setup
    sudo -u "${username}" -H bash -c "sudo apt-get install python3-powerline -y"
    sudo apt-get install vim-nox -y
    sudo -u "${username}" -H bash -c "curl -L https://gist.githubusercontent.com/engineervix/d9cef5adb520b6c2f2ee0e01e5280f1e/raw/8730b81fb4b18eb4476976520de9672d3335eaee/janus_setup.sh | bash"
    pushd "$HOME"/pre-dokku-server-setup/
    sudo cp -rv "$HOME"/pre-dokku-server-setup/.janus/ /home/"${username}"/ && sudo chown -R "${username}":"${username}" /home/"${username}"/.janus/
    sudo cp -v "$HOME"/pre-dokku-server-setup/extras/.vimrc.before /home/"${username}"/ && sudo chown -R "${username}":"${username}" /home/"${username}"/.vimrc.before
    sudo cp -v "$HOME"/pre-dokku-server-setup/extras/.vimrc.after /home/"${username}"/ && sudo chown -R "${username}":"${username}" /home/"${username}"/.vimrc.after
}

function setupMailWithSendgrid() {

    read -rp 'email address for root (dest email)?: ' root_email 
    read -rp 'email address for sending mail (from email)?: ' mail_from 
    sendgrid_domain=${mail_from#*@*}
    system_hostname=$(hostname)

    sudo debconf-set-selections <<< "postfix postfix/mailname string ${sendgrid_domain}"
    sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

    # Install Postfix
    sudo apt-get install libsasl2-modules postfix -y
    sudo apt-mark auto libsasl2-modules
    sudo apt install mailutils -y

    # Install mutt
    sudo apt install mutt -y

    # First, let's deal with /etc/postfix/main.cf
    sudo mv -v /etc/postfix/main.cf /etc/postfix/main.cf.bak
    sudo cp -v extras/sendgrid/postfix_main.cf /etc/postfix/main.cf
    sudo sed -i "s/CHANGE_THIS_TO_HOSTNAME/${system_hostname}/g" /etc/postfix/main.cf
    sudo sed -i "s/CHANGETHIS_TO_SENDGRID_DOMAIN/${sendgrid_domain}/g" /etc/postfix/main.cf

    # /etc/mailname already has ${sendgrid_domain}, so we don't mess with it

    # Now, we deal with /etc/postfix/sasl_passwd
    echo -e "\e[35m===========================================================\e[00m" 
    echo -e "\e[35m Please provide your Sendgrip API key for Postfix to use. \e[00m" 
    echo -e "\e[35m NOTE: It will not be displayed in the terminal when you type / paste it in\e[00m"
    # shellcheck disable=SC2162
    read -s -p "Sendgrid API key?: " sendgrid_api_key
    echo "[smtp.sendgrid.net]:587 apikey:${sendgrid_api_key}" | sudo dd of=/etc/postfix/sasl_passwd
    echo -e "\e[35m===========================================================\e[00m" 

    sudo postmap hash:/etc/postfix/sasl_passwd
    sudo chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
    sudo chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

    # aliases
    echo "" | sudo tee -a /etc/aliases
    echo "root: ${root_email}" | sudo tee -a /etc/aliases
    sudo newaliases

    # canonical_maps
    echo "/.+/    ${mail_from}" | sudo tee /etc/postfix/sender_canonical_maps

    # header_check
    echo "/From:.*/ REPLACE From: ${mail_from}" | sudo tee /etc/postfix/header_check

    # reload postfix
    sudo postfix reload
}

function setupMailwithMailJet() {

    read -rp 'email address for root (dest email)?: ' root_email 
    read -rp 'email address for sending mail (from email)?: ' mail_from 
    mailjet_domain=${mail_from#*@*}
    system_hostname=$(hostname)

    sudo debconf-set-selections <<< "postfix postfix/mailname string ${mailjet_domain}"
    sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

    # Install Postfix
    sudo apt-get install libsasl2-modules postfix -y
    sudo apt-mark auto libsasl2-modules
    sudo apt install mailutils -y

    # Install mutt
    sudo apt install mutt -y

    # First, let's deal with /etc/postfix/main.cf
    sudo mv -v /etc/postfix/main.cf /etc/postfix/main.cf.bak
    sudo cp -v extras/mailjet/postfix_main.cf /etc/postfix/main.cf
    sudo sed -i "s/CHANGE_THIS_TO_HOSTNAME/${system_hostname}/g" /etc/postfix/main.cf
    sudo sed -i "s/CHANGETHIS_TO_MAILJET_DOMAIN/${mailjet_domain}/g" /etc/postfix/main.cf

    # /etc/mailname already has ${mailjet_domain}, so we don't mess with it

    # Now, we deal with /etc/postfix/sasl_passwd
    echo -e "\e[35m===========================================================\e[00m" 
    echo -e "\e[35m Please provide your Mailjet API key for Postfix to use. \e[00m" 
    echo -e "\e[35m NOTE: It will not be displayed in the terminal when you type / paste it in\e[00m"
    # shellcheck disable=SC2162
    read -s -p 'Mailjet API key?: ' mailjet_api_key
    # shellcheck disable=SC2162
    read -s -p 'Mailjet Secret key?: ' mailjet_secret_key
    echo "[in-v3.mailjet.com]:587 ${mailjet_api_key}:${mailjet_secret_key}" | sudo dd of=/etc/postfix/sasl_passwd
    echo -e "\e[35m===========================================================\e[00m" 

    sudo postmap hash:/etc/postfix/sasl_passwd
    sudo chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
    sudo chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

    # aliases
    echo "" | sudo tee -a /etc/aliases
    echo "root: ${root_email}" | sudo tee -a /etc/aliases
    sudo newaliases

    # canonical_maps
    echo "/.+/    ${mail_from}" | sudo tee /etc/postfix/sender_canonical_maps

    # header_check
    echo "/From:.*/ REPLACE From: ${mail_from}" | sudo tee /etc/postfix/header_check

    # reload postfix
    sudo postfix reload
}

function configureUpdatesNotificationsAndLogwatch() {
    # Updates notification and other necessary sysadmin stuff

    # https://help.ubuntu.com/lts/serverguide/automatic-updates.html.en
    # https://linuxize.com/post/how-to-set-up-automatic-updates-on-ubuntu-18-04/
    sudo apt install apticron -y
    echo -e "\e[35m===========================================================\e[00m"
    echo "copying the \e[35mextras/apticron.conf\e[00m file to \e[35m/etc/apticron/apticron.conf\e[00m ..."
    sudo cp -v extras/apticron.conf /etc/apticron/apticron.conf
    echo "to be notified (via email) of any impending updates, I'll update \e[35mEMAIL=\e[00m ..."
    sudo sed -i "s/^EMAIL=\"\"/EMAIL=\"$root_email\"/" /etc/apticron/apticron.conf
    echo -e "\e[35m===========================================================\e[00m"

    # logwatch
    # https://www.howtoforge.com/tutorial/logwatch-installation-on-debian-and-ubuntu/
    # https://help.ubuntu.com/community/Logwatch
    # http://www.stellarcore.net/logwatch/tabs/docs/HOWTO-Customize-LogWatch.html
    sudo apt-get install logwatch -y
    sudo mkdir /var/cache/logwatch
    sudo cp -v /usr/share/logwatch/default.conf/logwatch.conf /etc/logwatch/conf/

    echo -e "\e[35m===========================================================\e[00m"
    echo -e "\e[35mNow, I will edit the /etc/logwatch/conf/logwatch.conf file ...\e[00m"
    echo "	Output = mail"
    echo "	Format = html"
    echo "	MailTo = me@example.com"
    echo "	MailFrom = email@example.com"
    echo "	Detail = High|Med"
    sudo sed -i 's/^Output\ =\ stdout/Output\ =\ mail/' /etc/logwatch/conf/logwatch.conf
    sudo sed -i 's/^Format\ =\ text/Format\ =\ html/' /etc/logwatch/conf/logwatch.conf
    sudo sed -i "s/^MailTo\ =\ root/MailTo\ =\ $root_email/" /etc/logwatch/conf/logwatch.conf
    sudo sed -i "s/^MailFrom\ =\ Logwatch/MailFrom\ =\ $mail_from/" /etc/logwatch/conf/logwatch.conf
    sudo sed -i 's/^Detail\ =\ Low/Detail\ =\ Med/' /etc/logwatch/conf/logwatch.conf
    echo -e "\e[35m===========================================================\e[00m"
}

function configureUnattendedUpgrades() {
    sudo apt install apt-show-versions -y
    # sudo dpkg-reconfigure -plow unattended-upgrades
    echo "unattended-upgrades       unattended-upgrades/enable_auto_updates boolean true" | sudo debconf-set-selections; sudo dpkg-reconfigure -f noninteractive unattended-upgrades
    echo -e "\e[35m===========================================================\e[00m"
    echo "I am now configuring the Unattended Upgrades package ..."
    #   sudo vim /etc/apt/apt.conf.d/50unattended-upgrades
    # 1. Unattended-Upgrade::DevRelease "auto"                        » Unattended-Upgrade::DevRelease\ "false"
    # 2. //Unattended-Upgrade::Mail ""                                » Unattended-Upgrade::Mail\ "$root_email"
    # 3. //Unattended-Upgrade::Remove-Unused-Kernel-Packages\ "true"  » Unattended-Upgrade::Remove-Unused-Kernel-Packages\ "true"
    # 4. //Unattended-Upgrade::Remove-New-Unused-Dependencies\ "true" » Unattended-Upgrade::Remove-New-Unused-Dependencies\ "true"
    # 5. //Unattended-Upgrade::Automatic-Reboot\ "false"              » Unattended-Upgrade::Automatic-Reboot\ "true"
    # 6. //Unattended-Upgrade::Automatic-Reboot-Time\ "02:00"         » Unattended-Upgrade::Automatic-Reboot-Time\ "02:17"
    sudo sed -i 's/^Unattended-Upgrade::DevRelease\ "auto"/Unattended-Upgrade::DevRelease\ "false"/' /etc/apt/apt.conf.d/50unattended-upgrades
    sudo sed -i "s#^//Unattended-Upgrade::Mail\ \"\"#Unattended-Upgrade::Mail\ \"$root_email\"#" /etc/apt/apt.conf.d/50unattended-upgrades
    sudo sed -i 's#^//Unattended-Upgrade::Remove-Unused-Kernel-Packages\ "true"#Unattended-Upgrade::Remove-Unused-Kernel-Packages\ "true"#' /etc/apt/apt.conf.d/50unattended-upgrades
    sudo sed -i 's#^//Unattended-Upgrade::Remove-New-Unused-Dependencies\ "true"#Unattended-Upgrade::Remove-New-Unused-Dependencies\ "true"#' /etc/apt/apt.conf.d/50unattended-upgrades
    sudo sed -i 's#^//Unattended-Upgrade::Automatic-Reboot\ "false"#Unattended-Upgrade::Automatic-Reboot\ "true"#' /etc/apt/apt.conf.d/50unattended-upgrades
    sudo sed -i 's#^//Unattended-Upgrade::Automatic-Reboot-Time\ "02:00"#Unattended-Upgrade::Automatic-Reboot-Time\ "02:17"#' /etc/apt/apt.conf.d/50unattended-upgrades
    echo -e "\e[35m===========================================================\e[00m"
    echo "APT::Periodic::AutocleanInterval \"7\";" | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades
}


function furtherHardening() {
    # https://www.digitalocean.com/community/questions/best-practices-for-hardening-new-sever-in-2017
    # https://linux-audit.com/ubuntu-server-hardening-guide-quick-and-secure/
    # https://dennisnotes.com/note/20180627-ubuntu-18.04-server-setup/
    # https://www.ncsc.gov.uk/guidance/eud-security-guidance-ubuntu-1804-lts
    # https://www.ubuntu.com/security
    sudo apt install fail2ban -y
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    echo -e "\e[35m===========================================================\e[00m"
    echo -e "\e[35mNow updating the /etc/fail2ban/jail.local file ...\e[00m"
    sudo sed -i "s/^destemail\ =\ root@localhost/destemail\ =\ $root_email/" /etc/fail2ban/jail.local
    sudo sed -i "s/^sender\ =\ root@<fq-hostname>/sender\ =\ $mail_from/" /etc/fail2ban/jail.local
    echo -e "\e[35menabling sshd ...\e[00m"
    sudo sed -i '/^\[sshd\]/a enabled\ =\ true' /etc/fail2ban/jail.local
    echo -e "\e[35m===========================================================\e[00m"

    # lynis -- https://cisofy.com/lynis/
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 013baa07180c50a7101097ef9de922f1c2fde6c4
    sudo apt install apt-transport-https -y
    echo 'Acquire::Languages "none";' | sudo tee /etc/apt/apt.conf.d/99disable-translations
    echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list
    sudo apt update
    sudo apt install lynis -y

    if [[ $SENDGRID || $MAILJET ]]; then
        # https://www.theurbanpenguin.com/detecting-rootkits-with-rkhunter-in-ubuntu-18-04/
        sudo apt install -y rkhunter
    fi

    sudo lynis audit system
}

function miscellaneousTasks() {

    # let's create some folders
    sudo -i -u "${username}" -H bash -c "mkdir -p /home/${username}/Downloads"
    sudo -i -u "${username}" -H bash -c "mkdir -p /home/${username}/_TEMP"

    # bring in the custom scripts
    sudo cp -v extras/shrinkpdf /home/"${username}"/bin/
    # sudo wget https://github.com/mozilla/geckodriver/releases/download/v0.29.1/geckodriver-v0.29.1-linux64.tar.gz -O /home/"${username}"/bin/geckodriver-v0.29.1-linux64.tar.gz
    # sudo tar -xvf /home/"${username}"/bin/geckodriver-v0.29.1-linux64.tar.gz -C /home/"${username}"/bin/
    # sudo rm -v /home/"${username}"/bin/geckodriver-v0.29.1-linux64.tar.gz

    sudo chown -R "${username}":"${username}" /home/"${username}"/bin/
}

function installExtraPackages() {
    sudo apt-get install wkhtmltopdf -y
    # sudo apt install default-jre -y
    sudo apt install openjdk-8-jdk -y

    # Hetzner's Ubuntu image doesn't seem to have snapd installed by default
    # shellcheck disable=SC2046
    if [ $(dpkg-query -W -f='${Status}' snapd 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        sudo apt install snapd -y
        sudo snap install core
        sudo snap refresh core
    fi

    # pdftk
    sudo snap install pdftk

    # ffmpeg, youtube-dl and more
    sudo apt install ffmpeg -y
    sudo apt install python3-scour -y
    sudo apt install libreoffice-common aspell hunspell -y
    sudo apt install jq shellcheck -y
    sudo apt install inkscape -y
    sudo apt install autoconf automake autotools-dev -y
    sudo apt install ocrmypdf xvfb rdiff-backup rclone apt-clone -y
    sudo apt install plocate pngquant pandoc sqlite3 poppler-utils ncdu libtool dos2unix -y
    
    # https://github.com/travis-ci/travis.rb
    gem install travis --no-document

    # https://github.com/athityakumar/colorls
    gem install colorls

    # https://github.com/Schniz/fnm/
    sudo -i -u "${username}" -H bash -c "curl -fsSL https://fnm.vercel.app/install | bash"

    if [[ $TEXLIVE ]]; then
        # install texlive-full
        sudo apt install texlive-full -y  # this may take a while
    fi

}


systemUpdate
main
