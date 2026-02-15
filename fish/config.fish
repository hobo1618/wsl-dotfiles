if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Disable greeting
set fish_greeting "Ask students about SAT products purchased
***
Приве́т, я Ви́лл. Я репети́тор по матема́тике и англи́йскому языку́.
Мы с Таней также ведём ютуб-канал, где делимся советами по математике, грамматике и чтению.
У меня есть дочь Мира, ей пять лет.
Она учится во французской школе здесь, в Барселоне.
***
Я принимаю душ.
I am taking shower.

Я обедаю.
I am eating lunch.

Я пью кофе.
I am drinking coffee.

Я чищу зубы.
I am cleaning teeth.

Я играю с дочерью.
I am playing with (my) daughter.

Я работаю.
I am working.

Я голоден.
I am hungry.

"

# Shell aliases
alias c="clear"
alias e="exit"
alias vim="nvim"
alias ls="eza"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias notes="cd ~/Documents/obsidian/"
alias courses="cd ~/Documents/business/askerra/content/courses/"
alias projects="cd ~/Documents/business/askerra/content/projects/"
alias worksheets="cd ~/Documents/business/askerra/content/worksheets/"
alias webinars="cd ~/Documents/business/askerra/content/webinars/"
alias dotfiles="cd ~/dotfiles"
alias nvimconfig="cd ~/nvim"
alias qb="cd ~/Documents/business/askerra/content/bank/"
alias students="cd ~/Documents/business/askerra/private-students/"
alias assets="cd ~/Documents/business/askerra/content/assets/"
alias excalidraw="/opt/homebrew/bin/excalidraw"



# Custom key bindings
function fish_user_key_bindings
    fish_default_key_bindings
    bind \cn history-search-forward
    bind \cp history-search-backward
end

starship init fish | source

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# Created by `pipx` on 2025-07-31 09:29:44
set PATH $PATH /home/hobo/.local/bin
direnv hook fish | source

function llm-list
    set db_path "$LLM_USER_PATH/logs.db"
    if not test -f $db_path
        set db_path "$HOME/.config/io.datasette.llm/logs.db"
    end

    set selection (sqlite3 $db_path "SELECT id || ' | ' || ifnull(name, '[no name]') || ' | ' || model FROM conversations ORDER BY rowid DESC;" | fzf)

    if test -n "$selection"
        set cid (string split '|' $selection)[1]
        llm chat --cid (string trim $cid)
    end
end

function llm-rename
    set db_path "$LLM_USER_PATH/logs.db"
    if not test -f $db_path
        set db_path "$HOME/.config/io.datasette.llm/logs.db"
    end

    set selection (sqlite3 $db_path "SELECT id || ' | ' || ifnull(name, '[no name]') || ' | ' || model FROM conversations ORDER BY rowid DESC;" | fzf)

    if test -z "$selection"
        echo "No conversation selected."
        return 1
    end

    set cid (string trim (string split '|' $selection)[1])

    echo -n "New title: "
    read -l new_title

    if test -z "$new_title"
        echo "No title entered."
        return 1
    end

    # Escape single quotes by replacing ' with ''
    set escaped_title (string replace -a "'" "''" -- $new_title)

    set query "UPDATE conversations SET name = '$escaped_title' WHERE id = '$cid';"
    sqlite3 $db_path "$query"

    echo "✅ Renamed conversation $cid to: $new_title"
end

function llm-save
    set db_path "$LLM_USER_PATH/logs.db"
    if not test -f $db_path
        set db_path "$HOME/.config/io.datasette.llm/logs.db"
    end

    set selection (sqlite3 $db_path "SELECT id || ' | ' || ifnull(name, '[no name]') || ' | ' || model FROM conversations ORDER BY rowid DESC;" | fzf)

    if test -z "$selection"
        echo "❌ No conversation selected."
        return 1
    end

    set cid (string trim (string split '|' $selection)[1])
    set title (string trim (string split '|' $selection)[2])
    set name_slug (string replace -a " " "_" -- (string lower $title))
    set outfile "chats/$name_slug.md"

    mkdir -p chats

    echo "💾 Saving chat to $outfile..."

    sqlite3 $db_path "
    SELECT 
      'user: ' || prompt || char(10) || char(10) || 
      'assistant: ' || response || char(10) || char(10)
    FROM responses
    WHERE conversation_id = '$cid'
    ORDER BY rowid;
  " >$outfile

    echo "📚 Embedding $outfile..."
    llm embed -i $outfile

    echo "✅ Saved and embedded: $outfile"
end

set -Ux BANK_DIR /Users/willhobden/Documents/business/askerra/content/bank
# set -Ux ASKERRA_BANK_DIR /Users/will/Documents/askerra/content/bank
# set -g fish_user_paths $ASKERRA_BANK_DIR/bin $fish_user_paths

set -Ux UXO_DIR $HOME/Documents/uxo 
set PATH $PATH $HOME/Documents/uxo/bin

set PATH $PATH /Library/TeX/texbin

# Created by `pipx` on 2025-09-10 04:32:59
set PATH $PATH /Users/will/.local/bin

set -x GPG_TTY (tty)


# Homebrew environment
if test -d /opt/homebrew/bin
    eval (/opt/homebrew/bin/brew shellenv)
end

# nvm support via bass
set -gx NVM_DIR $HOME/.nvm
if test -s /opt/homebrew/opt/nvm/nvm.sh
    bass source /opt/homebrew/opt/nvm/nvm.sh --no-use ';' nvm use default >/dev/null 2>&1
    function nvm
        bass source /opt/homebrew/opt/nvm/nvm.sh --no-use ';' nvm $argv
    end
end
