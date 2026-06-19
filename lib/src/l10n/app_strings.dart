import 'package:flutter/widgets.dart';

import '../models/app_models.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

  static const supportedLocales = [
    Locale('ru'),
    Locale('en'),
    Locale('da'),
  ];

  static const languageNames = {
    'ru': 'Русский',
    'en': 'English',
    'da': 'Dansk',
  };

  String get languageCode => locale.languageCode;

  String pick({required String ru, required String en, required String da}) {
    switch (locale.languageCode) {
      case 'en':
        return en;
      case 'da':
        return da;
      case 'ru':
      default:
        return ru;
    }
  }

  String get appName => pick(ru: 'Семейный планировщик', en: 'Family Planner', da: 'Familieplan');
  String get tagline => pick(
        ru: 'Обязанности, результаты и вклад семьи в одном месте',
        en: 'Tasks, results and family contribution in one place',
        da: 'Opgaver, resultater og familiens bidrag samlet et sted',
      );
  String get chooseLanguage => pick(ru: 'Язык', en: 'Language', da: 'Sprog');
  String get home => pick(ru: 'Главная', en: 'Home', da: 'Hjem');
  String get board => pick(ru: 'Доска', en: 'Board', da: 'Tavle');
  String get tasks => pick(ru: 'Задачи', en: 'Tasks', da: 'Opgaver');
  String get newspaper => pick(ru: 'Газета', en: 'Newspaper', da: 'Avis');
  String get calendar => pick(ru: 'Календарь', en: 'Calendar', da: 'Kalender');
  String get activities => pick(ru: 'Активности', en: 'Activities', da: 'Aktiviteter');
  String get stats => pick(ru: 'Статистика', en: 'Stats', da: 'Statistik');
  String get profile => pick(ru: 'Профиль', en: 'Profile', da: 'Profil');
  String get admin => pick(ru: 'Админ', en: 'Admin', da: 'Admin');
  String get signIn => pick(ru: 'Войти', en: 'Sign in', da: 'Log ind');
  String get email => pick(ru: 'Email', en: 'Email', da: 'Email');
  String get password => pick(ru: 'Пароль', en: 'Password', da: 'Adgangskode');
  String get familyLogin => pick(ru: 'Семейный логин', en: 'Family login', da: 'Familielogin');
  String get createAccount => pick(ru: 'Создать аккаунт', en: 'Create account', da: 'Opret konto');
  String get createEmailAccount => pick(ru: 'Создать email-аккаунт', en: 'Create email account', da: 'Opret emailkonto');
  String get alreadyHaveAccount => pick(ru: 'У меня уже есть аккаунт', en: 'I already have an account', da: 'Jeg har allerede en konto');
  String get completed => pick(ru: 'Выполнено', en: 'Done', da: 'Fuldført');
  String get missed => pick(ru: 'Пропущено', en: 'Missed', da: 'Sprunget over');
  String get pending => pick(ru: 'Осталось', en: 'Pending', da: 'Mangler');
  String get points => pick(ru: 'Баллы', en: 'Points', da: 'Point');
  String get editPoints => pick(ru: 'Изменить баллы', en: 'Edit points', da: 'Rediger point');
  String get pointsBalance => pick(ru: 'Баланс баллов', en: 'Point balance', da: 'Pointsaldo');
  String get rating => pick(ru: 'Рейтинг', en: 'Rating', da: 'Rangering');
  String get percent => pick(ru: 'Процент', en: 'Percent', da: 'Procent');
  String get noAssignee => pick(ru: 'Без исполнителя', en: 'No assignee', da: 'Ingen ansvarlig');
  String get noneYet => pick(ru: 'Пока нет', en: 'None yet', da: 'Ikke endnu');
  String get logout => pick(ru: 'Выйти', en: 'Sign out', da: 'Log ud');
  String get cancel => pick(ru: 'Отмена', en: 'Cancel', da: 'Annuller');
  String get save => pick(ru: 'Сохранить', en: 'Save', da: 'Gem');
  String get delete => pick(ru: 'Удалить', en: 'Delete', da: 'Slet');
  String get edit => pick(ru: 'Редактировать', en: 'Edit', da: 'Rediger');
  String get photo => pick(ru: 'Фото', en: 'Photo', da: 'Foto');
  String get creatorLine => pick(
        ru: 'Разработчик приложения: Адам Маргоев',
        en: 'App developer: Adam Margoev',
        da: 'App-udvikler: Adam Margoev',
      );
  String get appVersion => pick(ru: 'Версия 1.0.0', en: 'Version 1.0.0', da: 'Version 1.0.0');
  String get appearance => pick(ru: 'Внешний вид', en: 'Appearance', da: 'Udseende');
  String get lightTheme => pick(ru: 'Светлая тема', en: 'Light theme', da: 'Lyst tema');
  String get darkTheme => pick(ru: 'Тёмная тема', en: 'Dark theme', da: 'Mørkt tema');
  String get soundAndVibration => pick(ru: 'Звук и вибрация', en: 'Sound and vibration', da: 'Lyd og vibration');
  String get notificationSound => pick(ru: 'Звук уведомлений', en: 'Notification sound', da: 'Notifikationslyd');
  String get notificationVibration => pick(ru: 'Вибрация', en: 'Vibration', da: 'Vibration');
  String get uploadOwnPhoto => pick(ru: 'Загрузить моё фото', en: 'Upload my photo', da: 'Upload mit foto');
  String get photoLink => pick(ru: 'Ссылка на фото', en: 'Photo link', da: 'Fotolink');
  String get usePhotoLink => pick(ru: 'Использовать ссылку на фото', en: 'Use photo link', da: 'Brug fotolink');
  String get photoLinkHelp => pick(
        ru: 'Вставьте прямую HTTPS-ссылку на изображение из другого хранилища.',
        en: 'Paste a direct HTTPS image link from another storage service.',
        da: 'Indsæt et direkte HTTPS-billedlink fra en anden lagertjeneste.',
      );

  String get addFamilyMembers => pick(ru: 'Добавьте членов семьи', en: 'Add family members', da: 'Tilføj familiemedlemmer');
  String get adminCanCreateProfiles => pick(
        ru: 'Администратор может создать профили в разделе управления.',
        en: 'The administrator can create profiles in the admin section.',
        da: 'Administratoren kan oprette profiler i adminområdet.',
      );
  String get dayLeader => pick(ru: 'Лидер дня', en: 'Day leader', da: 'Dagens leder');
  String get completedToday => pick(ru: 'Выполнено сегодня', en: 'Done today', da: 'Fuldført i dag');
  String get stillLeft => pick(ru: 'Еще осталось', en: 'Still left', da: 'Stadig tilbage');
  String tasksRemainFor(String names) => pick(
        ru: 'Еще есть задачи у: $names',
        en: 'Tasks still remain for: $names',
        da: 'Der er stadig opgaver til: $names',
      );
  String pointsCount(int count) => pick(ru: '$count баллов', en: '$count points', da: '$count point');
  String doneOf(int done, int total) => pick(ru: '$done из $total', en: '$done of $total', da: '$done af $total');
  String get noTasksToday => pick(ru: 'Сегодня задач нет', en: 'No tasks today', da: 'Ingen opgaver i dag');
  String get noTasksFound => pick(ru: 'Задачи не найдены', en: 'No tasks found', da: 'Ingen opgaver fundet');
  String get taskSearch => pick(ru: 'Поиск задач', en: 'Search tasks', da: 'Søg i opgaver');
  String get filter => pick(ru: 'Фильтр', en: 'Filter', da: 'Filter');
  String get allStatuses => pick(ru: 'Все статусы', en: 'All statuses', da: 'Alle statusser');
  String get start => pick(ru: 'Начать', en: 'Start', da: 'Start');
  String get done => pick(ru: 'Готово', en: 'Done', da: 'Færdig');
  String get sendForReview => pick(ru: 'На проверку', en: 'Send for review', da: 'Send til kontrol');
  String get approveTask => pick(ru: 'Подтвердить и оплатить', en: 'Approve and pay', da: 'Godkend og betal');
  String get redoTask => pick(ru: 'Переделать', en: 'Redo', da: 'Lav igen');
  String get taskSentForReview => pick(ru: 'Задача отправлена на проверку', en: 'Task sent for review', da: 'Opgave sendt til kontrol');
  String get taskReturnedForRedo => pick(ru: 'Задача возвращена на переделку', en: 'Task returned for redo', da: 'Opgave sendt tilbage');

  String get daySummary => pick(ru: 'Итоги дня', en: 'Day summary', da: 'Dagens opsummering');
  String get weekSummary => pick(ru: 'Итоги недели', en: 'Week summary', da: 'Ugens opsummering');
  String get mostTasks => pick(ru: 'Больше всего задач', en: 'Most tasks', da: 'Flest opgaver');
  String get mostActive => pick(ru: 'Самый активный', en: 'Most active', da: 'Mest aktiv');
  String get wholeFamily => pick(ru: 'Всей семьей', en: 'Whole family', da: 'Hele familien');
  String get bestHelper => pick(ru: 'Лучший помощник', en: 'Best helper', da: 'Bedste hjælper');
  String get mostResponsible => pick(ru: 'Самый ответственный', en: 'Most responsible', da: 'Mest ansvarlig');
  String get doneThisWeek => pick(ru: 'Выполнено за неделю', en: 'Done this week', da: 'Fuldført i denne uge');
  String get announcements => pick(ru: 'Объявления', en: 'Announcements', da: 'Meddelelser');
  String get noAnnouncements => pick(ru: 'Объявлений пока нет', en: 'No announcements yet', da: 'Ingen meddelelser endnu');
  String get boardTasks => pick(ru: 'Задания', en: 'Tasks', da: 'Opgaver');
  String get notifications => pick(ru: 'Уведомления', en: 'Notifications', da: 'Notifikationer');
  String get noNotifications => pick(ru: 'Уведомлений пока нет', en: 'No notifications yet', da: 'Ingen notifikationer endnu');
  String get acceptNotification => pick(ru: 'Принял', en: 'Accept', da: 'Accepter');
  String get notificationAccepted => pick(ru: 'Принято', en: 'Accepted', da: 'Accepteret');
  String get emptyCalendar => pick(ru: 'Календарь пуст', en: 'Calendar is empty', da: 'Kalenderen er tom');

  String get exportPdf => pick(ru: 'Экспорт статистики в PDF', en: 'Export statistics to PDF', da: 'Eksporter statistik til PDF');
  String get chart7Days => pick(ru: 'Выполнение за 7 дней', en: 'Completion over 7 days', da: 'Fuldførelse over 7 dage');
  String get chart30Days => pick(ru: 'Выполнение за 30 дней', en: 'Completion over 30 days', da: 'Fuldførelse over 30 dage');
  String get familyRating => pick(ru: 'Рейтинг семьи', en: 'Family rating', da: 'Familierangering');
  String memberStats(int done, int missed) => pick(
        ru: 'Выполнено: $done, пропущено: $missed',
        en: 'Done: $done, missed: $missed',
        da: 'Fuldført: $done, sprunget over: $missed',
      );

  String get achievements => pick(ru: 'Достижения', en: 'Achievements', da: 'Præstationer');
  String get noAchievements => pick(
        ru: 'Первые достижения появятся после выполненных задач.',
        en: 'First achievements will appear after completed tasks.',
        da: 'De første præstationer vises efter fuldførte opgaver.',
      );
  String achievementLabel(String value) {
    switch (value) {
      case 'Первая выполненная задача':
        return pick(ru: value, en: 'First completed task', da: 'Første fuldførte opgave');
      case '10 выполненных задач':
        return pick(ru: value, en: '10 completed tasks', da: '10 fuldførte opgaver');
      case '50 выполненных задач':
        return pick(ru: value, en: '50 completed tasks', da: '50 fuldførte opgaver');
      case '100 выполненных задач':
        return pick(ru: value, en: '100 completed tasks', da: '100 fuldførte opgaver');
      case 'Неделя без пропусков':
        return pick(ru: value, en: 'A week without misses', da: 'En uge uden spring');
      case 'Месяц без пропусков':
        return pick(ru: value, en: 'A month without misses', da: 'En måned uden spring');
      default:
        return value;
    }
  }
  String yearsRole(int age, bool isAdmin) => pick(
        ru: '$age лет - ${isAdmin ? 'Администратор' : 'Участник'}',
        en: '$age years - ${isAdmin ? 'Administrator' : 'Member'}',
        da: '$age år - ${isAdmin ? 'Administrator' : 'Medlem'}',
      );
  String get profileNotLinked => pick(ru: 'Профиль не привязан', en: 'Profile is not linked', da: 'Profilen er ikke forbundet');
  String get chooseProfileToLink => pick(
        ru: 'Выберите свой профиль, чтобы связать его с текущим аккаунтом.',
        en: 'Choose your profile to link it with the current account.',
        da: 'Vælg din profil for at forbinde den med den aktuelle konto.',
      );
  String get thisIsMe => pick(ru: 'Это я', en: 'This is me', da: 'Det er mig');

  String get management => pick(ru: 'Управление', en: 'Management', da: 'Administration');
  String get members => pick(ru: 'Участники', en: 'Members', da: 'Medlemmer');
  String get taskTab => pick(ru: 'Задачи', en: 'Tasks', da: 'Opgaver');
  String get activityTab => pick(ru: 'Активности', en: 'Activities', da: 'Aktiviteter');
  String get history => pick(ru: 'История', en: 'History', da: 'Historik');
  String get addMember => pick(ru: 'Добавить участника', en: 'Add member', da: 'Tilføj medlem');
  String get newMember => pick(ru: 'Новый участник', en: 'New member', da: 'Nyt medlem');
  String get editMember => pick(ru: 'Редактировать участника', en: 'Edit member', da: 'Rediger medlem');
  String get name => pick(ru: 'Имя', en: 'Name', da: 'Navn');
  String get age => pick(ru: 'Возраст', en: 'Age', da: 'Alder');
  String get accountEmail => pick(ru: 'Email аккаунта', en: 'Account email', da: 'Konto-email');
  String get temporaryPassword => pick(ru: 'Временный пароль', en: 'Temporary password', da: 'Midlertidig adgangskode');
  String get leavePasswordBlank => pick(
        ru: 'Оставьте пустым, если аккаунт входа уже создан.',
        en: 'Leave empty if the sign-in account already exists.',
        da: 'Lad stå tomt, hvis login-kontoen allerede findes.',
      );
  String get role => pick(ru: 'Роль', en: 'Role', da: 'Rolle');
  String get normalUser => pick(ru: 'Обычный пользователь', en: 'Regular user', da: 'Almindelig bruger');
  String get administrator => pick(ru: 'Администратор', en: 'Administrator', da: 'Administrator');
  String get createTask => pick(ru: 'Создать задачу', en: 'Create task', da: 'Opret opgave');
  String get newTask => pick(ru: 'Новая задача', en: 'New task', da: 'Ny opgave');
  String get editTask => pick(ru: 'Редактировать задачу', en: 'Edit task', da: 'Rediger opgave');
  String get createActivity => pick(ru: 'Создать активность', en: 'Create activity', da: 'Opret aktivitet');
  String get newActivity => pick(ru: 'Новая активность', en: 'New activity', da: 'Ny aktivitet');
  String get editActivity => pick(ru: 'Редактировать активность', en: 'Edit activity', da: 'Rediger aktivitet');
  String get title => pick(ru: 'Название', en: 'Title', da: 'Titel');
  String get description => pick(ru: 'Описание', en: 'Description', da: 'Beskrivelse');
  String get location => pick(ru: 'Место', en: 'Location', da: 'Sted');
  String get startTime => pick(ru: 'Время начала', en: 'Start time', da: 'Starttid');
  String get endTime => pick(ru: 'Время окончания', en: 'End time', da: 'Sluttid');
  String get leaveHomeTime => pick(ru: 'Когда выйти из дома', en: 'When to leave home', da: 'Hvornår man skal gå hjemmefra');
  String get leaveNow => pick(ru: 'Пора выходить', en: 'Time to leave', da: 'Tid til at gå');
  String get acceptActivity => pick(ru: 'Понял', en: 'Accepted', da: 'Forstået');
  String get onWayActivity => pick(ru: 'Я вышел', en: 'I am on my way', da: 'Jeg er på vej');
  String get finishActivity => pick(ru: 'Закончил', en: 'Finished', da: 'Færdig');
  String get activityStatusPlanned => pick(ru: 'Запланировано', en: 'Planned', da: 'Planlagt');
  String get activityStatusAccepted => pick(ru: 'Принято', en: 'Accepted', da: 'Accepteret');
  String get activityStatusOnWay => pick(ru: 'В пути', en: 'On the way', da: 'På vej');
  String get activityStatusCompleted => pick(ru: 'Завершено', en: 'Completed', da: 'Fuldført');
  String get activityStatusMissed => pick(ru: 'Пропущено', en: 'Missed', da: 'Misset');
  String get dailyActivityTime => pick(ru: 'Время на активностях сегодня', en: 'Activity time today', da: 'Tid på aktiviteter i dag');
  String get activityTimeByMember => pick(ru: 'Время по участникам за сегодня', en: 'Time by member today', da: 'Tid pr. medlem i dag');
  String get taskStatsCalculated => pick(
        ru: 'Задачи считаются по выполненным задачам, а баллы берутся из баланса профиля.',
        en: 'Tasks are calculated from completed tasks, and points come from the profile balance.',
        da: 'Opgaver beregnes fra fuldførte opgaver, og point kommer fra profilsaldoen.',
      );
  String moneyForPoints(int points, double pointValue) {
    final amount = points * pointValue;
    return pick(
      ru: '${amount.toStringAsFixed(2)} DKK',
      en: '${amount.toStringAsFixed(2)} DKK',
      da: '${amount.toStringAsFixed(2)} kr.',
    );
  }
  String pointsAndMoney(int points, double pointValue) => pick(
        ru: '${pointsCount(points)} = ${moneyForPoints(points, pointValue)}',
        en: '${pointsCount(points)} = ${moneyForPoints(points, pointValue)}',
        da: '${pointsCount(points)} = ${moneyForPoints(points, pointValue)}',
      );
  String get todayPoints => pick(ru: 'Баллы сегодня', en: 'Points today', da: 'Point i dag');
  String get totalPoints => pick(ru: 'Баллы всего', en: 'Total points', da: 'Point i alt');
  String get pointValueDkk => pick(ru: 'Цена 1 балла в DKK', en: 'Value of 1 point in DKK', da: 'Værdi af 1 point i DKK');
  String get savePointValue => pick(ru: 'Сохранить цену балла', en: 'Save point value', da: 'Gem pointværdi');
  String get uploadProgress => pick(ru: 'Загрузка фото', en: 'Photo upload', da: 'Foto upload');
  String get photoZoom => pick(ru: 'Масштаб фото', en: 'Photo zoom', da: 'Foto zoom');
  String get choosePhotoFraming => pick(ru: 'Выбери приближение фото', en: 'Choose photo framing', da: 'Vælg fotoudsnit');
  String activityReminder(String title) => pick(
        ru: 'Напоминание: пора выходить на "$title".',
        en: 'Reminder: it is time to leave for "$title".',
        da: 'Påmindelse: det er tid til at gå til "$title".',
      );
  String activityFor(String memberName) => pick(
        ru: 'Активность: $memberName',
        en: 'Activity: $memberName',
        da: 'Aktivitet: $memberName',
      );
  String activityDuration(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) {
      return pick(ru: '$rest мин', en: '$rest min', da: '$rest min');
    }
    if (rest == 0) {
      return pick(ru: '$hours ч', en: '$hours h', da: '$hours t');
    }
    return pick(ru: '$hours ч $rest мин', en: '$hours h $rest min', da: '$hours t $rest min');
  }
  String activityStatus(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.planned:
        return activityStatusPlanned;
      case ActivityStatus.accepted:
        return activityStatusAccepted;
      case ActivityStatus.onWay:
        return activityStatusOnWay;
      case ActivityStatus.completed:
        return activityStatusCompleted;
      case ActivityStatus.missed:
        return activityStatusMissed;
    }
  }
  String get assignee => pick(ru: 'Исполнитель', en: 'Assignee', da: 'Ansvarlig');
  String get priority => pick(ru: 'Приоритет', en: 'Priority', da: 'Prioritet');
  String get recurrence => pick(ru: 'Повторение', en: 'Repeat', da: 'Gentagelse');
  String get status => pick(ru: 'Статус', en: 'Status', da: 'Status');
  String get message => pick(ru: 'Сообщение', en: 'Message', da: 'Besked');
  String get publishAnnouncement => pick(ru: 'Опубликовать объявление', en: 'Publish announcement', da: 'Udgiv meddelelse');
  String get newAnnouncement => pick(ru: 'Новое объявление', en: 'New announcement', da: 'Ny meddelelse');
  String get editAnnouncement => pick(ru: 'Редактировать объявление', en: 'Edit announcement', da: 'Rediger meddelelse');
  String get createJsonBackup => pick(ru: 'Создать резервную копию JSON', en: 'Create JSON backup', da: 'Opret JSON-sikkerhedskopi');
  String get historyEmpty => pick(ru: 'История пока пустая', en: 'History is empty', da: 'Historikken er tom');
  String get backup => pick(ru: 'Резервная копия', en: 'Backup', da: 'Sikkerhedskopi');
  String get close => pick(ru: 'Закрыть', en: 'Close', da: 'Luk');

  String taskStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return pick(ru: 'Ожидает', en: 'Pending', da: 'Afventer');
      case TaskStatus.inProgress:
        return pick(ru: 'Выполняется', en: 'In progress', da: 'I gang');
      case TaskStatus.awaitingApproval:
        return pick(ru: 'На проверке', en: 'Needs approval', da: 'Til kontrol');
      case TaskStatus.done:
        return pick(ru: 'Выполнено', en: 'Done', da: 'Fuldført');
      case TaskStatus.overdue:
        return pick(ru: 'Просрочено', en: 'Overdue', da: 'Forsinket');
    }
  }

  String taskPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return pick(ru: 'Низкий', en: 'Low', da: 'Lav');
      case TaskPriority.normal:
        return pick(ru: 'Обычный', en: 'Normal', da: 'Normal');
      case TaskPriority.high:
        return pick(ru: 'Высокий', en: 'High', da: 'Høj');
      case TaskPriority.urgent:
        return pick(ru: 'Срочный', en: 'Urgent', da: 'Haster');
    }
  }

  String taskRecurrence(TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.once:
        return pick(ru: 'Один раз', en: 'Once', da: 'En gang');
      case TaskRecurrence.daily:
        return pick(ru: 'Каждый день', en: 'Every day', da: 'Hver dag');
      case TaskRecurrence.weekly:
        return pick(ru: 'Каждую неделю', en: 'Every week', da: 'Hver uge');
      case TaskRecurrence.monthly:
        return pick(ru: 'Каждый месяц', en: 'Every month', da: 'Hver måned');
    }
  }

  String authError(String code, String? message) {
    switch (code) {
      case 'invalid-credential':
        return pick(
          ru: 'invalid-credential: email или пароль неверный, либо пользователь не создан в Firebase Authentication.',
          en: 'invalid-credential: the email or password is wrong, or the user was not created in Firebase Authentication.',
          da: 'invalid-credential: email eller adgangskode er forkert, eller brugeren er ikke oprettet i Firebase Authentication.',
        );
      case 'user-not-found':
        return pick(
          ru: 'user-not-found: такого email нет в Firebase Authentication.',
          en: 'user-not-found: this email is not in Firebase Authentication.',
          da: 'user-not-found: denne email findes ikke i Firebase Authentication.',
        );
      case 'wrong-password':
        return pick(ru: 'wrong-password: пароль неверный.', en: 'wrong-password: wrong password.', da: 'wrong-password: forkert adgangskode.');
      case 'unauthorized-domain':
        return pick(
          ru: 'unauthorized-domain: добавьте домен в Authentication -> Settings -> Authorized domains.',
          en: 'unauthorized-domain: add the domain in Authentication -> Settings -> Authorized domains.',
          da: 'unauthorized-domain: tilføj domænet i Authentication -> Settings -> Authorized domains.',
        );
      case 'family-login-not-found':
        return pick(
          ru: 'family-login-not-found: семейный логин еще не создан в Firestore.',
          en: 'family-login-not-found: this family login has not been created in Firestore yet.',
          da: 'family-login-not-found: dette familielogin er ikke oprettet i Firestore endnu.',
        );
      default:
        return '$code: ${message ?? 'Firebase Auth error'}';
    }
  }
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppStrings.supportedLocales.any((item) => item.languageCode == locale.languageCode);
  }

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
