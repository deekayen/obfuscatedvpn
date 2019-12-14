tell application "iTerm"
  activate
  set myterm to (make new terminal)
  tell myterm
    set mysession to (make new session at the end of sessions)

    set number of columns to 80
    set number of rows to 15
    tell mysession
    exec command "/usr/local/bin/obfsproxy scramblesuit --password QSCOXXUSXELBRT5SS2B54WCEQWSADY5L socks 127.0.0.1:2223"
    end tell
  end tell
end tell

