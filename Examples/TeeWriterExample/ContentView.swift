import SwiftUI
import TeeWrite

// model for Stdout Tee Writing
class StdoutTeeWrite: ObservableObject {
    // you probably what to store this somewhere better then in just a string,
    // this will buffer overflow.  Maybe only hold 1024 characters or something.
    // Even NSCache comes to mind as a way to hold without using too much RAM.
    @Published var text = ""
    private var teeWriter: TeeWriter!
    init() {
        teeWriter = TeeWriter(handle: FileHandle.standardOutput) { [weak self] data in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.text += String(data: data, encoding: .ascii) ?? "bad data"
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var stdoutTeeRead = StdoutTeeWrite()
    @State var input = ""
    var body: some View {
        VStack {
            TextField("text to print", text: $input).padding()
            Button("print") {
                print(input)
            }.padding()
            Text(stdoutTeeRead.text).padding()
        }
    }
}

@main
struct TeeWriterExample: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
