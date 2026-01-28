---
name: wireframe-rendering
description: Render lines, wireframes, rods, cables, and structural visualizations in React Three Fiber. Covers BufferGeometry, LineSegments, TubeGeometry, and dynamic updates.
---

# Wireframe & Line Rendering in React Native 3D

This skill covers rendering lines, wireframes, and structural elements like rods and cables - essential for engineering visualizations and structural simulations.

## Line Types in Three.js

| Type | Use Case | Thickness | Performance |
|------|----------|-----------|-------------|
| `<line>` | Single continuous line | 1px only | Fast |
| `<lineSegments>` | Multiple disconnected segments | 1px only | Fast |
| `Line2` (drei) | Fat lines with variable width | Variable | Slower |
| `<tubeGeometry>` | 3D cylindrical lines | 3D radius | Slowest |
| `<cylinderGeometry>` | Rods (straight segments) | 3D radius | Medium |

## Basic Line Rendering

### Single Line (1px width)

```tsx
import * as THREE from 'three';
import { useMemo } from 'react';

function BasicLine({
  start,
  end,
  color = '#ffffff'
}: {
  start: THREE.Vector3;
  end: THREE.Vector3;
  color?: string;
}) {
  const points = useMemo(() => [start, end], [start, end]);

  return (
    <line>
      <bufferGeometry>
        <bufferAttribute
          attach="attributes-position"
          count={2}
          array={new Float32Array([
            start.x, start.y, start.z,
            end.x, end.y, end.z
          ])}
          itemSize={3}
        />
      </bufferGeometry>
      <lineBasicMaterial color={color} />
    </line>
  );
}
```

### Multiple Line Segments

For rendering many disconnected lines efficiently (e.g., a wireframe structure):

```tsx
function WireframeStructure({
  segments  // Array of [startPoint, endPoint] pairs
}: {
  segments: Array<[THREE.Vector3, THREE.Vector3]>;
}) {
  const geometry = useMemo(() => {
    const positions: number[] = [];

    segments.forEach(([start, end]) => {
      positions.push(start.x, start.y, start.z);
      positions.push(end.x, end.y, end.z);
    });

    const geo = new THREE.BufferGeometry();
    geo.setAttribute(
      'position',
      new THREE.Float32BufferAttribute(positions, 3)
    );
    return geo;
  }, [segments]);

  return (
    <lineSegments geometry={geometry}>
      <lineBasicMaterial color="#00ff00" />
    </lineSegments>
  );
}
```

## Rods (Cylindrical 3D Lines)

For structural rods with actual thickness:

```tsx
function Rod({
  start,
  end,
  radius = 0.05,
  color = '#888888',
  isSelected = false,
  onSelect
}: {
  start: THREE.Vector3;
  end: THREE.Vector3;
  radius?: number;
  color?: string;
  isSelected?: boolean;
  onSelect?: () => void;
}) {
  // Calculate rod properties
  const { position, rotation, length } = useMemo(() => {
    const direction = new THREE.Vector3().subVectors(end, start);
    const length = direction.length();

    // Midpoint for position
    const position = new THREE.Vector3()
      .addVectors(start, end)
      .multiplyScalar(0.5);

    // Rotation to align cylinder with direction
    const up = new THREE.Vector3(0, 1, 0);
    const quaternion = new THREE.Quaternion();
    quaternion.setFromUnitVectors(up, direction.clone().normalize());
    const euler = new THREE.Euler().setFromQuaternion(quaternion);

    return { position, rotation: euler, length };
  }, [start, end]);

  return (
    <mesh
      position={position}
      rotation={rotation}
      onPointerDown={(e) => {
        e.stopPropagation();
        onSelect?.();
      }}
    >
      <cylinderGeometry args={[radius, radius, length, 8]} />
      <meshStandardMaterial
        color={isSelected ? '#ff6b6b' : color}
        metalness={0.3}
        roughness={0.7}
      />
    </mesh>
  );
}
```

## Cables (Flexible Lines)

For cables that may curve or sag:

### Option 1: Straight Cable (Simple)

```tsx
function StraightCable({
  start,
  end,
  color = '#4a90d9',
  thickness = 0.02
}: {
  start: THREE.Vector3;
  end: THREE.Vector3;
  color?: string;
  thickness?: number;
}) {
  const path = useMemo(() => {
    const curve = new THREE.LineCurve3(start, end);
    return curve;
  }, [start, end]);

  return (
    <mesh>
      <tubeGeometry args={[path, 1, thickness, 8, false]} />
      <meshStandardMaterial color={color} />
    </mesh>
  );
}
```

### Option 2: Catenary Cable (Realistic Sag)

