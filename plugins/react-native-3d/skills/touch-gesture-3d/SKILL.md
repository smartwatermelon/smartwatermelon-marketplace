---
name: touch-gesture-3d
description: Handle touch events and gestures in React Three Fiber native apps. Covers raycasting, object selection, drag interactions, and resolving conflicts with OrbitControls.
---

# Touch & Gesture Handling in React Native 3D

This skill covers the complex topic of handling touch interactions in R3F native apps - one of the most common sources of bugs.

## The Problem

Touch handling in R3F native is tricky because:

1. **Multiple gesture systems compete**: R3F pointer events, react-native-gesture-handler, OrbitControls
2. **Event propagation differs** from web R3F
3. **iOS vs Android** handle touch differently
4. **OrbitControls** often captures ALL touch events

## Architecture: Touch Event Flow

```
User Touch
    │
    ▼
┌─────────────────────────────────────┐
│ React Native Gesture System         │
│ (react-native-gesture-handler)      │
└─────────────────┬───────────────────┘
                  │
    ┌─────────────┴─────────────┐
    │                           │
    ▼                           ▼
┌─────────────┐         ┌─────────────────┐
│ R3F Canvas  │         │ Other RN Views  │
│ Pointer     │         │                 │
│ Events      │         │                 │
└──────┬──────┘         └─────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Three.js Raycaster                  │
│ (determines which object was hit)   │
└─────────────────┬───────────────────┘
                  │
    ┌─────────────┴─────────────┐
    │                           │
    ▼                           ▼
┌─────────────┐         ┌─────────────────┐
│ Object      │         │ OrbitControls   │
│ Handlers    │         │ (if enabled)    │
│ onPointer*  │         │                 │
└─────────────┘         └─────────────────┘
```

## Solution 1: Basic Object Selection

For simple tap-to-select without drag:

```tsx
import { Canvas } from '@react-three/fiber/native';
import { ThreeEvent } from '@react-three/fiber';

function SelectableNode({
  position,
  isSelected,
  onSelect
}: {
  position: [number, number, number];
  isSelected: boolean;
  onSelect: () => void;
}) {
  return (
    <mesh
      position={position}
      onPointerDown={(e: ThreeEvent<PointerEvent>) => {
        e.stopPropagation(); // CRITICAL: Prevent event bubbling
        onSelect();
      }}
    >
      <sphereGeometry args={[0.5, 16, 16]} />
      <meshStandardMaterial
        color={isSelected ? '#ff6b6b' : '#4ecdc4'}
      />
    </mesh>
  );
}
```

### Key Points

- **Always call `e.stopPropagation()`** to prevent OrbitControls from also handling the event
- Use `onPointerDown` not `onClick` for faster response on mobile
- The `ThreeEvent` type gives you access to intersection data

## Solution 2: Extracting Hit Point for Node Placement

When user taps empty space to place a new node:

```tsx
import { useThree } from '@react-three/fiber/native';
import { useRef } from 'react';
import * as THREE from 'three';

function PlacementPlane({ onPlace }: { onPlace: (point: THREE.Vector3) => void }) {
  const meshRef = useRef<THREE.Mesh>(null);

  return (
    <mesh
      ref={meshRef}
      rotation={[-Math.PI / 2, 0, 0]} // Horizontal plane
      onPointerDown={(e) => {
        e.stopPropagation();
        // e.point is the world-space intersection point
        onPlace(e.point.clone());
      }}
      visible={false} // Invisible but still receives events
    >
      <planeGeometry args={[100, 100]} />
      <meshBasicMaterial transparent opacity={0} />
    </mesh>
  );
}
```

## Solution 3: Drag to Move Objects

This is where it gets complex. You need to:

1. Capture the object on pointerdown
2. Track pointer movement
3. Update object position
4. Release on pointerup

