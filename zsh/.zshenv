#export FZF_TMUX=1
alias uefi="sudo systemctl reboot --firmware-setup"

fdcd(){
	local FILEPATH
	FILEPATH=$(find ./ -type d -name "*$1*" | fzf)
	cd $(pwd)${FILEPATH#.}
}

gz() {
    if [ "$#" -ne 1 ]; then
        echo "usage: gz input.jpg output.jpg"
        return 1
    fi
    guetzli --quality 84 "$1" "$1"
}
