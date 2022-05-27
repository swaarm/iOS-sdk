import SwiftUI
import SwaarmSdk

struct ContentView: View {
    var body: some View {

        SwaarmAnalytics.configure(config: SwaarmConfig(appToken: "123456", eventIngressHostname: "https://tracking-domain.com"))
        SwaarmAnalytics.debug(enable: true)
        
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