```tsx
function CatenaryCable({
  start,
  end,
  sag = 0.5,
  segments = 20,
  color = '#4a90d9',
  thickness = 0.02
}: {
  start: THREE.Vector3;
  end: THREE.Vector3;
  sag?: number;
  segments?: number;
  color?: string;
  thickness?: number;
}) {
  const path = useMemo(() => {
    const points: THREE.Vector3[] = [];
    const midY = (start.y + end.y) / 2 - sag;

    for (let i = 0; i <= segments; i++) {
      const t = i / segments;
      const x = start.x + (end.x - start.x) * t;
      const z = start.z + (end.z - start.z) * t;

      // Parabolic sag
      const sagFactor = 4 * t * (1 - t); // 0 at ends, 1 at middle
      const y = start.y + (end.y - start.y) * t - sag * sagFactor;

      points.push(new THREE.Vector3(x, y, z));
    }

    return new THREE.CatmullRomCurve3(points);
  }, [start, end, sag, segments]);

  return (
    <mesh>
      <tubeGeometry args={[path, segments, thickness, 8, false]} />
      <meshStandardMaterial color={color} />
    </mesh>
  );
}
```

## Nodes (Connection Points)

```tsx
function Node({
  position,
  radius = 0.15,
  color = '#ffffff',
  isSelected = false,
  isAnchored = false,
  onSelect,
  onDragStart,
  onDrag,
  onDragEnd
}: {
  position: THREE.Vector3;
  radius?: number;
  color?: string;
  isSelected?: boolean;
  isAnchored?: boolean;
  onSelect?: () => void;
  onDragStart?: () => void;
  onDrag?: (newPosition: THREE.Vector3) => void;
  onDragEnd?: () => void;
}) {
  const meshRef = useRef<THREE.Mesh>(null);

  // Visual indicator for anchored nodes
  const nodeColor = isAnchored ? '#ff0000' : isSelected ? '#ffff00' : color;

  return (
    <mesh
      ref={meshRef}
      position={position}
      onPointerDown={(e) => {
        e.stopPropagation();
        onSelect?.();
        onDragStart?.();
      }}
    >
      <sphereGeometry args={[radius, 16, 16]} />
      <meshStandardMaterial
        color={nodeColor}
        metalness={0.5}
        roughness={0.5}
      />

      {/* Selection ring */}
      {isSelected && (
        <mesh rotation={[Math.PI / 2, 0, 0]}>
          <torusGeometry args={[radius * 1.5, radius * 0.1, 8, 32]} />
          <meshBasicMaterial color="#ffff00" />
        </mesh>
      )}
    </mesh>
  );
}
```

## Dynamic Geometry Updates

For physics simulations where positions change every frame:

### Method 1: Update BufferGeometry Directly

```tsx
function DynamicWireframe({
  getPositions  // Function that returns current positions
}: {
  getPositions: () => Float32Array;
}) {
  const geometryRef = useRef<THREE.BufferGeometry>(null);

  useFrame(() => {
    if (geometryRef.current) {
      const positions = getPositions();
      const attr = geometryRef.current.getAttribute('position');
      (attr.array as Float32Array).set(positions);
      attr.needsUpdate = true;
    }
  });

  return (
    <lineSegments>
      <bufferGeometry ref={geometryRef}>
        <bufferAttribute
          attach="attributes-position"
          count={getPositions().length / 3}
          array={getPositions()}
          itemSize={3}
        />
      </bufferGeometry>
      <lineBasicMaterial color="#00ff00" />
    </lineSegments>
  );
}
```

### Method 2: Regenerate Geometry (Simpler but Slower)

```tsx
function SimpleDynamicStructure({ nodes, connections }) {
  // Regenerate on every change - simpler but creates garbage
  const geometry = useMemo(() => {
    const positions: number[] = [];

    connections.forEach(({ from, to }) => {
      const nodeA = nodes.find(n => n.id === from);
      const nodeB = nodes.find(n => n.id === to);
      if (nodeA && nodeB) {
        positions.push(
          nodeA.position.x, nodeA.position.y, nodeA.position.z,
          nodeB.position.x, nodeB.position.y, nodeB.position.z
        );
      }
    });

    const geo = new THREE.BufferGeometry();
    geo.setAttribute(
      'position',
      new THREE.Float32BufferAttribute(positions, 3)
    );
    return geo;
  }, [nodes, connections]); // Regenerate when data changes

  return (
    <lineSegments geometry={geometry}>
      <lineBasicMaterial color="#00ff00" />
    </lineSegments>
  );
}
```

## Complete Tensegrity Structure Component

Putting it all together for a tensegrity visualization:

