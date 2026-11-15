// Tella — o teclado acompanha o cursor entre o MacBook e os monitores externos, sem clique.
//
// Organização do código:
//   main.swift         abre o app (este arquivo)
//   AppDelegate.swift  estado, menu da barra de menus e ajustes
//   WindowFocus.swift  regras de qual janela recebe o teclado
//   Updates.swift      aviso de versão nova no GitHub
//   About.swift        janela "Sobre o Tella"
//   Support.swift      textos traduzidos, ícone, endereços e diagnóstico
import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // só ícone na barra de menus, sem ícone no Dock
app.run()
