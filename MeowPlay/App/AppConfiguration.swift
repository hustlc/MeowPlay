import Foundation

enum AppConfiguration {
    static let monthlyProductID = "com.meowplay.premium.monthly"
    static let annualProductID = "com.meowplay.premium.annual"
    static let productIDs: Set<String> = [monthlyProductID, annualProductID]


    static let privacyPolicyURL = URL(string: "https://meowplay-official.pages.dev/privacy.html")!
    static let termsURL = URL(string: "https://meowplay-official.pages.dev/terms.html")!
    static let supportURL = URL(string: "https://meowplay-official.pages.dev/support.html")!

    static let disclaimer = "Designed for entertainment and enrichment. This app does not translate animal language or provide veterinary or behavioral advice. Cats may respond differently."
}

