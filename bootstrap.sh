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
IS_GUI=false
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] || dpkg -l | grep -q xserver-xorg; then
    IS_GUI=true
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
    GIT_REPO_URL="https://github.com/inunosinsi/dotfiles.git"
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

# --- 4. Raspberry Pi OS ショートカットキーの設定 (Ctrl + Alt + 5 -> Alacritty) ---
if [ "$IS_GUI" = true ]; then
    info "Raspberry Pi OS のショートカットキー設定 (Ctrl+Alt+5 -> Alacritty) を確認・適用します..."

    KEYBIND_BLOCK='    <keybind key="C-A-5">
      <action name="Execute">
        <command>alacritty</command>
      </action>
    </keybind>'

    # (A) Wayland / Labwc 環境の設定 (Raspberry Pi OS Bookworm 以降)
    LABWC_CONF_DIR="$HOME/.config/labwc"
    LABWC_RC="$LABWC_CONF_DIR/rc.xml"

    if [ -d "/etc/xdg/labwc" ] || [ -f "$LABWC_RC" ]; then
        mkdir -p "$LABWC_CONF_DIR"
        if [ ! -f "$LABWC_RC" ]; then
            cp /etc/xdg/labwc/rc.xml "$LABWC_RC"
            info "Labwc のデフォルト設定ファイルを $LABWC_RC にコピーしました。"
        fi

        # 既に設定済みでないか確認して追加
        if ! grep -q "C-A-5" "$LABWC_RC"; then
            # </keyboard> の直前に keybind ブロックを挿入
            sed -i "/<\/keyboard>/i $KEYBIND_BLOCK" "$LABWC_RC"
            info "Labwc (Wayland) に Ctrl+Alt+5 のキーバインドを追加しました。"
        fi

        # 設定のリロード
        if command -v labwc &> /dev/null && [ -n "$WAYLAND_DISPLAY" ]; then
            labwc --reconfigure || true
        fi
    fi

    # (B) X11 / Openbox 環境の設定 (Bullseye 以前 または X11 モード)
    OPENBOX_CONF_DIR="$HOME/.config/openbox"
    OPENBOX_RC="$OPENBOX_CONF_DIR/lxde-pi-rc.xml"

    if [ -f "$OPENBOX_RC" ]; then
        if ! grep -q "C-A-5" "$OPENBOX_RC"; then
            sed -i "/<\/keyboard>/i $KEYBIND_BLOCK" "$OPENBOX_RC"
            info "Openbox (X11) に Ctrl+Alt+5 のキーバインドを追加しました。"
        fi

        # 設定のリロード
        if command -v openbox &> /dev/null && [ -n "$DISPLAY" ]; then
            openbox --reconfigure || true
        fi
    fi
fi

# --- 5. デフォルトシェルの変更 ---
CURRENT_SHELL=$(basename "$SHELL")
ZSH_PATH=$(which zsh)

if [ "$CURRENT_SHELL" != "zsh" ] && [ -n "$ZSH_PATH" ]; then
    info "デフォルトシェルを zsh に変更します（パスワードが求められる場合があります）..."
    chsh -s "$ZSH_PATH" || sudo chsh -s "$ZSH_PATH" "$USER"
fi

success "すべてのセットアップが完了しました！ ターミナルを再起動（または再ログイン）してください。"
