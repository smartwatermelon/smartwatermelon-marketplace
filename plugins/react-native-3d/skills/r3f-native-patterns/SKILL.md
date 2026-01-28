---
name: r3f-native-patterns
description: React Three Fiber native setup, Canvas configuration, scene structure, useFrame, useThree, lights, cameras, and the render loop.
---

# React Three Fiber Native Patterns

This skill covers core R3F patterns specific to React Native/Expo.

## Installation

```bash
npm install three @react-three/fiber @react-three/drei expo-gl
```

For TypeScript:

```bash
npm install -D @types/three
```

## Metro Configuration

**Critical**: Configure Metro to handle 3D asset files.

```js
// metro.config.js
const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Add 3D model extensions
config.resolver.assetExts.push('glb', 'gltf', 'obj', 'mtl', 'hdr');

// Add source extensions for R3F
config.resolver.sourceExts.push('cjs', 'mjs');

module.exports = config;
```

## Basic Canvas Setup

```tsx
import { Canvas } from '@react-three/fiber/native';
import { View, StyleSheet } from 'react-native';

export function Basic3DScene() {
  return (
    <View style={styles.container}>
      <Canvas
        camera={{ position: [0, 2, 5], fov: 75 }}
        gl={{ antialias: true }}
      >
        <Scene />
      </Canvas>
    </View>
  );
}

function Scene() {
  return (
    <>
      {/* Lights */}
      <ambientLight intensity={0.4} />
      <directionalLight position={[5, 5, 5]} intensity={1} />

      {/* Objects */}
      <mesh>
        <boxGeometry args={[1, 1, 1]} />
        <meshStandardMaterial color="orange" />
      </mesh>
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
```

## Canvas Props Reference

```tsx
<Canvas
  // Camera configuration
  camera={{
    position: [0, 0, 5],      // Initial position
    fov: 75,                   // Field of view (perspective)
    near: 0.1,                 // Near clipping plane
    far: 1000,                 // Far clipping plane
    orthographic: false,       // Use orthographic camera
  }}

  // WebGL configuration
  gl={{
    antialias: true,           // Smooth edges
    alpha: true,               // Transparent background
    powerPreference: 'high-performance',
  }}

  // Performance
  dpr={[1, 2]}                 // Pixel ratio range
  frameloop="always"           // 'always' | 'demand' | 'never'

  // Events
  onCreated={(state) => {}}    // Called when canvas initializes
  onPointerMissed={() => {}}   // Click/tap on empty space
/>
```

## The Render Loop: useFrame

`useFrame` runs every frame (~60fps). Use it for animations and continuous updates.

```tsx
import { useFrame } from '@react-three/fiber/native';
import { useRef } from 'react';
import * as THREE from 'three';

function RotatingCube() {
  const meshRef = useRef<THREE.Mesh>(null);

  useFrame((state, delta) => {
    // state: R3F state (camera, scene, gl, etc.)
    // delta: Time since last frame in seconds

    if (meshRef.current) {
      meshRef.current.rotation.x += delta;
      meshRef.current.rotation.y += delta * 0.5;
    }
  });

  return (
    <mesh ref={meshRef}>
      <boxGeometry />
      <meshStandardMaterial color="hotpink" />
    </mesh>
  );
}
```

### useFrame State Object

```tsx
useFrame((state) => {
  state.clock        // THREE.Clock - elapsed time
  state.camera       // Current camera
  state.scene        // THREE.Scene
  state.gl           // WebGL renderer
  state.size         // { width, height } of canvas
  state.pointer      // Normalized pointer position { x, y }
  state.raycaster    // THREE.Raycaster for picking
});
```

### Frame Priority

Control execution order with priority (lower = earlier):

```tsx
// Physics runs first
useFrame((state) => {
  updatePhysics();
}, -1);

// Then rendering updates
useFrame((state) => {
  updateVisuals();
}, 0);

// Finally, post-processing
useFrame((state) => {
  applyEffects();
}, 1);
```

