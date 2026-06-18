# Famora Family Planner

Famora Family Planner - мобильное и web-приложение для семьи: задачи, активности, объявления, статистика, баллы, профильные фото и роли участников.

Проект сделан на Flutter и Firebase. Репозиторий GitHub хранит исходный код и папку с профильными фотографиями. Само приложение сейчас работает не из GitHub, а через Firebase Hosting и Firebase Firestore.

## Где что находится

### Рабочее приложение

Публичная ссылка приложения:

```text
https://family-planner-famora.web.app
```

Эта ссылка открывает уже собранную web-версию, опубликованную через Firebase Hosting.

### GitHub-репозиторий

Исходный код проекта:

```text
https://github.com/Unnamed00000/family-planner-famora
```

Важно: GitHub здесь используется как место хранения проекта и профильных фотографий. Само приложение не запускается напрямую из GitHub.

### Локальная папка проекта

На этом компьютере проект находится здесь:

```text
C:\Users\Unnamed\Documents\Codex\2026-06-18\family-planner-7-flutter-firebase-authentication
```

### Профильные фотографии

В репозитории есть папка:

```text
Profile photos/
```

Туда добавлена фотография:

```text
Profile photos/Adam.jpg
```

После загрузки в GitHub прямую ссылку для приложения можно использовать такую:

```text
https://raw.githubusercontent.com/Unnamed00000/family-planner-famora/main/Profile%20photos/Adam.jpg
```

Эту ссылку можно вставить в приложении:

```text
Профиль -> Использовать ссылку на фото
```

или в админке:

```text
Админ -> Участники -> редактировать участника -> Ссылка на фото
```

## Что уже подключено сейчас

### Firebase project

Firebase-проект:

```text
family-planner-famora
```

Firebase Console:

```text
https://console.firebase.google.com/project/family-planner-famora/overview
```

### Firebase Hosting

Используется для публикации web-приложения.

Файлы собираются Flutter-командой:

```powershell
flutter build web
```

После сборки готовые файлы появляются в:

```text
build/web
```

Firebase Hosting берёт файлы именно из этой папки. Это указано в `firebase.json`:

```json
{
  "hosting": {
    "public": "build/web"
  }
}
```

Публикация выполняется командой:

```powershell
firebase deploy --only hosting,firestore:rules
```

### Firebase Authentication

Используется вход по email и паролю.

Также в приложении есть "семейный логин". Он работает так:

1. В Firebase Authentication всё равно создаётся обычный email/password аккаунт.
2. В Firestore создаётся документ в коллекции `familyLogins`.
3. Семейный логин находит email и затем входит через Firebase Auth.

Email/password provider должен быть включён здесь:

```text
Firebase Console -> Authentication -> Sign-in method -> Email/Password
```

### Cloud Firestore

Firestore хранит:

- участников семьи;
- задачи;
- активности;
- объявления;
- уведомления;
- настройки приложения;
- историю действий;
- семейные логины.

Основные коллекции:

```text
members
tasks
activities
announcements
notifications
settings
familyLogins
history
```

Правила безопасности лежат в файле:

```text
firestore.rules
```

Публикуются командой:

```powershell
firebase deploy --only firestore:rules
```

### Firebase Storage

Firebase Storage сейчас не обязателен.

Приложение умеет загружать фото через Firebase Storage, но Storage требует включения в Firebase Console. На момент настройки Firebase показывал, что Storage требует upgrade проекта.

Поэтому добавлен второй вариант: использовать фото по прямой ссылке из GitHub или другого хранилища.

Рекомендуемый бесплатный вариант сейчас:

1. Добавить фото в папку `Profile photos` в GitHub.
2. Открыть фото в GitHub.
3. Получить прямую `raw.githubusercontent.com` ссылку.
4. Вставить ссылку в профиль участника.

## Что умеет приложение

### Роли

Есть две роли:

- администратор;
- обычный участник.

Администратор может:

- добавлять участников;
- редактировать участников;
- удалять участников;
- менять роли;
- назначать задачи;
- создавать активности;
- создавать объявления;
- редактировать и удалять объявления;
- управлять баллами участников;
- задавать стоимость одного балла в датских кронах;
- смотреть историю действий.

Обычный участник может:

- смотреть свои задачи;
- смотреть семейную доску;
- принимать личные уведомления;
- отмечать свои задачи;
- видеть статистику;
- менять свой язык;
- менять свою тему;
- включать или выключать звук и вибрацию;
- поставить своё фото через ссылку или загрузку.

### Главная

На главной странице показываются участники семьи:

- имя;
- фото или буква имени;
- цвет участника;
- задачи на сегодня;
- процент выполнения;
- баллы;
- стоимость баллов в DKK.

Цвета участников заданы по именам:

