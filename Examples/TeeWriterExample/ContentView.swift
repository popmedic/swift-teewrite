import SwiftUI
import TeeWrite
import OSLog

// model for Stdout Tee Writing
class StdoutTeeWrite: ObservableObject {
    // you probably what to store this somewhere better then in just a string,
    // this will buffer overflow.  Maybe only hold 1024 characters or something.
    // Even NSCache comes to mind as a way to hold without using too much RAM.
    @Published var text = ""
    private var outTeeWriter: TeeWriter!
    private var errTeeWriter: TeeWriter!
    init() {
        typealias Setup = (UnsafeMutablePointer<FILE>, FileHandle) -> TeeWriter?
        let setup: Setup = { file, handle in
            setvbuf(file, nil, _IONBF, 0)
            return TeeWriter(handle: handle) { [weak self] data in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.text += String(data: data, encoding: .ascii) ?? "bad data"
                }
            }
        }

        self.outTeeWriter = setup(stdout, FileHandle.standardOutput)
        self.errTeeWriter = setup(stderr, FileHandle.standardError)
    }
}

struct ContentView: View {
    @ObservedObject var stdoutTeeRead = StdoutTeeWrite()
    @State var input = ""
    private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: "\(ContentView.self)")
    var body: some View {
        VStack {
            TextField("text to print/nslog/os_log", text: $input).padding()
            HStack {
                Button("print") {
                    print(input)
                }.padding()
                Button("nslog") {
                    NSLog(input)
                }.padding()
                Button("os_log") {
                    logger.notice("\(input)")
                }.padding()
            }
            ScrollView {
                Text(stdoutTeeRead.text).padding().frame(maxWidth: .infinity)
            }.frame(maxWidth: .infinity)
        }.onTapGesture {
            UIApplication.shared.endEditing()
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
