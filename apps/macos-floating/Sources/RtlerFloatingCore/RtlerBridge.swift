// Copyright (c) 2026 Mustafa Mohsen
// SPDX-License-Identifier: MIT

import Foundation

@_silgen_name("rtler_transform_text")
private func rtler_transform_text(_ input: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?

@_silgen_name("rtler_free_string")
private func rtler_free_string(_ ptr: UnsafeMutablePointer<CChar>?)

enum RtlerBridge {
    static func transform(_ input: String) -> String? {
        input.withCString { cString in
            guard let output = rtler_transform_text(cString) else {
                return nil
            }
            defer { rtler_free_string(output) }
            return String(cString: output)
        }
    }
}
