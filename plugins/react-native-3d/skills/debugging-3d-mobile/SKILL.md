---
name: debugging-3d-mobile
description: Debug React Native 3D issues - iOS simulator problems, Android differences, performance profiling, memory leaks, blank screens, touch not working, and common pitfalls.
---

# Debugging 3D in React Native

This skill covers diagnosing and fixing common 3D rendering issues in React Native apps.

## Critical Knowledge: iOS Simulator Limitations

**The iOS Simulator has incomplete and unreliable OpenGL-ES support.**

### Symptoms in Simulator

- `EXC_BAD_ACCESS` crashes
- Blank canvas
- Touch events not firing
- Textures not loading
- Shaders failing silently
- Performance drastically worse than device

### The Rule

```
If it works on physical device but fails in simulator → Simulator problem
If it fails on both → Your code problem

ALWAYS test 3D on physical device before extensive debugging.
```

### Quick Device Test Setup

```bash
# Connect physical iOS device, then:
npx expo run:ios --device

# Or for Android:
npx expo run:android --device
```

## Diagnostic Flowchart

```
Is the Canvas rendering anything?
├─ NO (blank/black screen)
│   ├─ Check: Is Canvas in a View with explicit dimensions?
│   ├─ Check: Is camera positioned to see objects?
│   ├─ Check: Is there any light source?
│   ├─ Check: Console errors? (esp. GL errors)
│   └─ Try: Add a simple <mesh> to verify Canvas works
│
└─ YES (something renders)
    │
    ├─ Objects look wrong?
    │   ├─ Check: Camera near/far planes
    │   ├─ Check: Object scale vs camera distance
    │   └─ Check: Material needs light?
    │
    ├─ Touch not working?
    │   ├─ Check: Is OrbitControls capturing events?
    │   ├─ Check: Does object have raycastable geometry?
    │   ├─ Check: Is there a blocking View/component?
    │   └─ Try: Add onPointerMissed to Canvas
    │
    └─ Performance issues?
        ├─ Check: Are you creating objects every render?
        ├─ Check: How many draw calls?
        └─ Check: Texture sizes
```

## Issue: Blank/Black Canvas

### Cause 1: No Dimensions

```tsx
// ❌ WRONG - Canvas has no size
<Canvas>
  <mesh>...</mesh>
</Canvas>

// ✅ CORRECT - Wrap in View with dimensions
<View style={{ flex: 1 }}>
  <Canvas>
    <mesh>...</mesh>
  </Canvas>
</View>

// ✅ ALSO CORRECT - Explicit dimensions
<View style={{ width: 300, height: 400 }}>
  <Canvas>
    <mesh>...</mesh>
  </Canvas>
</View>
```

### Cause 2: Camera Inside or Behind Objects

```tsx
// Default camera is at [0, 0, 0] looking at [0, 0, -1]
// If your objects are at [0, 0, 0], camera is INSIDE them

// ✅ Move camera back
<Canvas camera={{ position: [0, 0, 5] }}>
```

### Cause 3: No Lights for PBR Materials

```tsx
// ❌ meshStandardMaterial requires lights
<mesh>
  <boxGeometry />
  <meshStandardMaterial color="red" />  {/* Will be black without light */}
</mesh>

// ✅ Add lights
<>
  <ambientLight intensity={0.5} />
  <pointLight position={[10, 10, 10]} />
  <mesh>
    <boxGeometry />
    <meshStandardMaterial color="red" />
  </mesh>
</>

// ✅ Or use meshBasicMaterial (no lighting needed)
<mesh>
  <boxGeometry />
  <meshBasicMaterial color="red" />
</mesh>
```

### Cause 4: expo-gl Not Loaded

```tsx
// Check if GL context is available
import { GLView } from 'expo-gl';

function DebugGL() {
  return (
    <GLView
      style={{ flex: 1 }}
      onContextCreate={(gl) => {
        console.log('GL Context created:', gl);
        console.log('GL Version:', gl.getParameter(gl.VERSION));
      }}
    />
  );
}
```

## Issue: Touch Events Not Working

### Debug Step 1: Verify Canvas Receives Events

