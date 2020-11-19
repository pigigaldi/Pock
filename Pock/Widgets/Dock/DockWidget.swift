//
//  DockWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/04/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

class DockWidget: NSObject, PKWidget {
    
    var identifier: NSTouchBarItem.Identifier = NSTouchBarItem.Identifier.dockView
    var customizationLabel: String            = "Dock".localized
    var view: NSView!
    
    /// Core
    private var dockRepository: DockRepository!
    
    /// UI
    private var stackView:           NSStackView! = NSStackView(frame: .zero)
    private var dockScrubber:        NSScrubber! = NSScrubber(frame: NSRect(x: 0, y: 0, width: 200,  height: 30))
    private var separator:           NSView! = NSView(frame:     NSRect(x: 0, y: 0, width: 1,    height: 20))
    private var persistentScrubber: NSScrubber! = NSScrubber(frame: NSRect(x: 0, y: 0, width: 50,   height: 30))
    private var lastVisibleRange:   NSRange! = NSRange(location: 0, length: 0)
    
    /// Data
    private var dockItems:       [DockItem] = []
    private var persistentItems: [DockItem] = []
    private var cachedItemViews: [Int: DockItemView] = [:]
    
    required override init() {
        super.init()
        
        self.configureStackView()
        self.configureDockScrubber()
        self.configureSeparator()
        self.configurePersistentScrubber()
        self.displayScrubbers()
        self.view = stackView
        self.dockRepository = DockRepository(delegate: self)
        self.dockRepository.reload(nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(displayScrubbers), name: .shouldReloadPersistentItems, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(reloadDockScrubberLayout), name: .shouldReloadDockLayout, object: nil)
    }
    
    deinit {
        stackView           = nil
        dockScrubber        = nil
        separator           = nil
        persistentScrubber  = nil
        dockRepository      = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    /// Configure stack view
    private func configureStackView() {
        stackView.alignment = .centerY
        stackView.orientation = .horizontal
        stackView.distribution = .fill
    }
    
    @objc private func displayScrubbers() {
        self.separator.isHidden          = Defaults[.hidePersistentItems] || persistentItems.isEmpty
        self.persistentScrubber.isHidden = Defaults[.hidePersistentItems] || persistentItems.isEmpty
    }
    
    @objc private func reloadDockScrubberLayout() {
        let dockLayout              = NSScrubberFlowLayout()
        dockLayout.itemSize         = Constants.dockItemSize
        dockLayout.itemSpacing      = CGFloat(Defaults[.itemSpacing])
        dockScrubber.scrubberLayout = dockLayout
        let persistentLayout              = NSScrubberFlowLayout()
        persistentLayout.itemSize         = Constants.dockItemSize
        persistentLayout.itemSpacing      = CGFloat(Defaults[.itemSpacing])
        persistentScrubber.scrubberLayout = persistentLayout
    }
    
    /// Configure dock scrubber
    private func configureDockScrubber() {
        let layout = NSScrubberFlowLayout()
        layout.itemSize    = Constants.dockItemSize
        layout.itemSpacing = CGFloat(Defaults[.itemSpacing])
        dockScrubber.dataSource = self
        dockScrubber.delegate = self
        dockScrubber.showsAdditionalContentIndicators = true
        dockScrubber.mode = .free
        dockScrubber.isContinuous = false
        dockScrubber.itemAlignment = .none
        dockScrubber.scrubberLayout = layout
        stackView.addArrangedSubview(dockScrubber)
    }
    
    /// Configure separator
    private func configureSeparator() {
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.darkGray.cgColor
        separator.snp.makeConstraints({ m in
            m.width.equalTo(1)
            m.height.equalTo(20)
        })
        stackView.addArrangedSubview(separator)
    }
    
    /// Configure persistent scrubber
    private func configurePersistentScrubber() {
        let layout = NSScrubberFlowLayout()
        layout.itemSize    = Constants.dockItemSize
        layout.itemSpacing = CGFloat(Defaults[.itemSpacing])
        persistentScrubber.dataSource = self
        persistentScrubber.delegate = self
        persistentScrubber.showsAdditionalContentIndicators = true
        persistentScrubber.mode = .free
        persistentScrubber.isContinuous = false
        persistentScrubber.itemAlignment = .none
        persistentScrubber.scrubberLayout = layout
        persistentScrubber.snp.makeConstraints({ m in
            m.width.equalTo((Constants.dockItemSize.width + 8) * CGFloat(persistentItems.count))
        })
        stackView.addArrangedSubview(persistentScrubber)
    }
    
}

extension DockWidget: DockDelegate {
    func didUpdate(apps: [DockItem]) {
        update(scrubber: dockScrubber, oldItems: dockItems, newItems: apps) { [weak self] apps in
            apps.enumerated().forEach({ index, item in
                item.index = index
            })
            self?.dockItems = apps
        }
    }
    func didUpdate(items: [DockItem]) {
        update(scrubber: persistentScrubber, oldItems: persistentItems, newItems: items) { [weak self] items in
            self?.persistentItems = items
            self?.displayScrubbers()
            self?.persistentScrubber.snp.updateConstraints({ m in
                m.width.equalTo((Constants.dockItemSize.width + 8) * CGFloat(self?.persistentItems.count ?? 0))
            })
        }
    }
    