```text
Adam / Адам      -> красный
Samira / Самира  -> розовый
Maryam / Марьям  -> жёлтый
Muhammed         -> зелёный
Anas / Анас      -> коричневый
Iman / Иман      -> голубой
```

### Доска

Доска показывает:

- уведомления;
- объявления;
- сегодняшние задания.

Доска в основном предназначена для просмотра. Управление задачами находится во вкладке "Задачи".

### Задачи

Задачи имеют:

- название;
- описание;
- исполнителя;
- дату и время;
- приоритет;
- повторение;
- статус;
- баллы.

Статусы:

- ожидает;
- выполняется;
- выполнено;
- просрочено.

Если задача выполнена, её нельзя снова начать. Для нового выполнения нужна новая задача или повторение.

Обычный участник может управлять только своими задачами. Администратор может управлять всеми.

### Активности

Активности нужны для футбола, пианино, кружков, занятий и других дел вне дома.

У активности есть:

- название;
- описание;
- место;
- участник;
- время начала;
- время, когда выйти из дома;
- время окончания;
- статус.

Когда администратор создаёт активность, выбранному участнику создаётся уведомление.

Участник может:

1. нажать "Принял";
2. нажать "Я вышел";
3. нажать "Закончил".

### Объявления

Объявления создаются администратором.

В админке объявления можно:

- создать;
- редактировать;
- удалить.

Объявления отображаются на семейной доске.

### Статистика

Статистика показывает:

- выполненные задачи;
- пропущенные задачи;
- процент выполнения;
- время активностей;
- рейтинг семьи;
- баллы и сумму в DKK.

Графики теперь показывают отдельную линию для каждого участника. Цвет линии совпадает с цветом участника.

Например:

- Самира - розовая линия;
- Марьям - жёлтая линия;
- Иман - голубая линия.

### Профиль

В профиле участник может:

- выбрать язык;
- поставить фото;
- вставить ссылку на фото;
- выбрать светлую или тёмную тему;
- включить или выключить звук;
- включить или выключить вибрацию;
- видеть баллы;
- видеть сумму баллов в DKK;
- видеть достижения.

Тема сохраняется в профиле конкретного участника. Если один участник включил тёмную тему, это не меняет тему у других участников.

### Языки

Приложение поддерживает:

- русский;
- английский;
- датский.

Датский язык используется как язык по умолчанию.

## Как запустить локально на компьютере

### 1. Установить Flutter

На этом компьютере Flutter установлен здесь:

```text
C:\src\flutter_windows_3.44.2-stable\flutter\bin\flutter.bat
```

Проверка Flutter:

```powershell
flutter doctor
```

Если команда `flutter` не работает, можно запускать напрямую:

```powershell
& 'C:\src\flutter_windows_3.44.2-stable\flutter\bin\flutter.bat' doctor
```

### 2. Установить зависимости проекта

В папке проекта:

```powershell
flutter pub get
```

или напрямую:

```powershell
& 'C:\src\flutter_windows_3.44.2-stable\flutter\bin\flutter.bat' pub get
```

### 3. Запустить локально

```powershell
flutter run -d chrome --web-port 8080
```

После этого локальная версия открывается здесь:

```text
http://127.0.0.1:8080
```

Важно: `127.0.0.1:8080` - это только локальная версия на компьютере. Для семьи нужно использовать публичную ссылку Firebase Hosting:

```text
https://family-planner-famora.web.app
```

## Как собрать и опубликовать новую версию

### 1. Проверить код

```powershell
flutter analyze
```

### 2. Запустить тесты

```powershell
flutter test
```

### 3. Собрать web

```powershell
flutter build web
```

### 4. Опубликовать на Firebase

```powershell
firebase deploy --only hosting,firestore:rules
```

Если нужно публиковать Storage rules, команда такая:

```powershell
firebase deploy --only storage
```

Но Storage должен быть сначала включён в Firebase Console.

## Как подключить проект заново с нуля

Этот раздел нужен, если кто-то другой захочет развернуть такое же приложение на своём Firebase.

### 1. Создать Firebase project

1. Открыть:

```text
https://console.firebase.google.com
```

2. Нажать "Add project".
3. Создать проект.
4. Можно использовать Spark plan для Auth, Firestore и Hosting.

Для Storage может потребоваться Blaze plan.

### 2. Включить Authentication

1. Открыть Firebase project.
2. Перейти:

```text
Authentication -> Sign-in method
```

3. Включить:

```text
Email/Password
```

### 3. Создать Firestore Database

1. Перейти:

```text
Firestore Database
```

2. Нажать "Create database".
3. Выбрать Standard edition.
4. Выбрать регион.
5. После создания опубликовать правила из `firestore.rules`.

### 4. Добавить Web app в Firebase

1. В Firebase Project Overview нажать значок Web `</>`.
2. Зарегистрировать web app.
3. Firebase покажет config:

