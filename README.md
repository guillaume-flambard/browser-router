# BrowserRouter

A native macOS menubar app that routes URLs between Safari and Chrome:
local dev URLs open in Chrome, everything else opens in Safari.

## Why?

- **Safari** as daily driver — better battery life, Keychain, iCloud tabs
- **Chrome** for local development — DevTools, extensions, local servers
- Both, automatically, zero config

## Download

[Download latest BrowserRouter.dmg](https://github.com/guillaume-flambard/browser-router/releases)

Or build from source: `git clone` then `./build.sh && ./make-dmg.sh`

## How it works

BrowserRouter lives in your menubar. It registers as the default handler
for `http://` and `https://` URLs and routes based on the destination:

| Pattern | Opens in |
|---|---|
| `localhost`, `127.0.0.1`, `0.0.0.0` | Chrome |
| `*.test`, `*.local`, `*.dev` | Chrome |
| `10.*`, `192.168.*` | Chrome |
| Everything else | Safari |

## Install

1. Open the DMG
2. Drag **BrowserRouter.app** into **Applications**
3. Launch BrowserRouter
4. Click **Set as Default Browser** from the menubar icon

## Requirements

- macOS 13.0+ (Ventura)
- Google Chrome
- Safari

## Build from source

```bash
git clone https://github.com/guillaume-flambard/browser-router.git
cd browser-router
./build.sh        # compiles → build/BrowserRouter.app
./make-dmg.sh     # packages → build/BrowserRouter.dmg
```

## Uninstall

1. Go to **System Settings > Desktop & Dock > Default web browser**
   and select Safari
2. Delete `BrowserRouter.app` from your Applications folder

## License

MIT