```tsx
import React, { useMemo } from 'react';
import * as THREE from 'three';

interface TensegrityNode {
  id: string;
  position: THREE.Vector3;
  isAnchored: boolean;
}

interface TensegrityRod {
  id: string;
  nodeA: string;
  nodeB: string;
}

interface TensegrityCable {
  id: string;
  nodeA: string;
  nodeB: string;
  tension: number; // 0-1, affects color
}

interface TensegrityStructureProps {
  nodes: TensegrityNode[];
  rods: TensegrityRod[];
  cables: TensegrityCable[];
  selectedNodeId?: string;
  selectedRodId?: string;
  selectedCableId?: string;
  onNodeSelect?: (id: string) => void;
  onRodSelect?: (id: string) => void;
  onCableSelect?: (id: string) => void;
}

export function TensegrityStructure({
  nodes,
  rods,
  cables,
  selectedNodeId,
  selectedRodId,
  selectedCableId,
  onNodeSelect,
  onRodSelect,
  onCableSelect
}: TensegrityStructureProps) {
  const nodeMap = useMemo(() => {
    const map = new Map<string, TensegrityNode>();
    nodes.forEach(n => map.set(n.id, n));
    return map;
  }, [nodes]);

  return (
    <group>
      {/* Render cables first (behind rods) */}
      {cables.map(cable => {
        const nodeA = nodeMap.get(cable.nodeA);
        const nodeB = nodeMap.get(cable.nodeB);
        if (!nodeA || !nodeB) return null;

        // Color based on tension
        const tensionColor = new THREE.Color().lerpColors(
          new THREE.Color('#4a90d9'), // Low tension - blue
          new THREE.Color('#d94a4a'), // High tension - red
          cable.tension
        );

        return (
          <CatenaryCable
            key={cable.id}
            start={nodeA.position}
            end={nodeB.position}
            color={selectedCableId === cable.id ? '#ffff00' : `#${tensionColor.getHexString()}`}
            thickness={0.015}
            sag={0.1 * (1 - cable.tension)} // Less sag when tense
            onSelect={() => onCableSelect?.(cable.id)}
          />
        );
      })}

      {/* Render rods */}
      {rods.map(rod => {
        const nodeA = nodeMap.get(rod.nodeA);
        const nodeB = nodeMap.get(rod.nodeB);
        if (!nodeA || !nodeB) return null;

        return (
          <Rod
            key={rod.id}
            start={nodeA.position}
            end={nodeB.position}
            radius={0.05}
            color="#666666"
            isSelected={selectedRodId === rod.id}
            onSelect={() => onRodSelect?.(rod.id)}
          />
        );
      })}

      {/* Render nodes on top */}
      {nodes.map(node => (
        <Node
          key={node.id}
          position={node.position}
          isSelected={selectedNodeId === node.id}
          isAnchored={node.isAnchored}
          onSelect={() => onNodeSelect?.(node.id)}
        />
      ))}
    </group>
  );
}
```

## Performance Tips

### 1. Use Instancing for Many Similar Objects

```tsx
function InstancedNodes({ positions }: { positions: THREE.Vector3[] }) {
  const meshRef = useRef<THREE.InstancedMesh>(null);

  useEffect(() => {
    if (meshRef.current) {
      const matrix = new THREE.Matrix4();
      positions.forEach((pos, i) => {
        matrix.setPosition(pos);
        meshRef.current!.setMatrixAt(i, matrix);
      });
      meshRef.current.instanceMatrix.needsUpdate = true;
    }
  }, [positions]);

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, positions.length]}>
      <sphereGeometry args={[0.15, 16, 16]} />
      <meshStandardMaterial color="#ffffff" />
    </instancedMesh>
  );
}
```

### 2. Batch Lines into Single Geometry

Instead of one `<line>` per segment, combine into one `<lineSegments>`.

### 3. Use `useMemo` for Geometry Creation

Never create geometries in render - always memoize.

### 4. Consider LOD for Complex Structures

```tsx
function LODNode({ position, distance }) {
  return (
    <mesh position={position}>
      {distance < 5 ? (
        <sphereGeometry args={[0.15, 32, 32]} /> // High detail
      ) : distance < 15 ? (
        <sphereGeometry args={[0.15, 16, 16]} /> // Medium detail
      ) : (
        <sphereGeometry args={[0.15, 8, 8]} />   // Low detail
      )}
      <meshStandardMaterial color="#ffffff" />
    </mesh>
  );
}
```

## Line Width Limitations

**Important**: WebGL (and thus expo-gl) does not support line widths > 1px on most devices.

For thicker lines, you must use:

1. `TubeGeometry` - 3D tubes
2. `Line2` from drei - Screen-space fat lines
3. `CylinderGeometry` - For straight segments

```tsx
// Line2 from drei (screen-space width)
import { Line } from '@react-three/drei/native';

function FatLine({ points, width = 5 }) {
  return (
    <Line
      points={points}
      color="#ff0000"
      lineWidth={width}  // Screen-space pixels
    />
  );
}
```
