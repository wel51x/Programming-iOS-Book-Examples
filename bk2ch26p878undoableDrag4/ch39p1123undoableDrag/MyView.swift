

import UIKit

class ViewController : UIViewController {
    
}

class MyView : UIView {
    
    let undoer = UndoManager()
    override var undoManager : UndoManager? {
        return self.undoer
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let p = UIPanGestureRecognizer(target: self, action: #selector(dragging))
        self.addGestureRecognizer(p)
        let l = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        self.addGestureRecognizer(l)
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    // handler variant (new in iOS 9), better
    
    func dragging (_ p : UIPanGestureRecognizer) {
        switch p.state {
        case .began:
            self.undoer.beginUndoGrouping()
            fallthrough
        case .began, .changed:
            let delta = p.translation(in:self.superview!)
            var c = self.center
            c.x += delta.x; c.y += delta.y
            func registerForUndo() {
                let oldCenter = self.center
                self.undoer.registerUndoWithTarget(self) {
                    v in
                    UIView.animate(withDuration:0.4, delay: 0.1, animations: {
                        v.center = oldCenter
                        })
                    registerForUndo()
                }
                self.undoer.setActionName("Move")
            }
            registerForUndo()
            self.center = c // *
            p.setTranslation(CGPoint.zero, in: self.superview!)
        case .ended, .cancelled:
            self.undoer.endUndoGrouping()
            self.becomeFirstResponder()
        default: break
        }
    }
    
    // ===== press-and-hold, menu

    func longPress (_ g : UIGestureRecognizer) {
        if g.state == .began {
            let m = UIMenuController.shared()
            m.setTargetRect(self.bounds, in: self)
            let mi1 = UIMenuItem(title: self.undoer.undoMenuItemTitle, action: #selector(undo))
            let mi2 = UIMenuItem(title: self.undoer.redoMenuItemTitle, action: #selector(redo))
            m.menuItems = [mi1, mi2]
            m.setMenuVisible(true, animated:true)
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: AnyObject!) -> Bool {
        if action == #selector(undo) {
            return self.undoer.canUndo
        }
        if action == #selector(redo) {
            return self.undoer.canRedo
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    func undo(_:AnyObject?) {
        self.undoer.undo()
    }
    
    func redo(_:AnyObject?) {
        self.undoer.redo()
    }
}