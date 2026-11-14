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

    /// Tempo de espera depois de entrar no outro monitor antes de clicar.
    private let clickDelay: TimeInterval = 0.12

    private var enabled: Bool {
        get { UserDefaults.standard.bool(forKey: "enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "enabled"); refreshMenu() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["enabled": true])
        setupStatusItem()

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
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let versionItem = NSMenuItem(title: "Tella \(version)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)
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
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) { refreshMenu() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
