
enum TabItem: Int, CaseIterable {
    case settings   = 0
    case home
    case movies
    case series
    case cartoons
    case favorites
    case watching
    case search

    var title: String {
        switch self {
        case .settings:  return "Настройки"
        case .home:      return "Главная"
        case .movies:    return "Фильмы"
        case .series:    return "Сериалы"
        case .cartoons:  return "Мультфильмы"
        case .favorites: return "Избранное"
        case .watching:  return "Смотрю"
        case .search:    return "Search"
        }
    }

    var sfSymbol: String {
        switch self {
        case .settings:  return "gearshape.fill"
        case .home:      return "house.fill"
        case .movies:    return "film.stack.fill"
        case .series:    return "tv.fill"
        case .cartoons:  return "sparkles.tv.fill"
        case .favorites: return "star.fill"
        case .watching:  return "eye.fill"
        case .search:    return "magnifyingglass"
        }
    }

    var isIconOnly:    Bool { self == .settings }
    var isButtonStyle: Bool { self == .search }
}
