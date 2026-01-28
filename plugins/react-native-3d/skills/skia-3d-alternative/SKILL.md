---
name: skia-3d-alternative
description: When and how to use React Native Skia for 2.5D graphics instead of full 3D. Covers Canvas setup, Path drawing, transforms, touch handling, and hybrid approaches.
---

# Skia as an Alternative to Full 3D

This skill covers when React Native Skia is a better choice than React Three Fiber, and how to implement 2.5D graphics with it.

## When to Choose Skia Over R3F

| Scenario | Recommendation |
|----------|----------------|
| True 3D rotation (any axis) | **R3F** |
| Isometric/2.5D view (fixed angle) | **Skia** (simpler) |
| Vector graphics, charts, diagrams | **Skia** |
| Complex touch/gesture interactions | **Skia** (better integration) |
| Performance-critical 2D | **Skia** (GPU-accelerated 2D) |
| Wireframes with fixed camera | **Either** - Skia may be simpler |
| Physics-based 3D simulation | **R3F** |
| iOS Simulator reliability needed | **Skia** (more reliable) |

## Skia Advantages

1. **Touch handling** - Native gesture-handler integration, no raycast complexity
2. **iOS Simulator** - Works reliably (unlike expo-gl)
3. **Performance** - Extremely fast for 2D/2.5D
4. **Simplicity** - No camera, lights, or 3D concepts needed
5. **Path-based** - Perfect for lines, curves, wireframes

## Skia Disadvantages

1. **No true 3D** - Can't rotate objects in 3D space
2. **Manual projection** - You must convert 3D→2D yourself
3. **No depth sorting** - Must manage draw order manually
4. **No lighting** - Flat shading only

## Installation

```bash
npm install @shopify/react-native-skia
```

## Basic Skia Canvas

```tsx
import { Canvas, Path, Skia } from '@shopify/react-native-skia';
import { View, StyleSheet } from 'react-native';

function BasicSkiaScene() {
  // Create a path
  const path = Skia.Path.Make();
  path.moveTo(50, 50);
  path.lineTo(150, 50);
  path.lineTo(150, 150);
  path.lineTo(50, 150);
  path.close();

  return (
    <View style={styles.container}>
      <Canvas style={styles.canvas}>
        <Path
          path={path}
          color="#4a90d9"
          style="stroke"
          strokeWidth={2}
        />
      </Canvas>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  canvas: { flex: 1 },
});
```

## 2.5D Isometric Projection

For tensegrity-style structures with a fixed isometric view:

```tsx
import { Canvas, Path, Circle, Skia, vec } from '@shopify/react-native-skia';
import { useMemo } from 'react';

// Isometric projection constants
const ISO_ANGLE = Math.PI / 6; // 30 degrees
const COS_A = Math.cos(ISO_ANGLE);
const SIN_A = Math.sin(ISO_ANGLE);

// Convert 3D point to 2D isometric
function toIsometric(x: number, y: number, z: number, centerX: number, centerY: number, scale: number) {
  const isoX = (x - z) * COS_A * scale + centerX;
  const isoY = (x + z) * SIN_A * scale - y * scale + centerY;
  return { x: isoX, y: isoY };
}

interface Node3D {
  id: string;
  x: number;
  y: number;
  z: number;
}

interface Connection {
  from: string;
  to: string;
  type: 'rod' | 'cable';
}

function IsometricStructure({
  nodes,
  connections,
  width,
  height,
  scale = 50
}: {
  nodes: Node3D[];
  connections: Connection[];
  width: number;
  height: number;
  scale?: number;
}) {
  const centerX = width / 2;
  const centerY = height / 2;

  // Project all nodes to 2D
  const projectedNodes = useMemo(() => {
    const map = new Map<string, { x: number; y: number }>();
    nodes.forEach(node => {
      map.set(node.id, toIsometric(node.x, node.y, node.z, centerX, centerY, scale));
    });
    return map;
  }, [nodes, centerX, centerY, scale]);

  // Create paths for connections
  const rodPath = useMemo(() => {
    const path = Skia.Path.Make();
    connections
      .filter(c => c.type === 'rod')
      .forEach(conn => {
        const from = projectedNodes.get(conn.from);
        const to = projectedNodes.get(conn.to);
        if (from && to) {
          path.moveTo(from.x, from.y);
          path.lineTo(to.x, to.y);
        }
      });
    return path;
  }, [connections, projectedNodes]);

  const cablePath = useMemo(() => {
    const path = Skia.Path.Make();
    connections
      .filter(c => c.type === 'cable')
      .forEach(conn => {
        const from = projectedNodes.get(conn.from);
        const to = projectedNodes.get(conn.to);
        if (from && to) {
          path.moveTo(from.x, from.y);
          path.lineTo(to.x, to.y);
        }
      });
    return path;
  }, [connections, projectedNodes]);

  return (
    <Canvas style={{ width, height }}>
      {/* Draw cables first (behind) */}
      <Path
        path={cablePath}
        color="#4a90d9"
        style="stroke"
        strokeWidth={1}
      />

      {/* Draw rods */}
      <Path
        path={rodPath}
        color="#666666"
        style="stroke"
        strokeWidth={3}
      />

      {/* Draw nodes on top */}
      {nodes.map(node => {
        const pos = projectedNodes.get(node.id);
        if (!pos) return null;
        return (
          <Circle
            key={node.id}
            cx={pos.x}
            cy={pos.y}
            r={8}
            color="#ffffff"
          />
        );
      })}
    </Canvas>
  );
}
```

