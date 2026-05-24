import Foundation

struct IVSearchResponseDTO: Decodable {
    let numFound: Int?
    let docs: [IVSearchDocDTO]?
}

struct IVSearchDocDTO: Decodable {
    let key: String?
    let title: String?
    let authorName: [String]?
    let firstPublishYear: Int?
    let coverI: Int?
    let subject: [String]?
    let numberOfPagesMedian: Int?

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case authorName = "author_name"
        case firstPublishYear = "first_publish_year"
        case coverI = "cover_i"
        case subject
        case numberOfPagesMedian = "number_of_pages_median"
    }
}

struct IVWorkDTO: Decodable {
    let key: String?
    let title: String?
    let authors: [IVWorkAuthorRefDTO]?
    let description: IVDescriptionDTO?
    let subjects: [String]?
    let firstPublishDate: String?
    let covers: [Int]?

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case authors
        case description
        case subjects
        case firstPublishDate = "first_publish_date"
        case covers
    }
}

struct IVWorkAuthorRefDTO: Decodable {
    let author: IVAuthorKeyDTO?
}

struct IVAuthorKeyDTO: Decodable {
    let key: String?
}

enum IVDescriptionDTO: Decodable {
    case text(String)
    case object(value: String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            self = .text(s)
            return
        }
        struct V: Decodable { let value: String? }
        if let o = try? container.decode(V.self), let v = o.value {
            self = .object(value: v)
            return
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode description")
    }

    var plainText: String? {
        switch self {
        case .text(let s): s
        case .object(let v): v
        }
    }
}

struct IVSubjectResponseDTO: Decodable {
    let name: String?
    let works: [IVSubjectWorkDTO]?
}

struct IVSubjectWorkDTO: Decodable {
    let key: String?
    let title: String?
    let authors: [IVSubjectAuthorDTO]?
    let coverId: Int?
    let firstPublishYear: Int?

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case authors
        case coverId = "cover_id"
        case firstPublishYear = "first_publish_year"
    }
}

struct IVSubjectAuthorDTO: Decodable {
    let name: String?
    let key: String?
}
