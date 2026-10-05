# dotfiles

Linux (Ubuntu / Raspberry Pi OS) 環境向けの個人用設定ファイル (dotfiles) です。  
[GNU Stow](https://www.gnu.org/software/stow/) を使用してシンボリックリンクを一括管理・展開しています。

---

## 🛠 管理パッケージ

以下のツール・設定を Stow でパッケージ単位管理しています。

* **`zsh`** (`.zshrc`)
* **`tmux`** (`.tmux.conf`)
* **`alacritty`** (`.config/alacritty/alacritty.toml`)
* **`fzf`** (`.fzf.zsh`)
* **`ripgrep`** (`.ripgreprc`)
* **`sqlite3`** (`.sqliterc`)
* **`lftp`** (`.lftprc`)
* **`micro`** (`.config/micro/settings.json`, `bindings.json` 等)

---

## 🚀 新規環境セットアップ (Setup)

新しい環境 (Ubuntu または Raspberry Pi OS) で以下のコマンドを実行すると、必須ツールのインストールから GNU Stow による設定ファイルのシンボリックリンク展開まで全自動で行われます。

```bash
bash -c "$(curl -fsSL [https://raw.githubusercontent.com/inunosinsi/dotfiles/main/bootstrap.sh](https://raw.githubusercontent.com/inunosinsi/dotfiles/main/bootstrap.sh))"
