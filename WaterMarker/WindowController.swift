//
//  WindowController.swift
//  WaterMarker
//
//  Created by Матвей Анисович on 3/25/21.
//

import Cocoa

class WindowController: NSWindowController, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.hide(nil)
        return false
    }
}
