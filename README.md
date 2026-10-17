# Лендинг Tribe

Одна статичная страница. Все кнопки ведут в приложение: https://app.lockerposps.com (адрес задан в `src/config.ts`).

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
