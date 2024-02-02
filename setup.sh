#!/bin/bash
#
## Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m'

LINESIZE=57
LINE=$(printf '%*s' $LINESIZE "" | tr ' ' '*')


if [[ $EUID -eq 0 ]]; then
    echo ""
    echo -e "${RED}!! This script must NOT be run as root !! ${NC}" 
    echo "" 1>&2
    exit 1
fi

USER=$(whoami)
HOMEDIR="/home/$USER"
INSTALLDIR="$HOME/gdb_quick"
CONFIGDIR="$HOME/.config"
USER_GDBINIT="$HOME/.gdbinit"

if [ -f ~/.bashrc ]; then
  USERRC_FILE="~/.bashrc"
elif [ -f ~/.zshrc ]; then
  USERRC_FILE="~/.bashrc"
else
  echo ""
  echo -e "${RED}!! This script only supports :: .bashrc or .zshrc profiles !! ${NC}" 
  echo "" 1>&2
  exit 1
fi


echo -e "\n${GREEN} Installing Pwndbg + GEF + Peda + Tmux + Ghidra + Radare2${NC}"
echo -e "${GREEN} $LINE ${NC}"
echo -e ""
echo -e "${GREEN} [+] User : ${MAGENTA} $USER ${NC}" 
echo -e "${GREEN} [+] Profile : ${MAGENTA} $USERRC_FILE ${NC}" 
echo -e "${GREEN} [+] Home Dir : ${MAGENTA} $HOMEDIR ${NC}" 
echo -e "${GREEN} [+] Config Dir : ${MAGENTA} $CONFIGDIR ${NC}" 
echo -e "${GREEN} [+] Install Dir : ${MAGENTA} $INSTALLDIR ${NC}" 
echo -e "${GREEN} [+] User .gdbinit : ${MAGENTA} $USER_GDBINIT ${NC}"
echo -e "${GREEN} $LINE ${NC}"

echo -e "${GREEN}[-] Updating APT Sources ${NC}"
sudo apt update

echo -e "${GREEN}[-] Installing GIT / Tmux / Vim / Nvim ${NC}"
sudo apt install git tmux vim neovim apport -y
source ~/$USERRC_FILE

echo -e "${GREEN}[-] Creating Install/Config Dirs ${NC}"

if [ -d $CONFIGDIR ]; then
  echo -e "${GREEN} [✓] Config Dir Exists ${NC}" 
else
  mkdir $CONFIGDIR
  echo -e "${GREEN} [✓] Config Dir Created ${NC}" 
fi

if [ -d $INSTALLDIR ]; then
  echo -e "${GREEN} [✓] Install Dir Exists ${NC}" 
else
  mkdir $INSTALLDIR
  echo -e "${GREEN} [✓] Install Dir Created ${NC}" 
fi


echo -e "${GREEN}[-] Cloning Files${NC}"
cd $INSTALLDIR
git clone https://github.com/jerdna-regeiz/splitmind
git clone https://github.com/apogiatzis/gdb-peda-pwndbg-gef.git
echo -e "${GREEN} [✓] Cloned ${NC}"

echo -e "${GREEN}[-] Installing ${NC}"
cd gdb-peda-pwndbg-gef
./install.sh
cd ../splitmind

cd $HOMEDIR
echo -e "${GREEN}[-] Moving Files ${NC}"
mv ./pwndbg/ ~/gdb_quick/
echo -e "${GREEN} [✓] Moved pwndbg ${NC}"

mv ./gef/ ~/gdb_quick/
echo -e "${GREEN} [✓] Moved gef ${NC}"

mv ./peda/ ~/gdb_quick/
echo -e "${GREEN} [✓] Moved peda ${NC}"

mv ./peda-arm/ ~/gdb_quick/
echo -e "${GREEN} [✓] Moved peda-arm ${NC}"

echo -e "${GREEN}[-] Fixing .gdbinit ${NC}"

echo '''
define init-peda
source ~/gdb_quick/peda/peda.py
end
document init-peda
Initializes the PEDA (Python Exploit Development Assistant for GDB) framework
end

define init-peda-arm
source ~/gdb_quick/peda-arm/peda-arm.py
end
document init-peda-arm
Initializes the PEDA (Python Exploit Development Assistant for GDB) framework for ARM.
end

define init-peda-intel
source ~/gdb_quick/peda-arm/peda-intel.py
end
document init-peda-intel
Initializes the PEDA (Python Exploit Development Assistant for GDB) framework for INTEL.
end

define init-pwndbg
source ~/gdb_quick/pwndbg/gdbinit.py
source ~/gdb_quick/splitmind/gdbinit.py

python
import splitmind
(splitmind.Mind()
  .tell_splitter(show_titles=True)
  .tell_splitter(set_title="Main")
  .right(display="backtrace", size="20%")
  .above(of="main", display="disasm", size="70%")
  .tell_splitter(set_title="Assembly")
  .right(display="stack", size="55%")
  .above(display="legend", size="25")
  .show("regs", on="legend")
  .below(of="backtrace", display="code", size="70%")
  .below(of="code", display="ipython", cmd="ipython", size="30%")
  .above(of="disasm", display="ghidra",  size="40%")

).build(nobanner=True)
end

set disassembly-flavor intel
set context-ghidra always
set context-sections regs disasm code stack backtrace ghidra
set context-clear-screen on
set context-register-changed-marker ->
set context-source-code-lines 40
set context-code-lines 20
set context-stack-lines 20
document init-pwndbg
Initializes PwnDBG
end

define init-gef
source ~/gdb_quick/gef/gef.py
end
document init-gef
Initializes GEF (GDB Enhanced Features)
end
''' > ~/.gdbinit
#cat gdbinit > ~/.gdbinit
echo -e "${GREEN} [✓] Fixed ${NC}"


echo -e "${GREEN}[-] Installing radare2 ${NC}"
cd $INSTALLDIR
git clone https://github.com/radareorg/radare2
radare2/sys/install.sh

echo -e "${GREEN}[-] Updating r2pm ${NC}"
r2pm update

echo -e "${GREEN}[-] Install r2ghidra ${NC}"
r2pm -ci r2ghidra

echo -e "${GREEN}[-] Updating venv pip ${NC}"
cd ./pwndbg
python3.8 -m pip install ipython
/usr/bin/python3.8 -m venv -- ./.venv
./.venv/bin/python -m pip install --upgrade pip

echo -e "${GREEN}[-] Installing pexpect ${NC}"
./.venv/bin/python -m pip install pexpect

echo -e "${GREEN}[-] Installing r2pipe ${NC}"
./.venv/bin/python -m pip install r2pipe

cd $HOMEDIR
CMDLINE=$(printf '%*s' 15 "" | tr ' ' '*')


echo -e "\n${GREEN} Commands ${NC}"
echo -e "${GREEN} $CMDLINE ${NC}"

echo -e "${GREEN} [+] gdb ${NC}" 
echo -e "${GREEN} [+] gdb-gef ${NC}" 
echo -e "${GREEN} [+] gdb-peda ${NC}" 
echo -e "${GREEN} [+] gdb-peda-arm ${NC}"
echo -e "${GREEN} [+] gdb-peda-intel ${NC}" 
echo -e "${GREEN} [+] gdb-pwndbg ${NC}" 

echo -e "\n\n"
echo -e "${GREEN}[✓] DONE : Happy Exploiting ;) ${NC}"

