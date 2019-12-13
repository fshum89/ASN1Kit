//
// Copyright (c) 2019 gematik GmbH
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//    http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import DataKit
import Foundation

extension ASN1Primitive: CustomStringConvertible {
    public var description: String {
        return "{\n\ttag: \(tag),\n\tlength: \(length),\n\tconstructed: \(String(describing: constructed)),\n\t" +
                "value: \(tag.describing(data).replacingOccurrences(of: "\n", with: "\n\t"))\n}"
    }
}

extension ASN1Primitive: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.description
    }
}

extension ASN1Data: CustomStringConvertible {
    public var description: String {
        switch self {
        case .primitive(let data):
            return "Primitive: [\(data.hexString())]"
        case .constructed(let items):
            return "[\n\t" +
                    items.map { String(describing: $0).replacingOccurrences(of: "\n", with: "\n\t") }
                            .joined(separator: ",\n\t") +
                    "\n]"
        }
    }
}

extension ASN1Data: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.description
    }
}

extension ASN1Tag {
    internal func describing(_ data: Data) -> String {
        //swiftlint:disable no_fallthrough_only
        switch self {
        case .bmpString: fallthrough
        case .universalString: fallthrough
        case .utf8String:
            return (try? String(from: create(tag: .universal(self), data: .primitive(data)))) ??
                    "Invalid string: [\(data.hexString())]"
        case .objectIdentifier:
            return (try? ObjectIdentifier(from: create(tag: .universal(self), data: .primitive(data))).rawValue) ??
                    "Invalid OID: [\(data.hexString())]"
        case .utcTime: fallthrough
        case .generalizedTime:
            return String(describing: try? Date(from: create(tag: .universal(self), data: .primitive(data))))
        default:
            return "[\(data.hexString())]"
        }
    }
}

extension ASN1DecodedTag: CustomStringConvertible {
    internal func describing(_ data: ASN1Data) -> String {
        return data.fold({ primitive in
            switch self {
            case .universal(let tag):
                return tag.describing(primitive)
            case .applicationTag: fallthrough
            case .taggedTag: fallthrough
            case .privateTag:
                return "[IMPLICIT] \(primitive.hexString())"
            }
        }, { items in
            String(describing: items)
        })
        //swiftlint:enable no_fallthrough_only
    }

    public var description: String {
        switch self {
        case .applicationTag(let tag):
            return ".applicationTag[0x\(String(tag, radix: 16))]"
        case .taggedTag(let tag):
            return ".taggedTag[0x\(String(tag, radix: 16))]"
        case .privateTag(let tag):
            return ".privateTag[0x\(String(tag, radix: 16))]"
        case .universal(let tag):
            return ".\(String(describing: tag))"
        }
    }
}

extension ASN1DecodedTag: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.description
    }
}
