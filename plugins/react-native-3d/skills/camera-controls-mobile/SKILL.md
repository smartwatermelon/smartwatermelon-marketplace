---
name: camera-controls-mobile
description: Implement camera controls for mobile 3D apps - OrbitControls, gesture-based cameras, touch conflicts, camera animation, and bounds/limits.
---

# Camera Controls for Mobile 3D

This skill covers implementing camera controls in React Native 3D apps - orbit, pan, zoom - while avoiding common touch conflict issues.

## The Core Problem

OrbitControls and object interaction compete for touch events. Solutions:

1. **Managed enable/disable** - Turn off orbit during object interaction
2. **Gesture separation** - Different gestures for camera vs objects
3. **Custom controls** - Build camera controls from scratch with gesture-handler
4. **Zone-based** - Different screen areas for different interactions

## Option 1: drei OrbitControls with Enable Toggle

The simplest approach - disable controls during object interaction:

```tsx
import { OrbitControls } from '@react-three/drei/native';
import { OrbitControls as OrbitControlsImpl } from 'three-stdlib';
import { useRef, useState } from 'react';

function SceneWithControls() {
  const controlsRef = useRef<OrbitControlsImpl>(null);
  const [isInteracting, setIsInteracting] = useState(false);

  return (
    <>
      <OrbitControls
        ref={controlsRef}
        enabled={!isInteracting}
        enablePan={true}
        enableZoom={true}
        enableRotate={true}
        minDistance={2}
        maxDistance={20}
        minPolarAngle={0}
        maxPolarAngle={Math.PI / 2} // Prevent going below ground
      />

      <InteractiveObject
        onInteractionStart={() => setIsInteracting(true)}
        onInteractionEnd={() => setIsInteracting(false)}
      />
    </>
  );
}
```

### OrbitControls Props Reference

| Prop | Type | Description |
|------|------|-------------|
| `enabled` | boolean | Master enable/disable |
| `enableRotate` | boolean | Allow orbit rotation |
| `enablePan` | boolean | Allow panning |
| `enableZoom` | boolean | Allow pinch zoom |
| `minDistance` | number | Minimum zoom distance |
| `maxDistance` | number | Maximum zoom distance |
| `minPolarAngle` | number | Minimum vertical angle (0 = top) |
| `maxPolarAngle` | number | Maximum vertical angle (π = bottom) |
| `minAzimuthAngle` | number | Minimum horizontal angle |
| `maxAzimuthAngle` | number | Maximum horizontal angle |
| `dampingFactor` | number | Smoothing (requires enableDamping) |
| `target` | Vector3 | Look-at point |

## Option 2: r3f-native-orbitcontrols Package

A package specifically designed for React Native:

```bash
npm install r3f-native-orbitcontrols
```

```tsx
import { OrbitControls } from 'r3f-native-orbitcontrols';

function Scene() {
  return (
    <>
      <OrbitControls />
      {/* Your scene content */}
    </>
  );
}
```

**Note**: This package may have different behavior than drei's OrbitControls. Test both to see which works better for your use case.

## Option 3: Custom Gesture-Based Camera

For full control over camera behavior and gesture handling:

