import Foundation

public enum LlamaBackendError: LocalizedError, Equatable, Sendable {
    case modelNotFound(String)
    case modelLoadFailed(String)
    case contextCreateFailed
    case samplerCreateFailed
    case modelNotLoaded
    case tokenizationFailed
    case promptTooLong(Int)
    case contextBudgetInvalid
    case decodeFailed(Int32)
    case chatTemplateFailed
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let path):
            "No GGUF model was found at \(path)."
        case .modelLoadFailed(let path):
            "llama.cpp could not load the GGUF model at \(path)."
        case .contextCreateFailed:
            "llama.cpp could not create an inference context."
        case .samplerCreateFailed:
            "llama.cpp could not create the token sampler."
        case .modelNotLoaded:
            "The local GGUF model is not loaded."
        case .tokenizationFailed:
            "llama.cpp could not tokenize the prompt."
        case .promptTooLong(let tokenCount):
            "The prompt is too long for the configured local context (\(tokenCount) tokens)."
        case .contextBudgetInvalid:
            "The local model context is too small for the current response settings."
        case .decodeFailed(let code):
            "llama.cpp decode failed with code \(code)."
        case .chatTemplateFailed:
            "llama.cpp could not apply the model chat template."
        case .cancelled:
            "The local generation was cancelled."
        }
    }
}
