# Загрузка полного проекта с Windows

Архив содержит исходники, Xcode-проект, Share Extension, CarPlay-эксперимент и `.github/workflows/build-ipa.yml`. ZIP распаковывается без лишней вложенной папки.

## Существующий репозиторий GitHub (рекомендуется)

В PowerShell (путь `D:\Downloads\CarVideoLab-COMPLETE-v0.4.1.zip` при необходимости замени):

```powershell
New-Item -ItemType Directory -Force 'D:\Projects' | Out-Null
git clone https://github.com/gentle-bear/car-video-lab.git 'D:\Projects\car-video-lab-full'
Expand-Archive 'D:\Downloads\CarVideoLab-COMPLETE-v0.4.1.zip' -DestinationPath 'D:\Projects\car-video-lab-full' -Force
Set-Location 'D:\Projects\car-video-lab-full'
Test-Path '.github\workflows\build-ipa.yml'
git add -A
git commit -m 'Install complete Car Video Lab v0.4.1'
git branch -M main
git push -u origin main
```

Ожидаемый ответ `Test-Path` — `True`. Чтобы избежать конфликта, до выполнения `git clone` проверь, что папки `D:\Projects\car-video-lab-full` ещё нет.

## Если удалён и сам репозиторий GitHub

Сначала создай пустой `gentle-bear/car-video-lab` без README на https://github.com/new. После этого те же команды выше работают.

## Затем

Открой https://github.com/gentle-bear/car-video-lab/actions, выбери успешную сборку, скачай IPA из Artifacts и установи через Sideloadly.

GitHub Actions выполняет сборку на macOS с Xcode 27. Мы не гарантируем успешную сборку до реального запуска workflow; если будет красный крестик, смотри первый `error:` в логах или скачай `CarVideoLab-build-log`.

Для CarPlay Video требуется отдельный entitlement от Apple и автомобиль с поддержкой Video in Car. Никакая обычная Sideloadly-подпись не предоставляет его.
