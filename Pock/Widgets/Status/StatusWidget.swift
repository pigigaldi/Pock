//
//  StatusWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 23/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class StatusWidget: PKWidget {
    
    var identifier: NSTouchBarItem.Identifier = NSTouchBarItem.Identifier.status
    var customizationLabel: String            = "Status".localized
    var view: NSView!
    
    /// Core
    private var statusElements: [StatusItem] = [
        SWifiItem(),
        SLangItem(),
        SPowerItem(),
        SClockItem()
    ]
    private var statusElementViews: [String: NSView] = [:]
    
    /// UI
    private var stackView: NSStackView!
    
    required init() {
        self.customizationLabel = "Status".localized
        self.initStackView()
        self.loadStatusElements()
        self.view = stackView
    }
    
    deinit {
        statusElementViews.removeAll()
        statusElements.removeAll()
    }
    
    func viewDidAppear() {
        NSWorkspace.shared.notificationCenter.addObserver(forName: .shouldReloadStatusWidget, object: nil, queue: .main, using: { [weak self] _ in
            self?.loadStatusElements(needsUnload: true)
        })
    }
    
    func viewWillDisappear() {
        self.statusElements.forEach({ $0.didUnload() })
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    private func initStackView() {
        stackView = NSStackView(frame: NSRect(x: 0, y: 0, width: 100, height: 30))
        stackView.orientation  = .horizontal
        stackView.alignment    = .centerY
        stackView.distribution = .fillProportionally
        stackView.spacing      = 8
    }
    
    private func clearStackView() {
        stackView.arrangedSubviews.forEach({ subview in
            stackView.removeView(subview)
        })
    }
    
    private func loadStatusElements(needsUnload: Bool = false) {
        clearStackView()
        statusElements.filter({ $0.enabled }).forEach({ item in
            if needsUnload {
                item.didUnload()
            }
            item.didLoad()
            statusElementViews[item.title] = item.view
            item.reload()
            stackView.addArrangedSubview(item.view)
        })
    }
}
