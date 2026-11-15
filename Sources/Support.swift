// Tella — peças de apoio: textos traduzidos, ícone da barra de menus, endereços do projeto,
// leitura das versões publicadas e registro de diagnóstico.
import Cocoa
import ApplicationServices

/// Texto traduzido a partir de Resources/<idioma>.lproj/Localizable.strings (36 idiomas).
func L(_ key: String) -> String { NSLocalizedString(key, comment: "") }

/// Ícone da barra de menus: notebook à frente + tela extra atrás (mesmo desenho do ícone do app).
/// É uma imagem "template": o macOS pinta de preto no modo claro e de branco no modo escuro.
func makeMenuBarIcon() -> NSImage {
    let img = NSImage(size: NSSize(width: 21, height: 15), flipped: true) { _ in
        let screen = NSRect(x: 7.5, y: 1.5, width: 12.5, height: 9)    // tela extra
        let laptop = NSRect(x: 2, y: 5.1, width: 9, height: 6.6)       // tela do notebook
        let base = NSRect(x: 0.5, y: 11.7, width: 12, height: 1.6)     // base do notebook
        let gap: CGFloat = 1.1
        NSColor.black.setFill()
        NSBezierPath(roundedRect: screen, xRadius: 2, yRadius: 2).fill()
        // recorte que separa o notebook da tela de trás
        NSGraphicsContext.current?.compositingOperation = .clear
        NSBezierPath(roundedRect: laptop.insetBy(dx: -gap, dy: -gap), xRadius: 1.4 + gap, yRadius: 1.4 + gap).fill()
        NSBezierPath(roundedRect: base.insetBy(dx: -gap, dy: -gap), xRadius: 0.8 + gap, yRadius: 0.8 + gap).fill()
        NSGraphicsContext.current?.compositingOperation = .sourceOver
        NSBezierPath(roundedRect: laptop, xRadius: 1.4, yRadius: 1.4).fill()
        NSBezierPath(roundedRect: base, xRadius: 0.8, yRadius: 0.8).fill()
        return true
    }
    img.isTemplate = true
    img.accessibilityDescription = "Tella"
    return img
}

/// Traz o Tella para a frente (para a janela "Sobre", avisos, ou para "soltar" o teclado).
/// O macOS só deixa um app pegar o foco sozinho em casos especiais; pela Acessibilidade
/// (a mesma usada para ativar as outras janelas) funciona sempre.
func bringTellaForward() {
    AXUIElementSetAttributeValue(AXUIElementCreateApplication(ProcessInfo.processInfo.processIdentifier),
                                 kAXFrontmostAttribute as CFString, kCFBooleanTrue)
    if #available(macOS 14.0, *) {
        NSApp.activate()
    } else {
        NSApp.activate(ignoringOtherApps: true)
    }
}

/// Endereços do projeto no GitHub.
enum Project {
    static let developer = "Arthuislan"
    static let repo = "arthuislan/tella"
    static let page = URL(string: "https://github.com/\(repo)")!
    static let issues = URL(string: "https://github.com/\(repo)/issues")!
    static let latestReleaseAPI = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
}

/// Versão publicada mais recente no GitHub.
struct ReleaseInfo {
    let version: String
    let download: URL

    /// Lê a resposta de api.github.com/repos/<repo>/releases/latest.
    static func parse(_ data: Data) -> ReleaseInfo? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String,
              let pageString = json["html_url"] as? String,
              let page = URL(string: pageString) else { return nil }
        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let assets = json["assets"] as? [[String: Any]] ?? []
        let dmg = assets.first { ($0["name"] as? String)?.lowercased().hasSuffix(".dmg") == true }
        // Sem instalador anexado, abre a página da versão.
        let download = (dmg?["browser_download_url"] as? String).flatMap(URL.init(string:)) ?? page
        return ReleaseInfo(version: version, download: download)
    }

    /// Compara versões: "1.10" é mais nova que "1.9", "1.2.1" mais nova que "1.2",
    /// e "1.5" é mais nova que "1.5-beta" (uma versão de teste vem antes da final).
    static func isNewer(_ a: String, than b: String) -> Bool {
        func split(_ v: String) -> (numbers: [Int], preRelease: Bool) {
            let parts = v.split(separator: "-", maxSplits: 1)
            let numbers = (parts.first ?? "").split(separator: ".").map { piece in
                Int(piece.prefix(while: { $0.isNumber })) ?? 0
            }
            return (numbers, parts.count > 1)
        }
        let (na, preA) = split(a)
        let (nb, preB) = split(b)
        for i in 0..<max(na.count, nb.count) {
            let x = i < na.count ? na[i] : 0
            let y = i < nb.count ? nb[i] : 0
            if x != y { return x > y }
        }
        return preB && !preA
    }
}

/// Registro de diagnóstico, desligado por padrão. Só grava se existir o arquivo
/// ~/Documents/.tella-debug; o resultado vai para ~/Documents/tella-debug.log.
/// Serve para investigar um problema relatado — usuários normais nunca têm esse arquivo.
enum DebugLog {
    static let enabled = FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/.tella-debug")
    static let url = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/tella-debug.log")
    static let start = Date()

    static func write(_ text: @autoclosure () -> String) {
        guard enabled else { return }
        let line = String(format: "%8.3f  ", Date().timeIntervalSince(start)) + text() + "\n"
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            try? handle.close()
        } else {
            try? line.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
