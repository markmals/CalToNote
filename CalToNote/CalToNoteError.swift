enum CalToNoteError: Error {
    case userCancelled
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .userCancelled: return "You cancelled the process."
        case .unknownError: return "An unknown error occured."
        }
    }
}