```tsx
import { useThree, useFrame } from '@react-three/fiber/native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { useSharedValue, withSpring } from 'react-native-reanimated';
import { View } from 'react-native';
import * as THREE from 'three';
import { useRef, useCallback } from 'react';

// Shared values for camera state
interface CameraState {
  theta: SharedValue<number>;      // Horizontal angle
  phi: SharedValue<number>;        // Vertical angle
  radius: SharedValue<number>;     // Distance from target
  targetX: SharedValue<number>;    // Pan X
  targetY: SharedValue<number>;    // Pan Y
  targetZ: SharedValue<number>;    // Pan Z
}

function useCameraState(): CameraState {
  return {
    theta: useSharedValue(0),
    phi: useSharedValue(Math.PI / 4),
    radius: useSharedValue(10),
    targetX: useSharedValue(0),
    targetY: useSharedValue(0),
    targetZ: useSharedValue(0),
  };
}

// Component that updates camera each frame
function CameraController({ state }: { state: CameraState }) {
  const { camera } = useThree();

  useFrame(() => {
    // Spherical to Cartesian conversion
    const x = state.radius.value * Math.sin(state.phi.value) * Math.cos(state.theta.value);
    const y = state.radius.value * Math.cos(state.phi.value);
    const z = state.radius.value * Math.sin(state.phi.value) * Math.sin(state.theta.value);

    camera.position.set(
      x + state.targetX.value,
      y + state.targetY.value,
      z + state.targetZ.value
    );

    camera.lookAt(
      state.targetX.value,
      state.targetY.value,
      state.targetZ.value
    );
  });

  return null;
}

// Gesture wrapper component
function GestureControlledCanvas({ children }: { children: React.ReactNode }) {
  const cameraState = useCameraState();

  // Rotation gesture (single finger drag)
  const rotationGesture = Gesture.Pan()
    .onUpdate((e) => {
      cameraState.theta.value -= e.changeX * 0.01;
      cameraState.phi.value = Math.max(
        0.1,
        Math.min(Math.PI - 0.1, cameraState.phi.value - e.changeY * 0.01)
      );
    });

  // Zoom gesture (pinch)
  const zoomGesture = Gesture.Pinch()
    .onUpdate((e) => {
      const newRadius = cameraState.radius.value / e.scale;
      cameraState.radius.value = Math.max(2, Math.min(50, newRadius));
    });

  // Pan gesture (two finger drag)
  const panGesture = Gesture.Pan()
    .minPointers(2)
    .onUpdate((e) => {
      // Pan in camera-relative space
      const panSpeed = 0.01 * cameraState.radius.value;
      cameraState.targetX.value -= e.changeX * panSpeed;
      cameraState.targetY.value += e.changeY * panSpeed;
    });

  // Compose gestures
  const composed = Gesture.Simultaneous(
    rotationGesture,
    Gesture.Simultaneous(zoomGesture, panGesture)
  );

  return (
    <GestureDetector gesture={composed}>
      <View style={{ flex: 1 }}>
        <Canvas>
          <CameraController state={cameraState} />
          {children}
        </Canvas>
      </View>
    </GestureDetector>
  );
}

// Usage
export function App() {
  return (
    <GestureControlledCanvas>
      <ambientLight />
      <mesh>
        <boxGeometry />
        <meshStandardMaterial color="orange" />
      </mesh>
    </GestureControlledCanvas>
  );
}
```

## Option 4: Separate Object and Camera Gestures

Use different gesture types for different actions:

```tsx
function SmartGestureCanvas({ children }) {
  const [mode, setMode] = useState<'camera' | 'object'>('camera');
  const cameraState = useCameraState();

  // Long press to enter object mode
  const longPressGesture = Gesture.LongPress()
    .minDuration(300)
    .onStart(() => setMode('object'))
    .onEnd(() => setMode('camera'));

  // Camera rotation only when in camera mode
  const rotationGesture = Gesture.Pan()
    .enabled(mode === 'camera')
    .onUpdate((e) => {
      // ... rotate camera
    });

  return (
    <GestureDetector gesture={Gesture.Race(longPressGesture, rotationGesture)}>
      <View style={{ flex: 1 }}>
        <Canvas>
          <CameraController state={cameraState} />
          <ObjectLayer enabled={mode === 'object'} />
          {children}
        </Canvas>

        {/* Mode indicator */}
        <View style={styles.modeIndicator}>
          <Text>{mode === 'camera' ? '🎥 Camera' : '✋ Edit'}</Text>
        </View>
      </View>
    </GestureDetector>
  );
}
```

## Camera Animation

Smoothly animate camera to focus on selected objects:

```tsx
import { useSpring } from '@react-spring/three';

function AnimatedCamera({ targetPosition, targetLookAt }) {
  const { camera } = useThree();

  const [springs, api] = useSpring(() => ({
    position: [10, 10, 10],
    lookAt: [0, 0, 0],
    config: { mass: 1, tension: 170, friction: 26 }
  }));

  // Animate to new target
  useEffect(() => {
    api.start({
      position: targetPosition,
      lookAt: targetLookAt
    });
  }, [targetPosition, targetLookAt]);

  useFrame(() => {
    camera.position.set(...springs.position.get());
    camera.lookAt(...springs.lookAt.get());
  });

  return null;
}

// Usage: Focus on selected node
function Scene({ selectedNode }) {
  const targetPos = selectedNode
    ? [
        selectedNode.position.x + 5,
        selectedNode.position.y + 5,
        selectedNode.position.z + 5
      ]
    : [10, 10, 10];

  const targetLookAt = selectedNode
    ? [selectedNode.position.x, selectedNode.position.y, selectedNode.position.z]
    : [0, 0, 0];

  return (
    <>
      <AnimatedCamera targetPosition={targetPos} targetLookAt={targetLookAt} />
      {/* ... */}
    </>
  );
}
```

