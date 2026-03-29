
struct ProviderCategory: Sendable, Identifiable {
    let id:             String
    let title:          String
    let icon:           String
    let url:            String?
    let genres:         [ProviderGenre]
    var isFavorites:    Bool = false
    var isWatchHistory: Bool = false
    var isSearch:       Bool = false
}

extension ProviderCategory {

    static let filmixDefaults: [ProviderCategory] = [
        ProviderCategory(id: "home",      title: "Главная",      icon: "house.fill",
                         url: "https://filmix.my", genres: []),
        ProviderCategory(id: "movies",    title: "Фильмы",       icon: "film.fill",
                         url: "https://filmix.my/film/",  genres: ProviderGenre.filmixMovies),
        ProviderCategory(id: "series",    title: "Сериалы",      icon: "tv.fill",
                         url: "https://filmix.my/seria/", genres: ProviderGenre.filmixSeries),
        ProviderCategory(id: "cartoons",  title: "Мультфильмы",  icon: "sparkles.tv.fill",
                         url: "https://filmix.my/mults/", genres: ProviderGenre.filmixCartoons),
        ProviderCategory(id: "favorites", title: "Избранное",    icon: "star.fill",
                         url: nil, genres: [], isFavorites: true),
        ProviderCategory(id: "watching",  title: "Смотрю",       icon: "play.circle.fill",
                         url: nil, genres: [], isWatchHistory: true),
    ]
}
