import 'package:flutter/material.dart';

import 'brand.dart';
import 'theme.dart';

class ExtensionHelpScreen extends StatefulWidget {
  final String lang;
  const ExtensionHelpScreen({super.key, required this.lang});

  @override
  State<ExtensionHelpScreen> createState() => _ExtensionHelpScreenState();
}

class _ExtensionHelpScreenState extends State<ExtensionHelpScreen> {
  String _province = 'All';

  String _ui(String en, String sn, String nd, String toi) {
    switch (widget.lang) {
      case 'sn': return sn;
      case 'nd': return nd;
      case 'toi': return toi;
      default: return en;
    }
  }

  @override
  Widget build(BuildContext context) {
    final offices = _province == 'All'
        ? extensionDirectory
        : extensionDirectory.where((o) => o.province == _province).toList();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Expanded(child: CropMedicBrand(compact: true, showTagline: false)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _ui('Get local help', 'Wana rubatsiro rwemunharaunda', 'Thola usizo lwendawo', 'Tambula lugwasyo lwabusena'),
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 34,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: Palette.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ui(
                      'Official public contacts are marked as verified. Provincial locations are shown separately when a current direct number has not yet been confirmed.',
                      'Macontact eruzhinji akasimbiswa anoiswa chiratidzo. Nzvimbo dzemapurovhinzi dzinoratidzwa zvakasiyana kana nhamba yazvino isati yasimbiswa.',
                      'Ama-contact kahulumende aqinisekisiweyo amakwe. Izindawo zezigaba zikhonjiswa ngokwehlukana nxa inombolo yamanje ingakaqinisekiswa.',
                      'Macontact a boma asinizidwe alatondezyegwa. Busena bwamacisi bulatondezyegwa naa namba tayilasinizyigwa.',
                    ),
                    style: const TextStyle(color: Palette.textDim, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _province,
                    decoration: InputDecoration(
                      labelText: _ui('Province', 'Dunhu', 'Isabelo', 'Cisi'),
                      filled: true,
                      fillColor: Palette.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    items: ['All', ...zimbabweProvinces]
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _province = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  ...offices.map((o) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Palette.primarySoft,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(Icons.agriculture_rounded, color: Palette.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(o.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Palette.primaryDark)),
                                        const SizedBox(height: 3),
                                        Text(o.province, style: const TextStyle(color: Palette.textDim, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (o.verified)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(color: Palette.primarySoft, borderRadius: BorderRadius.circular(99)),
                                      child: const Text('Verified public contact', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Palette.primaryDark)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 13),
                              _line(Icons.location_on_outlined, o.address),
                              if (o.phone != null) _line(Icons.phone_outlined, o.phone!),
                              if (o.note != null) _line(Icons.info_outline_rounded, o.note!),
                              if (o.lastVerified != null) _line(Icons.verified_outlined, 'Last verified: ${o.lastVerified}'),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 4),
                  AppCard(
                    color: const Color(0xFFFFF5DE),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _ui('Directory quality matters', 'Hunhu hwerunyorwa hwakakosha', 'Ikhwalithi yohlu ibalulekile', 'Bululami bwaluzibo bulakankamana'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Palette.primaryDark),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _ui(
                            'CropMedic should never invent an extension-office number. Contacts can change, so verified entries carry a check date and unverified provincial entries do not show a phone number.',
                            'CropMedic haifaniri kugadzira nhamba yehofisi isiri yechokwadi. Macontact anochinja, saka akasimbiswa ane zuva rekutarisa uye asina kusimbiswa haana nhamba.',
                            'CropMedic akumelanga iqambe inombolo yehofisi. Ama-contact ayatshintsha, ngakho aqinisekisiweyo alosuku lokuhlolwa kuthi angakaqinisekiswa awanombolo.',
                            'CropMedic tayelede kulenga namba yaboola. Macontact alacinja, nkabela asinizidwe alatondezya buzuba bwakusinizya alimwi atasinizyidwe takwe namba.',
                          ),
                          style: const TextStyle(height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _ui('Next: verified district and ward extension contacts across Zimbabwe.', 'Zvinotevera: macontact akasimbiswa emadistrict nema ward.', 'Okulandelayo: ama-contact aqinisekisiweyo ezigaba lama ward.', 'Cilalako: macontact asinizidwe amadistrict amaward.'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Palette.primary),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(value, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

class ExtensionOffice {
  final String province;
  final String name;
  final String address;
  final String? phone;
  final String? note;
  final bool verified;
  final String? lastVerified;

  const ExtensionOffice({
    required this.province,
    required this.name,
    required this.address,
    this.phone,
    this.note,
    this.verified = false,
    this.lastVerified,
  });
}

const zimbabweProvinces = <String>[
  'Harare',
  'Bulawayo',
  'Manicaland',
  'Mashonaland Central',
  'Mashonaland East',
  'Mashonaland West',
  'Masvingo',
  'Matabeleland North',
  'Matabeleland South',
  'Midlands',
];

const extensionDirectory = <ExtensionOffice>[
  ExtensionOffice(
    province: 'Harare',
    name: 'ARDAS national office',
    address: 'Ngungunyana Building, 1 Liberation Legacy Way, Harare',
    phone: '+263 242 705341',
    note: 'Agricultural and Rural Development Advisory Services contact published by the Ministry of Lands, Agriculture, Fisheries, Water and Rural Development.',
    verified: true,
    lastVerified: '14 Oct 2026',
  ),
  ExtensionOffice(
    province: 'Harare',
    name: 'Ministry of Agriculture head office',
    address: 'Ngungunyana Building, 1 Liberation Legacy Way, Harare',
    phone: '+263 242 706081-9',
    note: 'Official Ministry head-office general line.',
    verified: true,
    lastVerified: '14 Oct 2026',
  ),
  ExtensionOffice(
    province: 'Harare',
    name: 'Plant Protection Institute',
    address: 'Agricultural Research Centre, 5th Street Extension, Harare',
    phone: '+263 712 724701',
    note: 'Public contact listed in the Ministry 2025 client charter for plant-protection support.',
    verified: true,
    lastVerified: '14 Oct 2026',
  ),
  ExtensionOffice(
    province: 'Bulawayo',
    name: 'Provincial agricultural services',
    address: 'Mhlahlandlela Government Complex, Bulawayo',
    note: 'Provincial office location retained; a current direct extension-office number still needs verification from an official source.',
  ),
  ExtensionOffice(
    province: 'Manicaland',
    name: 'Provincial agricultural services',
    address: 'Mutare Government Composite Building, Agritex Wing, Mutare',
    note: 'Office location identified; direct extension-office phone still to be verified.',
  ),
  ExtensionOffice(
    province: 'Mashonaland Central',
    name: 'Provincial agricultural services',
    address: 'Ndodahondo Government Complex, Bindura',
    note: 'Office location identified; direct extension-office phone still to be verified.',
  ),
  ExtensionOffice(
    province: 'Mashonaland East',
    name: 'Provincial agricultural services',
    address: 'Government Composite Building, Marondera',
    note: 'Office location identified; direct extension-office phone still to be verified.',
  ),
  ExtensionOffice(
    province: 'Mashonaland West',
    name: 'Provincial agricultural services',
    address: 'Government Composite Building, Chinhoyi',
    note: 'Office location identified; direct extension-office phone still to be verified.',
  ),
  ExtensionOffice(
    province: 'Masvingo',
    name: 'Provincial agricultural services',
    address: 'Benjamin Burombo Building, Masvingo',
    note: 'Office location identified; direct extension-office phone still to be verified.',
  ),
  ExtensionOffice(
    province: 'Matabeleland North',
    name: 'Provincial agricultural services',
    address: 'Mhlahlandlela Government Complex, Bulawayo',
    note: 'Provincial office location identified; direct extension-office phone still to be verified.',
  ),
  ExtensionOffice(
    province: 'Matabeleland South',
    name: 'Provincial agricultural services',
    address: 'Mhlahlandlela Government Complex, Bulawayo',
    note: 'Provincial office location identified; direct extension-office phone still to be verified.',
  ),
  ExtensionOffice(
    province: 'Midlands',
    name: 'Provincial agricultural services',
    address: 'Gweru government offices, Gweru',
    note: 'Direct extension-office contact still to be verified.',
  ),
];
