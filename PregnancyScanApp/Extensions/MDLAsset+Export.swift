import ModelIO
import Foundation

extension MDLAsset {

    /// Fallback binary STL writer for when MDLAsset.canExportFileExtension("stl") is false.
    /// Binary STL format: 80-byte header, 4-byte triangle count, then per-triangle:
    /// 12 bytes normal + 36 bytes (3 vertices x 3 floats) + 2 bytes attribute
    func exportAsBinarySTL(to url: URL) throws {
        var triangles: [(normal: SIMD3<Float>, v1: SIMD3<Float>, v2: SIMD3<Float>, v3: SIMD3<Float>)] = []

        for i in 0..<count {
            guard let object = self.object(at: i) as? MDLMesh else { continue }

            guard let vertexBuffer = object.vertexBuffers.first else { continue }
            let vertexMap = vertexBuffer.map()
            let vertexData = vertexMap.bytes

            let vertexStride = object.vertexDescriptor.layouts[0] as! MDLVertexBufferLayout
            let strideBytes = vertexStride.stride

            for submesh in object.submeshes as! [MDLSubmesh] {
                let indexBuffer = submesh.indexBuffer
                let indexMap = indexBuffer.map()
                let indexData = indexMap.bytes
                let indexCount = submesh.indexCount

                for t in stride(from: 0, to: indexCount, by: 3) {
                    let i0: Int
                    let i1: Int
                    let i2: Int

                    switch submesh.indexType {
                    case .uInt16:
                        i0 = Int(indexData.load(fromByteOffset: t * 2, as: UInt16.self))
                        i1 = Int(indexData.load(fromByteOffset: (t + 1) * 2, as: UInt16.self))
                        i2 = Int(indexData.load(fromByteOffset: (t + 2) * 2, as: UInt16.self))
                    case .uInt32:
                        i0 = Int(indexData.load(fromByteOffset: t * 4, as: UInt32.self))
                        i1 = Int(indexData.load(fromByteOffset: (t + 1) * 4, as: UInt32.self))
                        i2 = Int(indexData.load(fromByteOffset: (t + 2) * 4, as: UInt32.self))
                    default:
                        continue
                    }

                    let v1 = readVertex(from: vertexData, index: i0, stride: strideBytes)
                    let v2 = readVertex(from: vertexData, index: i1, stride: strideBytes)
                    let v3 = readVertex(from: vertexData, index: i2, stride: strideBytes)

                    let edge1 = v2 - v1
                    let edge2 = v3 - v1
                    let normal = simd_normalize(simd_cross(edge1, edge2))

                    triangles.append((normal: normal, v1: v1, v2: v2, v3: v3))
                }
            }
        }

        var data = Data()

        // 80-byte header
        let header = "BumpScan 3D STL Export".utf8
        var headerBytes = Array(header)
        headerBytes.append(contentsOf: Array(repeating: UInt8(0), count: max(0, 80 - headerBytes.count)))
        data.append(contentsOf: headerBytes.prefix(80))

        // Triangle count
        var triangleCount = UInt32(triangles.count)
        data.append(Data(bytes: &triangleCount, count: 4))

        // Triangle data
        for tri in triangles {
            appendVector(&data, tri.normal)
            appendVector(&data, tri.v1)
            appendVector(&data, tri.v2)
            appendVector(&data, tri.v3)
            var attribute: UInt16 = 0
            data.append(Data(bytes: &attribute, count: 2))
        }

        try data.write(to: url)
    }

    private func readVertex(from data: UnsafeRawPointer, index: Int, stride: Int) -> SIMD3<Float> {
        let offset = index * stride
        let x = data.load(fromByteOffset: offset, as: Float.self)
        let y = data.load(fromByteOffset: offset + 4, as: Float.self)
        let z = data.load(fromByteOffset: offset + 8, as: Float.self)
        return SIMD3<Float>(x, y, z)
    }

    private func appendVector(_ data: inout Data, _ v: SIMD3<Float>) {
        var x = v.x
        var y = v.y
        var z = v.z
        data.append(Data(bytes: &x, count: 4))
        data.append(Data(bytes: &y, count: 4))
        data.append(Data(bytes: &z, count: 4))
    }
}