```tsx
<Canvas
  onPointerDown={() => console.log('Canvas: pointerdown')}
  onPointerUp={() => console.log('Canvas: pointerup')}
  onPointerMissed={() => console.log('Canvas: pointer missed (background)')}
>
```

### Debug Step 2: Verify Object Receives Events

```tsx
<mesh
  onPointerDown={(e) => {
    console.log('Mesh hit!', e.object.name);
    console.log('Hit point:', e.point);
    console.log('Distance:', e.distance);
  }}
>
```

### Debug Step 3: Check for Blockers

```tsx
// Common blocker: OrbitControls with no enable toggle
<OrbitControls />  // May capture ALL events

// Solution: Disable when interacting
<OrbitControls enabled={!isInteracting} />
```

### Debug Step 4: Visualize Raycasting

```tsx
function RaycastDebugger() {
  const { raycaster, camera, pointer, scene } = useThree();

  useFrame(() => {
    raycaster.setFromCamera(pointer, camera);
    const intersects = raycaster.intersectObjects(scene.children, true);

    if (intersects.length > 0) {
      console.log('Would hit:', intersects.map(i => i.object.name || i.object.type));
    }
  });

  return null;
}
```

### Debug Step 5: Check View Hierarchy

```tsx
// ❌ TouchableOpacity overlay blocks Canvas
<View style={{ flex: 1 }}>
  <Canvas>...</Canvas>
  <TouchableOpacity style={StyleSheet.absoluteFill}>  {/* BLOCKS CANVAS */}
    ...
  </TouchableOpacity>
</View>

// ✅ Use pointerEvents="none" for overlays that shouldn't block
<View style={{ flex: 1 }}>
  <Canvas>...</Canvas>
  <View style={StyleSheet.absoluteFill} pointerEvents="none">
    {/* UI overlay */}
  </View>
</View>
```

## Issue: Performance Problems

### Diagnostic: Frame Rate

```tsx
import { useFrame } from '@react-three/fiber/native';

function FPSCounter() {
  const frameCount = useRef(0);
  const lastTime = useRef(performance.now());

  useFrame(() => {
    frameCount.current++;
    const now = performance.now();
    if (now - lastTime.current >= 1000) {
      console.log(`FPS: ${frameCount.current}`);
      frameCount.current = 0;
      lastTime.current = now;
    }
  });

  return null;
}
```

### Diagnostic: Draw Calls

```tsx
function DrawCallCounter() {
  const { gl } = useThree();

  useFrame(() => {
    console.log('Draw calls:', gl.info.render.calls);
    console.log('Triangles:', gl.info.render.triangles);
    console.log('Geometries:', gl.info.memory.geometries);
    console.log('Textures:', gl.info.memory.textures);
  });

  return null;
}
```

### Common Performance Killers

#### 1. Creating Objects Every Render

```tsx
// ❌ BAD - Creates new geometry every render
function BadMesh() {
  return (
    <mesh position={[0, 0, 0]}>
      <boxGeometry args={[1, 1, 1]} />  {/* NEW EVERY RENDER */}
      <meshStandardMaterial color="red" />  {/* NEW EVERY RENDER */}
    </mesh>
  );
}

// ✅ GOOD - Memoize expensive objects
function GoodMesh() {
  const geometry = useMemo(() => new THREE.BoxGeometry(1, 1, 1), []);
  const material = useMemo(() => new THREE.MeshStandardMaterial({ color: 'red' }), []);

  return <mesh geometry={geometry} material={material} />;
}
```

#### 2. Too Many Individual Objects

```tsx
// ❌ BAD - 1000 separate meshes = 1000 draw calls
{nodes.map(node => (
  <mesh key={node.id} position={node.position}>
    <sphereGeometry />
    <meshStandardMaterial />
  </mesh>
))}

// ✅ GOOD - Use instancing
<instancedMesh args={[undefined, undefined, nodes.length]}>
  <sphereGeometry />
  <meshStandardMaterial />
</instancedMesh>
```

#### 3. High-Poly Geometries

