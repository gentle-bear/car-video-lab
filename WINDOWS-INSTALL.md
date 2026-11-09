# Windows: обновление полного архива Car Video Lab v0.3.1

ВНИМАНИЕ: распакованная папка из ZIP — это НЕ git-репозиторий. Не вызывай `git init` внутри архива.

Рекомендуемый способ — чистый clone, потом скопировать все файлы, включая скрытую `.github`.

Открой PowerShell:

```powershell
cd D:\Downloads
git clone https://github.com/gentle-bear/car-video-lab.git car-video-lab-clean
```

Распакуй архив в `D:\Downloads\CarVideoLab-FULL-v0.3.1` (путь можно изменить). Затем:

```powershell
robocopy "D:\Downloads\CarVideoLab-FULL-v0.3.1" "D:\Downloads\car-video-lab-clean" /E /XD .git
cd D:\Downloads\car-video-lab-clean
git status -sb
git add -A
git commit -m "Fix complete Car Video Lab v0.3.1 project"
git push
```

`robocopy` возвращает коды 0–7 при обычном успехе или при наличии скопированных файлов; код 8 и выше — ошибка.

Если `car-video-lab-clean` уже существует, не выполняй повторный `git clone`; повтори `robocopy` в эту папку.

Проверь, что workflow присутствует:

```powershell
git ls-files .github/workflows
```

Ожидается `.github/workflows/build-ipa.yml`.

GitHub Actions: https://github.com/gentle-bear/car-video-lab/actions

При успешной сборке скачай artifact `CarVideoLab-v0.3.1-unsigned-IPA`. При неудачной сборке открой лог первого шага с ошибкой или скачай artifact `CarVideoLab-build-log`, если он создан. Не путай warning Node с ошибкой Swift.

Устанавливай IPA через Sideloadly, не включай `Remove App Extensions`.


## v0.4.0 important

The unsigned IPA includes the CarPlay scene code and AirPlay/HLS test UI, **but the restricted CarPlay Video entitlement is NOT granted**. Installing it with Sideloadly will not make the app appear inside ordinary CarPlay. See [CARPLAY-SETUP.md](CARPLAY-SETUP.md).
