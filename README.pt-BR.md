<p align="center">
  <img src="docs/images/icon.png" alt="Ícone do Tella" width="128">
</p>

<h1 align="center">Tella</h1>

<p align="center">
  <b>O teclado acompanha o seu cursor entre o MacBook e os monitores externos, sem clicar.</b>
</p>

<p align="center">
  <a href="README.md">English</a> · <b>Português</b> · <a href="README.es.md">Español</a>
</p>

<p align="center">
  <a href="https://github.com/arthuislan/tella/releases/latest/download/Tella.dmg"><b>⬇︎ Baixar Tella.dmg</b></a>
  &nbsp;·&nbsp; macOS 13+ · Apple Silicon
</p>

<p align="center">
  <img src="docs/images/cover.png" alt="Tella — o teclado acompanha o seu cursor entre o MacBook e a tela extra" width="100%">
</p>

**Tella** é um pequeno app para Mac, feito para quem trabalha com **MacBook e um ou mais monitores externos**. Quando você leva o cursor para outra tela, o Tella ativa automaticamente a janela que está na frente nessa tela. Assim, você já pode digitar nela **sem precisar clicar**.

Ele fica discreto na barra de menus, não abre janelas, não muda nada de lugar e não clica em nada.

---

## O problema

No macOS, o teclado sempre vai para o **app ativo**, e o app só fica ativo quando você clica nele. Mover o cursor não basta. Com mais de uma tela, isso gera duas situações chatas do dia a dia.

### 1. O teclado fica preso na outra tela

Você está no navegador do monitor externo, leva o cursor para o MacBook e começa a digitar uma nota. O texto vai parar na barra de endereço do navegador, na outra tela.

![Sem o Tella: o texto vai para a janela da outra tela](docs/images/1-without-tella-keyboard.png)

### 2. Clicar para ativar pode atrapalhar

A solução seria clicar na outra tela antes de digitar. O problema é que o cursor costuma chegar à tela do lado, e ali muitas vezes há uma **janela de trás**, maior, atrás da janela pequena que você está usando. O clique cai nela, ela pula para a frente e **cobre a janela que você queria usar**.

![Sem o Tella: o clique traz a janela de trás para a frente](docs/images/2-without-tella-click.png)

---

## A solução

Com o Tella ligado, quando o cursor entra em outra tela, o app ativa a **janela que já está na frente naquela tela**. Ele não usa o lugar onde o cursor caiu.

- ✅ O teclado acompanha o cursor: é só mudar de tela e digitar.
- ✅ Nenhum clique é simulado, então nenhum botão ou link é acionado sem querer.
- ✅ Nenhuma janela muda de lugar, e a de trás continua atrás.

![Com o Tella: a janela da frente é ativada sozinha, sem clique](docs/images/3-with-tella.png)

---

## Como funciona

1. O Tella confere a cada 30 ms em qual tela o cursor está.
2. Quando o cursor **muda de tela**, ele espera um instante (0,12 s) para confirmar que você realmente ficou nessa tela.
3. Ele procura, entre as janelas daquela tela, a que está **mais à frente** e ativa essa janela e o app dela pela API de Acessibilidade do macOS.

Alguns cuidados que o app toma:

- **Arrastando algo entre telas?** Se o botão do mouse estiver pressionado, o Tella não faz nada, para não atrapalhar o arraste.
- **Ligou ou desligou um monitor?** O Tella só atualiza a referência e não ativa nada.
- **A tela não tem nenhuma janela?** Ele não faz nada.

### Ao minimizar uma janela

Se você minimiza a janela que estava usando, o Tella ativa **na hora** a janela que ficou na frente naquela tela, normalmente a que estava atrás. Assim, você continua digitando sem precisar clicar nela.

> **Importante:** o Tella age **só quando o cursor muda de tela ou quando você minimiza uma janela**. No resto, tudo continua como sempre: para trocar de janela na mesma tela, você clica normalmente.

---

## Menu da barra de menus

| Opção | O que faz |
|---|---|
| **Sobre o Tella** | Mostra a versão, o desenvolvedor, o site e a licença. |
| **Atualização disponível: Tella x.y** | Só aparece quando há versão nova. Clique para baixar. |
| **Ativo** | Liga ou desliga o Tella sem precisar fechar o app. |
| **Abrir ao iniciar sessão** | Abre o Tella sozinho quando você liga o Mac. |
| **Permissão** | Mostra se a Acessibilidade está permitida (✓) ou faltando (⚠︎) e reúne as opções abaixo. |
| ↳ **Abrir Ajustes de Acessibilidade…** | Abre direto a lista de Acessibilidade nos Ajustes do Sistema. |
| ↳ **Pedir permissão novamente** | Mostra de novo o aviso do macOS e coloca o Tella na lista. |
| ↳ **Redefinir permissão** | Apaga a permissão antiga e pede de novo. É útil depois de atualizar o app. |
| ↳ **Mostrar o Tella no Finder** | Mostra o app no Finder, para você arrastá-lo para a lista se ele não aparecer lá. |
| **Procurar atualizações…** | Confere agora no GitHub se há versão nova. |
| **Procurar atualizações automaticamente** | Confere uma vez por dia (ligado por padrão). Desligue se preferir. |
| **Sair do Tella** | Fecha o app. |