## Touch Handling in Skia

Skia integrates cleanly with react-native-gesture-handler:

```tsx
import { Canvas, Circle, useValue } from '@shopify/react-native-skia';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { useSharedValue } from 'react-native-reanimated';

function TouchableNode({ initialX, initialY, radius = 20 }) {
  const x = useSharedValue(initialX);
  const y = useSharedValue(initialY);

  const panGesture = Gesture.Pan()
    .onUpdate((e) => {
      x.value = e.absoluteX;
      y.value = e.absoluteY;
    });

  return (
    <GestureDetector gesture={panGesture}>
      <Canvas style={{ flex: 1 }}>
        <Circle cx={x} cy={y} r={radius} color="#ff6b6b" />
      </Canvas>
    </GestureDetector>
  );
}
```

### Hit Testing for Node Selection

```tsx
import { Canvas, Circle, Skia } from '@shopify/react-native-skia';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { useState, useMemo } from 'react';

interface Node {
  id: string;
  x: number;
  y: number;
}

function SelectableNodes({ nodes, onSelect }: { nodes: Node[]; onSelect: (id: string) => void }) {
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const tapGesture = Gesture.Tap()
    .onEnd((e) => {
      // Find which node was tapped
      const tapX = e.x;
      const tapY = e.y;
      const hitRadius = 25; // Touch target size

      const hitNode = nodes.find(node => {
        const dx = node.x - tapX;
        const dy = node.y - tapY;
        return Math.sqrt(dx * dx + dy * dy) < hitRadius;
      });

      if (hitNode) {
        setSelectedId(hitNode.id);
        onSelect(hitNode.id);
      } else {
        setSelectedId(null);
      }
    });

  return (
    <GestureDetector gesture={tapGesture}>
      <Canvas style={{ flex: 1 }}>
        {nodes.map(node => (
          <Circle
            key={node.id}
            cx={node.x}
            cy={node.y}
            r={15}
            color={selectedId === node.id ? '#ff6b6b' : '#4ecdc4'}
          />
        ))}
      </Canvas>
    </GestureDetector>
  );
}
```

## Zoom and Pan with Skia

```tsx
import { Canvas, Group, Circle, Path } from '@shopify/react-native-skia';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { useSharedValue, useDerivedValue } from 'react-native-reanimated';

function ZoomableCanvas({ children }) {
  const scale = useSharedValue(1);
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);

  const savedScale = useSharedValue(1);
  const savedTranslateX = useSharedValue(0);
  const savedTranslateY = useSharedValue(0);

  const pinchGesture = Gesture.Pinch()
    .onStart(() => {
      savedScale.value = scale.value;
    })
    .onUpdate((e) => {
      scale.value = Math.max(0.5, Math.min(3, savedScale.value * e.scale));
    });

  const panGesture = Gesture.Pan()
    .onStart(() => {
      savedTranslateX.value = translateX.value;
      savedTranslateY.value = translateY.value;
    })
    .onUpdate((e) => {
      translateX.value = savedTranslateX.value + e.translationX;
      translateY.value = savedTranslateY.value + e.translationY;
    });

  const composed = Gesture.Simultaneous(pinchGesture, panGesture);

  // Create transform matrix
  const transform = useDerivedValue(() => [
    { translateX: translateX.value },
    { translateY: translateY.value },
    { scale: scale.value },
  ]);

  return (
    <GestureDetector gesture={composed}>
      <Canvas style={{ flex: 1 }}>
        <Group transform={transform}>
          {children}
        </Group>
      </Canvas>
    </GestureDetector>
  );
}
```

## Animated Skia with Reanimated

