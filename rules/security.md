# Sicherheitsregeln
## Geschuetzt (via Hook, Read/Write/Edit/Glob/Grep): .env*, secrets/, .ssh/, .aws/, .gnupg/, .git/, .npmrc, .netrc, *.pem, *.key
## Blockiert: curl/wget (deny), rm -rf /|~ (Hook), Push main/master (Hook)
## WebFetch erfordert Bestaetigung (ask-Tier).
