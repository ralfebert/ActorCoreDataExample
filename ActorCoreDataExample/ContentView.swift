import SwiftUI

struct ContentView: View {
    @StateObject var entryModel = EntryModel()

    var body: some View {
        List(entryModel.entries, id: \.self) { value in
            Text(String(value))
        }
        Button("Add") {
            Task {
                await entryModel.store.addEntry()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
