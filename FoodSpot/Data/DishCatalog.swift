import Foundation

/// Kuratierte Basisliste gängiger Gerichte für die Autocomplete beim
/// Bewerten. Ist ein Gericht nicht dabei, tippt der Nutzer einfach frei
/// weiter — der eingegebene Text wird 1:1 als neuer Dish-Tag gespeichert.
struct DishCatalogEntry: Identifiable {
    let name: String
    let synonyms: [String]

    var id: String { name }
}

enum DishCatalog {
    static func search(_ query: String) -> [DishCatalogEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        return all
            .filter { entry in
                entry.name.localizedCaseInsensitiveContains(trimmed)
                    || entry.synonyms.contains { $0.localizedCaseInsensitiveContains(trimmed) }
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static let all: [DishCatalogEntry] = [
        // Deutsch / Österreichisch
        DishCatalogEntry(name: "Schnitzel", synonyms: ["Wiener Schnitzel"]),
        DishCatalogEntry(name: "Currywurst", synonyms: []),
        DishCatalogEntry(name: "Bratwurst", synonyms: []),
        DishCatalogEntry(name: "Sauerbraten", synonyms: []),
        DishCatalogEntry(name: "Kaiserschmarrn", synonyms: []),
        DishCatalogEntry(name: "Käsespätzle", synonyms: ["Spätzle"]),
        DishCatalogEntry(name: "Maultaschen", synonyms: []),
        DishCatalogEntry(name: "Rouladen", synonyms: ["Rinderroulade"]),
        DishCatalogEntry(name: "Eisbein", synonyms: []),
        DishCatalogEntry(name: "Knödel", synonyms: ["Kloß"]),
        DishCatalogEntry(name: "Frikadelle", synonyms: ["Bulette", "Fleischpflanzerl"]),
        DishCatalogEntry(name: "Flammkuchen", synonyms: ["Tarte Flambée"]),
        DishCatalogEntry(name: "Kartoffelsalat", synonyms: []),
        DishCatalogEntry(name: "Königsberger Klopse", synonyms: []),
        DishCatalogEntry(name: "Gulasch", synonyms: []),
        DishCatalogEntry(name: "Zwiebelkuchen", synonyms: []),
        DishCatalogEntry(name: "Labskaus", synonyms: []),
        DishCatalogEntry(name: "Apfelstrudel", synonyms: []),
        DishCatalogEntry(name: "Pommes", synonyms: ["Fritten", "Pommes Frites"]),

        // Türkisch / Nahost
        DishCatalogEntry(name: "Döner", synonyms: ["Kebab", "Dürüm"]),
        DishCatalogEntry(name: "Falafel", synonyms: []),
        DishCatalogEntry(name: "Hummus", synonyms: []),
        DishCatalogEntry(name: "Lahmacun", synonyms: ["Türkische Pizza"]),
        DishCatalogEntry(name: "Pide", synonyms: []),
        DishCatalogEntry(name: "Shawarma", synonyms: []),
        DishCatalogEntry(name: "Baklava", synonyms: []),
        DishCatalogEntry(name: "Köfte", synonyms: []),
        DishCatalogEntry(name: "Adana Kebap", synonyms: []),
        DishCatalogEntry(name: "Manti", synonyms: []),
        DishCatalogEntry(name: "Tabbouleh", synonyms: []),
        DishCatalogEntry(name: "Shakshuka", synonyms: []),

        // Italienisch
        DishCatalogEntry(name: "Pizza Margherita", synonyms: ["Pizza"]),
        DishCatalogEntry(name: "Pizza Salami", synonyms: []),
        DishCatalogEntry(name: "Spaghetti Carbonara", synonyms: ["Carbonara"]),
        DishCatalogEntry(name: "Spaghetti Bolognese", synonyms: ["Bolognese"]),
        DishCatalogEntry(name: "Lasagne", synonyms: []),
        DishCatalogEntry(name: "Risotto", synonyms: []),
        DishCatalogEntry(name: "Gnocchi", synonyms: []),
        DishCatalogEntry(name: "Tiramisu", synonyms: []),
        DishCatalogEntry(name: "Caprese", synonyms: []),
        DishCatalogEntry(name: "Ravioli", synonyms: []),
        DishCatalogEntry(name: "Pesto Pasta", synonyms: []),
        DishCatalogEntry(name: "Ossobuco", synonyms: []),
        DishCatalogEntry(name: "Panna Cotta", synonyms: []),
        DishCatalogEntry(name: "Minestrone", synonyms: []),
        DishCatalogEntry(name: "Arancini", synonyms: []),

        // Japanisch
        DishCatalogEntry(name: "Ramen", synonyms: []),
        DishCatalogEntry(name: "Sushi", synonyms: []),
        DishCatalogEntry(name: "Sashimi", synonyms: []),
        DishCatalogEntry(name: "Tempura", synonyms: []),
        DishCatalogEntry(name: "Udon", synonyms: []),
        DishCatalogEntry(name: "Gyoza", synonyms: []),
        DishCatalogEntry(name: "Teriyaki", synonyms: []),
        DishCatalogEntry(name: "Miso-Suppe", synonyms: []),
        DishCatalogEntry(name: "Katsu Curry", synonyms: []),
        DishCatalogEntry(name: "Onigiri", synonyms: []),

        // Chinesisch
        DishCatalogEntry(name: "Peking-Ente", synonyms: []),
        DishCatalogEntry(name: "Gebratener Reis", synonyms: ["Nasi Goreng"]),
        DishCatalogEntry(name: "Dim Sum", synonyms: []),
        DishCatalogEntry(name: "Kung Pao Chicken", synonyms: []),
        DishCatalogEntry(name: "Frühlingsrolle", synonyms: []),
        DishCatalogEntry(name: "Süß-Sauer", synonyms: ["Süß-Sauer-Huhn"]),
        DishCatalogEntry(name: "Mapo Tofu", synonyms: []),

        // Thailändisch
        DishCatalogEntry(name: "Pad Thai", synonyms: []),
        DishCatalogEntry(name: "Grünes Curry", synonyms: ["Green Curry"]),
        DishCatalogEntry(name: "Tom Yum", synonyms: []),
        DishCatalogEntry(name: "Som Tam", synonyms: ["Papayasalat"]),

        // Vietnamesisch
        DishCatalogEntry(name: "Pho", synonyms: []),
        DishCatalogEntry(name: "Bun Cha", synonyms: []),
        DishCatalogEntry(name: "Banh Mi", synonyms: []),
        DishCatalogEntry(name: "Sommerrolle", synonyms: ["Frühlingsrolle Vietnamesisch"]),

        // Koreanisch
        DishCatalogEntry(name: "Bibimbap", synonyms: []),
        DishCatalogEntry(name: "Bulgogi", synonyms: []),
        DishCatalogEntry(name: "Kimchi", synonyms: []),
        DishCatalogEntry(name: "Korean Fried Chicken", synonyms: []),

        // Indisch
        DishCatalogEntry(name: "Chicken Tikka Masala", synonyms: []),
        DishCatalogEntry(name: "Butter Chicken", synonyms: []),
        DishCatalogEntry(name: "Biryani", synonyms: []),
        DishCatalogEntry(name: "Samosa", synonyms: []),
        DishCatalogEntry(name: "Naan", synonyms: []),
        DishCatalogEntry(name: "Dal", synonyms: ["Linsencurry"]),
        DishCatalogEntry(name: "Palak Paneer", synonyms: []),
        DishCatalogEntry(name: "Tandoori Chicken", synonyms: []),
        DishCatalogEntry(name: "Vindaloo", synonyms: []),

        // Griechisch
        DishCatalogEntry(name: "Gyros", synonyms: []),
        DishCatalogEntry(name: "Souvlaki", synonyms: []),
        DishCatalogEntry(name: "Moussaka", synonyms: []),
        DishCatalogEntry(name: "Tzatziki", synonyms: []),
        DishCatalogEntry(name: "Griechischer Salat", synonyms: []),

        // Mexikanisch
        DishCatalogEntry(name: "Tacos", synonyms: []),
        DishCatalogEntry(name: "Burrito", synonyms: []),
        DishCatalogEntry(name: "Quesadilla", synonyms: []),
        DishCatalogEntry(name: "Nachos", synonyms: []),
        DishCatalogEntry(name: "Enchiladas", synonyms: []),
        DishCatalogEntry(name: "Guacamole", synonyms: []),

        // Amerikanisch / Fast Food
        DishCatalogEntry(name: "Burger", synonyms: ["Cheeseburger", "Hamburger"]),
        DishCatalogEntry(name: "Hot Dog", synonyms: []),
        DishCatalogEntry(name: "Chicken Wings", synonyms: []),
        DishCatalogEntry(name: "BBQ Ribs", synonyms: ["Spare Ribs"]),
        DishCatalogEntry(name: "Mac and Cheese", synonyms: []),
        DishCatalogEntry(name: "Pancakes", synonyms: []),
        DishCatalogEntry(name: "Caesar Salad", synonyms: []),

        // Französisch
        DishCatalogEntry(name: "Croissant", synonyms: []),
        DishCatalogEntry(name: "Quiche Lorraine", synonyms: ["Quiche"]),
        DishCatalogEntry(name: "Coq au Vin", synonyms: []),
        DishCatalogEntry(name: "Ratatouille", synonyms: []),
        DishCatalogEntry(name: "Crème Brûlée", synonyms: []),
        DishCatalogEntry(name: "Zwiebelsuppe", synonyms: ["Onion Soup"]),
        DishCatalogEntry(name: "Boeuf Bourguignon", synonyms: []),
        DishCatalogEntry(name: "Crêpes", synonyms: []),

        // Spanisch
        DishCatalogEntry(name: "Paella", synonyms: []),
        DishCatalogEntry(name: "Tapas", synonyms: []),
        DishCatalogEntry(name: "Tortilla Española", synonyms: []),
        DishCatalogEntry(name: "Churros", synonyms: []),
        DishCatalogEntry(name: "Gazpacho", synonyms: []),

        // Fisch / Meeresfrüchte
        DishCatalogEntry(name: "Fish and Chips", synonyms: []),
        DishCatalogEntry(name: "Fischbrötchen", synonyms: []),
        DishCatalogEntry(name: "Räucherlachs", synonyms: []),
        DishCatalogEntry(name: "Miesmuscheln", synonyms: ["Moules Frites"]),

        // Frühstück / Bäckerei / Dessert
        DishCatalogEntry(name: "Waffeln", synonyms: []),
        DishCatalogEntry(name: "Brezel", synonyms: ["Brezn"]),
        DishCatalogEntry(name: "Apfelkuchen", synonyms: []),
        DishCatalogEntry(name: "Käsekuchen", synonyms: ["Cheesecake"]),
        DishCatalogEntry(name: "Donut", synonyms: []),
        DishCatalogEntry(name: "Eis", synonyms: ["Gelato", "Eiscreme"]),

        // Bowls / Vegetarisch / Vegan
        DishCatalogEntry(name: "Buddha Bowl", synonyms: []),
        DishCatalogEntry(name: "Poke Bowl", synonyms: []),
        DishCatalogEntry(name: "Veggie Burger", synonyms: []),
    ]
}
