//
//  ViewModel.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 23.11.25.
//

import Foundation
import FSKit
import Observation

@Observable
@MainActor
final class ViewModel {
    
    private var client: FSClient?
    private(set) var modules: [FSModuleIdentity] = []
    
    init() {
        client = FSClient.shared
        client?.fetchInstalledExtensions { modules, errors in
            if let modules {
                self.modules = modules
            }
        }
    }
}