```tsx
// ❌ BAD - Unnecessary detail for mobile
<sphereGeometry args={[1, 64, 64]} />  // 8192 triangles

// ✅ GOOD - Appropriate for mobile
<sphereGeometry args={[1, 16, 16]} />  // 512 triangles
```

## Issue: Memory Leaks

### Symptoms

- App slows down over time
- Eventually crashes with memory warning
- Performance degrades after navigating away and back

### Common Causes

#### 1. Not Disposing Geometries/Materials

```tsx
function ProperCleanup() {
  const geometryRef = useRef<THREE.BufferGeometry>();
  const materialRef = useRef<THREE.Material>();

  useEffect(() => {
    geometryRef.current = new THREE.BoxGeometry(1, 1, 1);
    materialRef.current = new THREE.MeshStandardMaterial();

    return () => {
      // CRITICAL: Dispose on unmount
      geometryRef.current?.dispose();
      materialRef.current?.dispose();
    };
  }, []);
}
```

#### 2. Event Listeners Not Removed

```tsx
function ProperEventCleanup() {
  const { gl } = useThree();

  useEffect(() => {
    const handleResize = () => { /* ... */ };
    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
    };
  }, []);
}
```

### Memory Diagnostic

```tsx
function MemoryMonitor() {
  const { gl } = useThree();

  useEffect(() => {
    const interval = setInterval(() => {
      console.log('=== Memory ===');
      console.log('Geometries:', gl.info.memory.geometries);
      console.log('Textures:', gl.info.memory.textures);
    }, 5000);

    return () => clearInterval(interval);
  }, [gl]);

  return null;
}
```

## Platform Differences

| Behavior | iOS | Android |
|----------|-----|---------|
| WebGL Version | ES 2.0/3.0 | ES 2.0/3.0 |
| Max Texture Size | Device-dependent | Device-dependent |
| Touch Latency | ~16ms | ~16ms |
| Simulator 3D | Unreliable | More reliable |
| Shader Precision | highp available | mediump default |

### Android-Specific Issues

```tsx
// Android may need explicit pixel ratio
<Canvas dpr={[1, 2]}>  {/* Limit pixel ratio for performance */}
```

### iOS-Specific Issues

```tsx
// iOS may need explicit onLayout for sizing
<View
  style={{ flex: 1 }}
  onLayout={(e) => {
    const { width, height } = e.nativeEvent.layout;
    console.log('Canvas container size:', width, height);
  }}
>
  <Canvas>...</Canvas>
</View>
```

## Complete Debug Component

Add this to your scene during development:

```tsx
function DebugPanel() {
  const { gl, scene, camera } = useThree();
  const [stats, setStats] = useState({});

  useFrame(() => {
    setStats({
      fps: Math.round(1000 / gl.info.render.frame),
      drawCalls: gl.info.render.calls,
      triangles: gl.info.render.triangles,
      geometries: gl.info.memory.geometries,
      textures: gl.info.memory.textures,
      objects: scene.children.length,
      cameraPos: camera.position.toArray().map(n => n.toFixed(2)),
    });
  });

  return (
    <Html position={[0, 3, 0]}>
      <View style={styles.debugPanel}>
        <Text>FPS: {stats.fps}</Text>
        <Text>Draw Calls: {stats.drawCalls}</Text>
        <Text>Triangles: {stats.triangles}</Text>
        <Text>Geometries: {stats.geometries}</Text>
        <Text>Textures: {stats.textures}</Text>
        <Text>Camera: [{stats.cameraPos?.join(', ')}]</Text>
      </View>
    </Html>
  );
}
```

## Quick Fixes Checklist

| Problem | Quick Fix |
|---------|-----------|
| Blank screen | Add dimensions to parent View |
| Black objects | Add ambient/point light |
| Touch not working | Disable OrbitControls or add stopPropagation |
| Low FPS | Use instancing, reduce geometry complexity |
| Memory growth | Dispose geometries/materials on unmount |
| Simulator crash | Test on physical device |
| Objects invisible | Check camera position and near/far planes |
| Lines too thin | Use TubeGeometry or Line2 (WebGL 1px limit) |
