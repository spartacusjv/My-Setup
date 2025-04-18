#!/bin/bash

#Notes 
#all fish alias and functions are in 
# ~/.config/fish/conf.d/*.fish


# Detect OS
if [ -f /etc/os-release ]; then
  source /etc/os-release
  DISTRO=$ID
  echo "Detected OS : $ID"
else
  echo "❌ Cannot detect OS."
  exit 1
fi

# Detect if running inside WSL
if grep -qi microsoft /proc/sys/kernel/osrelease; then
  IS_WSL=true
  echo "📦 Running inside WSL."
else
  IS_WSL=false
  echo "🖥️ Running on native Linux."
fi

# Set timezone
sudo timedatectl set-timezone Asia/Kolkata


# Start sudo keep-alive
sudo -v
while true; do sudo -n true; sleep 60; done 2>/dev/null &
sudo_keepalive_pid=$!

# Install packages
case "$DISTRO" in
  ubuntu|debian)
    touch ~/.hushlogin
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install software-properties-common curl wget git unzip gpg lsb-release ca-certificates -y
    sudo apt autoremove -y
    # Setup GPG key and source for eza
    if [ ! -f /etc/apt/keyrings/gierens.gpg ]; then
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    fi
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null

    #Add Apps
    sudo apt-get install fish eza zoxide -y
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt autoremove -y


    # Add Fastfetch PPA (for Ubuntu) + fallback for all
    if [[ "$DISTRO" == "ubuntu" ]]; then
        sudo add-apt-repository ppa:zhangsongcui3371/fastfetch -y
    fi
    sudo apt-get update -y
    sudo apt-get install fastfetch -y

    #Fastfetch if not found, using GitHub release
    echo "🔍 Checking if Fastfetch is already installed..."
    if command -v fastfetch &>/dev/null; then
    echo "✅ Fastfetch is already installed."
    else
    arch=$(dpkg --print-architecture) #stores architecture type in arch variable
    tmp=$(mktemp -d)
    url="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-$arch_fmt.deb" #arch_fmt means arch formatted like amd64
    curl -fsSL -o "$tmp/fastfetch.deb" "$url"
    sudo apt install "$tmp/fastfetch.deb" -y
    rm -rf "$tmp"
    echo "✅ Fastfetch installed successfully!"
    fi
    ;;
  arch)
  sudo pacman -Sy --noconfirm fish fastfetch eza git curl wget unzip gpg zoxide
    ;;
  *)
    echo "❌ Unsupported distro: $DISTRO"
    exit 1
    ;;
esac

# Install Oh My Fish
if [ ! -d ~/.local/share/omf ]; then
  curl -L https://get.oh-my.fish | fish
  fish -c 'echo 🐟 Oh My Fish installed successfully!'
  fish -c 'set -U fish_greeting ""'
fi

# Setup Fish config
echo "🔧 Setting up modular Fish config..."
# Directories
FISH_DIR="$HOME/.config/fish"
CONF_DIR="$FISH_DIR/conf.d"
FUNC_DIR="$FISH_DIR/functions"
mkdir -p "$CONF_DIR" "$FUNC_DIR"
# Minimal config.fish
cat << 'EOF' > "$FISH_DIR/config.fish"

# Load all configs from conf.d
for file in ~/.config/fish/conf.d/*.fish
    source $file
end
EOF
echo "✅ Created clean config.fish"

# ---- Modular Scripts --START-- ----
# Aliases (eza)
cat << 'EOF' > "$CONF_DIR/aliases.fish"
if command -v eza > /dev/null
    alias ll="eza -l --icons --colour --no-symlinks --no-user --no-permissions"
    alias lla="eza -l --icons --colour --no-symlinks -a --no-user --no-permissions"
    alias ls="eza --icons --colour --no-symlinks --no-user --no-permissions"
end
EOF
echo "✅ Added aliases.fish"
# Starship
cat << 'EOF' > "$CONF_DIR/starship.fish"
if command -v starship > /dev/null
    starship init fish | source
end
EOF
echo "✅ Added starship.fish"
# Fastfetch
cat << 'EOF' > "$CONF_DIR/fastfetch.fish"
# Run fastfetch only on interactive login
if status is-interactive
    and not set -q FASTFETCH_SHOWN
    set -g FASTFETCH_SHOWN 1
    fastfetch
end
EOF
echo "✅ Added fastfetch.fish"
# Zoxide
cat << 'EOF' > "$CONF_DIR/zoxide.fish"
if command -v zoxide > /dev/null
    zoxide init fish | source
end
EOF
echo "✅ Added zoxide.fish"

echo "🎉 Modular Fish setup complete!"

# ---- Modular Scripts --END-- ----

# Install Starship
if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi
mkdir -p ~/.config
starship preset pastel-powerline -o ~/.config/starship.toml

# Install FiraCode Nerd Font
mkdir -p ~/.local/share/fonts
curl -fLo ~/.local/share/fonts/FiraCodeNerdFontMono-Regular.ttf \
  https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Regular/FiraCodeNerdFontMono-Regular.ttf


# Refresh fonts if not in WSL
if [ "$IS_WSL" = false ] && command -v fc-cache &>/dev/null; then
  fc-cache -fv
fi

# Ensure fish is in /etc/shells and set as default
fish_bin=$(command -v fish)
if ! grep -q "$fish_bin" /etc/shells; then
  echo "$fish_bin" | sudo tee -a /etc/shells > /dev/null
fi
sudo chsh -s "$fish_bin" "$USER" || echo "⚠️ Could not set fish as default shell."

kill "$sudo_keepalive_pid"
echo "✅ Setup Complete!"