```javascript
const firebaseConfig = {
  apiKey: "...",
  authDomain: "...",
  projectId: "...",
  storageBucket: "...",
  messagingSenderId: "...",
  appId: "...",
  measurementId: "..."
};
```

4. Эти значения нужно перенести в:

```text
lib/firebase_options.dart
web/firebase-messaging-sw.js
```

В текущем проекте уже стоит config для:

```text
family-planner-famora
```

### 5. Установить Firebase CLI

Проверка:

```powershell
firebase --version
```

Если команда не работает, установить Firebase CLI:

```powershell
npm install -g firebase-tools
```

### 6. Авторизоваться в Firebase CLI

```powershell
firebase login
```

### 7. Привязать проект

В файле `.firebaserc` должен быть нужный Firebase project id:

```json
{
  "projects": {
    "default": "family-planner-famora"
  }
}
```

Если проект другой, заменить `family-planner-famora` на свой project id.

### 8. Опубликовать правила и Hosting

```powershell
flutter build web
firebase deploy --only hosting,firestore:rules
```

### 9. Создать первого администратора

Есть два варианта.

#### Вариант A: через Firebase Console

1. Открыть:

```text
Authentication -> Users
```

2. Создать пользователя email/password.
3. Скопировать UID пользователя.
4. Открыть Firestore.
5. Создать документ:

```text
members/{UID}
```

6. Добавить поля:

```json
{
  "name": "Adam",
  "age": 35,
  "role": "admin",
  "authUid": "UID_FROM_AUTH",
  "completedTasks": 0,
  "missedTasks": 0,
  "points": 0,
  "themeMode": "light",
  "soundEnabled": true,
  "vibrationEnabled": true
}
```

#### Вариант B: через уже существующего администратора

Если администратор уже есть, он может зайти в приложение:

```text
Админ -> Участники -> Добавить участника
```

Там можно указать:

- имя;
- возраст;
- email;
- временный пароль;
- семейный логин;
- роль;
- баланс баллов;
- ссылку на фото.

Если указать email и временный пароль, приложение создаст Firebase Auth аккаунт автоматически.

## Как добавить фото через GitHub

### 1. Добавить файл в папку

Положить фото в:

```text
Profile photos/
```

Например:

```text
Profile photos/Adam.jpg
Profile photos/Samira.jpg
Profile photos/Iman.jpg
```

### 2. Закоммитить и отправить в GitHub

```powershell
git add "Profile photos"
git commit -m "Add profile photos"
git push origin main
```

### 3. Получить прямую ссылку

Для файла `Profile photos/Adam.jpg` ссылка будет:

```text
https://raw.githubusercontent.com/Unnamed00000/family-planner-famora/main/Profile%20photos/Adam.jpg
```

Пробел в названии папки записывается как `%20`.

### 4. Вставить ссылку в приложение

Вариант для самого участника:

```text
Профиль -> Использовать ссылку на фото
```

Вариант для администратора:

```text
Админ -> Участники -> редактировать -> Ссылка на фото
```

После сохранения приложение будет показывать фото по этой ссылке.

## Почему GitHub не используется для автоматической загрузки фото

Автоматическая загрузка фото из web-приложения прямо в GitHub требует секретный GitHub token.

Такой токен нельзя хранить внутри Flutter Web приложения, потому что любой пользователь может открыть код сайта и украсть токен.

Поэтому безопасные варианты такие:

1. Вручную загружать фото в GitHub и вставлять raw-ссылку.
2. Использовать Firebase Storage.
3. Сделать отдельный backend, который будет безопасно принимать фото и загружать их в GitHub или Google Drive.

Сейчас выбран простой и безопасный вариант:

```text
GitHub folder -> raw link -> photoUrl in Firestore -> image in app
```

## Полезные команды Git

Проверить состояние:

```powershell
git status
```

Добавить изменения:

```powershell
git add .
```

Сделать коммит:

```powershell
git commit -m "Update app"
```

Отправить в GitHub:

```powershell
git push origin main
```

Получить последние изменения:

```powershell
git pull --rebase origin main
```

## Важные файлы проекта

```text
lib/main.dart
lib/firebase_options.dart
lib/src/app.dart
lib/src/models/app_models.dart
lib/src/services/firebase_service.dart
lib/src/screens/
lib/src/widgets/common.dart
lib/src/l10n/app_strings.dart
firebase.json
firestore.rules
storage.rules
web/firebase-messaging-sw.js
Profile photos/
```

## Короткое резюме

GitHub хранит:

- исходный код;
- README;
- папку `Profile photos`;
- правила Firebase;
- Flutter-проект.

Firebase запускает приложение:

- Hosting показывает сайт;
- Authentication отвечает за вход;
- Firestore хранит данные;
- Storage можно включить позже, если нужна загрузка файлов прямо из приложения.

Рабочая ссылка приложения:

```text
https://family-planner-famora.web.app
```