    @discardableResult
    private func updateView(for item: DockItem?) -> DockItemView? {
        guard let item = item else { return nil }
        var view: DockItemView! = cachedItemViews[item.diffId]
        if view == nil {
            view = DockItemView(frame: .zero)
            cachedItemViews[item.diffId] = view
        }
        view.clear()
        view.set(icon:        item.icon)
        view.set(hasBadge:    item.hasBadge)
        view.set(isRunning:   item.isRunning)
        view.set(isFrontmost: item.isFrontmost)
        return view
    }
    
    private func update(scrubber: NSScrubber?, oldItems: [DockItem], newItems: [DockItem], completion: (([DockItem]) -> Void)? = nil) {
        guard let scrubber = scrubber else {
            completion?(newItems)
            return
        }
        DispatchQueue.main.async { [weak self] in
            completion?(newItems)
            scrubber.reloadData()
            var toIndex = self?.lastVisibleRange.upperBound ?? 0
            if scrubber.numberOfItems > 0 {
                toIndex = toIndex >= scrubber.numberOfItems ? (scrubber.numberOfItems - 1) : toIndex
                scrubber.scrollItem(at: toIndex < 0 ? 0 : toIndex, to: .none)
            }
        }
    }
    func didUpdateBadge(for apps: [DockItem]) {
        DispatchQueue.main.async { [weak self] in
            guard let s = self else { return }
            s.cachedItemViews.forEach({ key, view in
                view.set(hasBadge: apps.first(where: { $0.diffId == key })?.hasBadge ?? false)
            })
        }
    }
    func didUpdateRunningState(for apps: [DockItem]) {
        DispatchQueue.main.async { [weak self] in
            guard let s = self else { return }
            s.cachedItemViews.forEach({ key, view in
                let item = apps.first(where: { $0.diffId == key })
                view.set(isRunning:   item?.isRunning   ?? false)
                view.set(isFrontmost: item?.isFrontmost ?? false)
                view.set(isLaunching: item?.isLaunching ?? false)
                if let i = item, i.isFrontmost && !i.isPersistentItem {
                    s.dockScrubber?.animator().scrollItem(at: i.index, to: .none)
                }
            })
        }
    }
}

extension DockWidget: NSScrubberDataSource {
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        if scrubber == persistentScrubber {
            return persistentItems.count
        }
        return dockItems.count
    }
    
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        let item = scrubber == persistentScrubber ? persistentItems[index] : dockItems[index]
        return updateView(for: item)!
    }
}

extension DockWidget: NSScrubberDelegate {
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
        let item = scrubber == persistentScrubber ? persistentItems[selectedIndex] : dockItems[selectedIndex]
        var result: Bool = false
        if item.bundleIdentifier?.lowercased() == "com.apple.finder" {
            dockRepository.launch(bundleIdentifier: item.bundleIdentifier, completion: { result = $0 })
        }else {
            dockRepository.launch(item: item, completion: { result = $0 })
        }
        NSLog("[Pock]: Did open: \(item.bundleIdentifier ?? item.path?.absoluteString ?? "Unknown") [success: \(result)]")
        scrubber.selectedIndex = -1
    }
    
    func scrubber(_ scrubber: NSScrubber, didChangeVisibleRange visibleRange: NSRange) {
        lastVisibleRange = visibleRange
    }
}
