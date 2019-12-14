tell application "iTerm"
  activate
  set myterm to (make new terminal)
  tell myterm
    set mysession to (make new session at the end of sessions)

    set number of columns to 80
    set number of rows to 15
    tell mysession
      exec command "/usr/local/bin/obfsproxy obfs3 socks 127.0.0.1:2222"
    end tell
  end tell
end tell