## Camera Bounds & Constraints

Prevent camera from going where it shouldn't:

```tsx
function BoundedCameraController({ bounds }) {
  const { camera } = useThree();

  useFrame(() => {
    // Clamp position to bounds
    camera.position.x = Math.max(bounds.minX, Math.min(bounds.maxX, camera.position.x));
    camera.position.y = Math.max(bounds.minY, Math.min(bounds.maxY, camera.position.y));
    camera.position.z = Math.max(bounds.minZ, Math.min(bounds.maxZ, camera.position.z));

    // Ensure camera doesn't go below ground
    if (camera.position.y < 0.5) {
      camera.position.y = 0.5;
    }
  });

  return null;
}
```

## Reset Camera

Provide a way to reset to default view:

```tsx
function CameraResetButton({ controlsRef }) {
  const resetCamera = () => {
    if (controlsRef.current) {
      controlsRef.current.reset();
    }
  };

  return (
    <TouchableOpacity style={styles.resetButton} onPress={resetCamera}>
      <Text>Reset View</Text>
    </TouchableOpacity>
  );
}

// Or with animated transition
function useCameraReset() {
  const { camera } = useThree();
  const controlsRef = useRef();

  const reset = useCallback(() => {
    // Animate to default position
    const defaultPos = new THREE.Vector3(10, 10, 10);
    const defaultTarget = new THREE.Vector3(0, 0, 0);

    // Use GSAP, react-spring, or manual animation
    // ...
  }, [camera]);

  return reset;
}
```

## Common Issues & Solutions

### Issue: OrbitControls blocks all touch events

**Solution**: Use `makeDefault={false}` or manage enabled state

```tsx
<OrbitControls makeDefault={false} enabled={!interacting} />
```

### Issue: Camera jumps when starting interaction

**Solution**: Store initial state and use relative changes

```tsx
const panGesture = Gesture.Pan()
  .onStart((e) => {
    // Store starting values
    startTheta.value = theta.value;
    startPhi.value = phi.value;
  })
  .onUpdate((e) => {
    // Use total translation, not change
    theta.value = startTheta.value - e.translationX * 0.01;
    phi.value = startPhi.value - e.translationY * 0.01;
  });
```

### Issue: Zoom feels wrong (too fast/slow)

**Solution**: Use logarithmic zoom with saved base value

```tsx
const savedRadius = useSharedValue(10);

const zoomGesture = Gesture.Pinch()
  .onStart(() => {
    savedRadius.value = radius.value;
  })
  .onUpdate((e) => {
    // Logarithmic zoom feels more natural
    radius.value = savedRadius.value * Math.pow(e.scale, -1);
  });
```

### Issue: Camera goes through objects

**Solution**: Implement collision detection or use minimum distance

```tsx
useFrame(() => {
  const minDistance = 2;
  const distToTarget = camera.position.distanceTo(target);
  if (distToTarget < minDistance) {
    camera.position.normalize().multiplyScalar(minDistance);
  }
});
```

## Recommended Setup for Tensegrity-Style Apps

For structural visualization with node selection:

```tsx
function TensegrityViewer({ structure }) {
  const controlsRef = useRef();
  const [selectedNode, setSelectedNode] = useState(null);
  const [isDragging, setIsDragging] = useState(false);

  return (
    <Canvas>
      {/* Camera controls - disabled during node drag */}
      <OrbitControls
        ref={controlsRef}
        enabled={!isDragging}
        enablePan={true}
        enableZoom={true}
        minDistance={3}
        maxDistance={30}
        maxPolarAngle={Math.PI * 0.9}
      />

      {/* Structure with selectable/draggable nodes */}
      <TensegrityStructure
        structure={structure}
        selectedNode={selectedNode}
        onNodeSelect={setSelectedNode}
        onDragStart={() => setIsDragging(true)}
        onDragEnd={() => setIsDragging(false)}
      />

      {/* Lights */}
      <ambientLight intensity={0.5} />
      <directionalLight position={[10, 10, 10]} intensity={1} />
    </Canvas>
  );
}
```
