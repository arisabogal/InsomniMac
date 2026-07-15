import { ImageResponse } from "next/og";

export const alt = "InsomniMac — Keep your Mac remotely reachable";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          background: "#090a0b",
          color: "#f4f4ef",
          padding: "72px",
          fontFamily: "sans-serif",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 18, fontSize: 28 }}>
          <div
            style={{
              display: "flex",
              width: 18,
              height: 18,
              borderRadius: 99,
              background: "#b7f34a",
              boxShadow: "0 0 30px #b7f34a",
            }}
          />
          InsomniMac
        </div>
        <div style={{ display: "flex", flexDirection: "column" }}>
          <div style={{ fontSize: 96, letterSpacing: "-6px", lineHeight: 0.95 }}>
            Keep your Mac reachable.
          </div>
          <div style={{ marginTop: 28, fontSize: 30, color: "#92958d" }}>
            So remote agents stay connected when you step away.
          </div>
        </div>
      </div>
    ),
    size,
  );
}
