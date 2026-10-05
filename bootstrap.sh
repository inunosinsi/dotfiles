#!/usr/bin/env bash

set -e

# --- 色定義 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- OSの判別 ---
info "OS環境を検出しています..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$ID"
    OS_LIKE="$ID_LIKE"
else
    error "OS情報の取得に失敗しました。/etc/os-release が見つかりません。"
fi

info "検出されたOS: $NAME ($VERSION)"

# --- 1. パッケージのインストール ---
info "パッケージリストを更新し、各種ツールをインストールします..."
sudo apt update

# 全環境共通の必須パッケージリスト
PACKAGES=(
    zsh
    tmux
    fzf
    ripgrep
    fd-find
    sqlite3
    lftp
    stow
    git
    curl
    zoxide
    tree
)

# GUI環境（Desktop）かどうかの判定（Alacritty インストール用）
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] || dpkg -l | grep -q xserver-xorg; then
    info "デスクトップ環境を検出したため、Alacritty もインストール対象に追加します。"
    PACKAGES+=(alacritty)
else
    info "CUI (Headless) 環境のため、Alacritty のインストールはスキップします。"
fi

# パッケージの一括インストール
sudo apt install -y "${PACKAGES[@]}"

# --- 2. fd コマンドのシンボリックリンク作成 ---
# Debian/Ubuntu/Raspberry Pi OS では fd-find のバイナリ名が fdfind になるため、~/.local/bin/fd を作成
mkdir -p "$HOME/.local/bin"
if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
    info "fdfind のシンボリックリンク (~/.local/bin/fd) を作成しました。"
fi

success "ツールのインストールが完了しました。"

# --- 3. dotfiles の Stow 適用 ---
DOTFILES_DIR="$HOME/dotfiles"

# リポジトリが存在しない場合は自動クローン
if [ ! -d "$DOTFILES_DIR" ]; then
    info "dotfiles ディレクトリが存在しないため、Git リポジトリをクローンします..."
    # TODO: ご自身の GitHub リポジトリ URL に変更してください
    GIT_REPO_URL="https://github.com/YOUR_USERNAME/dotfiles.git"
    git clone "$GIT_REPO_URL" "$DOTFILES_DIR"
fi

info "GNU Stow で設定ファイルを展開（シンボリックリンク化）します..."
cd "$DOTFILES_DIR"

# Stow 管理対象のパッケージ一覧（bash を除外）
STOW_PACKAGES=(
    "zsh"
    "tmux"
    "alacritty"
    "fzf"
    "ripgrep"
    "sqlite3"
    "lftp"
    "micro"
)

# 各パッケージを一括再リンク (-R)
for pkg in "${STOW_PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        stow -R "$pkg"
        info "Stow 適用完了: $pkg"
    else
        info "スキップ (ディレクトリ未作成): $pkg"
    fi
done

success "すべての dotfiles 設定を展開しました。"

# --- 4. デフォルトシェルの変更 ---
CURRENT_SHELL=$(basename "$SHELL")
ZSH_PATH=$(which zsh)

if [ "$CURRENT_SHELL" != "zsh" ] && [ -n "$ZSH_PATH" ]; then
    info "デフォルトシェルを zsh に変更します（パスワードが求められる場合があります）..."
    chsh -s "$ZSH_PATH" || sudo chsh -s "$ZSH_PATH" "$USER"
fi

success "すべてのセットアップが完了しました！ ターミナルを再起動（または再ログイン）してください。"
