struct Boxnote: Codable {
    struct TextContents: Codable {
        let text: String
        let attributes: String
        let attributesCount: Int?
        
        enum CodingKeys: String, CodingKey {
            case text
            case attributes = "attribs"
            case attributesCount = "appliedAttribsCount"
        }
    }
    
    let contents: TextContents
    let head: UInt
    let chatHead: Int
    let publicStatus: Bool
    let passwordHash: String?
    
    enum CodingKeys: String, CodingKey {
        case contents = "atext"
        case head
        case chatHead
        case publicStatus
        case passwordHash
    }
}


