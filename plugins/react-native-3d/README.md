# React Native 3D Plugin

Expert agent for 3D development in React Native/Expo applications.

## Coverage

- **React Three Fiber** (@react-three/fiber/native)
- **Three.js** geometries, materials, rendering
- **expo-gl** WebGL bridge
- **React Native Skia** for 2.5D alternatives
- **Touch/gesture handling** in 3D contexts
- **Camera controls** for mobile
- **Performance optimization**

## Agent

- `react-native-3d` - Main agent with decision tree and core patterns

## Skills (Loaded on Demand)

| Skill | Purpose |
|-------|---------|
| `r3f-native-patterns` | Canvas setup, useFrame, useThree, scene structure |
| `touch-gesture-3d` | Raycasting, object selection, drag interactions, OrbitControls conflicts |
| `wireframe-rendering` | Lines, BufferGeometry, rods, cables, tensegrity structures |
| `camera-controls-mobile` | OrbitControls, gesture cameras, animation, bounds |
| `skia-3d-alternative` | When/how to use Skia for 2.5D instead of full 3D |
| `debugging-3d-mobile` | iOS simulator issues, performance profiling, common pitfalls |

## Installation

Enable in Claude Code:

```bash
# In your Claude Code settings, enable:
react-native-3d@smartwatermelon-marketplace
```

## Usage

The agent automatically loads when working on React Native 3D code. For specific topics, it will suggest loading the appropriate skill:

```
"For touch handling issues, load skill: touch-gesture-3d"
```

## Ideal For

- Structural visualizations (tensegrity, wireframes, graphs)
- Mobile games with 3D elements
- Product viewers and 3D configurators
- AR experiences
- Data visualization in 3D

## Key Dependencies

```json
{
  "@react-three/fiber": "^9.x",
  "@react-three/drei": "^10.x",
  "three": "^0.160.0+",
  "expo-gl": "^14.x+",
  "@shopify/react-native-skia": "^2.x"
}
```

## License

MIT
