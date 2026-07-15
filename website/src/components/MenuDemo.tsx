"use client";

import {
  useEffect,
  useRef,
  useState,
  type KeyboardEvent as ReactKeyboardEvent,
  type PointerEvent as ReactPointerEvent,
  type ReactNode,
} from "react";

const playback = [
  0, 0, 0, 0, 0, 0,
  1, 1, 1,
  2, 2, 2,
  3, 3, 3, 3,
  4, 4, 4,
  5, 5, 5, 5,
  6, 6, 6, 6, 6, 6,
  7, 7, 7,
  8, 8,
  9, 9,
  10, 10,
  11, 11, 11,
  12, 12, 12,
  13, 13,
  14, 14, 14,
  15, 15, 15, 15, 15,
];

const dateTimeFormatter = new Intl.DateTimeFormat(undefined, {
  weekday: "short",
  month: "short",
  day: "numeric",
  hour: "numeric",
  minute: "2-digit",
});

function LockIcon() {
  return (
    <svg aria-hidden="true" viewBox="0 0 16 16" fill="currentColor">
      <path d="M4.75 6V4.8a3.25 3.25 0 0 1 6.5 0V6h.35c.77 0 1.4.63 1.4 1.4v5.2c0 .77-.63 1.4-1.4 1.4H4.4A1.4 1.4 0 0 1 3 12.6V7.4C3 6.63 3.63 6 4.4 6h.35Zm1.5 0h3.5V4.8a1.75 1.75 0 1 0-3.5 0V6Z" />
    </svg>
  );
}

function ToggleRow({
  checked,
  children,
  onChange,
}: {
  checked: boolean;
  children: ReactNode;
  onChange: (checked: boolean) => void;
}) {
  return (
    <button
      className="menu-row check"
      type="button"
      role="menuitemcheckbox"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
    >
      <span aria-hidden="true">{checked ? "✓" : ""}</span>
      {children}
    </button>
  );
}

