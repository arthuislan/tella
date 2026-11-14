// Tella — ativa a janela da frente quando o cursor muda de monitor ou quando uma janela é minimizada (sem clicar).
import Cocoa
import ApplicationServices
import ServiceManagement

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

/// Texto traduzido (pt-BR, en, es) a partir de Resources/<idioma>.lproj/Localizable.strings.
func L(_ key: String) -> String { NSLocalizedString(key, comment: "") }

/// Endereços do projeto no GitHub.
enum Project {
    static let developer = "Arthuislan"
    static let repo = "arthuislan/tella"
    static let page = URL(string: "https://github.com/\(repo)")!
    static let issues = URL(string: "https://github.com/\(repo)/issues")!
    static let releases = URL(string: "https://github.com/\(repo)/releases")!
    static let latestReleaseAPI = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
}

/// Versão publicada mais recente no GitHub.
struct ReleaseInfo {
    let version: String
    let download: URL
    let page: URL

    /// Lê a resposta de api.github.com/repos/<repo>/releases/latest.
    static func parse(_ data: Data) -> ReleaseInfo? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String,
              let pageString = json["html_url"] as? String,
              let page = URL(string: pageString) else { return nil }
        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let assets = json["assets"] as? [[String: Any]] ?? []
        let dmg = assets.first { ($0["name"] as? String)?.lowercased().hasSuffix(".dmg") == true }
        let download = (dmg?["browser_download_url"] as? String).flatMap(URL.init(string:)) ?? page
        return ReleaseInfo(version: version, download: download, page: page)
    }

    /// Compara versões numéricas: "1.10" é mais nova que "1.9", "1.2.1" mais nova que "1.2".
    static func isNewer(_ a: String, than b: String) -> Bool {
        let pa = a.split(separator: ".").map { Int($0) ?? 0 }
        let pb = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0
            let y = i < pb.count ? pb[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var lastDisplay: CGDirectDisplayID?
    private var pendingClick: DispatchWorkItem?
    private var pendingMinimize: DispatchWorkItem?
    private var observers: [pid_t: AXObserver] = [:]
    private var observerTimer: Timer?

    private let toggleItem = NSMenuItem(title: L("menu.enabled"), action: #selector(toggleEnabled), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: L("menu.login"), action: #selector(toggleLogin), keyEquivalent: "")
    private let permissionItem = NSMenuItem(title: L("perm.menu"), action: nil, keyEquivalent: "")
    private let permStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let updateItem = NSMenuItem(title: "", action: #selector(downloadUpdate), keyEquivalent: "")
    private let autoUpdateItem = NSMenuItem(title: L("update.auto"), action: #selector(toggleAutoUpdate), keyEquivalent: "")
    private var updateTimer: Timer?
    /// Versão nova encontrada no GitHub (nil = você já está na mais recente).
    private var availableUpdate: ReleaseInfo?

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
    private var autoUpdate: Bool {
        get { UserDefaults.standard.bool(forKey: "autoCheckUpdates") }
        set { UserDefaults.standard.set(newValue, forKey: "autoCheckUpdates"); refreshMenu() }
    }

    /// Tempo de espera depois de entrar no outro monitor antes de clicar.
    private let clickDelay: TimeInterval = 0.12

    private var enabled: Bool {
        get { UserDefaults.standard.bool(forKey: "enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "enabled"); refreshMenu() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["enabled": true, "autoCheckUpdates": true])
        setupStatusItem()
        startUpdateChecks()

        // Pede a permissão de Acessibilidade (necessária para simular cliques).
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)

        lastDisplay = currentDisplay()

        // Se um monitor for ligado/desligado, só atualiza a referência (sem clicar).
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.pendingClick?.cancel()
            self?.lastDisplay = self?.currentDisplay()
        }

        let t = Timer(timeInterval: 0.03, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t

        // Minimizar janela: observa os apps abertos (e os que forem abertos depois).
        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { [weak self] n in
            guard let app = n.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self?.observe(app) }
        }
        ws.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { [weak self] n in
            guard let app = n.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self?.stopObserving(app.processIdentifier)
        }
        observeAllApps()
        // Tenta de novo de tempos em tempos (ex.: logo após liberar a Acessibilidade).
        let ot = Timer(timeInterval: 5, repeats: true) { [weak self] _ in self?.observeAllApps() }
        RunLoop.main.add(ot, forMode: .common)
        observerTimer = ot
    }

    // MARK: - Janela minimizada

    private func observeAllApps() {
        guard AXIsProcessTrusted() else { return }
        for app in NSWorkspace.shared.runningApplications { observe(app) }
    }

    private func observe(_ app: NSRunningApplication) {
        let pid = app.processIdentifier
        guard app.activationPolicy == .regular,
              pid != ProcessInfo.processInfo.processIdentifier,
              observers[pid] == nil, AXIsProcessTrusted() else { return }

        let callback: AXObserverCallback = { _, element, _, refcon in
            guard let refcon = refcon else { return }
            Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue().windowMinimized(element)
        }
        var obs: AXObserver?
        guard AXObserverCreate(pid, callback, &obs) == .success, let observer = obs else { return }
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard AXObserverAddNotification(observer, AXUIElementCreateApplication(pid),
                                        kAXWindowMiniaturizedNotification as CFString, refcon) == .success else { return }
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        observers[pid] = observer
    }

    private func stopObserving(_ pid: pid_t) {
        guard let observer = observers.removeValue(forKey: pid) else { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
    }

    /// Uma janela foi minimizada: ativa na hora a janela que ficou na frente na tela do cursor,
    /// ignorando a que está sendo minimizada (não precisa esperar a animação).
    fileprivate func windowMinimized(_ minimizedWindow: AXUIElement) {
        guard enabled else { return }
        pendingMinimize?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.enabled, let display = self.currentDisplay() else { return }
            self.activateFrontWindow(on: display, excluding: minimizedWindow)
        }
        pendingMinimize = work
        // Quase instantâneo; a segunda tentativa só garante caso o app reative a própria janela.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { if !work.isCancelled { work.perform() } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { if !work.isCancelled { work.perform() } }
    }

    // MARK: - Lógica principal

    private func cursorLocation() -> CGPoint? {
        CGEvent(source: nil)?.location   // coordenadas globais (origem no topo-esquerdo)
    }

    private func currentDisplay() -> CGDirectDisplayID? {
        guard let p = cursorLocation() else { return nil }
        var id: CGDirectDisplayID = 0
        var count: UInt32 = 0
        guard CGGetDisplaysWithPoint(p, 1, &id, &count) == .success, count > 0 else { return nil }
        return id
    }

    private func tick() {
        guard let display = currentDisplay() else { return }
        guard display != lastDisplay else { return }
        lastDisplay = display

        pendingClick?.cancel()
        guard enabled else { return }
        // Não clica se você estiver arrastando algo entre monitores.
        guard NSEvent.pressedMouseButtons == 0 else { return }

        let work = DispatchWorkItem { [weak self] in
            guard let self = self,
                  self.currentDisplay() == display,
                  NSEvent.pressedMouseButtons == 0 else { return }
            self.activateFrontWindow(on: display)
        }
        pendingClick = work
        DispatchQueue.main.asyncAfter(deadline: .now() + clickDelay, execute: work)
    }

    /// Ativa a janela que já está na frente no monitor, sem clicar em nada
    /// (nenhuma janela de trás vem para a frente).
    private func activateFrontWindow(on display: CGDirectDisplayID, excluding: AXUIElement? = nil) {
        let screen = CGDisplayBounds(display)
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements],
                                                    kCGNullWindowID) as? [[String: Any]] else { return }
        let myPID = ProcessInfo.processInfo.processIdentifier

        // A lista vem da janela mais à frente para a mais atrás.
        for info in list {
            guard (info[kCGWindowLayer as String] as? Int) == 0,
                  let pid = info[kCGWindowOwnerPID as String] as? pid_t, pid != myPID,
                  let dict = info[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: dict),
                  rect.width > 50, rect.height > 50,
                  (info[kCGWindowAlpha as String] as? Double ?? 1) > 0,
                  screen.contains(CGPoint(x: rect.midX, y: rect.midY)) else { continue }
            if focus(pid: pid, frame: rect, excluding: excluding) { return }
        }
    }

    /// Retorna false se a janela não serve (minimizada, ou é a que está sendo minimizada) — aí tenta a próxima.
    @discardableResult
    private func focus(pid: pid_t, frame: CGRect, excluding: AXUIElement? = nil) -> Bool {
        let axApp = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        var target: AXUIElement?
        if AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &value) == .success,
           let windows = value as? [AXUIElement] {
            target = windows.first { w in
                guard let f = axFrame(w) else { return false }
                return abs(f.minX - frame.minX) < 3 && abs(f.minY - frame.minY) < 3 &&
                       abs(f.width - frame.width) < 3 && abs(f.height - frame.height) < 3
            }
        }
        if let w = target {
            if let ex = excluding, CFEqual(w, ex) { return false }
            var minimized: CFTypeRef?
            if AXUIElementCopyAttributeValue(w, kAXMinimizedAttribute as CFString, &minimized) == .success,
               (minimized as? Bool) == true { return false }
            AXUIElementSetAttributeValue(w, kAXMainAttribute as CFString, kCFBooleanTrue)
            AXUIElementSetAttributeValue(axApp, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
            AXUIElementPerformAction(w, kAXRaiseAction as CFString)
        } else {
            // Ao minimizar, uma janela sem correspondência é a que está animando: pula.
            if excluding != nil { return false }
            AXUIElementSetAttributeValue(axApp, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
        }
        return true
    }

    private func axFrame(_ w: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(w, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(w, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posRef, let sizeRef,
              CFGetTypeID(posRef) == AXValueGetTypeID(),
              CFGetTypeID(sizeRef) == AXValueGetTypeID() else { return nil }
        var pos = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posRef as! AXValue, .cgPoint, &pos)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        return CGRect(origin: pos, size: size)
    }

    // MARK: - Menu

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = makeMenuBarIcon()

        let menu = NSMenu()
        menu.delegate = self
        let aboutItem = NSMenuItem(title: L("about.menu"), action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        updateItem.target = self
        updateItem.isHidden = true
        menu.addItem(updateItem)
        menu.addItem(.separator())
        for item in [toggleItem, loginItem] { item.target = self }
        menu.addItem(toggleItem)
        menu.addItem(loginItem)
        menu.addItem(.separator())

        // Submenu "Permissão": sempre visível, para quem não encontra a Acessibilidade nos Ajustes.
        let permMenu = NSMenu()
        permStatusItem.isEnabled = false
        permMenu.addItem(permStatusItem)
        permMenu.addItem(.separator())
        for (key, action) in [("perm.open", #selector(openAccessibility)),
                              ("perm.request", #selector(requestAccessibility)),
                              ("perm.reset", #selector(resetAccessibility)),
                              ("perm.reveal", #selector(revealInFinder))] {
            let item = NSMenuItem(title: L(key), action: action, keyEquivalent: "")
            item.target = self
            permMenu.addItem(item)
        }
        permissionItem.submenu = permMenu
        menu.addItem(permissionItem)
        menu.addItem(.separator())

        let checkItem = NSMenuItem(title: L("update.check"), action: #selector(checkForUpdatesNow), keyEquivalent: "")
        checkItem.target = self
        autoUpdateItem.target = self
        menu.addItem(checkItem)
        menu.addItem(autoUpdateItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: L("menu.quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        refreshMenu()
    }

    private func refreshMenu() {
        toggleItem.state = enabled ? .on : .off
        loginItem.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        let trusted = AXIsProcessTrusted()
        permStatusItem.title = trusted ? "✓ " + L("perm.ok") : "⚠︎ " + L("perm.missing")
        permissionItem.title = trusted ? L("perm.menu") : "⚠︎ " + L("perm.menu")
        statusItem?.button?.appearsDisabled = !enabled
        autoUpdateItem.state = autoUpdate ? .on : .off
        if let update = availableUpdate {
            updateItem.title = "⬇︎ " + String(format: L("update.available"), update.version)
            updateItem.isHidden = false
        } else {
            updateItem.isHidden = true
        }
    }

    @objc private func toggleEnabled() {
        enabled.toggle()
        pendingClick?.cancel()
        lastDisplay = currentDisplay()
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = L("alert.login.title")
            alert.informativeText = L("alert.login.body") + "\n\n" + error.localizedDescription
            alert.runModal()
        }
        refreshMenu()
    }

    @objc private func openAccessibility() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Mostra de novo o aviso do macOS pedindo a permissão (e coloca o Tella na lista de Acessibilidade).
    @objc private func requestAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
        refreshMenu()
    }

    /// Apaga a permissão antiga (útil depois de atualizar o app) e pede de novo.
    @objc private func resetAccessibility() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        task.arguments = ["reset", "Accessibility", Bundle.main.bundleIdentifier ?? "local.tella"]
        try? task.run()
        task.waitUntilExit()
        requestAccessibility()
    }

    /// Abre o Finder com o Tella selecionado (para arrastar para a lista de Acessibilidade, se preciso).
    @objc private func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    // MARK: - Sobre o Tella

    /// Janela "Sobre" padrão do macOS: ícone, nome, versão, créditos e direitos autorais.
    @objc private func showAbout() {
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

        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Tella",
            .applicationVersion: currentVersion,
            .version: buildNumber,
            .credits: credits,
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2026 \(Project.developer)"
        ])
    }

    // MARK: - Atualizações

    /// Confere no GitHub, pouco depois de abrir e depois a cada 6 horas,
    /// se já passou um dia desde a última verificação automática.
    private func startUpdateChecks() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in self?.autoCheckIfDue() }
        let t = Timer(timeInterval: 6 * 3600, repeats: true) { [weak self] _ in self?.autoCheckIfDue() }
        RunLoop.main.add(t, forMode: .common)
        updateTimer = t
    }

    private func autoCheckIfDue() {
        guard autoUpdate else { return }
        let last = UserDefaults.standard.object(forKey: "lastUpdateCheck") as? Date ?? .distantPast
        guard Date().timeIntervalSince(last) > 20 * 3600 else { return }
        checkForUpdates(manual: false)
    }

    @objc private func checkForUpdatesNow() { checkForUpdates(manual: true) }

    @objc private func toggleAutoUpdate() {
        autoUpdate.toggle()
        if autoUpdate { autoCheckIfDue() }
    }

    /// Consulta só a página pública de versões do Tella no GitHub. Nada sobre você ou o seu Mac é enviado.
    private func checkForUpdates(manual: Bool) {
        var request = URLRequest(url: Project.latestReleaseAPI,
                                 cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Tella/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            let ok = (response as? HTTPURLResponse)?.statusCode == 200
            let release = ok ? data.flatMap(ReleaseInfo.parse) : nil
            DispatchQueue.main.async { self?.handleUpdateResult(release, manual: manual) }
        }.resume()
    }

    private func handleUpdateResult(_ release: ReleaseInfo?, manual: Bool) {
        guard let release = release else {
            if manual { showAlert(title: L("update.error.title"), text: L("update.error.body")) }
            return
        }
        UserDefaults.standard.set(Date(), forKey: "lastUpdateCheck")

        guard ReleaseInfo.isNewer(release.version, than: currentVersion) else {
            availableUpdate = nil
            refreshMenu()
            if manual {
                showAlert(title: L("update.uptodate.title"),
                          text: String(format: L("update.uptodate.body"), currentVersion))
            }
            return
        }

        availableUpdate = release
        refreshMenu()
        // Na verificação automática, avisa só uma vez por versão; depois fica o item no menu.
        let notified = UserDefaults.standard.string(forKey: "notifiedUpdateVersion")
        if manual || notified != release.version {
            UserDefaults.standard.set(release.version, forKey: "notifiedUpdateVersion")
            offerUpdate(release)
        }
    }

    private func offerUpdate(_ release: ReleaseInfo) {
        let alert = NSAlert()
        alert.icon = NSApp.applicationIconImage
        alert.messageText = String(format: L("update.new.title"), release.version)
        alert.informativeText = String(format: L("update.new.body"), currentVersion)
        alert.addButton(withTitle: L("update.download"))
        alert.addButton(withTitle: L("update.later"))
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(release.download)
        }
    }

    @objc private func downloadUpdate() {
        guard let release = availableUpdate else { return }
        NSWorkspace.shared.open(release.download)
    }

    private func showAlert(title: String, text: String) {
        let alert = NSAlert()
        alert.icon = NSApp.applicationIconImage
        alert.messageText = title
        alert.informativeText = text
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) { refreshMenu() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
