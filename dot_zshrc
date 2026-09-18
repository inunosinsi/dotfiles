autoload -U compinit && compinit

PROMPT='%F{green}%n@NUC12%f:%F{yellow}%~%f $ '

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'

# ターミナル起動時に tmux を自動起動（zsh用）
if [[ -z "$TMUX" && "$TERM_PROGRAM" != "vscode" && -o interactive ]]; then
    # 既存のセッションがあればアタッチ、なければ新規作成
    tmux attach-session -t default 2>/dev/null || tmux new-session -s default
fi

alias cfzf='cd $(find -type d | fzf)'
alias mfzf='micro $(fzf --preview "cat {}")'
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

frg() {
  # (上部はそのまま)
  local query="$*"
  if [ -z "$query" ]; then
    echo "検索キーワードを指定してください。 (例: frg target_word)"
    return 1
  fi

  local selection
  selection=$(rg --line-number --no-heading --color=always --smart-case "$query" | \
    fzf --ansi \
        --delimiter : \
        --nth 1,4.. \
        --preview 'bat --color=always --highlight-line {2} {1} 2>/dev/null || head -n 100 {1}' \
        --preview-window 'up:60%:~3')

  # 3. 選択されたら、ファイル名と行番号を抽出してmicroで開く
  if [ -n "$selection" ]; then
    local file
    local line
    file=$(echo "$selection" | cut -d: -f1)
    line=$(echo "$selection" | cut -d: -f2)

    # 修正ポイント: 「+行番号 ファイル名」の形に変える
    micro "+$line" "$file"
  fi
}

#fastfetch

eval "$(zoxide init zsh)"
