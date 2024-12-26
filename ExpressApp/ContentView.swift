import SwiftUI

// structs MARK
struct WordEntry: Identifiable, Codable {
    var id: UUID
    let word: String
    let explanation: String
    
    // init
    init(id: UUID = UUID(), word: String, explanation: String) {
        self.id = id
        self.word = word
        self.explanation = explanation
    }
}

// WORD LISTT VIEW
class WordListViewModel: ObservableObject {
    @Published var wordEntries: [WordEntry] = []
    
    private let fileName = "WordEntries.json"
    
    init() {
        loadEntries()
    }
    
    func addEntry(word: String, explanation: String) {
        let newEntry = WordEntry(word: word, explanation: explanation)
        wordEntries.append(newEntry)
        saveEntries()
    }
    
    func saveEntries() { // internal save
        do {
            let url = getFileURL()
            let data = try JSONEncoder().encode(wordEntries)
            try data.write(to: url, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Failed to save data: \(error.localizedDescription)")
        }
    }
    
    private func loadEntries() {
        do {
            let url = getFileURL()
            let data = try Data(contentsOf: url)
            wordEntries = try JSONDecoder().decode([WordEntry].self, from: data)
        } catch {
            print("No saved data found or failed to load: \(error.localizedDescription)")
        }
    }
    
    private func getFileURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
}



// content view
struct ContentView: View {
    @StateObject private var viewModel = WordListViewModel()
    
    var body: some View {
        TabView {
            AddWordView(viewModel: viewModel)
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }
            WordListView(viewModel: viewModel)
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
        }
    }
}

// ADD WORD TAB
struct AddWordView: View {
    @ObservedObject var viewModel: WordListViewModel
    @State private var word = ""
    @State private var explanation = ""
    @State private var showAlert = false
    
    @FocusState private var focusedField: FocusField?
    
    enum FocusField: Hashable {
        case word
        case explanation
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Word")) {
                    TextField("Word or Expression", text: $word)
                        .keyboardType(.default)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .word)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .explanation
                        }
                        .keyboardLanguage("it")
                    
                    TextField("Explanation or Translation", text: $explanation)
                        .keyboardType(.default)
                        .textInputAutocapitalization(.sentences)
                        .focused($focusedField, equals: .explanation)
                        .submitLabel(.done)
                        .onSubmit {
                            addWord()
                        }
                        .keyboardLanguage("en")
                }
                
                Button("Add") {
                    addWord()
                }
                .alert("Please fill in both fields!", isPresented: $showAlert) {
                    Button("OK", role: .cancel) { }
                }
            }
            .navigationTitle("Add Words")
        }
    }
    
    private func addWord() {
        guard !word.isEmpty && !explanation.isEmpty else {
            showAlert = true
            return
        }
        viewModel.addEntry(word: word, explanation: explanation)
        word = ""
        explanation = ""
        focusedField = nil // Dismiss keyboard
    }
}

// MARK: - WordListView
struct WordListView: View {
    @ObservedObject var viewModel: WordListViewModel
    @State private var searchText = ""
    @State private var selectedEntry: WordEntry?
    @State private var showExplanation = false
    
    var body: some View {
        NavigationView {
            VStack {
                // the search bar
                TextField("Search words", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                // filtered List
                List {
                    ForEach(filteredEntries) { entry in
                        HStack {
                            Text(entry.word)
                            Spacer()
                            Button(action: {
                                selectedEntry = entry
                                showExplanation = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .onDelete(perform: deleteEntry)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Word List")
            .alert(isPresented: $showExplanation) {
                Alert(
                    title: Text(selectedEntry?.word ?? "Unknown"),
                    message: Text(selectedEntry?.explanation ?? "No explanation available"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // filtered list on search query
    private var filteredEntries: [WordEntry] {
        if searchText.isEmpty {
            return viewModel.wordEntries
        } else {
            return viewModel.wordEntries.filter { entry in
                entry.word.lowercased().contains(searchText.lowercased()) ||
                entry.explanation.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    // delete entry from the list and update storage
    private func deleteEntry(at offsets: IndexSet) {
        viewModel.wordEntries.remove(atOffsets: offsets)
        viewModel.saveEntries()
    }
}



// expression's detail view
struct WordDetailView: View {
    let entry: WordEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(entry.word)
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(entry.explanation)
                .font(.body)
            Spacer()
        }
        .padding()
        .navigationTitle("Details")
    }
}


extension View {
    func keyboardLanguage(_ language: String) -> some View {
        self.environment(\.locale, Locale(identifier: language))
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

