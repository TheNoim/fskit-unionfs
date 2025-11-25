//
//  ContentView.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//

import SwiftUI
import FSKit

struct ContentView: View {
    @State
    private var viewModel = ViewModel()
    
    @StateObject
    var manageHelper: ManageHelper = ManageHelper()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                if manageHelper.isHelperToolInstalled {
                    VStack {
                        Text("Helper is installed 👍")
                        Text(manageHelper.message)
                        Button("Uninstall") {
                            Task {
                                await manageHelper.manageHelperTool(action: .uninstall)
                            }
                        }
                        Button("Test") {
                            
                        }
                    }
                } else {
                    VStack {
                        Text("Helper is not installed ❌")
                        Text(manageHelper.message)
                        Button("Install") {
                            Task {
                                await manageHelper.manageHelperTool(action: .install)
                            }
                        }
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
