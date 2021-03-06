/*
    Once.swift

    Copyright (c) 2016, 2017 Stephen Whittle  All rights reserved.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom
    the Software is furnished to do so, subject to the following conditions:

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

public class Once {
    private let _mutex: Mutex
    public private(set) var done = false

    public init() throws {
        self._mutex = try Mutex()
    }

    /// Execute a closure once whilst exclusive locked using a mutex.
    ///
    /// - Parameters:
    ///   - closure:  The closure to call.
    ///
    /// - Returns:    The return of the `closure` or nil if the `closure`
    ///               has already been called.
    public func execute<T>(_ closure: @escaping () throws -> T) throws -> T? {
        return try _mutex.lock {
            if (!self.done) {
                self.done = true

                return try closure()
            }

            return nil
        }
    }
}
