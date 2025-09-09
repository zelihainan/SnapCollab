import SwiftUI

struct SecureTextFieldWithToggle: View {
    let placeholder: String
    @Binding var text: String
    @State private var isSecured = true
    
    var body: some View {
        ZStack(alignment: .trailing) {
            if isSecured {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
            
            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: isSecured ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding(.trailing, 12)
        }
    }
}
