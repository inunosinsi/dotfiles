#export FZF_TMUX=1
alias saitodev="ssh -p 42986 saito@153.126.210.76"
alias minano="ssh -p 42424 saito@219.94.242.84"
alias yamarent="ssh -p 42424 saito@160.16.107.45"
alias yamatrip="ssh -p 42424 saito@160.16.116.12"
alias down="cd /home/saito/ダウンロード"
alias open="xdg-open ."
alias rpi="ssh pi@rpi"
alias rpiftp="lftp sftp://rpi"

alias uefi="sudo systemctl reboot --firmware-setup"
alias kotobuki="ssh -i /home/saito/.ssh/id_ecdsa.pem kotobukien@kotobukien.sakura.ne.jp"

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