## Accessing Three.js State: useThree

```tsx
import { useThree } from '@react-three/fiber/native';

function CameraInfo() {
  const { camera, gl, scene, size, pointer, raycaster } = useThree();

  console.log('Canvas size:', size.width, size.height);
  console.log('Camera position:', camera.position);

  return null;
}
```

### Subscribing to State Changes

```tsx
function ResponsiveObject() {
  const size = useThree((state) => state.size);

  // Re-renders only when size changes
  return (
    <mesh scale={size.width / 100}>
      <boxGeometry />
      <meshBasicMaterial color="blue" />
    </mesh>
  );
}
```

## Scene Organization

### Group Components Logically

```tsx
function GameScene() {
  return (
    <>
      <Lighting />
      <Environment />
      <Player />
      <Obstacles />
      <UI3D />
    </>
  );
}

function Lighting() {
  return (
    <group name="lighting">
      <ambientLight intensity={0.3} />
      <directionalLight position={[10, 10, 5]} castShadow />
      <pointLight position={[-10, 5, -10]} color="#ff9999" />
    </group>
  );
}

function Environment() {
  return (
    <group name="environment">
      <Ground />
      <Sky />
      <Trees />
    </group>
  );
}
```

### Use Groups for Transform Hierarchies

```tsx
function Robot() {
  const groupRef = useRef<THREE.Group>(null);

  // Moving the group moves all children together
  useFrame((state) => {
    if (groupRef.current) {
      groupRef.current.position.x = Math.sin(state.clock.elapsedTime);
    }
  });

  return (
    <group ref={groupRef}>
      <Body />
      <group position={[0, 1.5, 0]}>
        <Head />
      </group>
      <group position={[-0.5, 0.5, 0]}>
        <Arm side="left" />
      </group>
      <group position={[0.5, 0.5, 0]}>
        <Arm side="right" />
      </group>
    </group>
  );
}
```

## Cameras

### Perspective Camera (Default)

```tsx
<Canvas camera={{
  position: [0, 5, 10],
  fov: 50,           // Field of view in degrees
  near: 0.1,
  far: 1000,
}}>
```

### Orthographic Camera

```tsx
<Canvas
  orthographic
  camera={{
    position: [0, 0, 10],
    zoom: 50,
    near: 0.1,
    far: 1000,
  }}
>
```

### Switching Cameras

```tsx
function CameraSwitcher() {
  const perspCam = useRef<THREE.PerspectiveCamera>(null);
  const orthoCam = useRef<THREE.OrthographicCamera>(null);
  const set = useThree((state) => state.set);
  const [isOrtho, setIsOrtho] = useState(false);

  useEffect(() => {
    if (isOrtho && orthoCam.current) {
      set({ camera: orthoCam.current });
    } else if (!isOrtho && perspCam.current) {
      set({ camera: perspCam.current });
    }
  }, [isOrtho, set]);

  return (
    <>
      <PerspectiveCamera ref={perspCam} makeDefault={!isOrtho} position={[0, 5, 10]} />
      <OrthographicCamera ref={orthoCam} makeDefault={isOrtho} position={[0, 0, 10]} zoom={50} />
    </>
  );
}
```

## Lighting

### Common Light Setup

```tsx
function StandardLighting() {
  return (
    <>
      {/* Base illumination */}
      <ambientLight intensity={0.4} color="#ffffff" />

      {/* Main directional (sun-like) */}
      <directionalLight
        position={[10, 10, 5]}
        intensity={1}
        castShadow
        shadow-mapSize={[1024, 1024]}
      />

      {/* Fill light (soften shadows) */}
      <pointLight position={[-10, 5, -5]} intensity={0.3} color="#aaccff" />

      {/* Rim light (edge definition) */}
      <spotLight position={[0, 10, -10]} intensity={0.5} angle={0.3} />
    </>
  );
}
```

