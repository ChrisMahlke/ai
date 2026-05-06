import Foundation
import llama

public final class LlamaLocalEngine: @unchecked Sendable {
    public typealias ProgressHandler = @Sendable (Double, String) -> Void
    public typealias TokenHandler = @Sendable (String) -> Void

    private static let backendLock = NSLock()
    private static var backendInitialized = false

    private let queue = DispatchQueue(label: "io.chrismahlke.falken.llama-backend")
    private let generationLock = NSLock()
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var sampler: UnsafeMutablePointer<llama_sampler>?
    private var vocabulary: OpaquePointer?
    private var options = LlamaInferenceOptions()
    private var activeGenerationToken: LlamaGenerationToken?

    public init() {}

    deinit {
        unload()
    }

    public var isLoaded: Bool {
        queue.sync { model != nil && context != nil && sampler != nil }
    }

    public func load(
        modelPath: String,
        options: LlamaInferenceOptions = LlamaInferenceOptions(),
        progress: @escaping ProgressHandler = { _, _ in }
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    try self.loadSync(modelPath: modelPath, options: options, progress: progress)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func unload() {
        cancelGeneration()
        queue.sync {
            unloadSync()
        }
    }

    public func unloadAsync() async {
        cancelGeneration()
        await withCheckedContinuation { continuation in
            queue.async {
                self.unloadSync()
                continuation.resume()
            }
        }
    }

    public func cancelGeneration() {
        generationLock.lock()
        let token = activeGenerationToken
        generationLock.unlock()

        token?.cancel()
    }

    public func generate(
        prompt: String,
        onToken: @escaping TokenHandler
    ) async throws {
        try await runGeneration(onToken: onToken) { token, onToken in
            try self.generateSync(prompt: prompt, cancellationToken: token, onToken: onToken)
        }
    }

    public func generateChat(
        messages: [LlamaChatTurn],
        onToken: @escaping TokenHandler
    ) async throws {
        try await runGeneration(onToken: onToken) { token, onToken in
            let prompt = try self.chatPromptWithinBudgetSync(messages: messages)
            try self.generateSync(prompt: prompt, cancellationToken: token, onToken: onToken)
        }
    }

    private func runGeneration(
        onToken: @escaping TokenHandler,
        operation: @escaping @Sendable (LlamaGenerationToken, @escaping TokenHandler) throws -> Void
    ) async throws {
        let token = LlamaGenerationToken()
        setActiveGenerationToken(token)

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                queue.async {
                    defer {
                        self.clearActiveGenerationToken(token)
                    }

                    do {
                        try token.checkCancellation()
                        try operation(token, onToken)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } onCancel: {
            token.cancel()
        }
    }

    private func loadSync(
        modelPath: String,
        options: LlamaInferenceOptions,
        progress: ProgressHandler
    ) throws {
        if model != nil, context != nil, sampler != nil {
            return
        }

        guard FileManager.default.fileExists(atPath: modelPath) else {
            throw LlamaBackendError.modelNotFound(modelPath)
        }

        Self.initializeBackendIfNeeded()
        progress(0.1, "Preparing GGUF runtime")
        unloadSync()
        self.options = options

        var modelParams = llama_model_default_params()
        modelParams.n_gpu_layers = options.gpuLayerCount
        modelParams.use_mmap = true
        modelParams.use_mlock = false

        progress(0.35, "Loading GGUF model")
        let loadedModel = modelPath.withCString { path in
            llama_model_load_from_file(path, modelParams)
        }
        guard let loadedModel else {
            throw LlamaBackendError.modelLoadFailed(modelPath)
        }

        var contextParams = llama_context_default_params()
        contextParams.n_ctx = UInt32(options.contextTokenLimit)
        contextParams.n_batch = UInt32(options.batchTokenLimit)
        contextParams.n_ubatch = UInt32(options.batchTokenLimit)
        contextParams.n_seq_max = 1
        contextParams.n_threads = options.threadCount
        contextParams.n_threads_batch = options.threadCount
        contextParams.offload_kqv = true
        contextParams.flash_attn = false

        progress(0.72, "Creating inference context")
        guard let loadedContext = llama_init_from_model(loadedModel, contextParams) else {
            llama_model_free(loadedModel)
            throw LlamaBackendError.contextCreateFailed
        }

        guard let loadedVocabulary = llama_model_get_vocab(loadedModel) else {
            llama_free(loadedContext)
            llama_model_free(loadedModel)
            throw LlamaBackendError.contextCreateFailed
        }

        guard let loadedSampler = makeSampler(options: options) else {
            llama_free(loadedContext)
            llama_model_free(loadedModel)
            throw LlamaBackendError.samplerCreateFailed
        }

        model = loadedModel
        context = loadedContext
        vocabulary = loadedVocabulary
        sampler = loadedSampler
        progress(1.0, "Local model ready")
    }

    private func unloadSync() {
        if let sampler {
            llama_sampler_free(sampler)
        }

        if let context {
            llama_free(context)
        }

        if let model {
            llama_model_free(model)
        }

        sampler = nil
        context = nil
        model = nil
        vocabulary = nil
    }

    private func generateSync(
        prompt: String,
        cancellationToken: LlamaGenerationToken,
        onToken: TokenHandler
    ) throws {
        guard let context, let sampler, let vocabulary else {
            throw LlamaBackendError.modelNotLoaded
        }

        let cancellationContext = Unmanaged.passUnretained(cancellationToken).toOpaque()
        llama_set_abort_callback(context, Self.abortCallback, cancellationContext)
        defer {
            llama_set_abort_callback(context, nil, nil)
        }

        llama_kv_self_clear(context)
        llama_sampler_reset(sampler)
        try cancellationToken.checkCancellation()

        var promptTokens = try tokenize(prompt, vocabulary: vocabulary)
        guard !promptTokens.isEmpty else {
            throw LlamaBackendError.tokenizationFailed
        }

        let maxPromptTokens = Int(options.contextTokenLimit - options.outputTokenLimit)
        guard promptTokens.count <= maxPromptTokens else {
            throw LlamaBackendError.promptTooLong(promptTokens.count)
        }

        let promptBatch = llama_batch_get_one(&promptTokens, Int32(promptTokens.count))
        try cancellationToken.checkCancellation()
        let promptDecodeStatus = llama_decode(context, promptBatch)
        try cancellationToken.checkCancellation()
        guard promptDecodeStatus == 0 else {
            throw LlamaBackendError.decodeFailed(promptDecodeStatus)
        }

        for _ in 0..<options.outputTokenLimit {
            try cancellationToken.checkCancellation()

            let nextToken = llama_sampler_sample(sampler, context, -1)
            if llama_vocab_is_eog(vocabulary, nextToken) {
                break
            }

            if let piece = piece(for: nextToken, vocabulary: vocabulary), !piece.isEmpty {
                onToken(piece)
            }

            var token = nextToken
            let tokenBatch = llama_batch_get_one(&token, 1)
            let decodeStatus = llama_decode(context, tokenBatch)
            try cancellationToken.checkCancellation()
            guard decodeStatus == 0 else {
                throw LlamaBackendError.decodeFailed(decodeStatus)
            }
        }
    }

    private func chatPromptWithinBudgetSync(messages: [LlamaChatTurn]) throws -> String {
        let maxPromptTokens = Int(options.contextTokenLimit - options.outputTokenLimit)
        guard maxPromptTokens > 64 else {
            throw LlamaBackendError.contextBudgetInvalid
        }

        let systemMessages = messages.filter { $0.role == "system" }
        let conversationalMessages = messages.filter { $0.role != "system" }

        for startIndex in conversationalMessages.indices {
            let candidateMessages = systemMessages + Array(conversationalMessages[startIndex...])
            let prompt = try applyChatTemplateSync(messages: Array(candidateMessages))
            let tokenCount = try tokenCountSync(prompt)

            if tokenCount <= maxPromptTokens {
                return prompt
            }
        }

        let prompt = try applyChatTemplateSync(messages: systemMessages + Array(conversationalMessages.suffix(1)))
        let tokenCount = try tokenCountSync(prompt)
        throw LlamaBackendError.promptTooLong(tokenCount)
    }

    private func applyChatTemplateSync(messages: [LlamaChatTurn]) throws -> String {
        guard let model else {
            throw LlamaBackendError.modelNotLoaded
        }

        let template = llama_model_chat_template(model, nil)
        var cMessages = [llama_chat_message]()
        cMessages.reserveCapacity(messages.count)

        for message in messages {
            let role = strdup(message.role)
            let content = strdup(message.content)
            cMessages.append(llama_chat_message(role: role, content: content))
        }

        defer {
            for message in cMessages {
                free(UnsafeMutableRawPointer(mutating: message.role))
                free(UnsafeMutableRawPointer(mutating: message.content))
            }
        }

        let requiredLength = cMessages.withUnsafeBufferPointer { buffer in
            llama_chat_apply_template(
                template,
                buffer.baseAddress,
                buffer.count,
                true,
                nil,
                0
            )
        }

        guard requiredLength > 0 else {
            throw LlamaBackendError.chatTemplateFailed
        }

        var renderedPrompt = [CChar](repeating: 0, count: Int(requiredLength) + 1)
        let writtenLength = cMessages.withUnsafeBufferPointer { buffer in
            llama_chat_apply_template(
                template,
                buffer.baseAddress,
                buffer.count,
                true,
                &renderedPrompt,
                Int32(renderedPrompt.count)
            )
        }

        guard writtenLength > 0 else {
            throw LlamaBackendError.chatTemplateFailed
        }

        return String(cString: renderedPrompt)
    }

    private func tokenCountSync(_ text: String) throws -> Int {
        guard let vocabulary else {
            throw LlamaBackendError.modelNotLoaded
        }

        return try tokenize(text, vocabulary: vocabulary).count
    }

    private static func initializeBackendIfNeeded() {
        backendLock.lock()
        defer { backendLock.unlock() }

        guard !backendInitialized else { return }
        llama_backend_init()
        backendInitialized = true
    }

    private func makeSampler(options: LlamaInferenceOptions) -> UnsafeMutablePointer<llama_sampler>? {
        var samplerParams = llama_sampler_chain_default_params()
        samplerParams.no_perf = true

        guard let chain = llama_sampler_chain_init(samplerParams) else {
            return nil
        }

        llama_sampler_chain_add(chain, llama_sampler_init_penalties(64, options.repeatPenalty, 0, 0))
        llama_sampler_chain_add(chain, llama_sampler_init_top_k(options.topK))
        llama_sampler_chain_add(chain, llama_sampler_init_top_p(options.topP, 1))
        llama_sampler_chain_add(chain, llama_sampler_init_temp(options.temperature))
        llama_sampler_chain_add(chain, llama_sampler_init_dist(options.seed))
        return chain
    }

    private func tokenize(
        _ text: String,
        vocabulary: OpaquePointer
    ) throws -> [llama_token] {
        let utf8Count = Int32(text.utf8.count)
        var tokenCapacity = max(utf8Count + 8, 32)
        var tokens = [llama_token](repeating: 0, count: Int(tokenCapacity))

        let tokenCount = text.withCString { pointer in
            llama_tokenize(vocabulary, pointer, utf8Count, &tokens, tokenCapacity, true, true)
        }

        if tokenCount < 0 {
            tokenCapacity = -tokenCount
            tokens = [llama_token](repeating: 0, count: Int(tokenCapacity))
            let retryCount = text.withCString { pointer in
                llama_tokenize(vocabulary, pointer, utf8Count, &tokens, tokenCapacity, true, true)
            }
            guard retryCount >= 0 else {
                throw LlamaBackendError.tokenizationFailed
            }
            return Array(tokens.prefix(Int(retryCount)))
        }

        return Array(tokens.prefix(Int(tokenCount)))
    }

    private func piece(
        for token: llama_token,
        vocabulary: OpaquePointer
    ) -> String? {
        var buffer = [CChar](repeating: 0, count: 64)
        let written = llama_token_to_piece(vocabulary, token, &buffer, Int32(buffer.count), 0, false)

        if written < 0 {
            buffer = [CChar](repeating: 0, count: Int(-written))
            let retryWritten = llama_token_to_piece(vocabulary, token, &buffer, Int32(buffer.count), 0, false)
            guard retryWritten > 0 else {
                return nil
            }
            return String(decoding: buffer.prefix(Int(retryWritten)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
        }

        guard written > 0 else {
            return nil
        }
        return String(decoding: buffer.prefix(Int(written)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    private func setActiveGenerationToken(_ token: LlamaGenerationToken) {
        generationLock.lock()
        activeGenerationToken = token
        generationLock.unlock()
    }

    private func clearActiveGenerationToken(_ token: LlamaGenerationToken) {
        generationLock.lock()
        if activeGenerationToken === token {
            activeGenerationToken = nil
        }
        generationLock.unlock()
    }

    private static let abortCallback: ggml_abort_callback = { userData in
        guard let userData else {
            return false
        }

        let token = Unmanaged<LlamaGenerationToken>
            .fromOpaque(userData)
            .takeUnretainedValue()
        return token.isCancelled
    }
}

private final class LlamaGenerationToken: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }

    func checkCancellation() throws {
        if isCancelled {
            throw LlamaBackendError.cancelled
        }
    }
}
