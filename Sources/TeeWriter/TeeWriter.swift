import Foundation

// MARK: - TeeWriter
/**
 TeeWriter will just add a pipe to a FileHandle and pass the data through the pipe
 calling a handler when the data is available in the read FileHandler from the
 FileHandle you are reading from, and then write to a pipe that is where the
 the FileHandle used to go.

 Used to be:
 ```
 write -> fd
 ```
 with a tee:
 ```
 write -> readPipe -> writePipe -> fd
 ```
 */
public struct TeeWriter {
    let reader = Pipe()
    let writer = Pipe()

    /**
     Creates a TeeWriter for a specified `FileHandle`
     - parameters:
        - handle: the `FileHandle` to add the `TeeWriter` too
        - handler: closure for what to do when a write is done to `handle`.  Will
                   take in a `Data` with the most recent data writen to `handle`
     - returns: a new `TeeWriter` that will read all data written to `handle`
     */
    public init(handle: FileHandle, handler: @escaping (Data) -> Void) {
        dup2(handle.fileDescriptor, writer.fileHandleForWriting.fileDescriptor)
        dup2(reader.fileHandleForWriting.fileDescriptor, handle.fileDescriptor)
        reader.fileHandleForReading.readabilityHandler = { [self] handle in
            let data = handle.availableData
            writer.fileHandleForWriting.write(data)
            handler(data)
        }
    }

    /**
     Creates a TeeWriter for a specified `FileHandle`.  Anything written to handle will also
     be written other
     - parameters:
        - handle: the `FileHandle` to add the `TeeWriter` too
        - other: also write to this `FileHandle` when `handle` is written to
        - handler: an optional closure for whenever the `handle` and `other`
                    are written to (called post write)
     - returns: a new `TeeWriter` that will read all data written to `handle`
     */
    public init(_ handle: FileHandle, also other: FileHandle,
                written handler: ((Data) -> Void)? = nil) {
        self.init(handle: handle) { data in
            other.write(data)
            handler?(data)
        }
    }
}
