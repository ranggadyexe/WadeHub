# Wade Hub - UI Library

Wade Hub adalah Roblox UI Library eksklusif bergaya Mac OS yang dirancang dengan fokus pada estetika, kelancaran animasi (smoothness), dan kenyamanan pengguna. 

UI Library ini sangat ringan dan dilengkapi dengan berbagai fitur otomatis untuk mempermudah pembuatan script eksploitasi atau hub.

## ✨ Fitur Utama
- **Mac OS Smooth Animations**: Semua pergerakan UI menggunakan interpolasi Quint/Back Easing yang sangat memuaskan.
- **Built-In Watermark**: Menampilkan Live FPS, Ping, dan Session Uptime secara otomatis di pojok layar.
- **Auto Config System**: Tidak perlu lagi membuat logika penyimpanan! Setiap Toggle, Slider, dan elemen lainnya akan otomatis disimpan (`Auto Save`) dan dimuat ulang (`Auto Load`) jika dikonfigurasi.
- **Searchable Dropdown**: Dropdown dengan fitur pencarian teks, sangat cocok untuk daftar ratusan item (seperti daftar nama pemain di server).
- **Draggable Window**: Jendela UI bisa digeser dengan mulus ke mana saja.
- **Smart Notification System**: Notifikasi gaya Mac OS yang muncul bertumpuk (*stacked*) di sisi layar.

---

## 🚀 Cara Memuat (Booting)
Untuk menggunakan UI Library ini di dalam script buatanmu, gunakan kode `loadstring` berikut:

```lua
local WadeHub = loadstring(game:HttpGet("MASUKKAN_LINK_RAW_GITHUB_WADEHUB.LUA_DISINI"))()

local Window = WadeHub:CreateWindow({
    Name = "My Script Hub",
    OnClose = function()
        print("UI Ditutup!")
    end
})
```

*(Catatan: Pastikan kamu mengganti `MASUKKAN_LINK_RAW...` dengan link URL raw GitHub file `WadeHub.lua` milikmu).*

---

## 📚 Dokumentasi Elemen UI

### 1. Membuat Tab & Bagian (Section)
```lua
local MainTab = Window:CreateTab("General")
MainTab:CreateSection("Settings Dasar")
```

### 2. Tombol (Button)
```lua
MainTab:CreateButton({
    Name = "Klik Saya",
    Callback = function()
        print("Tombol ditekan!")
    end
})
```

### 3. Toggle (Saklar)
Jangan lupa tambahkan `Flag` agar status Toggle bisa disimpan otomatis oleh Config System.
```lua
MainTab:CreateToggle({
    Name = "Auto Farm",
    Flag = "Toggle_AutoFarm", 
    CurrentValue = false,
    Callback = function(state)
        print("Status:", state)
    end
})
```

### 4. Slider
```lua
MainTab:CreateSlider({
    Name = "Kecepatan Lari",
    Flag = "Slider_WalkSpeed",
    Min = 16,
    Max = 100,
    Default = 16,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})
```

### 5. Dropdown (dengan Fitur Pencarian)
```lua
local MyDropdown = MainTab:CreateSearchableDropdown({
    Name = "Pilih Pemain",
    Options = {"Ahmad", "Budi", "Citra"},
    Callback = function(selected)
        print("Memilih:", selected)
    end
})

-- Untuk memperbarui daftar Dropdown:
MyDropdown.Refresh({"Daftar", "Baru", "Disini"})
```

### 6. Dropdown Ganda (Multi-Dropdown)
Bisa memilih lebih dari satu opsi sekaligus.
```lua
MainTab:CreateMultiDropdown({
    Name = "Pilih Senjata",
    Options = {"Pedang", "Pistol", "Rifle", "Granat"},
    CurrentSelected = {"Pedang"},
    Callback = function(selectedList)
        print("Senjata terpilih:", table.concat(selectedList, ", "))
    end
})
```

### 7. TextBox (Input Teks)
```lua
MainTab:CreateTextBox({
    Name = "Masukkan Nama",
    Placeholder = "Ketik disini...",
    ClearOnFocus = false,
    Callback = function(text)
        print("Teks yang dimasukkan:", text)
    end
})
```

### 8. Keybind (Tombol Shortcut)
```lua
MainTab:CreateKeybind({
    Name = "Sembunyikan UI",
    Flag = "Key_HideUI",
    CurrentKey = Enum.KeyCode.RightControl,
    Callback = function(key)
        print("Tombol ditekan:", key)
    end
})
```

### 9. Color Picker
```lua
MainTab:CreateColorPicker({
    Name = "Warna Tema",
    Color = Color3.fromRGB(0, 255, 100),
    Callback = function(color)
        print("Warna diubah:", color)
    end
})
```

### 10. Memunculkan Notifikasi
Kamu bisa memanggil notifikasi dari mana saja menggunakan variabel `Window`.
```lua
Window:Notify({
    Title = "Peringatan",
    Content = "Ini adalah notifikasi percobaan.",
    Duration = 3
})
```

---

## 📄 Lisensi
Library ini dilisensikan di bawah **MIT License**. Kamu bebas untuk menggunakannya dan memodifikasinya!
