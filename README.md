# Лендинг Tribe

Одна статичная страница. Все кнопки ведут в приложение: https://app.funkicrm.ru (адрес задан в `src/config.ts`).

## Как запустить

```sh
pnpm install
pnpm dev       # разработка: http://localhost:4321
pnpm build     # сборка в папку dist/
pnpm preview   # посмотреть собранную версию
```

## Где что лежит

- `design/` — макет: образцы в HTML и описание
- `src/styles/tokens.css` — цвета, шрифты, размеры, отступы
- `src/components/sections/` — блоки страницы по порядку: Hero, Problem, Solution, Benefits, FinalCta
- `src/assets/photos/` — фото с Pexels (бесплатная лицензия)

## Выкатка на сервер

Лендинг работает на https://funkicrm.ru (сервер `157.22.207.202`, общий с приложением).

### Как выкатить новую версию

Отправьте коммит в ветку `main` (`git push`). Дальше всё произойдёт само (`.github/workflows/deploy.yml`):

1. GitHub Actions собирает страницу (`pnpm build` → папка `dist/`) и кладёт в неё `version.txt` с SHA коммита.
2. `rsync --delete` копирует `dist/` на сервер в `/var/www/funkicrm.ru`: новые и изменённые файлы заменяются, лишние удаляются. nginx сразу отдаёт новую версию.
3. Проверка: https://funkicrm.ru/version.txt совпадает с коммитом, а главная отвечает 200.

Если что-то сломалось, GitHub присылает письмо. Отката нет: исправьте и отправьте новый коммит.

### Как проверить

- Ход выкатки: вкладка **Actions** в репозитории на GitHub (или `gh run watch` в терминале).
- https://funkicrm.ru/version.txt показывает SHA последнего коммита в `main` — значит, на сервере новая версия.

### Как это настроено (уже сделано, нужно только для нового сервера)

1. На сервере установлен `rsync` (`sudo apt-get install -y rsync`), папка `/var/www/funkicrm.ru` принадлежит пользователю `crmapp`.
2. Ключ деплоя: публичный — в `~crmapp/.ssh/authorized_keys` с ограничением `command="/usr/bin/rrsync -wo /var/www/funkicrm.ru",restrict`. С этим ключом можно только записывать файлы в папку лендинга — ни зайти на сервер, ни тронуть приложение нельзя.
3. В GitHub (Settings → Secrets and variables → Actions): секрет `DEPLOY_SSH_KEY` (приватный ключ деплоя), переменные `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_KNOWN_HOSTS`.
