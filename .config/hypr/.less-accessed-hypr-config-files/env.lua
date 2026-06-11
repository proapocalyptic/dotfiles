-- env.lua — environment variables (was env.conf)

-- Editor
hl.env("EDITOR", "/home/alex/.local/bin/nvim-open")
hl.env("VISUAL", "/home/alex/.local/bin/nvim-open")

-- Path
hl.env("PATH",
    os.getenv("HOME") .. "/.config/hypr/scripts:" ..
    os.getenv("HOME") .. "/.config/waybar:" ..
    "/home/alex/.local/bin:" .. (os.getenv("PATH") or ""))

-- Cursor
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Qt theming
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT6CT_STYLE", "Adwaita-Dark")

-- Wayland compatibility
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- App-specific (LibreOffice: use GTK4 backend)
hl.env("SAL_USE_VCLPLUGIN", "gtk4")
hl.env("YDOTOOL_SOCKET", os.getenv("XDG_RUNTIME_DIR") .. "/.ydotool_socket")
