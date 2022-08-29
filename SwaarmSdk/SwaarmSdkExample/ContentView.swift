import SwaarmSdk
import SwiftUI

struct ContentView: View {
    var body: some View {
        SwaarmAnalytics.configure(token: "123456", host: "https://tracking-domain.com", debug: true)

        return Button(action: {
            SwaarmAnalytics.event(typeId: "2", aggregatedValue: 123, customValue: "cs")

        }) {
            Text("Trigger tracking event")
                .fontWeight(.regular)
                .foregroundColor(Color.red)
        }
        .frame(width: 200.0, height: 50.0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
