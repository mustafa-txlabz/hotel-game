import 'dart:ui' show Color;

/// Metadata for each of the 10 franchise locations on the City Travel Map.
class CityShopInfo {
  final int number;
  final String id;
  final String name;
  final String subtitle;
  final String emoji;
  final String category;
  final String description;
  final List<String> specialtyItems;
  final Color accentColor;
  final Color roofColor;
  final bool isPlayable;
  final bool isSupermarket;

  const CityShopInfo({
    required this.number,
    required this.id,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.category,
    required this.description,
    required this.specialtyItems,
    required this.accentColor,
    required this.roofColor,
    this.isPlayable = false,
    this.isSupermarket = false,
  });
}

/// Catalog of all 10 shops along the scenic highway & mountain route.
class CityShopsCatalog {
  CityShopsCatalog._();

  static const List<CityShopInfo> shops = [
    CityShopInfo(
      number: 1,
      id: 'store_1',
      name: 'Highway Kadak Dhaba',
      subtitle: 'GT Road • Chai & Paratha',
      emoji: '☕',
      category: 'Classic Dhaba',
      description:
          'Your flagship roadside dhaba! Brew steaming kadak chai, flip crispy tawa parathas, and serve VVIP luxury cars.',
      specialtyItems: ['☕ Kadak Chai', '🫓 Tawa Paratha', '🚗 VVIP Curbside'],
      accentColor: Color(0xFFFF8F00),
      roofColor: Color(0xFFD84315),
      isPlayable: true,
    ),
    CityShopInfo(
      number: 2,
      id: 'store_2',
      name: 'Desi Fast Food Corner',
      subtitle: 'City Food Street • Burgers & Fries',
      emoji: '🍔',
      category: 'Fast Food',
      description:
          'Sizzling bun kababs, crispy masala fries, and loaded zinger burgers for the bustling city crowd.',
      specialtyItems: ['🍔 Bun Kabab', '🍟 Masala Fries', '🍗 Crispy Zinger'],
      accentColor: Color(0xFFE53935),
      roofColor: Color(0xFFB71C1C),
    ),
    CityShopInfo(
      number: 3,
      id: 'store_3',
      name: 'Shahi Mithai & Sweets',
      subtitle: 'Anarkali Bazaar • Traditional Sweets',
      emoji: '🍮',
      category: 'Sweet Shop',
      description:
          'Warm syrupy gulab jamuns, crispy golden jalebis, and royal pistachio barfi gift boxes.',
      specialtyItems: ['🍮 Gulab Jamun', '🥨 Hot Jalebi', '🍬 Pistachio Barfi'],
      accentColor: Color(0xFFEC407A),
      roofColor: Color(0xFFAD1457),
    ),
    CityShopInfo(
      number: 4,
      id: 'store_4',
      name: 'Golden Oven Bakery',
      subtitle: 'Mall Road • Cakes & Pastries',
      emoji: '🥐',
      category: 'Bakery',
      description:
          'Freshly baked puff patties, butter croissants, cream cakes, and crunchy bakery biscuits.',
      specialtyItems: ['🥐 Croissants', '🍰 Cream Cakes', '🥧 Chicken Patties'],
      accentColor: Color(0xFFFFB300),
      roofColor: Color(0xFF8D6E63),
    ),
    CityShopInfo(
      number: 5,
      id: 'store_5',
      name: 'Chill & Scoops Parlor',
      subtitle: 'Canal View • Ice Cream & Kulfi',
      emoji: '🍦',
      category: 'Ice Cream',
      description:
          'Beat the heat with creamy matka kulfi, double-scoop waffle cones, and royal rabri falooda!',
      specialtyItems: ['🍦 Waffle Cones', '🍨 Royal Falooda', '🍡 Matka Kulfi'],
      accentColor: Color(0xFF29B6F6),
      roofColor: Color(0xFF0277BD),
    ),
    CityShopInfo(
      number: 6,
      id: 'store_6',
      name: 'Charcoal Tikka & BBQ',
      subtitle: 'Hillside Terrace • Live Grill',
      emoji: '🍢',
      category: 'BBQ & Grill',
      description:
          'Smoky chicken tikka, juicy seekh kababs, and garlic naan straight from the glowing tandoor.',
      specialtyItems: ['🍢 Seekh Kabab', '🍗 Chicken Tikka', '🫓 Garlic Naan'],
      accentColor: Color(0xFFFF5722),
      roofColor: Color(0xFFBF360C),
    ),
    CityShopInfo(
      number: 7,
      id: 'store_7',
      name: 'Fresh Juice & Lassi Bar',
      subtitle: 'Park Avenue • Shakes & Lassi',
      emoji: '🥭',
      category: 'Juice & Lassi',
      description:
          'Thick Punjabi sweet lassi, chilled mango shakes, and sparkling lemon mint coolers.',
      specialtyItems: ['🥭 Mango Shake', '🥛 Sweet Lassi', '🍋 Mint Cooler'],
      accentColor: Color(0xFF66BB6A),
      roofColor: Color(0xFF2E7D32),
    ),
    CityShopInfo(
      number: 8,
      id: 'store_8',
      name: 'Royal Biryani & Pulao',
      subtitle: 'Heritage Square • Spice Kitchen',
      emoji: '🍛',
      category: 'Biryani House',
      description:
          'Aromatic saffron-layered Karachi biryani, tender beef pulao, and chilled mint raita bowls.',
      specialtyItems: ['🍛 Spicy Biryani', '🍚 Beef Pulao', '🥣 Mint Raita'],
      accentColor: Color(0xFFFFA726),
      roofColor: Color(0xFFE65100),
    ),
    CityShopInfo(
      number: 9,
      id: 'store_9',
      name: 'Pizza & Shawarma Express',
      subtitle: 'Tech Hub • Wood-Fired & Wraps',
      emoji: '🍕',
      category: 'Pizza & Wraps',
      description:
          'Cheesy tikka wood-fired pizzas, toasted garlic shawarma wraps, and loaded cheese fries.',
      specialtyItems: ['🍕 Tikka Pizza', '🌯 Garlic Shawarma', '🧀 Cheese Fries'],
      accentColor: Color(0xFFAB47BC),
      roofColor: Color(0xFF6A1B9A),
    ),
    CityShopInfo(
      number: 10,
      id: 'store_10',
      name: 'GRAND EMPIRE SUPERMARKET',
      subtitle: 'Mountain Summit • Mega Mall & All 9 Shops',
      emoji: '🏬',
      category: 'Mega Supermarket',
      description:
          'The ultimate colossal empire! Features massive floor space, ALL items from Shops 1–9 combined, plus exclusive supermarket groceries & mega VIP orders!',
      specialtyItems: [
        '🛒 Mega Groceries',
        '☕🍔🍮 All 9 Shops',
        '👑 Ultra VIP Lanes',
      ],
      accentColor: Color(0xFFFFD54F),
      roofColor: Color(0xFF4A148C),
      isSupermarket: true,
    ),
  ];
}
