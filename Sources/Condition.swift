/*
    Condition.swift

    Copyright (c) 2016, 2017 Stephen Whittle  All rights reserved.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom
    the Software is furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

import Glibc
import Foundation
import ISFLibrary

public class Condition {
    private var condition = pthread_cond_t()
    public let mutex: Mutex

    ///  Returns a new Cond.
    /// - Parameter mutex: A Mutex object.
    public init(_ mutex: Mutex) throws {
        self.mutex = mutex

        guard (pthread_cond_init(&condition, nil) >= 0) else {
            throw MutexError.CondInit(code: errno)
        }
    }

    deinit {
        wrapper(do: {
                    guard (pthread_cond_destroy(&self.condition) >= 0) else {
                        throw MutexError.CondDestroy(code: errno)
                    }
                },
                catch: { failure in
                    mutexErrorLogger(failure)
                })
    }

    /// Wakes all operations waiting on `Cond`.
    public func broadcast() throws {
        guard (pthread_cond_broadcast(&condition) >= 0) else {
            throw MutexError.CondBroadcast(code: errno)
        }
    }

    /// Wakes one operations waiting on `Cond`.
    public func signal() throws {
        guard (pthread_cond_signal(&condition) >= 0) else {
            throw MutexError.CondSignal(code: errno)
        }
    }

    @discardableResult
    public func wait(_ timeout: TimeInterval = -1) throws -> Wait {
        if (timeout < 0) {
            guard (pthread_cond_wait(&condition, &mutex.mutex) >= 0) else {
                throw MutexError.CondWait(code: errno)
            }
        } else {
            var tv = timeval()
            var ts = timespec()

            gettimeofday(&tv, nil)

            ts.tv_sec = time(nil) + timeout.wholeSeconds
            ts.tv_nsec = Int(tv.tv_usec * 1_000 + (1_000 * 1_000 * (timeout.milliseconds % 1_000)))
            ts.tv_sec += ts.tv_nsec / 1_000_000_000
            ts.tv_nsec %= 1_000_000_000

            guard (pthread_cond_timedwait(&condition, &mutex.mutex, &ts) >= 0) else {
                let errorNumber = errno

                guard (errorNumber == ETIMEDOUT) else {
                    throw MutexError.CondTimedWait(code: errorNumber)
                }

                return .TimedOut
            }
        }

        return .Signaled
    }
}