```tsx
import { useThree } from '@react-three/fiber/native';
import { useRef, useState } from 'react';
import * as THREE from 'three';

function DraggableNode({
  initialPosition,
  onPositionChange
}: {
  initialPosition: THREE.Vector3;
  onPositionChange: (pos: THREE.Vector3) => void;
}) {
  const meshRef = useRef<THREE.Mesh>(null);
  const [isDragging, setIsDragging] = useState(false);
  const { camera, raycaster, pointer } = useThree();

  // Plane for drag projection
  const dragPlane = useRef(new THREE.Plane(new THREE.Vector3(0, 0, 1), 0));
  const intersection = useRef(new THREE.Vector3());
  const offset = useRef(new THREE.Vector3());

  const handlePointerDown = (e: ThreeEvent<PointerEvent>) => {
    e.stopPropagation();
    setIsDragging(true);

    // Calculate offset from object center to click point
    if (meshRef.current) {
      offset.current.copy(e.point).sub(meshRef.current.position);

      // Orient drag plane to face camera
      dragPlane.current.setFromNormalAndCoplanarPoint(
        camera.getWorldDirection(new THREE.Vector3()),
        e.point
      );
    }

    // Capture pointer for tracking outside mesh bounds
    (e.target as Element).setPointerCapture(e.pointerId);
  };

  const handlePointerMove = (e: ThreeEvent<PointerEvent>) => {
    if (!isDragging || !meshRef.current) return;
    e.stopPropagation();

    // Cast ray from camera through pointer
    raycaster.setFromCamera(pointer, camera);

    // Find intersection with drag plane
    if (raycaster.ray.intersectPlane(dragPlane.current, intersection.current)) {
      const newPos = intersection.current.sub(offset.current);
      meshRef.current.position.copy(newPos);
      onPositionChange(newPos.clone());
    }
  };

  const handlePointerUp = (e: ThreeEvent<PointerEvent>) => {
    setIsDragging(false);
    (e.target as Element).releasePointerCapture(e.pointerId);
  };

  return (
    <mesh
      ref={meshRef}
      position={initialPosition}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
    >
      <sphereGeometry args={[0.5, 16, 16]} />
      <meshStandardMaterial color={isDragging ? '#ff0000' : '#00ff00'} />
    </mesh>
  );
}
```

## Solution 4: Resolving OrbitControls Conflicts

The biggest pain point: OrbitControls captures all touch events, blocking object interaction.

### Approach A: Disable OrbitControls During Object Interaction

```tsx
import { OrbitControls } from '@react-three/drei/native';
import { useRef } from 'react';
import { OrbitControls as OrbitControlsImpl } from 'three-stdlib';

function Scene() {
  const controlsRef = useRef<OrbitControlsImpl>(null);
  const [interacting, setInteracting] = useState(false);

  return (
    <>
      <OrbitControls
        ref={controlsRef}
        enabled={!interacting}  // Disable when interacting with objects
      />

      <SelectableNode
        onInteractionStart={() => setInteracting(true)}
        onInteractionEnd={() => setInteracting(false)}
      />
    </>
  );
}
```

### Approach B: Custom Gesture-Based Controls

Replace OrbitControls with gesture-handler-based controls for finer control:

```tsx
import { useThree, useFrame } from '@react-three/fiber/native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, { useSharedValue, useAnimatedStyle } from 'react-native-reanimated';
import { View } from 'react-native';

function GestureControlledCanvas({ children }) {
  const rotation = useSharedValue({ x: 0, y: 0 });
  const scale = useSharedValue(1);

  const rotateGesture = Gesture.Pan()
    .onUpdate((e) => {
      rotation.value = {
        x: rotation.value.x + e.velocityY * 0.0001,
        y: rotation.value.y + e.velocityX * 0.0001,
      };
    });

  const pinchGesture = Gesture.Pinch()
    .onUpdate((e) => {
      scale.value = Math.max(0.5, Math.min(3, e.scale));
    });

  const composed = Gesture.Simultaneous(rotateGesture, pinchGesture);

  return (
    <GestureDetector gesture={composed}>
      <View style={{ flex: 1 }}>
        <Canvas>
          <CameraController rotation={rotation} scale={scale} />
          {children}
        </Canvas>
      </View>
    </GestureDetector>
  );
}

function CameraController({ rotation, scale }) {
  const { camera } = useThree();

  useFrame(() => {
    // Apply rotation/scale to camera
    camera.position.x = Math.sin(rotation.value.y) * 10 * scale.value;
    camera.position.z = Math.cos(rotation.value.y) * 10 * scale.value;
    camera.position.y = rotation.value.x * 5;
    camera.lookAt(0, 0, 0);
  });

  return null;
}
```

