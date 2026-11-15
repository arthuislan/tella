// Tella — regras de qual janela recebe o teclado.
//
// 1. "Ativar janela sob o cursor" ligado (padrão): uma janela livre — que nada cobre, flutuando
//    por cima das outras ou lado a lado — só recebe o teclado quando o CURSOR a escolhe, isto é,
//    quando entra nela. Em qualquer tela e mesa, sem clique. Quando o cursor SAI dela para um espaço
//    vazio (ou para cima de uma janela de trás), ela deixa de estar selecionada: nenhuma janela fica
//    ativa até o cursor escolher outra. Barra de menus, menus e Dock não mudam nada.
// 2. Desligado (comportamento clássico da 1.3): ao chegar de outro monitor, a janela da frente
//    daquela tela recebe o teclado.
// 3. Janela minimizada: a janela que ficou na frente recebe o teclado na hora.
//
// Sempre: nenhuma janela muda de lugar, e uma janela de trás nunca vem para a frente.
import Cocoa
import ApplicationServices

extension AppDelegate {

    // MARK: - Início

    func startWindowFocus() {
        // O macOS avisa quando o mouse se move: sem mouse andando, o Tella não gasta nada.
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        if let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] _ in self?.mouseMoved() }) {
            mouseMonitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.mouseMoved(); return event
        }) {
            mouseMonitors.append(local)
        }
        // Rede de segurança lenta, para casos em que o cursor muda de lugar sem evento de mouse.
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        safetyTimer = t

        // Monitor ligado/desligado: só atualiza a referência, sem ativar nada.
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.resetFocusState()
            self?.lastDisplay = self?.currentDisplay()
        }

        // Trocou de mesa (Space): trata como uma chegada; avalia depois da animação.
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self = self, self.enabled else { return }
            self.resetFocusState()
            self.forceEvaluate = true
            DebugLog.write("TROCOU DE MESA")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.tick() }
        }
    }

    /// Cancela qualquer ativação pendente.
    func resetFocusState() {
        pendingHover?.cancel()
        pendingArrival?.cancel()
        pendingRelease?.cancel()
        pendingRelease = nil
        hoverWindowID = 0
    }

    // MARK: - Cursor e telas

    func cursorLocation() -> CGPoint? {
        CGEvent(source: nil)?.location   // coordenadas globais (origem no topo-esquerdo)
    }

    func currentDisplay() -> CGDirectDisplayID? {
        guard let p = cursorLocation() else { return nil }
        var id: CGDirectDisplayID = 0
        var count: UInt32 = 0
        guard CGGetDisplaysWithPoint(p, 1, &id, &count) == .success, count > 0 else { return nil }
        return id
    }

    /// Chamado a cada movimento do mouse. Mouses rápidos geram centenas de eventos por segundo:
    /// verifica no máximo a cada 12 ms, e sempre faz uma última verificação no fim do movimento.
    func mouseMoved() {
        let now = CACurrentMediaTime()
        let elapsed = now - lastTickTime
        if elapsed >= tickInterval {
            tick()
        } else if !tickScheduled {
            tickScheduled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + (tickInterval - elapsed)) { [weak self] in
                self?.tickScheduled = false
                self?.tick()
            }
        }
    }

    func tick() {
        lastTickTime = CACurrentMediaTime()
        guard let display = currentDisplay() else { return }
        guard display != lastDisplay else {
            trackHover(on: display)
            return
        }
        lastDisplay = display
        resetFocusState()
        // Arrastando algo entre monitores? Não faz nada.
        guard enabled, NSEvent.pressedMouseButtons == 0 else { return }
        forceEvaluate = true
        DebugLog.write("CHEGOU na tela \(display)")

        if followCursor {
            trackHover(on: display)
        } else {
            // Comportamento da 1.3: ativa a janela da frente logo ao chegar.
            let work = DispatchWorkItem { [weak self] in
                guard let self = self, self.currentDisplay() == display,
                      NSEvent.pressedMouseButtons == 0 else { return }
                self.activateFrontWindow(on: display)
            }
            pendingArrival = work
            DispatchQueue.main.asyncAfter(deadline: .now() + classicArrivalDelay, execute: work)
        }
    }

    // MARK: - Janela sob o cursor

    /// - entrou numa janela que NADA cobre e ficou nela um instante (mesmo se movendo) → ela recebe
    ///   o teclado. Ela já está na frente, então nenhuma janela muda de lugar nem de camada;
    /// - saiu para um espaço vazio ou para cima de uma janela parcialmente atrás de outra → a janela
    ///   deixa de estar selecionada (nenhuma janela ativa) até o cursor escolher outra;
    /// - barra de menus, menus, Dock e avisos → nada muda.
    func trackHover(on display: CGDirectDisplayID) {
        guard enabled, followCursor else { return }   // desligado: só a chegada da 1.3 (em tick)
        guard let p = cursorLocation() else { return }
        // Tremidinhas de 1–2 pixels (trackpad) não contam como movimento.
        guard abs(p.x - lastMouse.x) > 2 || abs(p.y - lastMouse.y) > 2 || forceEvaluate else { return }
        forceEvaluate = false
        lastMouse = p
        guard NSEvent.pressedMouseButtons == 0 else {
            pendingHover?.cancel()
            hoverWindowID = 0
            return
        }

        let under = whatIsUnderCursor(at: p, on: display)
        if case .free(let window) = under {
            pendingRelease?.cancel()
            guard window.id != hoverWindowID else { return }   // continua na mesma janela
            hoverWindowID = window.id
            pendingHover?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self = self, self.enabled, self.hoverWindowID == window.id,
                      self.currentDisplay() == display,
                      NSEvent.pressedMouseButtons == 0 else { return }
                if NSWorkspace.shared.frontmostApplication?.processIdentifier == window.pid,
                   let focused = self.focusedWindowFrame(), self.sameFrame(focused, window.frame) {
                    return   // já é a janela ativa
                }
                DebugLog.write("ATIVA \(NSRunningApplication(processIdentifier: window.pid)?.localizedName ?? "?") \(window.frame)")
                // Ela já está na frente: não precisa "levantar" — só passar o teclado para ela.
                self.focus(pid: window.pid, frame: window.frame, raise: false)
            }
            pendingHover = work
            DispatchQueue.main.asyncAfter(deadline: .now() + dwellDelay, execute: work)
            return
        }

        // Fora de uma janela livre.
        hoverWindowID = 0
        pendingHover?.cancel()
        guard case .gap = under else {
            pendingRelease?.cancel()   // menus, Dock, barra de menus: não mexe em nada
            return
        }
        // Saiu da janela flutuante para um espaço vazio (ou para cima de uma janela de trás):
        // a janela deixa de estar selecionada, como se o cursor a "soltasse". Um instante de espera
        // evita soltar ao só atravessar o vãozinho entre duas janelas lado a lado.
        if let pending = pendingRelease, !pending.isCancelled { return }   // já vai soltar
        let release = DispatchWorkItem { [weak self] in
            self?.pendingRelease = nil
            guard let self = self, self.enabled, self.followCursor,
                  self.currentDisplay() == display,
                  NSEvent.pressedMouseButtons == 0,
                  let p = self.cursorLocation(),
                  case .gap = self.whatIsUnderCursor(at: p, on: display) else { return }
            self.releaseKeyboard()
        }
        pendingRelease = release
        DispatchQueue.main.asyncAfter(deadline: .now() + releaseDelay, execute: release)
    }

    /// Nenhuma janela fica selecionada: o teclado passa para o Tella, que não tem janelas.
    /// Nada muda de lugar; as janelas só aparecem como inativas até o cursor escolher outra.
    func releaseKeyboard() {
        let myPID = ProcessInfo.processInfo.processIdentifier
        guard !panelInUse(),
              NSWorkspace.shared.frontmostApplication?.processIdentifier != myPID else { return }
        DebugLog.write("SOLTA: nenhuma janela selecionada")
        bringTellaForward()
    }

    // MARK: - Lista de janelas

    /// Janela comum (camada 0) visível numa tela.
    struct VisibleWindow {
        let id: CGWindowID
        let pid: pid_t
        let frame: CGRect
    }

    /// Lista de janelas do macOS, da mais à frente para a mais atrás. Enquanto o mouse se move,
    /// a mesma lista é reaproveitada por 40 ms para não pedir ao macOS a cada passo.
    func onScreenWindowList(fresh: Bool = false) -> [[String: Any]] {
        let now = CACurrentMediaTime()
        if !fresh, let cache = windowListCache, now - cache.time < 0.04 { return cache.list }
        let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements],
                                              kCGNullWindowID) as? [[String: Any]] ?? []
        windowListCache = (now, list)
        return list
    }

    /// Janelas comuns da tela, da mais à frente para a mais atrás. Inclui as do próprio Tella
    /// (como a janela "Sobre"): elas nunca são ativadas, mas contam como "por cima" de outras.
    func windows(on display: CGDirectDisplayID, from list: [[String: Any]]) -> [VisibleWindow] {
        let screen = CGDisplayBounds(display)
        return list.compactMap { info in
            guard (info[kCGWindowLayer as String] as? Int) == 0,
                  let pid = info[kCGWindowOwnerPID as String] as? pid_t,
                  let dict = info[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: dict),
                  rect.width > 50, rect.height > 50,
                  (info[kCGWindowAlpha as String] as? Double ?? 1) > 0,
                  screen.contains(CGPoint(x: rect.midX, y: rect.midY)) else { return nil }
            let id = (info[kCGWindowNumber as String] as? NSNumber)?.uint32Value ?? 0
            return VisibleWindow(id: id, pid: pid, frame: rect)
        }
    }

    /// Duas áreas só contam como "sobrepostas" se a parte em comum passar de alguns pixels
    /// (janelas lado a lado costumam encostar uma na outra).
    func overlaps(_ a: CGRect, _ b: CGRect) -> Bool {
        let i = a.intersection(b)
        return !i.isNull && i.width > 8 && i.height > 8
    }

    func sameFrame(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) < 3 && abs(a.minY - b.minY) < 3 &&
        abs(a.width - b.width) < 3 && abs(a.height - b.height) < 3
    }

    /// O que está embaixo do cursor.
    enum UnderCursor {
        /// Janela livre: nada está por cima dela — pode receber o teclado sem clique.
        case free(VisibleWindow)
        /// Espaço vazio da mesa, ou uma janela parcialmente atrás de outra
        /// (ex.: o espaço entre o Finder e o Terminal, com outra janela atrás).
        case gap
        /// Menus, barra de menus, Dock, avisos ou janelas do Tella: não mexe em nada.
        case interface
    }

    func whatIsUnderCursor(at p: CGPoint, on display: CGDirectDisplayID) -> UnderCursor {
        let all = onScreenWindowList()

        // O que está no topo, embaixo do cursor? (inclui o próprio menu do Tella)
        let top = all.first { info in
            guard let dict = info[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: dict),
                  (info[kCGWindowAlpha as String] as? Double ?? 1) > 0 else { return false }
            return rect.contains(p)
        }
        if let top = top, (top[kCGWindowLayer as String] as? Int) != 0,
           let dict = top[kCGWindowBounds as String] as? NSDictionary,
           let rect = CGRect(dictionaryRepresentation: dict) {
            // Camadas invisíveis do tamanho da tela (de outros apps) não contam; menus, Dock e avisos sim.
            let screen = CGDisplayBounds(display)
            let coversScreen = rect.width >= screen.width * 0.9 && rect.height >= screen.height * 0.9
            if !coversScreen { return .interface }
        }
        // Faixa da barra de menus (mesmo quando ela se esconde): é por onde se chega aos menus.
        if p.y < CGDisplayBounds(display).minY + 40 { return .interface }

        let list = windows(on: display, from: all)
        guard let index = list.firstIndex(where: { $0.frame.contains(p) }) else { return .gap }   // mesa vazia
        let candidate = list[index]
        if candidate.pid == ProcessInfo.processInfo.processIdentifier { return .interface }      // janela do Tella
        // Alguma janela por cima dela? Então ativá-la a traria para a frente: não faz nada.
        if list[..<index].contains(where: { overlaps($0.frame, candidate.frame) }) { return .gap }
        return .free(candidate)
    }

    // MARK: - Ativar janelas

    /// Spotlight, Raycast, Alfred, avisos e janelas do próprio Tella (como "Sobre o Tella"): enquanto
    /// um deles está aberto, o Tella não troca de janela (senão ele fecharia ou ficaria escondido).
    func panelInUse() -> Bool {
        let regularApps = Set(NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .map { $0.processIdentifier })
        let myPID = ProcessInfo.processInfo.processIdentifier
        for info in onScreenWindowList(fresh: true) {
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t, !regularApps.contains(pid),
                  let layer = info[kCGWindowLayer as String] as? Int,
                  layer > 0 || pid == myPID,                                 // janelas do Tella contam sempre
                  layer != 20, layer != 24, layer != 25,                     // Dock, barra de menus e ícones dela
                  (info[kCGWindowOwnerName as String] as? String).map({ $0 != "Window Server" && $0 != "Dock" }) ?? true,
                  (info[kCGWindowAlpha as String] as? Double ?? 1) > 0.05,
                  let dict = info[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: dict),
                  rect.width > 200, rect.height > 40 else { continue }
            // Camadas invisíveis do tamanho da tela inteira não são painéis.
            let coversScreen = NSScreen.screens.contains { screen in
                let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
                let b = CGDisplayBounds(id)
                return rect.width >= b.width * 0.9 && rect.height >= b.height * 0.9
            }
            if !coversScreen {
                DebugLog.write("painel aberto: \(info[kCGWindowOwnerName as String] ?? "?") camada \(layer) — não troca")
                return true
            }
        }
        return false
    }

    /// Ativa a janela que já está na frente na tela, sem clicar em nada
    /// (nenhuma janela de trás vem para a frente).
    func activateFrontWindow(on display: CGDirectDisplayID, excluding: AXUIElement? = nil) {
        let myPID = ProcessInfo.processInfo.processIdentifier
        for window in windows(on: display, from: onScreenWindowList(fresh: true)) where window.pid != myPID {
            if focus(pid: window.pid, frame: window.frame, excluding: excluding) { return }
        }
    }

    /// Passa o teclado para a janela. Retorna false se ela não serve (minimizada, ou é a que está
    /// sendo minimizada) — aí quem chamou tenta a próxima.
    @discardableResult
    func focus(pid: pid_t, frame: CGRect, excluding: AXUIElement? = nil, raise: Bool = true) -> Bool {
        if panelInUse() { return true }
        let axApp = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        var target: AXUIElement?
        if AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &value) == .success,
           let windows = value as? [AXUIElement] {
            target = windows.first { w in
                guard let f = axFrame(w) else { return false }
                return sameFrame(f, frame)
            }
        }
        if let w = target {
            if let ex = excluding, CFEqual(w, ex) { return false }
            var minimized: CFTypeRef?
            if AXUIElementCopyAttributeValue(w, kAXMinimizedAttribute as CFString, &minimized) == .success,
               (minimized as? Bool) == true { return false }
            AXUIElementSetAttributeValue(w, kAXMainAttribute as CFString, kCFBooleanTrue)
            AXUIElementSetAttributeValue(axApp, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
            if raise { AXUIElementPerformAction(w, kAXRaiseAction as CFString) }
        } else {
            // Ao minimizar, uma janela sem correspondência é a que está animando: pula.
            if excluding != nil { return false }
            AXUIElementSetAttributeValue(axApp, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
        }
        return true
    }

    /// Moldura da janela que está recebendo o teclado agora.
    func focusedWindowFrame() -> CGRect? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return axFrame(value as! AXUIElement)
    }

    func axFrame(_ w: AXUIElement) -> CGRect? {
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

    // MARK: - Janela minimizada

    func startMinimizeObservers() {
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
        let t = Timer(timeInterval: 5, repeats: true) { [weak self] _ in self?.observeAllApps() }
        RunLoop.main.add(t, forMode: .common)
        observerTimer = t
    }

    func observeAllApps() {
        guard AXIsProcessTrusted() else { return }
        for app in NSWorkspace.shared.runningApplications { observe(app) }
    }

    func observe(_ app: NSRunningApplication) {
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

    func stopObserving(_ pid: pid_t) {
        guard let observer = observers.removeValue(forKey: pid) else { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
    }

    /// Uma janela foi minimizada: ativa na hora a janela que ficou na frente na tela do cursor,
    /// ignorando a que está sendo minimizada (não precisa esperar a animação).
    func windowMinimized(_ minimizedWindow: AXUIElement) {
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
}
