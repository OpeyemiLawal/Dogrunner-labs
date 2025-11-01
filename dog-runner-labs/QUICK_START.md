# 🎮 Dog Runner Labs - Quick Start Guide

## ✅ Everything is Ready!

Your game now has:
- ✨ **Professional lighting** (3-point setup with shadows)
- 🌫️ **Atmospheric fog** and post-processing
- 🏃 **Endless procedural levels** with walls and decorations
- 🎥 **Cinematic camera** with smooth follow
- 🐕 **Animated dog character** with swipe controls
- 🚧 **Random obstacles** (barriers, barrels, boxes)
- 🎨 **Visual polish** (glow, SSAO, color grading)

## 🚀 How to Run

1. **Open Godot 4.5**
2. **Load the project**
3. **Press F5** or click the Play button
4. **Enjoy!**

The main scene (`Scene/main.tscn`) is already set as the default.

## 🎮 Controls

### **Desktop Testing**
- **Arrow Up** → Jump
- **Arrow Down** → Slide
- **Arrow Left** → Move left lane
- **Arrow Right** → Move right lane

### **Mobile/Touch (HTML5)**
- **Swipe Up** → Jump
- **Swipe Down** → Slide
- **Swipe Left** → Move left
- **Swipe Right** → Move right

## 🎨 What You'll See

### **Visual Features**
- Dark underground lab atmosphere
- Volumetric fog creating depth
- Walls on both sides of the track
- Random decorations (torches, pillars, banners, candles)
- Dynamic shadows from obstacles
- Glowing torches and candles
- Smooth camera following the dog
- Camera tilting when changing lanes

### **Gameplay**
- Dog running forward automatically
- Infinite procedurally generated level
- Random obstacles to avoid
- 3-lane system
- Smooth animations (run, jump, slide)

## ⚙️ Quick Adjustments

### **Make it Easier**
Open `Scripts/level_spawner.gd`, line 64:
```gdscript
if randf() > 0.5:  # Change from 0.3 to 0.5 (50% obstacles instead of 70%)
```

### **Change Dog Speed**
Open `Scripts/dog.gd`, line 6:
```gdscript
const FORWARD_SPEED = 5.0  # Increase for faster, decrease for slower
```

### **Adjust Camera Distance**
Open `Scripts/camera_controller.gd`, line 4:
```gdscript
const CAMERA_OFFSET = Vector3(0, 4, 10)  # Change last number for distance
```

### **Brighter Scene**
Open `Scripts/world_environment.gd`, line 20:
```gdscript
directional_light.light_energy = 1.5  # Change from 1.2 to 1.5
```

## 📁 Project Structure

```
dog-runner-labs/
├── Assets/
│   ├── Character/
│   │   └── Dog/
│   └── Enviroment/
│       └── gltf/ (KayKit Dungeon Pack)
├── Scene/
│   ├── main.tscn ← Main game scene
│   ├── dog.tscn
│   └── level_spawner.tscn
└── Scripts/
    ├── dog.gd ← Player movement
    ├── level_spawner.gd ← Level generation
    ├── camera_controller.gd ← Camera system
    └── world_environment.gd ← Lighting & atmosphere
```

## 🎯 Next Steps

### **Gameplay**
1. Add collision detection (game over on hit)
2. Add score/distance counter
3. Add $XYZ token collection
4. Add power-ups
5. Increase speed over time

### **Visuals**
1. Add particle effects (dust, sparks)
2. Add UI (score, tokens, health)
3. Add screen shake on collision
4. Add speed lines effect

### **Features**
1. Main menu
2. Game over screen
3. Leaderboard
4. Character selection
5. Sound effects and music

## 🐛 Common Issues

### **Dog falls through floor?**
- Make sure dog has `CharacterBody3D` as root ✅
- Check ground detection in `dog.gd`

### **No obstacles appearing?**
- Check console for asset loading errors
- Verify assets exist in `Assets/Enviroment/gltf/`

### **Scene too dark?**
- Increase light energy in `world_environment.gd`
- Reduce fog density

### **Camera feels weird?**
- Adjust `CAMERA_SMOOTHING` in `camera_controller.gd`
- Try different `CAMERA_OFFSET` values

## 📚 Documentation

- **`WORLD_DESIGN_SETUP.md`** - Detailed visual setup guide
- **`LEVEL_GENERATION_SETUP.md`** - Level system documentation
- **Game Overview** - Original design document (in chat)

## 🎉 You're All Set!

Press **F5** and watch your professional-looking endless runner come to life!

For detailed customization, check the other documentation files.
