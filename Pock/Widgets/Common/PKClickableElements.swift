//
//  PKClickableElements.swift
//  Pock
//
//  Created by Konstantin Tuev on 19.11.20.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import Foundation

protocol ClickListener {
    /**
    Override this function to define an action for user's tap.
    */
    func didTapHandler()
    
    /**
    Override this function to define an action for user's long press.
    */
    func didLongPressHandler()
    
    /**
     Override this function to define an action for user's left swipe.
     */
    func didSwipeLeftHandler()
    
    /**
     Override this function to define an action for user's right swipe.
     */
    func didSwipeRightHandler()
}

private var longClickedItem: [Int: Bool] = [:]

class NSClickableStack: NSStackView {
    /// Core
    private var initialPosition: NSPoint?
    
    public var clickDelegate: ClickListener? = nil
    
    public var id: Int = -11
    
    required init(frame frameRect: NSRect, id localId: Int) {
        super.init(frame:frameRect);
        self.id = localId
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    /**
    Override this property to define custom long-press delay.
    */
    open var longPressDelay: TimeInterval = 0.5
    
    // MARK: Private handlers
    @objc private func _didLongPress() {
        longClickedItem[self.id] = true
        clickDelegate?.didLongPressHandler()
    }
    
    // MARK: Overrides
    override open func touchesBegan(with event: NSEvent) {
        /// Touches began
        super.touchesBegan(with: event)
        /// Get touch
        guard let touch = event.allTouches().first else { return }
        /// Get touch location
        let location = touch.location(in: self.superview)
        /// Check if location is in self
        if self.frame.contains(location) {
            self.initialPosition = location
            longClickedItem[self.id] = false
            self.perform(#selector(_didLongPress), with: nil, afterDelay: longPressDelay)
        }
    }
    
    override open func touchesEnded(with event: NSEvent) {
        /// Cancel long press handler, if needed
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_didLongPress), object: nil)
        /// Touches ended
        super.touchesEnded(with: event)
        /// Get touch
        guard longClickedItem[self.id] == false, let touch = event.allTouches().first else { return }
        /// Get touch location
        let location = touch.location(in: self.superview)
        /// Check location
        if location.x < initialPosition?.x ?? location.x {
            clickDelegate?.didSwipeLeftHandler()
        }else if location.x > initialPosition?.x ?? location.x {
            clickDelegate?.didSwipeRightHandler()
        }else {
            /// Check if location is in self
            if self.frame.contains(location) {
                clickDelegate?.didTapHandler()
            }
        }
    }
}

class NSClickableImageView: NSImageView {
    /// Core
    private var initialPosition: NSPoint?
    
    public var clickDelegate: ClickListener? = nil
    
    /**
    Override this property to define custom long-press delay.
    */
    open var longPressDelay: TimeInterval = 0.5
    
    public var id: Int = -11
    
    required init(frame frameRect: NSRect, id localId: Int) {
        super.init(frame:frameRect);
        self.id = localId
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: Private handlers
    @objc private func _didLongPress() {
        longClickedItem[self.id] = true
        clickDelegate?.didLongPressHandler()
    }
    
    // MARK: Overrides
    override open func touchesBegan(with event: NSEvent) {
        /// Touches began
        super.touchesBegan(with: event)
        /// Get touch
        guard let touch = event.allTouches().first else { return }
        /// Get touch location
        let location = touch.location(in: self.superview)
        /// Check if location is in self
        if self.frame.contains(location) {
            self.initialPosition = location
            longClickedItem[self.id] = false
            self.perform(#selector(_didLongPress), with: nil, afterDelay: longPressDelay)
        }
    }
    
    override open func touchesEnded(with event: NSEvent) {
        /// Cancel long press handler, if needed
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_didLongPress), object: nil)
        /// Touches ended
        super.touchesEnded(with: event)
        /// Get touch
        guard longClickedItem[self.id] == false, let touch = event.allTouches().first else { return }
        /// Get touch location
        let location = touch.location(in: self.superview)
        /// Check location
        if location.x < initialPosition?.x ?? location.x {
            clickDelegate?.didSwipeLeftHandler()
        }else if location.x > initialPosition?.x ?? location.x {
            clickDelegate?.didSwipeRightHandler()
        }else {
            /// Check if location is in self
            if self.frame.contains(location) {
                clickDelegate?.didTapHandler()
            }
        }
    }
}

class NSClickableTextField: NSTextField {
    /// Core
    private var initialPosition: NSPoint?
    
    public var clickDelegate: ClickListener? = nil
    
    /**
    Override this property to define custom long-press delay.
    */
    open var longPressDelay: TimeInterval = 0.5
    
    public var id: Int = -11
        
    required init(id localId: Int) {
        super.init(frame: NSRect.zero);
        self.id = localId
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: Private handlers
    @objc private func _didLongPress() {
        longClickedItem[self.id] = true
        clickDelegate?.didLongPressHandler()
    }
    
    // MARK: Overrides
    override open func touchesBegan(with event: NSEvent) {
        /// Touches began
        super.touchesBegan(with: event)
        /// Get touch
        guard let touch = event.allTouches().first else { return }
        /// Get touch location
        let location = touch.location(in: self.superview)
        /// Check if location is in self
        if self.frame.contains(location) {
            self.initialPosition = location
            longClickedItem[self.id] = false
            self.perform(#selector(_didLongPress), with: nil, afterDelay: longPressDelay)
        }
    }
    
    override open func touchesEnded(with event: NSEvent) {
        /// Cancel long press handler, if needed
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_didLongPress), object: nil)
        /// Touches ended
        super.touchesEnded(with: event)
        /// Get touch
        guard longClickedItem[self.id] == false, let touch = event.allTouches().first else { return }
        /// Get touch location
        let location = touch.location(in: self.superview)
        /// Check location
        if location.x < initialPosition?.x ?? location.x {
            clickDelegate?.didSwipeLeftHandler()
        }else if location.x > initialPosition?.x ?? location.x {
            clickDelegate?.didSwipeRightHandler()
        }else {
            /// Check if location is in self
            if self.frame.contains(location) {
                clickDelegate?.didTapHandler()
            }
        }
    }
}

