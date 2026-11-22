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

## Заголовки безопасности (nginx)

Настройки nginx для лендинга лежат в `deploy/nginx/funkicrm-landing.conf`. На сервере это файл `/etc/nginx/sites-available/funkicrm-landing.conf`. В нём заданы заголовки, которые получает браузер:

- `Strict-Transport-Security` — браузер год открывает сайт только по HTTPS (поддомены `app` и `test-app` не затронуты);
- `Content-Security-Policy` — скрипты, стили, картинки и шрифты грузятся только с самого сайта; встроенные скрипты и стили разрешены; страницу нельзя встроить в чужой сайт;
- `X-Frame-Options: DENY` — то же «нельзя встроить», для старых браузеров;
- `Referrer-Policy` — на другие сайты (и в приложение) уходит только адрес `https://funkicrm.ru`, без пути;
- `X-Content-Type-Options: nosniff` — браузер не угадывает тип файла;
- `Permissions-Policy` — камера, микрофон, геолокация, оплата и подобное выключены.

Номер версии nginx не показывает: `server_tokens off` в общем файле `/etc/nginx/conf.d/funkicrm-hardening.conf`.

Выкатка на сервер через Actions этот файл не трогает. После правки его нужно поставить вручную (нужен пароль sudo):

```sh
scp deploy/nginx/funkicrm-landing.conf deploy/nginx/install.sh crm:landing-nginx/
ssh -t crm "sudo bash landing-nginx/install.sh"
```

Скрипт делает копию, проверяет конфиг (`nginx -t`) и при ошибке возвращает всё как было. Проверить заголовки: `curl -sI https://funkicrm.ru/`.
