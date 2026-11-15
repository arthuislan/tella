// Tella — janela "Sobre o Tella".
import Cocoa

extension AppDelegate {
    /// Janela "Sobre" padrão do macOS: ícone, nome, versão, créditos e direitos autorais.
    @objc func showAbout() {
        let center = NSMutableParagraphStyle()
        center.alignment = .center
        center.paragraphSpacing = 6
        let small = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let body: [NSAttributedString.Key: Any] = [
            .font: small, .foregroundColor: NSColor.labelColor, .paragraphStyle: center
        ]
        let muted: [NSAttributedString.Key: Any] = [
            .font: small, .foregroundColor: NSColor.secondaryLabelColor, .paragraphStyle: center
        ]
        func link(_ title: String, _ url: URL) -> NSAttributedString {
            NSAttributedString(string: title, attributes: [.font: small, .link: url, .paragraphStyle: center])
        }

        let credits = NSMutableAttributedString()
        credits.append(NSAttributedString(string: String(format: L("about.developer"), Project.developer) + "\n", attributes: body))
        credits.append(NSAttributedString(string: L("about.thanks") + "\n\n", attributes: body))
        credits.append(link(L("about.website"), Project.page))
        credits.append(NSAttributedString(string: "   ·   ", attributes: muted))
        credits.append(link(L("about.issue"), Project.issues))
        credits.append(NSAttributedString(string: "\n\n" + L("about.license"), attributes: muted))

        bringTellaForward()
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Tella",
            .applicationVersion: currentVersion,
            .version: buildNumber,
            .credits: credits,
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2026 \(Project.developer)"
        ])
    }
}
