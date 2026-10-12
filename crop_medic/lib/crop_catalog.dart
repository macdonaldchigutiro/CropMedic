class CropOption {
  final String id;
  final String emoji;
  final bool aiSupported;
  final String en;
  final String sn;
  final String nd;
  final String toi;

  const CropOption({
    required this.id,
    required this.emoji,
    required this.aiSupported,
    required this.en,
    required this.sn,
    required this.nd,
    required this.toi,
  });

  String label(String lang) {
    switch (lang) {
      case 'sn':
        return sn;
      case 'nd':
        return nd;
      case 'toi':
        return toi;
      default:
        return en;
    }
  }
}

const supportedCrops = <CropOption>[
  CropOption(
    id: 'Maize',
    emoji: '🌽',
    aiSupported: true,
    en: 'Maize',
    sn: 'Chibage',
    nd: 'Umumbu',
    toi: 'Maize',
  ),
  CropOption(
    id: 'Tomato',
    emoji: '🍅',
    aiSupported: true,
    en: 'Tomato',
    sn: 'Madomasi',
    nd: 'Utamatisi',
    toi: 'Tomato',
  ),
  CropOption(
    id: 'Potato',
    emoji: '🥔',
    aiSupported: true,
    en: 'Potato',
    sn: 'Mbatatisi',
    nd: 'Amazambane',
    toi: 'Potato',
  ),
  CropOption(
    id: 'Bell pepper',
    emoji: '🫑',
    aiSupported: true,
    en: 'Bell pepper',
    sn: 'Mhiripiri',
    nd: 'Upelepele',
    toi: 'Bell pepper',
  ),
];

const roadmapCrops = <CropOption>[
  CropOption(id: 'Soybean', emoji: '🌱', aiSupported: false, en: 'Soybean', sn: 'Soya bean', nd: 'Soybean', toi: 'Soybean'),
  CropOption(id: 'Beans', emoji: '🫘', aiSupported: false, en: 'Beans', sn: 'Bhinzi', nd: 'Indumba', toi: 'Beans'),
  CropOption(id: 'Peas', emoji: '🫛', aiSupported: false, en: 'Peas', sn: 'Pizi', nd: 'Peas', toi: 'Peas'),
  CropOption(id: 'Tobacco', emoji: '🍃', aiSupported: false, en: 'Tobacco', sn: 'Fodya', nd: 'Gwayi', toi: 'Tobacco'),
  CropOption(id: 'Wheat', emoji: '🌾', aiSupported: false, en: 'Wheat', sn: 'Gorosi', nd: 'Ingqoloyi', toi: 'Wheat'),
  CropOption(id: 'Sorghum', emoji: '🌾', aiSupported: false, en: 'Sorghum', sn: 'Mapfunde', nd: 'Amabele', toi: 'Sorghum'),
  CropOption(id: 'Pearl millet', emoji: '🌾', aiSupported: false, en: 'Millet', sn: 'Mhunga', nd: 'Inyawuthi', toi: 'Millet'),
  CropOption(id: 'Finger millet', emoji: '🌾', aiSupported: false, en: 'Rapoko / finger millet', sn: 'Zviyo', nd: 'Finger millet', toi: 'Rapoko'),
  CropOption(id: 'Pumpkin', emoji: '🎃', aiSupported: false, en: 'Pumpkin', sn: 'Manhanga', nd: 'Amathanga', toi: 'Pumpkin'),
  CropOption(id: 'Watermelon', emoji: '🍉', aiSupported: false, en: 'Watermelon', sn: 'Mavise', nd: 'Ikhabe', toi: 'Watermelon'),
  CropOption(id: 'Onion', emoji: '🧅', aiSupported: false, en: 'Onion', sn: 'Hanyanisi', nd: 'Anyanisi', toi: 'Onion'),
  CropOption(id: 'Cabbage', emoji: '🥬', aiSupported: false, en: 'Cabbage', sn: 'Kabichi', nd: 'Ikhabitshi', toi: 'Cabbage'),
  CropOption(id: 'Leafy vegetables', emoji: '🥬', aiSupported: false, en: 'Leafy vegetables', sn: 'Muriwo', nd: 'Imibhida', toi: 'Vegetables'),
  CropOption(id: 'Mushroom', emoji: '🍄', aiSupported: false, en: 'Mushroom', sn: 'Howa', nd: 'Amakhowa', toi: 'Mushroom'),
  CropOption(id: 'Groundnut', emoji: '🥜', aiSupported: false, en: 'Groundnut', sn: 'Nzungu', nd: 'Amandongomane', toi: 'Groundnut'),
  CropOption(id: 'Sweet potato', emoji: '🍠', aiSupported: false, en: 'Sweet potato', sn: 'Mbambaira', nd: 'Ubhatata', toi: 'Sweet potato'),
  CropOption(id: 'Cucumber', emoji: '🥒', aiSupported: false, en: 'Cucumber', sn: 'Cucumber', nd: 'Cucumber', toi: 'Cucumber'),
  CropOption(id: 'Carrot', emoji: '🥕', aiSupported: false, en: 'Carrot', sn: 'Carrot', nd: 'Carrot', toi: 'Carrot'),
  CropOption(id: 'Sunflower', emoji: '🌻', aiSupported: false, en: 'Sunflower', sn: 'Sunflower', nd: 'Sunflower', toi: 'Sunflower'),
  CropOption(id: 'Cotton', emoji: '☁️', aiSupported: false, en: 'Cotton', sn: 'Donje', nd: 'Ikhothoni', toi: 'Cotton'),
];

CropOption? cropById(String id) {
  for (final crop in [...supportedCrops, ...roadmapCrops]) {
    if (crop.id == id) return crop;
  }
  return null;
}
