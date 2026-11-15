# Releasing a new version · Como publicar uma versão nova

Tella checks `https://api.github.com/repos/arthuislan/tella/releases/latest` to find new versions. These rules keep that check working.

O Tella consulta a última release do GitHub para saber se existe versão nova. Estas regras garantem que isso funcione.

## Rules · Regras

1. **Version numbers** use `MAJOR.MINOR.PATCH` (e.g. `1.3`, `1.3.1`, `2.0`).
   - Bug fix only → raise the last number (`1.3` → `1.3.1`).
   - New feature → raise the middle number (`1.3` → `1.4`).
   - Big change → raise the first number (`1.9` → `2.0`).
   
   **Números de versão** seguem `MAIOR.MENOR.CORREÇÃO`. Só correção → último número; recurso novo → número do meio; mudança grande → primeiro número.

2. **`Info.plist` must match the tag.** `CFBundleShortVersionString` = the version without the `v` (e.g. `1.3`). Also raise `CFBundleVersion` by 1 on every release.

   **O `Info.plist` precisa bater com a tag.** `CFBundleShortVersionString` é a versão sem o `v`; `CFBundleVersion` sobe 1 a cada release.

3. **The tag is `v` + version** (e.g. `v1.3`), created on `main`.

   **A tag é `v` + versão** (ex.: `v1.3`), criada a partir da `main`.

4. **The installer is named `Tella-<version>.dmg`** (e.g. `Tella-1.4.dmg`) and is attached to the release. `./build.sh --dmg` creates it with the right name from `Info.plist`. The app downloads whichever `.dmg` is attached to the latest release.

   **O instalador se chama `Tella-<versão>.dmg`** (ex.: `Tella-1.4.dmg`) e vai anexado na release. O `./build.sh --dmg` já gera com o nome certo a partir do `Info.plist`.

5. **The release must be published and marked as Latest** — drafts and pre-releases are ignored by the update check, so use a pre-release to test without notifying users.

   **A release precisa estar publicada e marcada como Latest.** Rascunhos e pre-releases não geram aviso — use pre-release para testar sem avisar ninguém.

6. **Update `CHANGELOG.md`** in English, Português and Español, and write the release notes in the same three languages.

   **Atualize o `CHANGELOG.md`** e as notas da release nos três idiomas.

7. **New texts in the app** go into all `Resources/*.lproj/Localizable.strings` files. The name **Tella** is never translated.

   **Textos novos no app** entram em todos os arquivos de tradução. O nome **Tella** nunca é traduzido.

8. **Update the download links** in `README.md`, `README.pt-BR.md` and `README.es.md` to the new version (search for the old number, e.g. `1.3`, in the download button and in step 1 of Installation): `https://github.com/arthuislan/tella/releases/download/v<version>/Tella-<version>.dmg`.

   **Atualize os links de download** nos três READMEs para a versão nova (botão de download e passo 1 da Instalação).

## Steps · Passo a passo

```bash
# 1. Edit Info.plist (version + build), CHANGELOG.md and the README download links
# 2. Build and test the installer
./build.sh --install     # try it on your Mac
./build.sh --dmg         # creates Tella-1.4.dmg (not committed — see .gitignore)

# 3. Commit and push
git add -A
git commit -m "Tella 1.4"
git push
```

4. On GitHub: **Releases → Draft a new release** → tag `v1.4` on `main` → title `Tella 1.4` → notes in EN/PT/ES → attach `Tella-1.4.dmg` → **Publish release**.

   No GitHub: **Releases → Draft a new release** → tag `v1.4` na `main` → título `Tella 1.4` → notas em EN/PT/ES → anexe o `Tella-1.4.dmg` → **Publish release**.

Within a day, everyone running an older version sees **Update Available** in the Tella menu.

Em até um dia, quem estiver com uma versão anterior vê **Atualização disponível** no menu do Tella.
