//
//  SPowerItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 23/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults
import IOKit.ps

struct SPowerStatus {
    var isCharging: Bool, currentValue: Int
}

class SPowerItem: StatusItem, ClickListener {
    
    /// Core
    private var refreshTimer: Timer?
    private var powerStatus: SPowerStatus = SPowerStatus(isCharging: false, currentValue: 0)
    private var shouldShowBatteryIcon: Bool {
        return Defaults[.shouldShowBatteryIcon]
    }
    private var shouldShowBatteryPercentage: Bool {
        return Defaults[.shouldShowBatteryPercentage]
    }
    private var shouldShowBatteryTime: Bool {
        return Defaults[.shouldShowBatteryTime]
    }
    
    private var lastShouldShowBatteryIcon: Bool = false
    private var lastShouldShowBatteryPercentage: Bool = false
    private var lastShouldShowBatteryTime: Bool = false
    
    /// An abstraction to the battery IO service
    private var battery: BatteryService!
    
    /// UI
    private var stackView: NSClickableStack = NSClickableStack(frame: .zero, id: -11)
    private let iconView: NSImageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 26, height: 26))
    private let valueLabel: NSTextField = NSTextField(frame: .zero)
    ///  The icon to display in the battery status bar item.
    private var icon: StatusBarIcon?
    
    init() {
        lastShouldShowBatteryIcon = shouldShowBatteryIcon
        lastShouldShowBatteryTime = shouldShowBatteryTime
        lastShouldShowBatteryPercentage = shouldShowBatteryPercentage
        didLoad()
        //reload()
    }
    
    deinit {
        didUnload()
    }
    
    func didLoad() {
        configureValueLabel()
        configureStackView()
        lastPercentage = nil
        lastBatteryTime = nil
        do {
            icon = StatusBarIcon()
            battery = try BatteryService()
            setBatteryStatus(battery)
            registerAsObserver()
        } catch {
        }
    }
    
    func didUnload() {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        battery.closeServiceConnection()
    }
    
    /// Registers the ApplicationController as observer for power source and user preference changes
    private func registerAsObserver() {
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(SPowerItem.powerSourceChanged(_:)),
                         name: NSNotification.Name(rawValue: powerSourceChangedNotification),
                         object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
                self, selector: #selector(onWakeNote(note:)),
                name: NSWorkspace.didWakeNotification, object: nil)
    }
    
    @objc func onWakeNote(note: NSNotification) {
        setBatteryStatus(battery)
    }
    
    ///  This message is sent to the receiver, when a powerSourceChanged message was posted. The receiver
    ///  must be registered as an observer for powerSourceChangedNotification's.
    ///
    ///  - parameter sender: The object that posted powerSourceChanged message.
    @objc public func powerSourceChanged(_: AnyObject) {
        setBatteryStatus(battery)
    }
    
    var enabled: Bool{ return Defaults[.shouldShowPowerItem] }
    
    var title: String  { return "power" }
    
    var view: NSView { return stackView }
    
    func action() {
        if !isProd { print("[Pock]: Power Status icon tapped!") }
    }
    
    private func configureValueLabel() {
        valueLabel.font = NSFont.systemFont(ofSize: 13)
        valueLabel.backgroundColor = .clear
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.isBezeled = false
        valueLabel.isEditable = false
        valueLabel.sizeToFit()
    }
    
    private func configureStackView() {
        stackView = NSClickableStack(frame: .zero, id: -11)
        stackView.clickDelegate = self
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.distribution = .fill
        stackView.spacing = 2
        stackView.addArrangedSubview(valueLabel)
        stackView.addArrangedSubview(iconView)
    }
    
    var lastPercentage: BatteryState? = nil
    var lastBatteryTime: String? = nil
    
    ///  Sets the pock bar item's battery icon.
    ///
    ///  - parameter batter: The battery to render the status bar icon for.
    private func setBatteryStatus(_ battery: BatteryService?) {
        if let batteryState = battery?.state {
            if lastPercentage != batteryState {
                lastPercentage = batteryState
                setBatteryIcon(batteryState)
                if !shouldShowBatteryTime {
                    setTitle(battery)
                }
            }
        }
        if shouldShowBatteryTime {
            if let timeRemaining = battery?.timeRemainingFormatted {
                valueLabel.isHidden = false
                if lastBatteryTime != timeRemaining {
                    lastBatteryTime = "\(timeRemaining)"
                    valueLabel.stringValue = timeRemaining
                }
            }
        }
    }
    
    
    ///  Sets the pock bar item's battery icon.
    private func setBatteryIcon(_ batteryState: BatteryState) {
        if shouldShowBatteryIcon {
            iconView.image = icon?.drawBatteryImage(forStatus: batteryState)
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
            iconView.image    = nil
        }
    }
    
    ///  Sets the pock bar item's title
    ///
    ///  - parameter battery: The battery to build the status bar title for.
    private func setTitle(_ battery: BatteryService?) {
        if shouldShowBatteryTime {
            guard let timeRemaining = battery?.timeRemainingFormatted
            else {
                return
            }
            valueLabel.isHidden = false
            valueLabel.stringValue = timeRemaining
        } else if shouldShowBatteryPercentage {
            guard let percentage = battery?.percentageFormatted
            else {
                return
            }
            valueLabel.isHidden = false
            valueLabel.stringValue = percentage
        } else {
            valueLabel.isHidden = true
            valueLabel.stringValue = ""
        }
    }
    
    // click handlers
    func didTapHandler() {
        if !Defaults[.shouldMakeClickable] {
            return
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Battery.prefPane"))
    }
    
    func didLongPressHandler() {
        if !Defaults[.shouldMakeClickable] {
            return
        }
        if shouldShowBatteryTime {
            Defaults[.shouldShowBatteryTime] = false
            Defaults[.shouldShowBatteryPercentage] = true
            NSWorkspace.shared.notificationCenter.post(name: .shouldReloadStatusWidget, object: nil)
        } else if shouldShowBatteryPercentage {
            Defaults[.shouldShowBatteryTime] = true
            Defaults[.shouldShowBatteryPercentage] = false
            NSWorkspace.shared.notificationCenter.post(name: .shouldReloadStatusWidget, object: nil)
        }
    }
    
    func didSwipeLeftHandler() {
    }
    
    func didSwipeRightHandler() {
    }
    
    func reload() {
        /*
        if lastShouldShowBatteryPercentage != shouldShowBatteryPercentage ||
            lastShouldShowBatteryTime != shouldShowBatteryTime {
            lastShouldShowBatteryTime = shouldShowBatteryTime
            lastShouldShowBatteryPercentage = shouldShowBatteryPercentage
            setTitle(battery)
        }
        if lastShouldShowBatteryIcon != shouldShowBatteryIcon {
            lastShouldShowBatteryIcon = shouldShowBatteryIcon
            if let batteryState = battery?.state {
                setBatteryIcon(batteryState)
            }
        }*/
    }
}
