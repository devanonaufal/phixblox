<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:1a1a2e,100:16213e&height=200&section=header&text=PhixBlox&fontSize=80&fontColor=ffffff&fontAlignY=35&desc=Roblox%20Utility%20Hub&descColor=aaaaff&descAlignY=55&animation=fadeIn" width="100%"/>

[![GitHub Stars](https://img.shields.io/github/stars/devanonaufal/phixblox?style=for-the-badge&logo=github&color=1a1a2e&labelColor=0d0d1a)](https://github.com/devanonaufal/phixblox/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/devanonaufal/phixblox?style=for-the-badge&logo=github&color=16213e&labelColor=0d0d1a)](https://github.com/devanonaufal/phixblox/network)
[![Version](https://img.shields.io/badge/version-2.0-blue?style=for-the-badge&color=1a1a2e&labelColor=0d0d1a)](https://github.com/devanonaufal/phixblox)
[![Lua](https://img.shields.io/badge/language-Lua-purple?style=for-the-badge&logo=lua&color=1a1a2e&labelColor=0d0d1a)](https://github.com/devanonaufal/phixblox)

> **A premium Roblox utility hub with Westbound-style UI — featuring ESP, Aimbot, Player Mods, and more.**

</div>

---

> [!WARNING]
> Script ini dibuat untuk tujuan **edukasi dan testing**. Menggunakan script ini melanggar Roblox Terms of Service dan dapat mengakibatkan ban. **Gunakan dengan risiko sendiri.**

---

## ⚡ Quick Start

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/devanonaufal/phixblox/main/PhixBlox.lua"))()
```

> Tekan `Right Shift` untuk toggle UI

---

## 🗂️ Pages & Features

<details>
<summary><b>🎯 Combat</b></summary>

| Feature | Description |
|:--------|:------------|
| **Aimbot** | Smooth camera lock-on ke target terdekat |
| **Wall Check** | Hanya aim ke target yang terlihat |
| **FOV Circle** | Visual radius aimbot di sekitar cursor |
| **Smoothness** | Adjust kecepatan lock-on |
| **Hitbox Expander** | Perbesar hitbox musuh (1–30 studs) |
| **Spinbot** | Anti-aim / spin character |

</details>

<details>
<summary><b>👁️ Visuals</b></summary>

| Feature | Description |
|:--------|:------------|
| **Glow ESP** | Highlight seluruh karakter musuh |
| **Nametags** | Tampilkan nama player |
| **Tracers** | Garis tracer dari bawah layar ke musuh |
| **Visible Color** | Warna ESP saat terlihat (wall check) |
| **Hidden Color** | Warna ESP saat behind wall |

</details>

<details>
<summary><b>🏃 Character</b></summary>

| Feature | Description |
|:--------|:------------|
| **WalkSpeed** | Override kecepatan jalan (16–250) |
| **JumpPower** | Override kekuatan lompat (50–500) |
| **Fly Mode** | Terbang dengan WASD + Space/Shift |
| **Fly Speed** | Atur kecepatan terbang |
| **Noclip** | Melewati dinding |
| **Infinite Jump** | Lompat tanpa batas (Space) |

</details>

<details>
<summary><b>📍 Locations</b></summary>

| Feature | Description |
|:--------|:------------|
| **Spawn** | Teleport ke spawn point |
| **Random Player** | Teleport ke player random |

</details>

<details>
<summary><b>⚙️ Miscellaneous</b></summary>

| Feature | Description |
|:--------|:------------|
| **Full Bright** | Hapus gelap dari map |
| **Camera FOV** | Adjust field of view kamera (70–120) |
| **FPS Cap** | Limit framerate (60–360) |
| **Click Teleport** | Teleport ke titik yang di-klik (T) |
| **Anti AFK** | Cegah kick karena AFK |
| **Anti Kick** | Block kick attempts dari server |
| **Server Hop** | Pindah ke server kosong |
| **Rejoin** | Rejoin server saat ini |

</details>

<details>
<summary><b>🔧 Settings</b></summary>

| Feature | Description |
|:--------|:------------|
| **Save Config** | Simpan settings ke file JSON |
| **Load Config** | Muat settings dari file |
| **Destroy Script** | Bersihkan semua modifikasi & hapus UI |

</details>

---

## ⌨️ Keybinds

| Key | Action |
|:----|:-------|
| `Right Shift` | Toggle UI (show/hide) |
| `Hold RMB` | Activate Aimbot |
| `T` | Click Teleport *(harus diaktifkan dulu)* |
| `WASD` | Fly direction |
| `Space / Left Shift` | Fly up / down |

---

## 📋 Requirements

> [!IMPORTANT]
> Executor Anda harus support fitur berikut agar semua berfungsi:
> - `Drawing` API — untuk ESP Tracers & FOV Circle
> - `writefile` / `readfile` — untuk Config save/load
> - `hookmetamethod` — untuk Anti-Kick
> - `queue_on_teleport` — untuk Auto Reattach
>
> **Supported executors:** Synapse X, KRNL, Fluxus, Solara, Xeno, dll.

---

## 🧹 Uninstall

Pergi ke tab **Settings** → klik **Destroy Script**.

Script akan:
- ✅ Disconnect semua loops & connections
- ✅ Hapus semua Drawing objects (Tracers, FOV, etc.)
- ✅ Restore hitbox musuh ke ukuran asli
- ✅ Reset WalkSpeed, JumpPower, Camera FOV
- ✅ Hapus GUI sepenuhnya

---

<div align="center">

**Made with ❤️ by [devanonaufal](https://github.com/devanonaufal)**

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:16213e,100:1a1a2e&height=100&section=footer" width="100%"/>

</div>
