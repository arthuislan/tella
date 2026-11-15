// Tella — estado do app, menu da barra de menus e ajustes.
import Cocoa
import ApplicationServices
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Estado

    var statusItem: NSStatusItem!
    var safetyTimer: Timer?
    var observerTimer: Timer?
    var updateTimer: Timer?
    var mouseMonitors: [Any] = []

    /// Tela onde o cursor estava na última verificação.
    var lastDisplay: CGDirectDisplayID?
    var lastMouse: CGPoint = .zero
    var lastTickTime: CFTimeInterval = 0
    var tickScheduled = false

    /// Janela livre (que nada cobre) onde o cursor está agora.
    var hoverWindowID: CGWindowID = 0
    var forceEvaluate = false

    var pendingHover: DispatchWorkItem?
    /// "Soltar" a janela quando o cursor sai dela para um espaço vazio.
    var pendingRelease: DispatchWorkItem?
    /// Ativação da 1.3 ao chegar na tela (só com "Ativar janela sob o cursor" desligado).
    var pendingArrival: DispatchWorkItem?
    var pendingMinimize: DispatchWorkItem?
    var observers: [pid_t: AXObserver] = [:]
    var windowListCache: (time: CFTimeInterval, list: [[String: Any]])?

    /// Versão nova encontrada no GitHub (nil = você já está na mais recente).
    var availableUpdate: ReleaseInfo?

    // MARK: - Tempos (em segundos)

    /// Intervalo mínimo entre duas verificações enquanto o mouse se move.
    let tickInterval: CFTimeInterval = 0.012
    /// Tempo que o cursor precisa ficar DENTRO de uma janela livre (mesmo se movendo) para ela
    /// receber o teclado — curto para parecer instantâneo, longo o bastante para ignorar
    /// janelas que o cursor só atravessa no caminho.
    let dwellDelay: TimeInterval = 0.045
    /// Tempo fora de uma janela flutuante (num espaço vazio) até ela deixar de estar selecionada.
    let releaseDelay: TimeInterval = 0.12
    /// Com "Ativar janela sob o cursor" desligado: espera ao chegar na tela (igual à 1.3).
    let classicArrivalDelay: TimeInterval = 0.12

    // MARK: - Itens do menu

    let toggleItem = NSMenuItem(title: L("menu.enabled"), action: #selector(toggleEnabled), keyEquivalent: "")
    let followItem = NSMenuItem(title: L("follow.menu"), action: #selector(toggleFollowCursor), keyEquivalent: "")
    let loginItem = NSMenuItem(title: L("menu.login"), action: #selector(toggleLogin), keyEquivalent: "")
    let permissionItem = NSMenuItem(title: L("perm.menu"), action: nil, keyEquivalent: "")
    let permStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    let updateItem = NSMenuItem(title: "", action: #selector(downloadUpdate), keyEquivalent: "")
    let autoUpdateItem = NSMenuItem(title: L("update.auto"), action: #selector(toggleAutoUpdate), keyEquivalent: "")

    // MARK: - Ajustes salvos

    var enabled: Bool {
        get { UserDefaults.standard.bool(forKey: "enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "enabled"); refreshMenu() }
    }
    /// Janela livre sob o cursor recebe o teclado (1.4). Desligado = comportamento da 1.3.
    var followCursor: Bool {
        get { UserDefaults.standard.bool(forKey: "followCursor") }
        set { UserDefaults.standard.set(newValue, forKey: "followCursor"); refreshMenu() }
    }
    var autoUpdate: Bool {
        get { UserDefaults.standard.bool(forKey: "autoCheckUpdates") }
        set { UserDefaults.standard.set(newValue, forKey: "autoCheckUpdates"); refreshMenu() }
    }

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    // MARK: - Início

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["enabled": true, "followCursor": true, "autoCheckUpdates": true])
        setupStatusItem()
        startUpdateChecks()

        // Pede a permissão de Acessibilidade (necessária para ativar janelas de outros apps).
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)

        lastDisplay = currentDisplay()
        startWindowFocus()
        startMinimizeObservers()
    }

    // MARK: - Menu

    func setupStatusItem() {
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

        for item in [toggleItem, followItem, loginItem] { item.target = self }
        menu.addItem(toggleItem)
        menu.addItem(followItem)
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

    func refreshMenu() {
        toggleItem.state = enabled ? .on : .off
        followItem.state = followCursor ? .on : .off
        followItem.isEnabled = enabled
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

    // MARK: - Ações do menu

    @objc func toggleEnabled() {
        enabled.toggle()
        resetFocusState()
        lastDisplay = currentDisplay()
    }

    @objc func toggleFollowCursor() {
        followCursor.toggle()
        resetFocusState()
    }

    @objc func toggleLogin() {
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
            bringTellaForward()
            alert.runModal()
        }
        refreshMenu()
    }

    @objc func openAccessibility() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Mostra de novo o aviso do macOS pedindo a permissão (e coloca o Tella na lista de Acessibilidade).
    @objc func requestAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
        refreshMenu()
    }

    /// Apaga a permissão antiga (útil depois de atualizar o app) e pede de novo.
    @objc func resetAccessibility() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        task.arguments = ["reset", "Accessibility", Bundle.main.bundleIdentifier ?? "local.tella"]
        try? task.run()
        task.waitUntilExit()
        requestAccessibility()
    }

    /// Abre o Finder com o Tella selecionado (para arrastar para a lista de Acessibilidade, se preciso).
    @objc func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) { refreshMenu() }
}
