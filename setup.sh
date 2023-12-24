#!/bin/bash

BREWFILE="$PWD/Brewfile"

ask() {
	local prompt default reply

	while true; do
		if [ "${2:-}" = "Y" ]; then
			prompt="Y/n"
			default=Y
		elif [ "${2:-}" = "N" ]; then
			prompt="y/N"
			default=N
		else
			prompt="y/n"
			default=
		fi

		echo ""
		echo -n "[?] $1 [$prompt] "
		read -r reply </dev/tty
		echo ""

		if [ -z "$reply" ]; then
			reply=$default
		fi

		case "$reply" in
		Y* | y*) return 0 ;;
		N* | n*) return 1 ;;
		esac
	done
}

message() {
	printf "\n%s\n" "$1"
}

message_success() {
	message "[✓] $1"
}

message_nochange() {
	message "[-] $1"
}

message_warning() {
	message "[!] $1"
}

message_question() {
	message "[?] $1"
}

message_err() {
	message "[X] $1"
}

err() {
	echo "error: $1" >&2
}

anykey() {
	printf "\nPress any key to continue... "
	read -n 1 -s -r </dev/tty
	printf "Continuing.\n"
	sleep 1
}

message "Please ensure you are connected to the internet and have signed into the App Store before continuing."

anykey

if type xcode-select &>/dev/null &&
	xpath=$(xcode-select --print-path) &&
	test -d "${xpath}" && test -x "${xpath}"; then
	message_nochange "Command Line Tools are already installed."
else
	message "Installing Command Line Tools for Xcode..."
	xcode-select --install
	message_success "Command Line Tools successfully installed. Please restart the script to continue."
	exit 0
fi

if ! [ -x "$(command -v brew)" ]; then
	message "Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	eval $(/opt/homebrew/bin/brew shellenv)
	message_success "Homebrew successfully installed."
else
	message_nochange "Homebrew is already installed."
fi

if [ -f "$BREWFILE" ]; then
	message "Installing packages from Brewfile..."
	brew bundle --no-lock --file=$BREWFILE
	brew cleanup 2>/dev/null
	message_success "Homebrew packages successfully installed."
else
	message_err "Brewfile not found. Unable to install Homebrew packages."
fi

message "Installing Oh My Zsh..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
message_success "Oh My Zsh successfully installed. You will be prompted later to change your default shell."

message "Adding customizations to .zshrc..."

cat <<END >>~/.zshrc
# Load zsh prompt
export TYPEWRITTEN_SYMBOL="●"
autoload -U promptinit; promptinit
prompt typewritten

# Define aliases
alias s="kitty +kitten ssh"
alias wolf="s lazarod1@teach.cs.toronto.edu"
alias ezsh="hx ~/.zshrc && source ~/.zshrc"
alias szsh="source ~/.zshrc"
alias aloe="s daniel@aloe"
END

echo 'eval $(/opt/homebrew/bin/brew shellenv)' >>~/.zshrc

if ask "Would you like to change your login shell to zsh?" Y; then
	chsh -s $(which zsh)
	message_success "Successfully changed default shell to zsh."
fi

message "Done!"

exit 0
