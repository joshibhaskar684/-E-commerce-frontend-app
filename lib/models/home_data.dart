/// Static home-page content, copied from the website so both look the same:
///   banners    ← components/Home/HomeComponent/HeroSectionCarsoule/Carsoule.js
///   categories ← components/Home/HomeComponent/CategorySection/CategoryData.js
///   popular    ← components/Navbar/components/SearchBar.jsx (POPULAR_SEARCHES)
class HomeBanner {
  const HomeBanner(this.image);
  final String image;
}

class HomeCategory {
  const HomeCategory({required this.name, required this.category, required this.image});

  /// Label shown in the UI.
  final String name;

  /// Value sent as `?category=` to /products/page/category/main
  /// (matched against the product's categoryPath).
  final String category;
  final String image;
}

class HomeData {
  HomeData._();

  static const banners = [
    HomeBanner('https://cdn2.shopclues.com/images/banners/2025/Oct/27/Smartphone_Web-27Oct25.jpg'),
    HomeBanner('https://cdn2.shopclues.com/images/banners/2026/Feb/06/Sunday-Flea-Market-Web-06Feb26.jpg'),
    HomeBanner('https://cdn2.shopclues.com/images/banners/2026/Jan/05/Winter-Fashion-Web-5jan25.jpg'),
    HomeBanner('https://cdn2.shopclues.com/images/banners/2025/Oct/16/Intell-Web-16Oct2025.jpg'),
  ];

  static const categories = [
    HomeCategory(
      name: 'Clothing',
      category: 'Clothing',
      image:
          'https://media.istockphoto.com/id/493626860/photo/colorful-saree-background.jpg?s=612x612&w=0&k=20&c=3buwZCcNoW-nZITKAAEonZBD6onlrOPq1yDH_lAuegc=',
    ),
    HomeCategory(
      name: 'Footwear',
      category: 'footwear',
      image:
          'https://media.istockphoto.com/id/812006616/photo/mens-shoe-isolated-on-gray.jpg?s=612x612&w=0&k=20&c=V_5t-jkUBYrAZcXTeBPg9l_UjI17rXTagpVEq4A79N8=',
    ),
    HomeCategory(
      name: 'Accessories',
      category: 'accessories',
      image:
          'https://media.istockphoto.com/id/626234448/photo/luxury-handbags.jpg?s=612x612&w=0&k=20&c=Zz4OsUc67DLv5wLftwYd1_NeYmQmb4RCBuaCVttpM4w=',
    ),
    HomeCategory(
      name: 'Electronics',
      category: 'electronics',
      image:
          'https://media.istockphoto.com/id/1211554164/photo/3d-render-of-home-appliances-collection-set.jpg?s=612x612&w=0&k=20&c=blm3IyPyZo5ElWLOjI-hFMG-NrKQ0G76JpWGyNttF8s=',
    ),
    HomeCategory(
      name: 'Home & Living',
      category: 'home-and-living',
      image:
          'https://media.istockphoto.com/id/1293762741/photo/modern-living-room-interior-3d-render.jpg?s=612x612&w=0&k=20&c=iZ561ZIXOtPYGSzqlKUnLrliorreOYVz1pzu8WJmrnc=',
    ),
    HomeCategory(
      name: 'Books',
      category: 'books',
      image:
          'https://media.istockphoto.com/id/1317371614/vector/simple-hand-book-minimal-vector.jpg?s=612x612&w=0&k=20&c=cy8ojb4EFNgIjDrk38WWEA48ZxeDjLwM35wrFrs2K0w=',
    ),
  ];

  static const popularSearches = [
    'Headphones',
    'Gaming Laptop',
    'Running Shoes',
    'Smartwatch',
    'Coffee Machine',
  ];
}
