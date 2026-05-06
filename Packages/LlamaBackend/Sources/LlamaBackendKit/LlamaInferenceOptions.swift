import Foundation

public struct LlamaInferenceOptions: Equatable, Sendable {
    public var contextTokenLimit: Int32
    public var batchTokenLimit: Int32
    public var outputTokenLimit: Int32
    public var gpuLayerCount: Int32
    public var threadCount: Int32
    public var topK: Int32
    public var topP: Float
    public var temperature: Float
    public var seed: UInt32
    public var repeatPenalty: Float

    public init(
        contextTokenLimit: Int32 = 2048,
        batchTokenLimit: Int32 = 512,
        outputTokenLimit: Int32 = 256,
        gpuLayerCount: Int32 = 99,
        threadCount: Int32 = 4,
        topK: Int32 = 40,
        topP: Float = 0.9,
        temperature: Float = 0.7,
        seed: UInt32 = UInt32.max,
        repeatPenalty: Float = 1.1
    ) {
        self.contextTokenLimit = contextTokenLimit
        self.batchTokenLimit = batchTokenLimit
        self.outputTokenLimit = outputTokenLimit
        self.gpuLayerCount = gpuLayerCount
        self.threadCount = threadCount
        self.topK = topK
        self.topP = topP
        self.temperature = temperature
        self.seed = seed
        self.repeatPenalty = repeatPenalty
    }
}
