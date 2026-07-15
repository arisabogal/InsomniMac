import Image from "next/image";

const githubUrl = "https://github.com/arisabogal/InsomniMac";

function ArrowIcon() {
  return (
    <svg aria-hidden="true" viewBox="0 0 16 16" fill="none">
      <path d="M3 8h10M9 4l4 4-4 4" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

function GitHubIcon() {
  return (
    <svg aria-hidden="true" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 .7a11.5 11.5 0 0 0-3.64 22.4c.58.1.79-.25.79-.56v-2.23c-3.22.7-3.9-1.37-3.9-1.37-.52-1.34-1.28-1.7-1.28-1.7-1.05-.72.08-.7.08-.7 1.16.08 1.77 1.19 1.77 1.19 1.03 1.77 2.7 1.26 3.36.96.1-.75.4-1.26.73-1.55-2.57-.3-5.27-1.29-5.27-5.7 0-1.27.45-2.3 1.19-3.11-.12-.3-.52-1.47.11-3.07 0 0 .97-.31 3.16 1.19a10.98 10.98 0 0 1 5.76 0c2.2-1.5 3.16-1.2 3.16-1.2.63 1.61.23 2.79.11 3.08.74.81 1.19 1.84 1.19 3.1 0 4.43-2.7 5.4-5.28 5.7.42.36.79 1.07.79 2.16v3.2c0 .31.2.67.8.56A11.5 11.5 0 0 0 12 .7Z" />
    </svg>
  );
}

function MenuPreview() {
  return (
    <div className="menu-scene" aria-label="Preview of the InsomniMac menu bar app">
      <div className="orbit orbit-one" />
      <div className="orbit orbit-two" />
      <div className="menubar">
        <span className="apple">●</span>
        <span>Finder</span>
        <span>File</span>
        <div className="menubar-right">
          <span className="active-lock" aria-hidden="true">▣</span>
          <span>Tue Jul 14&nbsp;&nbsp;11:48 PM</span>
        </div>
      </div>
      <div className="status-menu">
        <div className="menu-status">
          <span className="live-dot" />
          Awake Lock Active
        </div>
        <div className="menu-meta">Hotkey: ⌘ ⇧ L</div>
        <div className="menu-rule" />
        <div className="menu-row">Exit Awake Lock <span>⌘⇧L</span></div>
        <div className="menu-row">Set Shortcut</div>
        <div className="menu-row check"><span>✓</span> Open at Login</div>
        <div className="menu-row check"><span>✓</span> Show Overlay When Active</div>
        <div className="menu-row check"><span>✓</span> Share Remote Mode with Agents</div>
      </div>
      <p className="scene-note">Your Mac is staying awake.</p>
    </div>
  );
}

export default function Home() {
  return (
    <main>
      <header className="site-header">
        <a className="wordmark" href="#top" aria-label="InsomniMac home">
          <span className="wordmark-dot" />
          InsomniMac
        </a>
        <nav aria-label="Primary navigation">
          <a href="#features">Features</a>
          <a href={githubUrl} target="_blank" rel="noreferrer">GitHub</a>
          <a className="nav-download" href="/downloads/InsomniMac.zip" download>
            Download
          </a>
        </nav>
      </header>

      <section className="hero" id="top">
        <div className="hero-glow" />
        <div className="hero-copy">
          <p className="eyebrow hero-enter delay-one">Remote access, without the surprise disconnect</p>
          <h1 className="hero-enter delay-two">Keep your Mac reachable.</h1>
          <p className="hero-intro hero-enter delay-three">
            InsomniMac prevents sleep so remote-control agents<br />stay connected when you step away.
          </p>
          <div className="hero-actions hero-enter delay-four">
            <a className="button button-primary" href="/downloads/InsomniMac.zip" download>
              Download for Mac <ArrowIcon />
            </a>
            <a className="button button-secondary" href={githubUrl} target="_blank" rel="noreferrer">
              <GitHubIcon /> View source
            </a>
          </div>
          <p className="compatibility hero-enter delay-four">v1.0 · Intel + Apple silicon · macOS 26.2+</p>
        </div>

        <div className="hero-art hero-enter delay-three">
          <div className="icon-halo" />
          <Image
            className="app-icon"
            src="/insomnimac-icon.png"
            alt="InsomniMac app icon: a cheerful Mac beside a warm cup"
            width={1024}
            height={1024}
            priority
          />
          <div className="awake-badge"><span /> Awake lock active</div>
        </div>

        <a className="scroll-cue" href="#how" aria-label="Scroll to learn how it works">
          <span>See how it stays online</span>
          <span className="scroll-line" />
        </a>
      </section>

      <section className="how" id="how">
        <div className="section-number">01 / HOW IT WORKS</div>
        <div className="how-copy">
          <p className="display-line">Turn on Awake Lock.</p>
          <p className="display-line muted">Step away from your desk.</p>
          <p className="display-line">Your agent stays connected.</p>
        </div>
        <div className="shortcut" aria-label="Default keyboard shortcut Command Shift L">
          <kbd>⌘</kbd><kbd>⇧</kbd><kbd>L</kbd>
        </div>
      </section>

      <section className="product-proof" id="features">
        <div className="proof-copy">
          <div className="section-number">02 / RIGHT WHERE YOU NEED IT</div>
          <h2>Quietly lives<br />in your menu bar.</h2>
          <p>
            See the connection-safe state at a glance, set a shortcut, and let InsomniMac start with your Mac.
          </p>
        </div>
        <MenuPreview />
      </section>

      <section className="feature-list" aria-label="Features">
        <div className="section-number">03 / SMALL, ON PURPOSE</div>
        <div className="feature-row">
          <p className="feature-index">A</p>
          <h3>Persistent remote access</h3>
          <p>Prevent system sleep so remote-control agents can keep reaching the Mac while you are away.</p>
        </div>
        <div className="feature-row">
          <p className="feature-index">B</p>
          <h3>Agent-aware remote mode</h3>
          <p>Tell supported coding agents you are away, so they send screenshots or recordings when useful.</p>
        </div>
        <div className="feature-row">
          <p className="feature-index">C</p>
          <h3>One global shortcut</h3>
          <p>Toggle Awake Lock without breaking focus, from anywhere on your Mac.</p>
        </div>
        <div className="feature-row">
          <p className="feature-index">D</p>
          <h3>Open source</h3>
          <p>Small SwiftUI codebase. MIT licensed. Easy to inspect, fork, and improve.</p>
        </div>
      </section>

      <section className="final-cta">
        <div className="final-orb" />
        <p className="eyebrow">Your remote session should not end because the Mac took a nap</p>
        <h2>Stay away.<br /><em>Stay connected.</em></h2>
        <div className="final-actions">
          <a className="button button-primary" href="/downloads/InsomniMac.zip" download>
            Download InsomniMac <ArrowIcon />
          </a>
          <a className="text-link" href={githubUrl} target="_blank" rel="noreferrer">
            Read the source on GitHub <ArrowIcon />
          </a>
        </div>
      </section>

      <footer>
        <a className="wordmark" href="#top"><span className="wordmark-dot" />InsomniMac</a>
        <p>Free and open source.</p>
        <p>Made for macOS · 2026</p>
      </footer>
    </main>
  );
}
