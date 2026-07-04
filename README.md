# BrowserRouter

A tiny macOS menubar-less app that routes URLs between Safari and Chrome
based on the destination: local dev URLs open in Chrome, everything else
opens in Safari.

## Why?

- You use **Safari** as your daily driver (better battery life, Keychain, iCloud tabs)
- You need **Chrome** for local web development (DevTools, extensions, local servers)
- You want both, automatically, with zero config

## How it works

BrowserRouter registers itself as the default handler for `http://` and
`https://` URLs. When you click a link, it inspects the URL and routes it:

| Pattern | Opens in |
|---|---|
| `localhost` | Chrome |
| `127.0.0.1` | Chrome |
| `0.0.0.0` | Chrome |
| `*.test` | Chrome |
| `*.local` | Chrome |
| `*.dev` | Chrome |
| `10.*` | Chrome |
| `192.168.*` | Chrome |
| Everything else | Safari |

## Install

### Quick install

```bash
git clone https://github.com/guillaume-flambard/browser-router.git
cd browser-router
chmod +x install.sh
./install.sh
```

### Manual install

1. Open `BrowserRouter.app` and copy it to your `~/Applications` folder
2. Run once (it registers itself as the default handler)
3. Go to **System Settings > Desktop & Dock > Default web browser**
   and select **BrowserRouter**

## Uninstall

```bash
# Restore Safari as default browser
swift -e '
import Foundation
LSSetDefaultHandlerForURLScheme("http" as CFString, "com.apple.Safari" as CFString)
LSSetDefaultHandlerForURLScheme("https" as CFString, "com.apple.Safari" as CFString)
' 2>/dev/null

# Or just go to System Settings > Desktop & Dock > Default web browser
# and select Safari

# Delete the app
rm -rf ~/Applications/BrowserRouter.app
```

## Requirements

- macOS 13.0+ (Ventura)
- Google Chrome installed
- Safari installed

## License

MIT