```tsx
import { Canvas, Circle, useSharedValueEffect, useValue } from '@shopify/react-native-skia';
import { useSharedValue, withSpring, withRepeat, withTiming } from 'react-native-reanimated';
import { useEffect } from 'react';

function PulsingNode({ x, y }) {
  const radius = useSharedValue(15);

  // Pulse animation
  useEffect(() => {
    radius.value = withRepeat(
      withTiming(25, { duration: 500 }),
      -1,
      true
    );
  }, []);

  // Bridge reanimated value to Skia
  const skiaRadius = useValue(15);
  useSharedValueEffect(() => {
    skiaRadius.current = radius.value;
  }, radius);

  return (
    <Circle cx={x} cy={y} r={skiaRadius} color="#ff6b6b" />
  );
}
```

## Hybrid Approach: Skia + R3F

Use Skia for UI overlays on top of R3F 3D:

```tsx
import { View, StyleSheet } from 'react-native';
import { Canvas as R3FCanvas } from '@react-three/fiber/native';
import { Canvas as SkiaCanvas, Circle, Text } from '@shopify/react-native-skia';

function HybridScene() {
  return (
    <View style={styles.container}>
      {/* 3D layer */}
      <R3FCanvas style={StyleSheet.absoluteFill}>
        <ambientLight />
        <mesh>
          <boxGeometry />
          <meshStandardMaterial color="orange" />
        </mesh>
      </R3FCanvas>

      {/* 2D UI overlay */}
      <SkiaCanvas style={StyleSheet.absoluteFill} pointerEvents="none">
        <Circle cx={50} cy={50} r={20} color="rgba(255,0,0,0.5)" />
        <Text
          x={100}
          y={50}
          text="Score: 100"
          font={null}
          color="white"
        />
      </SkiaCanvas>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
});
```

## Drawing Lines and Curves

```tsx
import { Canvas, Path, Skia } from '@shopify/react-native-skia';

function CurvedCable({ start, end, sag = 20 }) {
  const path = useMemo(() => {
    const p = Skia.Path.Make();
    const midX = (start.x + end.x) / 2;
    const midY = (start.y + end.y) / 2 + sag;

    p.moveTo(start.x, start.y);
    p.quadTo(midX, midY, end.x, end.y);
    return p;
  }, [start, end, sag]);

  return (
    <Path
      path={path}
      color="#4a90d9"
      style="stroke"
      strokeWidth={2}
      strokeCap="round"
    />
  );
}

function DashedLine({ start, end }) {
  const path = useMemo(() => {
    const p = Skia.Path.Make();
    p.moveTo(start.x, start.y);
    p.lineTo(end.x, end.y);
    return p;
  }, [start, end]);

  return (
    <Path
      path={path}
      color="#888888"
      style="stroke"
      strokeWidth={1}
      strokeCap="round"
      // Dash pattern: 5px dash, 5px gap
      start={0}
      end={1}
    >
      {/* Use PathEffect for dashes */}
    </Path>
  );
}
```

## When to Switch from Skia to R3F

Consider switching to R3F if you need:

1. **User-controlled 3D rotation** - Orbit controls, examining from any angle
2. **Perspective depth** - True depth perception, not just isometric
3. **3D physics** - Collision detection in 3D space
4. **Complex lighting** - Shadows, reflections, PBR materials
5. **3D model loading** - GLTF/GLB files

## Migration Path: Skia → R3F

If you start with Skia and need to migrate:

1. **Keep your data structures** - 3D node positions work in both
2. **Replace projection** - Remove manual isometric, let R3F camera handle it
3. **Replace touch handling** - Move from gesture-handler to R3F pointer events
4. **Replace paths** - Convert to Three.js BufferGeometry/Line

```tsx
// Skia version
<Path path={linePath} color="#fff" style="stroke" />

// R3F equivalent
<line>
  <bufferGeometry>
    <bufferAttribute
      attach="attributes-position"
      array={new Float32Array([x1, y1, z1, x2, y2, z2])}
      count={2}
      itemSize={3}
    />
  </bufferGeometry>
  <lineBasicMaterial color="#ffffff" />
</line>
```

## Performance Comparison

| Metric | Skia | R3F |
|--------|------|-----|
| 2D drawing | Faster | Overkill |
| 100 nodes + lines | 60fps | 60fps |
| 1000 nodes + lines | 60fps | ~30fps (without instancing) |
| Touch responsiveness | Excellent | Good (raycast overhead) |
| iOS Simulator | Reliable | Unreliable |
| Memory usage | Lower | Higher |
| Setup complexity | Simple | More complex |
