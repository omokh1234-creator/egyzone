class ProductsData {
  static const List<Map<String, dynamic>> allProducts = [
    {
      "id": 1,
      "name": "Galaxy S24",
      "category": "Electronics",
      "subcategory": "Mobile Phones",
      "price": 18000.00,
      "rating": 4.7,
      "images": [
        {
          "url": "assets/images/Smasung s24/Samsung-Galaxy-S24-256GB-US-Version-Unlocked-Android-Smartphone-with-50MP-Camera-8K-Video-Long-Battery-Marble-Gray_c70f133f-968b-459c-ad11-bef1e287b7ea.db451ef78808754c12262de42fb341c6.jpeg",
          "semanticLabel": "Galaxy S24 front view"
        }
      ],
      "description": "The new Samsung Galaxy S24 with stunning AMOLED display.",
      "specifications": [
        {"label": "Display", "value": "6.5-inch AMOLED"}
      ],
      "inStock": true
    },
    {
      "id": 2,
      "name": "iPhone 15 Pro",
      "category": "Electronics",
      "subcategory": "Mobile Phones",
      "price": 70000.00,
      "rating": 4.8,
      "images": [
        {
          "url": "assets/images/iPhone_15_Pro/Apple-iPhone-15-Pro-Hero-Gear.jpg",
          "semanticLabel": "iPhone 15 Pro front view"
        }
      ],
      "description": "Apple iPhone 15 Pro with A17 Bionic chip.",
      "specifications": [
        {"label": "Display", "value": "6.1-inch Super Retina XDR"}
      ],
      "inStock": true
    }
    // ... adding others if I had them, but for brevity let's start with a few or extract from home_screen
  ];
}
