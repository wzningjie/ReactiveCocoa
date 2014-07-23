//
//  Atomic.swift
//  ReactiveCocoa
//
//  Created by Justin Spahr-Summers on 2014-06-10.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

/// An atomic variable.
internal final class Atomic<T> {
	private var _spinlock = OS_SPINLOCK_INIT
	private var _value: T
	
	/// Atomically gets or sets the value of the variable.
	public var value: T {
		get {
			_lock()
			let v = _value
			_unlock()

			return v
		}
	
		set(newValue) {
			_lock()
			_value = newValue
			_unlock()
		}
	}
	
	/// Initializes the variable with the given initial value.
	public init(_ value: T) {
		_value = value
	}
	
	private func _lock() {
		withUnsafePointer(&_spinlock, OSSpinLockLock)
	}
	
	private func _unlock() {
		withUnsafePointer(&_spinlock, OSSpinLockUnlock)
	}
	
	/// Atomically replaces the contents of the variable.
	///
	/// Returns the old value.
	public func swap(newValue: T) -> T {
		return modify { _ in newValue }
	}

	/// Atomically modifies the variable.
	///
	/// Returns the old value.
	public func modify(action: T -> T) -> T {
		let (oldValue, _) = modify { oldValue in (action(oldValue), 0) }
		return oldValue
	}
	
	/// Atomically modifies the variable.
	///
	/// Returns the old value, plus arbitrary user-defined data.
	public func modify<U>(action: T -> (T, U)) -> (T, U) {
		_lock()
		let oldValue: T = _value
		let (newValue, data) = action(_value)
		_value = newValue
		_unlock()
		
		return (oldValue, data)
	}
	
	/// Atomically performs an arbitrary action using the current value of the
	/// variable.
	///
	/// Returns the result of the action.
	public func withValue<U>(action: T -> U) -> U {
		_lock()
		let result = action(_value)
		_unlock()
		
		return result
	}

	/// Treats the Atomic variable as its underlying value in expressions.
	public func __conversion() -> T {
		return value
	}
}