export function MenuDemo() {
  const demoRef = useRef<HTMLDivElement>(null);
  const dragRef = useRef<{ pointerId: number; offsetX: number; offsetY: number } | null>(null);
  const [now, setNow] = useState(() => new Date());
  const [isInView, setIsInView] = useState(false);
  const [isRunning, setIsRunning] = useState(true);
  const [menuOpen, setMenuOpen] = useState(true);
  const [isActive, setIsActive] = useState(true);
  const [opensAtLogin, setOpensAtLogin] = useState(true);
  const [showOverlay, setShowOverlay] = useState(true);
  const [preventsLidSleep, setPreventsLidSleep] = useState(false);
  const [sharesRemoteMode, setSharesRemoteMode] = useState(true);
  const [shortcutIndex, setShortcutIndex] = useState(0);
  const [frame, setFrame] = useState(0);
  const [spritePosition, setSpritePosition] = useState<{ x: number; y: number } | null>(null);
  const [isDragging, setIsDragging] = useState(false);

  const shortcut = shortcutIndex === 0 ? ["⌘", "⇧", "\\"] : ["⌘", "⌥", "\\"];
  const overlayVisible = isRunning && isActive && showOverlay;
  const overlayAnimating = overlayVisible && isInView;
  const dateTime = dateTimeFormatter.format(now);

  useEffect(() => {
    const timer = window.setInterval(() => setNow(new Date()), 1000);
    return () => window.clearInterval(timer);
  }, []);

  useEffect(() => {
    const root = demoRef.current;
    if (!root) return;

    const observer = new IntersectionObserver(([entry]) => setIsInView(entry.isIntersecting), {
      threshold: 0.25,
    });
    observer.observe(root);
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    if (!overlayAnimating) return;
    let tick = 0;
    const timer = window.setInterval(() => {
      setFrame(playback[tick % playback.length]);
      tick += 1;
    }, 100);
    return () => window.clearInterval(timer);
  }, [overlayAnimating]);

  function toggleAwakeLock() {
    setIsActive((active) => !active);
  }

  function handlePointerDown(event: ReactPointerEvent<HTMLDivElement>) {
    const demo = demoRef.current;
    if (!demo) return;

    const spriteRect = event.currentTarget.getBoundingClientRect();
    dragRef.current = {
      pointerId: event.pointerId,
      offsetX: event.clientX - spriteRect.left,
      offsetY: event.clientY - spriteRect.top,
    };
    event.currentTarget.setPointerCapture(event.pointerId);
    setIsDragging(true);
  }

  function handlePointerMove(event: ReactPointerEvent<HTMLDivElement>) {
    const demo = demoRef.current;
    const drag = dragRef.current;
    if (!demo || !drag || drag.pointerId !== event.pointerId) return;

    const bounds = demo.getBoundingClientRect();
    const x = Math.min(Math.max(event.clientX - bounds.left - drag.offsetX, 0), bounds.width - 128);
    const y = Math.min(Math.max(event.clientY - bounds.top - drag.offsetY, 34), bounds.height - 144);
    setSpritePosition({ x, y });
  }

  function handlePointerUp(event: ReactPointerEvent<HTMLDivElement>) {
    if (dragRef.current?.pointerId !== event.pointerId) return;
    dragRef.current = null;
    setIsDragging(false);
  }

  function handleSpriteKeyDown(event: ReactKeyboardEvent<HTMLDivElement>) {
    const demo = demoRef.current;
    if (!demo || !["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"].includes(event.key)) return;

    event.preventDefault();
    const demoBounds = demo.getBoundingClientRect();
    const spriteBounds = event.currentTarget.getBoundingClientRect();
    const currentX = spritePosition?.x ?? spriteBounds.left - demoBounds.left;
    const currentY = spritePosition?.y ?? spriteBounds.top - demoBounds.top;
    const step = event.shiftKey ? 24 : 8;
    const deltaX = event.key === "ArrowLeft" ? -step : event.key === "ArrowRight" ? step : 0;
    const deltaY = event.key === "ArrowUp" ? -step : event.key === "ArrowDown" ? step : 0;

    setSpritePosition({
      x: Math.min(Math.max(currentX + deltaX, 0), demoBounds.width - 128),
      y: Math.min(Math.max(currentY + deltaY, 34), demoBounds.height - 144),
    });
  }

  const column = frame % 4;
  const row = Math.floor(frame / 4);

  return (
    <div className="menu-preview" ref={demoRef} aria-label="Interactive preview of the InsomniMac menu bar app">
      <div className="menubar">
        <div className="menubar-left">
          <span className="apple-mark" aria-hidden="true">●</span>
          <strong>Finder</strong>
          <span>File</span>
          <span>Edit</span>
          <span>View</span>
          <span>Go</span>
          <span>Window</span>
          <span>Help</span>
        </div>
        <div className="menubar-right">
          <span className="system-icon" aria-hidden="true">◖</span>
          {isRunning ? (
            <button
              className={`menubar-app-button${isActive ? " is-active" : ""}`}
              type="button"
              aria-label="Toggle InsomniMac menu"
              aria-expanded={menuOpen}
              onClick={() => setMenuOpen((open) => !open)}
            >
              <LockIcon />
            </button>
          ) : null}
          <time suppressHydrationWarning dateTime={now.toISOString()}>{dateTime}</time>
        </div>
      </div>

      {isRunning && menuOpen ? (
        <div className="status-menu" role="menu" aria-label="InsomniMac controls">
          <div className="menu-status">
            <span className={`live-dot${isActive ? "" : " is-inactive"}`} />
            Awake Lock {isActive ? "Active" : "Inactive"}
          </div>
          <div className="menu-meta">Hotkey: {shortcut.join(" ")}</div>
          <div className="menu-rule" />
          <button className="menu-row" type="button" role="menuitem" onClick={toggleAwakeLock}>
            {isActive ? "Exit" : "Enter"} Awake Lock <span>{shortcut.join("")}</span>
          </button>
          <button
            className="menu-row"
            type="button"
            role="menuitem"
            onClick={() => setShortcutIndex((index) => (index + 1) % 2)}
          >
            Set Shortcut <span>Try it</span>
          </button>
          <ToggleRow checked={opensAtLogin} onChange={setOpensAtLogin}>Open at Login</ToggleRow>
          <ToggleRow checked={showOverlay} onChange={setShowOverlay}>Show Overlay When Active</ToggleRow>
          <ToggleRow checked={preventsLidSleep} onChange={setPreventsLidSleep}>Prevent Sleep When Lid Closes</ToggleRow>
          <ToggleRow checked={sharesRemoteMode} onChange={setSharesRemoteMode}>Share Remote Mode with Agents</ToggleRow>
          <div className="menu-rule" />
          <button
            className="menu-row"
            type="button"
            role="menuitem"
            onClick={() => {
              setIsRunning(false);
              setIsActive(false);
              setMenuOpen(false);
            }}
          >
            Quit InsomniMac
          </button>
        </div>
      ) : null}

      {!isRunning ? (
        <button
          className="demo-relaunch"
          type="button"
          onClick={() => {
            setIsRunning(true);
            setIsActive(true);
            setMenuOpen(true);
          }}
        >
          Relaunch demo
        </button>
      ) : null}

      {overlayVisible ? (
        <div
          className={`awake-sprite${isDragging ? " is-dragging" : ""}`}
          style={spritePosition ? { left: spritePosition.x, top: spritePosition.y } : undefined}
          role="group"
          tabIndex={0}
          aria-label="Draggable caffeinated Mac overlay. Use arrow keys to move it."
          title="Drag the awake Mac anywhere"
          onPointerDown={handlePointerDown}
          onPointerMove={handlePointerMove}
          onPointerUp={handlePointerUp}
          onPointerCancel={handlePointerUp}
          onKeyDown={handleSpriteKeyDown}
        >
          <div
            className="awake-sprite-art"
            style={{ backgroundPosition: `${(column * 100) / 3}% ${(row * 100) / 3}%` }}
          />
          <div className="sprite-shortcut" aria-hidden="true">
            {shortcut.map((part) => <span key={part}>{part}</span>)}
          </div>
        </div>
      ) : null}
    </div>
  );
}
