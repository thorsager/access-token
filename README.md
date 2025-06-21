# access-token
Bash script for getting access-token.

I have had this script laying around for a wile i a [gist](https://gist.github.com/thorsager/cad8f5a00ab6b0b0520173cbfa667a09)
but decided to move int into a repo, to ensure that I get any updates that 
I add along the way gets tracked.

## Install
```bash
mkdir -p "$HOME/.local/bin" \
&& curl https://raw.githubusercontent.com/thorsager/access-token/refs/heads/main/access-token.sh --output "$HOME/.local/bin/access-token.sh" \
&& chmod +x "$HOME/.local/bin/access-token.sh"
```
And ensure that `~/.local/bin` is in your path.

## Get Started
```bash
access-token.sh -d -u "joe-user" -p "random-password" -c "my-client-id" -r "realm" -i https://issuer.domain.tld
```
Note: `access-token.sh` will souce `.env` in CWD and read the following variables:
 - CLIENT_ID
 - CLIENT_SECRET
 - ISSUER_URL
 - USERNAME
 - PASSWORD
 - GRANT_TYPE

## Easy Use with [curl](https://curl.se/) and such
```bash
curl -H "$(access-token.sh -H)" https://site.domain.tld
```

# Known Issues
- No caching of tokens are being done, every call to `access-token.sh` will contact the issuer and retrieve a
  new token.
