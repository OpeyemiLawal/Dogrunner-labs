# 🐕 Dog Runner Labs

A 3D endless runner game featuring animated pixel art dogs with professional visuals.

## ✅ Current Features

- **Dog Movement** - 3-lane runner system
- **Animations** - Run, jump, slide
- **Controls** - Keyboard & swipe support
- **Professional Lighting** - 3-point lighting setup
- **Cinematic Camera** - Smooth follow with tilt
- **Atmospheric Effects** - Fog, glow, SSAO
- **$XYZ Token Collection** - Collect Solana tokens mid-run

## 🎮 Controls

### Desktop
- **↑ / W** → Jump
- **↓ / S** → Slide
- **← / A** → Move left lane
- **→ / D** → Move right lane

### Mobile/Touch
- **Swipe Up** → Jump
- **Swipe Down** → Slide
- **Swipe Left** → Move left
- **Swipe Right** → Move right

## 📁 Project Structure

```
dog-runner-labs/
├── Assets/
│   ├── Character/Dog/          # Dog 3D model & animations
│   └── Enviroment/gltf/        # Environment assets
├── Scene/
│   ├── main.tscn               # Main game scene
│   └── dog.tscn                # Player character
└── Scripts/
    ├── dog.gd                  # Player movement & controls
    ├── camera_controller.gd    # Cinematic camera
    └── world_environment.gd    # Lighting & atmosphere
```

## 🚀 Quick Start

1. Open in **Godot 4.5**
2. Press **F5** to run
3. Use arrow keys or WASD to control the dog

## ⚙️ Configuration

### Dog Speed
Edit `Scripts/dog.gd`:
```gdscript
const FORWARD_SPEED = 5.0  # Change this value
```

### Camera Distance
Edit `Scripts/camera_controller.gd`:
```gdscript
const CAMERA_OFFSET = Vector3(0, 4, 10)  # Adjust last number
```

### Lighting
Edit `Scripts/world_environment.gd`:
```gdscript
directional_light.light_energy = 1.2  # Brightness
```

## 🎨 Visual Features

- Three-point lighting (Key, Fill, Rim)
- Volumetric fog
- Glow/Bloom effects
- SSAO (Ambient Occlusion)
- Dynamic shadows
- Color grading

## 🔜 Next Steps

- Add procedural level generation
- Implement collision detection
- Add collectibles & obstacles
- Create UI system
- Add sound effects
- Integrate Solana blockchain for $XYZ token economy
- Implement wallet connection for deposits/withdrawals

## 🛠️ Technical Details

- **Engine**: Godot 4.5
- **Rendering**: GL Compatibility
- **Target Platform**: HTML5 (Telegram)
- **Assets**: KayKit Dungeon Pack (CC0)

## 📚 Documentation

- **[QUICK_START.md](QUICK_START.md)** - Detailed setup guide
- **[WORLD_DESIGN_SETUP.md](WORLD_DESIGN_SETUP.md)** - Visual customization

---

**Ready to play!** Press F5 and start running! 🚀
