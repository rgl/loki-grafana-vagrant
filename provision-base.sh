#!/bin/bash
set -euxo pipefail

# configure apt for not asking interactive questions.
echo 'Defaults env_keep += "DEBIAN_FRONTEND"' >/etc/sudoers.d/env_keep_apt
chmod 440 /etc/sudoers.d/env_keep_apt
export DEBIAN_FRONTEND=noninteractive

# make sure grub can be installed in the current root disk.
# NB these anwsers were obtained (after installing grub-pc) with:
#
#   #sudo debconf-show grub-pc
#   sudo apt-get install debconf-utils
#   # this way you can see the comments:
#   sudo debconf-get-selections
#   # this way you can just see the values needed for debconf-set-selections:
#   sudo debconf-get-selections | grep -E '^grub-pc.+\s+' | sort
debconf-set-selections <<EOF
grub-pc	grub-pc/install_devices_disks_changed	multiselect	/dev/vda
grub-pc	grub-pc/install_devices	multiselect	/dev/vda
EOF

# upgrade the system.
apt-get update
apt-get dist-upgrade -y


#
# install tcpdump for being able to capture network traffic.

apt-get install -y tcpdump


#
# install vim.

apt-get install -y --no-install-recommends vim
cat >/etc/vim/vimrc.local <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
EOF


#
# configure the shell.

cat >/etc/profile.d/login.sh <<'EOF'
[[ "$-" != *i* ]] && return # bail when not running interactively.
export EDITOR=vim
export PAGER=less
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

cat >/etc/inputrc <<'EOF'
set input-meta on
set output-meta on
set show-all-if-ambiguous on
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOD": backward-word
"\eOC": forward-word
EOF

cat >~/.bash_aliases <<'EOF'
EOF

cat >~/.bash_history <<'EOF'
EOF

# configure the vagrant user home.
su vagrant -c bash <<'EOF-VAGRANT'
set -euxo pipefail

install -d -m 750 ~/.ssh
cat /vagrant/tmp/id_rsa.pub /vagrant/tmp/id_rsa.pub >>~/.ssh/authorized_keys

cat >~/.bash_history <<'EOF'
sudo su -l
EOF
EOF-VAGRANT

# provision useful tools.
apt-get install -y jq jo moreutils
apt-get install -y curl
apt-get install -y --no-install-recommends git-core
apt-get install -y make
apt-get install -y unzip

# install yq.
wget -qO- https://github.com/mikefarah/yq/releases/download/v4.9.3/yq_linux_amd64.tar.gz | tar xz
install yq_linux_amd64 /usr/local/bin/yq
rm yq_linux_amd64
