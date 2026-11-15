// Tella — aviso de versão nova. Consulta só a página pública de versões do Tella no GitHub,
// no máximo uma vez por dia. Nada sobre você ou o seu Mac é enviado.
import Cocoa

extension AppDelegate {
    /// Confere pouco depois de abrir e depois a cada 6 horas, se já passou um dia desde a última vez.
    func startUpdateChecks() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in self?.autoCheckIfDue() }
        let t = Timer(timeInterval: 6 * 3600, repeats: true) { [weak self] _ in self?.autoCheckIfDue() }
        RunLoop.main.add(t, forMode: .common)
        updateTimer = t
    }

    func autoCheckIfDue() {
        guard autoUpdate else { return }
        let last = UserDefaults.standard.object(forKey: "lastUpdateCheck") as? Date ?? .distantPast
        guard Date().timeIntervalSince(last) > 20 * 3600 else { return }
        checkForUpdates(manual: false)
    }

    @objc func checkForUpdatesNow() { checkForUpdates(manual: true) }

    @objc func toggleAutoUpdate() {
        autoUpdate.toggle()
        if autoUpdate { autoCheckIfDue() }
    }

    func checkForUpdates(manual: Bool) {
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

    func handleUpdateResult(_ release: ReleaseInfo?, manual: Bool) {
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

    func offerUpdate(_ release: ReleaseInfo) {
        let alert = NSAlert()
        alert.icon = NSApp.applicationIconImage
        alert.messageText = String(format: L("update.new.title"), release.version)
        alert.informativeText = String(format: L("update.new.body"), currentVersion)
        alert.addButton(withTitle: L("update.download"))
        alert.addButton(withTitle: L("update.later"))
        bringTellaForward()
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(release.download)
        }
    }

    @objc func downloadUpdate() {
        guard let release = availableUpdate else { return }
        NSWorkspace.shared.open(release.download)
    }

    func showAlert(title: String, text: String) {
        let alert = NSAlert()
        alert.icon = NSApp.applicationIconImage
        alert.messageText = title
        alert.informativeText = text
        bringTellaForward()
        alert.runModal()
    }
}
