# InsomniMac

InsomniMac is a small, open-source macOS menu bar utility that keeps your Mac awake so remote-control agents can continue to reach it while you are away.

Use a global keyboard shortcut to toggle Awake Lock, show an optional full-screen overlay, launch at login, and share remote-mode context with supported coding agents.

## Download

Download the latest packaged build from the [InsomniMac website](https://insomnimac.vercel.app). The current universal build supports Intel and Apple silicon Macs running macOS 26.2 or later.

InsomniMac checks the signed [Sparkle appcast](appcast.xml) for updates automatically. You can also choose **Check for Updates…** from the menu bar app at any time. Update archives are verified with an app-specific EdDSA key before installation.

## Development

Open `InsomniMac.xcodeproj` in Xcode to build the native app.

The marketing site lives in `website/` and uses Next.js:

```bash
cd website
npm install
npm run dev
```

## License

[MIT](LICENSE) © Ari Sabogal
