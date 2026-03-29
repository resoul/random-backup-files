
struct ProviderGenre: Sendable {
    let title: String
    let url:   String
}

extension ProviderGenre {

    static let filmixMovies: [ProviderGenre] = [
        ProviderGenre(title: "Боевики",        url: "https://filmix.my/film/boevik/"),
        ProviderGenre(title: "Комедии",        url: "https://filmix.my/film/komedia/"),
        ProviderGenre(title: "Драмы",          url: "https://filmix.my/film/drama/"),
        ProviderGenre(title: "Ужасы",          url: "https://filmix.my/film/uzhasu/"),
        ProviderGenre(title: "Фантастика",     url: "https://filmix.my/film/fantastiks/"),
        ProviderGenre(title: "Триллеры",       url: "https://filmix.my/film/triller/"),
        ProviderGenre(title: "Мелодрамы",      url: "https://filmix.my/film/melodrama/"),
        ProviderGenre(title: "Криминал",       url: "https://filmix.my/film/kriminaly/"),
        ProviderGenre(title: "Документальные", url: "https://filmix.my/film/dokumentalenyj/"),
        ProviderGenre(title: "Аниме",          url: "https://filmix.my/film/animes/"),
        ProviderGenre(title: "Приключения",    url: "https://filmix.my/film/prikluchenija/"),
        ProviderGenre(title: "Семейный",       url: "https://filmix.my/film/semejnye/"),
        ProviderGenre(title: "Мистика",        url: "https://filmix.my/film/mistika/"),
        ProviderGenre(title: "Исторический",   url: "https://filmix.my/film/istoricheskie/"),
        ProviderGenre(title: "Фэнтези",        url: "https://filmix.my/film/fjuntezia/"),
        ProviderGenre(title: "Биография",      url: "https://filmix.my/film/biografia/"),
        ProviderGenre(title: "Военный",        url: "https://filmix.my/film/voennyj/"),
        ProviderGenre(title: "Детектив",       url: "https://filmix.my/film/detektivy/"),
        ProviderGenre(title: "Вестерн",        url: "https://filmix.my/film/vesterny/"),
        ProviderGenre(title: "Спорт",          url: "https://filmix.my/film/sports/"),
    ]

    static let filmixSeries: [ProviderGenre] = [
        ProviderGenre(title: "Боевики",        url: "https://filmix.my/seria/boevik/s7/"),
        ProviderGenre(title: "Комедии",        url: "https://filmix.my/seria/komedia/s7/"),
        ProviderGenre(title: "Драмы",          url: "https://filmix.my/seria/drama/s7/"),
        ProviderGenre(title: "Ужасы",          url: "https://filmix.my/seria/uzhasu/s7/"),
        ProviderGenre(title: "Фантастика",     url: "https://filmix.my/seria/fantastiks/s7/"),
        ProviderGenre(title: "Триллеры",       url: "https://filmix.my/seria/triller/s7/"),
        ProviderGenre(title: "Мелодрамы",      url: "https://filmix.my/seria/melodrama/s7/"),
        ProviderGenre(title: "Дорамы",         url: "https://filmix.my/seria/dorama/s7/"),
        ProviderGenre(title: "Аниме",          url: "https://filmix.my/seria/animes/s7/"),
        ProviderGenre(title: "Криминал",       url: "https://filmix.my/seria/kriminaly/s7/"),
        ProviderGenre(title: "Документальные", url: "https://filmix.my/seria/dokumentalenyj/s7/"),
        ProviderGenre(title: "Мистика",        url: "https://filmix.my/seria/mistika/s7/"),
        ProviderGenre(title: "Исторический",   url: "https://filmix.my/seria/istoricheskie/s7/"),
        ProviderGenre(title: "Фэнтези",        url: "https://filmix.my/seria/fjuntezia/s7/"),
        ProviderGenre(title: "Ситком",         url: "https://filmix.my/seria/sitcom/s7/"),
        ProviderGenre(title: "Военный",        url: "https://filmix.my/seria/voennyj/s7/"),
        ProviderGenre(title: "Детектив",       url: "https://filmix.my/seria/detektivy/s7/"),
    ]

    static let filmixCartoons: [ProviderGenre] = [
        ProviderGenre(title: "Аниме",          url: "https://filmix.my/mults/animes/s14/"),
        ProviderGenre(title: "Комедии",        url: "https://filmix.my/mults/komedia/s14/"),
        ProviderGenre(title: "Приключения",    url: "https://filmix.my/mults/prikluchenija/s14/"),
        ProviderGenre(title: "Семейный",       url: "https://filmix.my/mults/semejnye/s14/"),
        ProviderGenre(title: "Фантастика",     url: "https://filmix.my/mults/fantastiks/s14/"),
        ProviderGenre(title: "Детский",        url: "https://filmix.my/mults/detskij/s14/"),
        ProviderGenre(title: "Фэнтези",        url: "https://filmix.my/mults/fjuntezia/s14/"),
        ProviderGenre(title: "Боевики",        url: "https://filmix.my/mults/boevik/s14/"),
        ProviderGenre(title: "Драмы",          url: "https://filmix.my/mults/drama/s14/"),
        ProviderGenre(title: "Мистика",        url: "https://filmix.my/mults/mistika/s14/"),
    ]
}
