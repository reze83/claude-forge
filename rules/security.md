# Sicherheitsregeln
## Geschuetzt (via Hook): .env*, secrets/, .ssh/, .aws/, .gnupg/, .git/, .npmrc, .netrc, *.pem, *.key
## Blockiert: curl/wget (deny), rm -rf /|~ (Hook), Push main/master (Hook)
## WebFetch erfordert Bestaetigung (ask-Tier).