### Approach C: Separate Touch Zones

Use different gesture areas for orbit vs object interaction:

```tsx
function SplitControlCanvas() {
  return (
    <View style={{ flex: 1 }}>
      {/* 3D Canvas - object interaction only */}
      <Canvas style={{ flex: 1 }}>
        <Scene />
        {/* No OrbitControls here */}
      </Canvas>

      {/* Overlay for camera controls */}
      <View
        style={{ position: 'absolute', bottom: 0, height: 100, width: '100%' }}
        pointerEvents="box-only"
      >
        {/* Gesture handlers for orbit here */}
      </View>
    </View>
  );
}
```

## Solution 5: Custom Raycasting for Non-Mesh Objects

Lines and custom geometries need explicit raycasting:

```tsx
import * as THREE from 'three';

function SelectableLine({ points, onSelect }) {
  const lineRef = useRef<THREE.Line>(null);

  // Lines need a custom raycast threshold
  useEffect(() => {
    if (lineRef.current) {
      // Set threshold for line selection (in world units)
      const material = lineRef.current.material as THREE.LineMaterial;
      lineRef.current.computeLineDistances(); // Required for raycasting
    }
  }, []);

  return (
    <line
      ref={lineRef}
      onPointerDown={(e) => {
        e.stopPropagation();
        onSelect();
      }}
    >
      <bufferGeometry>
        <bufferAttribute
          attach="attributes-position"
          count={points.length / 3}
          array={new Float32Array(points)}
          itemSize={3}
        />
      </bufferGeometry>
      <lineBasicMaterial color="#ffffff" linewidth={2} />
    </line>
  );
}
```

## Debugging Touch Issues

### 1. Add Visual Feedback

```tsx
function DebugTouchPoint() {
  const [lastTouch, setLastTouch] = useState<THREE.Vector3 | null>(null);

  return (
    <>
      <mesh
        onPointerMove={(e) => setLastTouch(e.point.clone())}
      >
        <planeGeometry args={[100, 100]} />
        <meshBasicMaterial visible={false} />
      </mesh>

      {lastTouch && (
        <mesh position={lastTouch}>
          <sphereGeometry args={[0.1]} />
          <meshBasicMaterial color="red" />
        </mesh>
      )}
    </>
  );
}
```

### 2. Log Event Flow

```tsx
function DebugEventFlow({ children }) {
  return (
    <group
      onPointerDown={(e) => console.log('Group pointerdown', e.object.name)}
      onPointerUp={(e) => console.log('Group pointerup', e.object.name)}
      onPointerMissed={() => console.log('Pointer missed - hit background')}
    >
      {children}
    </group>
  );
}
```

### 3. Check if Events Reach Canvas

```tsx
<Canvas
  onPointerDown={() => console.log('Canvas received pointer down')}
  onPointerMissed={() => console.log('Canvas pointer missed')}
>
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Not calling `e.stopPropagation()` | Always stop propagation for handled events |
| Using `onClick` instead of `onPointerDown` | `onPointerDown` is more reliable on mobile |
| OrbitControls with default settings | Set `enabled={false}` when interacting with objects |
| Invisible objects not receiving events | They need a material, even if transparent |
| Lines not selectable | Call `computeLineDistances()` and set threshold |
| Drag not working outside object bounds | Use `setPointerCapture`/`releasePointerCapture` |

## Platform Differences

| Behavior | iOS | Android |
|----------|-----|---------|
| Multi-touch | Works | Works |
| Pointer capture | Supported | Supported |
| Event timing | Slightly delayed | Immediate |
| Simulator testing | Unreliable | More reliable |
