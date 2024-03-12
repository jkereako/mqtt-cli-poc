//
//  MessageHandler.swift
//
//
//  Created by Jeffrey Kereakoglow on 3/12/24.
//

import Foundation

struct MessageHandler {
    var messageReceived: (String) -> Void
}

extension MessageHandler {
    static var defaultWitness = Self { _ in }
}