---

## Idiomas

O Tella usa automaticamente o idioma do seu Mac. São **36 idiomas**:

Português (Brasil) · Português (Portugal) · English · Español · Français · Deutsch · Italiano · Nederlands · Svenska · Dansk · Norsk · Suomi · Polski · Čeština · Slovenčina · Magyar · Română · Hrvatski · Slovenščina · Български · Català · Ελληνικά · Türkçe · Русский · Українська · עברית · العربية · हिन्दी · ไทย · Tiếng Việt · Bahasa Indonesia · Bahasa Melayu · 日本語 · 한국어 · 简体中文 · 繁體中文

Se o idioma do Mac não estiver na lista, o Tella aparece em **inglês**.

Para usar o Tella em outro idioma sem mudar o Mac inteiro, vá em **Ajustes do Sistema → Geral → Idioma e Região → Aplicativos**, clique em **+** e escolha o Tella.

---

## Requisitos

- macOS 13 (Ventura) ou mais novo
- Mac com Apple Silicon (M1, M2, M3, M4…)
- Permissão de **Acessibilidade**, que o Tella precisa para ativar janelas de outros apps

---

## Instalação

### Pelo instalador (DMG)

1. Baixe o **[Tella.dmg](https://github.com/arthuislan/tella/releases/latest/download/Tella.dmg)** na página de [Releases](https://github.com/arthuislan/tella/releases).
2. Abra o DMG e arraste o **Tella** para a pasta **Aplicativos**.
3. Abra o Tella. Como o app não é autenticado pela Apple, na primeira vez o macOS pode avisar que não consegue verificar o desenvolvedor. Para abrir mesmo assim, use **Ajustes do Sistema → Privacidade e Segurança → Abrir Mesmo Assim**, ou clique no app com o botão direito e escolha **Abrir**.
4. Quando o Tella pedir, ligue a permissão em **Ajustes do Sistema → Privacidade e Segurança → Acessibilidade**.

### Compilando o código

É preciso ter as ferramentas de linha de comando do Xcode (`xcode-select --install`).

```bash
git clone https://github.com/arthuislan/tella.git
cd tella
./build.sh --install   # compila, instala em /Applications e abre
./build.sh --dmg       # compila e gera o instalador Tella.dmg
```

---

## Solução de problemas

**O Tella não ativa as janelas.**
Na maioria das vezes, é a permissão de Acessibilidade. Depois de uma atualização, o macOS pode passar a tratar o Tella como outro app.

O jeito mais fácil de corrigir é pelo próprio Tella: no menu, vá em **Permissão → Redefinir permissão** e ligue o Tella de novo na lista de Acessibilidade.

Se preferir, pelo Terminal:

```bash
pkill -x Tella
tccutil reset Accessibility local.tella
open /Applications/Tella.app
```

Depois ligue o Tella de novo em **Acessibilidade**.

**O ícone antigo continua aparecendo.**
É cache do macOS. Para atualizar:

```bash
touch /Applications/Tella.app && killall Dock Finder
```

**Como desinstalar?**

```bash
pkill -x Tella
rm -rf /Applications/Tella.app
tccutil reset Accessibility local.tella
```

---

## Atualizações

O Tella confere uma vez por dia a página de [Releases](https://github.com/arthuislan/tella/releases). Quando sai uma versão nova, ele avisa e mostra **Atualização disponível** no menu.

Para atualizar: baixe o novo **Tella.dmg**, abra e arraste o Tella para **Aplicativos**, substituindo o antigo. Depois de atualizar, o macOS pode pedir de novo a permissão de **Acessibilidade**. Se não funcionar na hora, use **Permissão → Redefinir permissão** no menu.

---

## Privacidade

O Tella **não lê o que você digita** e não grava nada. Ele só observa a posição do cursor e a lista de janelas abertas, para saber qual janela ativar.

A única vez que ele acessa a internet é para conferir, no máximo uma vez por dia, a página pública de versões do Tella no GitHub. Nada sobre você ou o seu Mac é enviado. Dá para desligar em **Procurar atualizações automaticamente**.

---

## Estrutura do projeto

```
tella/
├── Sources/main.swift      # o app (barra de menus + lógica)
├── Resources/
│   ├── AppIcon.iconset/    # ícone do app
│   └── *.lproj/            # traduções (36 idiomas)
├── Info.plist
├── build.sh                # compilar, instalar e gerar o DMG
├── RELEASING.md            # como publicar uma versão nova
└── docs/
    ├── images/             # imagens deste README
    └── src/gen.py          # script que gera as ilustrações
```

O histórico de versões está no [CHANGELOG.md](CHANGELOG.md).

---

## Licença

[MIT](LICENSE) © 2026 Arthuislan