### Light Types

| Light | Use Case | Performance |
|-------|----------|-------------|
| `ambientLight` | Base fill, no shadows | Cheapest |
| `directionalLight` | Sun, parallel rays | Medium |
| `pointLight` | Bulbs, omni-directional | Medium |
| `spotLight` | Focused cone | More expensive |
| `hemisphereLight` | Sky + ground colors | Cheap |

## Materials Quick Reference

```tsx
// No lighting needed
<meshBasicMaterial color="red" />

// Standard PBR (needs lights)
<meshStandardMaterial
  color="red"
  metalness={0.5}
  roughness={0.5}
/>

// Physical PBR (more realistic)
<meshPhysicalMaterial
  color="red"
  metalness={0.8}
  roughness={0.2}
  clearcoat={1}
/>

// Wireframe
<meshBasicMaterial color="white" wireframe />

// Transparent
<meshBasicMaterial color="blue" transparent opacity={0.5} />

// Double-sided
<meshBasicMaterial color="green" side={THREE.DoubleSide} />
```

## Loading Assets

### GLTF/GLB Models

```tsx
import { useGLTF } from '@react-three/drei/native';

function Model({ url }) {
  const { scene } = useGLTF(url);
  return <primitive object={scene} />;
}

// Preload for better UX
useGLTF.preload('/model.glb');
```

### Textures

```tsx
import { useTexture } from '@react-three/drei/native';

function TexturedBox() {
  const texture = useTexture(require('./texture.png'));

  return (
    <mesh>
      <boxGeometry />
      <meshStandardMaterial map={texture} />
    </mesh>
  );
}
```

## Suspense for Loading

```tsx
import { Suspense } from 'react';

function App() {
  return (
    <Canvas>
      <Suspense fallback={<LoadingIndicator />}>
        <HeavyModel />
      </Suspense>
    </Canvas>
  );
}

function LoadingIndicator() {
  return (
    <mesh>
      <sphereGeometry args={[0.5]} />
      <meshBasicMaterial color="gray" wireframe />
    </mesh>
  );
}
```

## Disposing Resources

**Critical for mobile memory management:**

```tsx
function DisposableScene() {
  const geometryRef = useRef<THREE.BufferGeometry>();
  const materialRef = useRef<THREE.Material>();

  useEffect(() => {
    return () => {
      // Clean up on unmount
      geometryRef.current?.dispose();
      materialRef.current?.dispose();
    };
  }, []);

  return (
    <mesh>
      <boxGeometry ref={geometryRef} />
      <meshStandardMaterial ref={materialRef} />
    </mesh>
  );
}
```

## Performance Patterns

### Memoize Expensive Objects

```tsx
function OptimizedMesh({ color }) {
  // Geometry created once
  const geometry = useMemo(() => new THREE.BoxGeometry(1, 1, 1), []);

  // Material recreated only when color changes
  const material = useMemo(
    () => new THREE.MeshStandardMaterial({ color }),
    [color]
  );

  return <mesh geometry={geometry} material={material} />;
}
```

### Conditional Rendering

```tsx
function LODObject({ distance }) {
  if (distance > 100) return null; // Don't render if too far

  return (
    <mesh>
      {distance < 20 ? (
        <sphereGeometry args={[1, 32, 32]} /> // High detail
      ) : (
        <sphereGeometry args={[1, 8, 8]} />   // Low detail
      )}
      <meshStandardMaterial />
    </mesh>
  );
}
```

### Frameloop Control

```tsx
// Only render when needed (for static scenes)
<Canvas frameloop="demand">
  <StaticScene />
</Canvas>

// Inside scene, trigger render when needed:
function StaticScene() {
  const invalidate = useThree((state) => state.invalidate);

  const handleChange = () => {
    // Something changed, request a render
    invalidate();
  };
}
```
